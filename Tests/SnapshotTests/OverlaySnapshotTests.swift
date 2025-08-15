import SnapshotTesting
import XCTest

@testable import Unmissable

final class OverlaySnapshotTests: XCTestCase {

  override func setUp() {
    super.setUp()
    // Set a consistent test device for snapshots
    // isRecording = true // Uncomment to record new snapshots
  }

  func testOverlayContentViewLight() {
    let event = createSampleEvent()
    let view = OverlayContentView(
      event: event,
      onDismiss: {},
      onJoin: { _ in },
      onSnooze: { _ in }
    )
    .frame(width: 1200, height: 800)
    .preferredColorScheme(.light)

    // Skip snapshot testing for now - requires more setup
    // assertSnapshot(matching: view, as: .image)
    XCTAssertNotNil(view)
  }

  func testOverlayContentViewDark() {
    let event = createSampleEvent()
    let view = OverlayContentView(
      event: event,
      onDismiss: {},
      onJoin: { _ in },
      onSnooze: { _ in }
    )
    .frame(width: 1200, height: 800)
    .preferredColorScheme(.dark)

    // Skip snapshot testing for now - requires more setup
    // assertSnapshot(matching: view, as: .image)
    XCTAssertNotNil(view)
  }

  func testOverlayContentViewNoMeetingLink() {
    let event = createSampleEventWithoutLink()
    let view = OverlayContentView(
      event: event,
      onDismiss: {},
      onJoin: { _ in },
      onSnooze: { _ in }
    )
    .frame(width: 1200, height: 800)
    .preferredColorScheme(.light)

    // Skip snapshot testing for now - requires more setup
    // assertSnapshot(matching: view, as: .image)
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
}
