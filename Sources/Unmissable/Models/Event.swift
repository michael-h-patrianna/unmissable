import Foundation

struct Event: Identifiable, Codable, Equatable {
  let id: String
  let title: String
  let startDate: Date
  let endDate: Date
  let organizer: String?
  let isAllDay: Bool
  let calendarId: String
  let timezone: String
  let links: [URL]
  let provider: Provider?
  let snoozeUntil: Date?
  let autoJoinEnabled: Bool
  let createdAt: Date
  let updatedAt: Date

  init(
    id: String,
    title: String,
    startDate: Date,
    endDate: Date,
    organizer: String? = nil,
    isAllDay: Bool = false,
    calendarId: String,
    timezone: String = TimeZone.current.identifier,
    links: [URL] = [],
    provider: Provider? = nil,
    snoozeUntil: Date? = nil,
    autoJoinEnabled: Bool = false,
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) {
    self.id = id
    self.title = title
    self.startDate = startDate
    self.endDate = endDate
    self.organizer = organizer
    self.isAllDay = isAllDay
    self.calendarId = calendarId
    self.timezone = timezone
    self.links = links
    self.provider = provider ?? (links.first.map { Provider.detect(from: $0) })
    self.snoozeUntil = snoozeUntil
    self.autoJoinEnabled = autoJoinEnabled
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  var duration: TimeInterval {
    endDate.timeIntervalSince(startDate)
  }

  var primaryLink: URL? {
    links.first
  }

  var isOnlineMeeting: Bool {
    !links.isEmpty
  }

  var localStartDate: Date {
    let timeZone = TimeZone(identifier: timezone) ?? TimeZone.current
    let offset = timeZone.secondsFromGMT(for: startDate)
    return startDate.addingTimeInterval(TimeInterval(offset))
  }

  var localEndDate: Date {
    let timeZone = TimeZone(identifier: timezone) ?? TimeZone.current
    let offset = timeZone.secondsFromGMT(for: endDate)
    return endDate.addingTimeInterval(TimeInterval(offset))
  }

  // Helper method to create event with parsed Google Meet links
  static func withParsedLinks(
    id: String,
    title: String,
    startDate: Date,
    endDate: Date,
    organizer: String? = nil,
    isAllDay: Bool = false,
    calendarId: String,
    timezone: String = TimeZone.current.identifier,
    description: String? = nil,
    location: String? = nil,
    snoozeUntil: Date? = nil,
    autoJoinEnabled: Bool = false,
    createdAt: Date = Date(),
    updatedAt: Date = Date()
  ) -> Event {
    let parser = LinkParser.shared
    var allText = title

    if let description = description {
      allText += " \(description)"
    }

    if let location = location {
      allText += " \(location)"
    }

    let googleMeetLinks = parser.extractGoogleMeetLinks(from: allText)
    let provider = googleMeetLinks.first.map { Provider.detect(from: $0) }

    return Event(
      id: id,
      title: title,
      startDate: startDate,
      endDate: endDate,
      organizer: organizer,
      isAllDay: isAllDay,
      calendarId: calendarId,
      timezone: timezone,
      links: googleMeetLinks,
      provider: provider,
      snoozeUntil: snoozeUntil,
      autoJoinEnabled: autoJoinEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }
}
