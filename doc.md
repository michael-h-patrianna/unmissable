# Unmissable - LLM Coding Agent Documentation

## PROJECT OVERVIEW

**Project Type**: macOS SwiftUI application
**Purpose**: Calendar meeting reminder system with full-screen overlays to prevent missing meetings
**Architecture**: Menu bar application with Google Calendar integration
**Build System**: Swift Package Manager
**Target**: macOS 14+ (Sonoma)
**Development**: VS Code with Swift extension support

## CORE CONCEPT

Unmissable is a macOS menu bar application that:
1. Connects to Google Calendar via OAuth2
2. Syncs events to local SQLite database
3. Schedules alerts before meetings
4. Shows unmissable full-screen overlays with countdown timers
5. Provides one-click meeting join functionality
6. Allows snoozing reminders
7. Respects user preferences for timing, appearance, and behavior
8. **Displays next meeting preview directly in menu bar with configurable modes**

## DIRECTORY STRUCTURE

```
Sources/Unmissable/
├── App/                    # Application entry point and main UI
│   ├── UnmissableApp.swift           # SwiftUI @main entry point, MenuBarExtra
│   ├── AppDelegate.swift             # NSApplicationDelegate for URL schemes, permissions
│   ├── AppState.swift                # Central state management, service coordination
│   └── MenuBarView.swift             # Menu bar dropdown UI
├── Core/                   # Core business logic and utilities
│   ├── DatabaseManager.swift        # SQLite database operations via GRDB
│   ├── DatabaseModels.swift         # GRDB model extensions for Event/CalendarInfo
│   ├── EventScheduler.swift         # Alert scheduling and timing logic
│   ├── HealthMonitor.swift          # System health monitoring and diagnostics
│   ├── LinkParser.swift             # Meeting URL detection and provider identification
│   ├── MenuBarPreviewManager.swift  # Menu bar preview and timer logic
│   ├── QuickJoinManager.swift       # Meeting joining coordination
│   ├── SoundManager.swift           # Alert sound playback
│   ├── SyncManager.swift            # Periodic calendar sync orchestration
│   ├── TimezoneManager.swift        # Timezone handling and conversion
│   ├── CustomThemeManager.swift     # Custom theming system and appearance management
│   ├── CustomComponents.swift       # 100% custom UI components (buttons, cards, etc.)
│   ├── ProductionMonitor.swift      # Production readiness monitoring
│   └── Protocols.swift              # Core protocols and interfaces
├── Features/               # Feature-specific modules
│   ├── CalendarConnect/              # Google Calendar integration
│   │   ├── CalendarService.swift    # Main calendar service interface
│   │   ├── GoogleCalendarAPIService.swift # Google Calendar API client
│   │   └── OAuth2Service.swift      # OAuth2 authentication flow
│   ├── EventSync/                   # (Empty - sync logic in Core/SyncManager)
│   ├── FocusMode/                   # macOS Focus mode integration
│   │   └── FocusModeManager.swift   # Focus/DND awareness and override
│   ├── Join/                        # (Empty - join logic in Core/QuickJoinManager)
│   ├── Overlay/                     # Full-screen alert overlay system
│   │   ├── OverlayContentView.swift # SwiftUI overlay UI components
│   │   └── OverlayManager.swift     # Overlay window management and scheduling
│   ├── Preferences/                 # Settings and configuration
│   │   ├── PreferencesManager.swift # UserDefaults-backed preferences
│   │   ├── PreferencesView.swift    # SwiftUI preferences UI
│   │   └── PreferencesWindowManager.swift # Preferences window lifecycle
│   ├── QuickJoin/                   # Quick meeting access
│   │   └── QuickJoinView.swift      # Quick join UI components
│   ├── Shortcuts/                   # Global keyboard shortcuts
│   │   └── ShortcutsManager.swift   # Magnet-based global shortcuts
│   └── Snooze/                      # (Empty - snooze logic in Core/EventScheduler)
├── Models/                 # Data models
│   ├── CalendarInfo.swift           # Calendar metadata model
│   ├── Event.swift                  # Meeting event data model
│   ├── Provider.swift               # Meeting provider enum (Meet, Zoom, etc.)
│   └── ScheduledAlert.swift         # Alert scheduling data model
├── Config/                 # Configuration
│   └── GoogleCalendarConfig.swift   # OAuth client configuration
└── Resources/              # App resources (sounds, assets)
```

## DEPENDENCIES (Package.swift)

- **AppAuth** (1.7.5+): OAuth2/OIDC authentication for Google Calendar
- **GRDB.swift** (6.29.2+): SQLite database ORM for local caching
- **KeychainAccess** (4.2.2+): Secure token storage in macOS Keychain
- **Magnet** (3.4.0+): Global keyboard shortcuts registration
- **SwiftLint** (0.57.1+): Code linting (dev dependency)
- **SwiftFormat** (0.55.3+): Code formatting (dev dependency)
- **SnapshotTesting** (1.17.7+): UI testing via snapshot comparison

## THEMING SYSTEM

### Overview
Unmissable uses a **100% custom theming system** that completely replaces SwiftUI's system-dependent styling. This provides consistent, modern, flat design across light and dark themes without relying on macOS system appearance APIs.

### Architecture

#### CustomThemeManager (@MainActor)
Central theme coordinator that:
- Manages current theme state (Light, Dark, System)
- Observes macOS system appearance changes
- Provides reactive theme updates via @Published properties
- Calculates effective theme based on user preference and system state

```swift
@MainActor
class CustomThemeManager: ObservableObject {
    static let shared = CustomThemeManager()
    func setTheme(_ theme: AppTheme)  // Updates theme and triggers UI refresh
}

#### Custom Color System
Dramatic color differences between themes for maximum visual impact:

**Light Theme:**
- Backgrounds: Pure white (`Color.white`) to very light grays
- Text: Dark charcoal (`Color(red: 0.11, green: 0.11, blue: 0.13)`) for high contrast
- Accent: Vibrant cyan (`Color(red: 0.0, green: 0.7, blue: 1.0)`) for modern feel
- Borders: Subtle light grays for minimal visual noise

**Dark Theme:**
- Backgrounds: Very dark (`Color(red: 0.05, green: 0.05, blue: 0.07)`) to rich dark grays
- Text: Near-white (`Color(red: 0.98, green: 0.98, blue: 1.0)`) for maximum readability
- Accent: Electric cyan (`Color(red: 0.0, green: 0.9, blue: 1.0)`) for vibrant contrast
- Borders: Subtle dark grays that don't interfere

#### Custom Components (CustomComponents.swift)
Complete replacement for system UI components:

**CustomButton**: Three distinct styles without ButtonStyle dependencies
- `.primary`: Filled accent color with white text
- `.secondary`: Border-only with accent color text
- `.minimal`: Text-only with hover/press effects

**CustomCard**: Flat, minimal container component
- `.flat`: Minimal background with subtle borders
- `.standard`: Standard elevation with background
- `.elevated`: Enhanced shadow and background separation

**CustomPicker**: Completely custom dropdown picker
- No system Picker dependencies
- Custom styling matching theme colors
- Consistent appearance across themes

**CustomToggle**: Custom switch component
- Flat design aesthetic
- Theme-aware colors
- Smooth animations

**CustomSlider**: Custom range control
- Theme-integrated accent colors
- Minimal visual design
- Precise value control

### Environment Integration

#### Custom Environment
Theme system integrates via SwiftUI environment:

```swift
struct CustomDesign {
    let colors: CustomColors
    let fonts: CustomFonts
    let spacing: CustomSpacing
    let corners: CustomCorners
    let shadows: CustomShadows
}

// Environment key and modifier
@Environment(\.customDesign) private var design

extension View {
    func customThemedEnvironment() -> some View {
        environment(\.customDesign, CustomThemeManager.shared.currentDesign)
    }
}
```

All views use `design.colors.textPrimary` instead of system colors, ensuring complete custom control.

#### Preference Integration
Theme selection integrated in Appearance preferences:
- Dropdown picker for Light/Dark/System selection
- Real-time preview of theme changes
- Persistent storage via PreferencesManager
- Automatic CustomThemeManager synchronization

### Implementation Details

#### No System Dependencies
- **Zero** `Color.primary`, `Color.secondary`, or system semantic colors
- **Zero** `ButtonStyle`, `ToggleStyle`, or system component styles
- **Zero** `.foregroundStyle(.primary)` or system styling APIs
- **Complete** custom implementation of all UI components

#### MenuBarExtra Limitations
**Important**: MenuBarExtra popup container cannot be customized due to macOS restrictions:
- The popup window itself uses system styling (unavoidable)
- All **content inside** the popup uses our custom theming
- This is a fundamental macOS limitation, not a implementation issue

#### Real-time Theme Switching
Theme changes propagate immediately through:
1. User selects theme in preferences
2. PreferencesManager updates `appearanceTheme` property
3. Property change triggers CustomThemeManager.setTheme()
4. CustomThemeManager publishes effectiveTheme change
5. All views observe @Environment(\.customDesign) and re-render
6. Complete UI refresh with new colors/styling

### Usage Patterns

#### In Views
```swift
struct MyView: View {
    @Environment(\.customDesign) private var design

    var body: some View {
        VStack {
            Text("Hello")
                .foregroundColor(design.colors.textPrimary)  // Not .primary
                .font(design.fonts.headline)

            CustomButton("Action", style: .primary) {
                // Custom button, not Button
            }
        }
        .background(design.colors.background)  // Not Color(.systemBackground)
    }
}
```

#### Theme-aware Components
```swift
// Always use custom design environment
@Environment(\.customDesign) private var design

// Never use system colors
.foregroundColor(design.colors.textPrimary)     // ✅ Correct
.foregroundColor(.primary)                      // ❌ System dependent

// Always use custom components
CustomButton("Title", style: .primary)         // ✅ Themed
Button("Title") { }                            // ❌ System styled
```

### Testing Theme System
Debug controls in Appearance preferences allow testing:
- "Force Light" button → immediate light theme
- "Force Dark" button → immediate dark theme
- "System" button → follow macOS system setting
- Color swatches show current theme colors
- Real-time preview of theme differences

### Performance
- Minimal overhead: theme changes only trigger UI re-renders
- Efficient color calculation: pre-computed theme objects
- No system appearance polling: reactive updates only
- Memory efficient: shared CustomThemeManager singleton

## DATA MODELS

### Event
```swift
struct Event: Identifiable, Codable, Equatable {
    let id: String                    // Google Calendar event ID
    let title: String                 // Meeting title
    let startDate: Date              // Meeting start time (UTC)
    let endDate: Date                // Meeting end time (UTC)
    let organizer: String?           // Meeting organizer email
    let isAllDay: Bool               // All-day event flag
    let calendarId: String           // Source calendar ID
    let timezone: String             // Original timezone identifier
    let links: [URL]                 // Extracted meeting URLs
    let provider: Provider?          // Detected meeting provider
    let snoozeUntil: Date?          // Snooze timestamp (if snoozed)
    let autoJoinEnabled: Bool        // Per-event auto-join setting
    let createdAt: Date             // Local creation timestamp
    let updatedAt: Date             // Local update timestamp
}
```

### Provider
```swift
enum Provider: String, Codable, CaseIterable {
    case meet = "meet"              // Google Meet
    case zoom = "zoom"              // Zoom
    case teams = "teams"            // Microsoft Teams
    case webex = "webex"            // Cisco Webex
    case generic = "generic"        // Other/unknown
}
```

### CalendarInfo
```swift
struct CalendarInfo: Identifiable, Codable {
    let id: String                  // Google Calendar ID
    let name: String               // Display name
    let description: String?        // Calendar description
    let isSelected: Bool           // User selection for syncing
    let isPrimary: Bool            // Primary calendar flag
    let colorHex: String?          // Calendar color
    let lastSyncAt: Date?          // Last successful sync
    let createdAt: Date           // Local creation timestamp
    let updatedAt: Date           // Local update timestamp
}
```

### ScheduledAlert
```swift
struct ScheduledAlert: Identifiable {
    let id = UUID()
    let event: Event
    let triggerDate: Date
    let alertType: AlertType

    enum AlertType {
        case reminder(minutesBefore: Int)    // Regular alert
        case meetingStart                    // Meeting start notification
        case snooze(until: Date)            // Snoozed alert
    }
}
```

## ARCHITECTURE PATTERNS

### Dependency Injection
- Services injected via initializers (PreferencesManager passed to dependent services)
- Weak references used to prevent retain cycles (EventScheduler ↔ OverlayManager)
- Singleton pattern for shared resources (DatabaseManager.shared, TimezoneManager.shared)

### Observable Pattern
- All managers inherit from ObservableObject
- @Published properties for SwiftUI reactive updates
- Combine publishers for internal service communication
- Service-to-service communication via callbacks and Combine

### State Management
- AppState acts as central coordinator for all services
- Services maintain their own published state
- UI binds directly to service @Published properties via AppState
- Preferences changes trigger automatic service reconfiguration

### Error Handling
- Custom error enums with LocalizedError conformance
- Non-blocking error banners for sync/auth failures
- Graceful fallbacks (cached data during offline periods)
- OSLog for structured logging with privacy-safe redaction

## KEY SERVICES

### AppState (@MainActor)
Central state coordinator that:
- Initializes all services in dependency order
- Provides public interfaces to services for UI access
- Manages authentication flow and connection status
- Coordinates event rescheduling after sync updates
- Handles service lifecycle (start/stop periodic operations)

Key methods:
- `connectToCalendar()` → OAuth flow + sync startup
- `disconnectFromCalendar()` → cleanup and auth revocation
- `syncNow()` → manual sync trigger
- `showPreferences()` → preferences window display

### CalendarService (@MainActor)
Google Calendar integration manager:
- Wraps OAuth2Service for authentication
- Wraps GoogleCalendarAPIService for API calls
- Wraps SyncManager for periodic operations
- Provides timezone-adjusted events to UI
- Manages calendar selection state

Key responsibilities:
- OAuth2 token lifecycle management
- Calendar list fetching and caching
- Event syncing and local storage
- Timezone conversion for display
- Service status publishing for UI

### DatabaseManager
SQLite database operations via GRDB:
- Single-file database in ~/Library/Application Support/Unmissable/
- Schema versioning with migration support
- Atomic transactions for data consistency
- Event and calendar CRUD operations
- Query methods for upcoming events, search, date ranges

Database schema:
```sql
-- Events table
CREATE TABLE events (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    startDate REAL NOT NULL,
    endDate REAL NOT NULL,
    organizer TEXT,
    isAllDay INTEGER NOT NULL,
    calendarId TEXT NOT NULL,
    timezone TEXT NOT NULL,
    links TEXT NOT NULL,           -- JSON array of URLs
    provider TEXT,                 -- Provider enum raw value
    snoozeUntil REAL,
    autoJoinEnabled INTEGER NOT NULL,
    createdAt REAL NOT NULL,
    updatedAt REAL NOT NULL
);

-- Calendars table
CREATE TABLE calendars (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    isSelected INTEGER NOT NULL,
    isPrimary INTEGER NOT NULL,
    colorHex TEXT,
    lastSyncAt REAL,
    createdAt REAL NOT NULL,
    updatedAt REAL NOT NULL
);
```

### EventScheduler (@MainActor)
Alert and overlay scheduling engine:
- Monitors preferences for timing changes
- Schedules ScheduledAlert objects for future triggers
- Coordinates with OverlayManager for display
- Handles snooze scheduling and management
- Timer-based monitoring (5-second intervals)

Scheduling logic:
1. Calculate trigger times based on user preferences
2. Create ScheduledAlert objects for each trigger
3. Sort alerts by trigger time
4. Monitor for triggered alerts via timer
5. Delegate to OverlayManager for display
6. Support snooze rescheduling

### OverlayManager (@MainActor)
Full-screen overlay window management:
- Creates NSWindow instances above all content
- Manages multi-display support (all displays vs primary only)
- Coordinates with FocusModeManager for DND override
- Handles overlay dismissal and snooze callbacks
- Sound playback via SoundManager

Window configuration:
- NSWindow.Level.floating + high order for top-most display
- Covers all displays when showOnAllDisplays = true
- Ignores window shadows and standard behavior
- Keyboard shortcuts and click-outside handling

### SyncManager (@MainActor)
Periodic calendar synchronization:
- Timer-based sync intervals (15-300 seconds, default 60)
- Fetches events for next 24 hours + currently running
- Batch database updates for performance
- Offline handling with retry logic
- Sync status publishing for UI feedback

Sync flow:
1. Check authentication status
2. Fetch selected calendars
3. Query Google Calendar API for each calendar
4. Parse events and extract meeting links
5. Update local database
6. Trigger event rescheduling callback

### PreferencesManager (@MainActor)
UserDefaults-backed preference management:
- @Published properties for reactive UI updates
- Automatic UserDefaults persistence on property changes
- Type-safe preference keys and default values
- Preference validation and bounds checking
- Event-specific timing calculation

Key preference categories:
- Alert timing (default, length-based, per-duration rules)
- Appearance (theme, opacity, font size, minimal mode)
- Behavior (auto-join, focus override, multi-display)
- Sound (enabled, volume, alert timing)
- Sync (interval, all-day events inclusion)
- Menu bar display (icon, timer, name+timer modes)

### MenuBarPreviewManager (@MainActor)
Menu bar preview and timer management:
- Observes preference changes for display mode selection with immediate updates
- Detects next upcoming meeting from event list
- Manages real-time countdown timer with 1-second precision
- Formats time display based on context (< 1 min, XX min, HH:MM h, X d)
- Truncates meeting names to 12 characters with ellipsis
- Coordinates with CalendarService for event updates
- **Critical Fix**: Uses preference parameter directly in change handler to prevent timing issues

Timer management:
- Starts/stops timer based on display mode and meeting availability
- Updates menu bar text via @Published properties through AppState mirroring
- Automatic fallback to icon-only when no meetings exist
- Efficient resource usage (timer only runs when needed)
- **Preference Synchronization**: handlePreferenceChange() uses the new mode parameter directly instead of reading from PreferencesManager to avoid Combine timing issues where the property hasn't updated yet

## OAUTH2 FLOW

1. **Configuration**: GoogleCalendarConfig provides client ID and redirect URI
2. **Authorization Request**: AppAuth builds authorization URL with PKCE
3. **Web Authentication**: ASWebAuthenticationSession handles user consent
4. **Authorization Code**: Redirect URI captures authorization code
5. **Token Exchange**: AppAuth exchanges code for access/refresh tokens
6. **Token Storage**: KeychainAccess stores tokens securely
7. **Automatic Refresh**: AppAuth handles token refresh transparently

URL Scheme: `com.unmissable.app://oauth-callback`
Required Scopes: `https://www.googleapis.com/auth/calendar.readonly`

## GOOGLE CALENDAR API INTEGRATION

### Authentication
- OAuth2 with PKCE (AppAuth library)
- Tokens stored in macOS Keychain
- Automatic token refresh
- Scope: calendar.readonly

### API Endpoints Used
- `GET /calendar/v3/users/me/calendarList` - Fetch user calendars
- `GET /calendar/v3/calendars/{calendarId}/events` - Fetch calendar events

### Event Processing
1. Fetch events from selected calendars
2. Filter by time range (24 hours ahead)
3. Extract meeting links from description/location fields
4. Detect provider (Meet, Zoom, Teams, Webex)
5. Convert to local Event model
6. Store in SQLite database

### Link Extraction Patterns
```swift
// Google Meet
"https://meet.google.com/*"
"https://g.co/meet/*"

// Zoom
"https://zoom.us/j/*"
"https://*.zoom.us/*"

// Microsoft Teams
"https://teams.microsoft.com/*"
"https://teams.live.com/*"

// Cisco Webex
"https://*.webex.com/*"
```

## UI ARCHITECTURE

### SwiftUI Application Structure
- **UnmissableApp**: Main @main entry point with MenuBarExtra
- **MenuBarView**: Dropdown menu with connection status, upcoming events, preferences
- **OverlayContentView**: Full-screen meeting reminder overlay
- **PreferencesView**: Multi-tab settings interface

### Menu Bar Application
- MenuBarExtra with dynamic content (icon or text based on preferences)
- NSApp.setActivationPolicy(.accessory) to hide dock icon
- Window management for preferences and overlays

### Menu Bar Preview System
- **Three Display Modes**: Icon-only, Timer-only, Name+Timer
- **Real-time Updates**: 1-second timer precision for countdown display
- **Smart Formatting**: Context-aware time formats (< 1 min, XX min, HH:MM h, X d)
- **Name Truncation**: 12-character limit with ellipsis for long meeting titles
- **Automatic Sync**: Updates immediately when calendar events change
- **Preference Integration**: User-configurable via new "Menu Bar" preferences tab
- **Fallback Behavior**: Shows icon only when no upcoming meetings exist

### Overlay System
- NSWindow instances created per display
- Window level: .floating + additional ordering
- SwiftUI content embedded via NSHostingView
- Keyboard shortcuts: ESC to dismiss, custom shortcuts for join/snooze
- Countdown timer with sub-second updates

### Accessibility
- VoiceOver labels for all interactive elements
- Keyboard navigation support
- Color contrast compliance (WCAG AA)
- Font scaling support (80%-140%)
- Screen reader announcements for time-sensitive information

## TESTING STRATEGY

### Unit Tests (Tests/UnmissableTests/)
- Event model validation and timezone conversion
- Link parser accuracy across providers
- Preference validation and persistence
- Provider detection algorithm
- Database operations and migrations

### Snapshot Tests (Tests/SnapshotTests/)
- OverlayContentView in different states (before meeting, during meeting, snoozed)
- Preference panels across themes and font sizes
- Menu bar content with various connection states
- Multi-display overlay layouts

### Integration Tests (Tests/IntegrationTests/)
- Calendar service with URLProtocol mocks
- OAuth flow simulation
- Database migration scenarios
- Sync manager with network simulation

### **Critical: Deadlock Prevention Tests**
- **ProductionDismissDeadlockTest**: Production-mode dismiss button testing
- **ProductionSnoozeEndToEndTest**: Complete snooze workflow validation
- **DismissDeadlockFixValidationTest**: Deadlock prevention verification
- **UIInteractionDeadlockTest**: All button interaction deadlock tests
- **WindowServerDeadlockTest**: NSWindow close() vs orderOut() testing
- **TimerInvalidationDeadlockTest**: Timer + window operation race conditions

**REQUIREMENT**: All UI interaction code MUST have corresponding deadlock tests with:
- Production mode testing (isTestMode: false)
- Real NSWindow + SwiftUI Button integration
- Timeout-based deadlock detection (5-10 second limits)
- Background queue dispatch pattern validation

### Testing Utilities
- Time-travel capabilities for scheduler testing
- Mock network responses for API integration
- Deterministic UUID generation for snapshots
- Preference reset helpers for isolated tests

## BUILD & DEVELOPMENT

### Build Commands
```bash
# Build application
xcodebuild -scheme Unmissable -destination 'platform=macOS' build

# Run tests
xcodebuild -scheme Unmissable -destination 'platform=macOS' test

# Code formatting
Scripts/format.sh

# Build for release (requires signing)
xcodebuild -scheme Unmissable -destination 'platform=macOS' archive
```

### Code Quality
- SwiftLint for style enforcement
- SwiftFormat for consistent formatting
- Required accessibility annotations
- OSLog for privacy-safe logging
- Memory leak prevention with weak references

## RUNTIME BEHAVIOR

### Application Lifecycle
1. Launch → MenuBarExtra appears
2. First run → OAuth setup and calendar selection
3. Background → Periodic sync (60s default)
4. Alert time → Full-screen overlay display
5. Quit → Stop all timers and save state

### Performance Characteristics
- Memory usage: ~50-150MB steady state
- CPU usage: <2% average (timer-driven spikes)
- Network: Minimal (sync intervals)
- Database: Single file, <10MB typical
- Overlay render time: <500ms on modern hardware

### Error Scenarios
- Network offline → Use cached events, show offline status
- Token expired → Automatic refresh, fallback to re-auth
- API rate limiting → Exponential backoff
- Calendar deleted → Remove from local cache, continue operation
- System sleep/wake → Resume sync operations, adjust timers

### Multi-Display Support
- Detect display configuration changes
- Create overlay windows per display
- Handle hot-plugging during active overlays
- Preference for primary-only vs all-displays

## PRIVACY & SECURITY

### Data Handling
- OAuth tokens stored in macOS Keychain (encrypted)
- Event data cached locally only (no external transmission)
- OSLog with PII redaction for debugging
- No analytics or telemetry collection

### Permissions Required
- **Accessibility**: Global keyboard shortcuts (optional)
- **Network**: HTTPS calendar API access
- **Keychain**: OAuth token storage

### Security Measures
- HTTPS-only communication
- PKCE for OAuth2 (prevents code interception)
- Automatic token refresh (reduces exposure window)
- Local-only data storage (no cloud dependencies)

## EXTENSION POINTS

### Adding New Meeting Providers
1. Extend Provider enum with new case
2. Add URL patterns to Provider.detect(from:)
3. Update LinkParser.extractLinks() for provider-specific parsing
4. Add provider-specific icons and display names

### Custom Alert Types
1. Extend ScheduledAlert.AlertType enum
2. Update EventScheduler.handleTriggeredAlert()
3. Add UI handling in OverlayManager
4. Consider persistence requirements

### Additional Calendar Sources
1. Create new service similar to GoogleCalendarAPIService
2. Implement common Event mapping interface
3. Update CalendarService to support multiple sources
4. Handle authentication differences

### Notification Channels
1. Extend OverlayManager for additional display types
2. Create notification providers (macOS Notifications, email, etc.)
3. Add preference controls for notification channels
4. Consider delivery confirmation mechanisms

## DEBUG AND TROUBLESHOOTING

### Logging Categories
- `com.unmissable.app.AppState` - Service coordination
- `com.unmissable.app.CalendarService` - Sync operations
- `com.unmissable.app.OverlayManager` - Overlay display
- `com.unmissable.app.EventScheduler` - Alert scheduling
- `com.unmissable.app.DatabaseManager` - Database operations

### Common Issues
- **No overlays appearing**: Check EventScheduler alerts, verify overlay preferences
- **Sync failures**: Verify network connectivity, check OAuth token validity
- **Missing events**: Confirm calendar selection, check all-day event preferences
- **Display issues**: Verify multi-display settings, check window ordering
- **Performance problems**: Monitor database size, check sync interval settings

### Development Tools
- Console.app for OSLog output
- Database browser for SQLite inspection
- Network proxy tools for API debugging
- Accessibility Inspector for UI testing
- Time simulation for scheduler testing

## ⚠️ CRITICAL: DEADLOCK PREVENTION

### **MANDATORY READING FOR ALL DEVELOPERS**

This section documents critical deadlock issues that were discovered and resolved. **ALL FUTURE DEVELOPMENT MUST FOLLOW THESE PATTERNS** to avoid production-breaking deadlocks.

### **Root Cause: NSWindow.close() + Window Server Deadlock**

#### **The Problem (NEVER DO THIS):**
```swift
#### **The Problem (NEVER DO THIS):**

```swift
// ❌ DEADLOCK PRONE - DO NOT USE
func hideOverlay() {
  stopCountdownTimer()
  for window in overlayWindows {
    window.close()  // BLOCKS main thread waiting for Window Server
  }
  overlayWindows.removeAll()
}
```

#### **Why This Causes Deadlocks:**

1. **NSWindow.close()** requires synchronous communication with macOS Window Server
2. **Window Server** needs multiple main thread run loop iterations to complete cleanup
3. **Timer callbacks** executing on main thread prevent Window Server communication
4. **Result**: Circular dependency → Application freeze when clicking dismiss/snooze buttons

#### **The Solution (ALWAYS USE THIS):**

```swift
// ✅ DEADLOCK FREE - REQUIRED PATTERN
func hideOverlay() {
  // CRITICAL: Stop timers FIRST
  stopCountdownTimer()
  soundManager.stopSound()

  // CRITICAL: Clear state BEFORE window operations
  activeEvent = nil
  isOverlayVisible = false

  // CRITICAL: Use orderOut instead of close
  let windowsToClose = overlayWindows
  overlayWindows.removeAll()

  for window in windowsToClose {
    window.orderOut(nil)  // Non-blocking window hiding
  }
}
```
```

#### **Why This Causes Deadlocks:**
1. **NSWindow.close()** requires synchronous communication with macOS Window Server
2. **Window Server** needs multiple main thread run loop iterations to complete cleanup
3. **Timer callbacks** executing on main thread prevent Window Server communication
4. **Result**: Circular dependency → Application freeze when clicking dismiss/snooze buttons

#### **The Solution (ALWAYS USE THIS):**
```swift
// ✅ DEADLOCK FREE - REQUIRED PATTERN
func hideOverlay() {
  // CRITICAL: Stop timers FIRST
  stopCountdownTimer()
  soundManager.stopSound()

  // CRITICAL: Clear state BEFORE window operations
  activeEvent = nil
  isOverlayVisible = false

  // CRITICAL: Use orderOut instead of close
  let windowsToClose = overlayWindows
  overlayWindows.removeAll()

  for window in windowsToClose {
    window.orderOut(nil)  // Non-blocking window hiding
  }
}
```

### **Key Differences:**
- **`NSWindow.close()`**: Complex cleanup, Window Server communication, deadlock prone
- **`NSWindow.orderOut(nil)`**: Simple window hiding, no complex cleanup, deadlock free

### **Safe Callback Patterns for UI Interactions**

#### **SwiftUI Button Callbacks (REQUIRED PATTERN):**
```swift
#### **SwiftUI Button Callbacks (REQUIRED PATTERN):**

```swift
// ✅ SAFE - Background queue dispatch pattern
onDismiss: { [weak self] in
  DispatchQueue.global(qos: .userInitiated).async {
    DispatchQueue.main.async {
      self?.hideOverlay()
    }
  }
}

onSnooze: { [weak self] minutes in
  DispatchQueue.global(qos: .userInitiated).async {
    DispatchQueue.main.async {
      self?.snoozeOverlay(for: minutes)
    }
  }
}
```
```

#### **Why Background Queue Dispatch Is Required:**
1. **Breaks out of current main thread execution context**
2. **Prevents circular dependencies** between timer callbacks and UI operations
3. **Allows Window Server communication** to complete without blocking
4. **Maintains UI responsiveness** during overlay operations

### **Timer Management (CRITICAL PATTERNS)**

#### **Safe Timer Invalidation:**
```swift
// ✅ SAFE - Always stop timers BEFORE window operations
func hideOverlay() {
  // STEP 1: Stop ALL timers immediately
  stopCountdownTimer()
  soundManager.stopSound()

  // STEP 2: Clear application state
  activeEvent = nil
  isOverlayVisible = false

  // STEP 3: Then handle windows (after timers stopped)
  // ... window operations
}

private func stopCountdownTimer() {
  countdownTimer?.invalidate()
  countdownTimer = nil
}
```

#### **Safe Timer Callbacks:**

```swift
// ✅ SAFE - Check state before operations
private func updateCountdown(for event: Event) {
  // CRITICAL: Always guard against invalid state
  guard isOverlayVisible, let activeEvent = activeEvent, activeEvent.id == event.id else {
    logger.warning("⚠️ UPDATE COUNTDOWN: Overlay not visible or event mismatch, stopping timer")
    stopCountdownTimer()
    return
  }

  timeUntilMeeting = event.startDate.timeIntervalSinceNow

  // Auto-hide if meeting started more than 5 minutes ago
  if timeUntilMeeting < -300 {
    logger.info("⏰ AUTO-HIDE: Meeting started >5 minutes ago, hiding overlay")
    // CRITICAL FIX: Use async dispatch to prevent timer re-entrance issues
    DispatchQueue.main.async { [weak self] in
      self?.hideOverlay()
    }
  }
}
```
```

### **Testing Requirements for UI Operations**

#### **ALL UI interactions MUST have deadlock tests:**
```swift
// REQUIRED: Production-mode testing (isTestMode: false)
let overlayManager = OverlayManager(
  preferencesManager: preferencesManager,
  focusModeManager: focusModeManager,
  isTestMode: false  // CRITICAL: Use real windows
)

// REQUIRED: Test actual button callbacks, not simulated actions
Task {
  overlayManager.hideOverlay()  // Real production call
  dismissCompleted = true
}

// REQUIRED: Deadlock detection with timeout
let deadlockMonitor = Task {
  try await Task.sleep(nanoseconds: 5_000_000_000)  // 5 seconds
  if !dismissCompleted {
    deadlockDetected = true  // FAIL the test
  }
}
```

### **Validation Checklist for New UI Code**

Before adding ANY new UI interaction code, verify:

- [ ] **Uses `window.orderOut(nil)` instead of `window.close()`**
- [ ] **Stops all timers BEFORE window operations**
- [ ] **Clears application state BEFORE window operations**
- [ ] **Uses background queue dispatch for button callbacks**
- [ ] **Guards timer callbacks against invalid state**
- [ ] **Has production-mode deadlock tests**
- [ ] **Tests with real NSWindow + SwiftUI integration**
- [ ] **Includes timeout-based deadlock detection**

### **Signs of Deadlock Issues**
- Application freezes when clicking buttons
- UI becomes unresponsive during overlay operations
- Timer callbacks continue after overlay should be hidden
- Window operations taking longer than 1-2 seconds
- Force quit required to exit application

### **Emergency Debugging**
If deadlocks occur in production:
1. **Check Console.app** for timer callback errors
2. **Verify window close vs orderOut usage**
3. **Look for timer/callback execution order issues**
4. **Confirm background queue dispatch patterns**
5. **Run deadlock reproduction tests**

**⚠️ CRITICAL: These patterns are MANDATORY for overlay-related code. Ignoring them WILL cause production deadlocks.**

## FUTURE ENHANCEMENT AREAS

### Calendar Integration
- Support for additional calendar providers (Outlook, iCloud, CalDAV)
- Bi-directional sync (create/update events)
- Invitation response handling
- Meeting notes and follow-up tracking

### Meeting Features
- Join meeting with preferred application
- Meeting preparation reminders
- Automatic meeting recording detection
- Smart meeting conflict resolution

### User Experience
- Custom alert sounds and themes
- Meeting analytics and insights
- Integration with other productivity tools
- Widget support for Control Center

This documentation provides a comprehensive foundation for LLM coding agents to understand and work effectively with the Unmissable codebase. The architecture is designed for maintainability, testability, and extensibility while following Swift and macOS development best practices.
