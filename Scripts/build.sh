#!/bin/bash

# Build and test script for Unmissable

set -e

echo "🏗️  Building Unmissable..."
swift build

echo ""
echo "🧹  Running SwiftLint..."
if command -v swiftlint >/dev/null 2>&1; then
    swiftlint lint
else
    echo "⚠️  SwiftLint not installed. Run: brew install swiftlint"
fi

echo ""
echo "✨  Checking SwiftFormat..."
if command -v swiftformat >/dev/null 2>&1; then
    swiftformat --lint .
else
    echo "⚠️  SwiftFormat not installed. Run: brew install swiftformat"
fi

echo ""
echo "🧪  Running tests..."
swift test

echo ""
echo "✅  All checks passed!"
