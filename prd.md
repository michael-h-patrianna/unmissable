# Unmissable — Product Requirements Document (PRD)

Date: 2025-08-15
Version: 1.1 (refined for clarity, testability, and coverage)

## LLM Implementation Guidance

This PRD is intended to be executed by an LLM coding agent. Follow these guardrails: prefer standard Swift APIs, small modules, and test-first development. All user-visible behaviors must match Acceptance Criteria below.

## Tech Stack (Authoritative)

- Platform: macOS 14+ (Sonoma or later)
- Language: Swift 5.10+
- UI: SwiftUI for app UI; AppKit (NSWindow/NSWindowLevel) for full-screen overlay windows
- Build: Xcode 15+; Swift Package Manager (SPM) for dependencies
- Storage: SQLite via GRDB.swift for local cache; UserDefaults for preferences
- OAuth/OIDC: AppAuth for iOS/macOS (ASWebAuthenticationSession)
- Networking: URLSession
- Keychain: KeychainAccess
- Logging: OSLog
- Scheduling: Combine timers; DispatchSourceTimer for precision
- Global Shortcuts: Magnet
- Audio: AVFoundation
- Testing: XCTest (unit), XCUITest (UI/E2E), SnapshotTesting for overlay UI
- Lint/Format: SwiftLint, SwiftFormat
- CI: GitHub Actions (macOS 14 runner), xcodebuild + xcresult artifacts

## Repository Layout

```text
unmissable/
├─ Unmissable.xcodeproj
├─ Unmissable/
│  ├─ App/
│  ├─ Features/
│  │  ├─ CalendarConnect/
│  │  ├─ EventSync/
│  │  ├─ Overlay/
│  │  ├─ Join/
│  │  ├─ Preferences/
│  │  ├─ Snooze/
│  │  ├─ FocusMode/
│  │  └─ Shortcuts/
│  ├─ Core/
│  ├─ Models/
│  ├─ Resources/
│  └─ Config/
├─ Tests/
│  ├─ Unit/
│  ├─ Snapshot/
│  └─ Integration/
├─ UITests/
├─ Scripts/
├─ Package.swift
└─ README.md
```

## Dependencies (SPM)

- [AppAuth](https://github.com/openid/AppAuth-iOS)
- [GRDB.swift](https://github.com/groue/GRDB.swift)
- [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess)
- [Magnet](https://github.com/Clipy/Magnet)
- [SnapshotTesting](https://github.com/pointfreeco/swift-snapshot-testing)
- [SwiftLint](https://github.com/realm/SwiftLint)
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat)

## Permissions & Entitlements

- Keychain access (store OAuth tokens)
- Network client entitlement (HTTPS)
- Accessibility usage description (global shortcuts)
- Hardened Runtime; code signing and notarization for release

## Build & Run

- Dev (VS Code): edit, lint, and run tests from VS Code using the Xcode toolchain. Use tasks/launch configs or commands below.
- Dev (Xcode): open Xcode, scheme “Unmissable,” run on macOS 14+
- CI: xcodebuild -scheme Unmissable -destination 'platform=macOS' build test

## VS Code Development (Authoritative)

### Required extensions

- Swift (swift-server-work-group.swift) — SourceKit-LSP, build/test integration
- CodeLLDB (vadimcn.vscode-lldb) — debugging
- SwiftFormat (or run via Scripts) and SwiftLint (optional VS Code wrappers)

### Verify toolchain

```bash
xcodebuild -version
swift --version
xcode-select -p
```

### Build and test from VS Code

- Build app (project):

```bash
xcodebuild -scheme Unmissable -destination 'platform=macOS' build
```

- Run unit+integration tests:

```bash
xcodebuild -scheme Unmissable -destination 'platform=macOS' test
```

- Run SwiftPM-only tests (for pure packages):

```bash
swift test
```

### Debugging

- Use CodeLLDB to launch the built app binary or attach to the running process.
- Note: SwiftUI live previews are Xcode-only. Use SnapshotTesting and XCUITest instead.

### Signing & entitlements

- Automatic signing via xcodebuild requires being signed in to Xcode with a developer account (you can open Xcode once to sign in and accept licenses).
- For distribution/notarization, use Xcode archive or dedicated CI steps; not required for dev.

## Coding Standards

- Swift API Design Guidelines; small testable types
- No force unwraps in production paths; handle error cases explicitly
- OSLog with redacted PII; levels: info/warning/error
- Enforce SwiftLint/SwiftFormat in CI

## Test Automation Strategy (Authoritative)

- Unit tests: ≥ 80% coverage for Core/Features
- Snapshot tests: all overlay states (themes, opacity, minimal mode, multi-display)
- Integration tests: CalendarService with URLProtocol stubs; no live API calls
- UI tests: time-travelable scheduler (inject Clock protocol) to trigger overlays; verify shortcuts and join flows
- Deterministic time and network; CI fails if coverage < 80% or snapshots differ

## Data Models & Contracts

- Event: id (String), title (String), startDate (Date), endDate (Date), organizer (String?), isAllDay (Bool), calendarId (String), timezone (String), links: [URL], provider (Provider?), snoozeUntil (Date?), autoJoinEnabled (Bool), createdAt/updatedAt (Date)
- Provider enum: meet | zoom | teams | webex | generic
- CalendarService: fetchEvents(range: DateInterval) -> [Event]; selectedCalendars -> [String]
- LinkParser: parse(text: String, location: String?) -> (primary: URL?, all: [URL], provider: Provider?)
- Scheduler: schedule(events: [Event], preferences: Preferences) -> [ScheduledAlert]

## CI Pipeline (GitHub Actions)

- Jobs: lint/format → build → unit+integration → snapshot → selected UI tests
- Artifacts: xcresult, coverage (xccov), snapshots
- Cache: SPM dependencies by hash

## Milestones (Sequence for Agent)

1) Project scaffold + CI + lint/format
2) OAuth + calendar selection + Keychain storage
3) Event sync (polling) + local cache + timezone correctness
4) Link parsing + provider enum + quick join (basic)
5) Overlay engine (blocking, countdown) + snapshot tests
6) Preferences (timing/themes/opacity/minimal) + Snooze
7) Global shortcuts + Focus/DND integration + multi-display
8) Offline handling + reliability polish + metrics

## Summary

- Purpose: Ensure users on macOS never miss meetings by showing an unavoidable, configurable full‑screen overlay tied to Google Calendar.
- Success: Clear, testable acceptance criteria. Added missing features (onboarding, permissions, preferences, reliability, accessibility, privacy, error handling).

## Non-Functional Overview

- Privacy/Security: Tokens in macOS Keychain; least scopes; all data local; HTTPS only; code-signed/notarized.
- Performance: ≤ 2% avg CPU idle, ≤ 150 MB RAM, overlay render < 500 ms after trigger/wake.
- Accessibility: WCAG AA contrast; VoiceOver labels; keyboard navigation; adjustable font size.
- Reliability: Offline cache for next 24 h; wake/unlock handling; retries with exponential backoff.
- Localization: English first; structure ready for future locales.

## Test Language Convention

Use BDD-style acceptance criteria: GIVEN (preconditions), WHEN (action/trigger), THEN (measurable outcome). Include negative and edge cases where relevant.

---

## Epic E1 — Meeting Detection and Integration

Goal: The app automatically detects upcoming meetings from the user’s Google Calendar and displays an unmissable notification.

### Story E1-S1 — Calendar Connection (OAuth & Calendar Selection)

As a macOS user, I want to connect my Google Calendar so the app can detect upcoming meetings.

#### Requirements — E1-S1

- Google OAuth 2.0 sign-in with offline access and token refresh.
- User can select which calendars to monitor (multiple supported).
- Tokens stored in macOS Keychain; refresh handled automatically.
- Visible confirmation of connected account and selected calendars.

#### Acceptance Criteria — E1-S1

- GIVEN the app is launched first time, WHEN I choose “Connect Google Calendar,” THEN I’m taken through Google OAuth and returned signed in with my email shown.
- GIVEN I have multiple calendars, WHEN I open “Preferences → Calendars,” THEN I can toggle individual calendars on/off and the selection persists after restart.
- GIVEN my token expires, WHEN the app attempts to sync, THEN it silently refreshes using the refresh token without prompting, unless refresh fails due to revoked access.
- GIVEN I revoke access in Google, WHEN the app next syncs, THEN I see a non-blocking error banner with a “Reconnect” action.

#### Test Cases — E1-S1

- OAuth happy path returns access and refresh tokens saved to Keychain.
- Calendar list loads with accurate counts and names; toggles persist across relaunch.
- Revoked token shows reconnect CTA; successful reconnect resumes sync within 60 s.

### Story E1-S2 — Meeting Detection (Polling & Parsing)

As a connected calendar user, I want the app to fetch upcoming events in real time so it can alert me before meetings.

#### Requirements — E1-S2

- Poll events at least every 60 seconds (user-configurable 15–300 s).
- Detect online meeting links: Google Meet, Zoom, Microsoft Teams, Webex, and generic URLs.
- Ignore all-day events unless explicitly enabled in settings.
- Adjust meeting times to the Mac’s system timezone.

#### Acceptance Criteria — E1-S2

- GIVEN sync is enabled, WHEN 60 s elapse (default), THEN events for the next 24 h are refreshed and cached locally.
- GIVEN an event has a Meet/Zoom/Teams/Webex link in location/description/conferenceData, WHEN parsed, THEN the provider and URL are stored on the event.
- GIVEN an event is all-day and “Include all-day events” is off, WHEN syncing, THEN the event is excluded from alert scheduling.
- GIVEN my Mac timezone changes, WHEN a subsequent sync runs, THEN event local times update accordingly within the next refresh.

#### Test Cases — E1-S2

- Parsing identifies first valid join URL when multiple are present; user choice handled at overlay time (see E3-S1).
- Timezone switch (e.g., PST→EST) updates next alert trigger correctly within ≤ 60 s.
- Configurable polling validated at min 15 s and max 300 s without errors.

---

## Epic E2 — Unmissable Full-Screen Notification

Goal: The app ensures the user cannot overlook a meeting reminder.

### Story E2-S1 — Full-Screen Overlay Alert

As a meeting attendee, I want a full-screen overlay to appear before my meeting so I can’t miss the start.

#### Requirements — E2-S1

- Overlay covers the entire screen on all active displays (configurable primary-only).
- Shows meeting title, start time, organizer, and countdown timer.
- If available, includes meeting link and a “Join” button.
- Dims background and blocks interaction until dismissed or meeting started.
- Appears even if macOS is in Do Not Disturb (subject to user override setting in E6-S3).
- Appears X minutes before meeting (configurable; default 1 minute).

#### Acceptance Criteria — E2-S1

- GIVEN an upcoming meeting at T, WHEN now = T − X (default X = 1), THEN a blocking overlay appears on the configured displays within 500 ms with title, start time (local), organizer, and countdown.
- GIVEN multiple displays and “All displays” is on, WHEN the alert triggers, THEN identical overlays show on each active display.
- GIVEN DND is on and “Override Focus” is enabled, WHEN the alert triggers, THEN overlays appear regardless of Focus mode (see E6-S3 for permission/behavior).
- GIVEN no meeting link exists, WHEN the overlay shows, THEN the “Join” button is hidden/disabled and other info still displays.

#### Test Cases — E2-S1

- Overlay meets contrast and font-size settings; countdown ticks per second without stutter.
- Primary-only vs all-displays toggle respected on trigger and after hot-plugging a display.
- Overlay appears from cold wake within 1 s of session unlock if trigger window occurred while locked (see E5-S1).

### Story E2-S2 — Impossible-to-Miss Behavior

As a forgetful user, I want the app to override usual notification limitations so I cannot ignore the reminder.

#### Requirements — E2-S2

- Overlay persists until dismissed or meeting started.
- Requires deliberate close (button click or configured shortcut).
- Optional alert sound at configurable volume (subject to system permissions; cannot bypass hardware mute).
- If Mac is locked/sleeping, alert appears immediately after unlock/wake if still relevant.

#### Acceptance Criteria — E2-S2

- GIVEN an active overlay, WHEN I press ESC or click outside, THEN nothing happens; only “Dismiss” button or shortcut closes it.
- GIVEN alert sound is enabled at volume V, WHEN overlay appears, THEN a system alert plays at V and respects hardware mute (cannot physically bypass) but may play over DND if override is enabled.
- GIVEN the Mac is sleeping at T − X, WHEN it wakes before T, THEN the overlay appears within 1 s of unlock.

#### Test Cases — E2-S2

- Shortcut-only dismissal verified; clicks outside overlay do not close.
- Sound plays exactly once on appearance; optional repeat every N seconds if enabled in preferences (see E4-S3 Snooze & repeat).

---

## Epic E3 — Quick Meeting Join

Goal: Reduce friction to enter a meeting once reminded.

### Story E3-S1 — One-Click Join

As a meeting attendee, I want to join my online meeting directly from the overlay so I can save time.

#### Requirements — E3-S1

- “Join” opens link in default handler (browser/native app) based on URL scheme.
- If multiple links detected, overlay shows a quick selector (primary default highlighted) or opens the preferred provider based on user setting.
- Supports Google Meet, Zoom, Teams, Webex, and generic URLs.

#### Acceptance Criteria — E3-S1

- GIVEN a detected URL, WHEN I click “Join,” THEN the system opens the associated handler within 1 s and overlays dismiss.
- GIVEN multiple URLs, WHEN I click the dropdown/selector, THEN I can choose one and it opens; the app remembers my provider preference if “Remember” is checked.
- GIVEN a malformed URL, WHEN I click “Join,” THEN I see a clear error toast and the overlay remains so I can pick another link.

#### Test Cases — E3-S1

- Protocol handlers tested: meet, zoommtg, teams, webex, https.
- Preference “Default to X provider” respected for future meetings.

---

## Epic E4 — Configurability & Preferences

Goal: Let the user control when and how they are reminded.

### Story E4-S1 — Reminder Timing

As a user with variable schedules, I want to configure pre-alert timing so I can prepare in advance.

#### Requirements — E4-S1

- Global default alert time (minutes before meeting).
- Optional different alert time by meeting length (e.g., <30 min: 1 min; 30–60: 2 min; >60: 5 min).
- Disable alerts for certain calendars and all-day events.

#### Acceptance Criteria — E4-S1

- GIVEN preferences set to X minutes, WHEN a meeting is scheduled, THEN the overlay triggers at T − X.
- GIVEN length-based rules, WHEN a 45-min meeting exists, THEN the rule for 30–60 applies.
- GIVEN a personal calendar is excluded, WHEN events from it occur, THEN no overlay appears.

#### Test Cases — E4-S1

- Overlapping rules resolve by specificity: per-calendar exclusion > length-based > global default.

### Story E4-S2 — Appearance Customization

As a visually sensitive user, I want to customize alert appearance to match my preferences and accessibility needs.

#### Requirements — E4-S2

- Light/Dark theme toggle (with “Follow system” option).
- Adjustable overlay opacity (20–90%).
- Adjustable font size (Small/Medium/Large or percentage 80–140%).
- Toggle extra details beyond title & time (organizer, location, description snippet).

#### Acceptance Criteria — E4-S2

- GIVEN I change theme/opacity/font in Preferences, WHEN the next overlay appears, THEN it reflects the choices.
- GIVEN “Minimal details” is enabled, WHEN overlay shows, THEN only title and time are visible.

#### Test Cases — E4-S2

- VoiceOver reads elements in correct order under both themes; focusable controls reachable via keyboard.

### Story E4-S3 — Snooze & Repeat Alerts

As a user who sometimes isn’t ready, I want to snooze an alert so I’m reminded again before it starts.

#### Requirements — E4-S3

- “Snooze” presets: 1, 5, 10 minutes.
- Snoozed alert reappears as full-screen overlay at chosen time (if before meeting start).
- Snooze settings persist for that meeting only.

#### Acceptance Criteria — E4-S3

- GIVEN an active overlay, WHEN I click “Snooze 5,” THEN the overlay closes and reappears in 5 minutes (unless within 10 seconds of start, where it reappears immediately at start).
- GIVEN I snooze multiple times, WHEN the meeting starts, THEN snoozes stop and overlay at start takes precedence (or auto-join if enabled in E6-S1).

#### Test Cases — E4-S3

- Snooze timer survives app restart and brief offline periods (uses local schedule).

---

## Epic E5 — Reliability & Edge Cases

Goal: Ensure reminders work even in unusual situations.

### Story E5-S1 — Offline Handling

As a user with unstable internet, I want alerts for already-fetched meetings so I’m reminded even if offline.

#### Requirements — E5-S1

- Cache next 24 h of events locally with essential fields.
- If offline, alerts trigger based on cached data.
- Resume syncing when online with backoff and status indicator.

#### Acceptance Criteria — E5-S1

- GIVEN previously cached meetings, WHEN the network is offline, THEN scheduled overlays still trigger at the correct times.
- GIVEN connectivity returns, WHEN the next poll runs, THEN the cache updates and missed overlays (if still relevant) are shown immediately.

#### Test Cases — E5-S1

- Airplane mode simulation shows no crashes; status changes to “Offline” within 5 s.

### Story E5-S2 — Multi-Display Support

As a multi-monitor user, I want the overlay on all displays so I can’t miss it.

#### Requirements — E5-S2

- Overlays on all active displays simultaneously.
- Preference to show on primary display only.
- Dynamic handling of displays hot-plugged while overlay is active.

#### Acceptance Criteria — E5-S2

- GIVEN two displays and “All displays” on, WHEN the alert triggers, THEN both displays show identical overlays.
- GIVEN a new display is connected mid-overlay, WHEN detected, THEN the overlay appears on it within 1 s.

#### Test Cases — E5-S2

- Mission Control/Spaces do not hide or sandbox the overlay; it floats above.

---

## Epic E6 — Additional Convenience Features

Goal: Make the app more than just a reminder — a meeting assistant.

### Story E6-S1 — Auto-Join at Start

As a user in back-to-back meetings, I want the app to auto-join at start time to save clicks.

#### Requirements — E6-S1

- Global toggle and per-meeting override on overlay.
- Auto-join opens default handler at exact start time; cancels if meeting dismissed.

#### Acceptance Criteria — E6-S1

- GIVEN auto-join is enabled, WHEN now = T, THEN the meeting link opens and overlay dismisses.
- GIVEN I dismissed the overlay, WHEN T occurs, THEN auto-join does not execute.

#### Test Cases — E6-S1

- Per-meeting override from overlay updates only that meeting.

### Story E6-S2 — Keyboard Shortcuts (Global)

As a power user, I want global shortcuts for Dismiss/Join so I can act quickly.

#### Requirements — E6-S2

- Configurable global shortcuts for “Dismiss” and “Join.”
- Shortcuts work even when another app is focused (requires Accessibility permissions).

#### Acceptance Criteria — E6-S2

- GIVEN an overlay is visible, WHEN I press the Join shortcut, THEN the selected link opens and the overlay dismisses.
- GIVEN no overlay is visible, WHEN I press these shortcuts, THEN nothing happens.

#### Test Cases — E6-S2

- Conflicting shortcuts show a warning and cannot be saved.

### Story E6-S3 — Integration with macOS Focus Modes (DND)

As a user who uses Focus modes, I want the app to respect or override them per settings so I get notified for important meetings.

#### Requirements — E6-S3

- Setting to “Respect Focus” or “Override for meeting alerts.”
- If override is enabled, app ensures overlay appears regardless of DND; sounds may still be limited by system.

#### Acceptance Criteria — E6-S3

- GIVEN DND is enabled and “Respect Focus,” WHEN a meeting triggers, THEN overlay is delayed until Focus ends or appears silently based on preference.
- GIVEN DND is enabled and “Override,” WHEN a meeting triggers, THEN overlay appears immediately; sound follows system capability.

#### Test Cases — E6-S3

- Switching the toggle takes effect for the next alert without restart.

---

## Cross-Cutting: Onboarding, Permissions, and Error Handling

### Onboarding

- First-run flow: welcome, OAuth connect, calendar selection, permissions prompts (Notifications, Accessibility for shortcuts, optionally Screen Recording only if required by implementation), preferences quick setup.

### Permissions

- Accessibility: for global shortcuts; show rationale and deep link to System Settings.
- Notifications: to allow sound/badges if used; overlay itself does not require system notifications.
- Keychain access: to securely store tokens.

### Error Handling & Observability

- Human-readable, non-blocking banners for sync/auth errors with retry actions.
- Local, anonymized logs (PII redacted) for troubleshooting; no data leaves device.
- Health indicators in menu bar: syncing, offline, needs attention.

### Metrics & Success Criteria

- 95%+ of meetings with online links show an overlay ≥ configured minutes before start.
- ≤ 1 false positive overlay per user-week on average.
- Join action launches within ≤ 1 s from click/shortcut on modern hardware.

### Out of Scope (v1)

- Non-Google calendars; team sharing; cloud analytics; cross-device sync.

---

## Glossary

- Overlay: Full-screen, focus-stealing window rendered above apps to prevent missing a meeting.
- Provider: Meeting platform (Meet, Zoom, Teams, Webex, generic URL).
- DND/Focus: macOS mode reducing interruptions.

