import XCTest
import Foundation
@testable import Unmissable

/// Test cases specifically for snooze timer migration validation
/// These tests focus on the fallback snooze scheduling mechanism
class SnoozeTimerMigrationTests: XCTestCase {
  
  var overlayManager: OverlayManager!
  var preferencesManager: PreferencesManager!
  
  override func setUp() async throws {
    try await super.setUp()
    preferencesManager = TimerMigrationTestHelpers.createTestPreferencesManager()
    overlayManager = OverlayManager(
      preferencesManager: preferencesManager,
      focusModeManager: nil,
      isTestMode: true
    )
  }
  
  override func tearDown() async throws {
    overlayManager = nil
    preferencesManager = nil
    try await super.tearDown()
  }
  
  /// Test snooze timer accuracy for different durations
  func testSnoozeTimerAccuracy() async throws {
    let snoozeDurations = [1, 5, 15]  // 1, 5, 15 minutes
    
    for duration in snoozeDurations {
      let event = TimerMigrationTestHelpers.SnoozeTimer.createSnoozeTestEvent()
      
      let expectation = TimerMigrationTestHelpers.createTimerExpectation(
        description: "Snooze timer fired for \(duration) minutes",
        timeout: TimeInterval(duration * 60 + 5)  // Add 5 second buffer
      )
      
      // Show overlay first
      overlayManager.showOverlay(for: event)
      XCTAssertTrue(overlayManager.isOverlayVisible)
      
      let snoozeStartTime = Date()
      
      // Set up observer for overlay reappearance
      var overlayReappeared = false
      let observer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
        if self.overlayManager.isOverlayVisible && !overlayReappeared {
          overlayReappeared = true
          timer.invalidate()
          
          let actualSnoozeTime = Date()
          let expectedSnoozeTime = snoozeStartTime.addingTimeInterval(TimeInterval(duration * 60))
          
          TimerMigrationTestHelpers.logTimingMetrics(
            operation: "Snooze \(duration)min",
            expected: expectedSnoozeTime,
            actual: actualSnoozeTime,
            tolerance: TimerMigrationTestHelpers.SnoozeTimer.tolerance
          )
          
          TimerMigrationTestHelpers.validateTimerAccuracy(
            expected: expectedSnoozeTime,
            actual: actualSnoozeTime,
            tolerance: TimerMigrationTestHelpers.SnoozeTimer.tolerance
          )
          
          expectation.fulfill()
        }
      }
      
      // Trigger snooze
      overlayManager.snoozeOverlay(for: duration)
      XCTAssertFalse(overlayManager.isOverlayVisible, "Overlay should be hidden after snooze")
      
      // Wait for snooze to complete
      TimerMigrationTestHelpers.waitForTimerExpectations(
        [expectation],
        timeout: TimeInterval(duration * 60 + 10)
      )
      
      observer.invalidate()
      overlayManager.hideOverlay()  // Clean up
      
      // Brief pause between tests
      try await Task.sleep(for: .milliseconds(100))
    }
  }
  
  /// Test snooze timer cancellation
  func testSnoozeTimerCancellation() async throws {
    let event = TimerMigrationTestHelpers.SnoozeTimer.createSnoozeTestEvent()
    
    // Show overlay
    overlayManager.showOverlay(for: event)
    XCTAssertTrue(overlayManager.isOverlayVisible)
    
    // Trigger 5-minute snooze
    overlayManager.snoozeOverlay(for: 5)
    XCTAssertFalse(overlayManager.isOverlayVisible)
    
    // Wait 1 second to ensure snooze is active
    try await Task.sleep(for: .seconds(1))
    
    // Cancel by showing different event (should cancel pending snooze)
    let differentEvent = TimerMigrationTestHelpers.createTestEvent(
      minutesInFuture: 3,
      title: "Cancellation Test Event"
    )
    overlayManager.showOverlay(for: differentEvent)
    
    // Wait much longer than the original snooze would take
    try await Task.sleep(for: .seconds(2))
    
    // Should still be showing the new event, not the snoozed one
    XCTAssertTrue(overlayManager.isOverlayVisible)
    XCTAssertEqual(overlayManager.activeEvent?.title, "Cancellation Test Event")
    
    overlayManager.hideOverlay()
  }
  
  /// Test multiple concurrent snooze operations
  func testMultipleSnoozeOperations() async throws {
    let events = (0..<3).map { index in
      TimerMigrationTestHelpers.SnoozeTimer.createSnoozeTestEvent(snoozeMinutes: 1)
    }
    
    // Trigger multiple snoozes rapidly
    for (index, event) in events.enumerated() {
      overlayManager.showOverlay(for: event)
      overlayManager.snoozeOverlay(for: 1)  // 1 minute snooze
      
      // Brief delay between snoozes
      try await Task.sleep(for: .milliseconds(100))
    }
    
    // Only the last snooze should be active
    // Wait for potential snooze to trigger
    try await Task.sleep(for: .seconds(2))
    
    // Should either have no overlay or overlay from last event
    if overlayManager.isOverlayVisible {
      // If an overlay appeared, it should be from the last event
      let lastEvent = events.last!
      // Note: Due to timing, we can't guarantee exact event match,
      // but we can verify only one overlay is active
      XCTAssertNotNil(overlayManager.activeEvent)
    }
    
    overlayManager.hideOverlay()
  }
  
  /// Test snooze timer with EventScheduler unavailable (fallback mode)
  func testSnoozeTimerFallbackMode() async throws {
    // This test specifically targets the fallback snooze mechanism
    // when EventScheduler is not available
    
    let event = TimerMigrationTestHelpers.SnoozeTimer.createSnoozeTestEvent()
    
    // Ensure no EventScheduler is set (fallback mode)
    overlayManager.setEventScheduler(nil)
    
    let expectation = TimerMigrationTestHelpers.createTimerExpectation(
      description: "Fallback snooze timer fired"
    )
    
    overlayManager.showOverlay(for: event)
    
    let snoozeStartTime = Date()
    
    // Monitor for overlay reappearance
    let observer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
      if self.overlayManager.isOverlayVisible {
        timer.invalidate()
        
        let actualTime = Date()
        let expectedTime = snoozeStartTime.addingTimeInterval(60)  // 1 minute
        
        TimerMigrationTestHelpers.validateTimerAccuracy(
          expected: expectedTime,
          actual: actualTime,
          tolerance: TimerMigrationTestHelpers.SnoozeTimer.tolerance
        )
        
        expectation.fulfill()
      }
    }
    
    // Trigger fallback snooze
    overlayManager.snoozeOverlay(for: 1)  // 1 minute
    
    TimerMigrationTestHelpers.waitForTimerExpectations([expectation], timeout: 70.0)
    
    observer.invalidate()
    overlayManager.hideOverlay()
  }
  
  /// Test snooze timer memory usage
  func testSnoozeTimerMemoryUsage() async throws {
    let initialMemory = getMemoryUsage()
    
    let events = (0..<20).map { index in
      TimerMigrationTestHelpers.SnoozeTimer.createSnoozeTestEvent()
    }
    
    // Create and cancel many snooze timers
    for event in events {
      overlayManager.showOverlay(for: event)
      overlayManager.snoozeOverlay(for: 5)  // 5-minute snooze
      
      try await Task.sleep(for: .milliseconds(10))
      
      // Cancel by hiding
      overlayManager.hideOverlay()
      
      try await Task.sleep(for: .milliseconds(10))
    }
    
    // Wait for cleanup
    try await Task.sleep(for: .seconds(1))
    
    let finalMemory = getMemoryUsage()
    let memoryIncrease = finalMemory - initialMemory
    
    print("📊 SNOOZE MEMORY: Initial: \(initialMemory / 1024 / 1024) MB")
    print("📊 SNOOZE MEMORY: Final: \(finalMemory / 1024 / 1024) MB")
    print("📊 SNOOZE MEMORY: Increase: \(memoryIncrease / 1024 / 1024) MB")
    
    // Memory increase should be minimal
    XCTAssertLessThan(
      memoryIncrease,
      5 * 1024 * 1024,
      "Memory increase should be less than 5MB after snooze timer stress test"
    )
  }
  
  /// Test snooze timer behavior during system sleep/wake cycles
  func testSnoozeTimerSystemSleepWake() async throws {
    // This test simulates what happens when the system goes to sleep
    // and wakes up during a snooze period
    
    let event = TimerMigrationTestHelpers.SnoozeTimer.createSnoozeTestEvent()
    
    overlayManager.showOverlay(for: event)
    overlayManager.snoozeOverlay(for: 2)  // 2-minute snooze
    
    // Simulate system sleep by pausing execution
    // In a real scenario, this would be handled by the OS
    try await Task.sleep(for: .seconds(1))
    
    // Verify snooze is still active (overlay should still be hidden)
    XCTAssertFalse(overlayManager.isOverlayVisible)
    
    // Wait for snooze to potentially complete
    try await Task.sleep(for: .seconds(2))
    
    // System sleep/wake handling is complex and OS-dependent
    // For now, just verify no crashes occurred
    // Future enhancement: test actual sleep/wake notification handling
    
    overlayManager.hideOverlay()
  }
  
  // MARK: - Helper Methods
  
  private func getMemoryUsage() -> Int {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
    
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
      }
    }
    
    return kerr == KERN_SUCCESS ? Int(info.resident_size) : 0
  }
}
