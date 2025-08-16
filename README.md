# Unmissable

A macOS app that ensures you never miss important meetings by showing an unmissable full-screen overlay with countdown timer and one-click join functionality.

## Features

- 🚨 **Unmissable Alerts**: Full-screen blocking overlay that requires deliberate dismissal
- 📅 **Google Calendar Integration**: Secure OAuth 2.0 connection with automatic sync
- 🔗 **Smart Meeting Detection**: Automatically detects Meet, Zoom, Teams, and Webex links
- ⏰ **Configurable Timing**: Customizable alert timing based on meeting length
- 🎨 **Appearance Customization**: Light/dark themes, opacity, font size options
- 💤 **Snooze Functionality**: 1, 5, or 10-minute snooze options
- 🖥️ **Multi-Display Support**: Shows alerts on all displays or primary only
- ⌨️ **Global Shortcuts**: Join or dismiss meetings with keyboard shortcuts
- 🔇 **Focus Mode Integration**: Override Do Not Disturb for important meetings
- 📱 **Menu Bar Interface**: Lightweight menu bar app with quick access

## Requirements

- macOS 14.0 (Sonoma) or later
- Swift 5.10+

## Setup

### 🔒 OAuth Configuration (Required)

This app requires Google Calendar API access. Choose one of these secure configuration methods:

#### Option 1: Environment Variable (Recommended)

1. **Get Google OAuth credentials:**
   - Visit [Google Cloud Console](https://console.developers.google.com/)
   - Create a new project or select existing project  
   - Enable the Google Calendar API
   - Create OAuth 2.0 credentials (Desktop application)
   - Copy the Client ID

2. **Set environment variable:**

   ```bash
   export GOOGLE_OAUTH_CLIENT_ID="your-client-id-here"
   ```

3. **Build and run:**

   ```bash
   swift build && swift run
   ```

#### Option 2: Config.plist File

1. **Copy the configuration template:**

   ```bash
   cp Sources/Unmissable/Config/Config.plist.example Sources/Unmissable/Config/Config.plist
   ```

2. **Configure your credentials:**
   - Open `Sources/Unmissable/Config/Config.plist`
   - Replace `YOUR_GOOGLE_OAUTH_CLIENT_ID_HERE` with your actual client ID
   - Save the file

3. **Add to Xcode project resources** (if using Xcode)

**⚠️ Security Note:** Never commit OAuth credentials to version control. Both `Config.plist` and environment variables are secure for local development.
- Xcode 15+

## Development Setup

### Prerequisites

1. Install Xcode 15+ from the Mac App Store
2. Install Homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
3. Install development tools:
   ```bash
   brew install swiftlint swiftformat
   ```

### VS Code Setup (Recommended)

1. Install required extensions:
   - Swift (swift-server-work-group.swift)
   - CodeLLDB (vadimcn.vscode-lldb)

2. Verify toolchain:
   ```bash
   xcodebuild -version
   swift --version
   xcode-select -p
   ```

### Building

```bash
# Build the project
swift build

# Run tests
swift test

# Run all checks (build, lint, format, test)
./Scripts/build.sh

# Format code
./Scripts/format.sh
```

### Running in Development

```bash
# Build and run
swift run
```

## Architecture

The app follows a modular architecture with clear separation of concerns:

```
Sources/Unmissable/
├── App/                    # Main app entry point and UI
├── Features/
│   ├── CalendarConnect/    # Google Calendar OAuth & API
│   ├── EventSync/          # Event polling and caching
│   ├── Overlay/            # Full-screen overlay system
│   ├── Join/               # Meeting link handling
│   ├── Preferences/        # Settings and configuration
│   ├── Snooze/            # Snooze functionality
│   ├── FocusMode/         # Do Not Disturb integration
│   └── Shortcuts/         # Global keyboard shortcuts
├── Core/                  # Shared business logic
├── Models/                # Data models
├── Resources/             # Assets and resources
└── Config/               # Configuration files
```

## Key Components

- **CalendarService**: Handles Google Calendar OAuth and event fetching
- **OverlayManager**: Creates and manages full-screen overlay windows
- **EventScheduler**: Schedules and triggers meeting alerts
- **PreferencesManager**: Manages user settings and preferences
- **AppState**: Central state management for the app

## Testing

The project includes comprehensive testing:

- **Unit Tests**: Core business logic and data models
- **Snapshot Tests**: UI component visual regression testing
- **Integration Tests**: Service integration with mocked dependencies

Run tests with:
```bash
swift test
```

For UI tests and full integration testing, use Xcode:
```bash
xcodebuild -scheme Unmissable -destination 'platform=macOS' test
```

## Dependencies

- [AppAuth-iOS](https://github.com/openid/AppAuth-iOS): OAuth 2.0 and OpenID Connect
- [GRDB.swift](https://github.com/groue/GRDB.swift): SQLite database toolkit
- [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess): Keychain wrapper
- [Magnet](https://github.com/Clipy/Magnet): Global keyboard shortcuts
- [SnapshotTesting](https://github.com/pointfreeco/swift-snapshot-testing): Snapshot testing

## Privacy & Security

- All calendar data is cached locally using SQLite
- OAuth tokens are stored securely in macOS Keychain
- No telemetry or analytics - all data stays on your device
- HTTPS-only communication with Google Calendar API
- Code signed and notarized for distribution

## Permissions

The app requires the following permissions:

- **Calendar Access**: To connect to Google Calendar (via OAuth)
- **Accessibility**: For global keyboard shortcuts
- **Notifications**: For sound alerts (optional)

## License

Copyright (c) 2025 Unmissable. All rights reserved.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Run `./Scripts/build.sh` to verify all checks pass
5. Submit a pull request

## Support

For issues and feature requests, please create an issue on GitHub.
