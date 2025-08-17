import Foundation

struct Attendee: Identifiable, Codable, Equatable {
  let id: UUID
  let name: String?
  let email: String
  let status: AttendeeStatus?
  let isOptional: Bool
  let isOrganizer: Bool

  init(
    name: String? = nil,
    email: String,
    status: AttendeeStatus? = nil,
    isOptional: Bool = false,
    isOrganizer: Bool = false
  ) {
    self.id = UUID()
    self.name = name
    self.email = email
    self.status = status
    self.isOptional = isOptional
    self.isOrganizer = isOrganizer
  }

  var displayName: String {
    name ?? email
  }
}

enum AttendeeStatus: String, Codable, CaseIterable {
  case needsAction = "needsAction"
  case declined = "declined"
  case tentative = "tentative"
  case accepted = "accepted"

  var displayText: String {
    switch self {
    case .needsAction:
      return "Not responded"
    case .declined:
      return "Declined"
    case .tentative:
      return "Maybe"
    case .accepted:
      return "Accepted"
    }
  }

  var iconName: String {
    switch self {
    case .needsAction:
      return "questionmark.circle"
    case .declined:
      return "xmark.circle"
    case .tentative:
      return "questionmark.circle.fill"
    case .accepted:
      return "checkmark.circle.fill"
    }
  }
}
