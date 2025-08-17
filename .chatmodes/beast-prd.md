# Beast PRD - Meeting Details Popup

## Problem Statement & Users

**Problem**: Users need detailed information about meetings beyond what's shown in the basic menu bar dropdown. Currently, the menu bar only displays meeting title and time, but users often need to see meeting descriptions, participant lists, and other details to prepare or understand meeting context.

**Users**: Unmissable app users who need quick access to comprehensive meeting information without opening their calendar application.

**Jobs to Be Done (JTBD)**:

- As a user, I want to click on a meeting in the dropdown to see detailed information
- As a user, I want to see the meeting description to understand the agenda and context
- As a user, I want to see the participant list to know who will be attending
- As a user, I want scrollable containers for long descriptions and participant lists
- As a user, I want the popup to match the app's theming (light/dark mode)
- As a user, I want the popup to handle edge cases gracefully (missing data, very long content)

## Goals & Success Criteria

**Primary Goal**: Enable users to access detailed meeting information through a popup triggered by clicking meeting entries in the menu bar dropdown.

**Success Metrics**:

- ✅ Clicking any meeting entry opens a detailed popup with description and participants
- ✅ Long descriptions and participant lists are scrollable within the popup
- ✅ Popup integrates seamlessly with custom theming system
- ✅ All edge cases are handled gracefully (missing data, very long content)
- ✅ No memory leaks or deadlocks introduced by popup functionality
- ✅ End-to-end UI testing validates actual functionality

## Scope

### In Scope

- MeetingDetailsView SwiftUI component with scrollable content
- MeetingDetailsPopupManager for popup window management
- Click interaction on MenuBarView meeting entries
- Full integration with CustomThemeManager and design system
- Scrollable containers for descriptions and participant lists
- Edge case handling for missing/empty/very long data
- Memory leak prevention and deadlock avoidance patterns
- Comprehensive end-to-end testing suite

### Out of Scope

- Editing meeting details within the popup
- Creating new meetings from the popup
- Integration with other calendar providers (focus on Google Calendar)
- Advanced text formatting/rich text display
- Participant photos or status indicators
- Meeting notes or follow-up features

## Functional Requirements

### FR1: Popup Trigger Mechanism

- **MUST** make meeting entries in MenuBarView clickable
- **MUST** show appropriate hover states for interactive elements
- **MUST** trigger popup on click without interfering with existing functionality
- **MUST** handle keyboard navigation (Enter key support)

### FR2: Meeting Details Display

- **MUST** display meeting title, date/time, and duration prominently
- **MUST** show meeting description if available, with "No description" fallback
- **MUST** display participant list with names/emails if available
- **MUST** show meeting location and provider information
- **MUST** include meeting join link/button for quick access

### FR3: Scrollable Content Management

- **MUST** implement scrollable container for meeting descriptions longer than display area
- **MUST** implement scrollable container for participant lists with many attendees
- **MUST** set maximum popup dimensions to prevent screen overflow
- **MUST** provide visual scroll indicators that match theme
- **MUST** handle very long content gracefully (>10,000 characters)

### FR4: Popup Window Management

- **MUST** display popup as a properly positioned window relative to menu bar
- **MUST** dismiss popup when clicking outside or pressing Escape
- **MUST** handle multiple display configurations correctly
- **MUST** prevent multiple popup instances for the same meeting

### FR5: Data Model Extensions

- **MUST** extend Event model to include description and participant fields
- **MUST** update Google Calendar API integration to fetch description and attendees
- **MUST** handle missing or null data gracefully in UI
- **MUST** store participant information in local database

## Non-Functional Requirements

### Performance

- Popup display response time: <500ms after click
- Scrolling performance: Smooth 60fps scrolling for long content
- Memory usage: No memory leaks during repeated popup operations
- No deadlocks during window operations (orderOut vs close patterns)

### Accessibility

- Screen reader compatible content announcements
- Keyboard navigation support for all interactive elements
- High contrast theme support maintained
- Font scaling support (80%-140% range)
- VoiceOver labels for all UI components

### Localization

- Support for 12/24 hour time format preferences
- Proper timezone handling and display
- Right-to-left text support for descriptions
- Extensible for future language localization

### SwiftUI macOS Constraints

- Work within MenuBarExtra limitations
- Handle NSWindow lifecycle properly
- Follow documented deadlock prevention patterns
- Use custom theming system exclusively (no system dependencies)

## Acceptance Criteria

### AC1: Basic Popup Functionality

**Given** a user opens the menu bar dropdown with upcoming meetings
**When** the user clicks on any meeting entry
**Then** a popup window appears with detailed meeting information
**And** the popup displays title, time, description, and participants
**And** the popup can be dismissed by clicking outside or pressing Escape

### AC2: Scrollable Content Handling

**Given** a meeting with a very long description (>1000 characters)
**When** the user opens the meeting details popup
**Then** the description is displayed in a scrollable container
**And** the container has a maximum height constraint
**And** scroll indicators are visible and themed appropriately

**Given** a meeting with many participants (>20 people)
**When** the user opens the meeting details popup
**Then** the participant list is displayed in a scrollable container
**And** all participants are accessible through scrolling

### AC3: Theme Integration

**Given** the app is set to light theme
**When** a user opens a meeting details popup
**Then** the popup uses light theme colors and styling from CustomDesign
**And** switching to dark theme updates the popup immediately
**And** all custom components (buttons, text, backgrounds) follow theme

### AC4: Edge Case Handling

**Given** a meeting with no description
**When** the user opens the meeting details popup
**Then** the description section shows "No description available"
**And** the popup layout remains properly formatted

**Given** a meeting with no participants data
**When** the user opens the meeting details popup
**Then** the participants section shows "Participant information unavailable"
**And** the popup remains functional

**Given** a meeting with extremely long description (>10,000 characters)
**When** the user opens the meeting details popup
**Then** the popup displays without performance issues
**And** scrolling remains smooth and responsive

### AC5: Memory and Performance

**Given** a user opens and closes meeting popups repeatedly (50+ times)
**When** monitoring memory usage and application performance
**Then** no memory leaks are detected
**And** no deadlocks occur during window operations
**And** popup response time remains under 500ms

### AC6: Integration Testing

**Given** the complete meeting details popup implementation
**When** running end-to-end tests with real UI interactions
**Then** all popup functionality works in production mode (`isTestMode: false`)
**And** deadlock detection tests pass with timeout monitoring
**And** accessibility features function correctly
**And** theme switching works seamlessly

## Technical Implementation Plan

### Data Model Changes

```swift
// Extend Event model
struct Event {
    // ... existing fields
    let description: String?         // Meeting description/agenda
    let attendees: [Attendee]?      // Participant list
}

struct Attendee {
    let name: String?               // Display name
    let email: String               // Email address
    let status: AttendeeStatus?     // Response status
}
```

### UI Components

- **MeetingDetailsView**: Main popup content with scrollable sections
- **MeetingDetailsPopupManager**: Window management and lifecycle
- **Enhanced MenuBarView**: Clickable meeting entries
- **Custom scroll containers**: Themed scrollable areas

### Window Management

- Use NSWindow with proper positioning relative to menu bar
- Implement orderOut(nil) pattern for deadlock prevention
- Handle multi-display configurations
- Follow documented memory management patterns

### Testing Strategy

- Production mode testing with real NSWindow operations
- Deadlock detection with timeout monitoring
- Memory leak testing during repeated operations
- End-to-end UI interaction validation
- Accessibility compliance testing

## Technical Risks & Mitigation

### Risk 1: Memory Leaks

**Mitigation**: Follow documented patterns for timer management, use weak references in closures, avoid environment object retain cycles

### Risk 2: Deadlocks

**Mitigation**: Use orderOut(nil) instead of close(), background queue dispatch for UI callbacks, stop timers before window operations

### Risk 3: MenuBarExtra Limitations

**Mitigation**: Design popup as separate NSWindow, position relative to menu bar, handle dismissal properly

### Risk 4: Performance with Large Content

**Mitigation**: Use LazyVStack for large participant lists, implement content size limits, optimize scroll performance

**Done**: Comprehensive PRD complete for meeting details popup functionality with proper SwiftUI macOS considerations and thorough testing requirements.
