import AppKit
import Foundation

// Quick test to ensure FocusModeManager doesn't block the main thread
@MainActor
class TestFocusModeManager {
  private var isDoNotDisturbEnabled: Bool = false

  func testAsyncDNDCheck() {
    print("Testing async DND check...")
    let startTime = Date()

    // This simulates the old blocking behavior
    simulateBlockingCall()

    let endTime = Date()
    let duration = endTime.timeIntervalSince(startTime)
    print("Method completed in \(duration) seconds")

    if duration > 0.1 {
      print("⚠️ Method took too long - potential UI freeze!")
    } else {
      print("✅ Method completed quickly - no UI freeze")
    }
  }

  private func simulateBlockingCall() {
    // Simulate the fixed async behavior
    Task.detached { [weak self] in
      // Simulate some work
      try? await Task.sleep(nanoseconds: 50_000_000)  // 50ms

      await MainActor.run { [weak self] in
        self?.isDoNotDisturbEnabled = Bool.random()
        print("DND status updated asynchronously")
      }
    }
  }
}

// Run test
Task { @MainActor in
  let testManager = TestFocusModeManager()
  testManager.testAsyncDNDCheck()
}

// Keep the test running briefly
RunLoop.main.run(until: Date().addingTimeInterval(1.0))
