# Beast PRD - Join Button 10-Minute Window

## Problem & Users (Jobs to be Done)

**User Job**: "I want the Google Meet join button to only appear when it's actually useful - 10 minutes before the meeting starts and during the meeting - not hours earlier when I might accidentally click it."

**Current Pain**: Join buttons appear immediately for all online meetings regardless of timing, leading to accidental early joins and cluttered UI.

## Goals & Success Metrics

- **Primary Goal**: Show join buttons only within a 10-minute window before meeting start
- **Success Metric**: Zero accidental early joins, cleaner UI for distant meetings
- **User Experience**: Join buttons appear exactly when needed with real-time updates

## Scope

### In Scope ✅
- 10-minute window logic for join button visibility (10 minutes before start ≤ now < end)
- Real-time UI updates to show/hide buttons based on time
- Apply to both upcoming and started meetings in menubar dropdown
- Maintain all existing join functionality once button is visible

### Out of Scope
- Different time windows for different meeting types
- User-configurable timing preferences
- Visual indicators for when button will appear
- Apply timing to other UI components beyond menubar

## Functional Requirements

### FR1: Time-Based Button Visibility ✅
- **Requirement**: Join button visible only when now ≥ (startDate - 10 minutes) AND now < endDate
- **Implementation**: `Event.shouldShowJoinButton` computed property with real-time calculation
- **Acceptance**: Button appears exactly 10 minutes before, stays during meeting, disappears when ended

### FR2: Real-Time Updates ✅
- **Requirement**: UI refreshes automatically to show/hide buttons as time passes
- **Implementation**: 30-second UI refresh timer in CalendarService
- **Acceptance**: No manual refresh needed, buttons appear/disappear smoothly

### FR3: Cross-Meeting Support ✅
- **Requirement**: Logic applies to both upcoming and started meetings
- **Implementation**: Single computed property used in CustomEventRow for all meeting states
- **Acceptance**: Consistent behavior across "Started", "Today", "Tomorrow" groups

## Non-Functional Requirements

### Performance ✅
- Button visibility calculation: <1ms per event (simple date comparison)
- UI refresh overhead: Minimal with 30-second interval
- No impact on existing sync or overlay systems

### User Experience ✅
- No breaking changes to existing join functionality
- Seamless transition when buttons appear/disappear
- Maintains Google Meet link detection and click handling

## Acceptance Criteria (Testable & Measurable)

### AC1: 10-Minute Window Logic ✅
- **Test**: `StartedMeetingsTests.testJoinButtonTenMinuteWindow()`
- **Criteria**:
  - Meeting 15+ minutes away: shouldShowJoinButton = false
  - Meeting 5 minutes away: shouldShowJoinButton = true
  - Started meeting: shouldShowJoinButton = true
  - Ended meeting: shouldShowJoinButton = false
- **Status**: ✅ PASSED

### AC2: UI Integration ✅
- **Test**: Manual verification with demo script
- **Criteria**: CustomEventRow conditionally shows join button based on shouldShowJoinButton
- **Status**: ✅ VERIFIED - Button visibility controlled by computed property

### AC3: Real-Time Updates ✅
- **Test**: CalendarService UI refresh timer
- **Criteria**: Events refresh every 30 seconds to trigger UI updates
- **Status**: ✅ VERIFIED - Timer implemented and running

### AC4: No Regression ✅
- **Test**: Existing join functionality validation
- **Criteria**: When button is visible, all existing join behavior works identically
- **Status**: ✅ VERIFIED - Only visibility logic changed, not click handling

## IMPLEMENTATION COMPLETED ✅

**Status**: DONE - 10-minute window logic implemented and tested
**Key Changes**:
- `Event.shouldShowJoinButton` computed property with time window logic
- `CustomEventRow` updated to use new property instead of `isOnlineMeeting`
- `CalendarService` 30-second UI refresh timer for real-time updates
- Comprehensive tests validate timing logic across different scenarios

**User Impact**: Cleaner UI with contextually appropriate join buttons that appear exactly when needed.
