# Generators and Commands Reference

## Rails Commands

### Server and Console

```bash
# Start development server
bin/rails server
bin/rails s
bin/rails s -p 3001              # Custom port
bin/rails s -b 0.0.0.0           # Bind to all interfaces
bin/rails s -e production        # Production mode

# Interactive console
bin/rails console
bin/rails c
bin/rails c --sandbox            # Rollback all changes on exit
bin/rails c -e production        # Production console

# Database console
bin/rails dbconsole
bin/rails db
```

### Routes

```bash
# List all routes
bin/rails routes
bin/rails routes -g products     # Grep filter
bin/rails routes -c products     # Filter by controller
bin/rails routes --expanded      # Detailed format
```

### Database

```bash
# Create database
bin/rails db:create
bin/rails db:create:all          # All environments

# Run migrations
bin/rails db:migrate
bin/rails db:migrate:status      # Show migration status
bin/rails db:migrate VERSION=20240101000000  # Specific version

# Rollback
bin/rails db:rollback
bin/rails db:rollback STEP=3     # Rollback 3 migrations

# Reset (drop, create, migrate)
bin/rails db:reset

# Seed data
bin/rails db:seed
bin/rails db:seed:replant        # Truncate then seed

# Schema
bin/rails db:schema:dump         # Dump to schema.rb
bin/rails db:schema:load         # Load from schema.rb

# Structure (SQL format)
bin/rails db:structure:dump
bin/rails db:structure:load

# Database system change
bin/rails db:system:change --to=postgresql
```

### Assets

```bash
bin/rails assets:precompile      # Compile assets
bin/rails assets:clean           # Remove old assets
bin/rails assets:clobber         # Remove all compiled assets
```

### Testing

```bash
bin/rails test                   # All tests
bin/rails test:models            # Model tests
bin/rails test:controllers       # Controller tests
bin/rails test:system            # System tests
bin/rails test test/models/user_test.rb  # Specific file
bin/rails test test/models/user_test.rb:42  # Specific line
bin/rails test -n /user/         # Name pattern
bin/rails test -v                # Verbose
bin/rails test -f                # Fail fast
```

### Utilities

```bash
bin/rails runner "puts User.count"  # Execute Ruby
bin/rails runner script/daily_tasks.rb

bin/rails notes                  # Find TODO/FIXME/OPTIMIZE
bin/rails notes:todo             # Only TODO
bin/rails notes:custom ANNOTATION=REVIEW

bin/rails stats                  # Code statistics

bin/rails secret                 # Generate secret key
bin/rails credentials:edit       # Edit encrypted credentials
bin/rails credentials:show       # Show credentials

bin/rails initializers           # List all initializers
bin/rails middleware             # List middleware stack

bin/rails tmp:clear              # Clear tmp/
bin/rails tmp:cache:clear        # Clear cache
bin/rails log:clear              # Clear logs
```

---

## Generators

### Model

```bash
bin/rails generate model User name:string email:string

# With associations
bin/rails g model Post title:string body:text user:references

# With index
bin/rails g model Product name:string:index sku:string:uniq

# Specify types
bin/rails g model Order
  total:decimal{8,2}
  status:integer
  shipped_at:datetime
  metadata:jsonb
```

### Controller

```bash
bin/rails generate controller Products index show

# Skip views
bin/rails g controller Api::Products index show --skip-template-engine

# API only
bin/rails g controller Api::V1::Users index show --api
```

### Migration

```bash
# Generic migration
bin/rails generate migration AddStatusToOrders

# Add column (magic naming)
bin/rails g migration AddPublishedAtToArticles published_at:datetime

# Remove column
bin/rails g migration RemoveNameFromUsers name:string

# Create table
bin/rails g migration CreateProducts name:string price:decimal

# Add reference
bin/rails g migration AddUserToComments user:references

# Join table
bin/rails g migration CreateJoinTableCategoriesProducts categories products
```

### Scaffold

```bash
# Full CRUD scaffold
bin/rails generate scaffold Product name:string price:decimal description:text

# API scaffold
bin/rails g scaffold Product name price:decimal --api

# Skip parts
bin/rails g scaffold Product name --skip-test --skip-jbuilder
```

### Resource

```bash
# Model + migration + route + empty controller
bin/rails generate resource Product name:string price:decimal
```

### Mailer

```bash
bin/rails generate mailer User welcome reset_password
```

### Job

```bash
bin/rails generate job ProcessOrder
```

### Channel (Action Cable)

```bash
bin/rails generate channel Chat speak
```

### Stimulus Controller

```bash
bin/rails generate stimulus search
bin/rails g stimulus clipboard
```

### Task (Rake)

```bash
bin/rails generate task maintenance cleanup reset
```

### System Test

```bash
bin/rails generate system_test Users
```

### Integration Test

```bash
bin/rails generate integration_test UserFlows
```

### Authentication (Rails 8)

```bash
bin/rails generate authentication
```

Generates:

- User model with `has_secure_password`
- Session model for session management
- Authentication concern
- Login/logout views and controller

---

## Generator Options

### Common Flags

```bash
--skip-test              # Skip test files
--skip-system-test       # Skip system tests
--skip-routes            # Don't add routes
--skip-helper            # Skip helper file
--skip-jbuilder          # Skip JSON builder
--skip-template-engine   # Skip view templates
--api                    # API-only (no views)
--force                  # Overwrite existing files
--pretend               # Dry run
--quiet                 # Suppress output
```

### Examples

```bash
# API controller
bin/rails g controller Api::V1::Products index show --api --skip-routes

# Model without tests
bin/rails g model Product name:string --skip-test

# Preview changes
bin/rails g scaffold Product name --pretend
```

---

## Destroy (Undo)

```bash
# Reverse any generator
bin/rails destroy model Product
bin/rails destroy controller Products
bin/rails destroy scaffold Product
bin/rails destroy migration AddStatusToOrders

# Short form
bin/rails d model Product
```

---

## Custom Generators

### Location

```text
lib/generators/
├── my_generator/
│   ├── my_generator_generator.rb
│   └── templates/
│       └── template.rb.erb
```

### Basic Generator

```ruby
# lib/generators/service/service_generator.rb
class ServiceGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  def create_service_file
    template "service.rb.erb", File.join("app/services", class_path, "#{file_name}.rb")
  end

  def create_test_file
    template "service_test.rb.erb", File.join("test/services", class_path, "#{file_name}_test.rb")
  end
end
```

```erb
<%# lib/generators/service/templates/service.rb.erb %>
<% module_namespacing do -%>
class <%= class_name %>
  def initialize
  end

  def call
  end
end
<% end -%>
```

### Using Custom Generator

```bash
bin/rails generate service UserRegistration
```

---

## Rake Tasks

### List Tasks

```bash
bin/rails --tasks
bin/rails -T
bin/rails -T db                  # Filter
```

### Create Custom Task

```ruby
# lib/tasks/maintenance.rake
namespace :maintenance do
  desc "Clean up old records"
  task cleanup: :environment do
    puts "Cleaning up..."
    OldRecord.where("created_at < ?", 1.year.ago).delete_all
    puts "Done!"
  end

  desc "Generate daily report"
  task :report, [:date] => :environment do |t, args|
    date = args[:date] || Date.today
    ReportGenerator.new(date).generate
  end
end
```

### Run Tasks

```bash
bin/rails maintenance:cleanup
bin/rails "maintenance:report[2024-01-01]"
```

---

## Credentials

### Edit Credentials

```bash
EDITOR="code --wait" bin/rails credentials:edit
EDITOR=vim bin/rails credentials:edit

# Environment-specific
bin/rails credentials:edit --environment production
```

### Credentials Structure

```yaml
# config/credentials.yml.enc (decrypted view)
secret_key_base: abc123...

aws:
  access_key_id: AKIA...
  secret_access_key: secret...

stripe:
  publishable_key: pk_live_...
  secret_key: sk_live_...
```

### Access Credentials

```ruby
Rails.application.credentials.aws[:access_key_id]
Rails.application.credentials.dig(:aws, :access_key_id)
Rails.application.credentials.stripe&.secret_key
```

---

## Environment Configuration

### Rails Environments

```bash
# Run in specific environment
RAILS_ENV=production bin/rails console
RAILS_ENV=test bin/rails db:migrate
```

### Custom Configuration

```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    config.my_setting = "value"
  end
end

# Access
Rails.application.config.my_setting

# config/environments/production.rb
config.my_setting = "production_value"
```

### Environment Variables

```ruby
# Access
ENV["DATABASE_URL"]
ENV.fetch("API_KEY") { raise "API_KEY required" }
ENV.fetch("OPTIONAL_KEY", "default")
```

---

## Useful Patterns

### Runner Scripts

```ruby
# script/daily_tasks.rb
#!/usr/bin/env ruby
require_relative "../config/environment"

User.inactive.find_each do |user|
  UserMailer.with(user: user).reminder.deliver_later
end
```

```bash
bin/rails runner script/daily_tasks.rb
```

### Task Dependencies

```ruby
task full_reset: [:environment, "db:drop", "db:create", "db:migrate", "db:seed"] do
  puts "Database fully reset!"
end
```

### Interactive Tasks

```ruby
task :confirm_deploy => :environment do
  print "Deploy to production? (yes/no): "
  input = STDIN.gets.chomp
  abort "Cancelled" unless input == "yes"
  # proceed with deploy
end
```
