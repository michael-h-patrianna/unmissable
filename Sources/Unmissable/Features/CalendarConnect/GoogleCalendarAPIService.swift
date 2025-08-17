import Foundation
import OSLog

@MainActor
class GoogleCalendarAPIService: ObservableObject {
  private let logger = Logger(subsystem: "com.unmissable.app", category: "GoogleCalendarAPIService")
  private let debugLogger = DebugLogger(subsystem: "com.unmissable.app", category: "GoogleCalendarAPIService")
  private let oauth2Service: OAuth2Service

  @Published var calendars: [CalendarInfo] = []
  @Published var events: [Event] = []
  @Published var isLoading = false
  @Published var lastError: String?

  init(oauth2Service: OAuth2Service) {
    self.oauth2Service = oauth2Service
  }

  // MARK: - Calendar Operations

  func fetchCalendars() async throws {
    logger.info("Fetching calendar list")
    isLoading = true
    lastError = nil

    defer { isLoading = false }

    do {
      let accessToken = try await oauth2Service.getValidAccessToken()
      let url = URL(string: "\(GoogleCalendarConfig.calendarAPIBaseURL)/users/me/calendarList")!

      logger.info("Making request to: \(url.absoluteString)")

      var request = URLRequest(url: url)
      request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
      request.setValue("application/json", forHTTPHeaderField: "Accept")

      // Log first and last few characters of token for debugging
      let tokenPreview = "\(accessToken.prefix(10))...\(accessToken.suffix(10))"
      logger.info("Using access token: \(tokenPreview)")

      let (data, response) = try await URLSession.shared.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse else {
        throw GoogleCalendarAPIError.invalidResponse
      }

      logger.info("Response status code: \(httpResponse.statusCode)")

      guard httpResponse.statusCode == 200 else {
        let errorMessage = "HTTP \(httpResponse.statusCode)"
        if httpResponse.statusCode == 404 {
          logger.error(
            "Calendar list fetch failed: 404 - Check API is enabled and correct endpoint")
          logger.error("Request URL: \(url)")
          // Try to get error details from response body
          if let errorBody = String(data: data, encoding: .utf8) {
            logger.error("Error response body: \(errorBody)")
          }
        }
        logger.error("Calendar list fetch failed: \(errorMessage)")
        throw GoogleCalendarAPIError.requestFailed(httpResponse.statusCode, errorMessage)
      }

      let calendarList = try parseCalendarList(from: data)
      calendars = calendarList

      logger.info("Successfully fetched \(calendarList.count) calendars")

    } catch {
      logger.error("Failed to fetch calendars: \(error.localizedDescription)")
      lastError = error.localizedDescription
      throw error
    }
  }

  func fetchEvents(for calendarIds: [String], from startDate: Date, to endDate: Date) async throws {
    debugLogger.info("🌐 API: fetchEvents called for \(calendarIds.count) calendars")
    
    logger.info("Fetching events for \(calendarIds.count) calendars")
    isLoading = true
    lastError = nil

    defer { isLoading = false }

    var allEvents: [Event] = []
    var successfulCalendars = 0
    var skippedCalendars = 0

    for calendarId in calendarIds {
      do {
        let calendarEvents = try await fetchEventsForCalendar(
          calendarId: calendarId,
          startDate: startDate,
          endDate: endDate
        )
        allEvents.append(contentsOf: calendarEvents)
        successfulCalendars += 1
        logger.info(
          "Successfully fetched \(calendarEvents.count) events from calendar \(calendarId)")
      } catch {
        skippedCalendars += 1
        logger.warning(
          "Skipping calendar \(calendarId) due to error: \(error.localizedDescription)")
        // Continue with other calendars instead of failing completely
      }
    }

    // Sort events by start date
    allEvents.sort { $0.startDate < $1.startDate }
    events = allEvents

    logger.info(
      "Successfully fetched \(allEvents.count) events from \(successfulCalendars) calendars (\(skippedCalendars) skipped)"
    )
  }

  // MARK: - Private Methods

  private func fetchEventsForCalendar(calendarId: String, startDate: Date, endDate: Date)
    async throws -> [Event]
  {
    let accessToken = try await oauth2Service.getValidAccessToken()

    let dateFormatter = ISO8601DateFormatter()
    let timeMin = dateFormatter.string(from: startDate)
    let timeMax = dateFormatter.string(from: endDate)

    let encodedCalendarId =
      calendarId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? calendarId

    var urlComponents = URLComponents(
      string: "\(GoogleCalendarConfig.calendarAPIBaseURL)/calendars/\(encodedCalendarId)/events")!
    urlComponents.queryItems = [
      URLQueryItem(name: "timeMin", value: timeMin),
      URLQueryItem(name: "timeMax", value: timeMax),
      URLQueryItem(name: "singleEvents", value: "true"),
      URLQueryItem(name: "orderBy", value: "startTime"),
      URLQueryItem(name: "maxResults", value: "250"),
      // CRITICAL: maxAttendees required to get attendee list (defaults to truncation without this)
      URLQueryItem(name: "maxAttendees", value: "100"),
      // Request comprehensive event fields including description and attendees
      URLQueryItem(
        name: "fields",
        value:
          "items(id,summary,start,end,organizer,description,location,attendees,hangoutLink,conferenceData),nextPageToken"
      ),
    ]

    guard let url = urlComponents.url else {
      throw GoogleCalendarAPIError.invalidURL
    }

    var request = URLRequest(url: url)
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw GoogleCalendarAPIError.invalidResponse
    }

    guard httpResponse.statusCode == 200 else {
      // Handle specific calendar access issues gracefully
      if httpResponse.statusCode == 404 {
        logger.warning("Calendar \(calendarId) not found or not accessible, skipping")
        return []  // Return empty array instead of throwing error
      } else if httpResponse.statusCode == 403 {
        logger.warning("Access denied to calendar \(calendarId), skipping")
        return []  // Return empty array instead of throwing error
      } else {
        let errorMessage = "HTTP \(httpResponse.statusCode)"
        logger.error("Events fetch failed for calendar \(calendarId): \(errorMessage)")
        throw GoogleCalendarAPIError.requestFailed(httpResponse.statusCode, errorMessage)
      }
    }

    let (events, _) = try parseEventList(from: data, calendarId: calendarId)
    return events
  }

  private func parseCalendarList(from data: Data) throws -> [CalendarInfo] {
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    guard let items = json?["items"] as? [[String: Any]] else {
      throw GoogleCalendarAPIError.parseError
    }

    return items.compactMap { item in
      guard let id = item["id"] as? String,
        let summary = item["summary"] as? String
      else {
        return nil
      }

      let description = item["description"] as? String
      let isPrimary = item["primary"] as? Bool ?? false
      let colorId = item["colorId"] as? String

      return CalendarInfo(
        id: id,
        name: summary,
        description: description,
        isSelected: isPrimary,  // Default to selecting primary calendar
        isPrimary: isPrimary,
        colorHex: colorId
      )
    }
  }

  private func parseEventList(from data: Data, calendarId: String) throws -> ([Event], String?) {
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    guard let items = json?["items"] as? [[String: Any]] else {
      throw GoogleCalendarAPIError.parseError
    }

    // LOG RAW API RESPONSE for first event to see what Google actually returns
    if let firstEvent = items.first {
      debugLogger.info("🔍 RAW API RESPONSE for first event:")
      debugLogger.info("   - ID: \(firstEvent["id"] as? String ?? "missing")")
      debugLogger.info("   - Summary: \(firstEvent["summary"] as? String ?? "missing")")
      debugLogger.info("   - Description in API: \(firstEvent["description"] != nil ? "YES" : "NO")")
      debugLogger.info("   - Location in API: \(firstEvent["location"] != nil ? "YES" : "NO")")
      debugLogger.info("   - Attendees in API: \(firstEvent["attendees"] != nil ? "YES" : "NO")")
      
      if let attendees = firstEvent["attendees"] as? [[String: Any]] {
        debugLogger.info("   - Attendees count: \(attendees.count)")
      }
    }

    let events = items.compactMap { item in
      parseEvent(from: item, calendarId: calendarId)
    }

    let nextPageToken = json?["nextPageToken"] as? String

    return (events, nextPageToken)
  }

  private func parseEvent(from item: [String: Any], calendarId: String) -> Event? {
    guard let id = item["id"] as? String,
      let summary = item["summary"] as? String,
      let start = item["start"] as? [String: Any],
      let end = item["end"] as? [String: Any]
    else {
      return nil
    }

    // Parse dates
    let dateFormatter = ISO8601DateFormatter()
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool

    if let dateTimeString = start["dateTime"] as? String {
      // Regular event with specific time
      guard let parsedStartDate = dateFormatter.date(from: dateTimeString) else { return nil }
      startDate = parsedStartDate
      isAllDay = false
    } else if let dateString = start["date"] as? String {
      // All-day event
      let dayFormatter = DateFormatter()
      dayFormatter.dateFormat = "yyyy-MM-dd"
      guard let parsedStartDate = dayFormatter.date(from: dateString) else { return nil }
      startDate = parsedStartDate
      isAllDay = true
    } else {
      return nil
    }

    if let dateTimeString = end["dateTime"] as? String {
      guard let parsedEndDate = dateFormatter.date(from: dateTimeString) else { return nil }
      endDate = parsedEndDate
    } else if let dateString = end["date"] as? String {
      let dayFormatter = DateFormatter()
      dayFormatter.dateFormat = "yyyy-MM-dd"
      guard let parsedEndDate = dayFormatter.date(from: dateString) else { return nil }
      endDate = parsedEndDate
    } else {
      return nil
    }

    // Parse organizer
    let organizer = (item["organizer"] as? [String: Any])?["email"] as? String

    // Parse description
    let description = item["description"] as? String
    if description != nil {
      debugLogger.info("✅ DESCRIPTION found for event: \(summary)")
    } else {
      debugLogger.info("❌ NO DESCRIPTION for event: \(summary)")
    }

    // Parse location
    let location = item["location"] as? String

    // Parse attendees
    let attendeesData = item["attendees"] as? [[String: Any]] ?? []
    let attendees = parseAttendees(from: attendeesData)
    if !attendees.isEmpty {
      debugLogger.info("✅ ATTENDEES found for event: \(summary) - count: \(attendees.count)")
    } else {
      debugLogger.info("❌ NO ATTENDEES for event: \(summary) - raw data: \(attendeesData.isEmpty ? "empty" : "present but unparseable")")
    }

    // Parse timezone
    let timezone = start["timeZone"] as? String ?? TimeZone.current.identifier

    // Parse meeting links
    let links = parseMeetingLinks(from: item)
    let provider = links.first.map { Provider.detect(from: $0) }

    return Event(
      id: id,
      title: summary,
      startDate: startDate,
      endDate: endDate,
      organizer: organizer,
      description: description,
      location: location,
      attendees: attendees,
      isAllDay: isAllDay,
      calendarId: calendarId,
      timezone: timezone,
      links: links,
      provider: provider
    )
  }

  private func parseAttendees(from attendeesData: [[String: Any]]) -> [Attendee] {
    return attendeesData.compactMap { attendeeData in
      guard let email = attendeeData["email"] as? String else {
        return nil
      }

      let displayName = attendeeData["displayName"] as? String
      let responseStatus = attendeeData["responseStatus"] as? String
      let status = AttendeeStatus(rawValue: responseStatus ?? "needsAction")
      let isOptional = attendeeData["optional"] as? Bool ?? false
      let isOrganizer = attendeeData["organizer"] as? Bool ?? false

      return Attendee(
        name: displayName,
        email: email,
        status: status,
        isOptional: isOptional,
        isOrganizer: isOrganizer
      )
    }
  }

  private func parseMeetingLinks(from item: [String: Any]) -> [URL] {
    var links: [URL] = []

    // Check location field
    if let location = item["location"] as? String,
      let url = extractURL(from: location)
    {
      links.append(url)
    }

    // Check description field
    if let description = item["description"] as? String {
      let urls = extractURLs(from: description)
      links.append(contentsOf: urls)
    }

    // Check conferenceData (Google Meet)
    if let conferenceData = item["conferenceData"] as? [String: Any],
      let entryPoints = conferenceData["entryPoints"] as? [[String: Any]]
    {

      for entryPoint in entryPoints {
        if let uri = entryPoint["uri"] as? String,
          let url = URL(string: uri)
        {
          links.append(url)
        }
      }
    }

    return Array(Set(links))  // Remove duplicates
  }

  private func extractURL(from text: String) -> URL? {
    let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    let matches = detector?.matches(
      in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

    return matches?.first?.url
  }

  private func extractURLs(from text: String) -> [URL] {
    let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    let matches = detector?.matches(
      in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

    return matches?.compactMap { $0.url } ?? []
  }
}

enum GoogleCalendarAPIError: LocalizedError {
  case invalidURL
  case invalidResponse
  case requestFailed(Int, String)
  case parseError

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid URL"
    case .invalidResponse:
      return "Invalid response"
    case .requestFailed(let code, let message):
      return "Request failed with code \(code): \(message)"
    case .parseError:
      return "Failed to parse response"
    }
  }
}
