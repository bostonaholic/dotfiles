# Modern Rails 8 Patterns

## Solid Trifecta

Rails 8 replaces Redis/Memcached dependencies with database-backed adapters.

### Solid Queue (Default Job Backend)

Database-backed job queuing using `FOR UPDATE SKIP LOCKED` for efficient
queue management. Runs as a Puma plugin in production.

```yaml
# config/queue.yml
default: &default
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: "*"
      threads: 3
      processes: 1
      polling_interval: 0.1
```

Recurring jobs:

```yaml
# config/recurring.yml
production:
  periodic_cleanup:
    class: CleanupJob
    schedule: every day at 3am
```

### Solid Cache

Uses disk storage for bigger cache at lower cost:

```ruby
# config/environments/production.rb
config.cache_store = :solid_cache_store
```

### Solid Cable

Database-backed Action Cable with fast polling:

```ruby
# config/cable.yml
production:
  adapter: solid_cable
  polling_interval: 0.1.seconds
  message_retention: 1.day
```

### Database Configuration

```yaml
# config/database.yml
production:
  primary:
    <<: *default
    database: app_production
  queue:
    <<: *default
    database: app_production_queue
    migrations_paths: db/queue_migrate
  cache:
    <<: *default
    database: app_production_cache
    migrations_paths: db/cache_migrate
  cable:
    <<: *default
    database: app_production_cable
    migrations_paths: db/cable_migrate
```

## Built-in Authentication

```bash
bin/rails generate authentication
```

Generates: User model with `has_secure_password`, Session model with secure
tokens, Current model via `ActiveSupport::CurrentAttributes`, Authentication
concern with `require_authentication`/`allow_unauthenticated_access`, rate
limiting on login, password reset with 15-minute expiring tokens.

Use `User.authenticate_by(email:, password:)` for timing-safe authentication.

## params.expect (Rails 8)

Replaces `params.require(:key).permit(...)` with stricter type enforcement:

```ruby
# BEFORE (Rails 7)
params.require(:user).permit(:name, :email)

# AFTER (Rails 8)
params.expect(user: [:name, :email])

# Scalar parameter
params.expect(:id)

# Nested hash
params.expect(user: [:name, :email, { address: [:street, :city] }])

# Array of hashes (double bracket syntax)
params.expect(post: [:title, categories: [[:name]]])

# Conditional parameters
def user_params
  if Current.user.admin?
    params.expect(user: [:name, :email, :admin])
  else
    params.expect(user: [:name, :email])
  end
end
```

If parameters do not match the expected structure, raises
`ActionController::ParameterMissing` (400 Bad Request) instead of allowing
unexpected types that cause 500 errors.

## normalizes (Rails 7.1+)

Replaces manual `before_save` callbacks for data normalization:

```ruby
class User < ApplicationRecord
  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :phone, with: ->(phone) { phone.delete("^0-9").delete_prefix("1") }
  normalizes :name, with: ->(name) { name.strip.squeeze(" ") }
end

# Applied on assignment AND in queries
user = User.new(email: "  TEST@EXAMPLE.COM  ")
user.email  # => "test@example.com"

User.where(email: "  TEST@EXAMPLE.COM  ")
# Queries with: "test@example.com"
```

## generates_token_for (Rails 7.1+)

```ruby
class User < ApplicationRecord
  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end

  generates_token_for :email_confirmation, expires_in: 24.hours do
    email
  end
end

# Generate
token = user.generate_token_for(:password_reset)

# Find (nil if invalid/expired)
user = User.find_by_token_for(:password_reset, token)

# Token auto-invalidates when tracked attribute changes
user.update!(password: "new_password")
User.find_by_token_for(:password_reset, token)  # => nil
```

## strict_loading

Prevents N+1 queries by raising on lazy loading:

```ruby
# Global (recommended: n_plus_one_only mode)
# config/environments/development.rb
config.active_record.strict_loading_by_default = true
config.active_record.strict_loading_mode = :n_plus_one_only

# Production: log instead of raise
# config/environments/production.rb
config.active_record.action_on_strict_loading_violation = :log

# Per-model
class Movie < ApplicationRecord
  self.strict_loading_by_default = true
end

# Per-association
has_many :reviews, strict_loading: true

# Per-query
Movie.strict_loading.find(1)
```

`:n_plus_one_only` mode catches actual N+1 patterns without false positives.

## Enum Patterns (Rails 8)

```ruby
class Order < ApplicationRecord
  # New syntax -- one enum call per attribute
  enum :status, { pending: 0, processing: 1, shipped: 2, delivered: 3 }

  # With prefix/suffix for name collisions
  enum :comments_status, { active: 0, inactive: 1 }, prefix: :comments

  # With validation
  enum :status, { pending: 0, shipped: 1 }, validate: true
end
```

Always use explicit integer mappings. Never rely on array position. Add new
values at the end. Never reorder or remove existing mappings. The old keyword
argument syntax (`enum status: {}`) is removed in Rails 8.

## Hotwire Decision Framework

1. **Can HTML/CSS solve it?** Use standard rendering + Turbo Drive (free)
2. **Need isolated region updates?** Use Turbo Frames
3. **Need multiple regions updated?** Use Turbo Streams
4. **Need micro-interactions or external JS?** Use Stimulus

### Turbo Frames

For focused interactivity on isolated page regions:

```erb
<%# Lazy-loaded frame %>
<%= turbo_frame_tag "comments", src: comments_path, loading: :lazy do %>
  <p>Loading comments...</p>
<% end %>

<%# Inline edit pattern %>
<%= turbo_frame_tag dom_id(@message) do %>
  <%= render @message %>
  <%= link_to "Edit", edit_message_path(@message) %>
<% end %>
```

Key constraint: one frame at a time, replace only.

### Turbo Streams

For updating multiple DOM elements or real-time async updates:

```erb
<%# app/views/messages/create.turbo_stream.erb %>
<%= turbo_stream.prepend "messages", @message %>
<%= turbo_stream.update "message_count", Message.count %>
<%= turbo_stream.replace "new_message_form", partial: "messages/form" %>
```

Available actions: `append`, `prepend`, `replace`, `update`, `remove`,
`before`, `after`, `morph`, `refresh`.

```ruby
# Model broadcasts for real-time
class Message < ApplicationRecord
  broadcasts_to :room
end
```

### Turbo Anti-Patterns

- Using Stimulus for HTML templating when Turbo Frames suffice
- Monolithic "whole-page" Stimulus controllers
- Turbo Streams when a simple Frame replacement would work
- Defaulting to JavaScript when simpler Turbo solutions exist

## Stimulus Conventions

### Controller Naming and Structure

```javascript
// app/javascript/controllers/toggle_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // 1. Static declarations
  static targets = ["tooltip"]
  static values = { position: { type: String, default: "top" } }

  // 2. Lifecycle methods
  connect() { this.#setup() }
  disconnect() { this.#teardown() }

  // 3. Public actions (event handlers)
  show() { this.tooltipTarget.classList.remove("hidden") }
  hide() { this.tooltipTarget.classList.add("hidden") }

  // 4. Private methods
  #setup() { /* ... */ }
  #teardown() { /* ... */ }
}
```

Rules:

- Name controllers to reflect behavior, not pages (`toggle`, `clipboard`)
- One controller per file, anonymous class syntax
- Single responsibility -- split large controllers
- Use **targets** for DOM elements within scope
- Use **outlets** for cross-controller communication
- Pass configuration through data attributes, not hard-coded values
- Compose multiple small controllers rather than one large one

## Import Maps

Default for Rails 8. Use when sticking to the Hotwire stack without
TypeScript, JSX, or CSS-in-JS:

```ruby
# config/importmap.rb
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin_all_from "app/javascript/controllers", under: "controllers"
```

```bash
bin/importmap pin lodash              # Pin from CDN
bin/importmap pin lodash --download   # Download to vendor/javascript
```

Use a bundler (esbuild, Bun) instead when TypeScript, JSX, tree-shaking,
or heavy client-side JS frameworks are required.

## Modern Ruby Patterns

### Data.define (Ruby 3.2+)

```ruby
Coordinate = Data.define(:latitude, :longitude)
coord = Coordinate.new(latitude: 40.7128, longitude: -74.0060)
coord.frozen?  # => true

# With custom methods
SearchParams = Data.define(:query, :page, :per_page) do
  def offset = (page - 1) * per_page
end
```

### Pattern Matching (Ruby 3.0+)

```ruby
def discount_percentage
  case [membership_tier, years_active]
  in ["gold", (5..)] then 20
  in ["gold", _]      then 15
  in ["silver", _]    then 10
  else                     0
  end
end
```

### Endless Methods (Ruby 3.0+)

```ruby
def full_name = "#{first_name} #{last_name}"
def admin? = role == "admin"
def active? = status == "active"
```

## Current Attributes

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session
  delegate :user, to: :session, allow_nil: true
end
```

Keep minimal. Only explicitly defined `attribute` values reset between
requests. Do not define other instance variables on Current.

## Deployment

### Kamal 2

Zero-downtime deployment with automatic SSL via Let's Encrypt:

```bash
kamal setup     # First-time setup
kamal deploy    # Subsequent deploys
kamal rollback  # Roll back to previous version
```

### Thruster

HTTP proxy in the Rails 8 Dockerfile providing X-Sendfile acceleration,
asset caching, and Gzip/Brotli compression. No Nginx needed.

### Propshaft

Default asset pipeline replacing Sprockets. Provides load paths and digest
stamping for cache-friendly expiry. Aligns with #NOBUILD philosophy.

### Production Essentials

```ruby
# config/environments/production.rb
config.assume_ssl = true
config.force_ssl = true
```

## Performance Patterns

```ruby
# Eager loading
@posts = Post.includes(:author, :comments).where(published: true)

# Counter caches
class Comment < ApplicationRecord
  belongs_to :post, counter_cache: true
end

# Database constraints mirror validations
add_column :products, :comments_count, :integer, default: 0, null: false
add_check_constraint :products, "price >= 0"

# Bulk operations
Product.insert_all([...])
Product.upsert_all([...], unique_by: :sku)

# Batch processing
User.find_each(batch_size: 1000) { |u| u.process! }
User.where(active: false).in_batches { |b| b.update_all(archived: true) }

# Efficient queries
User.where(active: true).pluck(:email)    # single column
User.where(email: "a@b.com").exists?       # existence check
```

## Security Best Practices

1. Use `params.expect` for strong parameters (Rails 8)
2. CSRF protection enabled by default -- never disable
3. Parameterized queries -- never string interpolation for SQL
4. ERB escapes output by default -- never use `raw` without sanitization
5. Call `reset_session` after login to prevent session fixation
6. Rate limit login attempts: `rate_limit to: 10, within: 3.minutes`
7. Track session history (ip_address, user_agent) for security auditing
8. Password reset tokens expire in 15 minutes
