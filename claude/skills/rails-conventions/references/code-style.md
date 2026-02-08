# Code Style and Naming Conventions

## Ruby Style for Rails

- **Indentation**: 2 spaces, no tabs
- **Line length**: 120 characters max
- **String literals**: Double quotes (`"string"`) by default
- **Trailing commas**: Use in multi-line arrays, hashes, and argument lists
- **Frozen string literals**: Add `# frozen_string_literal: true` to all files
- **Parentheses**: Omit for DSL-style calls (validates, has_many, before_action); use for regular methods with arguments
- **Boolean methods**: End with `?` (e.g., `active?`, `admin?`)
- **Dangerous methods**: End with `!` for methods that mutate or raise (e.g., `save!`, `normalize!`)
- **Unused variables**: Prefix with `_` or use bare `_`
- **Accessors**: Never prefix with `get_` or `set_`

```ruby
# DSL style -- no parens
validates :email, presence: true
has_many :posts, dependent: :destroy
before_action :authenticate_user!

# Regular methods -- use parens
user.send_notification(message)
```

## HTTP Status Codes

Always use symbolic status codes:

```ruby
# GOOD
render status: :forbidden
render status: :not_found
render status: :unprocessable_entity

# BAD
render status: 403
render status: 404
render status: 422
```

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Class/Module | `CamelCase` | `UserProfile`, `Admin::Dashboard` |
| Method | `snake_case` | `send_notification`, `full_name` |
| Variable | `snake_case` | `current_user`, `total_count` |
| Instance variable | `@snake_case` | `@current_user` |
| Constant | `SCREAMING_SNAKE_CASE` | `MAX_RETRIES`, `API_KEY` |
| Predicate method | `snake_case?` | `active?`, `valid_email?` |
| Dangerous method | `snake_case!` | `save!`, `destroy!` |
| Model | Singular `CamelCase` | `User`, `BookClub` |
| Table | Plural `snake_case` | `users`, `book_clubs` |
| Controller | Plural + Controller | `UsersController` |
| Helper | Plural + Helper | `UsersHelper` |
| Mailer | CamelCase + Mailer | `UserMailer`, `OrderMailer` |
| Job | CamelCase + Job | `ProcessOrderJob` |
| Concern | Adjective/role | `Searchable`, `Auditable`, `Archivable` |
| Foreign key | `singular_table_id` | `user_id`, `book_club_id` |
| Join table | Alphabetical | `categories_products` |
| Migration | Descriptive CamelCase | `AddEmailToUsers` |
| File name | `snake_case.rb` | `user_profile.rb` |

## Model Organization Order

Enforce this ordering consistently (matches RuboCop expectations):

```ruby
class User < ApplicationRecord
  # 1. Constants
  ROLES = %w[admin editor viewer].freeze

  # 2. Attribute macros
  attr_accessor :skip_notification

  # 3. Enums
  enum :status, { active: 0, inactive: 1, suspended: 2 }

  # 4. Associations (belongs_to first, then has_one, has_many)
  belongs_to :organization
  has_one :profile, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :comments, through: :posts

  # 5. Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }

  # 6. Normalizations
  normalizes :email, with: ->(email) { email.strip.downcase }

  # 7. Callbacks
  before_save :generate_slug

  # 8. Scopes
  scope :active, -> { where(status: :active) }
  scope :recent, -> { order(created_at: :desc) }

  # 9. Class methods
  def self.search(query)
    where("name ILIKE ?", "%#{query}%")
  end

  # 10. Instance methods (public)
  def full_name
    "#{first_name} #{last_name}"
  end

  # 11. Private methods
  private

  def generate_slug
    self.slug = name.parameterize
  end
end
```

## Validation Patterns

```ruby
class User < ApplicationRecord
  # Use new-style hash syntax (not validates_presence_of)
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true,
                   length: { minimum: 2, maximum: 100 }
  validates :age, numericality: { greater_than: 0 }, allow_nil: true

  # Custom validation with descriptive method name
  validate :expiration_date_cannot_be_in_the_past

  # Conditional validations -- use symbol or lambda
  validates :card_number, presence: true, if: :paid_with_card?
  validates :phone_number, presence: true, if: -> { country == "US" }

  # Group related conditional validations
  with_options if: :active? do
    validates :email, presence: true
    validates :phone, presence: true
  end

  private

  def expiration_date_cannot_be_in_the_past
    if expiration_date.present? && expiration_date < Date.current
      errors.add(:expiration_date, "can't be in the past")
    end
  end
end
```

## Scope Conventions

Use scopes for simple chainable queries. Switch to class methods when the
query involves Ruby logic or conditional branches:

```ruby
class Product < ApplicationRecord
  # Scopes -- simple, chainable
  scope :active, -> { where(active: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :expensive, -> { where("price > ?", 100) }
  scope :in_category, ->(category) { where(category: category) }

  # Class method -- conditional logic
  def self.search(query)
    return all if query.blank?

    where("name ILIKE :q OR description ILIKE :q", q: "%#{query}%")
  end
end
```

## Association Best Practices

```ruby
class User < ApplicationRecord
  # Always specify dependent option
  has_many :posts, dependent: :destroy
  has_one :profile, dependent: :destroy

  # Prefer has_many :through over has_and_belongs_to_many
  has_many :memberships
  has_many :organizations, through: :memberships

  # Define preloadable associations instead of method queries
  # BAD: breaks preloading
  # def active_comments
  #   comments.where(soft_deleted: false)
  # end

  # GOOD: preloadable
  has_many :active_comments, -> { where(soft_deleted: false) }, class_name: "Comment"
end
```

Always use hash syntax for enum definitions with explicit integer mapping:

```ruby
# GOOD -- explicit
enum :status, { draft: 0, published: 1, archived: 2 }

# BAD -- implicit array (fragile if reordered)
enum :status, [:draft, :published, :archived]
```

## Query Patterns

```ruby
# Hash conditions when possible
User.where(active: true)

# Parameterized queries for safety (never interpolate)
User.where("age > ?", 18)

# Named placeholders for complex queries
User.where("age >= :min AND age <= :max", min: 18, max: 65)

# Range syntax
User.where(created_at: 7.days.ago..)
User.where(age: 18..65)

# Batch processing (never .all.each)
User.find_each(batch_size: 1000) { |user| user.process }

# Use pluck for single columns
User.where(active: true).pluck(:email)

# Use exists? for existence checks (not present?)
User.where(email: "a@b.com").exists?

# Use size (smart: uses COUNT if not loaded, .length if loaded)
@users.size

# Order by timestamps, not id
User.order(created_at: :desc)
```

## Controller Patterns

### DHH's Controller Philosophy

Controllers contain ONLY the 7 standard CRUD actions (`index`, `show`, `new`,
`edit`, `create`, `update`, `destroy`). Any custom action becomes a new
controller:

```ruby
# BAD
class InboxesController < ApplicationController
  def pendings; end
  def spam; end
end

# GOOD
class Inboxes::PendingsController < ApplicationController
  def index; end
end

class Inboxes::SpamsController < ApplicationController
  def index; end
end
```

### before_action Patterns

```ruby
class ProductsController < ApplicationController
  # Authentication -- broad
  before_action :authenticate_user!, except: %i[index show]

  # Resource loading -- specific actions
  before_action :set_product, only: %i[show edit update destroy]

  # Authorization -- after resource loading
  before_action :authorize_product!, only: %i[edit update destroy]

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def authorize_product!
    redirect_to products_path, alert: "Not authorized" unless @product.user == current_user
  end

  def product_params
    params.expect(product: [:name, :description, :price, :category_id])
  end
end
```

List actions in `only:`/`except:` in lexical (alphabetical) order. Keep filter
methods private. Prefer `only:` over `except:`.

### Minimize Instance Variables

Pass the fewest instance variables to views. One or two is ideal. If more
are needed, consider a presenter object.

## View Conventions

### Partials

- Never use instance variables in partials -- always pass data as locals
- Use strict locals (Rails 7.1+) to enforce partial interface
- Use collection rendering for lists instead of explicit loops

```erb
<%# locals: (product:, show_price: true) -%>
<div class="product">
  <h3><%= product.name %></h3>
  <% if show_price %>
    <p><%= number_to_currency(product.price) %></p>
  <% end %>
</div>
```

```erb
<%# Collection rendering %>
<%= render @products %>

<%# Explicit partial with locals %>
<%= render partial: "product", collection: @products, as: :item %>
```

### Helpers vs Presenters

**Helpers** for generic, stateless formatting:

```ruby
module ApplicationHelper
  def format_date(date)
    date&.strftime("%B %d, %Y")
  end

  def status_badge(status)
    tag.span(status.humanize, class: "badge badge-#{status}")
  end
end
```

**Presenters** for complex view logic spanning multiple models:

```ruby
class DashboardPresenter
  def initialize(user)
    @user = user
  end

  def recent_orders
    @user.orders.recent.limit(5)
  end

  def greeting
    hour = Time.current.hour
    prefix = if hour < 12 then "Good morning"
             elsif hour < 18 then "Good afternoon"
             else "Good evening"
             end
    "#{prefix}, #{@user.first_name}"
  end
end
```

### ERB Best Practices

- Keep Ruby logic minimal in templates
- Never call methods that trigger queries from views (load in controller)
- Use `content_for` and `yield` for layout sections
- Use `dom_id` and `dom_class` helpers for Turbo-compatible DOM identifiers

## Routing Conventions

### RESTful Routing

```ruby
Rails.application.routes.draw do
  root "pages#home"

  # Standard resources
  resources :products

  # Constrained -- only what you need
  resources :sessions, only: %i[new create destroy]

  # Nested -- never more than 1 level deep
  resources :posts do
    resources :comments, only: %i[create destroy]
  end

  # Shallow nesting
  resources :posts do
    resources :comments, shallow: true
  end

  # Namespaces
  namespace :admin do
    resources :products
    resources :users
  end

  # API versioning
  namespace :api do
    namespace :v1 do
      resources :products, only: %i[index show]
    end
  end
end
```

### Routing Rules

- Never nest routes more than 1 level deep
- Never use legacy wildcard routes
- Never use `match` without `:via`
- Prefer `resources`/`resource` over hand-crafted get/post routes
- Use `resource` (singular) for resources with one per user (e.g., `resource :profile`)
- Use `concerns` for DRY shared route definitions
- Use member routes for single-record actions, collection routes for resource-wide actions

```ruby
concern :commentable do
  resources :comments, only: %i[create destroy]
end

resources :posts, concerns: :commentable
resources :photos, concerns: :commentable
```

## RuboCop Configuration

Standard Rails setup:

```ruby
# Gemfile
group :development do
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-minitest", require: false
end
```
