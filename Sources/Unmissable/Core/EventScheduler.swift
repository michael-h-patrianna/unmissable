import AppKit
import Combine
import Foundation
import OSLog

@MainActor
class EventScheduler: ObservableObject {
  private let logger = Logger(subsystem: "com.unmissable.app", category: "EventScheduler")

  @Published var scheduledAlerts: [ScheduledAlert] = []

  private var timer: Timer?
  private let preferencesManager: PreferencesManager
  private var cancellables = Set<AnyCancellable>()

  // Store current events to allow rescheduling
  private var currentEvents: [Event] = []
  private weak var currentOverlayManager: OverlayManager?

  init(preferencesManager: PreferencesManager) {
    self.preferencesManager = preferencesManager
    setupPreferencesObserver()
  }

  deinit {
    timer?.invalidate()
    cancellables.removeAll()
  }

  private func setupPreferencesObserver() {
    // Watch for alert timing preference changes
    Publishers.CombineLatest4(
      preferencesManager.$defaultAlertMinutes,
      preferencesManager.$useLengthBasedTiming,
      preferencesManager.$overlayShowMinutesBefore,
      preferencesManager.$shortMeetingAlertMinutes
    )
    .sink { [weak self] _, _, _, _ in
      Task { @MainActor [weak self] in
        guard let self = self else { return }
        self.logger.info("🔔 Alert preferences changed, rescheduling alerts")
        await self.rescheduleCurrentAlerts()
      }
    }
    .store(in: &cancellables)

    // Also watch for medium and long meeting alert changes
    Publishers.CombineLatest(
      preferencesManager.$mediumMeetingAlertMinutes,
      preferencesManager.$longMeetingAlertMinutes
    )
    .sink { [weak self] _, _ in
      Task { @MainActor [weak self] in
        guard let self = self else { return }
        self.logger.info("🔔 Alert preferences changed, rescheduling alerts")
        await self.rescheduleCurrentAlerts()
      }
    }
    .store(in: &cancellables)
  }

  func startScheduling(events: [Event], overlayManager: OverlayManager) async {
    logger.info("Starting event scheduling for \(events.count) events")

    // Store for future rescheduling when preferences change
    currentEvents = events
    currentOverlayManager = overlayManager

    stopScheduling()
    scheduleAlerts(for: events)
    scheduleOverlays(for: events, overlayManager: overlayManager)
    startMonitoring(overlayManager: overlayManager)
  }

  private func rescheduleCurrentAlerts() async {
    guard !currentEvents.isEmpty, let overlayManager = currentOverlayManager else {
      logger.info("No current events to reschedule")
      return
    }

    logger.info(
      "Rescheduling alerts for \(self.currentEvents.count) events with updated preferences")

    stopScheduling()
    scheduleAlerts(for: currentEvents)
    scheduleOverlays(for: currentEvents, overlayManager: overlayManager)
    startMonitoring(overlayManager: overlayManager)
  }

  func stopScheduling() {
    logger.info("🛑 STOP SCHEDULING: Starting cleanup")

    // CRITICAL FIX: Ensure proper cleanup on main thread
    timer?.invalidate()
    timer = nil
    scheduledAlerts.removeAll()

    // CRITICAL FIX: Clean up properly to prevent memory leaks
    currentEvents.removeAll()
    currentOverlayManager = nil

    // CRITICAL FIX: Remove all Combine subscriptions
    cancellables.removeAll()

    logger.info("✅ STOP SCHEDULING: Cleanup completed")
  }

  private func scheduleAlerts(for events: [Event]) {
    // Preserve existing snooze alerts before clearing
    let existingSnoozeAlerts = scheduledAlerts.filter { alert in
      if case .snooze = alert.alertType {
        return alert.triggerDate > Date()  // Only keep future snooze alerts
      }
      return false
    }

    scheduledAlerts.removeAll()

    let currentTime = Date()

    for event in events {
      // Skip past events (but snooze alerts will be preserved above)
      if event.startDate < currentTime {
        continue
      }

      // Schedule overlay alerts based on preferences
      let overlayTiming = preferencesManager.overlayShowMinutesBefore
      let overlayTime = event.startDate.addingTimeInterval(-TimeInterval(overlayTiming * 60))

      if overlayTime > currentTime {
        let overlayAlert = ScheduledAlert(
          event: event,
          triggerDate: overlayTime,
          alertType: .reminder(minutesBefore: overlayTiming)
        )
        scheduledAlerts.append(overlayAlert)
      }

      // Schedule sound alerts if enabled (using event-specific timing)
      if preferencesManager.soundEnabled {
        let soundTiming = preferencesManager.alertMinutes(for: event)
        let soundTime = event.startDate.addingTimeInterval(-TimeInterval(soundTiming * 60))

        if soundTime > currentTime && soundTime != overlayTime {
          let soundAlert = ScheduledAlert(
            event: event,
            triggerDate: soundTime,
            alertType: .reminder(minutesBefore: soundTiming)
          )
          scheduledAlerts.append(soundAlert)
        }
      }
    }

    // Re-add preserved snooze alerts
    scheduledAlerts.append(contentsOf: existingSnoozeAlerts)

    // Sort by trigger time
    scheduledAlerts.sort { $0.triggerDate < $1.triggerDate }

    logger.info(
      "Scheduled \(self.scheduledAlerts.count) alerts (including \(existingSnoozeAlerts.count) preserved snooze alerts)"
    )
  }

  private func scheduleOverlays(for events: [Event], overlayManager: OverlayManager) {
    let currentTime = Date()
    let overlayTiming = preferencesManager.overlayShowMinutesBefore

    print(
      "🎯 SCHEDULE OVERLAYS: Processing \(events.count) events with timing \(overlayTiming) minutes before"
    )

    for event in events {
      // Only schedule overlays for future events
      guard event.startDate > currentTime else {
        print("⏭️ SKIP: Event \(event.title) starts in past (\(event.startDate) <= \(currentTime))")
        continue
      }

      print("📅 SCHEDULING: Calling overlayManager.scheduleOverlay for \(event.title)")
      overlayManager.scheduleOverlay(for: event, minutesBeforeMeeting: overlayTiming)
    }

    print("✅ SCHEDULED: Overlays for \(events.count) events")
  }

  private func startMonitoring(overlayManager: OverlayManager) {
    timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
      Task { @MainActor [weak self] in
        guard let self = self else { return }
        await self.checkForTriggeredAlerts(overlayManager: overlayManager)
      }
    }
  }

  private func checkForTriggeredAlerts(overlayManager: OverlayManager) async {
    let now = Date()

    // Find alerts that should trigger
    let triggeredAlerts = scheduledAlerts.filter { alert in
      alert.triggerDate <= now
    }

    if !triggeredAlerts.isEmpty {
      logger.info("🔔 Found \(triggeredAlerts.count) triggered alerts at \(now)")
      for alert in triggeredAlerts {
        let alertTypeName: String
        switch alert.alertType {
        case .reminder(let minutes):
          alertTypeName = "reminder(\(minutes)min)"
        case .snooze(let until):
          alertTypeName = "snooze(until: \(until))"
        case .meetingStart:
          alertTypeName = "meetingStart"
        }
        logger.info(
          "  - \(alertTypeName) for '\(alert.event.title)' (trigger: \(alert.triggerDate))")
      }
    }

    for alert in triggeredAlerts {
      await handleTriggeredAlert(alert, overlayManager: overlayManager)
    }

    // Remove triggered alerts
    let beforeCount = scheduledAlerts.count
    scheduledAlerts.removeAll { alert in
      triggeredAlerts.contains { $0.id == alert.id }
    }

    if !triggeredAlerts.isEmpty {
      let afterCount = scheduledAlerts.count
      logger.info(
        "✅ Processed \(triggeredAlerts.count) alerts, \(afterCount) remaining scheduled (was \(beforeCount))"
      )
    }
  }

  private func handleTriggeredAlert(_ alert: ScheduledAlert, overlayManager: OverlayManager) async {
    let alertTypeName: String
    switch alert.alertType {
    case .reminder(let minutes):
      alertTypeName = "reminder(\(minutes)min)"
    case .snooze(let until):
      alertTypeName = "snooze(until: \(until))"
    case .meetingStart:
      alertTypeName = "meetingStart"
    }

    logger.info("🚨 HANDLING ALERT: \(alertTypeName) for event: \(alert.event.title)")

    // CRITICAL FIX: Ensure all overlay operations happen on main thread
    await MainActor.run {
      switch alert.alertType {
      case .reminder:
        logger.info("📱 REMINDER: Showing overlay for \(alert.event.title)")
        overlayManager.showOverlay(for: alert.event, fromSnooze: false)

      case .meetingStart:
        if preferencesManager.autoJoinEnabled, let url = alert.event.primaryLink {
          logger.info("🚀 AUTO-JOIN: Opening meeting for \(alert.event.title)")
          NSWorkspace.shared.open(url)
        }

      case .snooze:
        logger.info("⏰ SNOOZE: Re-showing overlay for \(alert.event.title)")
        // SNOOZE FIX: Mark overlay as coming from snooze alert
        overlayManager.showOverlay(for: alert.event, fromSnooze: true)
      }
    }

    logger.info("✅ ALERT HANDLED: Completed for \(alert.event.title)")
  }

  func scheduleSnooze(for event: Event, minutes: Int) {
    let snoozeDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
    let meetingStarted = event.startDate < Date()

    // Allow snoozing past meeting start time - user might want to join late
    // Don't limit to meeting start time like the original logic
    let snoozeAlert = ScheduledAlert(
      event: event,
      triggerDate: snoozeDate,  // Use full snooze time, not limited by meeting start
      alertType: .snooze(until: snoozeDate)
    )

    scheduledAlerts.append(snoozeAlert)
    scheduledAlerts.sort { $0.triggerDate < $1.triggerDate }

    let formatter = DateFormatter()
    formatter.timeStyle = .medium
    formatter.dateStyle = .none

    if meetingStarted {
      logger.info(
        "⏰ Scheduled snooze for \(minutes) minutes for event '\(event.title)' (meeting already started). Will trigger at \(formatter.string(from: snoozeDate))"
      )
    } else {
      logger.info(
        "⏰ Scheduled snooze for \(minutes) minutes for event '\(event.title)' (meeting starts later). Will trigger at \(formatter.string(from: snoozeDate))"
      )
    }
  }
}
