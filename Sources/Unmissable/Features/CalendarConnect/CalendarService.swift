import Combine
import Foundation
import OSLog

@MainActor
class CalendarService: ObservableObject {
  private let logger = Logger(subsystem: "com.unmissable.app", category: "CalendarService")

  @Published var isConnected = false
  @Published var syncStatus: SyncStatus = .idle
  @Published var events: [Event] = []
  @Published var startedEvents: [Event] = []
  @Published var calendars: [CalendarInfo] = []
  @Published var lastSyncTime: Date?
  @Published var nextSyncTime: Date?

  let oauth2Service: OAuth2Service
  private let apiService: GoogleCalendarAPIService
  private let syncManager: SyncManager
  private let databaseManager: DatabaseManager
  private let timezoneManager: TimezoneManager
  private let preferencesManager: PreferencesManager
  private var cancellables = Set<AnyCancellable>()
  private var uiRefreshTimer: Timer?

  // Callback to notify when events need to be rescheduled after sync
  var onEventsUpdated: (() async -> Void)?

  init(preferencesManager: PreferencesManager) {
    self.preferencesManager = preferencesManager
    self.oauth2Service = OAuth2Service()
    self.apiService = GoogleCalendarAPIService(oauth2Service: oauth2Service)
    self.databaseManager = DatabaseManager.shared
    self.syncManager = SyncManager(
      apiService: apiService, databaseManager: databaseManager,
      preferencesManager: preferencesManager)
    self.timezoneManager = TimezoneManager.shared

    setupBindings()
    setupSyncCallback()
    startUIRefreshTimer()
  }

  private func setupBindings() {
    // Observe OAuth authentication status
    oauth2Service.$isAuthenticated
      .assign(to: \.isConnected, on: self)
      .store(in: &cancellables)

    // Observe sync status
    syncManager.$syncStatus
      .assign(to: \.syncStatus, on: self)
      .store(in: &cancellables)

    // Observe sync times
    syncManager.$lastSyncTime
      .assign(to: \.lastSyncTime, on: self)
      .store(in: &cancellables)

    syncManager.$nextSyncTime
      .assign(to: \.nextSyncTime, on: self)
      .store(in: &cancellables)

    // Load cached data on startup
    Task {
      await loadCachedData()
    }

    // Listen for timezone changes
    NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)
      .sink { [weak self] _ in
        Task { @MainActor in
          await self?.handleTimezoneChange()
        }
      }
      .store(in: &cancellables)
  }

  private func setupSyncCallback() {
    // Set up callback to refresh UI after automatic sync completes
    syncManager.onSyncCompleted = { [weak self] in
      await self?.loadCachedData()
      self?.logger.info("🔄 UI refreshed after automatic sync completion")

      // Also notify that events have been updated so alerts can be rescheduled
      await self?.onEventsUpdated?()
      self?.logger.info("📅 Event rescheduling triggered after sync completion")
    }
  }

  func checkConnectionStatus() async {
    logger.info("Checking calendar connection status")
    if isConnected {
      await loadCachedData()
    }
  }

  func connect() async {
    logger.info("Initiating calendar connection")
    do {
      try await oauth2Service.startAuthorizationFlow()

      if isConnected {
        await loadCalendars()
        try await syncManager.syncCalendarList()
        syncManager.startPeriodicSync()
        await loadCachedData()
      }
    } catch {
      logger.error("Calendar connection failed: \(error.localizedDescription)")
      isConnected = false
    }
  }

  func disconnect() async {
    logger.info("Disconnecting from calendar")
    syncManager.stopPeriodicSync()
    oauth2Service.signOut()
    events = []
    calendars = []
  }

  func syncEvents() async {
    await syncManager.performSync()
    await loadCachedData()
  }

  func updateCalendarSelection(_ calendarId: String, isSelected: Bool) {
    if let index = calendars.firstIndex(where: { $0.id == calendarId }) {
      calendars[index] = CalendarInfo(
        id: calendars[index].id,
        name: calendars[index].name,
        description: calendars[index].description,
        isSelected: isSelected,
        isPrimary: calendars[index].isPrimary,
        colorHex: calendars[index].colorHex,
        lastSyncAt: calendars[index].lastSyncAt,
        createdAt: calendars[index].createdAt,
        updatedAt: Date()
      )

      logger.info("Updated calendar \(calendarId) selection to \(isSelected)")

      // Save to database
      Task {
        try await databaseManager.saveCalendars([calendars[index]])
      }

      // Trigger a sync if we're connected
      if isConnected {
        Task {
          await syncEvents()
        }
      }
    }
  }

  private func loadCalendars() async {
    do {
      try await apiService.fetchCalendars()
      // Convert API calendars to local models
      calendars = apiService.calendars
      logger.info("Loaded \(self.calendars.count) calendars")
    } catch {
      logger.error("Failed to load calendars: \(error.localizedDescription)")
    }
  }

  private func loadCachedData() async {
    do {
      // Load calendars from database
      let cachedCalendars = try await databaseManager.fetchCalendars()
      if !cachedCalendars.isEmpty {
        calendars = cachedCalendars
      }

      // Load upcoming events from database with timezone conversion
      let cachedEvents = try await databaseManager.fetchUpcomingEvents(limit: 50)

      // Load started meetings from database with timezone conversion
      let cachedStartedEvents = try await databaseManager.fetchStartedMeetings(limit: 20)

      // DEBUG: Log what events we're loading for the UI
      print(
        "🔄 CalendarService: Loading \(cachedEvents.count) upcoming + \(cachedStartedEvents.count) started events for UI"
      )
      if let firstEvent = cachedEvents.first {
        print("🔄 CalendarService: First cached event - \(firstEvent.title)")
        print(
          "🔄 CalendarService: Description in cached: \(firstEvent.description != nil ? "YES (\(firstEvent.description!.count) chars)" : "NO")"
        )
        print("🔄 CalendarService: Attendees in cached: \(firstEvent.attendees.count) attendees")
      }
      if let firstStartedEvent = cachedStartedEvents.first {
        print("🔄 CalendarService: First started event - \(firstStartedEvent.title)")
      }
      fflush(stdout)

      events = cachedEvents.map { timezoneManager.localizedEvent($0) }
      startedEvents = cachedStartedEvents.map { timezoneManager.localizedEvent($0) }

      // DEBUG: Log what events we're setting for the UI after timezone conversion
      if let firstUIEvent = events.first {
        print("🔄 CalendarService: First UI event after timezone - \(firstUIEvent.title)")
        print(
          "🔄 CalendarService: Description in UI: \(firstUIEvent.description != nil ? "YES (\(firstUIEvent.description!.count) chars)" : "NO")"
        )
        print("🔄 CalendarService: Attendees in UI: \(firstUIEvent.attendees.count) attendees")
      }
      if let firstStartedUIEvent = startedEvents.first {
        print(
          "🔄 CalendarService: First started UI event after timezone - \(firstStartedUIEvent.title)")
      }
      fflush(stdout)

      logger.info(
        "Loaded \(self.calendars.count) calendars, \(self.events.count) upcoming events, and \(self.startedEvents.count) started meetings from cache"
      )
    } catch {
      logger.error("Failed to load cached data: \(error.localizedDescription)")
    }
  }

  private func handleTimezoneChange() async {
    logger.info("Handling timezone change")
    timezoneManager.handleTimezoneChange()

    // Reload events with new timezone
    await loadCachedData()
  }

  // MARK: - Search and Queries

  func searchEvents(query: String) async throws -> [Event] {
    let results = try await syncManager.searchEvents(query: query)
    return results.map { timezoneManager.localizedEvent($0) }
  }

  func getEventsForToday() async throws -> [Event] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today

    let results = try await syncManager.getEventsInRange(from: today, to: tomorrow)
    return results.map { timezoneManager.localizedEvent($0) }
  }

  func getUpcomingEvents(limit: Int = 10) async throws -> [Event] {
    let results = try await syncManager.getUpcomingEvents(limit: limit)
    return results.map { timezoneManager.localizedEvent($0) }
  }

  // MARK: - Public Accessors

  var syncManagerPublic: SyncManager {
    syncManager
  }

  // MARK: - UI Refresh Timer

  private func startUIRefreshTimer() {
    // Start a timer that refreshes UI events every 30 seconds
    // This ensures real-time updates for time-dependent UI elements like join buttons
    uiRefreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
      Task { @MainActor in
        await self?.refreshUIEvents()
      }
    }
    logger.info("✅ UI refresh timer started (30 second interval)")
  }

  private func stopUIRefreshTimer() {
    uiRefreshTimer?.invalidate()
    uiRefreshTimer = nil
    logger.info("⏹️ UI refresh timer stopped")
  }

  private func refreshUIEvents() async {
    // Refresh events from database to update time-dependent UI elements
    // without triggering a full calendar sync
    await loadCachedData()
  }
}
