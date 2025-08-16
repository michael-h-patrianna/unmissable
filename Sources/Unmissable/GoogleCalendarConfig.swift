import Foundation

struct GoogleCalendarConfig {
  // OAuth 2.0 configuration for Google Calendar API
  static let authorizationEndpoint = URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!
  static let tokenEndpoint = URL(string: "https://oauth2.googleapis.com/token")!
  static let issuer = URL(string: "https://accounts.google.com")!

  // Google Calendar API scopes
  static let scopes = [
    "https://www.googleapis.com/auth/calendar.readonly",
    "https://www.googleapis.com/auth/calendar.calendarlist.readonly",
    "https://www.googleapis.com/auth/userinfo.email",
  ]

  // MARK: - Secure Configuration Loading
  
  /// OAuth Client ID - loads from environment variable or Config.plist (in project root)
  /// This prevents committing sensitive credentials to git
  static let clientId: String = {
    // Try environment variable first (for development/CI)
    if let envClientId = ProcessInfo.processInfo.environment["GOOGLE_OAUTH_CLIENT_ID"],
       !envClientId.isEmpty,
       !envClientId.contains("YOUR_GOOGLE_OAUTH_CLIENT_ID") {
      return envClientId
    }
    
    // Try loading from Config.plist in project root (for local development)
    // This works for both debug and release builds when Config.plist is in project root
    if let configData = loadConfigFromProjectRoot(),
       let clientId = configData["GoogleOAuthClientID"] as? String,
       !clientId.isEmpty,
       !clientId.contains("YOUR_GOOGLE_OAUTH_CLIENT_ID") {
      return clientId
    }
    
    // Fallback error with helpful setup instructions
    fatalError("""
      ❌ OAUTH CLIENT ID NOT CONFIGURED
      
      📋 SETUP OPTIONS:
      
      Option 1 - Environment Variable (Recommended for CI/deployment):
      export GOOGLE_OAUTH_CLIENT_ID="your-client-id-here"
      
      Option 2 - Config.plist in project root (Recommended for local development):
      1. Copy: Config.plist.example → Config.plist (in project root)
      2. Edit Config.plist and replace YOUR_GOOGLE_OAUTH_CLIENT_ID with your actual client ID
      3. Config.plist will work for both debug and release builds automatically
      
      🔗 GET CLIENT ID: https://console.developers.google.com/
      
      🔒 SECURITY: Config.plist is excluded from git via .gitignore
      Environment variables are secure for CI/deployment
      """)
  }()
  
  static let redirectScheme: String = {
    // Try environment variable first
    if let envScheme = ProcessInfo.processInfo.environment["GOOGLE_OAUTH_REDIRECT_SCHEME"],
       !envScheme.isEmpty {
      return envScheme
    }
    
    // Try Config.plist in project root
    if let configData = loadConfigFromProjectRoot(),
       let scheme = configData["RedirectScheme"] as? String,
       !scheme.isEmpty {
      return scheme
    }
    
    // Safe default fallback
    return "com.unmissable.app"
  }()
  
  static let redirectURI = "\(redirectScheme):/"

  // API Base URLs
  static let calendarAPIBaseURL = "https://www.googleapis.com/calendar/v3"
  
  // MARK: - Environment Detection
  
  static let environment: String = {
    return ProcessInfo.processInfo.environment["UNMISSABLE_ENV"] ?? "production"
  }()
  
  static var isDevelopment: Bool {
    return environment == "development"
  }
  
  // MARK: - Configuration Loading Helper
  
  /// Loads Config.plist from project root directory
  /// This works for both debug and release builds when the plist is in the project root
  private static func loadConfigFromProjectRoot() -> [String: Any]? {
    // Try to find Config.plist in the project root by looking relative to the bundle
    let possiblePaths = [
      // For development builds - relative to current working directory
      "Config.plist",
      // For Xcode builds - relative to project directory  
      "../../../Config.plist",
      // For Swift Package Manager builds - relative to package root
      "../../Config.plist",
      // Additional fallback paths
      "../Config.plist",
      "../../../../Config.plist"
    ]
    
    for relativePath in possiblePaths {
      let expandedPath = NSString(string: relativePath).expandingTildeInPath
      if FileManager.default.fileExists(atPath: expandedPath),
         let plist = NSDictionary(contentsOfFile: expandedPath) as? [String: Any] {
        return plist
      }
    }
    
    // Also try relative to current working directory (for swift run)
    let currentDir = FileManager.default.currentDirectoryPath
    let configPath = NSString(string: currentDir).appendingPathComponent("Config.plist")
    if FileManager.default.fileExists(atPath: configPath),
       let plist = NSDictionary(contentsOfFile: configPath) as? [String: Any] {
      return plist
    }
    
    return nil
  }
}

extension GoogleCalendarConfig {
  /// Validates that the OAuth configuration is properly set up
  static func validateConfiguration() -> Bool {
    // Try to access clientId - this will trigger fatalError if misconfigured
    let _ = clientId
    let _ = redirectScheme
    return true
  }
  
  /// Returns configuration status for debugging
  static func configurationStatus() -> String {
    return """
    📊 OAUTH CONFIGURATION STATUS:
    • Client ID: \(clientId.isEmpty ? "❌ Missing" : "✅ Configured (\(clientId.prefix(20))...)")
    • Redirect Scheme: \(redirectScheme)
    • Environment: \(environment)
    • Configuration Source: \(configurationSource())
    • Scopes: \(scopes.count) configured
    """
  }
  
  private static func configurationSource() -> String {
    if ProcessInfo.processInfo.environment["GOOGLE_OAUTH_CLIENT_ID"] != nil {
      return "Environment Variable"
    } else if loadConfigFromProjectRoot() != nil {
      return "Config.plist (project root)"
    } else {
      return "Default/Fallback"
    }
  }
}
