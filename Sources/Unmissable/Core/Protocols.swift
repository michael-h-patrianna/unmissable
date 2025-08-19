import Foundation

// MARK: - Protocol Definitions for Dependency Injection

/// Protocol for overlay scheduling and display functionality
@MainActor
protocol OverlayManaging: ObservableObject {
  var activeEvent: Event? { get }
  var isOverlayVisible: Bool { get }
  var timeUntilMeeting: TimeInterval { get }

  func scheduleOverlay(for event: Event, minutesBeforeMeeting: Int)
  func showOverlay(for event: Event, minutesBeforeMeeting: Int, fromSnooze: Bool)
  func hideOverlay()
  func snoozeOverlay(for minutes: Int)
  func setEventScheduler(_ scheduler: EventScheduler)
}

/// Protocol for event scheduling functionality
@MainActor
protocol EventScheduling: ObservableObject {
  func startScheduling(events: [Event], overlayManager: OverlayManager) async
  func stopScheduling()
  func scheduleSnooze(for event: Event, minutes: Int)
}

/// Protocol for sound management
protocol SoundManaging {
  func playAlertSound()
  func playSnoozeSound()
}

/// Protocol for focus mode detection
@MainActor
protocol FocusModeManaging {
  func shouldShowOverlay() -> Bool
  func shouldPlaySound() -> Bool
}

/// Protocol for preferences management
@MainActor
protocol PreferencesManaging: ObservableObject {
  var overlayShowMinutesBefore: Int { get set }
  var soundEnabled: Bool { get set }
  var overlayOpacity: Double { get set }
  var appearanceTheme: AppTheme { get set }
  var showOnAllDisplays: Bool { get set }

  func alertMinutes(for event: Event) -> Int
}

/// Protocol for overlay rendering with error handling
@MainActor
protocol OverlayRendering: ObservableObject {
  var isRenderingOverlay: Bool { get }
  var lastRenderError: String? { get }

  func cleanup()
}

// MARK: - Test-Safe Implementations

/// Test-safe overlay manager that doesn't create actual UI elements
@MainActor
class TestSafeOverlayManager: OverlayManaging {
  @Published var activeEvent: Event?
  @Published var isOverlayVisible = false
  @Published var timeUntilMeeting: TimeInterval = 0

  private weak var eventScheduler: EventScheduler?
  private let isTestEnvironment: Bool

  init(isTestEnvironment: Bool = false) {
    self.isTestEnvironment = isTestEnvironment
  }

  func scheduleOverlay(for event: Event, minutesBeforeMeeting: Int = 5) {
    let showTime = event.startDate.addingTimeInterval(-TimeInterval(minutesBeforeMeeting * 60))
    let timeUntilShow = showTime.timeIntervalSinceNow

    print("🎯 TEST-SAFE SCHEDULE: Event '\(event.title)' should trigger in \(timeUntilShow)s")

    if timeUntilShow > 0 {
      // Swift 5.10+ compatible: Use Task.sleep instead of Timer for better concurrency
      Task { @MainActor in
        do {
          try await Task.sleep(for: .seconds(timeUntilShow))
          print("🔥 TEST-SAFE TIMER: Firing for \(event.title)")
          self.showOverlay(
            for: event, minutesBeforeMeeting: minutesBeforeMeeting, fromSnooze: false)
        } catch {
          print("⏰ TEST-SAFE: Task cancelled for \(event.title)")
        }
      }
    }
  }

  func showOverlay(for event: Event, minutesBeforeMeeting: Int = 5, fromSnooze: Bool = false) {
    print("🎬 TEST-SAFE SHOW: Overlay for \(event.title), fromSnooze: \(fromSnooze)")

    if isTestEnvironment {
      // In test environment, just set state without creating UI
      activeEvent = event
      isOverlayVisible = true
      print("✅ TEST-SAFE: Set overlay visible = true")
    } else {
      // In production, would create actual UI (but this class is for testing)
      activeEvent = event
      isOverlayVisible = true
    }
  }

  func hideOverlay() {
    print("🎬 TEST-SAFE HIDE: Overlay")
    activeEvent = nil
    isOverlayVisible = false
  }

  func snoozeOverlay(for minutes: Int) {
    guard let event = activeEvent else { return }
    print("⏰ TEST-SAFE SNOOZE: \(minutes) minutes for \(event.title)")
    hideOverlay()
    eventScheduler?.scheduleSnooze(for: event, minutes: minutes)
  }

  func setEventScheduler(_ scheduler: EventScheduler) {
    self.eventScheduler = scheduler
  }
}

// MARK: - Factory for Environment-Specific Implementations

enum OverlayManagerFactory {
  @MainActor
  static func create(
    preferencesManager: PreferencesManager,
    focusModeManager: FocusModeManager? = nil,
    isTestEnvironment: Bool = false
  ) -> any OverlayManaging {

    if isTestEnvironment {
      return TestSafeOverlayManager(isTestEnvironment: true)
    } else {
      return OverlayManager(
        preferencesManager: preferencesManager,
        focusModeManager: focusModeManager
      )
    }
  }
}
