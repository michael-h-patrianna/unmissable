import SnapshotTesting
import SwiftUI
import XCTest

@testable import Unmissable

final class OverlaySnapshotTests: XCTestCase {

  override func setUp() {
    super.setUp()
    // Use consistent device for snapshot testing
    isRecording = false
  }

  func testOverlayContentBeforeMeeting() {
    let event = Event(
      id: "test-before",
      title: "Team Standup Meeting",
      startDate: Date().addingTimeInterval(300),  // 5 minutes from now
      endDate: Date().addingTimeInterval(1800),
      organizer: "john.doe@company.com",
      calendarId: "primary",
      links: [URL(string: "https://meet.google.com/abc-defg-hij")!]
    )

    let overlayView = OverlayContentView(
      event: event,
      onDismiss: {},
      onJoin: {},
      onSnooze: { _ in }
    )

    let hostingController = NSHostingController(rootView: overlayView)
    hostingController.view.frame = CGRect(x: 0, y: 0, width: 1200, height: 800)

    assertSnapshot(matching: hostingController, as: .image, named: "overlay-before-meeting")
  }

  func testOverlayContentMeetingStarted() {
    let event = Event(
      id: "test-started",
      title: "Important Client Call - Q3 Review",
      startDate: Date().addingTimeInterval(-120),  // Started 2 minutes ago
      endDate: Date().addingTimeInterval(1800),
      organizer: "client@external.com",
      calendarId: "primary",
      links: [URL(string: "https://meet.google.com/xyz-urgent-call")!]
    )

    let overlayView = OverlayContentView(
      event: event,
      onDismiss: {},
      onJoin: {},
      onSnooze: { _ in }
    )

    let hostingController = NSHostingController(rootView: overlayView)
    hostingController.view.frame = CGRect(x: 0, y: 0, width: 1200, height: 800)

    assertSnapshot(matching: hostingController, as: .image, named: "overlay-meeting-started")
  }

  func testOverlayContentLongMeetingTitle() {
    let event = Event(
      id: "test-long-title",
      title:
        "Quarterly Business Review with External Partners and Stakeholders - Strategic Planning Session for 2025 Roadmap",
      startDate: Date().addingTimeInterval(60),  // 1 minute from now
      endDate: Date().addingTimeInterval(3600),
      organizer: "stakeholder@partner.com",
      calendarId: "primary",
      links: [URL(string: "https://meet.google.com/long-title-meeting")!]
    )

    let overlayView = OverlayContentView(
      event: event,
      onDismiss: {},
      onJoin: {},
      onSnooze: { _ in }
    )

    let hostingController = NSHostingController(rootView: overlayView)
    hostingController.view.frame = CGRect(x: 0, y: 0, width: 1200, height: 800)

    assertSnapshot(matching: hostingController, as: .image, named: "overlay-long-title")
  }

  func testOverlayContentNoMeetingLink() {
    let event = Event(
      id: "test-no-link",
      title: "In-Person Meeting",
      startDate: Date().addingTimeInterval(600),  // 10 minutes from now
      endDate: Date().addingTimeInterval(2400),
      organizer: "manager@company.com",
      calendarId: "primary",
      links: []
    )

    let overlayView = OverlayContentView(
      event: event,
      onDismiss: {},
      onJoin: {},
      onSnooze: { _ in }
    )

    let hostingController = NSHostingController(rootView: overlayView)
    hostingController.view.frame = CGRect(x: 0, y: 0, width: 1200, height: 800)

    assertSnapshot(matching: hostingController, as: .image, named: "overlay-no-link")
  }

  func testOverlayContentUrgentMeeting() {
    let event = Event(
      id: "test-urgent",
      title: "URGENT: Production Issue",
      startDate: Date().addingTimeInterval(30),  // 30 seconds from now
      endDate: Date().addingTimeInterval(1800),
      organizer: "oncall@company.com",
      calendarId: "primary",
      links: [URL(string: "https://meet.google.com/urgent-production")!]
    )

    let overlayView = OverlayContentView(
      event: event,
      onDismiss: {},
      onJoin: {},
      onSnooze: { _ in }
    )

    let hostingController = NSHostingController(rootView: overlayView)
    hostingController.view.frame = CGRect(x: 0, y: 0, width: 1200, height: 800)

    assertSnapshot(matching: hostingController, as: .image, named: "overlay-urgent-meeting")
  }

  @MainActor
  func testOverlayManagerShowHide() {
    let overlayManager = OverlayManager()
    let event = Event(
      id: "test-manager",
      title: "Test Meeting",
      startDate: Date().addingTimeInterval(300),
      endDate: Date().addingTimeInterval(1800),
      calendarId: "primary",
      links: [URL(string: "https://meet.google.com/test")!]
    )

    XCTAssertFalse(overlayManager.isOverlayVisible)
    XCTAssertNil(overlayManager.activeEvent)

    overlayManager.showOverlay(for: event)

    XCTAssertTrue(overlayManager.isOverlayVisible)
    XCTAssertEqual(overlayManager.activeEvent?.id, event.id)

    overlayManager.hideOverlay()

    XCTAssertFalse(overlayManager.isOverlayVisible)
    XCTAssertNil(overlayManager.activeEvent)
  }

  @MainActor
  func testOverlayManagerSnooze() {
    let overlayManager = OverlayManager()
    let event = Event(
      id: "test-snooze",
      title: "Snooze Test Meeting",
      startDate: Date().addingTimeInterval(300),
      endDate: Date().addingTimeInterval(1800),
      calendarId: "primary",
      links: [URL(string: "https://meet.google.com/snooze-test")!]
    )

    overlayManager.showOverlay(for: event)
    XCTAssertTrue(overlayManager.isOverlayVisible)

    overlayManager.snoozeOverlay(for: 5)
    XCTAssertFalse(overlayManager.isOverlayVisible)
  }

  @MainActor
  func testOverlayManagerScheduling() {
    let overlayManager = OverlayManager()
    let futureEvent = Event(
      id: "test-schedule",
      title: "Future Meeting",
      startDate: Date().addingTimeInterval(3600),  // 1 hour from now
      endDate: Date().addingTimeInterval(5400),
      calendarId: "primary",
      links: [URL(string: "https://meet.google.com/future")!]
    )

    // This should schedule without immediate display
    overlayManager.scheduleOverlay(for: futureEvent, minutesBeforeMeeting: 5)
    XCTAssertFalse(overlayManager.isOverlayVisible)

    // Test with event too soon to schedule
    let immediateEvent = Event(
      id: "test-immediate",
      title: "Immediate Meeting",
      startDate: Date().addingTimeInterval(60),  // 1 minute from now
      endDate: Date().addingTimeInterval(1860),
      calendarId: "primary",
      links: [URL(string: "https://meet.google.com/immediate")!]
    )

    overlayManager.scheduleOverlay(for: immediateEvent, minutesBeforeMeeting: 5)
    // Should not schedule since it's less than 5 minutes away
    XCTAssertFalse(overlayManager.isOverlayVisible)
  }
}
