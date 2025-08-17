import Foundation
import OSLog

// Enhanced logging utility that ensures visibility
class EnhancedLogger {
    private let logger: Logger
    private let logFile: String
    
    init(subsystem: String, category: String, logFile: String = "/tmp/unmissable_debug.log") {
        self.logger = Logger(subsystem: subsystem, category: category)
        self.logFile = logFile
    }
    
    func log(_ message: String) {
        // 1. Print to stdout (always visible)
        print(message)
        fflush(stdout)
        
        // 2. Write to file (persistent)
        let timestamped = "\(Date()): \(message)\n"
        if let data = timestamped.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFile) {
                if let fileHandle = FileHandle(forWritingAtPath: logFile) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: URL(fileURLWithPath: logFile))
            }
        }
        
        // 3. Also use system logger (for Console.app)
        logger.info("\(message)")
    }
}

// Test the enhanced logger
let enhancedLogger = EnhancedLogger(subsystem: "com.unmissable.app", category: "EnhancedTest")

enhancedLogger.log("🚀 ENHANCED LOGGING TEST START")
enhancedLogger.log("🔍 RAW API RESPONSE for first event:")
enhancedLogger.log("   - ID: test123")
enhancedLogger.log("   - Summary: Test Meeting")
enhancedLogger.log("   - Description in API: YES")
enhancedLogger.log("   - Location in API: NO")
enhancedLogger.log("   - Attendees in API: YES")
enhancedLogger.log("   - Attendees count: 3")
enhancedLogger.log("🔄 SYNC: Got 3 events from API")
enhancedLogger.log("✅ ENHANCED LOGGING TEST COMPLETE")

print("📝 Check log file at: /tmp/unmissable_debug.log")
