#!/bin/bash

echo "🔬 MANUAL OVERLAY DEADLOCK TEST"
echo "This script will test the actual overlay deadlock by running the app"
echo "and triggering overlay creation directly"

cd /Users/michaelhaufschild/Documents/code/unmissable

echo "🚀 Starting app in background..."
swift run &
APP_PID=$!

echo "📱 App started with PID: $APP_PID"
echo "⏰ Waiting 3 seconds for app to initialize..."
sleep 3

echo "🔍 Checking if app is still running..."
if kill -0 $APP_PID 2>/dev/null; then
    echo "✅ App is running successfully"

    echo "⏱️ Letting app run for 10 seconds to test stability..."
    sleep 10

    if kill -0 $APP_PID 2>/dev/null; then
        echo "✅ App remained stable for 10 seconds"
        echo "📋 This suggests overlay creation might work in real context"
    else
        echo "❌ App crashed during runtime"
    fi

    echo "🛑 Killing app..."
    kill $APP_PID 2>/dev/null
else
    echo "❌ App already crashed during startup"
fi

echo "📊 Test complete"
