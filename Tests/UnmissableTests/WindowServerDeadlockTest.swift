import AppKit
import Foundation
import OSLog
import XCTest

@testable import Unmissable

/// CRITICAL TEST: Reproduce the exact Window Server deadlock scenario
/// This test creates REAL windows to test the actual deadlock scenario
@MainActor
class WindowServerDeadlockTest: XCTestCase {

  private let logger = Logger(subsystem: "com.unmissable.test", category: "WindowServerTest")

  func testWindowServerCloseDeadlock() async throws {
    logger.info("🚨 CRITICAL TEST: Window Server close deadlock with timer")

    // Create a minimal scenario that reproduces the Window Server deadlock
    var window: NSWindow?
    var timer: Timer?
    var deadlockDetected = false

    let startTime = Date()
    let maxTestTime: TimeInterval = 10.0  // Allow more time for real window operations

    logger.info("🪟 Creating real NSWindow for deadlock test...")

    // Create a real window (not test mode)
    window = NSWindow(
      contentRect: NSRect(x: 100, y: 100, width: 400, height: 300),
      styleMask: [.borderless, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )

    window?.level = .floating
    window?.backgroundColor = NSColor.red.withAlphaComponent(0.8)
    window?.isOpaque = false
    window?.ignoresMouseEvents = true
    window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

    // Show the window to register it with Window Server
    window?.orderFront(nil)

    logger.info("✅ Window created and shown")

    // Start a timer that simulates the countdown timer
    var timerRunning = true
    timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
      // Simulate updateCountdown work
      self.logger.info("⏰ Timer callback executing...")
      Thread.sleep(forTimeInterval: 0.01)  // 10ms of work

      if !timerRunning {
        self.logger.info("🛑 Timer detected stop signal")
        return
      }
    }

    logger.info("⏰ Timer started")

    // Wait for timer to be established
    try await Task.sleep(nanoseconds: 200_000_000)  // 0.2 seconds

    // Now simulate the dismiss button click scenario
    logger.info("🔥 TESTING: Simulating dismiss button click during timer execution...")

    let dismissStartTime = Date()
    var dismissCompleted = false

    // This simulates the exact scenario that causes deadlock
    Task {
      self.logger.info("🛑 DISMISS: Starting window close sequence...")

      // Stop timer first (as in hideOverlay)
      timerRunning = false
      timer?.invalidate()
      timer = nil

      self.logger.info("🛑 DISMISS: Timer stopped, now closing window...")

      // This is where the deadlock occurs - window.close() while Window Server is busy
      window?.close()
      window = nil

      self.logger.info("✅ DISMISS: Window close completed")
      dismissCompleted = true
    }

    // Wait for completion or timeout
    var testCompleted = false
    var timeoutCounter = 0
    let maxTimeout = Int(maxTestTime * 10)  // Check every 0.1 seconds

    while !testCompleted && timeoutCounter < maxTimeout {
      try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
      timeoutCounter += 1

      if dismissCompleted {
        testCompleted = true
        logger.info("✅ Dismiss completed successfully")
      }
    }

    let totalTime = Date().timeIntervalSince(startTime)
    let dismissTime = dismissCompleted ? Date().timeIntervalSince(dismissStartTime) : totalTime

    if !testCompleted {
      deadlockDetected = true
      logger.error("❌ DEADLOCK DETECTED: Window close took too long")

      // Force cleanup
      timerRunning = false
      timer?.invalidate()
      timer = nil
      window?.close()
      window = nil
    }

    logger.info("📊 Window Server deadlock test completed in \(totalTime)s")
    logger.info("📊 Dismiss operation took \(dismissTime)s")

    // Validate results
    XCTAssertTrue(testCompleted, "Window close should complete without deadlock")
    XCTAssertFalse(deadlockDetected, "No deadlock should be detected")
    XCTAssertLessThan(dismissTime, 5.0, "Window close should complete within 5 seconds")
  }

  func testOverlayManagerWindowServerDeadlock() async throws {
    logger.info("🚨 CRITICAL TEST: OverlayManager Window Server deadlock reproduction")

    // Create OverlayManager in REAL mode (not test mode) to test actual windows
    let preferencesManager = PreferencesManager()
    let focusModeManager = FocusModeManager(preferencesManager: preferencesManager)
    let overlayManager = OverlayManager(
      preferencesManager: preferencesManager,
      focusModeManager: focusModeManager,
      isTestMode: false  // CRITICAL: Use real mode to test actual Window Server interaction
    )

    let testEvent = TestUtilities.createTestEvent(
      id: "window-server-deadlock-test",
      title: "Window Server Deadlock Test",
      startDate: Date().addingTimeInterval(300)  // 5 minutes from now
    )

    logger.info("📅 Created test event: \(testEvent.title)")

    // Show overlay to create real windows and start timer
    logger.info("🎬 Showing real overlay...")
    overlayManager.showOverlay(for: testEvent, minutesBeforeMeeting: 5)
    XCTAssertTrue(overlayManager.isOverlayVisible, "Overlay should be visible")

    // Wait for timer and windows to be established
    try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

    // Now simulate rapid dismiss (like user clicking button)
    logger.info("🔥 RAPID DISMISS: Simulating real dismiss button click...")

    let startTime = Date()
    let maxDismissTime: TimeInterval = 5.0  // Allow reasonable time for real window operations

    var dismissCompleted = false
    var deadlockDetected = false

    // This should trigger the exact same callback pattern as the real dismiss button
    Task {
      self.logger.info("🛑 DISMISS CALLBACK: Starting...")
      overlayManager.hideOverlay()
      self.logger.info("✅ DISMISS CALLBACK: Completed")
      dismissCompleted = true
    }

    // Monitor for completion or deadlock
    var timeoutCounter = 0
    let maxTimeout = Int(maxDismissTime * 10)  // Check every 0.1 seconds

    while !dismissCompleted && timeoutCounter < maxTimeout {
      try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
      timeoutCounter += 1
    }

    let totalTime = Date().timeIntervalSince(startTime)

    if !dismissCompleted {
      deadlockDetected = true
      logger.error("❌ OVERLAY DEADLOCK DETECTED: hideOverlay() took too long")

      // Force cleanup
      overlayManager.hideOverlay()
    }

    logger.info("📊 OverlayManager dismiss test completed in \(totalTime)s")

    // Validate results
    XCTAssertTrue(dismissCompleted, "OverlayManager dismiss should complete without deadlock")
    XCTAssertFalse(deadlockDetected, "No deadlock should be detected")
    XCTAssertFalse(overlayManager.isOverlayVisible, "Overlay should be hidden after dismiss")
    XCTAssertLessThan(totalTime, maxDismissTime, "Dismiss should complete quickly")

    logger.info("✅ OverlayManager Window Server test completed successfully")
  }
}
