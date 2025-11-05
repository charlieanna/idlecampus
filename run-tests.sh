#!/bin/bash

# Adaptive Docker/K8s Learning Platform - Test Runner Script
# This script runs all tests for the platform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} ✓ $1"
}

print_error() {
    echo -e "${RED}[$(date +'%H:%M:%S')]${NC} ✗ $1"
}

echo ""
echo "=========================================="
echo "  Running Test Suite"
echo "=========================================="
echo ""

FLASK_TESTS_PASSED=false
RAILS_TESTS_PASSED=false

# Run Flask tests
print_status "Running Flask ML Service tests..."
cd docker-python/neo_flask

if [ ! -d "venv" ]; then
    print_status "Creating Python virtual environment..."
    python3 -m venv venv
fi

source venv/bin/activate

if [ ! -f "venv/.deps_installed" ]; then
    print_status "Installing Python dependencies..."
    pip install -q -r requirements.txt
    touch venv/.deps_installed
fi

echo ""
echo "--- IRT Service Tests ---"
if pytest tests/test_irt_service.py -v; then
    print_success "IRT Service tests passed"
else
    print_error "IRT Service tests failed"
fi

echo ""
echo "--- FSRS Service Tests ---"
if pytest tests/test_fsrs_service.py -v; then
    print_success "FSRS Service tests passed"
else
    print_error "FSRS Service tests failed"
fi

echo ""
echo "--- Adaptive Learning Service Tests ---"
if pytest tests/test_adaptive_learning_service.py -v; then
    print_success "Adaptive Learning Service tests passed"
    FLASK_TESTS_PASSED=true
else
    print_error "Adaptive Learning Service tests failed"
fi

cd ../..

# Run Rails tests
echo ""
print_status "Running Rails Integration tests..."
cd entry-app/SOVisits

if [ ! -f ".bundle/config" ]; then
    print_status "Installing Ruby gems..."
    bundle install --quiet
fi

# Setup test database if needed
if [ ! -f "db/test.sqlite3" ]; then
    print_status "Setting up test database..."
    RAILS_ENV=test bundle exec rails db:create
    RAILS_ENV=test bundle exec rails db:migrate
fi

echo ""
echo "--- Rails Integration Tests ---"
# Suppress verbose object dumps with progress mode
if RAILS_ENV=test bundle exec rails test test/integration/adaptive_learning_integration_test.rb --progress 2>&1 | grep -v "@" | grep -v "Rails::Paths" | tail -50; then
    print_success "Rails integration tests passed"
    RAILS_TESTS_PASSED=true
else
    # Check if tests actually passed despite exit code
    TEST_RESULT=$(RAILS_ENV=test bundle exec rails test test/integration/adaptive_learning_integration_test.rb --progress 2>&1 | tail -3)
    if echo "$TEST_RESULT" | grep -q "0 failures, 0 errors"; then
        print_success "Rails integration tests passed"
        RAILS_TESTS_PASSED=true
    else
        print_error "Rails integration tests failed (service integration tests require Flask ML service to be running)"
    fi
fi

cd ../..

# Summary
echo ""
echo "=========================================="
echo "  Test Results Summary"
echo "=========================================="
echo ""

if [ "$FLASK_TESTS_PASSED" = true ]; then
    print_success "Flask ML Service Tests: PASSED"
else
    print_error "Flask ML Service Tests: FAILED"
fi

if [ "$RAILS_TESTS_PASSED" = true ]; then
    print_success "Rails Integration Tests: PASSED"
else
    print_error "Rails Integration Tests: FAILED"
fi

echo ""

if [ "$FLASK_TESTS_PASSED" = true ] && [ "$RAILS_TESTS_PASSED" = true ]; then
    print_success "All tests passed! ✨"
    exit 0
else
    print_error "Some tests failed. Please review the output above."
    exit 1
fi