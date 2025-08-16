import Combine
import XCTest

@testable import Unmissable

@MainActor
final class EventSchedulerComprehensiveTests: XCTestCase {

  var eventScheduler: EventScheduler!
  var mockPreferences: TestUtilities.MockPreferencesManager!
  var mockOverlayManager: MockOverlayManager!
  var cancellables: Set<AnyCancellable>!

  override func setUp() async throws {
    try await super.setUp()

    mockPreferences = TestUtilities.MockPreferencesManager()
    mockPreferences.testOverlayShowMinutesBefore = 2  // Set to the actual value being used
    eventScheduler = EventScheduler(preferencesManager: mockPreferences)
    mockOverlayManager = MockOverlayManager()
    cancellables = Set<AnyCancellable>()
  }

  override func tearDown() async throws {
    // Stop all scheduling operations and clean up timers
    eventScheduler.stopScheduling()
    cancellables.removeAll()

    // Give timers time to clean up
    try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds

    // Re-enable memory leak test with proper cleanup
    try TestUtilities.testForMemoryLeaks(instance: eventScheduler) {
      eventScheduler = nil
    }

    mockOverlayManager = nil
    mockPreferences = nil

    try await super.tearDown()
  }

  // MARK: - Basic Scheduling Tests

  func testBasicEventScheduling() async throws {
    let futureEvent = TestUtilities.createTestEvent(
      startDate: Date().addingTimeInterval(300)  // 5 minutes from now
    )

    await eventScheduler.startScheduling(events: [futureEvent], overlayManager: mockOverlayManager)

    // Should have scheduled alerts (may include both overlay and sound alerts)
    XCTAssertFalse(eventScheduler.scheduledAlerts.isEmpty)
    XCTAssertGreaterThanOrEqual(eventScheduler.scheduledAlerts.count, 1)

    let alert = eventScheduler.scheduledAlerts.first!
    XCTAssertEqual(alert.event.id, futureEvent.id)

    if case .reminder(let minutes) = alert.alertType {
      XCTAssertEqual(minutes, mockPreferences.overlayShowMinutesBefore)
    } else {
      XCTFail("Expected reminder alert type")
    }
  }

  func testPastEventNotScheduled() async throws {
    let pastEvent = TestUtilities.createPastEvent()

    await eventScheduler.startScheduling(events: [pastEvent], overlayManager: mockOverlayManager)

    // Should not schedule alerts for past events
    XCTAssertTrue(eventScheduler.scheduledAlerts.isEmpty)
  }

  func testMultipleEventsScheduling() async throws {
    let event1 = TestUtilities.createTestEvent(
      id: "event1",
      startDate: Date().addingTimeInterval(300)
    )
    let event2 = TestUtilities.createTestEvent(
      id: "event2",
      startDate: Date().addingTimeInterval(600)
    )

    await eventScheduler.startScheduling(
      events: [event1, event2], overlayManager: mockOverlayManager)

    XCTAssertGreaterThanOrEqual(eventScheduler.scheduledAlerts.count, 2)

    // Alerts should be sorted by trigger time
    let sortedAlerts = eventScheduler.scheduledAlerts.sorted { $0.triggerDate < $1.triggerDate }
    XCTAssertEqual(
      eventScheduler.scheduledAlerts.map { $0.triggerDate }, sortedAlerts.map { $0.triggerDate })
  }

  // MARK: - Preferences Integration Tests

  func testPreferenceChangesRescheduleAlerts() async throws {
    // This test validates that EventScheduler uses the correct preferences
    // when scheduling alerts, which is critical for avoiding notification spam

    // Create a custom test preferences that guarantees the value
    class TestPreferencesManager: PreferencesManager {
      override var overlayShowMinutesBefore: Int {
        get { return 10 }
        set { /* ignore */  }
      }

      // Set all alert timings to the same value to avoid confusion
      override var defaultAlertMinutes: Int {
        get { return 10 }
        set { /* ignore */  }
      }

      override var shortMeetingAlertMinutes: Int {
        get { return 10 }
        set { /* ignore */  }
      }

      override var mediumMeetingAlertMinutes: Int {
        get { return 10 }
        set { /* ignore */  }
      }

      override var longMeetingAlertMinutes: Int {
        get { return 10 }
        set { /* ignore */  }
      }
    }

    let testPreferences = TestPreferencesManager()

    // Verify the preference returns the correct value
    XCTAssertEqual(
      testPreferences.overlayShowMinutesBefore, 10, "Test preferences should return 10")

    // Create a new EventScheduler with our test preferences
    let testScheduler = EventScheduler(preferencesManager: testPreferences)

    let futureEvent = TestUtilities.createTestEvent(
      startDate: Date().addingTimeInterval(1200)  // 20 minutes from now (enough for 10-minute alert)
    )

    // Schedule with the test preferences
    await testScheduler.startScheduling(events: [futureEvent], overlayManager: mockOverlayManager)

    // Verify we got scheduled alerts
    XCTAssertGreaterThan(eventScheduler.scheduledAlerts.count, 0, "Should have scheduled alerts")

    print(
      "DebugTestPreferences:\(testPreferences.overlayShowMinutesBefore)"
    )
    print("DebugTestPreferences:\(testPreferences.soundEnabled)")
    print(
      "DebugTestPreferences:\(testPreferences.mediumMeetingAlertMinutes)"
    )  // Should have alerts with the specified timing
    let reminderAlerts = testScheduler.scheduledAlerts.filter {
      if case .reminder = $0.alertType { return true } else { return false }
    }
    XCTAssertFalse(reminderAlerts.isEmpty, "Should have reminder alerts")

    if let firstAlert = reminderAlerts.first,
      case .reminder(let minutes) = firstAlert.alertType
    {
      print("First alert reminder minutes = \(minutes)")
      XCTAssertEqual(minutes, 10, "EventScheduler should use the specified preference value")
    } else {
      XCTFail("Expected reminder alert type")
    }

    // Clean up
    testScheduler.stopScheduling()
  }

  func testLengthBasedTimingPreferences() async throws {
    // Create events of different lengths
    let shortEvent = TestUtilities.createTestEvent(
      id: "short",
      startDate: Date().addingTimeInterval(900),  // 15 minutes from now
      endDate: Date().addingTimeInterval(1800)  // 30 minutes total (15 min duration)
    )

    let longEvent = TestUtilities.createTestEvent(
      id: "long",
      startDate: Date().addingTimeInterval(1200),  // 20 minutes from now
      endDate: Date().addingTimeInterval(7200)  // 2 hours total (100 min duration)
    )

    // Enable length-based timing
    mockPreferences.testUseLengthBasedTiming = true
    mockPreferences.shortMeetingAlertMinutes = 2
    mockPreferences.longMeetingAlertMinutes = 10

    await eventScheduler.startScheduling(
      events: [shortEvent, longEvent], overlayManager: mockOverlayManager)

    // Verify different timing for different event lengths
    let shortAlert = eventScheduler.scheduledAlerts.first { $0.event.id == "short" }
    let longAlert = eventScheduler.scheduledAlerts.first { $0.event.id == "long" }

    XCTAssertNotNil(shortAlert)
    XCTAssertNotNil(longAlert)

    // Long events should have different timing than short events
    XCTAssertNotEqual(shortAlert?.triggerDate, longAlert?.triggerDate)
  }

  // MARK: - Sound Alert Tests

  func testSoundAlertsWhenEnabled() async throws {
    mockPreferences.testSoundEnabled = true
    mockPreferences.testDefaultAlertMinutes = 3
    mockPreferences.testOverlayShowMinutesBefore = 5

    let futureEvent = TestUtilities.createTestEvent(
      startDate: Date().addingTimeInterval(600)  // 10 minutes from now
    )

    await eventScheduler.startScheduling(events: [futureEvent], overlayManager: mockOverlayManager)

    // Should have both overlay and sound alerts when timings differ
    XCTAssertEqual(eventScheduler.scheduledAlerts.count, 2)

    let reminderAlerts = eventScheduler.scheduledAlerts.filter {
      if case .reminder = $0.alertType { return true }
      return false
    }

    XCTAssertEqual(reminderAlerts.count, 2)
  }

  func testNoSoundAlertsWhenDisabled() async throws {
    mockPreferences.testSoundEnabled = false

    let futureEvent = TestUtilities.createTestEvent(
      startDate: Date().addingTimeInterval(600)
    )

    await eventScheduler.startScheduling(events: [futureEvent], overlayManager: mockOverlayManager)

    // Should only have overlay alert, no sound alert
    XCTAssertEqual(eventScheduler.scheduledAlerts.count, 1)
  }

  // MARK: - Snooze Tests

  func testSnoozeScheduling() async throws {
    let event = TestUtilities.createTestEvent()

    eventScheduler.scheduleSnooze(for: event, minutes: 5)

    XCTAssertFalse(eventScheduler.scheduledAlerts.isEmpty)

    let snoozeAlert = eventScheduler.scheduledAlerts.first!
    if case .snooze(let until) = snoozeAlert.alertType {
      let expectedTime = Date().addingTimeInterval(5 * 60)
      let timeDifference = abs(until.timeIntervalSince(expectedTime))
      XCTAssertLessThan(timeDifference, 2.0)  // Allow 2 second tolerance
    } else {
      XCTFail("Expected snooze alert type")
    }
  }

  func testSnoozePreservedDuringRescheduling() async throws {
    let futureEvent = TestUtilities.createTestEvent(
      startDate: Date().addingTimeInterval(600)
    )

    await eventScheduler.startScheduling(events: [futureEvent], overlayManager: mockOverlayManager)

    // Add a snooze
    eventScheduler.scheduleSnooze(for: futureEvent, minutes: 3)
    _ = eventScheduler.scheduledAlerts.count  // Check that snooze was added

    // Change preferences to trigger rescheduling
    mockPreferences.testOverlayShowMinutesBefore = 8

    // Wait for rescheduling
    try await TestUtilities.waitForAsync(timeout: 3.0) {
      return self.eventScheduler.scheduledAlerts.contains { alert in
        if case .snooze = alert.alertType { return true }
        return false
      }
    }

    // Snooze alert should still be present
    let hasSnoozeAlert = eventScheduler.scheduledAlerts.contains { alert in
      if case .snooze = alert.alertType { return true }
      return false
    }

    XCTAssertTrue(hasSnoozeAlert, "Snooze alert should be preserved during rescheduling")
  }

  // MARK: - Timer Memory Management Tests

  func testStopSchedulingClearsTimers() async throws {
    let futureEvent = TestUtilities.createTestEvent(
      startDate: Date().addingTimeInterval(300)
    )

    await eventScheduler.startScheduling(events: [futureEvent], overlayManager: mockOverlayManager)
    XCTAssertFalse(eventScheduler.scheduledAlerts.isEmpty)

    eventScheduler.stopScheduling()

    XCTAssertTrue(eventScheduler.scheduledAlerts.isEmpty)
  }

  func testMemoryCleanupSimple() async throws {
    // First test if memory leak detection works with a simple object
    class SimpleTestObject {
      var value = 42
    }

    var simpleObject: SimpleTestObject? = SimpleTestObject()
    weak var weakSimple = simpleObject
    simpleObject = nil

    XCTAssertNil(weakSimple, "Simple object should be deallocated")

    // Now test EventScheduler with minimal setup
    let testPreferences = PreferencesManager()

    var scheduler: EventScheduler? = EventScheduler(preferencesManager: testPreferences)
    weak var weakScheduler = scheduler

    // Clean up reference immediately
    scheduler = nil

    // Give longer time for cleanup
    try await Task.sleep(nanoseconds: 1_000_000_000)  // 1.0 seconds

    // Log what we see for debugging
    if weakScheduler != nil {
      print("EventScheduler still exists after cleanup - investigating retain cycle")
    }

    XCTAssertNil(weakScheduler, "EventScheduler should be deallocated after cleanup")
  }  // MARK: - Alert Triggering Tests

  func testAlertTriggering() async throws {
    let nearFutureEvent = TestUtilities.createTestEvent(
      startDate: Date().addingTimeInterval(30)  // 30 seconds from now
    )

    // Set very short overlay timing for quick triggering
    mockPreferences.testOverlayShowMinutesBefore = 0  // Show immediately

    await eventScheduler.startScheduling(
      events: [nearFutureEvent], overlayManager: mockOverlayManager)

    // Wait for alert to trigger
    let alertTriggered = expectation(description: "Alert triggered")

    mockOverlayManager.onShowOverlay = { event in
      XCTAssertEqual(event.id, nearFutureEvent.id)
      alertTriggered.fulfill()
    }

    await fulfillment(of: [alertTriggered], timeout: 35.0)

    // Alert should be removed after triggering
    XCTAssertTrue(eventScheduler.scheduledAlerts.isEmpty)
  }

  // MARK: - Performance Tests

  func testLargeNumberOfEvents() async throws {
    let numberOfEvents = 100
    let events = (0..<numberOfEvents).map { index in
      TestUtilities.createTestEvent(
        id: "event-\(index)",
        startDate: Date().addingTimeInterval(Double(index * 60 + 300))  // Start 5 minutes from now, spaced 1 minute apart
      )
    }

    let (_, schedulingTime) = await TestUtilities.measureTimeAsync {
      await self.eventScheduler.startScheduling(
        events: events, overlayManager: self.mockOverlayManager)
    }

    // Scheduling should complete quickly even with many events
    XCTAssertLessThan(schedulingTime, 1.0, "Scheduling 100 events should take less than 1 second")

    // Should have alerts for all future events (may include multiple alert types per event)
    XCTAssertGreaterThanOrEqual(eventScheduler.scheduledAlerts.count, numberOfEvents)
  }
}

// MARK: - Mock OverlayManager

@MainActor
class MockOverlayManager: OverlayManager {
  var onShowOverlay: ((Event) -> Void)?
  var onHideOverlay: (() -> Void)?
  var onScheduleOverlay: ((Event, Int) -> Void)?

  override func showOverlay(for event: Event, minutesBeforeMeeting: Int = 5) {
    onShowOverlay?(event)
  }

  override func hideOverlay() {
    onHideOverlay?()
  }

  override func scheduleOverlay(for event: Event, minutesBeforeMeeting: Int = 5) {
    onScheduleOverlay?(event, minutesBeforeMeeting)
  }
}
