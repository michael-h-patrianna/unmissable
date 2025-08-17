#!/bin/bash

# Installation helper for Unmissable app
# Copies the app to Applications folder and provides login item instructions

set -e

APP_NAME="Unmissable"
APP_BUNDLE="${APP_NAME}.app"

echo "🚀  Installing ${APP_NAME}..."

# Check if app bundle exists
if [ ! -d "${APP_BUNDLE}" ]; then
    echo "❌  ${APP_BUNDLE} not found!"
    echo "    Run './Scripts/build-release.sh' first to create the app bundle."
    exit 1
fi

# Check if Applications directory is writable
if [ ! -w "/Applications" ]; then
    echo "⚠️  /Applications directory requires admin permissions"
    echo "📋  Manual installation:"
    echo "    1. Copy ${APP_BUNDLE} to /Applications/"
    echo "    2. You may need to enter your password"
    sudo cp -R "${APP_BUNDLE}" "/Applications/"
else
    echo "📦  Copying ${APP_BUNDLE} to /Applications/..."
    cp -R "${APP_BUNDLE}" "/Applications/"
fi

# Verify installation
if [ -d "/Applications/${APP_BUNDLE}" ]; then
    echo "✅  ${APP_NAME} installed successfully!"
    echo ""
    echo "🔧  Setup Instructions:"
    echo "    1. Launch ${APP_NAME} from Applications folder"
    echo "    2. Grant necessary permissions when prompted"
    echo "    3. Configure Google Calendar connection"
    echo ""
    echo "🔄  Auto-launch Setup:"
    echo "    1. Open System Settings"
    echo "    2. Go to General > Login Items"
    echo "    3. Click the '+' button"
    echo "    4. Select ${APP_NAME} from Applications"
    echo "    5. Enable 'Hide' to launch minimized"
    echo ""
    echo "💡  Alternative method:"
    echo "    • Right-click ${APP_NAME} in Applications"
    echo "    • Select 'Options' > 'Open at Login'"
    echo ""
    echo "🎉  Installation complete!"
else
    echo "❌  Installation failed"
    exit 1
fi
