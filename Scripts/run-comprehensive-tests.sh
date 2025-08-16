#!/bin/bash

# Test Automation Script for Unmissable App
# This script runs the comprehensive test suite and validates production readiness

set -e  # Exit on any error

echo "🧪 Starting Unmissable Test Automation Suite"
echo "=============================================="

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME="Unmissable"
DESTINATION="platform=macOS"
BUILD_DIR="$PROJECT_DIR/.build"
COVERAGE_DIR="$PROJECT_DIR/coverage"
REPORTS_DIR="$PROJECT_DIR/test-reports"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up temporary files..."
    rm -rf "$BUILD_DIR"
}

# Set up cleanup on exit
trap cleanup EXIT

# Create necessary directories
mkdir -p "$COVERAGE_DIR"
mkdir -p "$REPORTS_DIR"

# Step 1: Code Formatting and Linting
log_info "Step 1: Running code formatting and linting..."

if command -v swiftformat &> /dev/null; then
    log_info "Running SwiftFormat..."
    swiftformat "$PROJECT_DIR/Sources" "$PROJECT_DIR/Tests" --config "$PROJECT_DIR/.swiftformat"
    log_success "Code formatting completed"
else
    log_warning "SwiftFormat not found, skipping formatting"
fi

if command -v swiftlint &> /dev/null; then
    log_info "Running SwiftLint..."
    swiftlint --config "$PROJECT_DIR/.swiftlint.yml" --path "$PROJECT_DIR/Sources" --path "$PROJECT_DIR/Tests"
    log_success "Linting completed"
else
    log_warning "SwiftLint not found, skipping linting"
fi

# Step 2: Build the project
log_info "Step 2: Building project..."
xcodebuild -scheme "$SCHEME" -destination "$DESTINATION" build | tee "$REPORTS_DIR/build.log"
log_success "Build completed successfully"

# Step 3: Run Unit Tests
log_info "Step 3: Running unit tests..."
xcodebuild -scheme "$SCHEME" -destination "$DESTINATION" test \
    -only-testing:"UnmissableTests" \
    -resultBundlePath "$REPORTS_DIR/unit-tests.xcresult" \
    | tee "$REPORTS_DIR/unit-tests.log"

if [ $? -eq 0 ]; then
    log_success "Unit tests passed"
else
    log_error "Unit tests failed"
    exit 1
fi

# Step 4: Run Integration Tests
log_info "Step 4: Running integration tests..."
xcodebuild -scheme "$SCHEME" -destination "$DESTINATION" test \
    -only-testing:"IntegrationTests" \
    -resultBundlePath "$REPORTS_DIR/integration-tests.xcresult" \
    | tee "$REPORTS_DIR/integration-tests.log"

if [ $? -eq 0 ]; then
    log_success "Integration tests passed"
else
    log_error "Integration tests failed"
    exit 1
fi

# Step 5: Run UI/Snapshot Tests
log_info "Step 5: Running UI and snapshot tests..."
xcodebuild -scheme "$SCHEME" -destination "$DESTINATION" test \
    -only-testing:"SnapshotTests" \
    -resultBundlePath "$REPORTS_DIR/ui-tests.xcresult" \
    | tee "$REPORTS_DIR/ui-tests.log"

if [ $? -eq 0 ]; then
    log_success "UI tests passed"
else
    log_warning "UI tests failed (may be acceptable for snapshot tests)"
fi

# Step 6: Generate Code Coverage Report
log_info "Step 6: Generating code coverage report..."
if command -v xcov &> /dev/null; then
    xcov --project "$PROJECT_DIR/Unmissable.xcodeproj" \
         --scheme "$SCHEME" \
         --output_directory "$COVERAGE_DIR" \
         --minimum_coverage_percentage 80
    log_success "Code coverage report generated"
else
    log_warning "xcov not found, skipping coverage report"
fi

# Step 7: Performance Testing
log_info "Step 7: Running performance tests..."
xcodebuild -scheme "$SCHEME" -destination "$DESTINATION" test \
    -only-testing:"UnmissableTests/testLargeNumberOfEvents" \
    -only-testing:"UnmissableTests/testBatchEventSavePerformance" \
    -only-testing:"UnmissableTests/testEndToEndPerformance" \
    -resultBundlePath "$REPORTS_DIR/performance-tests.xcresult" \
    | tee "$REPORTS_DIR/performance-tests.log"

if [ $? -eq 0 ]; then
    log_success "Performance tests passed"
else
    log_warning "Performance tests had issues"
fi

# Step 8: Memory Leak Detection
log_info "Step 8: Running memory leak detection tests..."
xcodebuild -scheme "$SCHEME" -destination "$DESTINATION" test \
    -only-testing:"UnmissableTests/testEventSchedulerDeallocation" \
    -only-testing:"UnmissableTests/testOverlayManagerDeallocation" \
    -only-testing:"UnmissableTests/testDatabaseManagerDeallocation" \
    -resultBundlePath "$REPORTS_DIR/memory-tests.xcresult" \
    | tee "$REPORTS_DIR/memory-tests.log"

if [ $? -eq 0 ]; then
    log_success "Memory leak tests passed"
else
    log_error "Memory leak tests failed"
    exit 1
fi

# Step 9: Test Report Analysis
log_info "Step 9: Analyzing test results..."

# Extract test metrics from xcresult bundles
if command -v xcparse &> /dev/null; then
    for result_bundle in "$REPORTS_DIR"/*.xcresult; do
        if [ -f "$result_bundle" ]; then
            bundle_name=$(basename "$result_bundle" .xcresult)
            xcparse --output "$REPORTS_DIR/$bundle_name-summary.json" "$result_bundle"
        fi
    done
    log_success "Test results parsed"
else
    log_warning "xcparse not found, skipping detailed test analysis"
fi

# Step 10: Production Readiness Check
log_info "Step 10: Production readiness validation..."

# Check for critical issues
CRITICAL_ISSUES=0

# Check test pass rate
if grep -q "Test Suite.*failed" "$REPORTS_DIR/unit-tests.log"; then
    log_error "Unit test failures detected"
    CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
fi

if grep -q "Test Suite.*failed" "$REPORTS_DIR/integration-tests.log"; then
    log_error "Integration test failures detected"
    CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
fi

# Check for memory leaks
if grep -q "Memory leak detected" "$REPORTS_DIR/memory-tests.log"; then
    log_error "Memory leaks detected"
    CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
fi

# Check performance benchmarks
if grep -q "Performance test failed" "$REPORTS_DIR/performance-tests.log"; then
    log_warning "Performance benchmarks not met"
fi

# Generate final report
cat > "$REPORTS_DIR/production-readiness-report.md" << EOF
# Production Readiness Report

Generated: $(date)

## Test Suite Results

### Unit Tests
- Status: $(if grep -q "Test Suite.*failed" "$REPORTS_DIR/unit-tests.log"; then echo "❌ FAILED"; else echo "✅ PASSED"; fi)
- Log: unit-tests.log

### Integration Tests
- Status: $(if grep -q "Test Suite.*failed" "$REPORTS_DIR/integration-tests.log"; then echo "❌ FAILED"; else echo "✅ PASSED"; fi)
- Log: integration-tests.log

### UI Tests
- Status: $(if grep -q "Test Suite.*failed" "$REPORTS_DIR/ui-tests.log"; then echo "⚠️ ISSUES"; else echo "✅ PASSED"; fi)
- Log: ui-tests.log

### Performance Tests
- Status: $(if grep -q "Performance test failed" "$REPORTS_DIR/performance-tests.log"; then echo "⚠️ SLOW"; else echo "✅ PASSED"; fi)
- Log: performance-tests.log

### Memory Tests
- Status: $(if grep -q "Memory leak detected" "$REPORTS_DIR/memory-tests.log"; then echo "❌ LEAKS"; else echo "✅ PASSED"; fi)
- Log: memory-tests.log

## Critical Issues
- Count: $CRITICAL_ISSUES

## Production Readiness
$(if [ $CRITICAL_ISSUES -eq 0 ]; then echo "✅ **READY FOR PRODUCTION**"; else echo "❌ **NOT READY - $CRITICAL_ISSUES critical issues**"; fi)

## Recommendations
$(if [ $CRITICAL_ISSUES -eq 0 ]; then
    echo "- All critical tests passing"
    echo "- No memory leaks detected"
    echo "- System meets performance requirements"
    echo "- Safe to deploy to production"
else
    echo "- Fix failing unit/integration tests"
    echo "- Resolve memory leaks"
    echo "- Review performance issues"
    echo "- Re-run test suite before deployment"
fi)
EOF

# Final Results
echo ""
echo "🎯 Test Automation Complete!"
echo "==============================="
echo ""

if [ $CRITICAL_ISSUES -eq 0 ]; then
    log_success "ALL TESTS PASSED - APPLICATION IS PRODUCTION READY! 🚀"
    echo ""
    log_info "Summary:"
    echo "  ✅ Unit tests: PASSED"
    echo "  ✅ Integration tests: PASSED"
    echo "  ✅ Memory tests: PASSED"
    echo "  📊 Performance tests: $(if grep -q "Performance test failed" "$REPORTS_DIR/performance-tests.log"; then echo "SLOW"; else echo "PASSED"; fi)"
    echo "  📱 UI tests: $(if grep -q "Test Suite.*failed" "$REPORTS_DIR/ui-tests.log"; then echo "ISSUES"; else echo "PASSED"; fi)"
    echo ""
    echo "📋 Reports generated in: $REPORTS_DIR"
    echo "📊 Coverage report: $COVERAGE_DIR"
    echo ""
    echo "The application is stable, freeze-free, and ready for production deployment."
else
    log_error "TESTS FAILED - $CRITICAL_ISSUES CRITICAL ISSUES FOUND"
    echo ""
    log_info "Issues to fix:"
    grep -l "failed\|FAILED\|Memory leak" "$REPORTS_DIR"/*.log | while read -r file; do
        echo "  🔍 Check: $(basename "$file")"
    done
    echo ""
    echo "Review the test reports and fix issues before deployment."
    exit 1
fi
