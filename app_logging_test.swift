import Foundation
import OSLog

// Test logging within an app-like context
let logger = Logger(subsystem: "com.unmissable.app", category: "LoggingTest")

print("🚀 APP LOGGING TEST START")
fflush(stdout)

// Test different log levels
logger.info("📋 Logger INFO test")
logger.debug("🔍 Logger DEBUG test") 
logger.error("❌ Logger ERROR test")

// Test print statements in app context
print("✅ Print statement in app context")
fflush(stdout)

// Test file logging
let logFile = "/tmp/unmissable_app_test.log"
let message = "🔍 App logging test at \(Date())\n"

do {
    try message.write(toFile: logFile, atomically: true, encoding: .utf8)
    print("📝 File write successful: \(logFile)")
    fflush(stdout)
} catch {
    print("❌ File write failed: \(error)")
    fflush(stdout)
}

print("✅ APP LOGGING TEST COMPLETE")
fflush(stdout)
