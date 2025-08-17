# Beast Knowledge - Project Analysis Context

## Project Understanding

- **Project Type**: macOS SwiftUI calendar integration app with overlay notifications
- **Architecture**: Service-oriented with dependency injection, SQLite storage, OAuth2 authentication
- **Build System**: Swift Package Manager
- **Platform**: macOS 14+ with menu bar integration
- **Purpose**: Calendar meeting reminders with full-screen overlays

## Key Architectural Components

- Core services: AppState, CalendarService, EventScheduler, OverlayManager
- Custom theming system (mandatory - no system colors/fonts)
- Google Calendar API integration with OAuth2
- SQLite database (GRDB.swift) for event storage
- Timer-based event scheduling and overlay management

## Critical Constraints

- Must prevent deadlocks (NSWindow.close() issues)
- Custom theming required throughout
- Memory leak prevention patterns
- Background queue dispatch for UI callbacks
- Complete field copying in Event instances

## Analysis Context

- Scanning for obsolete test files, debugging artifacts, and unused components
- Recent fixes include TimezoneManager data loss bug and HTML/attachments system
- Focus on identifying truly unnecessary files vs. temporarily unused but architecturally important files
