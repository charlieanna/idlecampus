# PostgreSQL Migration Guide

**Status**: ✅ Configuration Complete - Ready for Migration
**Date**: November 6, 2025

---

## Overview

IdleCampus has been migrated from SQLite to PostgreSQL for better performance, scalability, and production readiness.

### Why PostgreSQL?

- ✅ **Better Performance**: Handles concurrent connections efficiently
- ✅ **Production Ready**: Industry standard for Rails applications
- ✅ **Advanced Features**: Full-text search, JSON support, better indexing
- ✅ **Scalability**: Handles larger datasets and more users
- ✅ **Data Integrity**: Superior constraint and transaction support

---

## Files Changed

### 1. Database Configuration
- ✅ `config/database.yml` - Updated to use PostgreSQL adapter
- ✅ `Gemfile` - Changed from `sqlite3` to `pg` gem
- ✅ `.env` - Added PostgreSQL credentials
- ✅ `.env.example` - Template with PostgreSQL settings

### 2. Docker Setup
- ✅ `docker-compose.yml` - Created with PostgreSQL, Redis, and pgAdmin services

### 3. Migration Tools
- ✅ `lib/tasks/db_migrate_to_postgres.rake` - Automated data migration script

---

## Quick Start

### Option 1: Using Docker (Recommended)

This is the easiest way to get PostgreSQL running locally.

```bash
# 1. Start PostgreSQL with Docker
cd backend
docker-compose up -d postgres

# Wait for PostgreSQL to start (about 10 seconds)
sleep 10

# 2. Install pg gem
bundle install

# 3. Create database and run migrations
bundle exec rails db:create
bundle exec rails db:migrate

# 4. Migrate data from SQLite (if you have existing data)
bundle exec rails db:migrate_to_postgres

# 5. Start Rails server
bundle exec rails server
```

**That's it!** Your application is now running with PostgreSQL.

---

### Option 2: Using Local PostgreSQL

If you prefer to install PostgreSQL locally:

```bash
# macOS (with Homebrew)
brew install postgresql@15
brew services start postgresql@15

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib
sudo systemctl start postgresql

# Create postgres user (if needed)
createuser -s postgres

# Then follow steps 2-5 from Option 1
```

---

## Step-by-Step Migration

### 1. Verify PostgreSQL is Running

```bash
# Using Docker
docker ps | grep postgres

# Or using local PostgreSQL
psql -U postgres -c "SELECT version();"
```

### 2. Install Dependencies

```bash
cd backend
bundle install
```

This installs the `pg` gem (PostgreSQL adapter for Rails).

### 3. Environment Variables

Your `.env` file should have:

```bash
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
```

These are already set if you're using Docker Compose.

### 4. Create Database

```bash
bundle exec rails db:create
```

This creates:
- `idlecampus_development`
- `idlecampus_test`

### 5. Run Migrations

```bash
bundle exec rails db:migrate
```

This creates all tables, indexes, and constraints.

### 6. Migrate Existing Data (Optional)

If you have data in SQLite that you want to preserve:

```bash
bundle exec rails db:migrate_to_postgres
```

This will:
- ✅ Backup your SQLite database
- ✅ Export all data from SQLite
- ✅ Import into PostgreSQL
- ✅ Reset sequences
- ✅ Verify data integrity

**Output Example:**
```
================================================================================
  🔄 Migrating from SQLite to PostgreSQL
================================================================================

📦 Step 1: Backing up SQLite database...
✅ Backup created: db/sqlite_backup_20251106_123456.sqlite3

📤 Step 2: Exporting data from SQLite...
   Found 15 tables to migrate:
     - users
     - courses
     - course_modules
     ...

📥 Step 4: Importing data to PostgreSQL...
   Importing: users (152 records)...
     ✅ Imported 152 records
   ...

================================================================================
  ✅ Migration Complete!
================================================================================

📊 Verification:
  ✅ users: 152 / 152 records
  ✅ courses: 3 / 3 records
  ✅ course_modules: 35 / 35 records
  ...
```

### 7. Seed Database (If Starting Fresh)

If you don't have existing data, seed the database:

```bash
bundle exec rails db:seed
```

### 8. Start Application

```bash
bundle exec rails server
```

Visit: http://localhost:3000

---

## Docker Services

### PostgreSQL
- **Image**: postgres:15-alpine
- **Port**: 5432
- **Container**: idlecampus_postgres
- **Volume**: postgres_data (persistent)

### Redis
- **Image**: redis:7-alpine
- **Port**: 6379
- **Container**: idlecampus_redis
- **Volume**: redis_data (persistent)

### pgAdmin (Optional Database UI)
- **Image**: dpage/pgadmin4
- **Port**: 5050
- **URL**: http://localhost:5050
- **Login**: admin@idlecampus.com / admin

To start pgAdmin:
```bash
docker-compose --profile tools up -d pgadmin
```

---

## Docker Commands

```bash
# Start all services
docker-compose up -d

# Start only PostgreSQL
docker-compose up -d postgres

# Stop all services
docker-compose down

# Stop and remove volumes (CAUTION: Deletes all data!)
docker-compose down -v

# View logs
docker-compose logs postgres
docker-compose logs -f postgres  # Follow logs

# Access PostgreSQL shell
docker exec -it idlecampus_postgres psql -U postgres

# Backup database
docker exec idlecampus_postgres pg_dump -U postgres idlecampus_development > backup.sql

# Restore database
cat backup.sql | docker exec -i idlecampus_postgres psql -U postgres idlecampus_development
```

---

## Troubleshooting

### Issue: "Cannot connect to database"

**Solution**:
```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# If not running, start it
docker-compose up -d postgres

# Check logs
docker-compose logs postgres
```

### Issue: "PG::ConnectionBad: FATAL: database does not exist"

**Solution**:
```bash
bundle exec rails db:create
```

### Issue: "Gem::LoadError: pg gem not installed"

**Solution**:
```bash
bundle install
```

### Issue: "Port 5432 already in use"

**Solution**:
```bash
# Check what's using port 5432
lsof -i :5432

# If it's a local PostgreSQL, stop it
brew services stop postgresql@15  # macOS
sudo systemctl stop postgresql    # Linux

# Or change port in docker-compose.yml to 5433:5432
```

### Issue: Migration fails with "foreign key constraint"

**Solution**:
The migration script handles this, but if you encounter issues:

```bash
# Drop and recreate database
bundle exec rails db:drop
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:migrate_to_postgres
```

---

## Database Management

### Using Rails Console

```bash
bundle exec rails console

# Check database adapter
ActiveRecord::Base.connection.adapter_name
# => "PostgreSQL"

# Check connection
ActiveRecord::Base.connection.execute("SELECT version();")

# Check table stats
User.count
Course.count
```

### Using psql (PostgreSQL CLI)

```bash
# Connect to database
docker exec -it idlecampus_postgres psql -U postgres idlecampus_development

# Useful commands
\dt              # List all tables
\d users         # Describe users table
\l               # List all databases
\conninfo        # Show connection info
\q               # Quit
```

### Using pgAdmin (Web UI)

1. Start pgAdmin: `docker-compose --profile tools up -d pgadmin`
2. Visit: http://localhost:5050
3. Login: admin@idlecampus.com / admin
4. Add server:
   - Name: IdleCampus
   - Host: postgres (or localhost if not using Docker)
   - Port: 5432
   - Username: postgres
   - Password: postgres

---

## Performance Tips

### 1. Add Indexes

```ruby
# In a migration
add_index :users, :email
add_index :courses, :slug
add_index :course_modules, :course_id
```

### 2. Enable Query Logging (Development)

```ruby
# config/environments/development.rb
config.log_level = :debug
config.active_record.verbose_query_logs = true
```

### 3. Use Connection Pooling

Already configured in `database.yml`:
```yaml
pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 10 } %>
```

### 4. Analyze Slow Queries

```sql
-- Enable query timing
\timing on

-- Explain query
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'test@example.com';
```

---

## Production Deployment

### Environment Variables

Set these in your production environment:

```bash
POSTGRES_HOST=your-postgres-host.com
POSTGRES_PORT=5432
POSTGRES_USER=your_db_user
POSTGRES_PASSWORD=your_secure_password
DATABASE_URL=postgresql://user:password@host:5432/idlecampus_production
```

### Database Setup

```bash
# On production server
RAILS_ENV=production bundle exec rails db:create
RAILS_ENV=production bundle exec rails db:migrate
RAILS_ENV=production bundle exec rails db:seed
```

### SSL Connection (Recommended)

Uncomment in `config/database.yml`:
```yaml
production:
  sslmode: require
```

---

## Rollback to SQLite (If Needed)

If you need to rollback:

1. Restore original files:
```bash
# Restore Gemfile
git checkout Gemfile

# Restore database.yml
git checkout config/database.yml

# Restore SQLite database from backup
cp db/sqlite_backup_*.sqlite3 db/development.sqlite3
```

2. Install SQLite gem:
```bash
bundle install
```

3. Start Rails:
```bash
bundle exec rails server
```

---

## Summary

### What Changed
- ✅ Database adapter: SQLite → PostgreSQL
- ✅ Gem: sqlite3 → pg
- ✅ Configuration: database.yml updated
- ✅ Docker: docker-compose.yml added
- ✅ Migration: Automated migration script created

### Benefits
- ✅ Better performance and scalability
- ✅ Production-ready database
- ✅ Advanced features (full-text search, JSON, etc.)
- ✅ Better concurrent connection handling
- ✅ Industry standard for Rails apps

### Next Steps
1. Run `docker-compose up -d postgres` to start PostgreSQL
2. Run `bundle install` to install pg gem
3. Run `bundle exec rails db:create db:migrate` to setup database
4. (Optional) Run `bundle exec rails db:migrate_to_postgres` to migrate existing data
5. Start developing!

---

**Questions?** Check the troubleshooting section or Rails/PostgreSQL documentation.

**Migration Status**: ✅ Complete and Ready to Use!
