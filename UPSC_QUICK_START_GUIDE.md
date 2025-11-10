# UPSC Platform - Quick Start Guide

## Overview
This guide will help you quickly set up and run the UPSC preparation module within the existing IdleCampus platform.

## Prerequisites
- PostgreSQL running (already configured)
- Rails 6.0.3
- Ruby 3.1.4
- Node.js for frontend
- Ollama installed (optional, for AI features)

## Step 1: Run Migrations

Execute the provided migration script:

```bash
cd backend
chmod +x create_upsc_migrations.sh
./create_upsc_migrations.sh
rails db:migrate
```

## Step 2: Seed Initial Data

Create a seed file for UPSC:

```bash
# This will populate:
# - UPSC Subjects (Prelims GS, CSAT, Mains GS1-4, etc.)
# - Sample Topics
# - Sample Questions
rails db:seed:upsc
```

## Step 3: Start Backend

```bash
cd backend
rails server -p 3000
```

## Step 4: Start Frontend

```bash
cd frontend
npm run dev
```

## Step 5: Access UPSC Module

Navigate to: `http://localhost:5173/upsc`

## Features Available

### Immediate (Phase 1)
- ✅ Subject browsing
- ✅ Topic navigation
- ✅ Progress tracking
- ✅ User profiles

### Week 2 (Phase 2)
- ⏳ Quiz/MCQ engine
- ⏳ Mock tests
- ⏳ Basic analytics

### Week 3-4 (Phase 3)
- ⏳ Answer writing practice
- ⏳ AI evaluation (basic)
- ⏳ Mentor review system

### Week 5-6 (Phase 4)
- ⏳ Current affairs feed
- ⏳ Study planner
- ⏳ Spaced repetition

## API Endpoints

### Subjects
- `GET /api/upsc/subjects` - List all subjects
- `GET /api/upsc/subjects/:id` - Get subject with topics

### Topics
- `GET /api/upsc/topics` - List topics
- `GET /api/upsc/topics/:id` - Get topic details

### Tests
- `GET /api/upsc/tests` - List available tests
- `POST /api/upsc/tests/:id/start` - Start a test
- `POST /api/upsc/test_attempts/:id/submit` - Submit test

### Answer Writing
- `GET /api/upsc/writing_questions` - Get daily questions
- `POST /api/upsc/user_answers` - Submit answer
- `GET /api/upsc/user_answers/:id/evaluation` - Get evaluation

### Current Affairs
- `GET /api/upsc/news_articles` - Get news feed
- `GET /api/upsc/news_articles/:id` - Get article

### Study Plan
- `GET /api/upsc/study_plans/current` - Get active study plan
- `POST /api/upsc/study_plans/generate` - Generate new plan
- `GET /api/upsc/daily_tasks` - Get today's tasks

## Environment Variables

Add to `.env`:

```bash
# UPSC Configuration
UPSC_AI_SERVICE_URL=http://localhost:8001
OLLAMA_HOST=http://localhost:11434
OLLAMA_MODEL=mistral

# Optional: OpenAI fallback
OPENAI_API_KEY=your_key_here
```

## Testing

```bash
# Backend tests
cd backend
rspec spec/models/upsc/
rspec spec/controllers/api/upsc/

# Frontend tests
cd frontend
npm test src/apps/upsc/
```

## Troubleshooting

### Migration Issues
```bash
# Reset UPSC tables only
rails db:rollback STEP=13  # Number of UPSC migrations
rails db:migrate
```

### AI Service Not Working
```bash
# Check Ollama is running
curl http://localhost:11434/api/tags

# Pull required model
ollama pull mistral
```

### Port Conflicts
```bash
# Backend (Rails)
rails server -p 3001

# Frontend (Vite)
vite --port 5174
```

## Development Workflow

1. **Create a new feature**:
   - Add migration if needed
   - Create/update models
   - Add controller endpoints
   - Create frontend components
   - Add tests

2. **Test locally**:
   - Run backend: `rails server`
   - Run frontend: `npm run dev`
   - Test endpoints with Postman/curl
   - Manual UI testing

3. **Deploy** (when ready):
   - Push to GitHub
   - Heroku/Railway auto-deploys
   - Run migrations on production
   - Seed production data

## Key Files Reference

### Backend
- **Models**: `backend/app/models/upsc/`
- **Controllers**: `backend/app/controllers/api/upsc/`
- **Migrations**: `backend/db/migrate/2025110*_create_upsc_*.rb`
- **Seeds**: `backend/db/seeds/upsc_seeds.rb`
- **Routes**: `backend/config/routes.rb`

### Frontend
- **App**: `frontend/src/apps/upsc/UpscApp.tsx`
- **Components**: `frontend/src/apps/upsc/components/`
- **Services**: `frontend/src/services/upscApi.ts`
- **Types**: `frontend/src/types/upsc.ts`

## Next Steps

1. ✅ Complete all migrations
2. ✅ Create all models
3. ⏳ Implement API controllers
4. ⏳ Build frontend components
5. ⏳ Add AI integration
6. ⏳ Seed sample data
7. ⏳ Testing & refinement

## Resources

- [UPSC Official Website](https://upsc.gov.in/)
- [Detailed Syllabus](https://upsc.gov.in/sites/default/files/Syllabus_CSE.pdf)
- [Previous Year Papers](https://upsc.gov.in/examinations/previous-question-papers)
- [Platform Architecture](./UPSC_PLATFORM_ARCHITECTURE.md)
- [Integration Plan](./UPSC_INTEGRATION_PLAN.md)

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review the integration plan document
3. Check Rails logs: `tail -f backend/log/development.log`
4. Check browser console for frontend errors
