import AppKit
import Combine
import Foundation
import OSLog
import SwiftUI

@MainActor
class OverlayManager: ObservableObject, OverlayManaging {
  private let logger = Logger(subsystem: "com.unmissable.app", category: "OverlayManager")

  @Published var activeEvent: Event?
  @Published var isOverlayVisible = false
  @Published var timeUntilMeeting: TimeInterval = 0

  private var overlayWindows: [NSWindow] = []
  private var countdownTimer: Timer?
  private var countdownTask: Task<Void, Never>?
  private var snoozeTask: Task<Void, Never>?
  private var scheduleTask: Task<Void, Never>?
  private var scheduledTimers: [Timer] = []  // Track all scheduled timers for cleanup
  private let preferencesManager: PreferencesManager
  private let soundManager: SoundManager
  private let focusModeManager: FocusModeManager

  // SNOOZE FIX: Track when overlay is shown from snooze alert
  private var isSnoozedAlert = false

  // Test mode to prevent UI creation in tests
  private let isTestMode: Bool

  // Reference to EventScheduler for proper snooze scheduling
  private weak var eventScheduler: EventScheduler?

  init(
    preferencesManager: PreferencesManager, focusModeManager: FocusModeManager? = nil,
    isTestMode: Bool = false
  ) {
    self.preferencesManager = preferencesManager
    self.soundManager = SoundManager(preferencesManager: preferencesManager)
    self.focusModeManager =
      focusModeManager ?? FocusModeManager(preferencesManager: preferencesManager)
    self.isTestMode = isTestMode
  }

  convenience init() {
    let prefs = PreferencesManager()
    self.init(
      preferencesManager: prefs, focusModeManager: FocusModeManager(preferencesManager: prefs),
      isTestMode: false)
  }

  func setEventScheduler(_ scheduler: EventScheduler) {
    self.eventScheduler = scheduler
  }

  func showOverlay(for event: Event, minutesBeforeMeeting: Int = 5, fromSnooze: Bool = false) {
    let startTime = Date()
    logger.info("🎬 SHOW OVERLAY: Starting for event: \(event.title), fromSnooze: \(fromSnooze)")

    // CRITICAL FIX: Ensure we're on main thread and prevent re-entrance
    guard Thread.isMainThread else {
      logger.error("❌ THREADING ERROR: showOverlay called off main thread")
      Task { @MainActor in
        self.showOverlay(
          for: event, minutesBeforeMeeting: minutesBeforeMeeting, fromSnooze: fromSnooze)
      }
      return
    }

    // CRITICAL FIX: Prevent overlapping overlay operations
    if isOverlayVisible && activeEvent?.id == event.id {
      logger.info("⚠️ SKIP: Overlay already visible for this event")
      return
    }

    // Check if we should show overlay based on Focus/DND status
    guard focusModeManager.shouldShowOverlay() else {
      logger.info("📵 FOCUS MODE: Overlay suppressed due to Focus/DND mode")
      return
    }

    // CRITICAL FIX: Clean up any existing overlay first (atomic operation)
    hideOverlay()

    // SNOOZE FIX: Track if this overlay is from a snooze alert
    isSnoozedAlert = fromSnooze

    // CRITICAL FIX: Set state atomically to prevent race conditions
    activeEvent = event
    isOverlayVisible = true

    // CRITICAL FIX: Initialize timeUntilMeeting immediately, not just in timer
    timeUntilMeeting = event.startDate.timeIntervalSinceNow

    logger.info(
      "✅ OVERLAY STATE: Set isOverlayVisible = true for \(event.title), timeUntilMeeting = \(self.timeUntilMeeting), isSnoozed = \(self.isSnoozedAlert)"
    )

    // Play alert sound if enabled and allowed by focus mode
    if focusModeManager.shouldPlaySound() {
      soundManager.playAlertSound()
    }

    // CRITICAL FIX: Create windows synchronously on main thread
    createOverlayWindows(for: event)
    startCountdownTimer(for: event)

    // Log successful overlay creation
    let responseTime = Date().timeIntervalSince(startTime)
    ProductionMonitor.shared.logOverlaySuccess(responseTime: responseTime)

    logger.info("🎬 SHOW OVERLAY: Completed for event: \(event.title) in \(responseTime)s")
  }

  func hideOverlay() {
    logger.info("🛑 HIDE OVERLAY: Starting cleanup")

    // CRITICAL FIX: Ensure we're on main thread
    guard Thread.isMainThread else {
      logger.error("❌ THREADING ERROR: hideOverlay called off main thread")
      Task { @MainActor in
        self.hideOverlay()
      }
      return
    }

    // CRITICAL FIX: Stop timer FIRST and clear state immediately
    stopCountdownTimer()
    invalidateAllScheduledTimers()  // NEW: Clean up all scheduled timers
    soundManager.stopSound()

    // CRITICAL FIX: Clear state immediately to prevent any race conditions
    activeEvent = nil
    isOverlayVisible = false
    isSnoozedAlert = false  // SNOOZE FIX: Reset snooze flag

    // CRITICAL FIX: Close windows on background queue to avoid Window Server deadlock
    let windowsToClose = overlayWindows
    overlayWindows.removeAll()

    if !windowsToClose.isEmpty {
      logger.info("🪟 Hiding \(windowsToClose.count) overlay windows...")

      // CRITICAL FIX: Use orderOut instead of close to avoid Window Server deadlock
      // orderOut removes window from screen without complex cleanup that can deadlock
      for window in windowsToClose {
        window.orderOut(nil)
      }
    }

    logger.info("✅ HIDE OVERLAY: Cleanup completed")
  }

  func snoozeOverlay(for minutes: Int) {
    guard let event = activeEvent else { return }

    logger.info("Snoozing overlay for \(minutes) minutes")
    hideOverlay()

    // Use EventScheduler for proper snooze scheduling
    if let scheduler = eventScheduler {
      scheduler.scheduleSnooze(for: event, minutes: minutes)
      logger.info("✅ Snooze scheduled through EventScheduler")
    } else {
      // Fallback to Task-based method if EventScheduler not available
      logger.warning("⚠️ EventScheduler not available, using fallback Task")

      snoozeTask = Task { @MainActor in
        do {
          let snoozeSeconds = TimeInterval(minutes * 60)
          logger.info("⏰ SNOOZE: Starting \(snoozeSeconds)s delay")
          try await Task.sleep(for: .seconds(snoozeSeconds))

          if !Task.isCancelled {
            logger.info("⏰ SNOOZE: Delay complete, showing overlay")
            showOverlay(for: event, minutesBeforeMeeting: 2, fromSnooze: true)
          }
        } catch {
          logger.info("⏰ SNOOZE: Task cancelled")
        }
      }
    }
  }

  func scheduleOverlay(for event: Event, minutesBeforeMeeting: Int = 5) {
    logger.info(
      "⏰ SCHEDULE OVERLAY: Event '\(event.title)' for \(minutesBeforeMeeting) minutes before")

    let showTime = event.startDate.addingTimeInterval(-TimeInterval(minutesBeforeMeeting * 60))
    let timeUntilShow = showTime.timeIntervalSinceNow

    logger.info(
      "🎯 SCHEDULE: Event '\(event.title)' should trigger in \(timeUntilShow)s (showTime: \(showTime), current: \(Date()))"
    )

    if timeUntilShow > 0 {
      logger.info("✅ SCHEDULING: Task-based overlay for \(event.title) in \(timeUntilShow) seconds")

      // Cancel any existing schedule task before creating new one
      scheduleTask?.cancel()

      // CRITICAL FIX: Use Task-based scheduling to ensure proper thread safety
      scheduleTask = Task { @MainActor in
        do {
          logger.info("⏰ SCHEDULE: Starting \(timeUntilShow)s delay for \(event.title)")
          try await Task.sleep(for: .seconds(timeUntilShow))

          if !Task.isCancelled {
            logger.info("🔥 TASK FIRED: Attempting to show overlay for \(event.title)")
            logger.info("📱 MAIN QUEUE: Calling showOverlay for \(event.title)")
            showOverlay(
              for: event, minutesBeforeMeeting: minutesBeforeMeeting, fromSnooze: false)
          } else {
            logger.info("⏰ SCHEDULE: Task was cancelled for \(event.title)")
          }
        } catch {
          logger.info("⏰ SCHEDULE: Task cancelled/interrupted for \(event.title)")
        }
      }

      logger.info("📝 TASK SCHEDULED: Schedule task created for \(event.title)")
    } else {
      logger.warning(
        "⚠️ SKIP: Event \(event.title) starts too soon to schedule overlay (timeUntilShow: \(timeUntilShow))"
      )
    }
  }

  private func createOverlayWindows(for event: Event) {
    if isTestMode {
      print("🧪 TEST MODE: Skipping actual window creation for \(event.title)")
      return
    }

    let screens = NSScreen.screens

    // Use preferences to determine which displays to show on
    let screensToUse =
      preferencesManager.showOnAllDisplays ? screens : [NSScreen.main].compactMap { $0 }

    for screen in screensToUse {
      let window = createOverlayWindow(for: screen, event: event)
      overlayWindows.append(window)
      window.makeKeyAndOrderFront(nil)
    }
  }

  private func createOverlayWindow(for screen: NSScreen, event: Event) -> NSWindow {
    let window = NSWindow(
      contentRect: screen.frame,
      styleMask: [.borderless],
      backing: .buffered,
      defer: false,
      screen: screen
    )

    window.level = .screenSaver
    window.backgroundColor = NSColor.black.withAlphaComponent(preferencesManager.overlayOpacity)
    window.isOpaque = false
    window.ignoresMouseEvents = false
    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

    // CRITICAL FIX: Use async dispatch with delay to break out of current execution context
    let overlayContent = OverlayContentView(
      event: event,
      onDismiss: { [weak self] in
        // CRITICAL FIX: Use background queue to break out of main thread deadlock
        Task.detached(priority: .userInitiated) {
          // Then dispatch back to main for UI operations
          await MainActor.run {
            self?.hideOverlay()
          }
        }
      },
      onJoin: { [weak self] in
        Task.detached(priority: .userInitiated) {
          await MainActor.run {
            if let url = event.primaryLink {
              NSWorkspace.shared.open(url)
              self?.hideOverlay()
            }
          }
        }
      },
      onSnooze: { [weak self] minutes in
        Task.detached(priority: .userInitiated) {
          await MainActor.run {
            self?.snoozeOverlay(for: minutes)
          }
        }
      },
      isFromSnooze: isSnoozedAlert
    )
    .environmentObject(preferencesManager)
    // FIXED: Retain cycle resolved by moving timer to OverlayContentView

    let hostingView = NSHostingView(rootView: overlayContent)
    window.contentView = hostingView

    return window
  }

  // MARK: - Countdown Timer

  private func startCountdownTimer(for event: Event) {
    logger.debug("⏰ COUNTDOWN: Starting Task-based countdown timer for \(event.title)")
    stopCountdownTimer()

    countdownTask = Task { @MainActor in
      while !Task.isCancelled && isOverlayVisible && activeEvent?.id == event.id {
        do {
          logger.debug("⏰ COUNTDOWN: Task iteration for \(event.title)")
          updateCountdown(for: event)
          try await Task.sleep(for: .seconds(1))
        } catch {
          // Task was cancelled
          logger.info("⏰ COUNTDOWN: Task cancelled for \(event.title)")
          break
        }
      }
      logger.info("⏰ COUNTDOWN: Task completed for \(event.title)")
    }
  }

  private func stopCountdownTimer() {
    // Cancel Task-based countdown
    if let task = countdownTask {
      task.cancel()
      countdownTask = nil
      logger.debug("⏹️ TASK: Countdown task cancelled and deallocated")
    }

    // Also clean up any legacy Timer (for transition period)
    if let timer = countdownTimer {
      timer.invalidate()
      countdownTimer = nil
      logger.debug("⏹️ TIMER: Legacy countdown timer stopped and deallocated")
    }
  }

  private func invalidateAllScheduledTimers() {
    logger.info("🧹 CLEANUP: Invalidating \(self.scheduledTimers.count) scheduled timers")
    for timer in scheduledTimers {
      timer.invalidate()
    }
    scheduledTimers.removeAll()

    // Cancel snooze task
    if let snoozeTask = snoozeTask {
      snoozeTask.cancel()
      self.snoozeTask = nil
      logger.debug("🧹 CLEANUP: Cancelled snooze task")
    }

    // Cancel schedule task
    if let scheduleTask = scheduleTask {
      scheduleTask.cancel()
      self.scheduleTask = nil
      logger.debug("🧹 CLEANUP: Cancelled schedule task")
    }
  }

  private func updateCountdown(for event: Event) {
    // CRITICAL FIX: Guard against invalid state
    guard isOverlayVisible, let activeEvent = activeEvent, activeEvent.id == event.id else {
      logger.warning("⚠️ UPDATE COUNTDOWN: Overlay not visible or event mismatch, stopping timer")
      stopCountdownTimer()
      return
    }

    timeUntilMeeting = event.startDate.timeIntervalSinceNow

    // SNOOZE FIX: Different auto-hide behavior for snoozed vs regular alerts
    let autoHideThreshold: TimeInterval = isSnoozedAlert ? -1800 : -300  // 30 minutes for snoozed, 5 minutes for regular

    if timeUntilMeeting < autoHideThreshold {
      let thresholdMinutes = Int(-autoHideThreshold / 60)
      logger.info(
        "⏰ AUTO-HIDE: Meeting \(event.title) started >\(thresholdMinutes) minutes ago, hiding overlay (snoozed: \(self.isSnoozedAlert))"
      )
      // CRITICAL FIX: Use async dispatch to prevent timer re-entrance issues
      Task { @MainActor in
        self.hideOverlay()
      }
    }
  }
}
