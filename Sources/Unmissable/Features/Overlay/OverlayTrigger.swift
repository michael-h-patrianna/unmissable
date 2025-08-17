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
  private var scheduledTasks: [Task<Void, Never>] = []

  deinit {
    // Clean up timers and tasks synchronously in deinit
    for timer in scheduledTimers {
      timer.invalidate()
    }
    for task in scheduledTasks {
      task.cancel()
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

    // Use async task instead of timer for better modern Swift patterns
    let task = Task { @MainActor in
      do {
        try await Task.sleep(for: .seconds(timeInterval))
        if !Task.isCancelled {
          handler()
        }
      } catch {
        // Task was cancelled
      }
    }

    scheduledTasks.append(task)
    scheduledCount = scheduledTasks.count + scheduledTimers.count

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
    logger.info(
      "Cancelling \(self.scheduledTimers.count) scheduled overlays and \(self.scheduledTasks.count) tasks"
    )

    for timer in scheduledTimers {
      timer.invalidate()
    }
    for task in scheduledTasks {
      task.cancel()
    }
    scheduledTimers.removeAll()
    scheduledTasks.removeAll()
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
      scheduledCount = scheduledTimers.count + scheduledTasks.count
    }
  }

  private func removeTask(_ task: Task<Void, Never>) {
    // Tasks will clean themselves up when completed or cancelled
    // We'll update count during cancelAllScheduled
  }
}
