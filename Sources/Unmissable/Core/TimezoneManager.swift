import Foundation
import OSLog

class TimezoneManager {
  private let logger = Logger(subsystem: "com.unmissable.app", category: "TimezoneManager")

  static let shared = TimezoneManager()

  private init() {}

  // MARK: - Timezone Conversion

  func convertToLocalTime(_ date: Date, from timezone: String) -> Date {
    guard let sourceTimezone = TimeZone(identifier: timezone) else {
      logger.warning("Invalid timezone identifier: \(timezone), using system timezone")
      return date
    }

    let localTimezone = TimeZone.current

    // Calculate the difference between source and local timezone
    let sourceOffset = sourceTimezone.secondsFromGMT(for: date)
    let localOffset = localTimezone.secondsFromGMT(for: date)
    let difference = localOffset - sourceOffset

    return date.addingTimeInterval(TimeInterval(difference))
  }

  func convertFromLocalTime(_ date: Date, to timezone: String) -> Date {
    guard let targetTimezone = TimeZone(identifier: timezone) else {
      logger.warning("Invalid timezone identifier: \(timezone), using system timezone")
      return date
    }

    let localTimezone = TimeZone.current

    // Calculate the difference between local and target timezone
    let localOffset = localTimezone.secondsFromGMT(for: date)
    let targetOffset = targetTimezone.secondsFromGMT(for: date)
    let difference = targetOffset - localOffset

    return date.addingTimeInterval(TimeInterval(difference))
  }

  // MARK: - Event Timezone Handling

  func localizedEvent(_ event: Event) -> Event {
    let localStartDate = convertToLocalTime(event.startDate, from: event.timezone)
    let localEndDate = convertToLocalTime(event.endDate, from: event.timezone)

    return Event(
      id: event.id,
      title: event.title,
      startDate: localStartDate,
      endDate: localEndDate,
      organizer: event.organizer,
      description: event.description,  // ✅ FIX: Copy description
      location: event.location,        // ✅ FIX: Copy location
      attendees: event.attendees,      // ✅ FIX: Copy attendees
      isAllDay: event.isAllDay,
      calendarId: event.calendarId,
      timezone: TimeZone.current.identifier,  // Convert to local timezone
      links: event.links,
      provider: event.provider,
      snoozeUntil: event.snoozeUntil,
      autoJoinEnabled: event.autoJoinEnabled,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt
    )
  }

  // MARK: - Alert Timing

  func calculateAlertTime(for event: Event, minutesBefore: Int) -> Date {
    let alertDate = event.startDate.addingTimeInterval(-TimeInterval(minutesBefore * 60))
    return convertToLocalTime(alertDate, from: event.timezone)
  }

  func timeUntilEvent(_ event: Event) -> TimeInterval {
    let localStartTime = convertToLocalTime(event.startDate, from: event.timezone)
    return localStartTime.timeIntervalSinceNow
  }

  func isEventStartingSoon(_ event: Event, within minutes: Int) -> Bool {
    let timeUntil = timeUntilEvent(event)
    let threshold = TimeInterval(minutes * 60)
    return timeUntil > 0 && timeUntil <= threshold
  }

  // MARK: - Timezone Information

  func getTimezoneDisplayName(_ timezone: String) -> String {
    guard let tz = TimeZone(identifier: timezone) else {
      return timezone
    }

    let formatter = DateFormatter()
    formatter.timeZone = tz
    return tz.localizedName(for: .shortStandard, locale: .current) ?? timezone
  }

  func getCurrentTimezoneOffset() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "Z"
    return formatter.string(from: Date())
  }

  // MARK: - Date Formatting

  func formatEventTime(_ event: Event, includeTimezone: Bool = false) -> String {
    let formatter = DateFormatter()

    if event.isAllDay {
      formatter.dateStyle = .medium
      formatter.timeStyle = .none
      return formatter.string(from: event.startDate)
    } else {
      formatter.dateStyle = .none
      formatter.timeStyle = .short

      if includeTimezone {
        formatter.timeZone = TimeZone(identifier: event.timezone)
        let timeString = formatter.string(from: event.startDate)
        let tzName = getTimezoneDisplayName(event.timezone)
        return "\(timeString) \(tzName)"
      } else {
        // Use local timezone for display
        let localStartDate = convertToLocalTime(event.startDate, from: event.timezone)
        return formatter.string(from: localStartDate)
      }
    }
  }

  func formatRelativeTime(to date: Date) -> String {
    let now = Date()
    let interval = date.timeIntervalSince(now)

    if interval < 0 {
      return "Past"
    }

    let minutes = Int(interval / 60)
    let hours = minutes / 60
    let days = hours / 24

    if minutes < 1 {
      return "Now"
    } else if minutes < 60 {
      return "\(minutes)m"
    } else if hours < 24 {
      return "\(hours)h"
    } else {
      return "\(days)d"
    }
  }

  // MARK: - System Timezone Changes

  func handleTimezoneChange() {
    logger.info("System timezone changed to: \(TimeZone.current.identifier)")

    // Post notification for other components to handle timezone change
    NotificationCenter.default.post(
      name: .NSSystemTimeZoneDidChange,
      object: nil
    )
  }
}

// MARK: - Notification Names

extension Notification.Name {
  static let timezoneChanged = Notification.Name("com.unmissable.timezoneChanged")
}
