#!/bin/bash

# Format code with SwiftFormat

echo "✨  Formatting code with SwiftFormat..."

if command -v swiftformat >/dev/null 2>&1; then
    swiftformat .
    echo "✅  Code formatting completed!"
else
    echo "❌  SwiftFormat not installed. Run: brew install swiftformat"
    exit 1
fi
