# Complete UPSC Migration Files

Copy each section below into the corresponding migration file.

## 20251107051558_create_upsc_tests.rb

```ruby
class CreateUpscTests < ActiveRecord::Migration[6.0]
  def change
    create_table :upsc_tests do |t|
      t.string :test_type, null: false
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
    add_index :upsc_tests, :is_live
  end
end
```

## 20251107051559_create_upsc_test_questions.rb

```ruby
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
    add_index :upsc_test_questions, :order_index
  end
end
```

## 20251107051560_create_upsc_user_test_attempts.rb

```ruby
class CreateUpscUserTestAttempts < ActiveRecord::Migration[6.0]
  def change
    create_table :upsc_user_test_attempts do |t|
      t.references :user, foreign_key: true, null: false
      t.references :upsc_test, foreign_key: true, null: false
      t.integer :attempt_number, default: 1
      t.datetime :started_at, null: false
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

    add_index :upsc_user_test_attempts, [:user_id, :upsc_test_id]
    add_index :upsc_user_test_attempts, :status
    add_index :upsc_user_test_attempts, :submitted_at
  end
end
```

## 20251107051603_create_upsc_writing_questions.rb

```ruby
class CreateUpscWritingQuestions < ActiveRecord::Migration[6.0]
  def change
    create_table :upsc_writing_questions do |t|
      t.references :upsc_subject, foreign_key: true
      t.references :upsc_topic, foreign_key: true
      t.string :question_type
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
    add_index :upsc_writing_questions, :current_affairs_date
  end
end
```

## 20251107051604_create_upsc_user_answers.rb

```ruby
class CreateUpscUserAnswers < ActiveRecord::Migration[6.0]
  def change
    create_table :upsc_user_answers do |t|
      t.references :user, foreign_key: true, null: false
      t.references :upsc_writing_question, foreign_key: true, null: false
      t.text :answer_text, null: false
      t.integer :word_count
      t.integer :time_taken_minutes
      t.string :submission_type, default: 'typed'
      t.string :file_url
      t.datetime :submitted_at, null: false
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

    add_index :upsc_user_answers, [:user_id, :upsc_writing_question_id], name: 'index_user_answers_on_user_and_question'
    add_index :upsc_user_answers, :status
    add_index :upsc_user_answers, :submitted_at
  end
end
```

## 20251107051605_create_upsc_news_articles.rb

```ruby
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
      t.string :importance_level
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
    add_index :upsc_news_articles, :is_featured
  end
end
```

## 20251107051606_create_upsc_study_plans.rb

```ruby
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
    add_index :upsc_study_plans, :target_exam_date
  end
end
```

## 20251107051607_create_upsc_daily_tasks.rb

```ruby
class CreateUpscDailyTasks < ActiveRecord::Migration[6.0]
  def change
    create_table :upsc_daily_tasks do |t|
      t.references :user, foreign_key: true, null: false
      t.references :upsc_study_plan, foreign_key: true
      t.date :task_date, null: false
      t.string :task_type
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
    add_index :upsc_daily_tasks, [:task_date, :status]
  end
end
```

## 20251107051608_create_upsc_revisions.rb

```ruby
class CreateUpscRevisions < ActiveRecord::Migration[6.0]
  def change
    create_table :upsc_revisions do |t|
      t.references :user, foreign_key: true, null: false
      t.references :upsc_topic, foreign_key: true
      t.string :revision_type
      t.date :scheduled_for, null: false
      t.datetime :completed_at
      t.integer :interval_index, default: 0
      t.integer :performance_rating
      t.integer :time_spent_minutes
      t.text :notes
      t.string :status, default: 'pending'

      t.timestamps
    end

    add_index :upsc_revisions, [:user_id, :scheduled_for]
    add_index :upsc_revisions, :status
    add_index :upsc_revisions, [:scheduled_for, :status]
  end
end
```

## 20251107051609_create_upsc_user_progress.rb

```ruby
class CreateUpscUserProgress < ActiveRecord::Migration[6.0]
  def change
    create_table :upsc_user_progress do |t|
      t.references :user, foreign_key: true, null: false
      t.references :upsc_topic, foreign_key: true, null: false
      t.string :status, default: 'not_started'
      t.integer :completion_percentage, default: 0
      t.integer :confidence_level
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
    add_index :upsc_user_progress, :last_accessed_at
  end
end
```

## Quick Apply Script

Run this in your backend directory:

```bash
# Copy each migration content from above into the respective files
# Then run:
rails db:migrate
```

Or use this command to apply all at once (after copying contents):

```bash
rails db:migrate:status  # Check pending migrations
rails db:migrate         # Run all pending migrations
```
