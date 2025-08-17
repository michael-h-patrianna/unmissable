# Beast PRD

## Problem & Users (JTBD)
**Problem:** User has a Swift calendar overlay app that currently runs as a CLI tool but wants to deploy it as a proper macOS application that can be installed in Applications folder and auto-launch on login.

**User:** Single user (developer) for personal use, no Apple Developer account available.

**Jobs to be Done:**
- Install app in Applications folder like any other macOS app
- Configure app to start automatically on login
- Persist configuration settings between app sessions
- Run as a proper GUI application instead of CLI tool

## Goals & Success Criteria
**Goals:**
- Create distributable .app bundle
- Enable auto-launch functionality
- Implement configuration persistence
- Maintain all existing functionality

**Success Criteria:**
- App can be moved to /Applications folder
- App appears in Login Items and can be enabled
- Configuration survives app restarts and system reboots
- App runs without terminal dependency

## Scope

**In Scope:**
- Create .app bundle structure
- Implement configuration persistence using Application Support directory
- Add Info.plist for proper macOS app registration
- Enable login item capability
- Self-signed distribution (no developer account required)

**Out of Scope:**
- App Store distribution
- Code signing with Apple Developer certificate
- Notarization
- Automatic updates

## Requirements

**Functional Requirements:**
- App bundle contains all necessary executables and resources
- Configuration persists in ~/Library/Application Support/Unmissable/
- App can be added to Login Items in System Preferences
- All existing calendar overlay functionality preserved

**Non-Functional Requirements:**
- Performance: No degradation from CLI version
- Accessibility: Standard macOS app behavior
- Localization: English only (current state)
- Compatibility: macOS 12.0+ (based on Swift requirements)

## Acceptance Criteria
1. App builds as .app bundle that can be copied to Applications folder
2. App launches without terminal and shows in Dock
3. Configuration files persist between sessions in proper location
4. App can be enabled in Login Items and auto-launches on reboot
5. All existing functionality (calendar overlay, meeting detection) works unchanged
