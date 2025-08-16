import Cocoa
import OSLog
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
  private let logger = Logger(subsystem: "com.unmissable.app", category: "AppDelegate")

  func applicationDidFinishLaunching(_ notification: Notification) {
    logger.info("Unmissable app finished launching")

    // Hide dock icon for menu bar only app
    NSApp.setActivationPolicy(.accessory)

    // Register URL scheme handler
    NSAppleEventManager.shared().setEventHandler(
      self,
      andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
      forEventClass: AEEventClass(kInternetEventClass),
      andEventID: AEEventID(kAEGetURL)
    )

    // Request necessary permissions on first launch
    requestPermissions()
  }

  func applicationWillTerminate(_ notification: Notification) {
    logger.info("Unmissable app will terminate")
  }

  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    // Allow normal termination when explicitly requested (e.g., via Quit menu)
    logger.info("Application termination requested")
    return .terminateNow
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool
  {
    // Show preferences when app is reopened
    if !flag {
      NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
    return true
  }

  @objc func handleURLEvent(
    _ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor
  ) {
    guard
      let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
      let url = URL(string: urlString)
    else {
      logger.error("Failed to parse URL from Apple Event")
      return
    }

    logger.info("Received URL: \(urlString)")

    // Handle OAuth callback using bundle ID scheme
    if url.scheme == "com.unmissable.app" {
      NotificationCenter.default.post(
        name: Notification.Name("OAuthCallback"),
        object: url
      )
    }
  }

  private func requestPermissions() {
    // Request accessibility permissions for global shortcuts
    let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
    let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)

    if !accessibilityEnabled {
      logger.warning("Accessibility permissions not granted")
    }
  }
}
