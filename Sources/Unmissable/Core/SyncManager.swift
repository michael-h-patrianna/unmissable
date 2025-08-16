import Combine
import Foundation
import Network
import OSLog

@MainActor
class SyncManager: ObservableObject {
  private let logger = Logger(subsystem: "com.unmissable.app", category: "SyncManager")

  @Published var syncStatus: SyncStatus = .idle
  @Published var lastSyncTime: Date?
  @Published var nextSyncTime: Date?
  @Published var isOnline: Bool = true
  @Published var retryCount: Int = 0

  private let apiService: GoogleCalendarAPIService
  private let databaseManager: DatabaseManager
  private let preferencesManager: PreferencesManager
  private var syncTimer: Timer?
  private var networkMonitor: NWPathMonitor?
  private let networkQueue = DispatchQueue(label: "NetworkMonitor")
  private var cancellables = Set<AnyCancellable>()

  // Sync completion callback
  var onSyncCompleted: (() async -> Void)?
  private let eventLookAheadDays = 7  // Sync events for next 7 days

  // Retry configuration
  private let maxRetries = 5
  private let baseRetryDelay: TimeInterval = 5.0  // Start with 5 seconds
  private var retryTimer: Timer?

  init(
    apiService: GoogleCalendarAPIService, databaseManager: DatabaseManager,
    preferencesManager: PreferencesManager
  ) {
    self.apiService = apiService
    self.databaseManager = databaseManager
    self.preferencesManager = preferencesManager
    setupNetworkMonitoring()
    setupPreferencesObserver()
  }

  deinit {
    networkMonitor?.cancel()
    syncTimer?.invalidate()
    retryTimer?.invalidate()
  }

  private var syncInterval: TimeInterval {
    TimeInterval(preferencesManager.syncIntervalSeconds)
  }

  private func setupPreferencesObserver() {
    // Watch for sync interval changes
    preferencesManager.$syncIntervalSeconds
      .sink { [weak self] _ in
        Task { @MainActor in
          // Restart periodic sync with new interval
          if self?.syncTimer != nil {
            self?.stopPeriodicSync()
            self?.startPeriodicSync()
          }
        }
      }
      .store(in: &cancellables)
  }

  private func setupNetworkMonitoring() {
    networkMonitor = NWPathMonitor()

    networkMonitor?.pathUpdateHandler = { [weak self] path in
      Task { @MainActor in
        let wasOnline = self?.isOnline ?? true
        self?.isOnline = path.status == .satisfied

        if !wasOnline && self?.isOnline == true {
          self?.logger.info("Network connection restored, attempting sync")
          await self?.performSync()
        } else if self?.isOnline == false {
          self?.logger.warning("Network connection lost")
          self?.syncStatus = .offline
        }
      }
    }

    networkMonitor?.start(queue: networkQueue)
  }

  func startPeriodicSync() {
    guard syncTimer == nil else {
      logger.info("🔄 Periodic sync already running - timer exists")
      return
    }

    let intervalSeconds = syncInterval
    let prefsInterval = preferencesManager.syncIntervalSeconds
    logger.info(
      "🚀 Starting periodic sync every \(intervalSeconds) seconds (from preferences: \(prefsInterval))"
    )

    // Sync immediately
    Task {
      await performSync()
    }

    // Schedule periodic sync
    syncTimer = Timer.scheduledTimer(withTimeInterval: intervalSeconds, repeats: true) {
      [weak self] _ in
      Task { @MainActor in
        await self?.performSync()
      }
    }

    updateNextSyncTime()
    logger.info("✅ Periodic sync timer created and scheduled successfully")
  }

  func stopPeriodicSync() {
    syncTimer?.invalidate()
    syncTimer = nil
    nextSyncTime = nil
    logger.info("Stopped periodic sync")
  }

  func performSync() async {
    guard isOnline else {
      logger.info("Skipping sync - device is offline")
      syncStatus = .offline
      return
    }

    guard syncStatus != .syncing else {
      logger.info("Sync already in progress, skipping")
      return
    }

    syncStatus = .syncing
    logger.info("Starting calendar sync (attempt \(self.retryCount + 1))")

    do {
      // Get calendars from database
      let calendars = try await databaseManager.fetchCalendars()
      logger.info("Found \(calendars.count) calendars in database")

      let selectedCalendarIds = calendars.filter { $0.isSelected }.map { $0.id }
      logger.info("Selected calendar IDs: \(selectedCalendarIds)")

      guard !selectedCalendarIds.isEmpty else {
        logger.warning("No calendars selected for sync")
        // Log details about available calendars
        for calendar in calendars {
          logger.info(
            "Available calendar: \(calendar.name) (ID: \(calendar.id), Selected: \(calendar.isSelected))"
          )
        }
        syncStatus = .idle
        updateSyncTimes()
        resetRetryCount()
        return
      }

      // Calculate sync window
      let now = Date()
      let endDate = Calendar.current.date(byAdding: .day, value: eventLookAheadDays, to: now) ?? now

      logger.info(
        "📅 Syncing events from \(now) to \(endDate) (\(self.eventLookAheadDays) days ahead)")

      // Fetch events from API
      try await apiService.fetchEvents(
        for: selectedCalendarIds,
        from: now,
        to: endDate
      )

      let fetchedEvents = apiService.events
      logger.info("📥 API returned \(fetchedEvents.count) events")

      // Log details about fetched events for debugging
      for event in fetchedEvents.prefix(5) {  // Log first 5 events
        logger.info("📅 Event: '\(event.title)' at \(event.startDate)")
      }

      // Save events to database
      try await databaseManager.saveEvents(fetchedEvents)

      // Update calendar sync times
      for calendarId in selectedCalendarIds {
        try await databaseManager.updateCalendarSyncTime(calendarId)
      }

      syncStatus = .idle
      updateSyncTimes()
      resetRetryCount()

      logger.info("✅ Sync completed successfully. Synced \(fetchedEvents.count) events")

      // Notify completion callback
      await onSyncCompleted?()

    } catch {
      logger.error("Sync failed: \(error.localizedDescription)")

      // Check if it's a network-related error
      if isNetworkError(error) {
        await handleNetworkError(error)
      } else {
        syncStatus = .error(error.localizedDescription)
        resetRetryCount()
      }

      updateSyncTimes()
    }
  }

  private func isNetworkError(_ error: Error) -> Bool {
    // Check for common network error patterns
    let nsError = error as NSError

    return nsError.domain == NSURLErrorDomain || nsError.code == NSURLErrorNotConnectedToInternet
      || nsError.code == NSURLErrorTimedOut || nsError.code == NSURLErrorCannotConnectToHost
      || nsError.code == NSURLErrorNetworkConnectionLost
  }

  private func handleNetworkError(_ error: Error) async {
    guard retryCount < maxRetries else {
      logger.error("Max retries reached, giving up")
      syncStatus = .error("Network error after \(maxRetries) attempts")
      resetRetryCount()
      return
    }

    retryCount += 1
    let retryDelay = calculateRetryDelay()

    logger.info(
      "Network error occurred, retrying in \(retryDelay) seconds (attempt \(self.retryCount)/\(self.maxRetries))"
    )
    syncStatus = .error("Retrying in \(Int(retryDelay))s...")

    retryTimer?.invalidate()
    retryTimer = Timer.scheduledTimer(withTimeInterval: retryDelay, repeats: false) {
      [weak self] _ in
      Task { @MainActor in
        await self?.performSync()
      }
    }
  }

  private func calculateRetryDelay() -> TimeInterval {
    // Exponential backoff with jitter
    let exponentialDelay = baseRetryDelay * pow(2.0, Double(retryCount - 1))
    let jitter = Double.random(in: 0.8...1.2)  // ±20% jitter
    return min(exponentialDelay * jitter, 300.0)  // Cap at 5 minutes
  }

  private func resetRetryCount() {
    retryCount = 0
    retryTimer?.invalidate()
    retryTimer = nil
  }

  func syncCalendarList() async throws {
    logger.info("Syncing calendar list")

    try await apiService.fetchCalendars()

    // Convert API calendars to database models
    let dbCalendars = apiService.calendars.map { calendar in
      CalendarInfo(
        id: calendar.id,
        name: calendar.name,
        description: calendar.description,
        isSelected: calendar.isSelected,
        isPrimary: calendar.isPrimary,
        colorHex: calendar.colorHex,
        createdAt: Date(),
        updatedAt: Date()
      )
    }

    try await databaseManager.saveCalendars(dbCalendars)
    logger.info("Calendar list synced successfully")
  }

  private func updateSyncTimes() {
    lastSyncTime = Date()
    updateNextSyncTime()
  }

  private func updateNextSyncTime() {
    if syncTimer != nil {
      nextSyncTime = Date().addingTimeInterval(syncInterval)
    } else {
      nextSyncTime = nil
    }
  }

  // MARK: - Manual Operations

  func forceSyncNow() async {
    logger.info("Force sync requested")
    await performSync()
  }

  func refreshCalendarList() async throws {
    logger.info("Refresh calendar list requested")
    try await syncCalendarList()
  }

  // MARK: - Database Operations

  func getUpcomingEvents(limit: Int = 10) async throws -> [Event] {
    return try await databaseManager.fetchUpcomingEvents(limit: limit)
  }

  func getEventsInRange(from startDate: Date, to endDate: Date) async throws -> [Event] {
    return try await databaseManager.fetchEvents(from: startDate, to: endDate)
  }

  func searchEvents(query: String) async throws -> [Event] {
    return try await databaseManager.searchEvents(query: query)
  }

  func performDatabaseMaintenance() async {
    logger.info("Performing database maintenance")
    do {
      try await databaseManager.performMaintenance()
    } catch {
      logger.error("Database maintenance failed: \(error.localizedDescription)")
    }
  }
}
