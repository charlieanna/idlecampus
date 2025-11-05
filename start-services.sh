#!/bin/bash

# Adaptive Docker/K8s Learning Platform - Service Startup Script
# This script starts all required services for local development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} ✓ $1"
}

print_error() {
    echo -e "${RED}[$(date +'%H:%M:%S')]${NC} ✗ $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')]${NC} ⚠ $1"
}

# Check if required commands exist
check_dependencies() {
    print_status "Checking dependencies..."
    
    local missing_deps=()
    
    if ! command -v redis-server &> /dev/null; then
        missing_deps+=("redis-server")
    fi
    
    if ! command -v python3 &> /dev/null; then
        missing_deps+=("python3")
    fi
    
    if ! command -v bundle &> /dev/null; then
        missing_deps+=("bundle (Ruby bundler)")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        echo ""
        echo "Please install missing dependencies:"
        echo "  macOS: brew install redis python3 ruby"
        echo "  Ubuntu: sudo apt-get install redis-server python3 python3-pip ruby-bundler"
        exit 1
    fi
    
    print_success "All dependencies found"
}

# Start Redis
start_redis() {
    print_status "Starting Redis..."
    
    if pgrep -x "redis-server" > /dev/null; then
        print_warning "Redis already running"
    else
        # Use custom config file in current directory
        redis-server redis.conf 2>/dev/null
        sleep 1
        
        if pgrep -x "redis-server" > /dev/null; then
            print_success "Redis started on port 6379"
        else
            # Try without config file as fallback
            print_warning "Trying to start Redis without config file..."
            redis-server --port 6379 --daemonize yes --logfile redis.log --pidfile redis.pid --dir . 2>/dev/null
            sleep 1
            
            if pgrep -x "redis-server" > /dev/null; then
                print_success "Redis started on port 6379"
            else
                print_error "Failed to start Redis. Please start Redis manually: redis-server"
                exit 1
            fi
        fi
    fi
}

# Start Flask ML Service
start_flask() {
    print_status "Starting Flask ML Service..."
    
    cd docker-python/neo_flask
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ]; then
        print_status "Creating Python virtual environment..."
        python3 -m venv venv
    fi
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Install dependencies
    if [ ! -f "venv/.deps_installed" ]; then
        print_status "Installing Python dependencies..."
        pip install -q -r requirements.txt
        touch venv/.deps_installed
        print_success "Python dependencies installed"
    fi
    
    # Check if already running
    if lsof -Pi :5000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_warning "Flask service already running on port 5000"
    else
        # Start Flask in background
        print_status "Starting Flask on port 5000..."
        nohup python app/main.py > flask.log 2>&1 &
        FLASK_PID=$!
        echo $FLASK_PID > flask.pid
        
        # Wait for Flask to be ready
        sleep 3
        
        if curl -s http://localhost:5000/api/health > /dev/null 2>&1; then
            print_success "Flask ML Service started (PID: $FLASK_PID)"
        else
            print_error "Flask service failed to start (check flask.log)"
            exit 1
        fi
    fi
    
    cd ../..
}

# Start Rails App
start_rails() {
    print_status "Starting Rails Application..."
    
    cd entry-app/SOVisits
    
    # Install gems if needed
    if [ ! -f ".bundle/config" ]; then
        print_status "Installing Ruby gems..."
        bundle install --quiet
        print_success "Ruby gems installed"
    fi
    
    # Check if database exists
    if [ ! -f "db/development.sqlite3" ]; then
        print_status "Setting up database..."
        bundle exec rails db:create
        bundle exec rails db:migrate
        print_success "Database created and migrated"
        
        print_status "Loading seed data (Docker commands, K8s resources, labs)..."
        bundle exec rails db:seed
        print_success "Seed data loaded"
    fi
    
    # Check if already running on port 3000
    if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_warning "Rails already running on port 3000"
    else
        # Start Rails in background on port 3000
        print_status "Starting Rails on port 3000..."
        nohup bundle exec rails server -p 3000 > rails.log 2>&1 &
        RAILS_PID=$!
        echo $RAILS_PID > rails.pid
        
        # Wait for Rails to be ready
        print_status "Waiting for Rails to start (this may take 10-15 seconds)..."
        for i in {1..30}; do
            if curl -s http://localhost:3000 > /dev/null 2>&1; then
                print_success "Rails Application started (PID: $RAILS_PID)"
                break
            fi
            sleep 1
            if [ $i -eq 30 ]; then
                print_error "Rails failed to start (check rails.log)"
                exit 1
            fi
        done
    fi
    
    cd ../..
}

# Print service status
print_service_status() {
    echo ""
    echo "=========================================="
    echo "   Services Status"
    echo "=========================================="
    echo ""
    
    if pgrep -x "redis-server" > /dev/null; then
        print_success "Redis:        Running (port 6379)"
    else
        print_error "Redis:        Not running"
    fi
    
    if lsof -Pi :5000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_success "Flask ML:     Running (port 5000)"
    else
        print_error "Flask ML:     Not running"
    fi
    
    if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_success "Rails App:    Running (port 3000)"
    else
        print_error "Rails App:    Not running"
    fi
    
    echo ""
    echo "=========================================="
    echo "   Access URLs"
    echo "=========================================="
    echo ""
    echo "  Rails App:        http://localhost:3000"
    echo "  Flask ML API:     http://localhost:5000/api/health"
    echo "  Redis:            redis://localhost:6379"
    echo ""
    echo "=========================================="
    echo "   Log Files"
    echo "=========================================="
    echo ""
    echo "  Flask logs:       docker-python/neo_flask/flask.log"
    echo "  Rails logs:       entry-app/SOVisits/rails.log"
    echo ""
    echo "=========================================="
    echo "   Useful Commands"
    echo "=========================================="
    echo ""
    echo "  Stop services:    ./stop-services.sh"
    echo "  View logs:        tail -f entry-app/SOVisits/rails.log"
    echo "  Run tests:        ./run-tests.sh"
    echo ""
}

# Main execution
main() {
    echo ""
    echo "=========================================="
    echo "  Starting Adaptive Learning Platform"
    echo "=========================================="
    echo ""
    
    check_dependencies
    start_redis
    start_flask
    start_rails
    
    print_service_status
    
    print_success "All services started successfully!"
    echo ""
}

# Run main function
main