# Architecture Patterns and Anti-Patterns

## The Vanilla Rails Approach

Basecamp's codebase is almost 9 years old, has 400 controllers and 500 models,
and serves millions of users -- all with "vanilla Rails." Controllers access
domain models directly. Complex operations delegate to composition classes
within the model's namespace, not to a separate services layer.

The progression when complexity demands it:

1. **Model methods and scopes** -- the default
2. **Concerns** for shared traits
3. **Composition** within model namespace (`Recording::Incineration`)
4. **Form objects** for multi-model forms
5. **Query objects** for complex queries
6. **Service objects** ONLY for cross-cutting operations

## Service Objects

### When NOT to Use Them

- Simple CRUD operations -- just use the model
- Wrapping a single model method in a class -- procedural code in OOP costume
- When the logic naturally belongs on the model itself
- When a model method with a clear name would suffice

DHH has described service object overuse as "a J2EE renaissance fair" and
"digging up every discredited pattern of complexity to do a reunion tour."

### When to Use Them (If You Must)

- The operation spans multiple models with no clear owner
- The operation interacts with an external service (payments, APIs)
- There are multiple strategies for performing the action

### Convention (If Used)

```ruby
# Location: app/services/ or namespaced under model
# Naming: verb-noun or namespace::verb
# Interface: single public #call method

class Users::Register
  def initialize(params)
    @params = params
  end

  def call
    user = User.create!(@params)
    UserMailer.welcome(user).deliver_later
    user
  end
end
```

### Prefer Composition Within Model Namespace

The 37signals pattern -- delegate to classes within the model's namespace:

```ruby
# A Recording model exposes:
recording.incinerate       # delegates to Recording::Incineration
recording.copy_to(bucket)  # delegates to Recording::Copier

# app/models/recording/incineration.rb
class Recording::Incineration
  def initialize(recording)
    @recording = recording
  end

  def perform
    # complex incineration logic
  end
end
```

## Concerns

### Rules for Good Concerns

From 37signals:

- Must have genuine "has trait" or "acts as" semantics
- Each concern captures a single, well-defined domain concept
- Name them to reflect domain concepts: `Archivable`, `Searchable`, `Taggable`
- Model-specific concerns: `app/models/<model_name>/` (e.g., `app/models/message/mentionable.rb`)
- Shared concerns: `app/models/concerns/`

### Good Concern Example

```ruby
module Archivable
  extend ActiveSupport::Concern

  included do
    scope :archived, -> { where.not(archived_at: nil) }
    scope :unarchived, -> { where(archived_at: nil) }
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def unarchive!
    update!(archived_at: nil)
  end

  def archived?
    archived_at.present?
  end
end
```

### When Concerns Are Inappropriate

- Merely reducing line count in a single model (code hiding, not extraction)
- The concern depends on specific model internals
- Only used in one model (just use private methods)
- Mixing unrelated behaviors into one concern
- "Catch-all" concerns mixing unrelated functionality

## Callback Discipline

### Acceptable Uses

- Data normalization before save (downcasing, stripping)
- Setting default values
- Generating derived attributes (slugs, tokens)
- Maintaining data integrity within the model's own data

### What to Avoid in Callbacks

- Sending emails or notifications
- Enqueuing background jobs
- Calling external APIs
- Complex conditional logic
- Operations spanning multiple models
- Anything with side effects beyond the model's own data

### Callback Rules

1. Avoid conditional callbacks in the signature; put conditions in the method body
2. Make callbacks idempotent (safe to run multiple times)
3. Prefer `after_commit` over `after_save` for any side effects
4. Declare callback methods as private
5. Order callbacks in the order they execute
6. Use `prepend: true` for `before_destroy` validation callbacks

```ruby
# ACCEPTABLE
class User < ApplicationRecord
  normalizes :email, with: ->(email) { email.strip.downcase }
  before_save :generate_slug

  private

  def generate_slug
    self.slug = name.parameterize
  end
end

# BAD -- side effects in callbacks
class Order < ApplicationRecord
  after_create :send_confirmation_email
  after_create :notify_warehouse
  after_create :charge_payment
  after_save :sync_to_crm
end

# GOOD -- explicit orchestration
class OrdersController < ApplicationController
  def create
    @order = Order.new(order_params)
    if @order.save
      OrderMailer.confirmation(@order).deliver_later
      WarehouseNotificationJob.perform_later(@order.id)
      redirect_to @order
    else
      render :new, status: :unprocessable_entity
    end
  end
end
```

### before_destroy Validation

```ruby
class User < ApplicationRecord
  has_many :posts, dependent: :destroy

  before_destroy :ensure_no_active_subscriptions, prepend: true

  private

  def ensure_no_active_subscriptions
    if active_subscriptions.any?
      errors.add(:base, "Cannot delete user with active subscriptions")
      throw(:abort)
    end
  end
end
```

## Query Objects

Use when a query is too complex for a single scope or needs parameterization
beyond what a scope lambda provides.

```ruby
# Location: app/queries/
# Naming: <Description>Query
# Accept a relation, return a relation

class AbandonedCartsQuery
  def initialize(relation = Cart.all)
    @relation = relation
  end

  def call
    @relation
      .left_joins(:order)
      .where(orders: { id: nil })
      .where(carts: { updated_at: ..3.days.ago })
      .where.not(carts: { email: nil })
  end
end

# Composable with scopes:
AbandonedCartsQuery.new(Cart.where(store_id: store.id)).call
```

Start with model scopes. Extract to a query object only when the query is too
complex for a single scope.

## Form Objects

Use when a form touches multiple models or needs contextual validation.

```ruby
# Location: app/forms/
# Include ActiveModel::Model for form_with compatibility

class RegistrationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :company_name, :string
  attribute :user_name, :string
  attribute :user_email, :string
  attribute :user_password, :string

  validates :company_name, :user_name, :user_email, :user_password, presence: true
  validates :user_email, format: { with: URI::MailTo::EMAIL_REGEXP }

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      company = Company.create!(name: company_name)
      company.users.create!(
        name: user_name,
        email: user_email,
        password: user_password
      )
    end
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)
    false
  end
end
```

Do not use form objects for simple single-model CRUD. Use `ActiveModel::Model`
and `ActiveModel::Attributes` -- no need for gems like Reform or Virtus.

## Value Objects

Use `Data.define` (Ruby 3.2+) for immutable value objects:

```ruby
Money = Data.define(:amount_cents, :currency) do
  def to_s = "#{currency} #{amount_cents / 100.0}"

  def +(other)
    raise ArgumentError, "Currency mismatch" unless currency == other.currency
    self.class.new(amount_cents: amount_cents + other.amount_cents, currency: currency)
  end
end

price = Money.new(amount_cents: 1999, currency: "USD")
price.frozen?  # => true

# In Rails models via composed_of:
class Product < ApplicationRecord
  composed_of :price,
    class_name: "Money",
    mapping: [%w[price_cents amount_cents], %w[price_currency currency]]
end
```

Prefer `Data.define` over `Struct` for anything that should not be mutated.

## Anti-Patterns

### God Models / Fat Models

When a model accumulates hundreds of methods, extract in this order:

1. Concerns with genuine trait semantics
2. Value objects via `composed_of`
3. Composition classes in the model's namespace
4. Query objects for complex queries
5. Form objects for multi-model forms

### N+1 Queries

Three layers of defense:

1. **strict_loading** -- raises when lazy loading occurs
2. **Bullet gem** -- detects N+1s in development/test
3. **Correct eager loading** -- `includes`, `preload`, `eager_load`

```ruby
# Default choice
Post.includes(:comments, :author)

# Force separate queries
Post.preload(:comments)

# Force LEFT OUTER JOIN (filter on association)
Post.eager_load(:comments).where(comments: { approved: true })
```

Common mistakes:

- `.count` always executes SQL -- use `.size` instead
- `.where` in instance methods breaks preloading -- define associations instead
- `.any?` then `.each` = two queries -- use `.load.any?`

### Over-Abstraction

Symptoms of over-engineering:

- A `services/` directory with more files than `models/`
- Service objects that delegate to a single model method
- Separate "application layer" and "domain layer" for a CRUD app
- Pulling in `dry-monads`, `dry-validation` for standard operations

## Database Conventions

### Index Strategies

Always index:

- All foreign keys
- Columns in WHERE, ORDER BY, GROUP BY clauses
- Unique constraints
- Polymorphic type + id pairs (composite index)

```ruby
# Composite index -- most selective column first
add_index :orders, [:user_id, :created_at]

# Partial index (PostgreSQL)
add_index :users, :email, unique: true, where: "deleted_at IS NULL"

# Concurrent index creation (zero-downtime)
disable_ddl_transaction!
add_index :orders, :status, algorithm: :concurrently
```

### Migration Safety (strong_migrations gem)

| Unsafe Operation | Safe Alternative |
|---|---|
| `remove_column` | Add `ignored_columns`, deploy, then remove |
| `change_column` type | Create new column, backfill, switch |
| `rename_column` | New column, backfill, migrate reads, drop old |
| `add_index` (non-concurrent) | `algorithm: :concurrently` |
| `add_foreign_key` | `validate: false`, then validate separately |
| JSON column (PostgreSQL) | Use `jsonb` instead |

General migration rules:

- One structural change per migration
- Always ensure reversibility
- Separate data migrations from schema migrations
- Never use ActiveRecord model classes in migrations (use raw SQL)
- Test rollbacks: `bin/rails db:migrate:redo`
- Batch and throttle data backfills

### Safe Column Removal (Two-Step Deploy)

```ruby
# Step 1: Deploy code with ignored_columns
class User < ApplicationRecord
  self.ignored_columns += ["legacy_field"]
end

# Step 2: After deploy, run migration
class RemoveLegacyFieldFromUsers < ActiveRecord::Migration[8.0]
  def change
    safety_assured { remove_column :users, :legacy_field, :string }
  end
end
```

## Palkan's Seven Deadly Rails Anti-Patterns

From Vladimir Dementyev (Evil Martians):

1. **Callbacks** -- Reserve for data normalization only
2. **Concerns** -- Must have genuine trait semantics
3. **Helpers** -- Disable `config.action_controller.include_all_helpers = false`
4. **Current attributes** -- Keep minimal; use `Current.set(..., &block)`
5. **Instance variables in views** -- Use strict locals in partials
6. **Core extensions** -- Use refinements for scoped monkey patches
7. **Turbo broadcasts** -- Be selective; broadcast only changed attributes

The closing principle: "Hell is full of Rails applications trying to go against
the Rails Way."
