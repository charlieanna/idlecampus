#!/bin/bash

# Adaptive Docker/K8s Learning Platform - Service Shutdown Script
# This script stops all running services

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

print_warning() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')]${NC} ⚠ $1"
}

echo ""
echo "=========================================="
echo "  Stopping Adaptive Learning Platform"
echo "=========================================="
echo ""

# Stop Rails
if [ -f "entry-app/SOVisits/rails.pid" ]; then
    RAILS_PID=$(cat entry-app/SOVisits/rails.pid)
    if ps -p $RAILS_PID > /dev/null 2>&1; then
        print_status "Stopping Rails (PID: $RAILS_PID)..."
        kill $RAILS_PID
        rm entry-app/SOVisits/rails.pid
        print_success "Rails stopped"
    else
        print_warning "Rails not running"
        rm entry-app/SOVisits/rails.pid
    fi
else
    # Try to find Rails process by port
    RAILS_PID=$(lsof -ti:3001)
    if [ ! -z "$RAILS_PID" ]; then
        print_status "Stopping Rails (PID: $RAILS_PID)..."
        kill $RAILS_PID
        print_success "Rails stopped"
    else
        print_warning "Rails not running"
    fi
fi

# Stop Flask
if [ -f "docker-python/neo_flask/flask.pid" ]; then
    FLASK_PID=$(cat docker-python/neo_flask/flask.pid)
    if ps -p $FLASK_PID > /dev/null 2>&1; then
        print_status "Stopping Flask (PID: $FLASK_PID)..."
        kill $FLASK_PID
        rm docker-python/neo_flask/flask.pid
        print_success "Flask stopped"
    else
        print_warning "Flask not running"
        rm docker-python/neo_flask/flask.pid
    fi
else
    # Try to find Flask process by port
    FLASK_PID=$(lsof -ti:5000)
    if [ ! -z "$FLASK_PID" ]; then
        print_status "Stopping Flask (PID: $FLASK_PID)..."
        kill $FLASK_PID
        print_success "Flask stopped"
    else
        print_warning "Flask not running"
    fi
fi

# Stop Redis (optional - you may want to keep Redis running)
read -p "Stop Redis? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if pgrep -x "redis-server" > /dev/null; then
        print_status "Stopping Redis..."
        redis-cli shutdown
        print_success "Redis stopped"
    else
        print_warning "Redis not running"
    fi
fi

echo ""
print_success "Services stopped"
echo ""