# UPSC Platform - Rails Implementation Guide

## Setup Instructions

### 1. Create New Rails API Application

```bash
# Create new Rails 7 API-only application with PostgreSQL
rails new upsc_platform_api --api --database=postgresql --skip-test

cd upsc_platform_api

# Add required gems to Gemfile
```

### 2. Essential Gems (Gemfile)

```ruby
# Gemfile
source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.2.2'

# Core Rails
gem 'rails', '~> 7.1.0'
gem 'pg', '~> 1.5'
gem 'puma', '~> 6.0'

# Authentication & Authorization
gem 'bcrypt', '~> 3.1.7'
gem 'jwt'
gem 'pundit'

# API
gem 'jsonapi-serializer'
gem 'rack-cors'
gem 'kaminari' # Pagination

# Background Jobs
gem 'sidekiq', '~> 7.0'
gem 'redis', '~> 5.0'

# File Upload
gem 'aws-sdk-s3', require: false
gem 'image_processing', '~> 1.2'

# Search
gem 'searchkick'
gem 'elasticsearch', '~> 8.0'

# Utilities
gem 'httparty' # HTTP requests
gem 'faraday' # HTTP client
gem 'oj' # Fast JSON
gem 'dotenv-rails'
gem 'paper_trail' # Audit trail

# Performance
gem 'bootsnap', require: false
gem 'rack-attack' # Rate limiting
gem 'connection_pool'

group :development, :test do
  gem 'debug'
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'pry-rails'
  gem 'bullet' # N+1 query detection
end

group :development do
  gem 'annotate' # Model annotations
  gem 'brakeman' # Security scanner
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
end

group :test do
  gem 'shoulda-matchers'
  gem 'database_cleaner-active_record'
  gem 'simplecov', require: false
end
```

### 3. Initial Configuration

```ruby
# config/application.rb
module UpscPlatformApi
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = true

    # Middleware
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore

    # CORS
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
        resource '*',
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head],
          credentials: true
      end
    end

    # Timezone
    config.time_zone = 'Asia/Kolkata'
    config.active_record.default_timezone = :local

    # Generators
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
      g.test_framework :rspec
      g.fixture_replacement :factory_bot, dir: 'spec/factories'
    end

    # Active Job
    config.active_job.queue_adapter = :sidekiq

    # Cache Store
    config.cache_store = :redis_cache_store, {
      url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
      namespace: 'upsc_platform'
    }
  end
end
```

```ruby
# config/database.yml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  host: <%= ENV.fetch("DB_HOST", "localhost") %>
  username: <%= ENV.fetch("DB_USERNAME", "postgres") %>
  password: <%= ENV.fetch("DB_PASSWORD", "") %>

development:
  <<: *default
  database: upsc_platform_development

test:
  <<: *default
  database: upsc_platform_test

production:
  <<: *default
  database: upsc_platform_production
  username: <%= ENV['DB_USERNAME'] %>
  password: <%= ENV['DB_PASSWORD'] %>
```

## Core Models Implementation

### 1. User Model

```bash
rails generate model User email:string:uniq encrypted_password:string name:string phone:string role:string subscription_status:string subscription_plan:string subscription_expires_at:datetime email_confirmed_at:datetime last_sign_in_at:datetime current_sign_in_at:datetime sign_in_count:integer study_preferences:jsonb notification_preferences:jsonb timezone:string avatar_url:text profile_completed:boolean profile_completed_at:datetime deleted_at:datetime
```

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  # Associations
  has_one :student_profile, dependent: :destroy
  has_one :study_streak, dependent: :destroy
  has_one :user_points, dependent: :destroy
  has_many :user_progress, dependent: :destroy
  has_many :topics, through: :user_progress
  has_many :user_test_attempts, dependent: :destroy
  has_many :user_answers, dependent: :destroy
  has_many :daily_tasks, dependent: :destroy
  has_many :study_sessions, dependent: :destroy
  has_many :revisions, dependent: :destroy
  has_many :user_achievements, dependent: :destroy
  has_many :achievements, through: :user_achievements
  has_many :notifications, dependent: :destroy
  has_many :forum_threads, dependent: :destroy
  has_many :forum_replies, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :role, inclusion: { in: %w[student mentor admin content_creator] }
  validates :subscription_status, inclusion: { in: %w[free active expired cancelled] }

  # Scopes
  scope :students, -> { where(role: 'student') }
  scope :active_subscribers, -> { where(subscription_status: 'active') }
  scope :confirmed, -> { where.not(email_confirmed_at: nil) }

  # Callbacks
  before_create :set_defaults
  after_create :create_associated_records

  # Enums (using string columns)
  def self.roles
    %w[student mentor admin content_creator]
  end

  def student?
    role == 'student'
  end

  def mentor?
    role == 'mentor'
  end

  def admin?
    role == 'admin'
  end

  def active_subscription?
    subscription_status == 'active' && subscription_expires_at&.> Time.current
  end

  # Methods
  def generate_jwt
    payload = {
      user_id: id,
      email: email,
      role: role,
      exp: 24.hours.from_now.to_i
    }
    JWT.encode(payload, Rails.application.credentials.secret_key_base)
  end

  def track_sign_in(request)
    self.last_sign_in_at = current_sign_in_at
    self.current_sign_in_at = Time.current
    self.sign_in_count = (sign_in_count || 0) + 1
    save
  end

  private

  def set_defaults
    self.role ||= 'student'
    self.subscription_status ||= 'free'
    self.study_preferences ||= {}
    self.notification_preferences ||= default_notification_preferences
    self.timezone ||= 'Asia/Kolkata'
    self.sign_in_count ||= 0
  end

  def create_associated_records
    create_student_profile if student?
    create_study_streak
    create_user_points
  end

  def default_notification_preferences
    {
      email: {
        daily_reminder: true,
        test_reminder: true,
        achievement: true,
        weekly_summary: true
      },
      push: {
        study_reminder: true,
        new_content: false,
        forum_reply: true
      }
    }
  end
end
```

### 2. Student Profile Model

```bash
rails generate model StudentProfile user:references target_exam_date:date attempt_number:integer optional_subject:references medium_of_exam:string previous_attempt_details:jsonb educational_background:text current_occupation:string work_experience:text study_hours_per_day:integer preferred_study_time:string daf_details:jsonb strengths:text goals:text
```

```ruby
# app/models/student_profile.rb
class StudentProfile < ApplicationRecord
  belongs_to :user
  belongs_to :optional_subject, class_name: 'Subject', optional: true

  # Validations
  validates :attempt_number, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :medium_of_exam, inclusion: { in: %w[english hindi] }, allow_nil: true
  validates :study_hours_per_day, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 18 }, allow_nil: true

  # Callbacks
  before_create :set_defaults

  # Methods
  def days_until_exam
    return nil unless target_exam_date
    (target_exam_date - Date.current).to_i
  end

  def exam_phase
    days = days_until_exam
    return 'exam_passed' if days && days < 0
    return 'exam_imminent' if days && days <= 30
    return 'final_prep' if days && days <= 90
    return 'practice_phase' if days && days <= 180
    'foundation_phase'
  end

  def is_first_attempt?
    attempt_number == 1
  end

  private

  def set_defaults
    self.attempt_number ||= 1
    self.medium_of_exam ||= 'english'
    self.previous_attempt_details ||= {}
    self.daf_details ||= {}
  end
end
```

### 3. Subject & Topic Models

```bash
rails generate model Subject name:string code:string:uniq exam_type:string paper_number:integer total_marks:integer duration_minutes:integer description:text syllabus_pdf_url:text is_optional:boolean is_active:boolean order_index:integer icon_url:text color_code:string

rails generate model Topic subject:references parent_topic:references name:string slug:string description:text difficulty_level:string estimated_hours:decimal order_index:integer is_high_yield:boolean pyq_frequency:integer tags:text learning_objectives:text
```

```ruby
# app/models/subject.rb
class Subject < ApplicationRecord
  # Associations
  has_many :topics, dependent: :destroy
  has_many :contents, through: :topics
  has_many :questions, dependent: :nullify
  has_many :tests, dependent: :nullify
  has_many :writing_questions, dependent: :nullify

  # Validations
  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
  validates :exam_type, presence: true, inclusion: { in: %w[prelims mains both] }

  # Scopes
  scope :prelims, -> { where(exam_type: ['prelims', 'both']) }
  scope :mains, -> { where(exam_type: ['mains', 'both']) }
  scope :optional, -> { where(is_optional: true) }
  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:order_index) }

  # Search
  searchkick word_start: [:name]

  def search_data
    {
      name: name,
      code: code,
      description: description
    }
  end
end

# app/models/topic.rb
class Topic < ApplicationRecord
  belongs_to :subject
  belongs_to :parent_topic, class_name: 'Topic', optional: true

  # Associations
  has_many :child_topics, class_name: 'Topic', foreign_key: 'parent_topic_id', dependent: :destroy
  has_many :contents, dependent: :destroy
  has_many :user_progress, dependent: :destroy
  has_many :questions, dependent: :nullify
  has_many :writing_questions, dependent: :nullify
  has_many :revisions, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :subject_id }
  validates :difficulty_level, inclusion: { in: %w[beginner intermediate advanced] }, allow_nil: true

  # Scopes
  scope :root_topics, -> { where(parent_topic_id: nil) }
  scope :high_yield, -> { where(is_high_yield: true) }
  scope :ordered, -> { order(:order_index) }

  # Callbacks
  before_validation :generate_slug

  # Search
  searchkick word_start: [:name, :tags]

  def search_data
    {
      name: name,
      description: description,
      tags: tags,
      subject_name: subject.name
    }
  end

  # Methods
  def full_path
    path = [name]
    current = self
    while current.parent_topic
      current = current.parent_topic
      path.unshift(current.name)
    end
    path.join(' > ')
  end

  def prerequisite_topics
    return [] unless prerequisite_topic_ids.present?
    Topic.where(id: prerequisite_topic_ids)
  end

  private

  def generate_slug
    self.slug = name.parameterize if name.present? && slug.blank?
  end
end
```

### 4. Content Model

```bash
rails generate model Content topic:references content_type:string title:string body:text summary:text video_url:text video_duration_seconds:integer file_url:text file_size_bytes:bigint thumbnail_url:text author:references reviewer:references version:integer status:string published_at:datetime view_count:integer like_count:integer tags:text meta_data:jsonb seo_title:string seo_description:text
```

```ruby
# app/models/content.rb
class Content < ApplicationRecord
  belongs_to :topic
  belongs_to :author, class_name: 'User', optional: true
  belongs_to :reviewer, class_name: 'User', optional: true

  # Associations
  has_many :content_resources, dependent: :destroy
  has_many :user_content_interactions, dependent: :destroy
  has_one_attached :file
  has_one_attached :thumbnail

  # Validations
  validates :title, presence: true
  validates :content_type, presence: true, inclusion: { in: %w[text video pdf infographic flashcard audio] }
  validates :status, inclusion: { in: %w[draft review published archived] }

  # Scopes
  scope :published, -> { where(status: 'published') }
  scope :by_type, ->(type) { where(content_type: type) }
  scope :recent, -> { order(published_at: :desc) }

  # Search
  searchkick word_start: [:title, :tags]

  def search_data
    {
      title: title,
      summary: summary,
      body: body,
      tags: tags,
      content_type: content_type,
      topic_name: topic.name,
      subject_name: topic.subject.name
    }
  end

  # Methods
  def publish!
    update(status: 'published', published_at: Time.current)
  end

  def increment_view_count
    increment!(:view_count)
  end

  def increment_like_count
    increment!(:like_count)
  end

  def reading_time_minutes
    return nil unless body.present?
    words = body.split.size
    (words / 200.0).ceil # Assuming 200 words per minute
  end
end
```

### 5. Question & Test Models

```bash
rails generate model Question subject:references topic:references question_type:string difficulty:string marks:decimal negative_marks:decimal time_limit_seconds:integer question_text:text question_image_url:text options:jsonb correct_answer:text explanation:text explanation_video_url:text hints:text pyq_year:integer pyq_paper:string pyq_question_number:integer source:string tags:text relevance_score:integer attempt_count:integer correct_attempt_count:integer average_time_taken_seconds:integer status:string created_by:references reviewed_by:references

rails generate model Test test_type:string title:string description:text instructions:text subject:references duration_minutes:integer total_marks:decimal passing_marks:decimal negative_marking_enabled:boolean negative_marking_ratio:decimal is_live:boolean is_free:boolean scheduled_at:datetime starts_at:datetime ends_at:datetime result_publish_at:datetime max_attempts:integer shuffle_questions:boolean shuffle_options:boolean show_answers_after_submit:boolean difficulty_level:string tags:text created_by:references

rails generate model TestQuestion test:references question:references marks:decimal negative_marks:decimal order_index:integer section:string

rails generate model UserTestAttempt user:references test:references attempt_number:integer started_at:datetime submitted_at:datetime time_taken_minutes:integer score:decimal percentage:decimal percentile:decimal rank:integer total_questions:integer correct_answers:integer wrong_answers:integer unanswered:integer answers:jsonb question_wise_time:jsonb analysis:jsonb status:string
```

```ruby
# app/models/question.rb
class Question < ApplicationRecord
  belongs_to :subject, optional: true
  belongs_to :topic, optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :reviewed_by, class_name: 'User', optional: true

  has_many :test_questions, dependent: :destroy
  has_many :tests, through: :test_questions

  # Validations
  validates :question_text, presence: true
  validates :question_type, presence: true, inclusion: { in: %w[mcq msq tf assertion_reason] }
  validates :difficulty, inclusion: { in: %w[easy medium hard] }, allow_nil: true
  validates :correct_answer, presence: true

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :by_difficulty, ->(level) { where(difficulty: level) }
  scope :pyqs, -> { where.not(pyq_year: nil) }
  scope :by_subject, ->(subject_id) { where(subject_id: subject_id) }
  scope :by_topic, ->(topic_id) { where(topic_id: topic_id) }

  # Search
  searchkick

  # Methods
  def is_pyq?
    pyq_year.present?
  end

  def update_stats(is_correct, time_taken)
    increment!(:attempt_count)
    increment!(:correct_attempt_count) if is_correct

    # Update average time
    current_total = (average_time_taken_seconds || 0) * (attempt_count - 1)
    self.average_time_taken_seconds = ((current_total + time_taken) / attempt_count).round
    save
  end

  def accuracy_percentage
    return 0 if attempt_count.zero?
    (correct_attempt_count.to_f / attempt_count * 100).round(2)
  end
end

# app/models/test.rb
class Test < ApplicationRecord
  belongs_to :subject, optional: true
  belongs_to :created_by, class_name: 'User', optional: true

  has_many :test_questions, -> { order(:order_index) }, dependent: :destroy
  has_many :questions, through: :test_questions
  has_many :user_test_attempts, dependent: :destroy

  # Validations
  validates :title, presence: true
  validates :test_type, presence: true
  validates :duration_minutes, presence: true, numericality: { greater_than: 0 }
  validates :total_marks, presence: true, numericality: { greater_than: 0 }

  # Scopes
  scope :live, -> { where(is_live: true) }
  scope :upcoming, -> { where('starts_at > ?', Time.current) }
  scope :ongoing, -> { where('starts_at <= ? AND ends_at >= ?', Time.current, Time.current) }
  scope :completed, -> { where('ends_at < ?', Time.current) }

  # Methods
  def add_questions(question_ids, marks_per_question)
    question_ids.each_with_index do |question_id, index|
      test_questions.create!(
        question_id: question_id,
        marks: marks_per_question,
        negative_marks: negative_marking_enabled ? marks_per_question * negative_marking_ratio : 0,
        order_index: index + 1
      )
    end
  end

  def is_ongoing?
    return false unless starts_at && ends_at
    Time.current.between?(starts_at, ends_at)
  end

  def is_upcoming?
    starts_at && starts_at > Time.current
  end

  def average_score
    user_test_attempts.where(status: 'submitted').average(:score)
  end

  def total_attempts
    user_test_attempts.where(status: 'submitted').count
  end
end

# app/models/user_test_attempt.rb
class UserTestAttempt < ApplicationRecord
  belongs_to :user
  belongs_to :test

  # Validations
  validates :attempt_number, presence: true
  validates :status, inclusion: { in: %w[in_progress submitted evaluated] }

  # Scopes
  scope :submitted, -> { where(status: ['submitted', 'evaluated']) }
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  before_create :set_attempt_number
  after_create :initialize_answers

  # Methods
  def submit_answer(question_id, selected_answer, time_spent)
    answers[question_id.to_s] = selected_answer
    question_wise_time[question_id.to_s] = time_spent
    save
  end

  def submit_test!
    return false if submitted_at.present?

    self.submitted_at = Time.current
    self.time_taken_minutes = ((submitted_at - started_at) / 60).round
    self.status = 'submitted'

    calculate_score
    save

    # Background job for detailed analysis
    TestEvaluationJob.perform_later(id)
  end

  def calculate_score
    total_score = 0
    correct = 0
    wrong = 0
    unanswered = 0

    test.test_questions.includes(:question).each do |tq|
      user_answer = answers[tq.question_id.to_s]

      if user_answer.blank?
        unanswered += 1
        next
      end

      if tq.question.correct_answer == user_answer
        total_score += tq.marks
        correct += 1
        tq.question.update_stats(true, question_wise_time[tq.question_id.to_s])
      else
        total_score -= tq.negative_marks if test.negative_marking_enabled
        wrong += 1
        tq.question.update_stats(false, question_wise_time[tq.question_id.to_s])
      end
    end

    self.score = total_score
    self.percentage = (total_score / test.total_marks * 100).round(2)
    self.total_questions = test.test_questions.count
    self.correct_answers = correct
    self.wrong_answers = wrong
    self.unanswered = unanswered
  end

  def calculate_percentile
    better_scores = UserTestAttempt
      .where(test_id: test_id)
      .where('score > ?', score)
      .count

    total_attempts = UserTestAttempt.where(test_id: test_id).count

    return 100 if total_attempts <= 1

    ((total_attempts - better_scores - 1).to_f / (total_attempts - 1) * 100).round(2)
  end

  private

  def set_attempt_number
    last_attempt = user.user_test_attempts.where(test_id: test_id).maximum(:attempt_number) || 0
    self.attempt_number = last_attempt + 1
  end

  def initialize_answers
    self.answers ||= {}
    self.question_wise_time ||= {}
    self.analysis ||= {}
  end
end
```

### 6. Writing Question & Answer Models

```bash
rails generate model WritingQuestion subject:references topic:references question_type:string question_text:text question_context:text word_limit:integer marks:decimal time_limit_minutes:integer difficulty:string directive_keywords:text evaluation_criteria:jsonb model_answer:text model_answer_url:text key_points:text suggested_structure:jsonb pyq_year:integer pyq_paper:string tags:text current_affairs_date:date relevance_score:integer created_by:references

rails generate model UserAnswer user:references writing_question:references answer_text:text word_count:integer time_taken_minutes:integer submission_type:string file_url:text submitted_at:datetime ai_evaluation:jsonb ai_score:decimal ai_evaluated_at:datetime mentor_evaluation:jsonb mentor_score:decimal mentor_evaluated_at:datetime evaluator:references final_score:decimal status:string revision_number:integer original_answer:references is_public:boolean like_count:integer
```

```ruby
# app/models/writing_question.rb
class WritingQuestion < ApplicationRecord
  belongs_to :subject, optional: true
  belongs_to :topic, optional: true
  belongs_to :created_by, class_name: 'User', optional: true

  has_many :user_answers, dependent: :destroy

  # Validations
  validates :question_text, presence: true
  validates :question_type, inclusion: { in: %w[essay case_study general analytical] }, allow_nil: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :pyqs, -> { where.not(pyq_year: nil) }
  scope :by_type, ->(type) { where(question_type: type) }

  # Search
  searchkick

  # Methods
  def is_pyq?
    pyq_year.present?
  end

  def is_current_affairs?
    current_affairs_date.present?
  end
end

# app/models/user_answer.rb
class UserAnswer < ApplicationRecord
  belongs_to :user
  belongs_to :writing_question
  belongs_to :evaluator, class_name: 'User', optional: true
  belongs_to :original_answer, class_name: 'UserAnswer', optional: true

  has_one_attached :uploaded_file
  has_many :revisions, class_name: 'UserAnswer', foreign_key: 'original_answer_id'

  # Validations
  validates :answer_text, presence: true, unless: :file_url?
  validates :submission_type, inclusion: { in: %w[typed uploaded] }
  validates :status, inclusion: { in: %w[submitted ai_evaluated mentor_review completed] }

  # Scopes
  scope :pending_evaluation, -> { where(status: ['submitted', 'ai_evaluated']) }
  scope :evaluated, -> { where(status: ['mentor_review', 'completed']) }
  scope :recent, -> { order(submitted_at: :desc) }

  # Callbacks
  before_create :calculate_word_count
  after_create :enqueue_ai_evaluation

  # Methods
  def evaluate_with_ai
    AiAnswerEvaluationService.new(self).evaluate
  end

  def evaluate_by_mentor(mentor, evaluation_data)
    self.evaluator = mentor
    self.mentor_evaluation = evaluation_data
    self.mentor_score = evaluation_data['total_score']
    self.mentor_evaluated_at = Time.current
    self.final_score = mentor_score
    self.status = 'completed'
    save
  end

  def is_revision?
    original_answer_id.present?
  end

  private

  def calculate_word_count
    self.word_count = answer_text.split.size if answer_text.present?
  end

  def enqueue_ai_evaluation
    AiEvaluationJob.perform_later(id)
  end
end
```

## Services & Background Jobs

### Authentication Service

```ruby
# app/services/authentication_service.rb
class AuthenticationService
  def self.encode_token(payload)
    payload[:exp] = 24.hours.from_now.to_i
    JWT.encode(payload, Rails.application.credentials.secret_key_base)
  end

  def self.decode_token(token)
    JWT.decode(token, Rails.application.credentials.secret_key_base)[0]
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end

  def self.authenticate(email, password)
    user = User.find_by(email: email.downcase)
    return nil unless user&.authenticate(password)
    user
  end
end
```

### AI Answer Evaluation Service

```ruby
# app/services/ai_answer_evaluation_service.rb
class AiAnswerEvaluationService
  def initialize(user_answer)
    @user_answer = user_answer
    @question = user_answer.writing_question
  end

  def evaluate
    response = call_ai_api

    @user_answer.update(
      ai_evaluation: response,
      ai_score: response['total_score'],
      ai_evaluated_at: Time.current,
      status: 'ai_evaluated'
    )

    response
  end

  private

  def call_ai_api
    # Call to Python AI service (Ollama)
    conn = Faraday.new(url: ENV['AI_SERVICE_URL'])

    response = conn.post('/api/v1/evaluate_answer') do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = {
        question: @question.question_text,
        answer: @user_answer.answer_text,
        word_limit: @question.word_limit,
        marks: @question.marks,
        evaluation_criteria: @question.evaluation_criteria
      }.to_json
    end

    JSON.parse(response.body)
  rescue => e
    Rails.logger.error "AI Evaluation failed: #{e.message}"
    { error: e.message }
  end
end
```

### Study Plan Generator Service

```ruby
# app/services/study_plan_generator_service.rb
class StudyPlanGeneratorService
  def initialize(user)
    @user = user
    @profile = user.student_profile
  end

  def generate
    return nil unless @profile&.target_exam_date

    days_until_exam = (@profile.target_exam_date - Date.current).to_i
    return nil if days_until_exam <= 0

    plan = StudyPlan.create!(
      user: @user,
      start_date: Date.current,
      target_exam_date: @profile.target_exam_date,
      total_days: days_until_exam,
      phase_breakdown: calculate_phases(days_until_exam),
      daily_schedule: generate_daily_schedule
    )

    generate_tasks(plan)
    plan
  end

  private

  def calculate_phases(total_days)
    {
      foundation: {
        days: (total_days * 0.4).to_i,
        objectives: ['Complete NCERT', 'Basic concepts', 'Start answer writing']
      },
      practice: {
        days: (total_days * 0.35).to_i,
        objectives: ['Practice questions', 'Mock tests', 'Current affairs']
      },
      revision: {
        days: (total_days * 0.25).to_i,
        objectives: ['Revision', 'Full mocks', 'Weak areas']
      }
    }
  end

  def generate_daily_schedule
    {
      morning: { hours: 3, activities: ['NCERTs', 'Static content'] },
      afternoon: { hours: 2, activities: ['Practice questions', 'CSAT'] },
      evening: { hours: 3, activities: ['Current affairs', 'Answer writing'] }
    }
  end

  def generate_tasks(plan)
    # Generate tasks for next 7 days
    subjects = Subject.active.ordered

    7.times do |day_offset|
      task_date = Date.current + day_offset.days
      subject = subjects[day_offset % subjects.length]

      DailyTask.create!(
        user: @user,
        study_plan: plan,
        task_date: task_date,
        task_type: 'study',
        title: "Study #{subject.name}",
        estimated_minutes: 180,
        priority: 'high'
      )
    end
  end
end
```

Continue in next message...
