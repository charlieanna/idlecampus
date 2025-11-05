#!/bin/bash
set -e

IDLECAMPUS="/Users/ankurkothari/Documents/workspace/idlecampus"
GITHUB_USER="ankothari1986-ux"
GITHUB_BASE_URL="https://github.com/${GITHUB_USER}"

echo "🚀 Pushing Idlecampus Repositories to GitHub..."
echo ""

cd "$IDLECAMPUS"

# Function to create GitHub repo if it doesn't exist
create_github_repo() {
    local repo_name=$1
    local description=$2
    
    echo "📦 Creating GitHub repository: $repo_name"
    
    # Check if repo already exists
    if gh repo view "${GITHUB_USER}/${repo_name}" &>/dev/null; then
        echo "✅ Repository $repo_name already exists on GitHub"
    else
        gh repo create "$repo_name" --private --description "$description" || {
            echo "⚠️  Failed to create $repo_name. You may need to create it manually."
            echo "   Or it might already exist. Continuing..."
        }
    fi
}

# Function to push submodule to GitHub
push_submodule() {
    local dir=$1
    local repo_name=$2
    local branch=${3:-master}
    
    if [ ! -d "$dir" ]; then
        echo "⚠️  Directory $dir not found, skipping..."
        return
    fi
    
    if [ ! -d "$dir/.git" ]; then
        echo "⚠️  $dir has no .git directory, skipping..."
        return
    fi
    
    echo ""
    echo "📤 Pushing $dir to GitHub..."
    cd "$IDLECAMPUS/$dir"
    
    # Check if remote already exists
    if git remote get-url origin &>/dev/null; then
        echo "✅ Remote 'origin' already exists for $dir"
        CURRENT_URL=$(git remote get-url origin)
        echo "   Current URL: $CURRENT_URL"
        
        # Update if it's a file:// URL
        if [[ "$CURRENT_URL" == file://* ]]; then
            echo "🔄 Updating remote URL to GitHub..."
            git remote set-url origin "${GITHUB_BASE_URL}/${repo_name}.git"
        fi
    else
        echo "➕ Adding remote 'origin'..."
        git remote add origin "${GITHUB_BASE_URL}/${repo_name}.git"
    fi
    
    # Ensure we're on the right branch
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
    if [ -z "$CURRENT_BRANCH" ]; then
        echo "⚠️  No branch found, creating master..."
        git checkout -b master 2>/dev/null || git branch -M master
    fi
    
    # Push to GitHub
    echo "📤 Pushing to GitHub..."
    git push -u origin "$branch" || {
        echo "⚠️  Push failed. Trying with --force if needed..."
        read -p "Force push? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git push -u origin "$branch" --force
        else
            echo "⚠️  Skipping push for $dir"
        fi
    }
    
    echo "✅ $dir pushed to GitHub"
}

# Step 1: Create GitHub repositories
echo "📦 Step 1: Creating GitHub repositories..."
echo ""

create_github_repo "idlecampus" "Idlecampus Platform - Meta repository with submodules"
create_github_repo "idlecampus-frontend" "Idlecampus Frontend - React application"
create_github_repo "idlecampus-backend" "Idlecampus Backend - Rails API"
create_github_repo "idlecampus-ml-service" "Idlecampus ML Service - Flask ML algorithms"

# Check for adaptive-learning repos
if [ -d "adaptive-learning" ] && [ -d "adaptive-learning/.git" ]; then
    create_github_repo "idlecampus-adaptive-learning" "Idlecampus Adaptive Learning - JavaScript library"
fi

if [ -d "adaptive-learning-gem" ] && [ -d "adaptive-learning-gem/.git" ]; then
    create_github_repo "idlecampus-adaptive-learning-gem" "Idlecampus Adaptive Learning Gem - Ruby gem"
fi

# Step 2: Push submodules to GitHub
echo ""
echo "📤 Step 2: Pushing submodules to GitHub..."
echo ""

push_submodule "frontend" "idlecampus-frontend" "master"
push_submodule "backend" "idlecampus-backend" "master"
push_submodule "ml-service" "idlecampus-ml-service" "master"

if [ -d "adaptive-learning" ] && [ -d "adaptive-learning/.git" ]; then
    push_submodule "adaptive-learning" "idlecampus-adaptive-learning" "master"
fi

if [ -d "adaptive-learning-gem" ] && [ -d "adaptive-learning-gem/.git" ]; then
    push_submodule "adaptive-learning-gem" "idlecampus-adaptive-learning-gem" "master"
fi

# Step 3: Update .gitmodules with GitHub URLs
echo ""
echo "📝 Step 3: Updating .gitmodules with GitHub URLs..."
echo ""

cd "$IDLECAMPUS"

# Backup .gitmodules
cp .gitmodules .gitmodules.backup

# Update URLs in .gitmodules
sed -i '' "s|file:///Users/ankurkothari/Documents/workspace/idlecampus/frontend|${GITHUB_BASE_URL}/idlecampus-frontend.git|g" .gitmodules
sed -i '' "s|file:///Users/ankurkothari/Documents/workspace/idlecampus/backend|${GITHUB_BASE_URL}/idlecampus-backend.git|g" .gitmodules
sed -i '' "s|file:///Users/ankurkothari/Documents/workspace/idlecampus/ml-service|${GITHUB_BASE_URL}/idlecampus-ml-service.git|g" .gitmodules

if [ -d "adaptive-learning" ] && [ -d "adaptive-learning/.git" ]; then
    sed -i '' "s|file:///Users/ankurkothari/Documents/workspace/idlecampus/adaptive-learning|${GITHUB_BASE_URL}/idlecampus-adaptive-learning.git|g" .gitmodules
fi

if [ -d "adaptive-learning-gem" ] && [ -d "adaptive-learning-gem/.git" ]; then
    sed -i '' "s|file:///Users/ankurkothari/Documents/workspace/idlecampus/adaptive-learning-gem|${GITHUB_BASE_URL}/idlecampus-adaptive-learning-gem.git|g" .gitmodules
fi

echo "✅ Updated .gitmodules with GitHub URLs"
echo ""
echo "📋 Updated .gitmodules:"
cat .gitmodules

# Step 4: Commit and push parent repo
echo ""
echo "💾 Step 4: Committing and pushing parent repository..."
echo ""

cd "$IDLECAMPUS"

# Add untracked files if any
git add .gitmodules GIT_REPOSITORY_STRUCTURE.md 2>/dev/null || true

# Commit if there are changes
if ! git diff --staged --quiet || ! git diff --quiet .gitmodules; then
    git add .gitmodules
    git commit -m "Update submodule URLs to GitHub" || true
    echo "✅ Committed .gitmodules update"
else
    echo "ℹ️  No changes to commit"
fi

# Add remote if not exists
if ! git remote get-url origin &>/dev/null; then
    echo "➕ Adding remote 'origin' for parent repo..."
    git remote add origin "${GITHUB_BASE_URL}/idlecampus.git"
else
    CURRENT_URL=$(git remote get-url origin)
    if [[ "$CURRENT_URL" == file://* ]]; then
        echo "🔄 Updating remote URL to GitHub..."
        git remote set-url origin "${GITHUB_BASE_URL}/idlecampus.git"
    else
        echo "✅ Remote 'origin' already set: $CURRENT_URL"
    fi
fi

# Ensure we're on master branch
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
if [ -z "$CURRENT_BRANCH" ]; then
    git checkout -b master 2>/dev/null || git branch -M master
fi

# Push parent repo
echo "📤 Pushing parent repository to GitHub..."
git push -u origin master || {
    echo "⚠️  Push failed. You may need to push manually:"
    echo "   git push -u origin master"
}

echo ""
echo "✅ Push to GitHub complete!"
echo ""
echo "📊 Summary:"
echo "==========="
echo ""
echo "✅ All repositories created on GitHub"
echo "✅ All submodules pushed to GitHub"
echo "✅ .gitmodules updated with GitHub URLs"
echo "✅ Parent repository pushed to GitHub"
echo ""
echo "🔗 Your repositories:"
echo "   - ${GITHUB_BASE_URL}/idlecampus"
echo "   - ${GITHUB_BASE_URL}/idlecampus-frontend"
echo "   - ${GITHUB_BASE_URL}/idlecampus-backend"
echo "   - ${GITHUB_BASE_URL}/idlecampus-ml-service"
echo ""
echo "💡 To clone everything:"
echo "   git clone --recursive ${GITHUB_BASE_URL}/idlecampus.git"

