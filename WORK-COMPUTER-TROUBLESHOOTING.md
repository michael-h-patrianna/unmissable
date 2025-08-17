# Unmissable - Work Computer Troubleshooting

## 🔧 OAuth Authentication Issues

If the "Connect to Google Calendar" button does nothing, follow these steps:

### Step 1: Check Console Logs (macOS)
1. Open **Console.app** (search in Spotlight)
2. In the left sidebar, click your computer name under "Devices"
3. In the search box, type: `com.unmissable.app`
4. Click "Connect to Google Calendar" in Unmissable
5. Look for log messages starting with 🚀, ❌, or ⚠️

### Step 2: Common Issues & Solutions

**Issue: "Failed to start authorization flow"**
- **Cause**: Corporate security blocking browser access
- **Solution**: Try opening your default browser manually first
- **Alternative**: Contact IT about OAuth redirect allowlists

**Issue: "No response received"**
- **Cause**: Browser blocking redirects back to the app
- **Solution**:
  1. Check if default browser is Safari, Chrome, or Firefox
  2. Ensure the browser isn't in "private/incognito" mode
  3. Try setting Safari as default temporarily

**Issue: "Authorization failed"**
- **Cause**: Corporate proxy or firewall blocking Google OAuth
- **Solution**: Connect to personal WiFi or mobile hotspot temporarily for setup

### Step 3: Manual Browser Test
1. Open your browser manually
2. Go to: `https://accounts.google.com/oauth/authorize?client_id=YOUR_OAUTH_CLIENT_ID&redirect_uri=com.unmissable.app%3A%2F%2Foauth-callback&response_type=code&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcalendar.readonly`
3. If this page loads, OAuth should work
4. If blocked, contact IT about Google OAuth access

### Step 4: Alternative Setup Methods

**Option A: Personal Computer Setup**
1. Install on personal computer first
2. Complete OAuth setup there
3. Copy the configured app to work computer
   - Note: This may not work due to Keychain differences

**Option B: IT Department**
- Ask IT to allowlist:
  - `accounts.google.com` (OAuth)
  - `googleapis.com` (Calendar API)
  - Custom URL scheme: `com.unmissable.app://`

### Step 5: Debug Information Collection
If still having issues, collect this info:

```bash
# Check default browser
defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers | grep -A2 -B2 https

# Check if URL scheme is registered
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -dump | grep -i unmissable

# Check system logs
log show --last 5m --predicate 'subsystem == "com.unmissable.app"'
```

## 🔒 Corporate Security Considerations

- Some companies block OAuth redirects to custom URL schemes
- Proxy servers may interfere with Google OAuth
- DLP (Data Loss Prevention) tools may block calendar access
- Browser security policies may prevent app communication

## 🆘 Still Not Working?

The enhanced debug version will show detailed logs in Console.app. Common patterns:

- ❌ "Authorization failed" = Browser/network issue
- ⚠️ "No active authorization flow" = Timing issue
- 🚀 "Starting OAuth" but no browser = Browser access blocked
- 📥 "Received URL" = OAuth callback working

Contact your IT department with these specific error messages for faster resolution.
