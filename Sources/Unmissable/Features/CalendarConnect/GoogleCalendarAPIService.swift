import Foundation
import OSLog

@MainActor
class GoogleCalendarAPIService: ObservableObject {
  private let logger = Logger(subsystem: "com.unmissable.app", category: "GoogleCalendarAPIService")
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

      var request = URLRequest(url: url)
      request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
      request.setValue("application/json", forHTTPHeaderField: "Accept")

      let (data, response) = try await URLSession.shared.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse else {
        throw GoogleCalendarAPIError.invalidResponse
      }

      guard httpResponse.statusCode == 200 else {
        let errorMessage = "HTTP \(httpResponse.statusCode)"
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
    logger.info("Fetching events for \(calendarIds.count) calendars")
    isLoading = true
    lastError = nil

    defer { isLoading = false }

    do {
      var allEvents: [Event] = []

      for calendarId in calendarIds {
        let calendarEvents = try await fetchEventsForCalendar(
          calendarId: calendarId,
          startDate: startDate,
          endDate: endDate
        )
        allEvents.append(contentsOf: calendarEvents)
      }

      // Sort events by start date
      allEvents.sort { $0.startDate < $1.startDate }
      events = allEvents

      logger.info("Successfully fetched \(allEvents.count) events")

    } catch {
      logger.error("Failed to fetch events: \(error.localizedDescription)")
      lastError = error.localizedDescription
      throw error
    }
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
      let errorMessage = "HTTP \(httpResponse.statusCode)"
      logger.error("Events fetch failed for calendar \(calendarId): \(errorMessage)")
      throw GoogleCalendarAPIError.requestFailed(httpResponse.statusCode, errorMessage)
    }

    return try parseEventList(from: data, calendarId: calendarId)
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

  private func parseEventList(from data: Data, calendarId: String) throws -> [Event] {
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    guard let items = json?["items"] as? [[String: Any]] else {
      throw GoogleCalendarAPIError.parseError
    }

    return items.compactMap { item in
      parseEvent(from: item, calendarId: calendarId)
    }
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
      isAllDay: isAllDay,
      calendarId: calendarId,
      timezone: timezone,
      links: links,
      provider: provider
    )
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
