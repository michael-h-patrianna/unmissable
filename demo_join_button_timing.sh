#!/bin/bash

echo "🎯 Testing Join Button 10-Minute Window"
echo "======================================="

cd /Users/michaelhaufschild/Documents/code/unmissable

# Clean up any existing test data
echo "🧹 Cleaning up database..."
swift -e "
import Foundation
import SQLite3

let dbPath = NSHomeDirectory() + \"/Library/Application Support/Unmissable/database.sqlite\"
var db: OpaquePointer?

if sqlite3_open(dbPath, &db) == SQLITE_OK {
    // Delete test events
    let deleteSQL = \"DELETE FROM events WHERE id LIKE 'demo-%'\"
    var statement: OpaquePointer?
    if sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK {
        sqlite3_step(statement)
        print(\"🗑️ Cleaned up demo events\")
    }
    sqlite3_finalize(statement)
    sqlite3_close(db)
}
"

# Create test meetings with different time windows
echo "📅 Creating test meetings..."
swift -e "
import Foundation
import SQLite3

let dbPath = NSHomeDirectory() + \"/Library/Application Support/Unmissable/database.sqlite\"
var db: OpaquePointer?

if sqlite3_open(dbPath, &db) == SQLITE_OK {
    let now = Date()

    // Meeting in 15 minutes (should NOT show join button)
    let future15 = now.addingTimeInterval(900)
    let future15End = now.addingTimeInterval(2700)

    // Meeting in 5 minutes (should show join button)
    let future5 = now.addingTimeInterval(300)
    let future5End = now.addingTimeInterval(2100)

    // Started meeting (should show join button)
    let started = now.addingTimeInterval(-300)
    let startedEnd = now.addingTimeInterval(1500)

    let meetings = [
        (\"demo-too-early\", \"📅 Meeting Too Early (15 min)\", future15, future15End, \"https://meet.google.com/too-early\"),
        (\"demo-just-right\", \"✅ Meeting Just Right (5 min)\", future5, future5End, \"https://meet.google.com/just-right\"),
        (\"demo-started\", \"🟢 Started Meeting\", started, startedEnd, \"https://meet.google.com/started-now\")
    ]

    for meeting in meetings {
        let insertSQL = \"\"\"
        INSERT OR REPLACE INTO events
        (id, title, startDate, endDate, organizer, isAllDay, calendarId, timezone, links, provider, snoozeUntil, autoJoinEnabled, createdAt, updatedAt)
        VALUES
        (?, ?, ?, ?, 'demo@example.com', 0, 'demo-calendar', 'UTC', ?, 'meet', NULL, 1, ?, ?)
        \"\"\"

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, meeting.0, -1, nil)
            sqlite3_bind_text(statement, 2, meeting.1, -1, nil)
            sqlite3_bind_double(statement, 3, meeting.2.timeIntervalSince1970)
            sqlite3_bind_double(statement, 4, meeting.3.timeIntervalSince1970)
            sqlite3_bind_text(statement, 5, \"[\\\"\" + meeting.4 + \"\\\"]\", -1, nil)
            sqlite3_bind_double(statement, 6, now.timeIntervalSince1970)
            sqlite3_bind_double(statement, 7, now.timeIntervalSince1970)

            if sqlite3_step(statement) == SQLITE_DONE {
                print(\"✅ Created: \" + meeting.1)
            }
        }
        sqlite3_finalize(statement)
    }
    sqlite3_close(db)
}
"

echo ""
echo "🚀 Starting Unmissable..."
echo "📋 Check the menubar dropdown to see:"
echo "   • 📅 Meeting Too Early (15 min) - NO join button"
echo "   • ✅ Meeting Just Right (5 min) - HAS join button"
echo "   • 🟢 Started Meeting - HAS join button"
echo ""
echo "⏰ Wait and watch as buttons appear/disappear based on time!"
echo "🔄 UI updates every 30 seconds automatically"
echo ""
echo "Press Ctrl+C to stop..."

# Run the app
swift run Unmissable
