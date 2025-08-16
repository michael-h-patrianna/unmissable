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
  
  /// OAuth Client ID - loads from environment variable or Config.plist
  /// This prevents committing sensitive credentials to git
  static let clientId: String = {
    // Try environment variable first (for development/CI)
    if let envClientId = ProcessInfo.processInfo.environment["GOOGLE_OAUTH_CLIENT_ID"],
       !envClientId.isEmpty,
       !envClientId.contains("YOUR_GOOGLE_OAUTH_CLIENT_ID") {
      return envClientId
    }
    
    // Try loading from Config.plist (for local development)
    if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
       let plist = NSDictionary(contentsOfFile: path) as? [String: Any],
       let clientId = plist["GoogleOAuthClientID"] as? String,
       !clientId.isEmpty,
       !clientId.contains("YOUR_GOOGLE_OAUTH_CLIENT_ID") {
      return clientId
    }
    
    // Fallback error with helpful setup instructions
    fatalError("""
      ❌ OAUTH CLIENT ID NOT CONFIGURED
      
      📋 SETUP OPTIONS:
      
      Option 1 - Environment Variable (Recommended for development):
      export GOOGLE_OAUTH_CLIENT_ID="your-client-id-here"
      
      Option 2 - Config.plist file:
      1. Copy: Sources/Unmissable/Config/Config.plist.example
      2. To: Sources/Unmissable/Config/Config.plist
      3. Replace YOUR_GOOGLE_OAUTH_CLIENT_ID with your actual client ID
      4. Add Config.plist to your Xcode project resources
      
      🔗 GET CLIENT ID: https://console.developers.google.com/
      
      🔒 SECURITY: Config.plist is excluded from git via .gitignore
      Environment variables are secure for local development
      """)
  }()
  
  static let redirectScheme: String = {
    // Try environment variable first
    if let envScheme = ProcessInfo.processInfo.environment["GOOGLE_OAUTH_REDIRECT_SCHEME"],
       !envScheme.isEmpty {
      return envScheme
    }
    
    // Try Config.plist
    if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
       let plist = NSDictionary(contentsOfFile: path) as? [String: Any],
       let scheme = plist["RedirectScheme"] as? String,
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
    } else if Bundle.main.path(forResource: "Config", ofType: "plist") != nil {
      return "Config.plist"
    } else {
      return "Default/Fallback"
    }
  }
}
