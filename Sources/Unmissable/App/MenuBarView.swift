import SwiftUI

// Event grouping structure for date-based organization
struct EventGroup {
  let title: String
  let events: [Event]
}

struct MenuBarView: View {
  @EnvironmentObject var appState: AppState
  @Environment(\.customDesign) private var design

  private var groupedEvents: [EventGroup] {
    let events =
      appState.preferencesManagerPublic.showTodayOnlyInMenuBar
      ? filteredTodayEvents
      : filteredEventsForDisplay

    return groupEventsByDate(events)
  }

  private var filteredTodayEvents: [Event] {
    let calendar = Calendar.current
    let today = Date()

    return appState.upcomingEvents.filter { event in
      calendar.isDate(event.startDate, inSameDayAs: today)
    }
  }

  private var filteredEventsForDisplay: [Event] {
    let calendar = Calendar.current
    let today = Date()
    let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
    let monday = getNextMondayIfNeeded(from: tomorrow, calendar: calendar)

    return appState.upcomingEvents.filter { event in
      calendar.isDate(event.startDate, inSameDayAs: today)
        || calendar.isDate(event.startDate, inSameDayAs: tomorrow)
        || (monday != nil && calendar.isDate(event.startDate, inSameDayAs: monday!))
    }
  }

  private func getNextMondayIfNeeded(from tomorrow: Date, calendar: Calendar) -> Date? {
    // If tomorrow is Saturday (weekday 7), also include Monday
    if calendar.component(.weekday, from: tomorrow) == 7 {
      return calendar.date(byAdding: .day, value: 2, to: tomorrow)
    }
    return nil
  }

  private func groupEventsByDate(_ events: [Event]) -> [EventGroup] {
    let calendar = Calendar.current
    let today = Date()
    let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

    var groups: [EventGroup] = []

    // Group events by date
    let todayEvents = events.filter { calendar.isDate($0.startDate, inSameDayAs: today) }
    let tomorrowEvents = events.filter { calendar.isDate($0.startDate, inSameDayAs: tomorrow) }

    // Get Monday events if tomorrow is Saturday
    var mondayEvents: [Event] = []
    if calendar.component(.weekday, from: tomorrow) == 7,
      let monday = calendar.date(byAdding: .day, value: 2, to: tomorrow)
    {
      mondayEvents = events.filter { calendar.isDate($0.startDate, inSameDayAs: monday) }
    }

    // Add non-empty groups
    if !todayEvents.isEmpty {
      groups.append(EventGroup(title: "Today", events: todayEvents))
    }

    if !tomorrowEvents.isEmpty {
      groups.append(EventGroup(title: "Tomorrow", events: tomorrowEvents))
    }

    if !mondayEvents.isEmpty {
      groups.append(EventGroup(title: "Monday", events: mondayEvents))
    }

    return groups
  }

  var body: some View {
    VStack(spacing: 0) {
      // Header with custom styling
      VStack(spacing: 0) {
        HStack {
          HStack(spacing: design.spacing.md) {
            Image(systemName: "calendar.badge.clock")
              .foregroundColor(design.colors.accent)
              .font(.system(size: 18, weight: .semibold))

            Text("Unmissable")
              .font(design.fonts.headline)
              .foregroundColor(design.colors.textPrimary)
          }

          Spacer()

          CustomStatusIndicator(status: connectionStatus, size: 12)
        }
        .padding(.horizontal, design.spacing.lg)
        .padding(.vertical, design.spacing.lg)
        .background(design.colors.background)

        Rectangle()
          .fill(design.colors.divider)
          .frame(height: 1)
      }

      // Content area with custom background
      VStack(spacing: design.spacing.lg) {
        if !appState.isConnectedToCalendar {
          // Connection error state
          VStack(spacing: design.spacing.lg) {
            if let authError = appState.authError {
              CustomCard(style: .flat) {
                VStack(alignment: .leading, spacing: design.spacing.sm) {
                  HStack(spacing: design.spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                      .foregroundColor(design.colors.error)
                      .font(.system(size: 16, weight: .medium))

                    Text("Connection Error")
                      .font(design.fonts.subheadline)
                      .foregroundColor(design.colors.error)
                  }

                  Text(authError)
                    .font(design.fonts.caption1)
                    .foregroundColor(design.colors.textSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                  if authError.contains("configuration") {
                    Text("See OAUTH_SETUP_GUIDE.md for setup instructions")
                      .font(design.fonts.caption2)
                      .foregroundColor(design.colors.interactive)
                      .lineLimit(2)
                      .multilineTextAlignment(.leading)
                  }
                }
                .padding(design.spacing.md)
              }
            }

            CustomButton("Connect Google Calendar", icon: "link", style: .primary) {
              Task {
                await appState.connectToCalendar()
              }
            }
          }
          .padding(.horizontal, design.spacing.lg)

        } else {
          // Connected state
          VStack(spacing: design.spacing.lg) {
            // Sync status with custom design
            HStack {
              HStack(spacing: design.spacing.sm) {
                syncStatusIcon
                Text(appState.syncStatus.description)
                  .font(design.fonts.caption1)
                  .foregroundColor(design.colors.textSecondary)
              }

              Spacer()

              if case .syncing = appState.syncStatus {
                ProgressView()
                  .scaleEffect(0.7)
                  .tint(design.colors.accent)
              } else {
                CustomButton("Sync", style: .minimal) {
                  Task {
                    await appState.syncNow()
                  }
                }
              }
            }
            .padding(.horizontal, design.spacing.lg)

            // Events list with custom cards and grouping
            if groupedEvents.isEmpty {
              CustomCard(style: .flat) {
                HStack(spacing: design.spacing.sm) {
                  Image(systemName: "calendar")
                    .foregroundColor(design.colors.textTertiary)
                    .font(.system(size: 16))

                  Text("No upcoming meetings")
                    .font(design.fonts.callout)
                    .foregroundColor(design.colors.textTertiary)
                }
                .padding(design.spacing.lg)
              }
              .padding(.horizontal, design.spacing.lg)
            } else {
              VStack(spacing: design.spacing.md) {
                // Show today only toggle
                HStack {
                  Text("Show today only")
                    .font(design.fonts.caption1)
                    .foregroundColor(design.colors.textSecondary)

                  Spacer()

                  CustomToggle(
                    isOn: Binding(
                      get: { appState.preferencesManagerPublic.showTodayOnlyInMenuBar },
                      set: { appState.preferencesManagerPublic.showTodayOnlyInMenuBar = $0 }
                    )
                  )
                }
                .padding(.horizontal, design.spacing.lg)

                // Grouped events
                ForEach(groupedEvents.indices, id: \.self) { groupIndex in
                  let group = groupedEvents[groupIndex]

                  VStack(spacing: design.spacing.sm) {
                    // Group header
                    HStack {
                      Text(group.title)
                        .font(design.fonts.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(design.colors.accent)

                      Spacer()
                    }
                    .padding(.horizontal, design.spacing.lg)

                    // Group events
                    ForEach(group.events.prefix(3)) { event in
                      CustomEventRow(event: event)
                        .padding(.horizontal, design.spacing.lg)
                    }
                  }
                }
              }
            }
          }
        }
      }
      .padding(.vertical, design.spacing.lg)
      .background(design.colors.backgroundSecondary)

      // Footer with actions
      VStack(spacing: 0) {
        Rectangle()
          .fill(design.colors.divider)
          .frame(height: 1)

        HStack {
          CustomButton("Preferences", style: .minimal) {
            appState.showPreferences()
          }

          Spacer()

          CustomButton("Quit", style: .minimal) {
            NSApplication.shared.terminate(nil)
          }
        }
        .padding(.horizontal, design.spacing.lg)
        .padding(.vertical, design.spacing.md)
        .background(design.colors.background)
      }
    }
    .background(design.colors.background)
    .frame(width: 340)
  }

  @ViewBuilder
  private var syncStatusIcon: some View {
    Group {
      switch appState.syncStatus {
      case .idle:
        Image(systemName: "checkmark.circle.fill")
          .foregroundColor(design.colors.success)
      case .syncing:
        Image(systemName: "arrow.triangle.2.circlepath")
          .foregroundColor(design.colors.accent)
      case .offline:
        Image(systemName: "wifi.slash")
          .foregroundColor(design.colors.warning)
      case .error:
        Image(systemName: "exclamationmark.circle.fill")
          .foregroundColor(design.colors.error)
      }
    }
    .font(.system(size: 14, weight: .medium))
  }

  private var connectionStatus: CustomStatusIndicator.Status {
    if !appState.isConnectedToCalendar {
      return .disconnected
    }

    switch appState.syncStatus {
    case .idle:
      return .connected
    case .syncing:
      return .connecting
    case .offline:
      return .disconnected
    case .error:
      return .error
    }
  }
}

// MARK: - Custom Event Row

struct CustomEventRow: View {
  let event: Event
  @Environment(\.customDesign) private var design

  var body: some View {
    CustomCard(style: .standard) {
      HStack(spacing: design.spacing.md) {
        VStack(alignment: .leading, spacing: design.spacing.xs) {
          Text(event.title)
            .font(design.fonts.callout)
            .fontWeight(.medium)
            .foregroundColor(design.colors.textPrimary)
            .lineLimit(1)

          HStack(spacing: design.spacing.xs) {
            Image(systemName: "clock.fill")
              .foregroundColor(design.colors.accent)
              .font(.system(size: 12, weight: .medium))

            Text(event.startDate, style: .time)
              .font(design.fonts.caption1)
              .foregroundColor(design.colors.textSecondary)
          }
        }

        Spacer()

        HStack(spacing: design.spacing.md) {
          if event.isOnlineMeeting {
            Image(systemName: event.provider?.iconName ?? "link")
              .foregroundColor(design.colors.accent)
              .font(.system(size: 14, weight: .medium))
          }

          if event.isOnlineMeeting, let primaryLink = event.primaryLink {
            CustomButton("Join", icon: "video.fill", style: .secondary) {
              NSWorkspace.shared.open(primaryLink)
            }
          }
        }
      }
      .padding(design.spacing.md)
    }
  }
}

#Preview {
  MenuBarView()
    .environmentObject(AppState())
    .customThemedEnvironment()
}
