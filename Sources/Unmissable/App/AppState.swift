import Combine
import Foundation
import OSLog

@MainActor
class AppState: ObservableObject {
  private let logger = Logger(subsystem: "com.unmissable.app", category: "AppState")

  // Published properties for UI binding
  @Published var isConnectedToCalendar = false
  @Published var syncStatus: SyncStatus = .idle
  @Published var lastSyncTime: Date?
  @Published var upcomingEvents: [Event] = []
  @Published var activeOverlay: Event?
  @Published var userEmail: String?
  @Published var calendars: [CalendarInfo] = []
  @Published var authError: String?
  @Published var healthStatus: HealthStatus = .healthy

  // Services
  private let calendarService = CalendarService()
  private let preferencesManager = PreferencesManager()
  private let overlayManager: OverlayManager
  private let eventScheduler = EventScheduler()
  private let shortcutsManager = ShortcutsManager()
  private let focusModeManager: FocusModeManager
  private let healthMonitor = HealthMonitor()

  private var cancellables = Set<AnyCancellable>()

  init() {
    // Initialize services in dependency order
    self.focusModeManager = FocusModeManager(preferencesManager: preferencesManager)
    self.overlayManager = OverlayManager(
      preferencesManager: preferencesManager, focusModeManager: focusModeManager)

    setupBindings()
    checkInitialState()

    // Setup shortcuts after managers are ready
    shortcutsManager.setup(overlayManager: overlayManager)

    // Setup health monitoring
    healthMonitor.setup(
      calendarService: calendarService,
      syncManager: calendarService.syncManagerPublic,
      overlayManager: overlayManager
    )
  }

  private func setupBindings() {
    // Observe calendar connection status
    calendarService.$isConnected
      .assign(to: \.isConnectedToCalendar, on: self)
      .store(in: &cancellables)

    // Observe sync status
    calendarService.$syncStatus
      .assign(to: \.syncStatus, on: self)
      .store(in: &cancellables)

    // Observe upcoming events
    calendarService.$events
      .assign(to: \.upcomingEvents, on: self)
      .store(in: &cancellables)

    // Observe calendars
    calendarService.$calendars
      .assign(to: \.calendars, on: self)
      .store(in: &cancellables)

    // Observe user email
    calendarService.oauth2Service.$userEmail
      .assign(to: \.userEmail, on: self)
      .store(in: &cancellables)

    // Observe auth errors
    calendarService.oauth2Service.$authorizationError
      .assign(to: \.authError, on: self)
      .store(in: &cancellables)

    // Observe active overlay
    overlayManager.$activeEvent
      .assign(to: \.activeOverlay, on: self)
      .store(in: &cancellables)

    // Observe health status
    healthMonitor.$healthStatus
      .assign(to: \.healthStatus, on: self)
      .store(in: &cancellables)
  }

  private func checkInitialState() {
    Task {
      await calendarService.checkConnectionStatus()
      if isConnectedToCalendar {
        await startPeriodicSync()
      }
    }
  }

  // MARK: - Public Interface

  func connectToCalendar() async {
    logger.info("Initiating calendar connection")
    await calendarService.connect()

    if isConnectedToCalendar {
      await startPeriodicSync()
    }
  }

  func disconnectFromCalendar() async {
    logger.info("Disconnecting from calendar")
    await calendarService.disconnect()
    eventScheduler.stopScheduling()
  }

  func syncNow() async {
    logger.info("Manual sync requested")
    await calendarService.syncEvents()
  }

  func updateCalendarSelection(_ calendarId: String, isSelected: Bool) {
    calendarService.updateCalendarSelection(calendarId, isSelected: isSelected)
  }

  // MARK: - Public Services Access

  var calendarServicePublic: CalendarService {
    calendarService
  }

  var preferencesManagerPublic: PreferencesManager {
    preferencesManager
  }

  var shortcutsManagerPublic: ShortcutsManager {
    shortcutsManager
  }

  var focusModeManagerPublic: FocusModeManager {
    focusModeManager
  }

  var healthMonitorPublic: HealthMonitor {
    healthMonitor
  }

  private func startPeriodicSync() async {
    await eventScheduler.startScheduling(
      events: upcomingEvents,
      overlayManager: overlayManager
    )
  }
}

enum SyncStatus: Equatable {
  case idle
  case syncing
  case offline
  case error(String)

  var description: String {
    switch self {
    case .idle:
      return "Ready"
    case .syncing:
      return "Syncing..."
    case .offline:
      return "Offline"
    case .error(let message):
      return "Error: \(message)"
    }
  }
}
