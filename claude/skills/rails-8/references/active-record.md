# Active Record Reference

## Naming Conventions

Active Record maps Ruby classes to database tables through pluralization:

| Model | Table | Foreign Key |
|-------|-------|-------------|
| `User` | `users` | `user_id` |
| `BookClub` | `book_clubs` | `book_club_id` |
| `Person` | `people` | `person_id` |

Primary keys default to `id`. Timestamps (`created_at`, `updated_at`) auto-update.

## Validations

### Built-in Validators

```ruby
class Product < ApplicationRecord
  # Presence - attribute must not be blank
  validates :name, presence: true

  # Uniqueness - no duplicates in database
  validates :sku, uniqueness: true
  validates :email, uniqueness: { case_sensitive: false, scope: :account_id }

  # Format - matches regex pattern
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  # Length - string constraints
  validates :name, length: { minimum: 2, maximum: 100 }
  validates :bio, length: { in: 10..500 }
  validates :password, length: { is: 8 }

  # Numericality - numeric constraints
  validates :price, numericality: { greater_than: 0 }
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Inclusion/Exclusion - value in set
  validates :status, inclusion: { in: %w[draft published archived] }
  validates :subdomain, exclusion: { in: %w[www admin api] }

  # Acceptance - checkbox confirmation
  validates :terms, acceptance: true

  # Confirmation - matches _confirmation field
  validates :email, confirmation: true

  # Comparison - compare to another attribute
  validates :end_date, comparison: { greater_than: :start_date }
end
```

### Validation Options

```ruby
# Allow nil/blank
validates :nickname, length: { minimum: 3 }, allow_nil: true
validates :bio, length: { minimum: 10 }, allow_blank: true

# Custom error message
validates :name, presence: { message: "is required" }
validates :age, numericality: { message: "%{value} must be a number" }

# Conditional validation
validates :card_number, presence: true, if: :paid_with_card?
validates :reason, presence: true, unless: -> { status == "approved" }

# Validation context
validates :password, presence: true, on: :create
validates :password, length: { minimum: 8 }, on: :update
```

### Custom Validations

```ruby
class Product < ApplicationRecord
  validate :price_within_range

  private

  def price_within_range
    return unless price.present?
    if price < 0
      errors.add(:price, "cannot be negative")
    elsif price > 10_000
      errors.add(:price, "seems unreasonably high")
    end
  end
end
```

### Error Handling

```ruby
product = Product.new
product.valid?                        # Run validations, return boolean
product.invalid?                      # Opposite of valid?
product.errors                        # ActiveModel::Errors object
product.errors.full_messages          # ["Name can't be blank", "Price is invalid"]
product.errors[:name]                 # ["can't be blank"]
product.errors.add(:base, "Generic error")  # Object-level error
```

## Associations

### belongs_to

Declares a model contains a foreign key to another:

```ruby
class Order < ApplicationRecord
  belongs_to :customer                          # customer_id required
  belongs_to :customer, optional: true          # customer_id can be nil
  belongs_to :author, class_name: "User"        # Custom class name
  belongs_to :parent, class_name: "Category", foreign_key: "parent_id"
end
```

### has_one

One-to-one where foreign key is in associated table:

```ruby
class User < ApplicationRecord
  has_one :profile, dependent: :destroy
  has_one :avatar, as: :imageable              # Polymorphic
end
```

### has_many

One-to-many relationships:

```ruby
class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_many :published_posts, -> { where(published: true) }, class_name: "Post"
  has_many :comments, through: :posts          # Has many through
end
```

### has_many :through

Many-to-many with join model:

```ruby
class Doctor < ApplicationRecord
  has_many :appointments
  has_many :patients, through: :appointments
end

class Appointment < ApplicationRecord
  belongs_to :doctor
  belongs_to :patient
end

class Patient < ApplicationRecord
  has_many :appointments
  has_many :doctors, through: :appointments
end
```

### has_and_belongs_to_many

Simple many-to-many without join model:

```ruby
class Article < ApplicationRecord
  has_and_belongs_to_many :tags
end

class Tag < ApplicationRecord
  has_and_belongs_to_many :articles
end

# Requires join table: articles_tags (no id, has article_id and tag_id)
```

### Polymorphic Associations

Single model belongs to multiple types:

```ruby
class Image < ApplicationRecord
  belongs_to :imageable, polymorphic: true
end

class Product < ApplicationRecord
  has_many :images, as: :imageable
end

class User < ApplicationRecord
  has_many :images, as: :imageable
end

# images table needs: imageable_id and imageable_type columns
```

### Association Options

```ruby
has_many :posts,
  dependent: :destroy,        # Destroy associated records
  dependent: :nullify,        # Set foreign key to null
  dependent: :restrict_with_error,  # Prevent deletion if associated
  inverse_of: :author,        # Explicit inverse for caching
  counter_cache: true         # Cache count in parent (posts_count column)
```

## Callbacks

### Available Callbacks

```ruby
class User < ApplicationRecord
  # Creating
  before_validation :normalize_data
  after_validation :log_errors, if: -> { errors.any? }
  before_save :hash_password
  around_save :log_save_time
  after_save :send_notification
  before_create :set_defaults
  after_create :send_welcome_email
  after_create_commit :process_async  # After transaction commits

  # Updating
  before_update :track_changes
  after_update :sync_external
  after_update_commit :broadcast_change

  # Destroying
  before_destroy :check_dependencies
  after_destroy :cleanup_files
  after_destroy_commit :remove_from_index

  # Touching
  after_touch :update_timestamp

  private

  def normalize_data
    self.email = email&.downcase&.strip
  end
end
```

### Callback Conditions

```ruby
before_save :process_image, if: :image_changed?
after_create :send_notification, unless: :spam?
before_validation :set_slug, on: :create
```

### Halting Execution

```ruby
before_save :check_status

def check_status
  throw(:abort) if status == "locked"
end
```

## Scopes

```ruby
class Product < ApplicationRecord
  scope :active, -> { where(active: true) }
  scope :expensive, -> { where("price > ?", 100) }
  scope :by_category, ->(cat) { where(category: cat) }
  scope :recent, -> { order(created_at: :desc).limit(10) }

  # Chainable
  default_scope { where(deleted: false) }  # Use sparingly
end

# Usage
Product.active.expensive.by_category("electronics")
```

## Query Interface

### Finding Records

```ruby
# Single record
User.find(1)                    # By ID, raises ActiveRecord::RecordNotFound
User.find_by(email: "a@b.com")  # First match, returns nil
User.find_by!(email: "a@b.com") # First match, raises if not found
User.first                      # First by primary key
User.last                       # Last by primary key
User.take                       # Any single record

# Multiple records
User.all                        # All records (lazy loaded)
User.find([1, 2, 3])            # Multiple IDs
User.where(active: true)        # Collection
```

### Conditions

```ruby
User.where(active: true)
User.where("age > ?", 18)
User.where("name LIKE ?", "%john%")
User.where(created_at: 1.week.ago..)
User.where.not(status: "banned")
User.where(role: ["admin", "moderator"])
```

### Ordering and Limiting

```ruby
User.order(:name)
User.order(created_at: :desc)
User.order("LOWER(name)")
User.limit(10)
User.offset(20)
User.limit(10).offset(20)  # Pagination
```

### Selecting and Grouping

```ruby
User.select(:id, :name)
User.select("COUNT(*) as count, status").group(:status)
User.distinct.pluck(:email)
User.ids                        # Pluck IDs only
User.count
User.average(:age)
User.sum(:balance)
User.maximum(:score)
User.minimum(:score)
```

### Joins and Includes

```ruby
# Inner join
User.joins(:posts).where(posts: { published: true })

# Eager loading (N+1 prevention)
User.includes(:posts)           # Separate query
User.eager_load(:posts)         # Single LEFT OUTER JOIN
User.preload(:posts)            # Separate queries always

# Multiple associations
User.includes(:posts, :comments)
User.includes(posts: :comments)
```

### Existence Checks

```ruby
User.exists?(1)
User.exists?(email: "a@b.com")
User.where(active: true).exists?
User.any?
User.none?
User.many?
```

## Transactions

```ruby
ActiveRecord::Base.transaction do
  account1.withdraw(100)
  account2.deposit(100)
  # Both succeed or both fail
end

# Nested transactions
User.transaction do
  User.create!(name: "A")
  User.transaction(requires_new: true) do
    User.create!(name: "B")
    raise ActiveRecord::Rollback  # Only rolls back inner
  end
end

# Model-level
user.with_lock do
  user.balance -= 100
  user.save!
end
```

## Locking

```ruby
# Optimistic locking (requires lock_version column)
user = User.find(1)
user.name = "New"
user.save!  # Raises ActiveRecord::StaleObjectError if version changed

# Pessimistic locking
User.transaction do
  user = User.lock.find(1)  # SELECT ... FOR UPDATE
  user.balance -= 100
  user.save!
end
```
