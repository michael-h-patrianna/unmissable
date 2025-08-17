import XCTest

@testable import Unmissable

class AttendeeModelTests: XCTestCase {

  // MARK: - Basic Model Tests

  func testAttendeeInitialization() {
    let attendee = Attendee(
      name: "John Doe",
      email: "john@example.com",
      status: .accepted,
      isOptional: false,
      isOrganizer: true
    )

    XCTAssertEqual(attendee.name, "John Doe")
    XCTAssertEqual(attendee.email, "john@example.com")
    XCTAssertEqual(attendee.status, .accepted)
    XCTAssertFalse(attendee.isOptional)
    XCTAssertTrue(attendee.isOrganizer)
    XCTAssertEqual(attendee.displayName, "John Doe")
  }

  func testAttendeeWithoutName() {
    let attendee = Attendee(
      email: "noname@example.com",
      status: .needsAction
    )

    XCTAssertNil(attendee.name)
    XCTAssertEqual(attendee.email, "noname@example.com")
    XCTAssertEqual(attendee.status, .needsAction)
    XCTAssertFalse(attendee.isOptional)
    XCTAssertFalse(attendee.isOrganizer)
    XCTAssertEqual(attendee.displayName, "noname@example.com", "Should use email when name is nil")
  }

  func testAttendeeDefaultValues() {
    let attendee = Attendee(email: "default@example.com")

    XCTAssertNil(attendee.name)
    XCTAssertEqual(attendee.email, "default@example.com")
    XCTAssertNil(attendee.status)
    XCTAssertFalse(attendee.isOptional)
    XCTAssertFalse(attendee.isOrganizer)
  }

  // MARK: - AttendeeStatus Tests

  func testAttendeeStatusDisplayText() {
    XCTAssertEqual(AttendeeStatus.accepted.displayText, "Accepted")
    XCTAssertEqual(AttendeeStatus.declined.displayText, "Declined")
    XCTAssertEqual(AttendeeStatus.tentative.displayText, "Maybe")
    XCTAssertEqual(AttendeeStatus.needsAction.displayText, "Not responded")
  }

  func testAttendeeStatusIconNames() {
    XCTAssertEqual(AttendeeStatus.accepted.iconName, "checkmark.circle.fill")
    XCTAssertEqual(AttendeeStatus.declined.iconName, "xmark.circle")
    XCTAssertEqual(AttendeeStatus.tentative.iconName, "questionmark.circle.fill")
    XCTAssertEqual(AttendeeStatus.needsAction.iconName, "questionmark.circle")
  }

  func testAttendeeStatusRawValues() {
    XCTAssertEqual(AttendeeStatus.accepted.rawValue, "accepted")
    XCTAssertEqual(AttendeeStatus.declined.rawValue, "declined")
    XCTAssertEqual(AttendeeStatus.tentative.rawValue, "tentative")
    XCTAssertEqual(AttendeeStatus.needsAction.rawValue, "needsAction")
  }

  // MARK: - Codable Tests

  func testAttendeeCodableEncoding() throws {
    let attendee = Attendee(
      name: "Test User",
      email: "test@example.com",
      status: .accepted,
      isOptional: true,
      isOrganizer: false
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(attendee)

    XCTAssertNotNil(data)
    XCTAssertGreaterThan(data.count, 0)
  }

  func testAttendeeCodableDecoding() throws {
    let attendee = Attendee(
      name: "Test User",
      email: "test@example.com",
      status: .declined,
      isOptional: false,
      isOrganizer: true
    )

    let encoder = JSONEncoder()
    let data = try encoder.encode(attendee)

    let decoder = JSONDecoder()
    let decodedAttendee = try decoder.decode(Attendee.self, from: data)

    XCTAssertEqual(decodedAttendee.name, attendee.name)
    XCTAssertEqual(decodedAttendee.email, attendee.email)
    XCTAssertEqual(decodedAttendee.status, attendee.status)
    XCTAssertEqual(decodedAttendee.isOptional, attendee.isOptional)
    XCTAssertEqual(decodedAttendee.isOrganizer, attendee.isOrganizer)
    // Note: UUID ids will be different, but that's expected
  }

  func testAttendeeArrayCodable() throws {
    let attendees = [
      Attendee(name: "User 1", email: "user1@example.com", status: .accepted),
      Attendee(email: "user2@example.com", status: .tentative, isOptional: true),
      Attendee(name: "Organizer", email: "org@example.com", status: .accepted, isOrganizer: true),
    ]

    let encoder = JSONEncoder()
    let data = try encoder.encode(attendees)

    let decoder = JSONDecoder()
    let decodedAttendees = try decoder.decode([Attendee].self, from: data)

    XCTAssertEqual(decodedAttendees.count, attendees.count)

    for (original, decoded) in zip(attendees, decodedAttendees) {
      XCTAssertEqual(original.name, decoded.name)
      XCTAssertEqual(original.email, decoded.email)
      XCTAssertEqual(original.status, decoded.status)
      XCTAssertEqual(original.isOptional, decoded.isOptional)
      XCTAssertEqual(original.isOrganizer, decoded.isOrganizer)
    }
  }

  // MARK: - Edge Case Tests

  func testAttendeeWithEmptyEmail() {
    let attendee = Attendee(name: "No Email", email: "")

    XCTAssertEqual(attendee.email, "")
    XCTAssertEqual(attendee.displayName, "No Email", "Should use name when email is empty")
  }

  func testAttendeeWithVeryLongName() {
    let longName = String(repeating: "Very Long Name ", count: 100)
    let attendee = Attendee(name: longName, email: "long@example.com")

    XCTAssertEqual(attendee.name, longName)
    XCTAssertEqual(attendee.displayName, longName)
  }

  func testAttendeeWithSpecialCharacters() {
    let specialName = "José Müller-Schmidt 🎉"
    let specialEmail = "josé.müller+test@exämple-dömaın.cöm"

    let attendee = Attendee(name: specialName, email: specialEmail)

    XCTAssertEqual(attendee.name, specialName)
    XCTAssertEqual(attendee.email, specialEmail)
    XCTAssertEqual(attendee.displayName, specialName)
  }
}
