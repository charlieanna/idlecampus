# UPSC Platform - Detailed Database Schema

## Schema Design Principles
- Normalized database structure to reduce redundancy
- Proper indexing for performance
- JSONB fields for flexible metadata
- Soft deletes for important records
- Timestamp tracking for all tables
- Foreign key constraints with appropriate cascading

## Core Tables

### 1. Users & Authentication

```sql
-- users table
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  encrypted_password VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  role VARCHAR(50) DEFAULT 'student', -- student, mentor, admin, content_creator
  subscription_status VARCHAR(50) DEFAULT 'free', -- free, active, expired, cancelled
  subscription_plan VARCHAR(50), -- basic, premium, pro
  subscription_expires_at TIMESTAMP,
  email_confirmed_at TIMESTAMP,
  last_sign_in_at TIMESTAMP,
  current_sign_in_at TIMESTAMP,
  sign_in_count INTEGER DEFAULT 0,
  study_preferences JSONB DEFAULT '{}',
  notification_preferences JSONB DEFAULT '{}',
  timezone VARCHAR(50) DEFAULT 'Asia/Kolkata',
  avatar_url TEXT,
  profile_completed BOOLEAN DEFAULT false,
  profile_completed_at TIMESTAMP,
  deleted_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_subscription_status ON users(subscription_status);

-- student_profiles table
CREATE TABLE student_profiles (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  target_exam_date DATE,
  attempt_number INTEGER DEFAULT 1,
  optional_subject_id BIGINT REFERENCES subjects(id),
  medium_of_exam VARCHAR(50) DEFAULT 'english', -- english, hindi
  previous_attempt_details JSONB DEFAULT '{}', -- scores, weak areas, etc.
  educational_background TEXT,
  current_occupation VARCHAR(100),
  work_experience TEXT,
  study_hours_per_day INTEGER,
  preferred_study_time VARCHAR(50), -- morning, afternoon, evening, night
  daf_details JSONB DEFAULT '{}', -- Detailed Application Form for interview prep
  strengths TEXT[],
  weaknesses TEXT[],
  goals TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);

CREATE INDEX idx_student_profiles_user_id ON student_profiles(user_id);
CREATE INDEX idx_student_profiles_target_exam_date ON student_profiles(target_exam_date);
```

### 2. Curriculum & Content

```sql
-- subjects table
CREATE TABLE subjects (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  code VARCHAR(50) NOT NULL UNIQUE,
  exam_type VARCHAR(50) NOT NULL, -- prelims, mains
  paper_number INTEGER,
  total_marks INTEGER,
  duration_minutes INTEGER,
  description TEXT,
  syllabus_pdf_url TEXT,
  is_optional BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  order_index INTEGER,
  icon_url TEXT,
  color_code VARCHAR(20),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_subjects_exam_type ON subjects(exam_type);
CREATE INDEX idx_subjects_is_optional ON subjects(is_optional);
CREATE INDEX idx_subjects_order_index ON subjects(order_index);

-- topics table (hierarchical)
CREATE TABLE topics (
  id BIGSERIAL PRIMARY KEY,
  subject_id BIGINT NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  parent_topic_id BIGINT REFERENCES topics(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL,
  description TEXT,
  difficulty_level VARCHAR(50), -- beginner, intermediate, advanced
  estimated_hours DECIMAL(5,2),
  order_index INTEGER,
  is_high_yield BOOLEAN DEFAULT false, -- frequently asked in exams
  pyq_frequency INTEGER DEFAULT 0, -- count of previous year questions
  tags TEXT[],
  learning_objectives TEXT[],
  prerequisite_topic_ids BIGINT[],
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_topics_subject_id ON topics(subject_id);
CREATE INDEX idx_topics_parent_topic_id ON topics(parent_topic_id);
CREATE INDEX idx_topics_difficulty_level ON topics(difficulty_level);
CREATE INDEX idx_topics_is_high_yield ON topics(is_high_yield);
CREATE INDEX idx_topics_slug ON topics(slug);

-- contents table
CREATE TABLE contents (
  id BIGSERIAL PRIMARY KEY,
  topic_id BIGINT NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
  content_type VARCHAR(50) NOT NULL, -- text, video, pdf, infographic, flashcard
  title VARCHAR(500) NOT NULL,
  body TEXT,
  summary TEXT,
  video_url TEXT,
  video_duration_seconds INTEGER,
  file_url TEXT,
  file_size_bytes BIGINT,
  thumbnail_url TEXT,
  author_id BIGINT REFERENCES users(id),
  reviewer_id BIGINT REFERENCES users(id),
  version INTEGER DEFAULT 1,
  status VARCHAR(50) DEFAULT 'draft', -- draft, review, published, archived
  published_at TIMESTAMP,
  view_count INTEGER DEFAULT 0,
  like_count INTEGER DEFAULT 0,
  tags TEXT[],
  meta_data JSONB DEFAULT '{}',
  seo_title VARCHAR(255),
  seo_description TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_contents_topic_id ON contents(topic_id);
CREATE INDEX idx_contents_content_type ON contents(content_type);
CREATE INDEX idx_contents_status ON contents(status);
CREATE INDEX idx_contents_author_id ON contents(author_id);

-- content_resources table (additional resources like PDFs, links)
CREATE TABLE content_resources (
  id BIGSERIAL PRIMARY KEY,
  content_id BIGINT REFERENCES contents(id) ON DELETE CASCADE,
  resource_type VARCHAR(50), -- pdf, link, book_reference, video
  title VARCHAR(255),
  url TEXT,
  description TEXT,
  order_index INTEGER,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_content_resources_content_id ON content_resources(content_id);
```

### 3. Study Progress & Tracking

```sql
-- user_progress table
CREATE TABLE user_progress (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  topic_id BIGINT NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
  status VARCHAR(50) DEFAULT 'not_started', -- not_started, in_progress, completed, mastered
  completion_percentage INTEGER DEFAULT 0,
  confidence_level INTEGER, -- 1-5 scale
  time_spent_minutes INTEGER DEFAULT 0,
  last_accessed_at TIMESTAMP,
  first_started_at TIMESTAMP,
  completed_at TIMESTAMP,
  mastered_at TIMESTAMP,
  notes TEXT,
  bookmarked BOOLEAN DEFAULT false,
  revision_count INTEGER DEFAULT 0,
  last_revised_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, topic_id)
);

CREATE INDEX idx_user_progress_user_id ON user_progress(user_id);
CREATE INDEX idx_user_progress_topic_id ON user_progress(topic_id);
CREATE INDEX idx_user_progress_status ON user_progress(status);
CREATE INDEX idx_user_progress_last_accessed_at ON user_progress(last_accessed_at);

-- user_content_interactions table
CREATE TABLE user_content_interactions (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content_id BIGINT NOT NULL REFERENCES contents(id) ON DELETE CASCADE,
  interaction_type VARCHAR(50), -- view, like, bookmark, complete
  time_spent_seconds INTEGER,
  progress_percentage INTEGER DEFAULT 0,
  completed BOOLEAN DEFAULT false,
  notes TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_content_interactions_user_id ON user_content_interactions(user_id);
CREATE INDEX idx_user_content_interactions_content_id ON user_content_interactions(content_id);
CREATE INDEX idx_user_content_interactions_type ON user_content_interactions(interaction_type);
```

### 4. Questions & Assessments

```sql
-- questions table
CREATE TABLE questions (
  id BIGSERIAL PRIMARY KEY,
  subject_id BIGINT REFERENCES subjects(id) ON DELETE SET NULL,
  topic_id BIGINT REFERENCES topics(id) ON DELETE SET NULL,
  question_type VARCHAR(50) NOT NULL, -- mcq, msq, tf, assertion_reason
  difficulty VARCHAR(50), -- easy, medium, hard
  marks DECIMAL(5,2) DEFAULT 1.0,
  negative_marks DECIMAL(5,2) DEFAULT 0,
  time_limit_seconds INTEGER,
  question_text TEXT NOT NULL,
  question_image_url TEXT,
  options JSONB, -- [{id: 'A', text: '...', is_correct: true/false}]
  correct_answer TEXT, -- For MCQ: 'A', for MSQ: ['A', 'C']
  explanation TEXT,
  explanation_video_url TEXT,
  hints TEXT[],
  pyq_year INTEGER, -- Previous Year Question year
  pyq_paper VARCHAR(100), -- Which paper (Prelims GS/CSAT, Mains GS1-4)
  pyq_question_number INTEGER,
  source VARCHAR(255), -- source of question
  tags TEXT[],
  relevance_score INTEGER DEFAULT 50, -- 0-100, how relevant to current pattern
  attempt_count INTEGER DEFAULT 0,
  correct_attempt_count INTEGER DEFAULT 0,
  average_time_taken_seconds INTEGER,
  status VARCHAR(50) DEFAULT 'active', -- active, archived, under_review
  created_by_id BIGINT REFERENCES users(id),
  reviewed_by_id BIGINT REFERENCES users(id),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_questions_subject_id ON questions(subject_id);
CREATE INDEX idx_questions_topic_id ON questions(topic_id);
CREATE INDEX idx_questions_question_type ON questions(question_type);
CREATE INDEX idx_questions_difficulty ON questions(difficulty);
CREATE INDEX idx_questions_pyq_year ON questions(pyq_year);
CREATE INDEX idx_questions_status ON questions(status);

-- tests table
CREATE TABLE tests (
  id BIGSERIAL PRIMARY KEY,
  test_type VARCHAR(50) NOT NULL, -- mock_prelims, mock_mains, topic_test, subject_test, practice
  title VARCHAR(255) NOT NULL,
  description TEXT,
  instructions TEXT,
  subject_id BIGINT REFERENCES subjects(id),
  duration_minutes INTEGER NOT NULL,
  total_marks DECIMAL(7,2) NOT NULL,
  passing_marks DECIMAL(7,2),
  negative_marking_enabled BOOLEAN DEFAULT true,
  negative_marking_ratio DECIMAL(3,2) DEFAULT 0.33,
  is_live BOOLEAN DEFAULT false,
  is_free BOOLEAN DEFAULT false,
  scheduled_at TIMESTAMP,
  starts_at TIMESTAMP,
  ends_at TIMESTAMP,
  result_publish_at TIMESTAMP,
  max_attempts INTEGER DEFAULT 1,
  shuffle_questions BOOLEAN DEFAULT true,
  shuffle_options BOOLEAN DEFAULT true,
  show_answers_after_submit BOOLEAN DEFAULT true,
  difficulty_level VARCHAR(50),
  tags TEXT[],
  created_by_id BIGINT REFERENCES users(id),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tests_test_type ON tests(test_type);
CREATE INDEX idx_tests_subject_id ON tests(subject_id);
CREATE INDEX idx_tests_scheduled_at ON tests(scheduled_at);
CREATE INDEX idx_tests_is_live ON tests(is_live);

-- test_questions table (join table)
CREATE TABLE test_questions (
  id BIGSERIAL PRIMARY KEY,
  test_id BIGINT NOT NULL REFERENCES tests(id) ON DELETE CASCADE,
  question_id BIGINT NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  marks DECIMAL(5,2) NOT NULL,
  negative_marks DECIMAL(5,2) DEFAULT 0,
  order_index INTEGER NOT NULL,
  section VARCHAR(100), -- For grouped questions
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(test_id, question_id)
);

CREATE INDEX idx_test_questions_test_id ON test_questions(test_id);
CREATE INDEX idx_test_questions_question_id ON test_questions(question_id);

-- user_test_attempts table
CREATE TABLE user_test_attempts (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  test_id BIGINT NOT NULL REFERENCES tests(id) ON DELETE CASCADE,
  attempt_number INTEGER DEFAULT 1,
  started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  submitted_at TIMESTAMP,
  time_taken_minutes INTEGER,
  score DECIMAL(7,2),
  percentage DECIMAL(5,2),
  percentile DECIMAL(5,2),
  rank INTEGER,
  total_questions INTEGER,
  correct_answers INTEGER DEFAULT 0,
  wrong_answers INTEGER DEFAULT 0,
  unanswered INTEGER DEFAULT 0,
  answers JSONB DEFAULT '{}', -- {question_id: selected_option, ...}
  question_wise_time JSONB DEFAULT '{}', -- {question_id: time_in_seconds}
  analysis JSONB DEFAULT '{}', -- subject_wise, difficulty_wise breakdown
  status VARCHAR(50) DEFAULT 'in_progress', -- in_progress, submitted, evaluated
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_test_attempts_user_id ON user_test_attempts(user_id);
CREATE INDEX idx_user_test_attempts_test_id ON user_test_attempts(test_id);
CREATE INDEX idx_user_test_attempts_status ON user_test_attempts(status);
CREATE INDEX idx_user_test_attempts_submitted_at ON user_test_attempts(submitted_at);
```

### 5. Answer Writing & Evaluation

```sql
-- writing_questions table
CREATE TABLE writing_questions (
  id BIGSERIAL PRIMARY KEY,
  subject_id BIGINT REFERENCES subjects(id) ON DELETE SET NULL,
  topic_id BIGINT REFERENCES topics(id) ON DELETE SET NULL,
  question_type VARCHAR(50), -- essay, case_study, general, analytical
  question_text TEXT NOT NULL,
  question_context TEXT, -- Background information
  word_limit INTEGER,
  marks DECIMAL(5,2) DEFAULT 10.0,
  time_limit_minutes INTEGER,
  difficulty VARCHAR(50),
  directive_keywords TEXT[], -- analyze, critically examine, discuss, etc.
  evaluation_criteria JSONB, -- [{criterion: 'relevance', weight: 20}]
  model_answer TEXT,
  model_answer_url TEXT,
  key_points TEXT[],
  suggested_structure JSONB,
  pyq_year INTEGER,
  pyq_paper VARCHAR(100),
  tags TEXT[],
  current_affairs_date DATE, -- If linked to specific current event
  relevance_score INTEGER DEFAULT 50,
  created_by_id BIGINT REFERENCES users(id),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_writing_questions_subject_id ON writing_questions(subject_id);
CREATE INDEX idx_writing_questions_topic_id ON writing_questions(topic_id);
CREATE INDEX idx_writing_questions_question_type ON writing_questions(question_type);
CREATE INDEX idx_writing_questions_pyq_year ON writing_questions(pyq_year);

-- user_answers table
CREATE TABLE user_answers (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  writing_question_id BIGINT NOT NULL REFERENCES writing_questions(id) ON DELETE CASCADE,
  answer_text TEXT NOT NULL,
  word_count INTEGER,
  time_taken_minutes INTEGER,
  submission_type VARCHAR(50) DEFAULT 'typed', -- typed, uploaded
  file_url TEXT, -- If handwritten and uploaded
  submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ai_evaluation JSONB, -- AI-generated feedback
  ai_score DECIMAL(5,2),
  ai_evaluated_at TIMESTAMP,
  mentor_evaluation JSONB, -- Human mentor feedback
  mentor_score DECIMAL(5,2),
  mentor_evaluated_at TIMESTAMP,
  evaluator_id BIGINT REFERENCES users(id),
  final_score DECIMAL(5,2),
  status VARCHAR(50) DEFAULT 'submitted', -- submitted, ai_evaluated, mentor_review, completed
  revision_number INTEGER DEFAULT 1,
  original_answer_id BIGINT REFERENCES user_answers(id), -- If this is a revision
  is_public BOOLEAN DEFAULT false, -- Can be viewed by other students
  like_count INTEGER DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_answers_user_id ON user_answers(user_id);
CREATE INDEX idx_user_answers_writing_question_id ON user_answers(writing_question_id);
CREATE INDEX idx_user_answers_status ON user_answers(status);
CREATE INDEX idx_user_answers_submitted_at ON user_answers(submitted_at);

-- evaluation_rubrics table
CREATE TABLE evaluation_rubrics (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  applicable_to VARCHAR(50), -- essay, case_study, general, all
  criteria JSONB NOT NULL, -- [{name: 'relevance', max_score: 10, description: '...'}]
  total_score DECIMAL(5,2) NOT NULL,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### 6. Current Affairs

```sql
-- news_articles table
CREATE TABLE news_articles (
  id BIGSERIAL PRIMARY KEY,
  title VARCHAR(500) NOT NULL,
  slug VARCHAR(500) NOT NULL UNIQUE,
  summary TEXT,
  full_content TEXT NOT NULL,
  source VARCHAR(255),
  source_url TEXT,
  author VARCHAR(255),
  published_date DATE NOT NULL,
  categories TEXT[], -- polity, economy, international, etc.
  tags TEXT[],
  relevance_score INTEGER DEFAULT 50, -- How relevant to UPSC
  importance_level VARCHAR(50), -- low, medium, high, critical
  is_featured BOOLEAN DEFAULT false,
  image_url TEXT,
  related_topic_ids BIGINT[],
  related_subject_ids BIGINT[],
  exam_perspective TEXT, -- Why this is important for UPSC
  key_points TEXT[],
  view_count INTEGER DEFAULT 0,
  like_count INTEGER DEFAULT 0,
  status VARCHAR(50) DEFAULT 'published',
  created_by_id BIGINT REFERENCES users(id),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_news_articles_published_date ON news_articles(published_date DESC);
CREATE INDEX idx_news_articles_slug ON news_articles(slug);
CREATE INDEX idx_news_articles_categories ON news_articles USING GIN(categories);
CREATE INDEX idx_news_articles_tags ON news_articles USING GIN(tags);
CREATE INDEX idx_news_articles_is_featured ON news_articles(is_featured);

-- current_affairs_quizzes table
CREATE TABLE current_affairs_quizzes (
  id BIGSERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  quiz_type VARCHAR(50), -- daily, weekly, monthly
  quiz_date DATE NOT NULL,
  description TEXT,
  duration_minutes INTEGER,
  total_marks DECIMAL(5,2),
  is_published BOOLEAN DEFAULT false,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_current_affairs_quizzes_quiz_date ON current_affairs_quizzes(quiz_date DESC);
CREATE INDEX idx_current_affairs_quizzes_quiz_type ON current_affairs_quizzes(quiz_type);

-- monthly_magazines table
CREATE TABLE monthly_magazines (
  id BIGSERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  month INTEGER NOT NULL,
  year INTEGER NOT NULL,
  description TEXT,
  cover_image_url TEXT,
  pdf_url TEXT,
  page_count INTEGER,
  file_size_bytes BIGINT,
  is_published BOOLEAN DEFAULT false,
  published_at TIMESTAMP,
  download_count INTEGER DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(month, year)
);

CREATE INDEX idx_monthly_magazines_year_month ON monthly_magazines(year DESC, month DESC);
```

### 7. Gamification & Engagement

```sql
-- achievements table
CREATE TABLE achievements (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,
  icon_url TEXT,
  category VARCHAR(50), -- study, practice, consistency, social
  criteria_type VARCHAR(50), -- streak, count, score, percentage
  criteria_value JSONB, -- {type: 'streak_days', value: 30}
  points_awarded INTEGER DEFAULT 0,
  badge_level VARCHAR(50), -- bronze, silver, gold, platinum
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_achievements_category ON achievements(category);
CREATE INDEX idx_achievements_slug ON achievements(slug);

-- user_achievements table
CREATE TABLE user_achievements (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  achievement_id BIGINT NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
  earned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  progress_percentage INTEGER DEFAULT 100,
  current_value INTEGER,
  is_claimed BOOLEAN DEFAULT false,
  UNIQUE(user_id, achievement_id)
);

CREATE INDEX idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX idx_user_achievements_earned_at ON user_achievements(earned_at DESC);

-- study_streaks table
CREATE TABLE study_streaks (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  current_streak_days INTEGER DEFAULT 0,
  longest_streak_days INTEGER DEFAULT 0,
  last_activity_date DATE,
  streak_milestones JSONB DEFAULT '[]', -- [{days: 30, achieved_at: '...'}]
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);

CREATE INDEX idx_study_streaks_user_id ON study_streaks(user_id);
CREATE INDEX idx_study_streaks_current_streak ON study_streaks(current_streak_days DESC);

-- user_points table
CREATE TABLE user_points (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  total_points INTEGER DEFAULT 0,
  points_this_week INTEGER DEFAULT 0,
  points_this_month INTEGER DEFAULT 0,
  rank_overall INTEGER,
  rank_this_week INTEGER,
  level INTEGER DEFAULT 1,
  level_progress_percentage INTEGER DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);

CREATE INDEX idx_user_points_total_points ON user_points(total_points DESC);
CREATE INDEX idx_user_points_rank_overall ON user_points(rank_overall);

-- point_transactions table
CREATE TABLE point_transactions (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  points INTEGER NOT NULL,
  transaction_type VARCHAR(50), -- earned, spent, bonus
  reason VARCHAR(255),
  reference_type VARCHAR(50), -- test_attempt, answer_submission, streak, etc.
  reference_id BIGINT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_point_transactions_user_id ON point_transactions(user_id);
CREATE INDEX idx_point_transactions_created_at ON point_transactions(created_at DESC);
```

### 8. Revision & Spaced Repetition

```sql
-- revisions table
CREATE TABLE revisions (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  topic_id BIGINT REFERENCES topics(id) ON DELETE CASCADE,
  revision_type VARCHAR(50), -- scheduled, manual, triggered
  scheduled_for DATE NOT NULL,
  completed_at TIMESTAMP,
  interval_index INTEGER DEFAULT 0, -- Position in spaced repetition schedule
  performance_rating INTEGER, -- 1-5, how well did the user recall
  time_spent_minutes INTEGER,
  notes TEXT,
  status VARCHAR(50) DEFAULT 'pending', -- pending, completed, skipped
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_revisions_user_id ON revisions(user_id);
CREATE INDEX idx_revisions_scheduled_for ON revisions(scheduled_for);
CREATE INDEX idx_revisions_status ON revisions(status);

-- flashcards table
CREATE TABLE flashcards (
  id BIGSERIAL PRIMARY KEY,
  topic_id BIGINT REFERENCES topics(id) ON DELETE CASCADE,
  front_text TEXT NOT NULL,
  back_text TEXT NOT NULL,
  front_image_url TEXT,
  back_image_url TEXT,
  difficulty VARCHAR(50),
  tags TEXT[],
  created_by_id BIGINT REFERENCES users(id),
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_flashcards_topic_id ON flashcards(topic_id);
CREATE INDEX idx_flashcards_is_public ON flashcards(is_public);

-- user_flashcard_reviews table
CREATE TABLE user_flashcard_reviews (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  flashcard_id BIGINT NOT NULL REFERENCES flashcards(id) ON DELETE CASCADE,
  ease_factor DECIMAL(3,2) DEFAULT 2.5, -- SM-2 algorithm
  interval_days INTEGER DEFAULT 1,
  repetitions INTEGER DEFAULT 0,
  next_review_date DATE NOT NULL,
  last_reviewed_at TIMESTAMP,
  quality_rating INTEGER, -- 0-5, last quality of recall
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, flashcard_id)
);

CREATE INDEX idx_user_flashcard_reviews_user_id ON user_flashcard_reviews(user_id);
CREATE INDEX idx_user_flashcard_reviews_next_review ON user_flashcard_reviews(next_review_date);
```

### 9. Study Planning & Scheduling

```sql
-- study_plans table
CREATE TABLE study_plans (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan_name VARCHAR(255),
  start_date DATE NOT NULL,
  target_exam_date DATE NOT NULL,
  total_days INTEGER,
  phase_breakdown JSONB, -- {foundation: {days: 120, ...}, practice: {...}}
  daily_schedule JSONB, -- Default daily schedule template
  is_active BOOLEAN DEFAULT true,
  completion_percentage INTEGER DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_study_plans_user_id ON study_plans(user_id);
CREATE INDEX idx_study_plans_is_active ON study_plans(is_active);

-- daily_tasks table
CREATE TABLE daily_tasks (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  study_plan_id BIGINT REFERENCES study_plans(id) ON DELETE CASCADE,
  task_date DATE NOT NULL,
  task_type VARCHAR(50), -- study, practice, test, revision
  title VARCHAR(255) NOT NULL,
  description TEXT,
  topic_id BIGINT REFERENCES topics(id),
  estimated_minutes INTEGER,
  actual_minutes INTEGER,
  priority VARCHAR(50) DEFAULT 'medium', -- low, medium, high
  status VARCHAR(50) DEFAULT 'pending', -- pending, in_progress, completed, skipped
  completed_at TIMESTAMP,
  notes TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_daily_tasks_user_id ON daily_tasks(user_id);
CREATE INDEX idx_daily_tasks_task_date ON daily_tasks(task_date);
CREATE INDEX idx_daily_tasks_status ON daily_tasks(status);

-- study_sessions table
CREATE TABLE study_sessions (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  topic_id BIGINT REFERENCES topics(id),
  session_type VARCHAR(50), -- focused_study, practice, revision
  started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ended_at TIMESTAMP,
  duration_minutes INTEGER,
  notes TEXT,
  productivity_rating INTEGER, -- 1-5 self-rating
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_study_sessions_user_id ON study_sessions(user_id);
CREATE INDEX idx_study_sessions_started_at ON study_sessions(started_at DESC);
```

### 10. Community & Social Features

```sql
-- discussion_forums table
CREATE TABLE discussion_forums (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,
  category VARCHAR(100),
  subject_id BIGINT REFERENCES subjects(id),
  is_active BOOLEAN DEFAULT true,
  order_index INTEGER,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_discussion_forums_slug ON discussion_forums(slug);
CREATE INDEX idx_discussion_forums_subject_id ON discussion_forums(subject_id);

-- forum_threads table
CREATE TABLE forum_threads (
  id BIGSERIAL PRIMARY KEY,
  forum_id BIGINT NOT NULL REFERENCES discussion_forums(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(500) NOT NULL,
  content TEXT NOT NULL,
  is_pinned BOOLEAN DEFAULT false,
  is_locked BOOLEAN DEFAULT false,
  is_solved BOOLEAN DEFAULT false,
  view_count INTEGER DEFAULT 0,
  reply_count INTEGER DEFAULT 0,
  like_count INTEGER DEFAULT 0,
  tags TEXT[],
  last_activity_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_forum_threads_forum_id ON forum_threads(forum_id);
CREATE INDEX idx_forum_threads_user_id ON forum_threads(user_id);
CREATE INDEX idx_forum_threads_last_activity ON forum_threads(last_activity_at DESC);

-- forum_replies table
CREATE TABLE forum_replies (
  id BIGSERIAL PRIMARY KEY,
  thread_id BIGINT NOT NULL REFERENCES forum_threads(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  parent_reply_id BIGINT REFERENCES forum_replies(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  is_solution BOOLEAN DEFAULT false,
  like_count INTEGER DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_forum_replies_thread_id ON forum_replies(thread_id);
CREATE INDEX idx_forum_replies_user_id ON forum_replies(user_id);
CREATE INDEX idx_forum_replies_created_at ON forum_replies(created_at);

-- study_groups table
CREATE TABLE study_groups (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  group_type VARCHAR(50), -- public, private, invite_only
  creator_id BIGINT NOT NULL REFERENCES users(id),
  member_limit INTEGER,
  member_count INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_study_groups_creator_id ON study_groups(creator_id);
CREATE INDEX idx_study_groups_is_active ON study_groups(is_active);

-- study_group_members table
CREATE TABLE study_group_members (
  id BIGSERIAL PRIMARY KEY,
  study_group_id BIGINT NOT NULL REFERENCES study_groups(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(50) DEFAULT 'member', -- admin, moderator, member
  joined_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(study_group_id, user_id)
);

CREATE INDEX idx_study_group_members_group_id ON study_group_members(study_group_id);
CREATE INDEX idx_study_group_members_user_id ON study_group_members(user_id);
```

### 11. Notifications & Communication

```sql
-- notifications table
CREATE TABLE notifications (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  notification_type VARCHAR(50), -- task_reminder, test_reminder, achievement, etc.
  title VARCHAR(255) NOT NULL,
  message TEXT,
  action_url TEXT,
  reference_type VARCHAR(50),
  reference_id BIGINT,
  priority VARCHAR(50) DEFAULT 'normal', -- low, normal, high
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMP,
  sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_sent_at ON notifications(sent_at DESC);
```

### 12. Analytics & Reporting

```sql
-- user_analytics table
CREATE TABLE user_analytics (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  study_time_minutes INTEGER DEFAULT 0,
  topics_completed INTEGER DEFAULT 0,
  questions_attempted INTEGER DEFAULT 0,
  questions_correct INTEGER DEFAULT 0,
  answers_written INTEGER DEFAULT 0,
  tests_taken INTEGER DEFAULT 0,
  average_test_score DECIMAL(5,2),
  revision_count INTEGER DEFAULT 0,
  points_earned INTEGER DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, date)
);

CREATE INDEX idx_user_analytics_user_id ON user_analytics(user_id);
CREATE INDEX idx_user_analytics_date ON user_analytics(date DESC);
```

## Migration Notes

1. All tables use `BIGSERIAL` for primary keys to support large scale
2. Proper foreign key constraints with cascade rules
3. Comprehensive indexing for common query patterns
4. JSONB for flexible data storage (preferences, metadata)
5. Array columns for tags and multi-value fields
6. Timestamp tracking (created_at, updated_at) for all tables
7. Soft deletes (deleted_at) for critical user data
8. GIN indexes for array and JSONB columns where needed

## Performance Considerations

1. Add partial indexes for frequently filtered queries
2. Consider table partitioning for large tables (analytics, sessions)
3. Implement materialized views for complex aggregations
4. Use connection pooling (PgBouncer)
5. Regular VACUUM and ANALYZE operations
6. Monitor slow queries and optimize accordingly
