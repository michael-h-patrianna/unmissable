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
  private let preferencesManager: PreferencesManager
  private let soundManager: SoundManager
  private let focusModeManager: FocusModeManager

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

  func showOverlay(for event: Event, minutesBeforeMeeting: Int = 5) {
    let startTime = Date()
    logger.info("🎬 SHOW OVERLAY: Starting for event: \(event.title)")

    // CRITICAL FIX: Ensure we're on main thread and prevent re-entrance
    guard Thread.isMainThread else {
      logger.error("❌ THREADING ERROR: showOverlay called off main thread")
      DispatchQueue.main.async { [weak self] in
        self?.showOverlay(for: event, minutesBeforeMeeting: minutesBeforeMeeting)
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

    // CRITICAL FIX: Set state atomically to prevent race conditions
    activeEvent = event
    isOverlayVisible = true

    logger.info("✅ OVERLAY STATE: Set isOverlayVisible = true for \(event.title)")

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
      DispatchQueue.main.async { [weak self] in
        self?.hideOverlay()
      }
      return
    }

    // CRITICAL FIX: Stop timer FIRST and clear state immediately
    stopCountdownTimer()
    soundManager.stopSound()

    // CRITICAL FIX: Clear state immediately to prevent any race conditions
    activeEvent = nil
    isOverlayVisible = false

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
      // Fallback to old method if EventScheduler not available
      logger.warning("⚠️ EventScheduler not available, using fallback timer")
      Timer.scheduledTimer(withTimeInterval: TimeInterval(minutes * 60), repeats: false) {
        [weak self] _ in
        Task { @MainActor in
          self?.showOverlay(for: event, minutesBeforeMeeting: 2)
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
      "🎯 SCHEDULE: Event '\(event.title)' should trigger in \(timeUntilShow)s (showTime: \(showTime))"
    )

    if timeUntilShow > 0 {
      logger.info("✅ SCHEDULING: Overlay for \(event.title) in \(timeUntilShow) seconds")

      // CRITICAL FIX: Use MainActor to ensure proper thread safety
      Timer.scheduledTimer(withTimeInterval: timeUntilShow, repeats: false) { [weak self] timer in
        guard let self = self else { return }

        self.logger.info("🔥 TIMER FIRED: Attempting to show overlay for \(event.title)")

        // CRITICAL FIX: Always use async dispatch to avoid deadlocks
        DispatchQueue.main.async { [weak self] in
          guard let self = self else { return }
          self.logger.info("📱 MAIN QUEUE: Calling showOverlay for \(event.title)")
          self.showOverlay(for: event, minutesBeforeMeeting: minutesBeforeMeeting)
        }
      }
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
        DispatchQueue.global(qos: .userInitiated).async {
          // Then dispatch back to main for UI operations
          DispatchQueue.main.async {
            self?.hideOverlay()
          }
        }
      },
      onJoin: { [weak self] in
        DispatchQueue.global(qos: .userInitiated).async {
          DispatchQueue.main.async {
            if let url = event.primaryLink {
              NSWorkspace.shared.open(url)
              self?.hideOverlay()
            }
          }
        }
      },
      onSnooze: { [weak self] minutes in
        DispatchQueue.global(qos: .userInitiated).async {
          DispatchQueue.main.async {
            self?.snoozeOverlay(for: minutes)
          }
        }
      }
    )
    .environmentObject(preferencesManager)
    .environmentObject(self)  // CRITICAL FIX: Provide OverlayManager as environment object

    let hostingView = NSHostingView(rootView: overlayContent)
    window.contentView = hostingView

    return window
  }

  // MARK: - Countdown Timer

  private func startCountdownTimer(for event: Event) {
    stopCountdownTimer()

    countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      DispatchQueue.main.async {
        self?.updateCountdown(for: event)
      }
    }
  }

  private func stopCountdownTimer() {
    countdownTimer?.invalidate()
    countdownTimer = nil
  }

  private func updateCountdown(for event: Event) {
    // CRITICAL FIX: Guard against invalid state
    guard isOverlayVisible, let activeEvent = activeEvent, activeEvent.id == event.id else {
      logger.warning("⚠️ UPDATE COUNTDOWN: Overlay not visible or event mismatch, stopping timer")
      stopCountdownTimer()
      return
    }

    timeUntilMeeting = event.startDate.timeIntervalSinceNow

    // Auto-hide if meeting started more than 5 minutes ago
    if timeUntilMeeting < -300 {
      logger.info("⏰ AUTO-HIDE: Meeting \(event.title) started >5 minutes ago, hiding overlay")
      // CRITICAL FIX: Use async dispatch to prevent timer re-entrance issues
      DispatchQueue.main.async { [weak self] in
        self?.hideOverlay()
      }
    }
  }
}
