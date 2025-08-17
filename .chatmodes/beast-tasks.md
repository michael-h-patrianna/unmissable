# Beast Tasks - Join Button 10-Minute Window

## Phase 1: UNDERSTAND & PLAN [✓]

- [✓] Analyze current join button logic in CustomEventRow
- [✓] Identify real-time update mechanism for MenuBarView
- [✓] Plan 10-minute window logic for both upcoming and started meetings
- [✓] Design test strategy for time-based button visibility

## Phase 2: IMPLEMENT SOLUTION [✓]

- [✓] Add 10-minute window logic to Event model (shouldShowJoinButton computed property)
- [✓] Update CustomEventRow to conditionally show join button based on time
- [✓] Ensure real-time updates via 30-second UI refresh timer in CalendarService
- [✓] Test button appears exactly 10 minutes before meeting
- [✓] Test button remains available during started meetings
- [✓] Update existing tests to account for new join button logic

## Phase 3: VALIDATE & ITERATE [✓]

- [✓] Test join button appears at T-10 minutes for upcoming meetings
- [✓] Test join button remains visible for started meetings
- [✓] Test join button disappears for meetings >10 minutes away
- [✓] Verify real-time updates work correctly (30-second timer implemented)
- [✓] Test with multiple meetings at different time windows
- [✓] Validate new test passes with 10-minute window logic
