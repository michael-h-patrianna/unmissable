import Cocoa
import OSLog
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
  private let logger = Logger(subsystem: "com.unmissable.app", category: "AppDelegate")

  func applicationDidFinishLaunching(_ notification: Notification) {
    logger.info("Unmissable app finished launching")

    // Hide dock icon for menu bar only app
    NSApp.setActivationPolicy(.accessory)

    // Request necessary permissions on first launch
    requestPermissions()
  }

  func applicationWillTerminate(_ notification: Notification) {
    logger.info("Unmissable app will terminate")
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool
  {
    // Show preferences when app is reopened
    if !flag {
      NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
    return true
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
