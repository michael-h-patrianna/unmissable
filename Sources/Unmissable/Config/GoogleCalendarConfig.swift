import Foundation

struct GoogleCalendarConfig {
  // OAuth 2.0 configuration for Google Calendar API
  static let authorizationEndpoint = URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!
  static let tokenEndpoint = URL(string: "https://oauth2.googleapis.com/token")!
  static let issuer = URL(string: "https://accounts.google.com")!

  // Google Calendar API scopes
  static let scopes = [
    "https://www.googleapis.com/auth/calendar.readonly",
    "https://www.googleapis.com/auth/userinfo.email",
  ]

  // OAuth Client Configuration
  // Note: In production, these would be loaded from a secure configuration
  // For development, these are placeholder values that need to be replaced
  static let clientId = "833157900285-2l03i5lgpp7u5ci6912o17ut0o8ubupl.apps.googleusercontent.com"
  static let redirectScheme = "com.unmissable.app"
  static let redirectURI = "\(redirectScheme)://oauth/callback"

  // API Base URLs
  static let calendarAPIBaseURL = "https://www.googleapis.com/calendar/v3"
}

extension GoogleCalendarConfig {
  /// Validates that the OAuth configuration is properly set up
  static func validateConfiguration() -> Bool {
    return !clientId.contains("YOUR_CLIENT_ID") && !clientId.isEmpty && !redirectScheme.isEmpty
  }
}
