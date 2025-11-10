# 🤖 Ollama AI Integration - Setup Guide

## 🎉 Ollama AI is Now Integrated!

Your UPSC platform now has AI-powered features using Ollama for:
- ✅ Answer evaluation with detailed feedback
- ✅ Concept explanations
- ✅ Practice question generation
- ✅ Study plan suggestions

---

## 🚀 Quick Start (3 Options)

### Option 1: Docker (Recommended - Easiest)

```bash
# Start Ollama with Docker Compose
docker-compose -f docker-compose.ollama.yml up -d

# Wait for Ollama to start (30 seconds)
sleep 30

# Pull the model
docker exec upsc_ollama ollama pull llama3.2

# Verify it's working
curl http://localhost:11434/api/tags
```

**Done!** Ollama is running on `http://localhost:11434`

### Option 2: macOS/Linux Native Installation

```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Start Ollama service
ollama serve &

# Pull the model
ollama pull llama3.2

# Verify
ollama list
```

### Option 3: Download from Website

1. Visit: https://ollama.com/download
2. Download for your OS
3. Install and run
4. Pull model: `ollama pull llama3.2`

---

## 📋 Supported Models

**Recommended for UPSC**:
- ✅ `llama3.2` (Default - 3B params, fast, good quality)
- ✅ `llama3.1:8b` (8B params, better quality, slower)
- ✅ `mistral` (7B params, excellent for evaluation)
- ✅ `gemma2:9b` (9B params, very accurate)

**Pull a model**:
```bash
ollama pull llama3.2
# or
ollama pull mistral
```

**List installed models**:
```bash
ollama list
```

**Switch model** (set environment variable):
```bash
export OLLAMA_MODEL=mistral
# or add to .env file:
echo "OLLAMA_MODEL=mistral" >> backend/.env
```

---

## 🔧 Configuration

### Backend Environment Variables

Add to `backend/.env`:

```bash
# Ollama Configuration
OLLAMA_URL=http://localhost:11434
OLLAMA_MODEL=llama3.2

# Optional: Increase timeout for larger models
OLLAMA_TIMEOUT=120
```

### Verify Installation

```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# Test via Rails console
cd backend
rails console

# In console:
OllamaService.available?
# => true

OllamaService.list_models
# => ["llama3.2:latest", ...]
```

---

## 🎯 Features Implemented

### 1. Answer Evaluation

**Automatic evaluation when submitting answers**

```bash
# API Endpoint
POST /api/v1/upsc/user_answers?auto_evaluate=true

# Body:
{
  "upsc_writing_question_id": 1,
  "answer_text": "Your answer here...",
  "word_count": 250,
  "time_taken_minutes": 30
}

# Response includes AI evaluation:
{
  "success": true,
  "data": {
    "user_answer": {
      "id": 1,
      "score": 85,
      "status": "evaluated",
      "ai_evaluation": {
        "overall_score": 85,
        "content_coverage": 88,
        "structure": 82,
        "language_quality": 87,
        "presentation": 80,
        "strengths": [
          "Well-structured introduction",
          "Good use of examples",
          "Clear conclusion"
        ],
        "weaknesses": [
          "Could expand on point 2",
          "Missing recent data"
        ],
        "suggestions": [
          "Include 2024 statistics",
          "Add government scheme references"
        ],
        "detailed_feedback": "Comprehensive feedback...",
        "key_points_covered": 7,
        "key_points_missed": ["Point about sustainability"]
      }
    }
  }
}
```

### 2. Request Evaluation Manually

```bash
# For previously submitted answers
POST /api/v1/upsc/user_answers/:id/request_evaluation
```

### 3. AI Status Check

```bash
GET /api/v1/upsc/ai/status

# Response:
{
  "success": true,
  "data": {
    "available": true,
    "url": "http://localhost:11434",
    "model": "llama3.2",
    "models_available": ["llama3.2:latest", "mistral:latest"],
    "status": "online"
  }
}
```

### 4. Explain Concepts

```bash
POST /api/v1/upsc/ai/explain

# Body:
{
  "topic": "Indian Federalism",
  "difficulty": "medium"
}

# Response: AI-generated explanation
```

### 5. Generate Practice Questions

```bash
POST /api/v1/upsc/ai/generate_questions

# Body:
{
  "topic": "Article 370",
  "question_type": "mcq",
  "count": 5
}

# Response: 5 AI-generated MCQ questions
```

### 6. Study Plan Suggestions

```bash
POST /api/v1/upsc/ai/study_plan_suggestions

# Body:
{
  "target_date": "2025-06-15",
  "current_level": "beginner",
  "subjects": ["Polity", "History", "Geography"],
  "hours_per_day": 8
}

# Response: AI-generated study plan
```

---

## 🧪 Testing

### Test 1: Verify Ollama is Running

```bash
curl http://localhost:11434/api/tags | jq
```

**Expected**: JSON with list of models

### Test 2: Test via Rails Console

```bash
cd backend
rails console

# Test availability
OllamaService.available?
# => true

# Test evaluation
result = OllamaService.evaluate_answer(
  answer_text: "India is a federal country with quasi-federal features...",
  question_text: "Discuss the federal structure of India",
  word_limit: 250
)

puts result
# => { "overall_score" => 75, "strengths" => [...], ... }
```

### Test 3: Test via API

```bash
# Check status
curl http://localhost:3000/api/v1/upsc/ai/status | jq

# Explain concept
curl -X POST http://localhost:3000/api/v1/upsc/ai/explain \
  -H "Content-Type: application/json" \
  -d '{"topic": "Monsoon in India", "difficulty": "easy"}' | jq

# Generate questions
curl -X POST http://localhost:3000/api/v1/upsc/ai/generate_questions \
  -H "Content-Type: application/json" \
  -d '{"topic": "Climate Change", "question_type": "mcq", "count": 3}' | jq
```

---

## 🎨 Evaluation Criteria

The AI evaluates answers on:

1. **Overall Score** (0-100): Aggregate score
2. **Content Coverage** (0-100): How well key points are covered
3. **Structure** (0-100): Organization and flow
4. **Language Quality** (0-100): Grammar, vocabulary, clarity
5. **Presentation** (0-100): Formatting and readability

Plus detailed feedback:
- ✅ **Strengths**: What was done well
- ❌ **Weaknesses**: Areas needing improvement
- 💡 **Suggestions**: Specific improvement tips
- 📝 **Detailed Feedback**: Paragraph-form analysis
- ✓ **Key Points Covered**: Number of key points addressed
- ✗ **Key Points Missed**: Missing important points

---

## 🔄 Fallback Behavior

**If Ollama is not available**:
- Answers are saved with status `submitted`
- User can request evaluation later
- System provides helpful error messages
- No data is lost

**Graceful degradation**:
```ruby
# Controller automatically falls back if Ollama fails
# User gets:
{
  "success": false,
  "error": "AI evaluation service unavailable. Answer saved for later evaluation.",
  "fallback": true
}
```

---

## 📊 Performance Tips

### For Fast Evaluation (Development)

```bash
# Use smaller model
export OLLAMA_MODEL=llama3.2  # ~2-3 seconds per evaluation
```

### For Better Quality (Production)

```bash
# Use larger model
export OLLAMA_MODEL=mistral  # ~5-10 seconds, much better quality
```

### Batch Processing

For evaluating multiple answers:
```ruby
# In background job
answers.each do |answer|
  begin
    evaluate_with_ai(answer)
  rescue => e
    Rails.logger.error("Evaluation failed for answer #{answer.id}: #{e.message}")
  end
end
```

---

## 🐛 Troubleshooting

### Issue: "Connection refused"

**Cause**: Ollama not running

**Fix**:
```bash
# Check if running
curl http://localhost:11434/api/tags

# If not, start it
docker-compose -f docker-compose.ollama.yml up -d
# or
ollama serve &
```

### Issue: "Model not found"

**Cause**: Model not pulled

**Fix**:
```bash
ollama pull llama3.2
```

### Issue: "Timeout error"

**Cause**: Model too large for available memory

**Fix**:
```bash
# Switch to smaller model
export OLLAMA_MODEL=llama3.2

# Or increase timeout in backend/.env
OLLAMA_TIMEOUT=300
```

### Issue: "Out of memory"

**Cause**: Not enough RAM for model

**Fix**:
- Use smaller model (llama3.2 needs ~2GB)
- Close other applications
- Use quantized models: `ollama pull llama3.2:latest-q4_0`

---

## 📈 Resource Requirements

| Model | RAM Required | Speed | Quality |
|-------|--------------|-------|---------|
| llama3.2 | 2-3 GB | Fast (2-3s) | Good |
| mistral | 5-6 GB | Medium (5-10s) | Excellent |
| llama3.1:8b | 6-8 GB | Medium (5-10s) | Excellent |
| gemma2:9b | 8-10 GB | Slow (10-15s) | Best |

**Recommendation for Development**: `llama3.2`
**Recommendation for Production**: `mistral` or `llama3.1:8b`

---

## 🔐 Security Notes

1. **Ollama runs locally** - No data sent to external services
2. **Student answers stay private** - All processing on your server
3. **No API keys needed** - Completely free and open source
4. **GDPR compliant** - Data never leaves your infrastructure

---

## 🚀 Production Deployment

### Docker Compose (Full Stack)

```yaml
# docker-compose.production.yml
version: '3.8'

services:
  rails:
    build: ./backend
    environment:
      - OLLAMA_URL=http://ollama:11434
      - OLLAMA_MODEL=mistral
    depends_on:
      - ollama
      - postgres

  ollama:
    image: ollama/ollama:latest
    volumes:
      - ollama_data:/root/.ollama
    ports:
      - "11434:11434"
    deploy:
      resources:
        limits:
          memory: 8G

  postgres:
    image: postgres:15
    # ... postgres config

volumes:
  ollama_data:
```

### Systemd Service (Linux)

```ini
# /etc/systemd/system/ollama.service
[Unit]
Description=Ollama Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/ollama serve
Restart=always
User=ollama
Environment="OLLAMA_HOST=0.0.0.0"

[Install]
WantedBy=multi-user.target
```

---

## 📞 API Endpoints Summary

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/upsc/ai/status` | GET | Check Ollama status |
| `/api/v1/upsc/ai/explain` | POST | Get concept explanations |
| `/api/v1/upsc/ai/generate_questions` | POST | Generate practice questions |
| `/api/v1/upsc/ai/study_plan_suggestions` | POST | Get study plan AI suggestions |
| `/api/v1/upsc/user_answers?auto_evaluate=true` | POST | Submit answer with auto-evaluation |
| `/api/v1/upsc/user_answers/:id/request_evaluation` | POST | Request evaluation for existing answer |

---

## ✅ What's Working Now

1. ✅ **Automatic answer evaluation** - AI grades answers with detailed feedback
2. ✅ **Concept explanations** - AI explains UPSC topics
3. ✅ **Question generation** - AI creates practice questions
4. ✅ **Study plan suggestions** - AI recommends study strategies
5. ✅ **Fallback handling** - Graceful degradation if Ollama unavailable
6. ✅ **Multiple model support** - Switch between different AI models
7. ✅ **Error recovery** - Robust error handling

---

## 🎯 Next Steps

1. **Start Ollama**: `docker-compose -f docker-compose.ollama.yml up -d`
2. **Pull model**: `docker exec upsc_ollama ollama pull llama3.2`
3. **Test status**: `curl http://localhost:3000/api/v1/upsc/ai/status`
4. **Start using**: Submit answers with `?auto_evaluate=true`

---

## 📚 Additional Resources

- **Ollama Docs**: https://ollama.com/docs
- **Model Library**: https://ollama.com/library
- **GitHub**: https://github.com/ollama/ollama

---

**Created by**: Claude (Anthropic)
**Date**: November 6, 2025
**Status**: ✅ Fully Integrated and Ready to Use

🎉 **AI-powered UPSC preparation is now live!**
