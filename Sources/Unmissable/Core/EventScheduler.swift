import AppKit
import Combine
import Foundation
import OSLog

@MainActor
class EventScheduler: ObservableObject {
  private let logger = Logger(subsystem: "com.unmissable.app", category: "EventScheduler")

  @Published var scheduledAlerts: [ScheduledAlert] = []

  private var timer: Timer?
  private var preferencesManager = PreferencesManager()

  func startScheduling(events: [Event], overlayManager: OverlayManager) async {
    logger.info("Starting event scheduling for \(events.count) events")

    stopScheduling()
    scheduleAlerts(for: events)
    scheduleOverlays(for: events, overlayManager: overlayManager)
    startMonitoring(overlayManager: overlayManager)
  }

  func stopScheduling() {
    logger.info("Stopping event scheduling")
    timer?.invalidate()
    timer = nil
    scheduledAlerts.removeAll()
  }

  private func scheduleAlerts(for events: [Event]) {
    scheduledAlerts.removeAll()

    let currentTime = Date()
    let prefs = preferencesManager

    for event in events {
      // Skip past events
      if event.startDate < currentTime {
        continue
      }

      // Schedule overlay alerts based on preferences
      let overlayTiming = prefs.overlayShowMinutesBefore
      let overlayTime = event.startDate.addingTimeInterval(-TimeInterval(overlayTiming * 60))

      if overlayTime > currentTime {
        let overlayAlert = ScheduledAlert(
          event: event,
          triggerDate: overlayTime,
          alertType: .reminder(minutesBefore: overlayTiming)
        )
        scheduledAlerts.append(overlayAlert)
      }

      // Schedule sound alerts if enabled
      if prefs.soundEnabled {
        let soundTiming = prefs.soundMinutesBefore
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

    // Sort by trigger time
    scheduledAlerts.sort { $0.triggerDate < $1.triggerDate }

    logger.info("Scheduled \(self.scheduledAlerts.count) alerts")
  }

  private func scheduleOverlays(for events: [Event], overlayManager: OverlayManager) {
    let currentTime = Date()
    let overlayTiming = preferencesManager.overlayShowMinutesBefore

    for event in events {
      // Only schedule overlays for future events
      guard event.startDate > currentTime else { continue }

      overlayManager.scheduleOverlay(for: event, minutesBeforeMeeting: overlayTiming)
    }

    logger.info("Scheduled overlays for \(events.count) events")
  }

  private func startMonitoring(overlayManager: OverlayManager) {
    timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
      Task { @MainActor in
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

    for alert in triggeredAlerts {
      await handleTriggeredAlert(alert, overlayManager: overlayManager)
    }

    // Remove triggered alerts
    scheduledAlerts.removeAll { alert in
      triggeredAlerts.contains { $0.id == alert.id }
    }
  }

  private func handleTriggeredAlert(_ alert: ScheduledAlert, overlayManager: OverlayManager) async {
    logger.info("Handling triggered alert for event: \(alert.event.title)")

    switch alert.alertType {
    case .reminder:
      overlayManager.showOverlay(for: alert.event)

    case .meetingStart:
      if preferencesManager.autoJoinEnabled, let url = alert.event.primaryLink {
        logger.info("Auto-joining meeting: \(alert.event.title)")
        NSWorkspace.shared.open(url)
      }

    case .snooze:
      overlayManager.showOverlay(for: alert.event)
    }
  }

  func scheduleSnooze(for event: Event, minutes: Int) {
    let snoozeDate = Date().addingTimeInterval(TimeInterval(minutes * 60))

    // Don't snooze past the meeting start time
    let effectiveSnoozeDate = min(snoozeDate, event.startDate)

    let snoozeAlert = ScheduledAlert(
      event: event,
      triggerDate: effectiveSnoozeDate,
      alertType: .snooze(until: snoozeDate)
    )

    scheduledAlerts.append(snoozeAlert)
    scheduledAlerts.sort { $0.triggerDate < $1.triggerDate }

    logger.info("Scheduled snooze for \(minutes) minutes for event: \(event.title)")
  }
}
