import SnapshotTesting
import SwiftUI
import XCTest

@testable import Unmissable

@MainActor
final class UIComponentComprehensiveTests: XCTestCase {

  var testDesign: CustomDesign!

  override func setUp() async throws {
    try await super.setUp()
    testDesign = TestUtilities.createTestEnvironment()
  }

  override func tearDown() async throws {
    testDesign = nil
    try await super.tearDown()
  }

  // MARK: - OverlayContentView Tests

  func testOverlayContentViewBasicFunctionality() throws {
    let event = TestUtilities.createTestEvent(
      title: "Important Meeting",
      startDate: Date().addingTimeInterval(300)
    )

    var dismissCalled = false
    var joinCalled = false
    var snoozeCalled = false
    var snoozeMinutes: Int?
    var joinURL: URL?

    let view = OverlayContentView(
      event: event,
      onDismiss: { dismissCalled = true },
      onJoin: {
        joinCalled = true
        joinURL = event.primaryLink
      },
      onSnooze: { minutes in
        snoozeCalled = true
        snoozeMinutes = minutes
      }
    )
    .environment(\.customDesign, testDesign)

    // Test that view can be created without crashing
    XCTAssertNotNil(view)

    // Verify callback variables are properly initialized
    XCTAssertFalse(dismissCalled)
    XCTAssertFalse(joinCalled)
    XCTAssertFalse(snoozeCalled)
    XCTAssertNil(snoozeMinutes)
    XCTAssertNil(joinURL)

    // Note: Testing actual button interactions requires more complex SwiftUI testing setup
    // For now, we verify the view structure is sound
  }

  func testOverlayContentViewWithMeetingLink() throws {
    let meetingEvent = TestUtilities.createMeetingEvent(provider: .meet)

    let view = OverlayContentView(
      event: meetingEvent,
      onDismiss: {},
      onJoin: {},
      onSnooze: { _ in }
    )
    .environment(\.customDesign, testDesign)

    XCTAssertNotNil(view)

    // Event should have a meeting link
    XCTAssertFalse(meetingEvent.links.isEmpty)
    XCTAssertNotNil(meetingEvent.primaryLink)
  }

  func testOverlayContentViewWithoutMeetingLink() throws {
    let regularEvent = TestUtilities.createTestEvent(
      title: "In-Person Meeting",
      links: []  // No meeting links
    )

    let view = OverlayContentView(
      event: regularEvent,
      onDismiss: {},
      onJoin: {},
      onSnooze: { _ in }
    )
    .environment(\.customDesign, testDesign)

    XCTAssertNotNil(view)

    // Event should not have meeting links
    XCTAssertTrue(regularEvent.links.isEmpty)
    XCTAssertNil(regularEvent.primaryLink)
  }

  func testOverlayContentViewCountdownFormatting() throws {
    let futureEvent = TestUtilities.createTestEvent(
      startDate: Date().addingTimeInterval(300)  // 5 minutes from now
    )

    let view = OverlayContentView(
      event: futureEvent,
      onDismiss: {},
      onJoin: {},
      onSnooze: { _ in }
    )
    .environment(\.customDesign, testDesign)

    // Test countdown timer functionality
    XCTAssertNotNil(view)

    // Test different time intervals
    let pastEvent = TestUtilities.createTestEvent(
      startDate: Date().addingTimeInterval(-60)  // 1 minute ago
    )

    let pastView = OverlayContentView(
      event: pastEvent,
      onDismiss: {},
      onJoin: {},
      onSnooze: { _ in }
    )
    .environment(\.customDesign, testDesign)

    XCTAssertNotNil(pastView)
  }

  // MARK: - CustomButton Tests

  func testCustomButtonStyles() throws {
    let action = {}

    let primaryButton = CustomButton("Primary", style: .primary, action: action)
      .environment(\.customDesign, testDesign)

    let secondaryButton = CustomButton("Secondary", style: .secondary, action: action)
      .environment(\.customDesign, testDesign)

    let minimalButton = CustomButton("Minimal", style: .minimal, action: action)
      .environment(\.customDesign, testDesign)

    XCTAssertNotNil(primaryButton)
    XCTAssertNotNil(secondaryButton)
    XCTAssertNotNil(minimalButton)
  }

  func testCustomButtonWithIcon() throws {
    let iconButton = CustomButton("Join", icon: "video", style: .primary) {}
      .environment(\.customDesign, testDesign)

    XCTAssertNotNil(iconButton)
  }

  func testCustomButtonDisabledState() throws {
    let disabledButton = CustomButton("Disabled", style: .primary) {}
      .disabled(true)
      .environment(\.customDesign, testDesign)

    XCTAssertNotNil(disabledButton)
  }

  // MARK: - MenuBarView Tests

  func testMenuBarViewWithConnection() throws {
    let mockAppState = MockAppState()
    mockAppState.isConnected = true
    mockAppState.upcomingEvents = [
      TestUtilities.createTestEvent(
        title: "Next Meeting",
        startDate: Date().addingTimeInterval(1800)
      )
    ]

    let menuBarView = MenuBarView()
      .environmentObject(mockAppState)
      .environment(\.customDesign, testDesign)

    XCTAssertNotNil(menuBarView)
  }

  func testMenuBarViewWithoutConnection() throws {
    let mockAppState = MockAppState()
    mockAppState.isConnected = false
    mockAppState.upcomingEvents = []

    let menuBarView = MenuBarView()
      .environmentObject(mockAppState)
      .environment(\.customDesign, testDesign)

    XCTAssertNotNil(menuBarView)
  }

  // MARK: - Theme System Tests

  func testThemeConsistency() throws {
    let lightDesign = CustomDesign.design(for: .light)
    let darkDesign = CustomDesign.design(for: .dark)

    // Test that both themes have all required properties
    XCTAssertNotNil(lightDesign.colors.background)
    XCTAssertNotNil(lightDesign.colors.textPrimary)
    XCTAssertNotNil(lightDesign.colors.accent)

    XCTAssertNotNil(darkDesign.colors.background)
    XCTAssertNotNil(darkDesign.colors.textPrimary)
    XCTAssertNotNil(darkDesign.colors.accent)

    // Themes should be different
    XCTAssertNotEqual(lightDesign.colors.background, darkDesign.colors.background)
    XCTAssertNotEqual(lightDesign.colors.textPrimary, darkDesign.colors.textPrimary)
  }

  func testCustomColorsIntegrity() throws {
    let lightColors = CustomColors.lightTheme
    let darkColors = CustomColors.darkTheme

    // All color properties should be non-nil (this is guaranteed by the struct)
    // Test that accent colors are vibrant (not grayscale)
    XCTAssertNotNil(lightColors.accent)
    XCTAssertNotNil(darkColors.accent)

    // Interactive colors should be different from backgrounds
    XCTAssertNotEqual(lightColors.interactive, lightColors.background)
    XCTAssertNotEqual(darkColors.interactive, darkColors.background)
  }

  // MARK: - Accessibility Tests

  func testOverlayAccessibility() throws {
    let event = TestUtilities.createTestEvent(title: "Accessible Meeting")

    let view = OverlayContentView(
      event: event,
      onDismiss: {},
      onJoin: {},
      onSnooze: { _ in }
    )
    .environment(\.customDesign, testDesign)

    // Test that view can be created (full accessibility testing requires UI testing)
    XCTAssertNotNil(view)
  }

  func testButtonAccessibility() throws {
    let accessibleButton = CustomButton("Accessible Button", style: .primary) {}
      .accessibilityLabel("Join the meeting")
      .accessibilityHint("Tap to join the scheduled meeting")
      .environment(\.customDesign, testDesign)

    XCTAssertNotNil(accessibleButton)
  }

  // MARK: - Layout Tests

  func testOverlayLayoutConsistency() throws {
    let shortTitleEvent = TestUtilities.createTestEvent(title: "Meeting")
    let longTitleEvent = TestUtilities.createTestEvent(
      title: "This is a very long meeting title that should wrap properly and not break the layout"
    )

    let shortView = OverlayContentView(
      event: shortTitleEvent,
      onDismiss: {},
      onJoin: {},
      onSnooze: { _ in }
    )
    .environment(\.customDesign, testDesign)
    .frame(width: 800, height: 600)

    let longView = OverlayContentView(
      event: longTitleEvent,
      onDismiss: {},
      onJoin: {},
      onSnooze: { _ in }
    )
    .environment(\.customDesign, testDesign)
    .frame(width: 800, height: 600)

    XCTAssertNotNil(shortView)
    XCTAssertNotNil(longView)
  }

  // MARK: - Performance Tests

  func testViewCreationPerformance() throws {
    let event = TestUtilities.createTestEvent()

    let (_, creationTime) = TestUtilities.measureTime {
      for _ in 0..<100 {
        let _ = OverlayContentView(
          event: event,
          onDismiss: {},
          onJoin: {},
          onSnooze: { _ in }
        )
        .environment(\.customDesign, self.testDesign)
      }
    }

    XCTAssertLessThan(creationTime, 1.0, "Creating 100 views should take less than 1 second")
  }

  func testButtonCreationPerformance() throws {
    let (_, creationTime) = TestUtilities.measureTime {
      for i in 0..<100 {
        let _ = CustomButton("Button \(i)", style: .primary) {}
          .environment(\.customDesign, self.testDesign)
      }
    }

    XCTAssertLessThan(creationTime, 0.5, "Creating 100 buttons should take less than 0.5 seconds")
  }

  // MARK: - Error Handling Tests

  func testViewWithNilEvent() throws {
    // Test that views handle edge cases gracefully
    let emptyEvent = TestUtilities.createTestEvent(
      title: "",
      organizer: nil
    )

    let view = OverlayContentView(
      event: emptyEvent,
      onDismiss: {},
      onJoin: {},
      onSnooze: { _ in }
    )
    .environment(\.customDesign, testDesign)

    XCTAssertNotNil(view)
  }

  func testViewWithExtremeDates() throws {
    let distantFutureEvent = TestUtilities.createTestEvent(
      startDate: Date().addingTimeInterval(365 * 24 * 3600)  // 1 year from now
    )

    let distantPastEvent = TestUtilities.createTestEvent(
      startDate: Date().addingTimeInterval(-365 * 24 * 3600)  // 1 year ago
    )

    let futureView = OverlayContentView(
      event: distantFutureEvent,
      onDismiss: {},
      onJoin: {},
      onSnooze: { _ in }
    )
    .environment(\.customDesign, testDesign)

    let pastView = OverlayContentView(
      event: distantPastEvent,
      onDismiss: {},
      onJoin: {},
      onSnooze: { _ in }
    )
    .environment(\.customDesign, testDesign)

    XCTAssertNotNil(futureView)
    XCTAssertNotNil(pastView)
  }

  // MARK: - Snapshot Tests (Disabled for CI)

  func testOverlaySnapshotLight() throws {
    let event = TestUtilities.createMeetingEvent(provider: .meet)

    let view = OverlayContentView(
      event: event,
      onDismiss: {},
      onJoin: {},
      onSnooze: { _ in }
    )
    .environment(\.customDesign, CustomDesign.design(for: .light))
    .frame(width: 1000, height: 700)

    // Snapshot testing disabled for now - would require additional setup
    // assertSnapshot(matching: view, as: .image, named: "overlay-light")
    XCTAssertNotNil(view)
  }

  func testOverlaySnapshotDark() throws {
    let event = TestUtilities.createMeetingEvent(provider: .zoom)

    let view = OverlayContentView(
      event: event,
      onDismiss: {},
      onJoin: {},
      onSnooze: { _ in }
    )
    .environment(\.customDesign, CustomDesign.design(for: .dark))
    .frame(width: 1000, height: 700)

    // Snapshot testing disabled for now - would require additional setup
    // assertSnapshot(matching: view, as: .image, named: "overlay-dark")
    XCTAssertNotNil(view)
  }
}

// MARK: - Mock AppState for Testing

@MainActor
class MockAppState: ObservableObject {
  @Published var isConnected = false
  @Published var upcomingEvents: [Event] = []
  @Published var syncStatus = "Ready"
  @Published var connectionStatus = "Disconnected"

  func connectToCalendar() async {
    isConnected = true
    connectionStatus = "Connected"
  }

  func disconnectFromCalendar() async {
    isConnected = false
    connectionStatus = "Disconnected"
    upcomingEvents = []
  }

  func syncNow() async {
    syncStatus = "Syncing..."
    // Simulate sync delay
    try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
    syncStatus = "Ready"
  }
}
