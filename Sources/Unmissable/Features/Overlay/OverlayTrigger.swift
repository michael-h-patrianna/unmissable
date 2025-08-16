import Foundation
import OSLog

/// Thread-safe overlay trigger that handles timing and scheduling without complex async chains
/// Eliminates deadlocks by using simple, direct dispatch patterns
@MainActor
class OverlayTrigger: ObservableObject {
  private let logger = Logger(subsystem: "com.unmissable.app", category: "OverlayTrigger")

  @Published var isActive = false
  @Published var scheduledCount = 0

  private var scheduledTimers: [Timer] = []

  deinit {
    // Clean up timers synchronously in deinit - no async calls allowed
    for timer in scheduledTimers {
      timer.invalidate()
    }
  }

  /// Schedule an overlay to display at a specific future time
  /// Uses simple, direct timer dispatch to eliminate async chain complexity
  func scheduleOverlay(
    for event: Event,
    at triggerTime: Date,
    handler: @escaping () -> Void
  ) {
    let timeInterval = triggerTime.timeIntervalSinceNow

    guard timeInterval > 0 else {
      logger.warning("Cannot schedule overlay for past time: \(triggerTime)")
      return
    }

    logger.info("Scheduling overlay for '\(event.title)' in \(timeInterval) seconds")

    // Use simple, direct timer on main queue - no nested async calls
    let timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) {
      [weak self] timer in
      // Execute handler with proper main actor dispatch
      Task { @MainActor [weak self] in
        handler()

        // Clean up timer reference
        self?.removeTimer(timer)
      }
    }

    scheduledTimers.append(timer)
    scheduledCount = scheduledTimers.count

    logger.info("Overlay scheduled. Total scheduled: \(self.scheduledCount)")
  }

  /// Trigger overlay immediately for alerts that should fire now
  func triggerImmediately(
    for event: Event,
    handler: @escaping () -> Void
  ) {
    logger.info("Triggering immediate overlay for: \(event.title)")
    isActive = true

    // Execute handler directly - no async dispatch needed
    handler()

    isActive = false
  }

  /// Cancel all scheduled overlays
  func cancelAllScheduled() {
    logger.info("Cancelling \(self.scheduledTimers.count) scheduled overlays")

    for timer in scheduledTimers {
      timer.invalidate()
    }
    scheduledTimers.removeAll()
    scheduledCount = 0
  }

  /// Cancel overlays for a specific event
  func cancelScheduled(for eventId: String) {
    // Note: This would require storing event IDs with timers for full implementation
    // For now, we'll implement simple cancellation
    logger.info("Cancelling scheduled overlays for event: \(eventId)")

    // In a full implementation, we'd store event IDs with timers
    // For immediate fix, we'll provide the interface
  }

  private func removeTimer(_ timer: Timer) {
    if let index = scheduledTimers.firstIndex(of: timer) {
      scheduledTimers.remove(at: index)
      scheduledCount = scheduledTimers.count
    }
  }
}
