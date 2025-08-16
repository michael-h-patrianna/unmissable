import Foundation

/// PRODUCTION OVERLAY TEST
/// This will test the exact scenario described by the user
/// Run this with: swift run --target UnmissableTest
class ProductionOverlayTest {

  static func main() async {
    print("🚨 PRODUCTION OVERLAY DEADLOCK TEST")
    print("Simulating exact user scenario: scheduled alert triggering overlay")

    // Create production-identical components
    let preferencesManager = PreferencesManager()
    let overlayManager = OverlayManager(preferencesManager: preferencesManager)
    let eventScheduler = EventScheduler(preferencesManager: preferencesManager)

    // Connect exactly as in production
    overlayManager.setEventScheduler(eventScheduler)

    print("📅 Creating test event that triggers in 3 seconds...")

    // Create event that should trigger an overlay in 3 seconds
    let futureTime = Date().addingTimeInterval(3)
    let testEvent = Event(
      id: "production-test",
      title: "Production Deadlock Test",
      startDate: futureTime.addingTimeInterval(300),  // Event starts 5 minutes after trigger
      endDate: futureTime.addingTimeInterval(3900),  // 1 hour long
      organizer: "test@example.com",
      calendarId: "test-calendar"
    )

    print("🎯 Event created. Starting EventScheduler monitoring...")

    // Start the exact same process as production
    await eventScheduler.startScheduling(events: [testEvent], overlayManager: overlayManager)

    print("⏰ Waiting for scheduled alert to trigger...")
    print("   User reported: sound plays but overlay doesn't open, app freezes")

    let startTime = Date()
    var overlayAppeared = false

    // Monitor for 10 seconds
    while Date().timeIntervalSince(startTime) < 10 {
      try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 second checks

      let elapsed = Date().timeIntervalSince(startTime)

      if elapsed >= 3.5 && !overlayAppeared {
        let isVisible = overlayManager.isOverlayVisible
        if isVisible {
          overlayAppeared = true
          print("✅ SUCCESS at \(elapsed)s: Overlay appeared!")
          print("🎉 DEADLOCK FIXED: Scheduled alert successfully triggered overlay")
          break
        }
      }

      if elapsed >= 8 && !overlayAppeared {
        print("❌ DEADLOCK STILL EXISTS at \(elapsed)s: No overlay despite scheduled alert")
        print("   This matches the user's exact report")
        break
      }
    }

    let totalTime = Date().timeIntervalSince(startTime)
    print("📊 Test completed in \(totalTime) seconds")

    if overlayAppeared {
      print("🎯 CRITICAL FIX VALIDATED: User's deadlock issue is resolved")
      overlayManager.hideOverlay()
    } else {
      print("⚠️ DEADLOCK PERSISTS: Further investigation needed")
    }

    eventScheduler.stopScheduling()
    print("🏁 Production test complete")
  }
}

// Run the test
await ProductionOverlayTest.main()
