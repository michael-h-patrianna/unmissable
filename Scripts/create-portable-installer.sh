#!/bin/bash

# Portable Installer Creator for Unmissable
# Creates a self-contained package that can be sent via email

set -e

PACKAGE_NAME="Unmissable-Installer"
PACKAGE_DIR="${PACKAGE_NAME}"
TEMP_CONFIG="Config.plist.work"

echo "📦  Creating portable installer package..."

# Clean up any existing package
rm -rf "${PACKAGE_DIR}"
rm -f "${PACKAGE_NAME}.zip"

# Step 1: Build the latest version
echo "🏗️  Building latest release..."
./Scripts/build-release.sh

# Step 2: Create package directory structure
echo "📁  Creating package structure..."
mkdir -p "${PACKAGE_DIR}"

# Step 3: Copy the built app
echo "📋  Copying app bundle..."
cp -R "Unmissable.app" "${PACKAGE_DIR}/"

# Step 4: Create work-safe config template
echo "⚙️  Creating work config template..."
cat > "${PACKAGE_DIR}/Config.plist.template" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>GoogleCalendar</key>
    <dict>
        <key>ClientID</key>
        <string>YOUR_GOOGLE_CLIENT_ID_HERE</string>
        <key>RedirectURI</key>
        <string>com.unmissable.app://oauth-callback</string>
    </dict>
</dict>
</plist>
EOF

# Step 5: Create simple installer script for work laptop
echo "🔧  Creating work installer script..."
cat > "${PACKAGE_DIR}/install-on-work-laptop.sh" << 'EOF'
#!/bin/bash

# Unmissable Work Laptop Installer
# Simple installer that requires no development tools

set -e

echo "🚀  Installing Unmissable on work laptop..."
echo "=========================================="

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌  This installer is for macOS only"
    exit 1
fi

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
MACOS_MAJOR=$(echo $MACOS_VERSION | cut -d. -f1)
if [[ $MACOS_MAJOR -lt 14 ]]; then
    echo "❌  macOS 14.0 (Sonoma) or later required. You have: $MACOS_VERSION"
    exit 1
fi

echo "✅  macOS version: $MACOS_VERSION"

# Step 1: Check if app bundle exists
if [[ ! -d "Unmissable.app" ]]; then
    echo "❌  Unmissable.app not found in current directory"
    echo "    Make sure you're running this from the installer folder"
    exit 1
fi

# Step 2: Setup OAuth configuration
echo ""
echo "🔑  OAuth Configuration Setup"
echo "=============================="

if [[ ! -f "Config.plist" ]]; then
    echo "⚠️  OAuth configuration needed for Google Calendar access"
    echo ""
    echo "Options:"
    echo "  1. Use without Google Calendar (local calendar only)"
    echo "  2. Set up Google Calendar OAuth (requires Google Cloud project)"
    echo ""
    read -p "Choose option (1 or 2): " oauth_choice

    if [[ "$oauth_choice" == "2" ]]; then
        echo ""
        echo "📋  To set up Google Calendar access:"
        echo "    1. Copy Config.plist.template to Config.plist"
        echo "    2. Edit Config.plist with your Google OAuth credentials"
        echo "    3. Run this installer again"
        echo ""
        echo "For now, installing without Google Calendar..."
        sleep 2
    fi
else
    echo "✅  OAuth configuration found"
    # Copy config to app bundle
    cp "Config.plist" "Unmissable.app/Contents/Resources/"
fi

# Step 3: Install to Applications
echo ""
echo "📦  Installing to Applications..."

if [[ -d "/Applications/Unmissable.app" ]]; then
    echo "⚠️  Unmissable already exists in Applications"
    read -p "Replace existing installation? (y/N): " replace_choice
    if [[ "$replace_choice" != "y" && "$replace_choice" != "Y" ]]; then
        echo "Installation cancelled"
        exit 0
    fi
    rm -rf "/Applications/Unmissable.app"
fi

# Copy with appropriate permissions
if [[ -w "/Applications" ]]; then
    cp -R "Unmissable.app" "/Applications/"
else
    echo "🔐  Administrator permission needed for /Applications/"
    sudo cp -R "Unmissable.app" "/Applications/"
    sudo chown -R root:admin "/Applications/Unmissable.app"
fi

# Step 4: First launch setup
echo ""
echo "🚀  First Launch Setup"
echo "======================"

echo "✅  Unmissable installed successfully!"
echo ""
echo "📋  Next steps:"
echo "    1. Launch Unmissable from Applications folder"
echo "    2. Right-click and 'Open' (first time only - security)"
echo "    3. Grant permissions when prompted"
echo "    4. The app will appear in your menu bar"
echo ""

# Step 5: Login item setup
echo "🔄  Auto-launch Setup (Optional)"
echo "================================="
echo ""
echo "To start Unmissable automatically on login:"
echo "    1. Open System Settings"
echo "    2. Go to General > Login Items"
echo "    3. Click '+' and select Unmissable"
echo "    4. Enable 'Hide' to start minimized"
echo ""

# Step 6: Launch the app
read -p "Launch Unmissable now? (Y/n): " launch_choice
if [[ "$launch_choice" != "n" && "$launch_choice" != "N" ]]; then
    echo "🚀  Launching Unmissable..."
    open "/Applications/Unmissable.app"
    echo "✅  Check your menu bar - Unmissable should appear there!"
fi

echo ""
echo "🎉  Installation complete!"
echo ""
echo "💡  Tips:"
echo "    • Menu bar icon provides access to all features"
echo "    • Set up Google Calendar in preferences for meeting alerts"
echo "    • Configure alert timing and appearance to your liking"
EOF

# Step 6: Create README for work laptop
echo "📖  Creating work laptop README..."
cat > "${PACKAGE_DIR}/README-WORK-LAPTOP.md" << 'EOF'
# Unmissable - Work Laptop Installation

This package contains everything needed to install Unmissable on your work laptop.

## What's Included

- `Unmissable.app` - Pre-built application bundle
- `install-on-work-laptop.sh` - Simple installer script
- `Config.plist.template` - OAuth configuration template
- This README file

## Requirements

- macOS 14.0 (Sonoma) or later
- No development tools required
- No Apple Developer account needed

## Installation

1. **Extract this package** to any folder on your work laptop
2. **Open Terminal** and navigate to the extracted folder
3. **Run the installer:**
   ```bash
   chmod +x install-on-work-laptop.sh
   ./install-on-work-laptop.sh
   ```
4. **Follow the prompts** for OAuth setup and installation

## Google Calendar Setup (Optional)

If you want Google Calendar integration:

1. Copy `Config.plist.template` to `Config.plist`
2. Edit `Config.plist` with your Google OAuth credentials
3. Run the installer again

Without Google Calendar, the app works with local calendar events only.

## Security Notes

- App is self-signed (no Apple Developer certificate)
- First launch: Right-click app and select "Open"
- Gatekeeper will ask for permission - this is normal
- All data stored locally, no external transmission

## Auto-Launch Setup

After installation, to start automatically on login:

1. System Settings > General > Login Items
2. Add Unmissable from Applications
3. Enable "Hide" to start minimized

## Features

- ✅ Menu bar calendar overview
- ✅ Full-screen meeting reminders
- ✅ Meeting link detection (Google Meet, Zoom, Teams, etc.)
- ✅ Snooze functionality
- ✅ Customizable alert timing
- ✅ Light/Dark theme support
- ✅ Persistent configuration

## Troubleshooting

**App won't launch:**
- Right-click and "Open" (first time only)
- Check Console.app for error messages

**No calendar events:**
- Set up Google Calendar OAuth, or
- Check local calendar permissions

**Missing from menu bar:**
- App may be hidden - check Activity Monitor
- Try launching from Applications again

---

**Installation takes about 2 minutes. No restart required.**
EOF

# Step 7: Make installer executable
chmod +x "${PACKAGE_DIR}/install-on-work-laptop.sh"

# Step 8: Create compressed package
echo "🗜️  Creating compressed package..."
zip -r "${PACKAGE_NAME}.zip" "${PACKAGE_DIR}"

# Step 9: Show package info
echo ""
echo "✅  Portable installer created!"
echo ""
echo "📦  Package: ${PACKAGE_NAME}.zip"
echo "📏  Size: $(du -sh "${PACKAGE_NAME}.zip" | cut -f1)"
echo "📁  Contents:"
ls -la "${PACKAGE_DIR}"
echo ""
echo "📧  Email Instructions:"
echo "======================================"
echo "1. Attach ${PACKAGE_NAME}.zip to email"
echo "2. Send to your work email"
echo "3. On work laptop: Download and extract"
echo "4. Run: ./install-on-work-laptop.sh"
echo ""
echo "🔒  Security: Self-signed app, no Apple Developer account needed"
echo "⏱️  Install time: ~2 minutes on work laptop"
echo ""
echo "🎉  Ready to send!"

# Clean up
rm -rf "${PACKAGE_DIR}"
