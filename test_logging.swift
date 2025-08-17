#!/usr/bin/env swift

import Foundation

print("=== LOGGING TEST ===")
print("✅ Basic print statement works")

// Test fflush to force output
print("🔄 Testing immediate output...")
fflush(stdout)

// Test writing to stderr
fputs("❌ Testing stderr output\n", stderr)
fflush(stderr)

// Test Foundation logging
let now = Date()
print("📅 Current time: \(now)")

// Test file writing
let testMessage = "🔍 Test log entry at \(now)\n"
if let data = testMessage.data(using: .utf8) {
    let url = URL(fileURLWithPath: "/tmp/unmissable_test.log")
    try? data.write(to: url)
    print("📝 Wrote to file: \(url.path)")
}

print("=== END LOGGING TEST ===")
