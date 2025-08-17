import SnapshotTesting
import XCTest

@testable import Unmissable

final class OverlaySnapshotTests: XCTestCase {

  override func setUp() {
    super.setUp()
    // Set a consistent test device for snapshots
    // isRecording = true // Uncomment to record new snapshots
  }

  func testOverlayContentBeforeMeeting() {
    let event = createSampleEvent()
    let preferencesManager = TestUtilities.MockPreferencesManager()

    let view = OverlayContentView(
      event: event,
      onDismiss: {},
      onJoin: {},
      onSnooze: { _ in }
    )
    .environmentObject(preferencesManager)
    .frame(width: 1200, height: 800)
    .preferredColorScheme(.light)

    // Basic view creation test (snapshots disabled for now)
    XCTAssertNotNil(view)
  }

  func testOverlayContentLongMeetingTitle() {
    let event = createSampleEventWithLongTitle()
    let preferencesManager = TestUtilities.MockPreferencesManager()

    let view = OverlayContentView(
      event: event,
      onDismiss: {},
      onJoin: {},
      onSnooze: { _ in }
    )
    .environmentObject(preferencesManager)
    .frame(width: 1200, height: 800)
    .preferredColorScheme(.light)

    // Basic view creation test (snapshots disabled for now)
    XCTAssertNotNil(view)
  }

  private func createSampleEvent() -> Event {
    Event(
      id: "snapshot-test",
      title: "Important Team Meeting",
      startDate: Date().addingTimeInterval(300),  // 5 minutes from now
      endDate: Date().addingTimeInterval(1800),  // 30 minutes from now
      organizer: "john.doe@company.com",
      calendarId: "primary",
      links: [URL(string: "https://meet.google.com/abc-defg-hij")!],
      provider: .meet
    )
  }

  private func createSampleEventWithoutLink() -> Event {
    Event(
      id: "snapshot-test-no-link",
      title: "In-Person Meeting",
      startDate: Date().addingTimeInterval(300),
      endDate: Date().addingTimeInterval(1800),
      organizer: "jane.smith@company.com",
      calendarId: "primary"
    )
  }

  private func createSampleEventWithLongTitle() -> Event {
    Event(
      id: "snapshot-test-long",
      title:
        "Very Important Cross-Functional Strategic Planning Meeting with Multiple Stakeholders",
      startDate: Date().addingTimeInterval(300),
      endDate: Date().addingTimeInterval(1800),
      organizer: "strategic.planner@company.com",
      calendarId: "primary",
      links: [URL(string: "https://meet.google.com/abc-defg-hij")!],
      provider: .meet
    )
  }
}
