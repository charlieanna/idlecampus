# Idlecampus Platform

Meta-repository managing all Idlecampus services as git submodules.

## Structure

- `frontend/` - React frontend application
- `backend/` - Rails backend API
- `ml-service/` - Flask ML service
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

