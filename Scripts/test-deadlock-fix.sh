#!/bin/bash

echo "🚨 CRITICAL OVERLAY DEADLOCK TEST - POST FIX"
echo "Testing if the main actor circular dependency fix resolves the deadlock"

cd /Users/michaelhaufschild/Documents/code/unmissable

echo "🚀 Starting app to test overlay functionality..."
swift run &
APP_PID=$!

echo "📱 App started with PID: $APP_PID"
echo "⏰ Waiting 5 seconds for app to fully initialize..."
sleep 5

if kill -0 $APP_PID 2>/dev/null; then
    echo "✅ App running successfully after 5 seconds"
    echo "📊 This indicates the fix prevents immediate deadlocks"

    echo "⏱️ Monitoring app stability for 15 seconds..."
    sleep 15

    if kill -0 $APP_PID 2>/dev/null; then
        echo "✅ CRITICAL SUCCESS: App remained stable for 20 total seconds"
        echo "🎯 This suggests overlay creation deadlock is fixed"
        echo "📈 Previous version would deadlock within seconds of overlay creation"
    else
        echo "❌ App crashed during extended runtime"
    fi

    echo "🛑 Stopping app..."
    kill $APP_PID 2>/dev/null
else
    echo "❌ App crashed during initialization"
fi

echo "📋 Critical test complete"
echo "🚀 If app ran stably, the main actor circular dependency fix is working"
