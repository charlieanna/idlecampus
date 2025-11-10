# UPSC Platform - Integration Plan with IdleCampus

## Current System Analysis

### Backend (Rails 6.0.3)
- **Database**: PostgreSQL (migrated from SQLite)
- **Existing Models**: User, Course, CourseModule, Lesson, Quiz, Achievement, Lab Sessions
- **Architecture**: Modular course system with enrollments, progress tracking, achievements
- **Frontend Integration**: React-Rails with API endpoints

### Frontend (React + TypeScript + Vite)
- **Framework**: React 18 with TypeScript
- **Routing**: React Router v7
- **Existing Apps**: Docker, Kubernetes, Linux, Security, Coding Interview, System Design, Python, Golang, IIT-JEE
- **UI**: Tailwind CSS, Framer Motion animations
- **Components**: ProgressiveModuleViewer, CourseSelectionDashboard

## Integration Strategy

### Approach: Add UPSC as a New "App" within IdleCampus

Instead of creating a separate platform, we'll integrate UPSC preparation as a specialized app within the existing IdleCampus infrastructure, similar to how Docker, Kubernetes, and IIT-JEE are implemented.

### Benefits:
1. **Reuse existing infrastructure** (authentication, course management, progress tracking)
2. **Leverage existing UI components** (module viewers, progress dashboards)
3. **Unified user experience** across all learning domains
4. **Faster development** by extending proven patterns
5. **Shared features** (gamification, achievements, analytics)

## Phase 1: Database Schema Extension

### New UPSC-Specific Tables

```ruby
# 1. UPSC Subjects (extends existing Course model)
class CreateUpscSubjects < ActiveRecord::Migration[6.0]
  def change
    create_table :upsc_subjects do |t|
      t.string :name, null: false
      t.string :code, null: false, index: { unique: true }
      t.string :exam_type, null: false # prelims, mains, both
      t.integer :paper_number
      t.integer :total_marks
      t.integer :duration_minutes
      t.text :description
      t.string :syllabus_pdf_url
      t.boolean :is_optional, default: false
      t.boolean :is_active, default: true
      t.integer :order_index
      t.string :icon_url
      t.string :color_code
      t.timestamps
    end

    add_index :upsc_subjects, :exam_type
    add_index :upsc_subjects, :is_optional
  end
end

# 2. UPSC Topics (hierarchical, links to Course Modules/Lessons)
class CreateUpscTopics < ActiveRecord::Migration[6.0]
  def change
    create_table :upsc_topics do |t|
      t.references :upsc_subject, foreign_key: true, null: false
      t.references :parent_topic, foreign_key: { to_table: :upsc_topics }
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :difficulty_level # beginner, intermediate, advanced
      t.decimal :estimated_hours, precision: 5, scale: 2
      t.integer :order_index
      t.boolean :is_high_yield, default: false
      t.integer :pyq_frequency, default: 0
      t.text :tags, array: true, default: []
      t.text :learning_objectives, array: true, default: []
      t.bigint :prerequisite_topic_ids, array: true, default: []

      # Link to existing course system
      t.references :course_lesson, foreign_key: true
      t.references :course_module, foreign_key: true

      t.timestamps
    end

    add_index :upsc_topics, :slug
    add_index :upsc_topics, :difficulty_level
    add_index :upsc_topics, :is_high_yield
  end
end

# 3. UPSC Student Profiles (extends existing User model)
class CreateUpscStudentProfiles < ActiveRecord::Migration[6.0]
  def change
    create_table :upsc_student_profiles do |t|
      t.references :user, foreign_key: true, null: false, index: { unique: true }
      t.date :target_exam_date
      t.integer :attempt_number, default: 1
      t.references :optional_subject, foreign_key: { to_table: :upsc_subjects }
      t.string :medium_of_exam, default: 'english'
      t.jsonb :previous_attempt_details, default: {}
      t.text :educational_background
      t.string :current_occupation
      t.text :work_experience
      t.integer :study_hours_per_day
      t.string :preferred_study_time
      t.jsonb :daf_details, default: {} # For interview prep
      t.text :strengths, array: true, default: []
      t.text :weaknesses, array: true, default: []
      t.text :goals
      t.timestamps
    end
  end
end

# 4. UPSC Questions (extends existing quiz system)
class CreateUpscQuestions < ActiveRecord::Migration[6.0]
  def change
    create_table :upsc_questions do |t|
      t.references :upsc_subject, foreign_key: true
      t.references :upsc_topic, foreign_key: true
      t.string :question_type, null: false # mcq, msq, tf, assertion_reason
      t.string :difficulty # easy, medium, hard
      t.decimal :marks, precision: 5, scale: 2, default: 1.0
      t.decimal :negative_marks, precision: 5, scale: 2, default: 0
      t.integer :time_limit_seconds
      t.text :question_text, null: false
      t.string :question_image_url
      t.jsonb :options # [{id: 'A', text: '...', is_correct: true/false}]
      t.text :correct_answer, null: false
      t.text :explanation
      t.string :explanation_video_url
      t.text :hints, array: true, default: []
      t.integer :pyq_year # Previous Year Question
      t.string :pyq_paper
      t.integer :pyq_question_number
      t.string :source
      t.text :tags, array: true, default: []
      t.integer :relevance_score, default: 50
      t.integer :attempt_count, default: 0
      t.integer :correct_attempt_count, default: 0
      t.integer :average_time_taken_seconds
      t.string :status, default: 'active'
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :upsc_questions, :question_type
    add_index :upsc_questions, :difficulty
    add_index :upsc_questions, :pyq_year
  end
end

# 5. UPSC Tests (mock exams)
class CreateUpscTests < ActiveRecord::Migration[6.0]
  def change
    create_table :upsc_tests do |t|
      t.string :test_type, null: false # mock_prelims, mock_mains, topic_test, subject_test
      t.string :title, null: false
      t.text :description
      t.text :instructions
      t.references :upsc_subject, foreign_key: true
      t.integer :duration_minutes, null: false
      t.decimal :total_marks, precision: 7, scale: 2, null: false
      t.decimal :passing_marks, precision: 7, scale: 2
      t.boolean :negative_marking_enabled, default: true
      t.decimal :negative_marking_ratio, precision: 3, scale: 2, default: 0.33
      t.boolean :is_live, default: false
      t.boolean :is_free, default: false
      t.datetime :scheduled_at
      t.datetime :starts_at
      t.datetime :ends_at
      t.datetime :result_publish_at
      t.integer :max_attempts, default: 1
      t.boolean :shuffle_questions, default: true
      t.boolean :shuffle_options, default: true
      t.boolean :show_answers_after_submit, default: true
      t.string :difficulty_level
      t.text :tags, array: true, default: []
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :upsc_tests, :test_type
    add_index :upsc_tests, :scheduled_at
  end
end

# 6. Test Questions (join table)
class CreateUpscTestQuestions < ActiveRecord::Migration[6.0]
  def change
    create_table :upsc_test_questions do |t|
      t.references :upsc_test, foreign_key: true, null: false
      t.references :upsc_question, foreign_key: true, null: false
      t.decimal :marks, precision: 5, scale: 2, null: false
      t.decimal :negative_marks, precision: 5, scale: 2, default: 0
      t.integer :order_index, null: false
      t.string :section
      t.timestamps
    end

    add_index :upsc_test_questions, [:upsc_test_id, :upsc_question_id], unique: true, name: 'index_test_questions_unique'
  end
end

# 7. User Test Attempts
class CreateUpscUserTestAttempts < ActiveRecord::Migration[6.0]
  def change
    create_table :upsc_user_test_attempts do |t|
      t.references :user, foreign_key: true, null: false
      t.references :upsc_test, foreign_key: true, null: false
      t.integer :attempt_number, default: 1
      t.datetime :started_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime :submitted_at
      t.integer :time_taken_minutes
      t.decimal :score, precision: 7, scale: 2
      t.decimal :percentage, precision: 5, scale: 2
      t.decimal :percentile, precision: 5, scale: 2
      t.integer :rank
      t.integer :total_questions
      t.integer :correct_answers, default: 0
      t.integer :wrong_answers, default: 0
      t.integer :unanswered, default: 0
      t.jsonb :answers, default: {}
      t.jsonb :question_wise_time, default: {}
      t.jsonb :analysis, default: {}
      t.string :status, default: 'in_progress'
      t.timestamps
    end

    add_index :upsc_user_test_attempts, :status
    add_index :upsc_user_test_attempts, :submitted_at
  end
end

# 8. Writing Questions (Mains Answer Writing)
class CreateUpscWritingQuestions < ActiveRecord::Migration[6.0]
  def change
    create_table :upsc_writing_questions do |t|
      t.references :upsc_subject, foreign_key: true
      t.references :upsc_topic, foreign_key: true
      t.string :question_type # essay, case_study, general, analytical
      t.text :question_text, null: false
      t.text :question_context
      t.integer :word_limit
      t.decimal :marks, precision: 5, scale: 2, default: 10.0
      t.integer :time_limit_minutes
      t.string :difficulty
      t.text :directive_keywords, array: true, default: []
      t.jsonb :evaluation_criteria
      t.text :model_answer
      t.string :model_answer_url
      t.text :key_points, array: true, default: []
      t.jsonb :suggested_structure
      t.integer :pyq_year
      t.string :pyq_paper
      t.text :tags, array: true, default: []
      t.date :current_affairs_date
      t.integer :relevance_score, default: 50
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :upsc_writing_questions, :question_type
    add_index :upsc_writing_questions, :pyq_year
  end
end

# 9. User Answers (Answer Writing Submissions)
class CreateUpscUserAnswers < ActiveRecord::Migration[6.0]
  def change
    create_table :upsc_user_answers do |t|
      t.references :user, foreign_key: true, null: false
      t.references :upsc_writing_question, foreign_key: true, null: false
      t.text :answer_text, null: false
      t.integer :word_count
      t.integer :time_taken_minutes
      t.string :submission_type, default: 'typed' # typed, uploaded
      t.string :file_url
      t.datetime :submitted_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.jsonb :ai_evaluation
      t.decimal :ai_score, precision: 5, scale: 2
      t.datetime :ai_evaluated_at
      t.jsonb :mentor_evaluation
      t.decimal :mentor_score, precision: 5, scale: 2
      t.datetime :mentor_evaluated_at
      t.references :evaluator, foreign_key: { to_table: :users }
      t.decimal :final_score, precision: 5, scale: 2
      t.string :status, default: 'submitted'
      t.integer :revision_number, default: 1
      t.references :original_answer, foreign_key: { to_table: :upsc_user_answers }
      t.boolean :is_public, default: false
      t.integer :like_count, default: 0
      t.timestamps
    end

    add_index :upsc_user_answers, :status
    add_index :upsc_user_answers, :submitted_at
  end
end

# 10. Current Affairs / News Articles
class CreateUpscNewsArticles < ActiveRecord::Migration[6.0]
  def change
    create_table :upsc_news_articles do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :summary
      t.text :full_content, null: false
      t.string :source
      t.string :source_url
      t.string :author
      t.date :published_date, null: false
      t.text :categories, array: true, default: []
      t.text :tags, array: true, default: []
      t.integer :relevance_score, default: 50
      t.string :importance_level # low, medium, high, critical
      t.boolean :is_featured, default: false
      t.string :image_url
      t.bigint :related_topic_ids, array: true, default: []
      t.bigint :related_subject_ids, array: true, default: []
      t.text :exam_perspective
      t.text :key_points, array: true, default: []
      t.integer :view_count, default: 0
      t.integer :like_count, default: 0
      t.string :status, default: 'published'
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :upsc_news_articles, :slug, unique: true
    add_index :upsc_news_articles, :published_date
    add_index :upsc_news_articles, :categories, using: :gin
    add_index :upsc_news_articles, :tags, using: :gin
  end
end

# 11. Study Plans
class CreateUpscStudyPlans < ActiveRecord::Migration[6.0]
  def change
    create_table :upsc_study_plans do |t|
      t.references :user, foreign_key: true, null: false
      t.string :plan_name
      t.date :start_date, null: false
      t.date :target_exam_date, null: false
      t.integer :total_days
      t.jsonb :phase_breakdown
      t.jsonb :daily_schedule
      t.boolean :is_active, default: true
      t.integer :completion_percentage, default: 0
      t.timestamps
    end

    add_index :upsc_study_plans, [:user_id, :is_active]
  end
end

# 12. Daily Tasks
class CreateUpscDailyTasks < ActiveRecord::Migration[6.0]
  def change
    create_table :upsc_daily_tasks do |t|
      t.references :user, foreign_key: true, null: false
      t.references :upsc_study_plan, foreign_key: true
      t.date :task_date, null: false
      t.string :task_type # study, practice, test, revision
      t.string :title, null: false
      t.text :description
      t.references :upsc_topic, foreign_key: true
      t.integer :estimated_minutes
      t.integer :actual_minutes
      t.string :priority, default: 'medium'
      t.string :status, default: 'pending'
      t.datetime :completed_at
      t.text :notes
      t.timestamps
    end

    add_index :upsc_daily_tasks, [:user_id, :task_date]
    add_index :upsc_daily_tasks, :status
  end
end

# 13. Revisions (Spaced Repetition)
class CreateUpscRevisions < ActiveRecord::Migration[6.0]
  def change
    create_table :upsc_revisions do |t|
      t.references :user, foreign_key: true, null: false
      t.references :upsc_topic, foreign_key: true
      t.string :revision_type # scheduled, manual, triggered
      t.date :scheduled_for, null: false
      t.datetime :completed_at
      t.integer :interval_index, default: 0
      t.integer :performance_rating # 1-5
      t.integer :time_spent_minutes
      t.text :notes
      t.string :status, default: 'pending'
      t.timestamps
    end

    add_index :upsc_revisions, [:user_id, :scheduled_for]
    add_index :upsc_revisions, :status
  end
end

# 14. User Progress (extends existing progress tracking)
class CreateUpscUserProgress < ActiveRecord::Migration[6.0]
  def change
    create_table :upsc_user_progress do |t|
      t.references :user, foreign_key: true, null: false
      t.references :upsc_topic, foreign_key: true, null: false
      t.string :status, default: 'not_started'
      t.integer :completion_percentage, default: 0
      t.integer :confidence_level # 1-5
      t.integer :time_spent_minutes, default: 0
      t.datetime :last_accessed_at
      t.datetime :first_started_at
      t.datetime :completed_at
      t.datetime :mastered_at
      t.text :notes
      t.boolean :bookmarked, default: false
      t.integer :revision_count, default: 0
      t.datetime :last_revised_at
      t.timestamps
    end

    add_index :upsc_user_progress, [:user_id, :upsc_topic_id], unique: true, name: 'index_upsc_user_progress_unique'
    add_index :upsc_user_progress, :status
  end
end
```

### Linking with Existing Models

```ruby
# In app/models/user.rb - Add UPSC associations
class User < ApplicationRecord
  # ... existing associations ...

  # UPSC associations
  has_one :upsc_student_profile, class_name: 'Upsc::StudentProfile', dependent: :destroy
  has_many :upsc_user_test_attempts, class_name: 'Upsc::UserTestAttempt', dependent: :destroy
  has_many :upsc_user_answers, class_name: 'Upsc::UserAnswer', dependent: :destroy
  has_many :upsc_study_plans, class_name: 'Upsc::StudyPlan', dependent: :destroy
  has_many :upsc_daily_tasks, class_name: 'Upsc::DailyTask', dependent: :destroy
  has_many :upsc_revisions, class_name: 'Upsc::Revision', dependent: :destroy
  has_many :upsc_user_progress, class_name: 'Upsc::UserProgress', dependent: :destroy
end
```

## Phase 2: Rails Models Implementation

Create models in `backend/app/models/upsc/` directory:

```ruby
# app/models/upsc/subject.rb
module Upsc
  class Subject < ApplicationRecord
    self.table_name = 'upsc_subjects'

    has_many :topics, class_name: 'Upsc::Topic', foreign_key: 'upsc_subject_id', dependent: :destroy
    has_many :questions, class_name: 'Upsc::Question', foreign_key: 'upsc_subject_id', dependent: :nullify
    has_many :tests, class_name: 'Upsc::Test', foreign_key: 'upsc_subject_id', dependent: :nullify
    has_many :writing_questions, class_name: 'Upsc::WritingQuestion', foreign_key: 'upsc_subject_id', dependent: :nullify

    validates :name, presence: true
    validates :code, presence: true, uniqueness: true
    validates :exam_type, inclusion: { in: %w[prelims mains both] }

    scope :prelims, -> { where(exam_type: ['prelims', 'both']) }
    scope :mains, -> { where(exam_type: ['mains', 'both']) }
    scope :optional, -> { where(is_optional: true) }
    scope :active, -> { where(is_active: true) }
    scope :ordered, -> { order(:order_index) }
  end
end

# app/models/upsc/topic.rb
module Upsc
  class Topic < ApplicationRecord
    self.table_name = 'upsc_topics'

    belongs_to :subject, class_name: 'Upsc::Subject', foreign_key: 'upsc_subject_id'
    belongs_to :parent_topic, class_name: 'Upsc::Topic', optional: true
    belongs_to :course_lesson, class_name: 'CourseLesson', optional: true
    belongs_to :course_module, class_name: 'CourseModule', optional: true

    has_many :child_topics, class_name: 'Upsc::Topic', foreign_key: 'parent_topic_id', dependent: :destroy
    has_many :user_progress, class_name: 'Upsc::UserProgress', foreign_key: 'upsc_topic_id', dependent: :destroy
    has_many :questions, class_name: 'Upsc::Question', foreign_key: 'upsc_topic_id', dependent: :nullify
    has_many :writing_questions, class_name: 'Upsc::WritingQuestion', foreign_key: 'upsc_topic_id', dependent: :nullify
    has_many :revisions, class_name: 'Upsc::Revision', foreign_key: 'upsc_topic_id', dependent: :destroy

    validates :name, presence: true
    validates :slug, presence: true, uniqueness: { scope: :upsc_subject_id }

    before_validation :generate_slug

    scope :root_topics, -> { where(parent_topic_id: nil) }
    scope :high_yield, -> { where(is_high_yield: true) }
    scope :ordered, -> { order(:order_index) }

    def full_path
      path = [name]
      current = self
      while current.parent_topic
        current = current.parent_topic
        path.unshift(current.name)
      end
      path.join(' > ')
    end

    private

    def generate_slug
      self.slug = name.parameterize if name.present? && slug.blank?
    end
  end
end

# Continue with other models...
```

## Phase 3: API Controllers

Create controllers in `backend/app/controllers/api/upsc/` directory:

```ruby
# app/controllers/api/upsc/subjects_controller.rb
module Api
  module Upsc
    class SubjectsController < ApplicationController
      def index
        @subjects = ::Upsc::Subject.active.ordered
        render json: @subjects
      end

      def show
        @subject = ::Upsc::Subject.find(params[:id])
        @topics = @subject.topics.root_topics.ordered
        render json: {
          subject: @subject,
          topics: @topics
        }
      end
    end
  end
end

# app/controllers/api/upsc/tests_controller.rb
module Api
  module Upsc
    class TestsController < ApplicationController
      before_action :authenticate_user!

      def index
        @tests = ::Upsc::Test.live.order(scheduled_at: :desc)
        render json: @tests
      end

      def show
        @test = ::Upsc::Test.find(params[:id])
        render json: @test.as_json(include: { test_questions: { include: :question } })
      end

      def start
        @test = ::Upsc::Test.find(params[:id])
        @attempt = current_user.upsc_user_test_attempts.create!(
          upsc_test: @test,
          attempt_number: calculate_attempt_number,
          started_at: Time.current
        )
        render json: @attempt
      end

      def submit
        @attempt = current_user.upsc_user_test_attempts.find(params[:id])
        @attempt.submit_test!
        render json: @attempt.reload
      end

      private

      def calculate_attempt_number
        current_user.upsc_user_test_attempts
          .where(upsc_test_id: params[:id])
          .maximum(:attempt_number).to_i + 1
      end
    end
  end
end
```

## Phase 4: Frontend Integration

### 1. Create UPSC App Structure

```bash
frontend/src/apps/upsc/
├── UpscApp.tsx              # Main UPSC app component
├── Dashboard.tsx            # Student dashboard
├── Subjects.tsx             # Subject listing
├── SubjectView.tsx          # Individual subject view
├── Topics.tsx               # Topic listing
├── TopicView.tsx            # Topic content viewer
├── Tests/
│   ├── TestList.tsx         # Available tests
│   ├── TestPlayer.tsx       # Test taking interface
│   └── TestResults.tsx      # Results and analysis
├── AnswerWriting/
│   ├── QuestionList.tsx     # Daily answer practice
│   ├── AnswerEditor.tsx     # Rich text editor
│   └── Evaluation.tsx       # AI/Mentor feedback
├── CurrentAffairs/
│   ├── NewsFeed.tsx         # Daily news
│   ├── ArticleView.tsx      # Full article
│   └── CAQuiz.tsx           # Current affairs quiz
├── StudyPlanner/
│   ├── PlanView.tsx         # Study plan overview
│   ├── DailyTasks.tsx       # Today's tasks
│   └── Calendar.tsx         # Calendar view
└── components/
    ├── ProgressTracker.tsx
    ├── StreakCounter.tsx
    └── PerformanceChart.tsx
```

### 2. Update AppRouter.tsx

```typescript
// frontend/src/AppRouter.tsx
import UpscApp from './apps/upsc/UpscApp';

// Add to Routes
<Route path="/upsc/*" element={<UpscApp />} />
```

### 3. UPSC Main App Component

```typescript
// frontend/src/apps/upsc/UpscApp.tsx
import { Routes, Route } from 'react-router-dom';
import Dashboard from './Dashboard';
import SubjectsList from './Subjects';
import TestList from './Tests/TestList';
import AnswerWriting from './AnswerWriting/QuestionList';
import CurrentAffairs from './CurrentAffairs/NewsFeed';

export default function UpscApp() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50">
      <Routes>
        <Route index element={<Dashboard />} />
        <Route path="subjects" element={<SubjectsList />} />
        <Route path="subjects/:id" element={<SubjectView />} />
        <Route path="tests" element={<TestList />} />
        <Route path="tests/:id" element={<TestPlayer />} />
        <Route path="answer-writing" element={<AnswerWriting />} />
        <Route path="current-affairs" element={<CurrentAffairs />} />
        <Route path="study-plan" element={<StudyPlanner />} />
      </Routes>
    </div>
  );
}
```

## Phase 5: AI Integration (Ollama)

### Setup Docker Compose for Ollama

```yaml
# docker-compose.yml
services:
  ollama:
    image: ollama/ollama:latest
    container_name: upsc_ai
    volumes:
      - ollama_data:/root/.ollama
    ports:
      - "11434:11434"
    restart: unless-stopped

  ai_service:
    build: ./ai_service
    container_name: upsc_ai_service
    depends_on:
      - ollama
    environment:
      - OLLAMA_HOST=http://ollama:11434
    ports:
      - "8001:8000"
    volumes:
      - ./ai_service:/app
    restart: unless-stopped

volumes:
  ollama_data:
```

### Python AI Service (FastAPI)

```python
# ai_service/main.py
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import httpx
import json
import os

app = FastAPI()

OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")
MODEL_NAME = "mistral"  # or llama2, codellama, etc.

class AnswerEvaluationRequest(BaseModel):
    question: str
    answer: str
    word_limit: int
    marks: float
    evaluation_criteria: dict = None

class AnswerEvaluationResponse(BaseModel):
    relevance_score: float
    structure_score: float
    content_depth_score: float
    examples_score: float
    language_score: float
    critical_analysis_score: float
    total_score: float
    strengths: list[str]
    improvements: list[str]
    suggested_additions: list[str]
    detailed_feedback: str

@app.post("/api/v1/evaluate_answer", response_model=AnswerEvaluationResponse)
async def evaluate_answer(request: AnswerEvaluationRequest):
    prompt = f"""
You are an expert UPSC CSE evaluator. Evaluate the following answer:

Question: {request.question}
Word Limit: {request.word_limit}
Marks: {request.marks}

Answer:
{request.answer}

Evaluate based on:
1. Relevance to Question (0-10)
2. Structure & Organization (0-10)
3. Content Depth & Coverage (0-10)
4. Use of Examples/Data (0-10)
5. Language & Clarity (0-10)
6. Critical Analysis (0-10)

Provide:
- Individual scores
- Total score out of 60
- Top 3 strengths
- Top 3 areas for improvement
- Suggested additions (specific examples, data, or perspectives)
- Detailed feedback paragraph

Response format as JSON.
"""

    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{OLLAMA_HOST}/api/generate",
                json={
                    "model": MODEL_NAME,
                    "prompt": prompt,
                    "stream": False
                },
                timeout=60.0
            )

            result = response.json()
            evaluation_text = result["response"]

            # Parse JSON from response
            evaluation = json.loads(evaluation_text)

            return AnswerEvaluationResponse(**evaluation)

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
```

## Implementation Timeline

### Week 1-2: Database & Models
- [ ] Create all migrations
- [ ] Implement UPSC models
- [ ] Seed initial data (subjects, topics)
- [ ] Test model relationships

### Week 3-4: API Controllers
- [ ] Implement CRUD controllers
- [ ] Add authentication/authorization
- [ ] Create serializers
- [ ] API documentation

### Week 5-6: Frontend Foundation
- [ ] Create UPSC app structure
- [ ] Build dashboard
- [ ] Implement subject/topic browsers
- [ ] Add progress tracking UI

### Week 7-8: Test Engine
- [ ] Test player interface
- [ ] Answer submission
- [ ] Results and analytics
- [ ] Leaderboards

### Week 9-10: Answer Writing
- [ ] Rich text editor
- [ ] File upload for handwritten answers
- [ ] AI evaluation integration
- [ ] Mentor review system

### Week 11-12: Current Affairs & Study Planner
- [ ] News feed
- [ ] Article management
- [ ] Study plan generator
- [ ] Daily task scheduler

### Week 13-14: AI Integration & Polish
- [ ] Ollama setup
- [ ] AI evaluation refinement
- [ ] Performance optimization
- [ ] Bug fixes and testing

## Next Steps

1. **Create migration files** based on the schema above
2. **Implement core models** (Subject, Topic, Question, Test)
3. **Build basic API** for subjects and topics
4. **Create UPSC dashboard** in frontend
5. **Integrate with existing authentication**

Would you like me to start implementing any specific phase?
