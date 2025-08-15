import Combine
import Foundation

@MainActor
class PreferencesManager: ObservableObject {
  private let userDefaults = UserDefaults.standard

  // Alert timing
  @Published var defaultAlertMinutes: Int = 1 {
    didSet { userDefaults.set(defaultAlertMinutes, forKey: "defaultAlertMinutes") }
  }

  @Published var useLengthBasedTiming: Bool = false {
    didSet { userDefaults.set(useLengthBasedTiming, forKey: "useLengthBasedTiming") }
  }

  @Published var shortMeetingAlertMinutes: Int = 1 {
    didSet { userDefaults.set(shortMeetingAlertMinutes, forKey: "shortMeetingAlertMinutes") }
  }

  @Published var mediumMeetingAlertMinutes: Int = 2 {
    didSet { userDefaults.set(mediumMeetingAlertMinutes, forKey: "mediumMeetingAlertMinutes") }
  }

  @Published var longMeetingAlertMinutes: Int = 5 {
    didSet { userDefaults.set(longMeetingAlertMinutes, forKey: "longMeetingAlertMinutes") }
  }

  // Sync settings
  @Published var syncIntervalSeconds: Int = 60 {
    didSet { userDefaults.set(syncIntervalSeconds, forKey: "syncIntervalSeconds") }
  }

  @Published var includeAllDayEvents: Bool = false {
    didSet { userDefaults.set(includeAllDayEvents, forKey: "includeAllDayEvents") }
  }

  // Appearance
  @Published var appearanceTheme: AppearanceTheme = .system {
    didSet { userDefaults.set(appearanceTheme.rawValue, forKey: "appearanceTheme") }
  }

  @Published var overlayOpacity: Double = 0.9 {
    didSet { userDefaults.set(overlayOpacity, forKey: "overlayOpacity") }
  }

  @Published var overlayShowMinutesBefore: Int = 5 {
    didSet { userDefaults.set(overlayShowMinutesBefore, forKey: "overlayShowMinutesBefore") }
  }

  @Published var fontSize: FontSize = .medium {
    didSet { userDefaults.set(fontSize.rawValue, forKey: "fontSize") }
  }

  @Published var minimalMode: Bool = false {
    didSet { userDefaults.set(minimalMode, forKey: "minimalMode") }
  }

  @Published var showOnAllDisplays: Bool = true {
    didSet { userDefaults.set(showOnAllDisplays, forKey: "showOnAllDisplays") }
  }

  // Sound
  @Published var playAlertSound: Bool = true {
    didSet { userDefaults.set(playAlertSound, forKey: "playAlertSound") }
  }

  // Convenience aliases for overlay scheduling
  var soundEnabled: Bool { playAlertSound }
  var soundMinutesBefore: Int { defaultAlertMinutes }

  @Published var alertVolume: Double = 0.7 {
    didSet { userDefaults.set(alertVolume, forKey: "alertVolume") }
  }

  // Focus mode
  @Published var overrideFocusMode: Bool = true {
    didSet { userDefaults.set(overrideFocusMode, forKey: "overrideFocusMode") }
  }

  // Auto-join
  @Published var autoJoinEnabled: Bool = false {
    didSet { userDefaults.set(autoJoinEnabled, forKey: "autoJoinEnabled") }
  }

  init() {
    loadPreferences()
  }

  private func loadPreferences() {
    defaultAlertMinutes = userDefaults.object(forKey: "defaultAlertMinutes") as? Int ?? 1
    useLengthBasedTiming = userDefaults.bool(forKey: "useLengthBasedTiming")
    shortMeetingAlertMinutes = userDefaults.object(forKey: "shortMeetingAlertMinutes") as? Int ?? 1
    mediumMeetingAlertMinutes =
      userDefaults.object(forKey: "mediumMeetingAlertMinutes") as? Int ?? 2
    longMeetingAlertMinutes = userDefaults.object(forKey: "longMeetingAlertMinutes") as? Int ?? 5

    syncIntervalSeconds = userDefaults.object(forKey: "syncIntervalSeconds") as? Int ?? 60
    includeAllDayEvents = userDefaults.bool(forKey: "includeAllDayEvents")

    if let themeRawValue = userDefaults.object(forKey: "appearanceTheme") as? String,
      let theme = AppearanceTheme(rawValue: themeRawValue)
    {
      appearanceTheme = theme
    }

    overlayOpacity = userDefaults.object(forKey: "overlayOpacity") as? Double ?? 0.9
    overlayShowMinutesBefore = userDefaults.object(forKey: "overlayShowMinutesBefore") as? Int ?? 5

    if let fontSizeRawValue = userDefaults.object(forKey: "fontSize") as? String,
      let fontSize = FontSize(rawValue: fontSizeRawValue)
    {
      self.fontSize = fontSize
    }

    minimalMode = userDefaults.bool(forKey: "minimalMode")
    showOnAllDisplays = userDefaults.object(forKey: "showOnAllDisplays") as? Bool ?? true

    playAlertSound = userDefaults.object(forKey: "playAlertSound") as? Bool ?? true
    alertVolume = userDefaults.object(forKey: "alertVolume") as? Double ?? 0.7

    overrideFocusMode = userDefaults.object(forKey: "overrideFocusMode") as? Bool ?? true
    autoJoinEnabled = userDefaults.bool(forKey: "autoJoinEnabled")
  }

  func alertMinutes(for event: Event) -> Int {
    guard useLengthBasedTiming else {
      return defaultAlertMinutes
    }

    let durationMinutes = Int(event.duration / 60)

    if durationMinutes < 30 {
      return shortMeetingAlertMinutes
    } else if durationMinutes <= 60 {
      return mediumMeetingAlertMinutes
    } else {
      return longMeetingAlertMinutes
    }
  }
}

enum AppearanceTheme: String, CaseIterable {
  case system = "system"
  case light = "light"
  case dark = "dark"

  var displayName: String {
    switch self {
    case .system:
      return "Follow System"
    case .light:
      return "Light"
    case .dark:
      return "Dark"
    }
  }
}

enum FontSize: String, CaseIterable {
  case small = "small"
  case medium = "medium"
  case large = "large"

  var scale: Double {
    switch self {
    case .small:
      return 0.8
    case .medium:
      return 1.0
    case .large:
      return 1.4
    }
  }
}
