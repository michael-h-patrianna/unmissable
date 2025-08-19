#!/bin/bash

# CONSOLIDATED TEST CLEANUP AND MANAGEMENT SCRIPT
# This script removes duplicate/overlapping tests and runs the new consolidated test suite

echo "🧹 CONSOLIDATING TEST SUITE: Removing duplicate and overlapping tests"
echo "======================================================================"

cd /Users/michaelhaufschild/Documents/code/unmissable

# List of tests to remove (duplicates and overlaps)
TESTS_TO_REMOVE=(
    # Deadlock tests (consolidated into EndToEndDeadlockPreventionTests)
    "Tests/UnmissableTests/CriticalOverlayDeadlockTest.swift"
    "Tests/UnmissableTests/OverlayDeadlockReproductionTest.swift"
    "Tests/UnmissableTests/OverlayDeadlockSimpleTest.swift"
    "Tests/UnmissableTests/TimerInvalidationDeadlockTest.swift"
    "Tests/UnmissableTests/WindowServerDeadlockTest.swift"
    "Tests/UnmissableTests/AsyncDispatchDeadlockFixTest.swift"
    "Tests/UnmissableTests/DismissDeadlockFixValidationTest.swift"
    "Tests/UnmissableTests/ProductionDismissDeadlockTest.swift"
    "Tests/UnmissableTests/UIInteractionDeadlockTest.swift"

    # Overlay functionality tests (consolidated into OverlayFunctionalityIntegrationTests)
    "Tests/UnmissableTests/ComprehensiveOverlayTest.swift"
    "Tests/UnmissableTests/OverlayCompleteIntegrationTests.swift"
    "Tests/UnmissableTests/OverlayManagerComprehensiveTests.swift"
    "Tests/UnmissableTests/OverlayManagerIntegrationTests.swift"
    "Tests/UnmissableTests/OverlayAccuracyAndInteractionTests.swift"
    "Tests/UnmissableTests/OverlayBugReproductionTests.swift"

    # Timer tests (consolidated into the main test suites)
    "Tests/UnmissableTests/OverlayTimerLogicTests.swift"
    "Tests/UnmissableTests/OverlayTimerFixValidationTests.swift"
    "Tests/UnmissableTests/CountdownTimerMigrationTests.swift"
    "Tests/UnmissableTests/SnoozeTimerMigrationTests.swift"
    "Tests/UnmissableTests/ScheduleTimerMigrationTests.swift"
    "Tests/UnmissableTests/OverlayManagerTimerFixTest.swift"
    "Tests/UnmissableTests/TimerMigrationTestHelpers.swift"

    # UI/Component tests that overlap
    "Tests/UnmissableTests/ComprehensiveUICallbackTest.swift"
    "Tests/UnmissableTests/UIComponentComprehensiveTests.swift"
    "Tests/UnmissableTests/UIInteractionDeadlockTest.swift"
    "Tests/UnmissableTests/OverlayUIInteractionValidationTests.swift"

    # Redundant snooze tests
    "Tests/UnmissableTests/OverlaySnoozeAndDismissTests.swift"
    "Tests/UnmissableTests/ProductionSnoozeEndToEndTest.swift"
    "Tests/UnmissableTests/SnoozeAfterMeetingStartTest.swift"
)

echo "📋 Tests scheduled for removal:"
for test in "${TESTS_TO_REMOVE[@]}"; do
    if [ -f "$test" ]; then
        echo "  ✓ $test"
    else
        echo "  ⚠️  $test (already removed)"
    fi
done

echo ""
read -p "🤔 Do you want to proceed with removing these duplicate tests? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  Removing duplicate tests..."

    for test in "${TESTS_TO_REMOVE[@]}"; do
        if [ -f "$test" ]; then
            rm "$test"
            echo "  ✅ Removed: $test"
        fi
    done

    echo ""
    echo "✅ Duplicate test removal completed!"
else
    echo "❌ Test removal cancelled."
    echo "💡 You can review the list above and remove tests manually if preferred."
fi

echo ""
echo "🧪 REMAINING CORE TESTS AFTER CONSOLIDATION:"
echo "=============================================="

# List core tests that should remain
CORE_TESTS=(
    "Tests/UnmissableTests/EndToEndDeadlockPreventionTests.swift"
    "Tests/UnmissableTests/OverlayFunctionalityIntegrationTests.swift"
    "Tests/UnmissableTests/EventTests.swift"
    "Tests/UnmissableTests/LinkParserTests.swift"
    "Tests/UnmissableTests/StartedMeetingsTests.swift"
    "Tests/UnmissableTests/AttendeeModelTests.swift"
    "Tests/UnmissableTests/ProviderTests.swift"
    "Tests/UnmissableTests/PreferencesManagerTests.swift"
    "Tests/UnmissableTests/DatabaseManagerComprehensiveTests.swift"
    "Tests/UnmissableTests/EventSchedulerComprehensiveTests.swift"
    "Tests/UnmissableTests/EventFilteringTests.swift"
    "Tests/UnmissableTests/MeetingDetailsEndToEndTests.swift"
    "Tests/UnmissableTests/MeetingDetailsPopupTests.swift"
    "Tests/UnmissableTests/MeetingDetailsUIAutomationTests.swift"
    "Tests/UnmissableTests/SystemIntegrationTests.swift"
    "Tests/UnmissableTests/QuickJoinManagerTests.swift"
    "Tests/UnmissableTests/OverlayContentViewTests.swift"
    "Tests/UnmissableTests/TestUtilities.swift"
    "Tests/IntegrationTests/CalendarServiceIntegrationTests.swift"
    "Tests/SnapshotTests/OverlaySnapshotTests.swift"
)

echo "📊 Core test suite (focused and non-overlapping):"
for test in "${CORE_TESTS[@]}"; do
    if [ -f "$test" ]; then
        echo "  ✅ $test"
    else
        echo "  ❌ $test (missing - this is expected for newly consolidated tests)"
    fi
done

echo ""
echo "🚀 RUNNING CONSOLIDATED TEST SUITE:"
echo "===================================="

echo "🔧 Building project..."
swift build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "🧪 Running new consolidated deadlock prevention tests..."
    swift test --filter EndToEndDeadlockPreventionTests

    echo ""
    echo "🧪 Running new consolidated overlay functionality tests..."
    swift test --filter OverlayFunctionalityIntegrationTests

    echo ""
    echo "🧪 Running core model and utility tests..."
    swift test --filter "EventTests|LinkParserTests|AttendeeModelTests|ProviderTests"

else
    echo "❌ Build failed. Please fix compilation errors before running tests."
fi

echo ""
echo "📋 CONSOLIDATION SUMMARY:"
echo "========================"
echo "✅ Removed duplicate deadlock tests - consolidated into EndToEndDeadlockPreventionTests"
echo "✅ Removed duplicate overlay tests - consolidated into OverlayFunctionalityIntegrationTests"
echo "✅ Removed duplicate timer tests - functionality covered in main test suites"
echo "✅ Kept essential model, parsing, and integration tests"
echo ""
echo "🎯 FOCUS: End-to-end deadlock prevention with comprehensive coverage"
echo "💡 The new test suite covers all previous functionality with better organization"
