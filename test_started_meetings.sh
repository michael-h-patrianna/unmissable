#!/bin/bash

echo "Testing Started Meetings Functionality"
echo "======================================="

# Kill any existing instances
pkill -f Unmissable || echo "No existing app found"

# Build the app
echo "Building app..."
swift build

# Add a test started meeting to the database
swift -e "
import Foundation
import SQLite3

let dbPath = NSHomeDirectory() + \"/Library/Application Support/Unmissable/database.sqlite\"
var db: OpaquePointer?

if sqlite3_open(dbPath, &db) == SQLITE_OK {
    let now = Date()
    let startDate = now.addingTimeInterval(-600) // 10 minutes ago
    let endDate = now.addingTimeInterval(1800)   // 30 minutes from now

    let insertSQL = \"\"\"
    INSERT OR REPLACE INTO events
    (id, title, startDate, endDate, organizer, isAllDay, calendarId, timezone, links, provider, snoozeUntil, autoJoinEnabled, createdAt, updatedAt)
    VALUES
    ('manual-test-started', 'MANUAL TEST STARTED MEETING', ?, ?, 'test@example.com', 0, 'test-calendar', 'UTC', '[\"https://meet.google.com/test-started\"]', 'meet', NULL, 1, ?, ?)
    \"\"\"

    var statement: OpaquePointer?
    if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
        sqlite3_bind_double(statement, 1, startDate.timeIntervalSince1970)
        sqlite3_bind_double(statement, 2, endDate.timeIntervalSince1970)
        sqlite3_bind_double(statement, 3, now.timeIntervalSince1970)
        sqlite3_bind_double(statement, 4, now.timeIntervalSince1970)

        if sqlite3_step(statement) == SQLITE_DONE {
            print(\"✅ Test started meeting added to database\")
        } else {
            print(\"❌ Failed to add test meeting\")
        }
    }
    sqlite3_finalize(statement)
    sqlite3_close(db)
} else {
    print(\"❌ Failed to open database\")
}
"

echo ""
echo "Running app with started meeting data..."
echo "Please check the menubar dropdown for a 'Started' group with the test meeting"
echo "Press Ctrl+C to stop the app"

# Run the app
swift run Unmissable
