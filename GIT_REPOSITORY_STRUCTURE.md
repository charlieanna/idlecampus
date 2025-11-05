# Git Repository Structure - Idlecampus

## Overview

This document explains which directories are git repositories and how they should be managed on GitHub.

## Repository Types

### 1. **Existing Git Repositories** (Already have .git)

These already have their own git history and are independent repositories:

- **`adaptive-learning/`** - JavaScript adaptive learning library
  - ✅ Already has `.git/`
  - ✅ Has its own git history
  - ✅ Should be pushed to GitHub as: `idlecampus-adaptive-learning` or `adaptive-learning`

- **`adaptive-learning-gem/`** - Ruby gem adaptive learning library
  - ✅ Already has `.git/`
  - ✅ Has its own git history
  - ✅ Should be pushed to GitHub as: `idlecampus-adaptive-learning-gem` or `adaptive-learning-gem`

### 2. **New Git Repositories** (Need to be initialized)

These were copied from the monorepo and need new git repos:

- **`frontend/`** - React frontend (from `idlecampus-learning/`)
  - ❌ No `.git/` yet (or was removed during copy)
  - ⚠️ Needs: `git init` + initial commit
  - ✅ Should be pushed to GitHub as: `idlecampus-frontend`

- **`backend/`** - Rails backend (from `entry-app/SOVisits/`)
  - ❌ No `.git/` yet (or was removed during copy)
  - ⚠️ Needs: `git init` + initial commit
  - ✅ Should be pushed to GitHub as: `idlecampus-backend`

- **`ml-service/`** - Flask ML service (from `docker-python/neo_flask/`)
  - ❌ No `.git/` yet (or was removed during copy)
  - ⚠️ Needs: `git init` + initial commit
  - ✅ Should be pushed to GitHub as: `idlecampus-ml-service`

### 3. **Parent Meta-Repository**

- **`idlecampus/`** (root directory) - Parent repository
  - ⚠️ Needs: `git init` (if not done)
  - 📋 Contains: `.gitmodules` file + infrastructure files
  - ✅ Should be pushed to GitHub as: `idlecampus` (main meta-repo)

## GitHub Repository Structure

### Recommended GitHub Repositories:

```
idlecampus (main meta-repo)
├── idlecampus-frontend
├── idlecampus-backend
├── idlecampus-ml-service
├── idlecampus-adaptive-learning (or adaptive-learning)
└── idlecampus-adaptive-learning-gem (or adaptive-learning-gem)
```

## Setup Steps

### For Existing Repos (adaptive-learning, adaptive-learning-gem):

1. **Check remote:**
   ```bash
   cd adaptive-learning
   git remote -v
   ```

2. **Add GitHub remote (if not exists):**
   ```bash
   git remote add origin https://github.com/ankothari1986-ux/idlecampus-adaptive-learning.git
   ```

3. **Push to GitHub:**
   ```bash
   git push -u origin main  # or master, depending on your default branch
   ```

### For New Repos (frontend, backend, ml-service):

1. **Initialize git:**
   ```bash
   cd frontend
   git init
   git add .
   git commit -m "Initial commit - extracted from monorepo"
   ```

2. **Create GitHub repo** (via GitHub UI or gh CLI):
   ```bash
   gh repo create idlecampus-frontend --private
   ```

3. **Add remote and push:**
   ```bash
   git remote add origin https://github.com/ankothari1986-ux/idlecampus-frontend.git
   git branch -M main
   git push -u origin main
   ```

### For Parent Meta-Repo (idlecampus):

1. **Initialize if not done:**
   ```bash
   cd /Users/ankurkothari/Documents/workspace/idlecampus
   git init
   ```

2. **Set up submodules:**
   ```bash
   # Run the setup script or manually create .gitmodules
   bash setup-idlecampus-submodules.sh
   ```

3. **Create GitHub repo:**
   ```bash
   gh repo create idlecampus --private
   ```

4. **Add remote and push:**
   ```bash
   git remote add origin https://github.com/ankothari1986-ux/idlecampus.git
   git branch -M main
   git push -u origin main
   ```

## Submodule URLs in .gitmodules

After pushing to GitHub, update `.gitmodules` to use GitHub URLs instead of `file://`:

```ini
[submodule "frontend"]
    path = frontend
    url = https://github.com/ankothari1986-ux/idlecampus-frontend.git

[submodule "backend"]
    path = backend
    url = https://github.com/ankothari1986-ux/idlecampus-backend.git

[submodule "ml-service"]
    path = ml-service
    url = https://github.com/ankothari1986-ux/idlecampus-ml-service.git

[submodule "adaptive-learning"]
    path = adaptive-learning
    url = https://github.com/ankothari1986-ux/idlecampus-adaptive-learning.git

[submodule "adaptive-learning-gem"]
    path = adaptive-learning-gem
    url = https://github.com/ankothari1986-ux/idlecampus-adaptive-learning-gem.git
```

## Summary

| Directory | Git Status | GitHub Action |
|-----------|-----------|---------------|
| `idlecampus/` (parent) | Needs init | Create `idlecampus` repo |
| `frontend/` | Needs init | Create `idlecampus-frontend` repo |
| `backend/` | Needs init | Create `idlecampus-backend` repo |
| `ml-service/` | Needs init | Create `idlecampus-ml-service` repo |
| `adaptive-learning/` | ✅ Has .git | Push to `idlecampus-adaptive-learning` |
| `adaptive-learning-gem/` | ✅ Has .git | Push to `idlecampus-adaptive-learning-gem` |

## Quick Check Commands

```bash
# Check which directories have .git
cd /Users/ankurkothari/Documents/workspace/idlecampus
for dir in */; do 
    if [ -d "$dir/.git" ]; then 
        echo "✅ $dir has .git"; 
    else 
        echo "❌ $dir needs git init"; 
    fi
done

# Check parent
if [ -d ".git" ]; then echo "✅ Parent has .git"; else echo "❌ Parent needs git init"; fi
```

