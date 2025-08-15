import SwiftUI

@main
struct UnmissableApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @StateObject private var appState = AppState()

  var body: some Scene {
    MenuBarExtra("Unmissable", systemImage: "calendar.badge.clock") {
      MenuBarView()
        .environmentObject(appState)
    }
    .menuBarExtraStyle(.window)

    // Preferences window
    Settings {
      PreferencesView()
        .environmentObject(appState)
    }
  }
}
