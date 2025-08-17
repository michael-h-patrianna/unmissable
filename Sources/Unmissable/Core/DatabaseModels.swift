import Foundation
import GRDB

extension Event: FetchableRecord, PersistableRecord {
  static let databaseTableName = "events"

  enum Columns {
    static let id = Column("id")
    static let title = Column("title")
    static let startDate = Column("startDate")
    static let endDate = Column("endDate")
    static let organizer = Column("organizer")
    static let description = Column("description")
    static let location = Column("location")
    static let attendees = Column("attendees")
    static let isAllDay = Column("isAllDay")
    static let calendarId = Column("calendarId")
    static let timezone = Column("timezone")
    static let links = Column("links")
    static let provider = Column("provider")
    static let snoozeUntil = Column("snoozeUntil")
    static let autoJoinEnabled = Column("autoJoinEnabled")
    static let createdAt = Column("createdAt")
    static let updatedAt = Column("updatedAt")
  }

  init(row: Row) {
    id = row[Columns.id]
    title = row[Columns.title]
    startDate = row[Columns.startDate]
    endDate = row[Columns.endDate]
    organizer = row[Columns.organizer]
    description = row[Columns.description]
    location = row[Columns.location]

    // Decode attendees from JSON string
    let attendeesData = row[Columns.attendees] as? String ?? "[]"
    if let data = attendeesData.data(using: .utf8),
      let decodedAttendees = try? JSONDecoder().decode([Attendee].self, from: data)
    {
      attendees = decodedAttendees
    } else {
      attendees = []
    }

    isAllDay = row[Columns.isAllDay]
    calendarId = row[Columns.calendarId]
    timezone = row[Columns.timezone]

    // Decode URLs from JSON string
    let linksData = row[Columns.links] as? String ?? "[]"
    if let data = linksData.data(using: .utf8),
      let urlStrings = try? JSONDecoder().decode([String].self, from: data)
    {
      links = urlStrings.compactMap { URL(string: $0) }
    } else {
      links = []
    }

    // Decode provider
    if let providerRawValue = row[Columns.provider] as? String {
      provider = Provider(rawValue: providerRawValue)
    } else {
      provider = nil
    }

    snoozeUntil = row[Columns.snoozeUntil]
    autoJoinEnabled = row[Columns.autoJoinEnabled]
    createdAt = row[Columns.createdAt]
    updatedAt = row[Columns.updatedAt]
  }

  func encode(to container: inout PersistenceContainer) {
    container[Columns.id] = id
    container[Columns.title] = title
    container[Columns.startDate] = startDate
    container[Columns.endDate] = endDate
    container[Columns.organizer] = organizer
    container[Columns.description] = description
    container[Columns.location] = location

    // Encode attendees as JSON string
    if let data = try? JSONEncoder().encode(attendees),
      let jsonString = String(data: data, encoding: .utf8)
    {
      container[Columns.attendees] = jsonString
    } else {
      container[Columns.attendees] = "[]"
    }

    container[Columns.isAllDay] = isAllDay
    container[Columns.calendarId] = calendarId
    container[Columns.timezone] = timezone

    // Encode URLs as JSON string
    let urlStrings = links.map { $0.absoluteString }
    if let data = try? JSONEncoder().encode(urlStrings),
      let jsonString = String(data: data, encoding: .utf8)
    {
      container[Columns.links] = jsonString
    } else {
      container[Columns.links] = "[]"
    }

    container[Columns.provider] = provider?.rawValue
    container[Columns.snoozeUntil] = snoozeUntil
    container[Columns.autoJoinEnabled] = autoJoinEnabled
    container[Columns.createdAt] = createdAt
    container[Columns.updatedAt] = updatedAt
  }
}

extension CalendarInfo: FetchableRecord, PersistableRecord {
  static let databaseTableName = "calendars"

  enum Columns {
    static let id = Column("id")
    static let name = Column("name")
    static let description = Column("description")
    static let isSelected = Column("isSelected")
    static let isPrimary = Column("isPrimary")
    static let colorHex = Column("colorHex")
    static let lastSyncAt = Column("lastSyncAt")
    static let createdAt = Column("createdAt")
    static let updatedAt = Column("updatedAt")
  }

  init(row: Row) {
    id = row[Columns.id]
    name = row[Columns.name]
    description = row[Columns.description]
    isSelected = row[Columns.isSelected]
    isPrimary = row[Columns.isPrimary]
    colorHex = row[Columns.colorHex]
    lastSyncAt = row[Columns.lastSyncAt]
    createdAt = row[Columns.createdAt]
    updatedAt = row[Columns.updatedAt]
  }

  func encode(to container: inout PersistenceContainer) {
    container[Columns.id] = id
    container[Columns.name] = name
    container[Columns.description] = description
    container[Columns.isSelected] = isSelected
    container[Columns.isPrimary] = isPrimary
    container[Columns.colorHex] = colorHex
    container[Columns.lastSyncAt] = lastSyncAt
    container[Columns.createdAt] = createdAt
    container[Columns.updatedAt] = updatedAt
  }
}
