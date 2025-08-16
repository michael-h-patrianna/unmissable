import AppAuth
import AppKit
import Foundation
import KeychainAccess
import OSLog

@MainActor
class OAuth2Service: ObservableObject {
  private let logger = Logger(subsystem: "com.unmissable.app", category: "OAuth2Service")
  private let keychain = Keychain(service: "com.unmissable.app.oauth")

  @Published var isAuthenticated = false
  @Published var userEmail: String?
  @Published var authorizationError: String?

  private var authState: OIDAuthState?
  private let keychainAccessTokenKey = "google_access_token"
  private let keychainRefreshTokenKey = "google_refresh_token"
  private let keychainUserEmailKey = "google_user_email"

  init() {
    loadAuthStateFromKeychain()

    // Listen for OAuth callback notifications
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleOAuthCallback(_:)),
      name: Notification.Name("OAuthCallback"),
      object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  @objc private func handleOAuthCallback(_ notification: Notification) {
    guard let url = notification.object as? URL else { return }

    logger.info("Handling OAuth callback URL: \(url)")

    // Handle the callback URL with AppAuth
    if let currentAuthFlow = self.currentAuthorizationFlow {
      if currentAuthFlow.resumeExternalUserAgentFlow(with: url) {
        self.currentAuthorizationFlow = nil
      }
    }
  }

  private var currentAuthorizationFlow: OIDExternalUserAgentSession?

  // MARK: - Public Interface

  func startAuthorizationFlow() async throws {
    logger.info("Starting OAuth 2.0 authorization flow")

    guard GoogleCalendarConfig.validateConfiguration() else {
      let error =
        "OAuth configuration not properly set up. Please configure your Google OAuth client ID."
      logger.error("\(error)")
      authorizationError = error
      throw OAuth2Error.configurationError(error)
    }

    // Clear any existing error
    authorizationError = nil

    // Create service configuration
    let configuration = OIDServiceConfiguration(
      authorizationEndpoint: GoogleCalendarConfig.authorizationEndpoint,
      tokenEndpoint: GoogleCalendarConfig.tokenEndpoint,
      issuer: GoogleCalendarConfig.issuer
    )

    // Create authorization request
    let request = OIDAuthorizationRequest(
      configuration: configuration,
      clientId: GoogleCalendarConfig.clientId,
      scopes: GoogleCalendarConfig.scopes,
      redirectURL: URL(string: GoogleCalendarConfig.redirectURI)!,
      responseType: OIDResponseTypeCode,
      additionalParameters: nil
    )

    // Perform authorization request
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      // Use external user agent (browser) for authorization
      // Create a minimal window as fallback if no key window exists
      let fallbackWindow = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
        styleMask: .borderless,
        backing: .buffered,
        defer: false
      )
      let presentingWindow = NSApplication.shared.keyWindow ?? fallbackWindow
      let userAgent = OIDExternalUserAgentMac(presenting: presentingWindow)

      self.currentAuthorizationFlow = OIDAuthorizationService.present(
        request,
        externalUserAgent: userAgent
      ) { [weak self] authorizationResponse, error in
        Task { @MainActor in
          self?.currentAuthorizationFlow = nil

          if let error = error {
            self?.logger.error("Authorization failed: \(error.localizedDescription)")
            self?.authorizationError = error.localizedDescription
            continuation.resume(throwing: OAuth2Error.authorizationFailed(error))
          } else if let authResponse = authorizationResponse {
            self?.logger.info("Authorization successful, exchanging code for tokens")

            // Exchange authorization code for tokens
            OIDAuthorizationService.perform(
              authResponse.tokenExchangeRequest()!
            ) { tokenResponse, tokenError in
              Task { @MainActor in
                if let tokenError = tokenError {
                  self?.logger.error("Token exchange failed: \(tokenError.localizedDescription)")
                  self?.authorizationError = tokenError.localizedDescription
                  continuation.resume(throwing: OAuth2Error.authorizationFailed(tokenError))
                } else if let tokenResponse = tokenResponse {
                  // Create auth state with both responses
                  self?.authState = OIDAuthState(
                    authorizationResponse: authResponse, tokenResponse: tokenResponse)
                  self?.saveAuthStateToKeychain()
                  await self?.fetchUserEmail()
                  self?.isAuthenticated = true
                  continuation.resume()
                } else {
                  let error = OAuth2Error.authorizationFailed(
                    NSError(
                      domain: "OAuth2Service", code: -1,
                      userInfo: [NSLocalizedDescriptionKey: "No token response received"]))
                  continuation.resume(throwing: error)
                }
              }
            }
          } else {
            let error = OAuth2Error.authorizationFailed(
              NSError(
                domain: "OAuth2Service", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unknown authorization error"]))
            continuation.resume(throwing: error)
          }
        }
      }
    }
  }

  func getValidAccessToken() async throws -> String {
    guard let authState = authState else {
      throw OAuth2Error.notAuthenticated
    }

    return try await withCheckedThrowingContinuation {
      (continuation: CheckedContinuation<String, Error>) in
      authState.performAction { accessToken, idToken, error in
        if let error = error {
          continuation.resume(throwing: OAuth2Error.tokenRefreshFailed(error))
        } else if let accessToken = accessToken {
          continuation.resume(returning: accessToken)
        } else {
          continuation.resume(
            throwing: OAuth2Error.tokenRefreshFailed(
              NSError(
                domain: "OAuth2Service", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No access token available"])))
        }
      }
    }
  }

  func signOut() {
    logger.info("Signing out user")

    authState = nil
    isAuthenticated = false
    userEmail = nil
    authorizationError = nil

    clearKeychain()
  }

  // MARK: - Private Methods

  private func loadAuthStateFromKeychain() {
    do {
      if let accessToken = try keychain.get(keychainAccessTokenKey),
        let refreshToken = try keychain.get(keychainRefreshTokenKey)
      {

        // Reconstruct auth state from stored tokens
        // Note: This is a simplified approach. In production, you'd want to store the complete auth state
        logger.info("Loading auth state from keychain")
        userEmail = try keychain.get(keychainUserEmailKey)

        // For now, just check if we have tokens - proper token validation would be done in production
        isAuthenticated = !accessToken.isEmpty && !refreshToken.isEmpty

        if isAuthenticated {
          logger.info("User already authenticated")
        }
      }
    } catch {
      logger.error("Failed to load auth state from keychain: \(error.localizedDescription)")
    }
  }

  private func saveAuthStateToKeychain() {
    guard let authState = authState,
      let accessToken = authState.lastTokenResponse?.accessToken,
      let refreshToken = authState.lastTokenResponse?.refreshToken
    else {
      logger.error("Cannot save auth state - missing tokens")
      return
    }

    do {
      try keychain.set(accessToken, key: keychainAccessTokenKey)
      try keychain.set(refreshToken, key: keychainRefreshTokenKey)

      if let userEmail = userEmail {
        try keychain.set(userEmail, key: keychainUserEmailKey)
      }

      logger.info("Auth state saved to keychain")
    } catch {
      logger.error("Failed to save auth state to keychain: \(error.localizedDescription)")
    }
  }

  private func clearKeychain() {
    do {
      try keychain.remove(keychainAccessTokenKey)
      try keychain.remove(keychainRefreshTokenKey)
      try keychain.remove(keychainUserEmailKey)
      logger.info("Keychain cleared")
    } catch {
      logger.error("Failed to clear keychain: \(error.localizedDescription)")
    }
  }

  private func fetchUserEmail() async {
    do {
      let accessToken = try await getValidAccessToken()
      let email = try await fetchUserInfoFromGoogle(accessToken: accessToken)
      userEmail = email
      logger.info("User email fetched: \(email)")
    } catch {
      logger.error("Failed to fetch user email: \(error.localizedDescription)")
    }
  }

  private func fetchUserInfoFromGoogle(accessToken: String) async throws -> String {
    let url = URL(string: "https://www.googleapis.com/oauth2/v2/userinfo")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
      httpResponse.statusCode == 200
    else {
      throw OAuth2Error.userInfoFetchFailed
    }

    let userInfo = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    guard let email = userInfo?["email"] as? String else {
      throw OAuth2Error.userInfoFetchFailed
    }

    return email
  }
}

enum OAuth2Error: LocalizedError {
  case configurationError(String)
  case authorizationFailed(Error)
  case tokenRefreshFailed(Error)
  case notAuthenticated
  case userInfoFetchFailed

  var errorDescription: String? {
    switch self {
    case .configurationError(let message):
      return "Configuration Error: \(message)"
    case .authorizationFailed(let error):
      return "Authorization Failed: \(error.localizedDescription)"
    case .tokenRefreshFailed(let error):
      return "Token Refresh Failed: \(error.localizedDescription)"
    case .notAuthenticated:
      return "User not authenticated"
    case .userInfoFetchFailed:
      return "Failed to fetch user information"
    }
  }
}
