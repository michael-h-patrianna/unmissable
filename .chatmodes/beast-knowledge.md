# Beast Knowledge

## Assumptions
- User wants macOS .app bundle for personal use
- Configuration should persist between app restarts
- App should support login item functionality
- Public GitHub repo but private use case

## Decisions
- Will use Swift Package Manager with executable target
- Configuration will be stored in user's Application Support directory
- Will create proper .app bundle structure for macOS
- Will include Info.plist for proper app registration

## Context Notes
- This is a Swift-based calendar overlay application
- Currently runs as CLI tool
- Needs to become GUI app with system integration

## Sources/Links
- macOS App Bundle Programming Guide
- Swift Package Manager documentation
- Login Items configuration
