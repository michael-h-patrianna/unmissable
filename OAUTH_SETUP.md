# OAuth Setup Guide

## Google Calendar OAuth Configuration

To enable Google Calendar integration, you need to set up OAuth 2.0 credentials with Google Cloud Console.

### Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google Calendar API:
   - Go to "APIs & Services" > "Library"
   - Search for "Google Calendar API"
   - Click "Enable"

### Step 2: Configure OAuth Consent Screen

1. Go to "APIs & Services" > "OAuth consent screen"
2. Choose "External" user type (unless you have Google Workspace)
3. Fill in required information:
   - App name: "Unmissable"
   - User support email: Your email
   - Developer contact information: Your email
4. Add scopes:
   - `https://www.googleapis.com/auth/calendar.readonly`
   - `https://www.googleapis.com/auth/userinfo.email`
5. Save and continue

### Step 3: Create OAuth Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth 2.0 Client IDs"
3. Application type: "macOS"
4. Name: "Unmissable macOS App"
5. Bundle ID: `com.unmissable.app`
6. Download the client configuration

### Step 4: Configure the App

1. Open `Sources/Unmissable/Config/GoogleCalendarConfig.swift`
2. Replace `YOUR_CLIENT_ID` with your actual client ID from Google Cloud Console
3. The client ID should look like: `123456789-abcdefghijklmnop.apps.googleusercontent.com`

Example:
```swift
static let clientId = "123456789-abcdefghijklmnop.apps.googleusercontent.com"
```

### Step 5: Add URL Scheme to App

1. In Xcode, go to your app target settings
2. Go to the "Info" tab
3. Add a new URL Scheme:
   - Identifier: `com.unmissable.app`
   - URL Schemes: `com.unmissable.app`

### Step 6: Test the Integration

1. Build and run the app
2. Go to Preferences > Calendar
3. Click "Connect Google Calendar"
4. Complete the OAuth flow in your browser
5. Verify the connection shows your email and calendar list

## Security Notes

- Never commit your actual client ID to version control if your repository is public
- For production builds, store sensitive configuration securely
- The OAuth tokens are securely stored in the macOS Keychain
- Tokens are automatically refreshed when needed

## Troubleshooting

### "OAuth configuration not properly set up" Error
- Verify you've replaced `YOUR_CLIENT_ID` with your actual client ID
- Make sure the client ID is correctly formatted

### Browser doesn't redirect back to app
- Check that the URL scheme is properly configured in Xcode
- Verify the redirect URI matches in Google Cloud Console

### "Access denied" or scope errors
- Ensure you've added the required scopes in Google Cloud Console
- Verify the OAuth consent screen is properly configured

### Calendar API quota exceeded
- Google Calendar API has usage limits
- For production use, you may need to request quota increases
