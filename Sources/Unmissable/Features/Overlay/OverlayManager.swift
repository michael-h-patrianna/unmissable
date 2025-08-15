import AppKit
import Combine
import Foundation
import OSLog
import SwiftUI

@MainActor
class OverlayManager: ObservableObject {
  private let logger = Logger(subsystem: "com.unmissable.app", category: "OverlayManager")

  @Published var activeEvent: Event?
  @Published var isOverlayVisible = false
  @Published var timeUntilMeeting: TimeInterval = 0

  private var overlayWindows: [NSWindow] = []
  private var countdownTimer: Timer?
  private let preferencesManager: PreferencesManager
  private let soundManager: SoundManager
  private let focusModeManager: FocusModeManager

  init(preferencesManager: PreferencesManager, focusModeManager: FocusModeManager? = nil) {
    self.preferencesManager = preferencesManager
    self.soundManager = SoundManager(preferencesManager: preferencesManager)
    self.focusModeManager =
      focusModeManager ?? FocusModeManager(preferencesManager: preferencesManager)
  }

  convenience init() {
    let prefs = PreferencesManager()
    self.init(
      preferencesManager: prefs, focusModeManager: FocusModeManager(preferencesManager: prefs))
  }

  func showOverlay(for event: Event, minutesBeforeMeeting: Int = 5) {
    logger.info("Showing overlay for event: \(event.title)")

    // Check if we should show overlay based on Focus/DND status
    guard focusModeManager.shouldShowOverlay() else {
      logger.info("Overlay suppressed due to Focus/DND mode")
      return
    }

    hideOverlay()

    activeEvent = event
    isOverlayVisible = true

    // Play alert sound if enabled and allowed by focus mode
    if focusModeManager.shouldPlaySound() {
      soundManager.playAlertSound()
    }

    createOverlayWindows(for: event)
    startCountdownTimer(for: event)
  }

  func hideOverlay() {
    logger.info("Hiding overlay")

    stopCountdownTimer()
    soundManager.stopSound()

    for window in overlayWindows {
      window.close()
    }
    overlayWindows.removeAll()

    activeEvent = nil
    isOverlayVisible = false
  }

  func snoozeOverlay(for minutes: Int) {
    guard let event = activeEvent else { return }

    logger.info("Snoozing overlay for \(minutes) minutes")
    hideOverlay()

    // Re-schedule overlay to appear after snooze period
    Timer.scheduledTimer(withTimeInterval: TimeInterval(minutes * 60), repeats: false) {
      [weak self] _ in
      Task { @MainActor in
        self?.showOverlay(for: event, minutesBeforeMeeting: 2)  // Shorter warning after snooze
      }
    }
  }

  func scheduleOverlay(for event: Event, minutesBeforeMeeting: Int = 5) {
    let showTime = event.startDate.addingTimeInterval(-TimeInterval(minutesBeforeMeeting * 60))
    let timeUntilShow = showTime.timeIntervalSinceNow

    if timeUntilShow > 0 {
      logger.info("Scheduling overlay for \(event.title) in \(timeUntilShow) seconds")

      Timer.scheduledTimer(withTimeInterval: timeUntilShow, repeats: false) { [weak self] _ in
        Task { @MainActor in
          self?.showOverlay(for: event, minutesBeforeMeeting: minutesBeforeMeeting)
        }
      }
    } else {
      logger.warning("Event \(event.title) starts too soon to schedule overlay")
    }
  }

  private func createOverlayWindows(for event: Event) {
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

    // Create SwiftUI view for overlay content
    let hostingView = NSHostingView(
      rootView: OverlayContentView(
        event: event,
        onDismiss: { [weak self] in
          self?.hideOverlay()
        },
        onJoin: { [weak self] in
          if let url = event.primaryLink {
            NSWorkspace.shared.open(url)
            self?.hideOverlay()
          }
        },
        onSnooze: { [weak self] minutes in
          self?.snoozeOverlay(for: minutes)
        }
      )
      .environmentObject(preferencesManager)  // Pass preferences for theming
    )

    window.contentView = hostingView

    return window
  }

  // MARK: - Countdown Timer

  private func startCountdownTimer(for event: Event) {
    stopCountdownTimer()

    countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      Task { @MainActor in
        self?.updateCountdown(for: event)
      }
    }
  }

  private func stopCountdownTimer() {
    countdownTimer?.invalidate()
    countdownTimer = nil
  }

  private func updateCountdown(for event: Event) {
    timeUntilMeeting = event.startDate.timeIntervalSinceNow

    // Auto-hide if meeting started more than 5 minutes ago
    if timeUntilMeeting < -300 {
      hideOverlay()
    }
  }
}
