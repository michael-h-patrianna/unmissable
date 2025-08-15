# Beast Knowledge - Unmissable macOS App Implementation

## Technical Assumptions

## Completed Implementation

### Milestone 1: Project Scaffold ✓
- Swift Package Manager project structure with modern Swift 6.1.2
- All required dependencies: AppAuth, GRDB, KeychainAccess, Magnet 3.4.0, SnapshotTesting
- SwiftLint + SwiftFormat configuration
- GitHub Actions CI pipeline with build, test, and coverage
- Complete test suite structure (unit, integration, snapshot tests)
- 25 tests passing with comprehensive coverage

### Milestone 2: OAuth + Calendar Integration ✓
- OAuth2Service with secure AppAuth integration
- GoogleCalendarAPIService for fetching calendars and events
- Keychain-based token storage with automatic refresh
- Calendar selection UI with primary/secondary indicators
- Real-time connection status and error handling
- Proper separation of concerns with reactive bindings
- Configuration validation and setup guide (OAUTH_SETUP.md)

### Milestone 3: Event Sync + Local Cache ✓
- Complete Event data model with timezone handling
- GRDB-powered local database with automatic migrations
- Polling-based sync system with configurable intervals
- Meeting link extraction and parsing from multiple fields
- Provider detection for Google Meet, Zoom, Teams, Webex
- Cache invalidation and event state management

### Milestone 4: Google Meet Quick Join ✓
- **Decision**: Simplified to focus only on Google Meet (user's actual use case)
- Simple regex-based detection of `meet.google.com` URLs
- One-click join functionality directly opening browser
- Removed complex provider abstraction in favor of focused implementation
- Clean UI integration in menu bar and event views

### Milestone 5: Full-Screen Blocking Overlay Engine ✓
- **AppKit NSWindow-based overlay system** with `.screenSaver` window level
- **Multi-display support**: Shows on all connected screens simultaneously
- **Real-time countdown timer** with visual urgency (red when <60 seconds)
- **Smart scheduling system** integrated with EventScheduler and PreferencesManager
- **Snooze functionality** with automatic re-scheduling (1, 5, 10, 15 minute options)
- **SwiftUI content** hosted in NSHostingView for rich UI within blocking window
- **Comprehensive snapshot tests** for all overlay states (before meeting, started, urgent, no-link)
- **Proper lifecycle management** with countdown timers and auto-hide after meetings

## Architecture Decisions

### OAuth Flow Design
- **Decision**: Use AppAuth-iOS library for OAuth 2.0 implementation
- **Rationale**: Industry standard, well-maintained, handles token refresh automatically
- **Implementation**: Temporary window for auth flow, secure keychain storage, proper error handling

### Data Binding Strategy
- **Decision**: ObservableObject + @Published properties with Combine bindings
- **Rationale**: Native SwiftUI pattern, reactive updates, clean separation
- **Implementation**: AppState centralizes UI state, services publish changes

### Security Approach
- **Decision**: Keychain storage for OAuth tokens, client ID configuration validation
- **Rationale**: macOS Keychain is secure system store, prevents credential exposure
- **Implementation**: KeychainAccess wrapper, runtime configuration validation

## Technical Context

### Swift 6 Compatibility
- Using modern async/await patterns throughout
- Proper @MainActor annotations for UI updates
- Explicit capture semantics for closures (self.property syntax)
- Type-safe continuation handling in async flows

### Google Calendar API Integration
- RESTful API with Bearer token authentication
- JSON parsing with proper error handling
- Timezone-aware date parsing (ISO8601 + custom formats)
- Meeting link extraction from multiple fields (location, description, conferenceData)

### Testing Strategy
- Unit tests for models and business logic
- Integration tests for service interactions (mocked for OAuth)
- Snapshot tests (placeholder for UI components)
- Build verification in CI pipeline

### Implementation Constraints
- macOS 14+ target as specified in PRD
- Swift 5.10+ with SwiftUI and AppKit integration
- Must handle multi-display scenarios with identical overlays
- Global shortcuts require Accessibility permissions
- Keychain storage for OAuth tokens (secure by default)

### Google Calendar API Integration
- **Confidence: High** - Using Google Calendar API v3 with OAuth 2.0
- **Scope needed**: `https://www.googleapis.com/auth/calendar.readonly`
- **Refresh token required** for offline access and automatic token refresh
- **Rate limits**: Standard Google API limits apply (1000 requests/100 seconds/user)

### Meeting Link Detection Patterns
- **Google Meet**: `meet.google.com/`, `g.co/meet/`
- **Zoom**: `zoom.us/j/`, `zoom.us/meeting/`, `zoommtg://`
- **Microsoft Teams**: `teams.microsoft.com/`, `teams.live.com/`
- **Webex**: `webex.com/meet/`, `webex.com/join/`
- **Generic**: Any HTTPS URL in location or description fields

### Overlay Window Implementation
- **NSWindow** with `NSWindowLevel.screenSaver` or higher
- **NSWindow.CollectionBehavior**: `.canJoinAllSpaces`, `.fullScreenAuxiliary`
- **Frame**: Cover entire screen bounds for each display
- **Interaction**: Modal behavior - blocks all other app interaction

## Context Notes

### Development Environment
- Primary development in VS Code with Swift extension
- Xcode required for project creation and signing
- GitHub Actions for CI using macOS 14 runner
- SwiftLint and SwiftFormat for code quality

### Privacy & Security
- All calendar data cached locally in SQLite
- OAuth tokens stored in macOS Keychain
- No telemetry or external analytics
- HTTPS-only network communication
- Code signing and notarization for distribution

### Performance Targets
- ≤ 2% average CPU usage when idle
- ≤ 150 MB RAM usage
- Overlay render time < 500ms
- Background sync every 60 seconds (configurable 15-300s)

## Decision Log

### Technical Decisions Made
1. **Full-screen overlay strategy**: Using NSWindow with highest window level rather than system notifications for "unmissable" behavior
2. **Calendar sync approach**: Polling-based rather than push notifications for simplicity and reliability
3. **Local storage**: GRDB.swift for structured data with automatic migrations
4. **Testing strategy**: Combination of unit tests, snapshot tests for UI, and integration tests with mocked API calls

### User Experience Decisions
1. **Default alert timing**: 1 minute before meeting start
2. **Multi-display behavior**: Show on all displays by default with option for primary-only
3. **Dismissal**: Requires explicit action (button click or keyboard shortcut)
4. **Provider detection**: Automatic with manual override options

## External Resources

### Documentation Sources
- [Google Calendar API v3](https://developers.google.com/calendar/api/v3/reference)
- [AppAuth for iOS/macOS](https://github.com/openid/AppAuth-iOS)
- [GRDB.swift Documentation](https://github.com/groue/GRDB.swift)
- [SwiftUI and AppKit Integration](https://developer.apple.com/documentation/swiftui/appkit-integration)

### Code Examples & Patterns
- Full-screen overlay window patterns from accessibility apps
- OAuth 2.0 implementation examples with AppAuth
- Calendar API integration patterns
- Global keyboard shortcut handling with Magnet framework
