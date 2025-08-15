import SwiftUI

struct PreferencesView: View {
  @EnvironmentObject var appState: AppState
  @StateObject private var preferences = PreferencesManager()

  var body: some View {
    TabView {
      GeneralPreferencesView()
        .environmentObject(preferences)
        .tabItem {
          Label("General", systemImage: "gear")
        }

      CalendarPreferencesView()
        .environmentObject(appState)
        .environmentObject(preferences)
        .tabItem {
          Label("Calendars", systemImage: "calendar")
        }

      AppearancePreferencesView()
        .environmentObject(preferences)
        .tabItem {
          Label("Appearance", systemImage: "paintbrush")
        }

      ShortcutsPreferencesView()
        .environmentObject(preferences)
        .tabItem {
          Label("Shortcuts", systemImage: "keyboard")
        }
    }
    .frame(width: 600, height: 400)
  }
}

struct GeneralPreferencesView: View {
  @EnvironmentObject var preferences: PreferencesManager

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("General Settings")
        .font(.title2)
        .bold()

      // Alert timing
      VStack(alignment: .leading, spacing: 8) {
        Text("Alert Timing")
          .font(.headline)

        HStack {
          Text("Default alert time:")
          Picker("", selection: $preferences.defaultAlertMinutes) {
            ForEach([1, 2, 5, 10, 15], id: \.self) { minutes in
              Text("\(minutes) minute\(minutes == 1 ? "" : "s")")
                .tag(minutes)
            }
          }
          .pickerStyle(.menu)
          .frame(width: 120)
          Text("before meeting")
          Spacer()
        }

        Toggle(
          "Use different timing based on meeting length", isOn: $preferences.useLengthBasedTiming)

        if preferences.useLengthBasedTiming {
          VStack(alignment: .leading, spacing: 4) {
            HStack {
              Text("Short meetings (<30 min):")
              Spacer()
              Picker("", selection: $preferences.shortMeetingAlertMinutes) {
                ForEach([1, 2, 5], id: \.self) { minutes in
                  Text("\(minutes) min").tag(minutes)
                }
              }
              .pickerStyle(.menu)
              .frame(width: 80)
            }

            HStack {
              Text("Medium meetings (30-60 min):")
              Spacer()
              Picker("", selection: $preferences.mediumMeetingAlertMinutes) {
                ForEach([2, 5, 10], id: \.self) { minutes in
                  Text("\(minutes) min").tag(minutes)
                }
              }
              .pickerStyle(.menu)
              .frame(width: 80)
            }

            HStack {
              Text("Long meetings (>60 min):")
              Spacer()
              Picker("", selection: $preferences.longMeetingAlertMinutes) {
                ForEach([5, 10, 15], id: \.self) { minutes in
                  Text("\(minutes) min").tag(minutes)
                }
              }
              .pickerStyle(.menu)
              .frame(width: 80)
            }
          }
          .padding(.leading, 16)
        }
      }

      Divider()

      // Sync settings
      VStack(alignment: .leading, spacing: 8) {
        Text("Sync Settings")
          .font(.headline)

        HStack {
          Text("Sync interval:")
          Picker("", selection: $preferences.syncIntervalSeconds) {
            Text("15 seconds").tag(15)
            Text("30 seconds").tag(30)
            Text("1 minute").tag(60)
            Text("2 minutes").tag(120)
            Text("5 minutes").tag(300)
          }
          .pickerStyle(.menu)
          .frame(width: 120)
          Spacer()
        }

        Toggle("Include all-day events", isOn: $preferences.includeAllDayEvents)
      }

      Spacer()
    }
    .padding()
  }
}

struct CalendarPreferencesView: View {
  @EnvironmentObject var appState: AppState
  @EnvironmentObject var preferences: PreferencesManager
  @State private var isConnecting = false

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Calendar Connection")
        .font(.title2)
        .bold()

      if appState.isConnectedToCalendar {
        HStack {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.green)
          Text("Connected to Google Calendar")

          if let email = appState.userEmail {
            Text("(\(email))")
              .foregroundColor(.secondary)
          }

          Spacer()
        }

        Button("Disconnect") {
          Task {
            await appState.disconnectFromCalendar()
          }
        }
        .buttonStyle(.borderless)
        .foregroundColor(.red)

        Divider()

        // Calendar Selection
        VStack(alignment: .leading, spacing: 12) {
          Text("Select Calendars")
            .font(.headline)

          Text("Choose which calendars to monitor for meeting alerts")
            .font(.caption)
            .foregroundColor(.secondary)

          if appState.calendars.isEmpty {
            HStack {
              ProgressView()
                .scaleEffect(0.8)
              Text("Loading calendars...")
                .foregroundColor(.secondary)
            }
          } else {
            ForEach(appState.calendars) { calendar in
              CalendarSelectionRow(
                calendar: calendar,
                onToggle: { isSelected in
                  appState.updateCalendarSelection(calendar.id, isSelected: isSelected)
                }
              )
            }
          }
        }

      } else {
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            Image(systemName: "exclamationmark.circle")
              .foregroundColor(.orange)
            Text("Not connected to Google Calendar")
          }

          Text(
            "Connect your Google Calendar to receive meeting alerts and never miss important meetings."
          )
          .foregroundColor(.secondary)
          .font(.caption)

          Button("Connect Google Calendar") {
            isConnecting = true
            Task {
              await appState.connectToCalendar()
              isConnecting = false
            }
          }
          .buttonStyle(.borderedProminent)
          .disabled(isConnecting)

          if isConnecting {
            HStack {
              ProgressView()
                .scaleEffect(0.8)
              Text("Connecting...")
                .foregroundColor(.secondary)
            }
          }

          if let error = appState.authError {
            Text("Error: \(error)")
              .foregroundColor(.red)
              .font(.caption)
          }
        }
      }

      Spacer()
    }
    .padding()
  }
}

struct CalendarSelectionRow: View {
  let calendar: CalendarInfo
  let onToggle: (Bool) -> Void

  var body: some View {
    HStack {
      Toggle(
        "",
        isOn: Binding(
          get: { calendar.isSelected },
          set: { onToggle($0) }
        )
      )
      .toggleStyle(.checkbox)

      VStack(alignment: .leading, spacing: 2) {
        HStack {
          Text(calendar.name)
            .font(.body)

          if calendar.isPrimary {
            Text("PRIMARY")
              .font(.caption)
              .foregroundColor(.blue)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(Color.blue.opacity(0.1))
              .cornerRadius(4)
          }
        }

        if let description = calendar.description, !description.isEmpty {
          Text(description)
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(2)
        }
      }

      Spacer()
    }
    .padding(.vertical, 4)
  }
}

struct AppearancePreferencesView: View {
  @EnvironmentObject var preferences: PreferencesManager

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Appearance")
        .font(.title2)
        .bold()

      // Theme
      VStack(alignment: .leading, spacing: 8) {
        Text("Theme")
          .font(.headline)

        Picker("", selection: $preferences.appearanceTheme) {
          Text("Follow System").tag(AppearanceTheme.system)
          Text("Light").tag(AppearanceTheme.light)
          Text("Dark").tag(AppearanceTheme.dark)
        }
        .pickerStyle(.segmented)
      }

      // Overlay settings
      VStack(alignment: .leading, spacing: 8) {
        Text("Overlay Settings")
          .font(.headline)

        HStack {
          Text("Opacity:")
          Slider(value: $preferences.overlayOpacity, in: 0.2...0.9, step: 0.1)
          Text("\(Int(preferences.overlayOpacity * 100))%")
            .frame(width: 40)
        }

        HStack {
          Text("Font size:")
          Picker("", selection: $preferences.fontSize) {
            Text("Small").tag(FontSize.small)
            Text("Medium").tag(FontSize.medium)
            Text("Large").tag(FontSize.large)
          }
          .pickerStyle(.segmented)
        }

        Toggle("Minimal details (title and time only)", isOn: $preferences.minimalMode)

        Toggle("Show on all displays", isOn: $preferences.showOnAllDisplays)
      }

      // Sound
      VStack(alignment: .leading, spacing: 8) {
        Text("Sound")
          .font(.headline)

        Toggle("Play alert sound", isOn: $preferences.playAlertSound)

        if preferences.playAlertSound {
          HStack {
            Text("Volume:")
            Slider(value: $preferences.alertVolume, in: 0.0...1.0, step: 0.1)
            Text("\(Int(preferences.alertVolume * 100))%")
              .frame(width: 40)
          }
          .padding(.leading, 16)
        }
      }

      Spacer()
    }
    .padding()
  }
}

struct ShortcutsPreferencesView: View {
  @EnvironmentObject var preferences: PreferencesManager

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Keyboard Shortcuts")
        .font(.title2)
        .bold()

      Text("Global shortcuts work even when other apps are focused")
        .font(.caption)
        .foregroundColor(.secondary)

      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text("Dismiss overlay:")
          Spacer()
          // TODO: Implement shortcut recorder
          Text("⌘⎋")
            .font(.system(.body, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(4)
        }

        HStack {
          Text("Join meeting:")
          Spacer()
          Text("⌘⏎")
            .font(.system(.body, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(4)
        }
      }

      Divider()

      VStack(alignment: .leading, spacing: 8) {
        Text("Focus Mode Integration")
          .font(.headline)

        Toggle("Override Do Not Disturb for meeting alerts", isOn: $preferences.overrideFocusMode)

        if !preferences.overrideFocusMode {
          Text("Alerts will be delayed when Do Not Disturb is active")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.leading, 16)
        }
      }

      Spacer()
    }
    .padding()
  }
}

#Preview {
  PreferencesView()
    .environmentObject(AppState())
}
