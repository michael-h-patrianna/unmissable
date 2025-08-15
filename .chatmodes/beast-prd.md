# Beast PRD - Unmissable macOS App Implementation

## Problem Statement

**Job-to-be-Done**: As a macOS user with a busy meeting schedule, I need an absolutely unmissable reminder system that prevents me from missing important online meetings by showing a full-screen alert that I cannot ignore, so that I maintain professional reliability and never lose opportunities due to forgotten meetings.

**Primary Users**:
- Knowledge workers with 3+ daily meetings
- Remote workers juggling multiple video conferences
- Professionals who frequently miss calendar notifications
- Users who work in distraction-heavy environments

**Pain Points Addressed**:
- System notifications are easily missed or dismissed
- Calendar alerts get buried under other windows
- Meeting links are hard to find when rushing
- No foolproof way to ensure meeting attendance

## Goals & Success Metrics

### Primary Goals
1. **Zero missed meetings**: 95%+ of meetings with online links show overlay ≥ configured minutes before start
2. **Instant access**: Join action launches within ≤1s from click/shortcut
3. **Unmissable alerts**: Full-screen blocking overlay that requires deliberate dismissal
4. **Seamless integration**: Connect with Google Calendar with minimal setup friction

### Success Metrics
- Meeting attendance rate improvement (user-reported)
- ≤1 false positive overlay per user-week
- <500ms overlay render time after trigger
- 95%+ successful OAuth connections on first attempt
- ≤2% average CPU usage when idle

### User Satisfaction Targets
- Setup completed in <2 minutes from first launch
- Zero crashes during normal operation
- Overlay appears within 1s of wake/unlock if relevant
- All accessibility guidelines (WCAG AA) met

## Scope Definition

### In Scope (v1.0)
- Google Calendar integration with OAuth 2.0
- Full-screen overlay alerts with countdown timer
- Meeting link detection and one-click join
- Multi-display support
- Configurable alert timing and appearance
- Snooze functionality
- Global keyboard shortcuts
- Offline alert caching (24h)
- Focus/DND override options
- Basic preferences and settings

### Out of Scope (v1.0)
- Other calendar providers (Outlook, Apple Calendar)
- Team/organization features
- Cloud sync across devices
- Advanced analytics or reporting
- Meeting transcription or recording
- Calendar editing capabilities
- Mobile app companion

### Future Considerations
- Exchange/Outlook integration
- Slack/Teams status integration
- Meeting preparation reminders
- Smart scheduling suggestions

## Functional Requirements

### Core Features

#### F1: Calendar Connection
- OAuth 2.0 authentication with Google Calendar
- Multiple calendar selection and management
- Automatic token refresh with error recovery
- Secure credential storage in macOS Keychain

#### F2: Meeting Detection & Parsing
- Real-time event synchronization (configurable 15-300s intervals)
- Meeting link extraction from location/description fields
- Provider detection (Meet, Zoom, Teams, Webex, generic URLs)
- All-day event filtering options
- Timezone-aware scheduling

#### F3: Full-Screen Overlay System
- Blocking overlay on all active displays (configurable)
- Meeting details: title, time, organizer, countdown
- One-click join with provider-specific handling
- Dismissal via button click or keyboard shortcut only
- Persistence until explicit dismissal or meeting start

#### F4: Customization & Preferences
- Alert timing configuration (global + per-meeting-length rules)
- Visual customization (themes, opacity, font size, minimal mode)
- Calendar exclusion settings
- Sound alerts with volume control
- Multi-display preferences

#### F5: Advanced Features
- Snooze functionality (1, 5, 10 minutes)
- Auto-join at meeting start time
- Global keyboard shortcuts
- Focus/DND mode integration
- Offline alert caching

## Non-Functional Requirements

### Performance
- **Startup time**: <3s from launch to ready state
- **Memory usage**: ≤150MB during normal operation
- **CPU usage**: ≤2% average when idle, ≤10% during sync
- **Network efficiency**: Minimal API calls with smart caching
- **Overlay responsiveness**: <500ms from trigger to display

### Reliability
- **Uptime**: 99.9% availability during business hours
- **Error recovery**: Automatic retry with exponential backoff
- **Offline resilience**: 24h cached alert capability
- **Wake/sleep handling**: Resume operation within 1s of system wake
- **Multi-display stability**: Handle display changes without crashes

### Security & Privacy
- **Data encryption**: All tokens stored in macOS Keychain
- **Network security**: HTTPS-only API communication
- **Data minimization**: Only essential calendar data cached locally
- **No telemetry**: Zero data transmission to third parties
- **Code signing**: Notarized app bundle for secure distribution

### Accessibility
- **WCAG AA compliance**: High contrast themes and scalable fonts
- **VoiceOver support**: Full screen reader compatibility
- **Keyboard navigation**: Complete keyboard-only operation
- **Reduced motion**: Respect system accessibility preferences
- **Font scaling**: Support for system font size preferences

### Localization
- **Primary language**: English (US)
- **Architecture**: Prepared for future localization
- **Date/time formatting**: Respect system locale settings
- **RTL support**: Future consideration for RTL languages

## Acceptance Criteria (Testable)

### Epic E1: Meeting Detection and Integration

**E1-S1: Calendar Connection**
- GIVEN app launches first time, WHEN user selects "Connect Google Calendar", THEN OAuth flow completes and user email displays within 30s
- GIVEN user has multiple calendars, WHEN accessing Preferences → Calendars, THEN all calendars show with toggle controls and selections persist after restart
- GIVEN token expires, WHEN sync occurs, THEN refresh happens automatically without user prompt (unless refresh fails)
- GIVEN Google access revoked, WHEN next sync runs, THEN error banner shows with "Reconnect" button

**E1-S2: Meeting Detection**
- GIVEN sync enabled, WHEN 60s elapsed (default), THEN next 24h events refresh and cache locally
- GIVEN event has Meet/Zoom/Teams/Webex link, WHEN parsed, THEN provider and URL stored correctly
- GIVEN all-day event and "Include all-day" disabled, WHEN syncing, THEN event excluded from alerts
- GIVEN timezone change, WHEN subsequent sync runs, THEN event times update within next refresh cycle

### Epic E2: Unmissable Full-Screen Notification

**E2-S1: Full-Screen Overlay Alert**
- GIVEN meeting at time T, WHEN now = T - X minutes (default X=1), THEN blocking overlay appears on configured displays within 500ms showing title, time, organizer, countdown
- GIVEN multiple displays and "All displays" on, WHEN alert triggers, THEN identical overlays appear on each active display
- GIVEN DND active and "Override Focus" enabled, WHEN alert triggers, THEN overlay appears regardless of Focus mode
- GIVEN no meeting link exists, WHEN overlay shows, THEN "Join" button hidden and other info displays correctly

**E2-S2: Impossible-to-Miss Behavior**
- GIVEN active overlay, WHEN ESC pressed or clicking outside, THEN overlay persists (only "Dismiss" button or shortcut closes)
- GIVEN alert sound enabled at volume V, WHEN overlay appears, THEN sound plays at volume V respecting hardware mute
- GIVEN Mac sleeping at T-X, WHEN wakes before T, THEN overlay appears within 1s of unlock

### Epic E3: Quick Meeting Join

**E3-S1: One-Click Join**
- GIVEN detected URL, WHEN "Join" clicked, THEN system opens handler within 1s and overlay dismisses
- GIVEN multiple URLs, WHEN dropdown selected, THEN chosen link opens and preference remembered if "Remember" checked
- GIVEN malformed URL, WHEN "Join" clicked, THEN error toast shows and overlay remains for retry

### Epic E4: Configurability & Preferences

**E4-S1: Reminder Timing**
- GIVEN preferences set to X minutes, WHEN meeting scheduled, THEN overlay triggers at T-X
- GIVEN length-based rules, WHEN 45-min meeting exists, THEN 30-60min rule applies
- GIVEN calendar excluded, WHEN events from it occur, THEN no overlay appears

**E4-S2: Appearance Customization**
- GIVEN theme/opacity/font changed in Preferences, WHEN next overlay appears, THEN changes reflected
- GIVEN "Minimal details" enabled, WHEN overlay shows, THEN only title and time visible

**E4-S3: Snooze & Repeat**
- GIVEN active overlay, WHEN "Snooze 5" clicked, THEN overlay closes and reappears in 5min (unless <10s to start)
- GIVEN multiple snoozes, WHEN meeting starts, THEN snoozes stop and start overlay takes precedence

### Epic E5: Reliability & Edge Cases

**E5-S1: Offline Handling**
- GIVEN cached meetings, WHEN network offline, THEN scheduled overlays trigger at correct times
- GIVEN connectivity returns, WHEN next poll runs, THEN cache updates and missed relevant overlays show immediately

**E5-S2: Multi-Display Support**
- GIVEN two displays and "All displays" on, WHEN alert triggers, THEN both displays show identical overlays
- GIVEN new display connected mid-overlay, WHEN detected, THEN overlay appears on it within 1s

### Epic E6: Additional Features

**E6-S1: Auto-Join at Start**
- GIVEN auto-join enabled, WHEN now = T, THEN meeting link opens and overlay dismisses
- GIVEN overlay dismissed, WHEN T occurs, THEN auto-join does not execute

**E6-S2: Global Shortcuts**
- GIVEN overlay visible, WHEN Join shortcut pressed, THEN selected link opens and overlay dismisses
- GIVEN no overlay visible, WHEN shortcuts pressed, THEN nothing happens

**E6-S3: Focus Mode Integration**
- GIVEN DND enabled and "Respect Focus", WHEN meeting triggers, THEN overlay delayed until Focus ends or appears silently per preference
- GIVEN DND enabled and "Override", WHEN meeting triggers, THEN overlay appears immediately with sound per system capability

## Quality Gates

### Definition of Done
- All acceptance criteria pass automated tests
- Code coverage ≥80% for Core/Features modules
- All snapshot tests pass on CI
- SwiftLint violations = 0
- Manual testing on multiple display configurations
- Accessibility audit complete with no major issues
- Performance benchmarks meet targets

### Release Criteria
- Zero crashes in 48h continuous testing
- OAuth flow 95%+ success rate in testing
- Overlay timing accuracy within ±5s under normal load
- Memory leaks = 0 after 24h operation
- All security requirements verified
- Code signing and notarization complete
