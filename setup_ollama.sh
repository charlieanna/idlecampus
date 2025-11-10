#!/bin/bash

# UPSC Platform - Ollama AI Setup Script
# This script sets up Ollama for AI-powered answer evaluation

set -e

echo "🤖 UPSC Platform - Ollama AI Setup"
echo "===================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    echo "Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

echo -e "${GREEN}✅ Docker found${NC}"
echo ""

# Check if docker-compose is available
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
elif docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    echo -e "${RED}❌ docker-compose is not available${NC}"
    echo "Please install docker-compose"
    exit 1
fi

echo -e "${GREEN}✅ docker-compose found${NC}"
echo ""

# Start Ollama container
echo "📦 Starting Ollama container..."
$DOCKER_COMPOSE -f docker-compose.ollama.yml up -d

# Wait for Ollama to be ready
echo ""
echo "⏳ Waiting for Ollama to start (30 seconds)..."
sleep 30

# Check if Ollama is responding
echo ""
echo "🔍 Checking Ollama status..."
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo -e "${GREEN}✅ Ollama is running!${NC}"
else
    echo -e "${RED}❌ Ollama is not responding${NC}"
    echo "Try: docker logs upsc_ollama"
    exit 1
fi

echo ""
echo "📥 Pulling AI model (llama3.2)..."
echo "This may take a few minutes depending on your internet connection..."
docker exec upsc_ollama ollama pull llama3.2

# Verify model is installed
echo ""
echo "🔍 Verifying model installation..."
if docker exec upsc_ollama ollama list | grep -q "llama3.2"; then
    echo -e "${GREEN}✅ Model llama3.2 installed successfully!${NC}"
else
    echo -e "${YELLOW}⚠️  Model installation may have failed${NC}"
    echo "Check with: docker exec upsc_ollama ollama list"
fi

# Test the API
echo ""
echo "🧪 Testing AI service..."
if curl -s http://localhost:11434/api/tags | grep -q "llama3.2"; then
    echo -e "${GREEN}✅ AI service is working!${NC}"
else
    echo -e "${YELLOW}⚠️  Could not verify AI service${NC}"
fi

# Setup environment variables
echo ""
echo "📝 Setting up environment variables..."
if [ ! -f backend/.env ]; then
    touch backend/.env
fi

# Add Ollama config if not present
if ! grep -q "OLLAMA_URL" backend/.env; then
    echo "" >> backend/.env
    echo "# Ollama AI Configuration" >> backend/.env
    echo "OLLAMA_URL=http://localhost:11434" >> backend/.env
    echo "OLLAMA_MODEL=llama3.2" >> backend/.env
    echo -e "${GREEN}✅ Environment variables added to backend/.env${NC}"
else
    echo -e "${YELLOW}⚠️  Ollama config already exists in backend/.env${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🎉 Ollama AI Setup Complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Status:"
echo "  • Ollama running on: http://localhost:11434"
echo "  • Model installed: llama3.2"
echo "  • Container name: upsc_ollama"
echo ""
echo "🚀 Next Steps:"
echo "  1. Start Rails: cd backend && rails server"
echo "  2. Test status: curl http://localhost:3000/api/v1/upsc/ai/status"
echo "  3. Submit answers with auto_evaluate=true"
echo ""
echo "📚 Documentation:"
echo "  • Setup Guide: OLLAMA_SETUP_GUIDE.md"
echo "  • API Docs: OPTION_B_DELIVERY_COMPLETE.md"
echo ""
echo "🔧 Useful Commands:"
echo "  • View logs: docker logs upsc_ollama"
echo "  • Stop Ollama: $DOCKER_COMPOSE -f docker-compose.ollama.yml down"
echo "  • Restart: $DOCKER_COMPOSE -f docker-compose.ollama.yml restart"
echo "  • Pull different model: docker exec upsc_ollama ollama pull mistral"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
