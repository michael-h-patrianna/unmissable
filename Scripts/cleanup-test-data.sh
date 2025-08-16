#!/bin/bash

# Test Cleanup Script - Removes debug calendars and test data
# This script should be run after tests to ensure no debug data remains

echo "🧹 Starting test cleanup..."

# Remove application data directory
if [ -d ~/Library/Application\ Support/Unmissable/ ]; then
    echo "🗑️  Removing application data directory..."
    rm -rf ~/Library/Application\ Support/Unmissable/
    echo "✅ Application data cleaned"
else
    echo "✅ No application data found"
fi

# Remove preference files
if [ -f ~/Library/Preferences/Unmissable.plist ]; then
    echo "🗑️  Removing preference files..."
    rm ~/Library/Preferences/Unmissable.plist
    echo "✅ Preferences cleaned"
else
    echo "✅ No preference files found"
fi

# Remove any temporary test files
echo "🗑️  Cleaning temporary test files..."
find . -name "*.tmp" -delete 2>/dev/null || true
find . -name "*test*.db" -delete 2>/dev/null || true
find . -name "*debug*.log" -delete 2>/dev/null || true

# Clean up build artifacts that might contain test data
echo "🗑️  Cleaning build artifacts..."
if [ -d .build ]; then
    # Only remove specific test-related build artifacts, not all build files
    find .build -name "*test*" -type f -delete 2>/dev/null || true
    find .build -name "*debug*" -type f -delete 2>/dev/null || true
fi

echo "✅ Test cleanup completed successfully!"
echo ""
echo "📋 Summary:"
echo "   - Removed application data directory"
echo "   - Removed preference files"
echo "   - Cleaned temporary test files"
echo "   - Cleaned debug build artifacts"
echo ""
echo "🎯 Production app is now clean of all test/debug data"
