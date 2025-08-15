import SwiftUI

struct MenuBarView: View {
  @EnvironmentObject var appState: AppState
  @Environment(\.openSettings) private var openSettings

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Header
      HStack {
        Image(systemName: "calendar.badge.clock")
          .foregroundColor(.primary)
        Text("Unmissable")
          .font(.headline)
        Spacer()
        statusIndicator
      }
      .padding(.horizontal)
      .padding(.top, 8)

      Divider()

      // Connection Status
      if !appState.isConnectedToCalendar {
        if let authError = appState.authError {
          VStack(alignment: .leading, spacing: 4) {
            Text("Connection Error")
              .font(.caption)
              .foregroundColor(.red)
            Text(authError)
              .font(.caption2)
              .foregroundColor(.secondary)
              .lineLimit(3)

            if authError.contains("configuration") {
              Text("See OAUTH_SETUP_GUIDE.md for setup instructions")
                .font(.caption2)
                .foregroundColor(.blue)
                .lineLimit(2)
            }
          }
          .padding(.horizontal)
        }

        Button("Connect Google Calendar") {
          Task {
            await appState.connectToCalendar()
          }
        }
        .buttonStyle(.borderedProminent)
        .padding(.horizontal)
      } else {
        // Sync Status
        HStack {
          Text(appState.syncStatus.description)
            .font(.caption)
            .foregroundColor(.secondary)
          Spacer()
          if case .syncing = appState.syncStatus {
            ProgressView()
              .scaleEffect(0.5)
          } else {
            Button("Sync Now") {
              Task {
                await appState.syncNow()
              }
            }
            .buttonStyle(.borderless)
            .font(.caption)
          }
        }
        .padding(.horizontal)

        // Upcoming Events
        if appState.upcomingEvents.isEmpty {
          Text("No upcoming meetings")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal)
        } else {
          ForEach(appState.upcomingEvents.prefix(3)) { event in
            EventRowView(event: event)
          }
        }
      }

      Divider()

      // Actions
      HStack {
        Button("Preferences") {
          openSettings()
        }
        .buttonStyle(.borderless)

        Spacer()

        Button("Quit") {
          NSApplication.shared.terminate(nil)
        }
        .buttonStyle(.borderless)
      }
      .padding(.horizontal)
      .padding(.bottom, 8)
    }
    .frame(width: 300)
  }

  @ViewBuilder
  private var statusIndicator: some View {
    Circle()
      .fill(statusColor)
      .frame(width: 8, height: 8)
  }

  private var statusColor: Color {
    if !appState.isConnectedToCalendar {
      return .red
    }

    switch appState.syncStatus {
    case .idle:
      return .green
    case .syncing:
      return .yellow
    case .offline:
      return .orange
    case .error:
      return .red
    }
  }
}

struct EventRowView: View {
  let event: Event

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text(event.title)
          .font(.caption)
          .lineLimit(1)

        Text(event.startDate, style: .time)
          .font(.caption2)
          .foregroundColor(.secondary)
      }

      Spacer()

      Spacer()

      if event.isOnlineMeeting, let primaryLink = event.primaryLink {
        Button(action: {
          NSWorkspace.shared.open(primaryLink)
        }) {
          HStack {
            Image(systemName: "video.fill")
            Text("Join")
          }
          .foregroundColor(.blue)
        }
        .buttonStyle(PlainButtonStyle())
      }

      if event.isOnlineMeeting {
        Image(systemName: event.provider?.iconName ?? "link")
          .foregroundColor(.accentColor)
          .font(.caption)
      }
    }
    .padding(.horizontal)
    .padding(.vertical, 4)
  }
}

#Preview {
  MenuBarView()
    .environmentObject(AppState())
}
