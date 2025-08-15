import XCTest

@testable import Unmissable

final class LinkParserTests: XCTestCase {

  var linkParser: LinkParser!

  override func setUp() {
    super.setUp()
    linkParser = LinkParser.shared
  }

  override func tearDown() {
    linkParser = nil
    super.tearDown()
  }

  func testGoogleMeetLinkExtraction() {
    let text = "Join the meeting at https://meet.google.com/abc-defg-hij"
    let links = linkParser.extractGoogleMeetLinks(from: text)

    XCTAssertEqual(links.count, 1)
    XCTAssertEqual(links.first?.absoluteString, "https://meet.google.com/abc-defg-hij")
  }

  func testGoogleMeetIDExtraction() {
    let url = URL(string: "https://meet.google.com/abc-defg-hij")!
    let meetingId = linkParser.extractGoogleMeetID(from: url)

    XCTAssertEqual(meetingId, "abc-defg-hij")
  }

  func testGoogleMeetDetection() {
    let meetUrl = URL(string: "https://meet.google.com/test-room")!
    let regularUrl = URL(string: "https://example.com")!

    XCTAssertTrue(linkParser.isGoogleMeetURL(meetUrl))
    XCTAssertFalse(linkParser.isGoogleMeetURL(regularUrl))
  }

  func testMultipleGoogleMeetLinks() {
    let text = """
      Main meeting: https://meet.google.com/abc-defg-hij
      Backup: https://meet.google.com/xyz-uvwx-stu
      Regular link: https://example.com
      """
    let links = linkParser.extractGoogleMeetLinks(from: text)

    XCTAssertEqual(links.count, 2)
    XCTAssertTrue(links.contains { $0.absoluteString.contains("abc-defg-hij") })
    XCTAssertTrue(links.contains { $0.absoluteString.contains("xyz-uvwx-stu") })
  }

  func testNoGoogleMeetLinks() {
    let text = "This is a regular text with https://example.com and no meeting links"
    let links = linkParser.extractGoogleMeetLinks(from: text)

    XCTAssertEqual(links.count, 0)
  }

  func testDuplicateGoogleMeetLinks() {
    let text = """
      https://meet.google.com/abc-defg-hij
      Join at https://meet.google.com/abc-defg-hij
      """
    let links = linkParser.extractGoogleMeetLinks(from: text)

    XCTAssertEqual(links.count, 1)
  }

  @MainActor
  func testEventWithParsedGoogleMeetLinks() async {
    let event = Event.withParsedLinks(
      id: "test",
      title: "Team Meeting",
      startDate: Date(),
      endDate: Date().addingTimeInterval(3600),
      calendarId: "primary",
      description: "Join us at https://meet.google.com/abc-defg-hij",
      location: "Google Meet"
    )

    XCTAssertTrue(event.isOnlineMeeting)
    XCTAssertEqual(event.links.count, 1)
    XCTAssertEqual(event.provider, .meet)
    XCTAssertEqual(event.primaryLink?.absoluteString, "https://meet.google.com/abc-defg-hij")
  }
}
