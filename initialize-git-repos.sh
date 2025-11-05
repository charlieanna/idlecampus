#!/bin/bash
set -e

IDLECAMPUS="/Users/ankurkothari/Documents/workspace/idlecampus"

echo "🚀 Initializing Git Repositories for Idlecampus..."
echo ""

cd "$IDLECAMPUS"

# Function to initialize a git repo if it doesn't have one
init_git_repo() {
    local dir=$1
    local name=$2
    
    if [ ! -d "$dir" ]; then
        echo "⚠️  Directory $dir not found, skipping..."
        return
    fi
    
    cd "$IDLECAMPUS/$dir"
    
    if [ -d ".git" ]; then
        echo "✅ $name already has .git (existing repo)"
    else
        echo "📦 Initializing git for $name..."
        git init
        git add .
        
        # Check if there are any changes to commit
        if ! git diff --staged --quiet || ! git diff --quiet; then
            git commit -m "Initial commit - extracted from monorepo"
            echo "✅ $name initialized and committed"
        else
            echo "⚠️  $name: No changes to commit (empty or already committed)"
        fi
    fi
}

# Step 1: Initialize new repos (frontend, backend, ml-service)
echo "📦 Step 1: Initializing new git repositories..."
echo ""

init_git_repo "frontend" "Frontend"
init_git_repo "backend" "Backend"
init_git_repo "ml-service" "ML Service"

echo ""
echo "📦 Step 2: Checking existing git repositories..."
echo ""

# Check existing repos (adaptive-learning, adaptive-learning-gem)
if [ -d "adaptive-learning" ]; then
    if [ -d "adaptive-learning/.git" ]; then
        echo "✅ adaptive-learning already has .git (existing repo)"
        cd "$IDLECAMPUS/adaptive-learning"
        echo "   Current branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
        echo "   Remotes: $(git remote -v 2>/dev/null | head -1 || echo 'none')"
    else
        echo "⚠️  adaptive-learning exists but has no .git"
    fi
fi

if [ -d "adaptive-learning-gem" ]; then
    if [ -d "adaptive-learning-gem/.git" ]; then
        echo "✅ adaptive-learning-gem already has .git (existing repo)"
        cd "$IDLECAMPUS/adaptive-learning-gem"
        echo "   Current branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
        echo "   Remotes: $(git remote -v 2>/dev/null | head -1 || echo 'none')"
    else
        echo "⚠️  adaptive-learning-gem exists but has no .git"
    fi
fi

echo ""
echo "📦 Step 3: Setting up parent meta-repository..."
echo ""

cd "$IDLECAMPUS"

# Initialize parent repo if needed
if [ ! -d ".git" ]; then
    echo "📁 Initializing parent git repository..."
    git init
else
    echo "✅ Parent repository already initialized"
fi

# Create .gitmodules file
echo "📝 Creating .gitmodules file..."

cat > .gitmodules << 'EOF'
[submodule "frontend"]
	path = frontend
	url = file:///Users/ankurkothari/Documents/workspace/idlecampus/frontend

[submodule "backend"]
	path = backend
	url = file:///Users/ankurkothari/Documents/workspace/idlecampus/backend

[submodule "ml-service"]
	path = ml-service
	url = file:///Users/ankurkothari/Documents/workspace/idlecampus/ml-service
EOF

# Add adaptive-learning libraries if they exist
if [ -d "adaptive-learning" ] && [ -d "adaptive-learning/.git" ]; then
    echo "[submodule \"adaptive-learning\"]" >> .gitmodules
    echo "	path = adaptive-learning" >> .gitmodules
    echo "	url = file:///Users/ankurkothari/Documents/workspace/idlecampus/adaptive-learning" >> .gitmodules
    echo "✅ Added adaptive-learning to .gitmodules"
fi

if [ -d "adaptive-learning-gem" ] && [ -d "adaptive-learning-gem/.git" ]; then
    echo "[submodule \"adaptive-learning-gem\"]" >> .gitmodules
    echo "	path = adaptive-learning-gem" >> .gitmodules
    echo "	url = file:///Users/ankurkothari/Documents/workspace/idlecampus/adaptive-learning-gem" >> .gitmodules
    echo "✅ Added adaptive-learning-gem to .gitmodules"
fi

# Initialize and update submodules
echo ""
echo "🔗 Step 4: Initializing submodules..."
git submodule init

echo ""
echo "📥 Updating submodules..."
git submodule update || {
    echo "⚠️  Some submodules may need to be initialized manually"
    echo "   This is normal if repos were just created"
}

# Create/update README if needed
if [ ! -f README.md ]; then
    cat > README.md << 'EOF'
# Idlecampus Platform

Meta-repository managing all Idlecampus services as git submodules.

## Structure

- `frontend/` - React frontend application
- `backend/` - Rails backend API
- `ml-service/` - Flask ML service
- `adaptive-learning/` - JavaScript adaptive learning library (if present)
- `adaptive-learning-gem/` - Ruby gem adaptive learning library (if present)
- Infrastructure files (docker-compose, nginx, scripts) in root

## Setup

```bash
# Clone with submodules
git clone --recursive <repo-url>

# Or if already cloned
git submodule update --init --recursive
```

## Development

See individual service READMEs for development instructions.

## Services

Each service is an independent git repository managed as a submodule.
EOF
    echo "✅ Created README.md"
fi

# Stage all changes
echo ""
echo "💾 Step 5: Staging changes..."
git add .gitmodules README.md

# Add infrastructure files if they exist
if [ -f docker-compose.yml ]; then
    git add docker-compose*.yml nginx.conf *.sh 2>/dev/null || true
fi

# Commit if there are changes
if ! git diff --staged --quiet || ! git diff --quiet; then
    git commit -m "Initial commit - parent meta-repo with submodules and infrastructure" || true
    echo "✅ Committed parent repository"
else
    echo "ℹ️  No changes to commit in parent repo"
fi

echo ""
echo "✅ Git repository initialization complete!"
echo ""
echo "📊 Summary:"
echo "==========="
echo ""
echo "Parent repository:"
echo "  Location: $IDLECAMPUS"
echo "  Status: $(cd $IDLECAMPUS && git status --short 2>/dev/null | head -1 || echo 'Ready')"
echo ""
echo "Submodules:"
git submodule status 2>/dev/null || echo "  Run 'git submodule init && git submodule update' to complete setup"
echo ""
echo "📋 Next Steps:"
echo "=============="
echo ""
echo "1. Review the repositories:"
echo "   cd frontend && git log --oneline"
echo "   cd backend && git log --oneline"
echo "   cd ml-service && git log --oneline"
echo ""
echo "2. Create GitHub repositories (via UI or gh CLI):"
echo "   gh repo create idlecampus --private"
echo "   gh repo create idlecampus-frontend --private"
echo "   gh repo create idlecampus-backend --private"
echo "   gh repo create idlecampus-ml-service --private"
echo ""
echo "3. Push to GitHub:"
echo "   # For each repo:"
echo "   cd frontend"
echo "   git remote add origin https://github.com/ankothari1986-ux/idlecampus-frontend.git"
echo "   git push -u origin main"
echo ""
echo "4. Update .gitmodules with GitHub URLs after pushing"
echo "   See GIT_REPOSITORY_STRUCTURE.md for details"

