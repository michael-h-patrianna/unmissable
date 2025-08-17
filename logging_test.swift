#!/usr/bin/env swift

import Foundation

// Test basic Swift logging functionality
print("🚀 LOGGING TEST START")
fflush(stdout)

// Test 1: Basic print to stdout
print("✅ Test 1: Basic print statement")
fflush(stdout)

// Test 2: Print with emoji and special characters
print("🔍 Test 2: Emoji and special chars work")
fflush(stdout)

// Test 3: Multi-line output
let testData = [
    "📝 Event 1: Meeting with description",
    "   - Description: YES (25 chars)",
    "   - Attendees: 3 attendees",
    "🔄 SYNC: Got 3 events from API"
]

for line in testData {
    print(line)
    fflush(stdout)
}

// Test 4: File writing
let logFile = "/tmp/unmissable_logging_test.log"
let testMessage = "🔍 Logging test at \(Date())\n"

do {
    try testMessage.write(toFile: logFile, atomically: true, encoding: .utf8)
    print("📝 Test 4: Successfully wrote to file: \(logFile)")
} catch {
    print("❌ Test 4: Failed to write to file: \(error)")
}

// Test 5: Read back from file
do {
    let content = try String(contentsOfFile: logFile)
    print("📤 Test 5: Read from file: \(content.trimmingCharacters(in: .whitespacesAndNewlines))")
} catch {
    print("❌ Test 5: Failed to read from file: \(error)")
}

print("✅ LOGGING TEST COMPLETE")
fflush(stdout)
