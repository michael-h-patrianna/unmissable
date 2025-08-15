# OAuth Setup Guide for Unmissable

## 🔧 Issue: "Connect Google Calendar" Button Not Working

**Problem**: The OAuth configuration is using placeholder values, preventing the Google Calendar connection from working.

**Solution**: You need to set up Google OAuth credentials.

## 📋 Step-by-Step OAuth Setup

### 1. Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Name it something like "Unmissable Calendar App"

### 2. Enable Google Calendar API

1. Go to **APIs & Services** > **Library**
2. Search for "Google Calendar API"
3. Click on it and press **Enable**

### 3. Create OAuth 2.0 Credentials

1. Go to **APIs & Services** > **Credentials**
2. Click **+ CREATE CREDENTIALS** > **OAuth client ID**
3. If prompted, configure the OAuth consent screen first:
   - Choose **External** (unless you have a Google Workspace)
   - Fill in required fields:
     - App name: "Unmissable"
     - User support email: your email
     - Developer contact: your email
   - Save and continue through the scopes and test users steps

4. For the OAuth client ID:
   - Application type: **Desktop application**
   - Name: "Unmissable Desktop Client"
   - Click **Create**

### 4. Configure the App

1. Copy the **Client ID** from the credentials page
2. Open `Sources/Unmissable/Config/GoogleCalendarConfig.swift`
3. Replace this line:
   ```swift
   static let clientId = "YOUR_CLIENT_ID.apps.googleusercontent.com"
   ```

   With your actual client ID:
   ```swift
   static let clientId = "your-actual-client-id.apps.googleusercontent.com"
   ```

### 5. Test the Connection

1. Build and run the app:
   ```bash
   cd /path/to/unmissable
   xcodebuild -scheme Unmissable -destination 'platform=macOS' build
   open ~/Library/Developer/Xcode/DerivedData/unmissable-*/Build/Products/Debug/Unmissable
   ```

2. Click the menu bar icon
3. Click "Connect Google Calendar"
4. Your browser should open with Google's OAuth flow
5. Sign in and grant permissions
6. The app should now show "Ready" status

## 🔍 Troubleshooting

### Browser Doesn't Open
- Check that the client ID is correct
- Verify the redirect URI is set to `com.unmissable.app://oauth/callback`
- Check Console.app for OAuth error messages

### "Redirect URI Mismatch" Error
1. In Google Cloud Console, go to your OAuth client
2. Add these redirect URIs:
   - `com.unmissable.app://oauth/callback`
   - `urn:ietf:wg:oauth:2.0:oob`

### Permission Denied
- Make sure the Calendar API is enabled
- Check that the OAuth consent screen is properly configured
- Verify you're using the correct Google account

## 🚀 Alternative: Development Mode

For quick testing, you can also create a temporary configuration:

1. Create a simple test by modifying the validation:
   ```swift
   // In GoogleCalendarConfig.swift - TEMPORARY FOR TESTING
   static func validateConfiguration() -> Bool {
     return true // Skip validation for testing
   }
   ```

2. This will bypass the OAuth setup but won't actually connect to Google Calendar

## 📝 Production Considerations

- Store the client ID securely (not in source code)
- Use environment variables or a secure configuration file
- Consider using a backend service for OAuth token management
- Implement proper error handling for various OAuth scenarios

Once the OAuth is properly configured, both the "Connect Google Calendar" and "Preferences" buttons should work correctly! 🎉
