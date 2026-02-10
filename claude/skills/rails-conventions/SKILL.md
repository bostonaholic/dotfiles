---
name: rails-conventions
description: This skill should be used when writing Ruby on Rails code, reviewing Rails pull requests, creating models, controllers, views, tests, or migrations. It enforces opinionated coding conventions for Rails projects including minitest over RSpec, fixtures over factories, vanilla Rails architecture, DHH's controller philosophy, callback discipline, and modern Rails 8 patterns. Automatically triggered when working in any Rails application.
---

# Rails Coding Conventions

## Golden Rules

- ALWAYS use minitest, never use RSpec
- ALWAYS use fixtures, never use factories
- ALWAYS prefer vanilla Rails over additional abstractions
- ALWAYS use `params.expect` over `params.require.permit` (Rails 8)
- ALWAYS add database constraints mirroring model validations
- NEVER put side effects in callbacks (emails, jobs, API calls)
- NEVER nest routes more than one level deep
- NEVER add service objects for simple single-model operations

## Philosophy

Follow DHH's "Vanilla Rails is plenty" approach. Start with the framework's
conventions and reach for additional patterns only when genuine complexity
demands it. Resist the temptation to import patterns from other ecosystems.
Rails is driven by extraction from real applications, not by abstract
architectural ideals.

The progression when complexity grows:

1. Model methods and scopes (default)
2. Concerns for shared traits (`Archivable`, `Searchable`, `Filterable`)
3. Composition within model namespace (`Recording::Incineration`)
4. Form objects for multi-model forms
5. Query objects for complex queries
6. Service objects ONLY for cross-cutting operations

Do not start at step 6.

## Model Organization

Order model internals consistently:

```ruby
class User < ApplicationRecord
  # 1. Constants
  ROLES = %w[admin editor viewer].freeze

  # 2. Enums (hash syntax, explicit integers)
  enum :status, { active: 0, inactive: 1, suspended: 2 }

  # 3. Associations (belongs_to first, then has_one, has_many)
  belongs_to :organization
  has_one :profile, dependent: :destroy
  has_many :posts, dependent: :destroy

  # 4. Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }

  # 5. Normalizations
  normalizes :email, with: ->(email) { email.strip.downcase }

  # 6. Callbacks (data normalization ONLY)
  before_save :generate_slug

  # 7. Scopes
  scope :active, -> { where(status: :active) }
  scope :recent, -> { order(created_at: :desc) }

  # 8. Class methods
  # 9. Instance methods (public)
  # 10. Private methods
end
```

## Controller Conventions

Controllers contain ONLY the 7 standard CRUD actions. Any custom action
becomes a new controller:

```ruby
# BAD: custom action on existing controller
class InboxesController < ApplicationController
  def pendings; end
end

# GOOD: new controller for each resource concept
class Inboxes::PendingsController < ApplicationController
  def index; end
end
```

Keep controllers skinny. Each action invokes at most one operation beyond
an initial find or new. Use `params.expect` for strong parameters:

```ruby
def product_params
  params.expect(product: [:name, :description, :price, :category_id])
end
```

## Callback Discipline

Acceptable callback uses:

- Data normalization (`before_save :normalize_email`)
- Setting defaults (`before_create :set_default_status`)
- Generating derived attributes (`before_save :generate_slug`)

Move everything else to the controller or a dedicated class:

- Sending emails or notifications
- Enqueuing background jobs
- Calling external APIs
- Complex conditional logic
- Operations spanning multiple models

Always prefer `after_commit` over `after_save` for any remaining side effects.

## Concern Guidelines

Concerns must have genuine "has trait" or "acts as" semantics. Name them as
adjectives: `Archivable`, `Searchable`, `Filterable`, `Taggable`, `Publishable`.

- Model-specific concerns: `app/models/user/authenticatable.rb`
- Shared concerns: `app/models/concerns/archivable.rb`
- Never use concerns as arbitrary code-hiding containers
- Each concern captures a single, well-defined domain concept

## Testing Conventions

Test with minitest and fixtures exclusively. Follow the testing pyramid:
many model tests, fewer integration tests, minimal system tests.

### Fixtures

Keep 1-2 default fixtures per model with boring, sane defaults. Use
descriptive names for specialized fixtures:

```yaml
# test/fixtures/users.yml
DEFAULTS: &DEFAULTS
  confirmed_at: <%= 1.week.ago %>
  password_digest: <%= BCrypt::Password.create("password", cost: 4) %>

one:
  <<: *DEFAULTS
  name: Regular User
  email: user@example.com

admin:
  <<: *DEFAULTS
  name: Admin User
  email: admin@example.com
  role: admin
```

Reference associations by label, never by ID. Customize fixtures inline
in tests rather than creating dozens of specialized fixtures.

### Assertions

Use purpose-built assertions, never generic `assert` with booleans:

```ruby
# GOOD
assert_equal "expected", actual
assert_nil actual
assert_includes collection, item
assert_predicate user, :active?
assert_difference "Article.count" do ... end

# BAD
assert actual == "expected"
assert actual.nil?
assert collection.include?(item)
assert user.active?
```

### What NOT to Test

- Do not test Rails framework behavior (validations work)
- Do not test private methods directly
- Do not mock Active Record or database interactions
- Do not write system tests for things controller tests cover

## Database Conventions

Mirror every model validation with a database constraint:

```ruby
create_table :products do |t|
  t.string :name, null: false
  t.string :sku, null: false
  t.decimal :price, precision: 8, scale: 2, null: false
  t.references :category, foreign_key: true
  t.timestamps
end

add_index :products, :sku, unique: true
add_check_constraint :products, "price >= 0", name: "products_price_positive"
```

Always index foreign keys, columns in WHERE/ORDER BY, and unique columns.
Use `algorithm: :concurrently` for production index additions.

## Performance Patterns

- Enable `strict_loading` in development/test to catch N+1 queries
- Use `includes` for eager loading, `preload` for separate queries
- Use `find_each` for batch processing, never `.all.each`
- Use `pluck` for value arrays, `exists?` for existence checks
- Use `size` over `count` (smart: uses COUNT if not loaded)
- Use counter caches for frequently counted associations
- Use `insert_all` / `upsert_all` for bulk operations

## Quick Reference

| Pattern | Use When |
|---------|----------|
| Model method | Logic operates on model's own data |
| Scope | Simple, chainable WHERE/ORDER queries |
| Concern | Genuinely shared trait across models |
| Composition | Complex operation within model's domain |
| Form object | Form spans multiple models |
| Query object | Query too complex for a single scope |
| Service object | Cross-cutting operation across domains |

## Additional Resources

### Reference Files

For detailed patterns and techniques, consult:

- **`references/code-style.md`** - Ruby style, naming conventions, model/controller/view/routing patterns
- **`references/architecture-patterns.md`** - Service objects, concerns, callbacks, query/form/value objects, anti-patterns, database migrations
- **`references/testing.md`** - Minitest assertions, fixtures, test organization, system/integration tests, parallel testing, anti-patterns
- **`references/modern-rails.md`** - Rails 8 features, Hotwire/Turbo/Stimulus, params.expect, normalizes, strict_loading, enums, Kamal deployment
