---
name: rails-8
description: This skill should be used when working with Ruby on Rails 8 applications, including tasks like "create a Rails model", "add a migration", "set up routes", "build a controller", "add validations", "configure associations", "write Rails tests", "implement authentication", "create background jobs", or when the user mentions Rails 8, Active Record, Action Controller, or Rails conventions.
---

# Ruby on Rails 8 Development

## Philosophy

Rails operates on two core principles:

1. **Convention Over Configuration** - Sensible defaults eliminate configuration files
2. **Don't Repeat Yourself (DRY)** - Every piece of knowledge has a single representation

## Directory Structure

```text
app/
├── controllers/    # Request handlers
├── models/         # Active Record models
├── views/          # ERB templates
├── helpers/        # View helpers
├── jobs/           # Background jobs (Active Job)
├── mailers/        # Email templates
└── assets/         # CSS, JS, images
config/
├── routes.rb       # URL routing
├── database.yml    # Database config
└── environments/   # Per-environment settings
db/
├── migrate/        # Database migrations
├── schema.rb       # Current schema snapshot
└── seeds.rb        # Seed data
test/
├── models/         # Unit tests
├── controllers/    # Functional tests
├── integration/    # Workflow tests
└── system/         # Browser tests
```

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Model | Singular, CamelCase | `User`, `BookClub` |
| Table | Plural, snake_case | `users`, `book_clubs` |
| Controller | Plural, CamelCase + Controller | `UsersController` |
| Migration | Descriptive, CamelCase | `AddEmailToUsers` |
| Foreign Key | `singularized_table_id` | `user_id`, `book_club_id` |

## Essential Commands

```bash
# Server and console
bin/rails server              # Start development server
bin/rails console             # Interactive REPL

# Generators
bin/rails generate model User name:string email:string
bin/rails generate controller Users index show
bin/rails generate migration AddAgeToUsers age:integer
bin/rails generate authentication  # Rails 8 built-in auth

# Database
bin/rails db:migrate          # Run pending migrations
bin/rails db:rollback         # Undo last migration
bin/rails db:seed             # Load seed data
bin/rails db:reset            # Drop, create, migrate, seed

# Routes and info
bin/rails routes              # List all routes
bin/rails routes -g users     # Filter routes by pattern
```

## Models and Active Record

### Basic Model

```ruby
class User < ApplicationRecord
  # Validations
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true, length: { minimum: 2 }

  # Associations
  has_many :posts, dependent: :destroy
  has_one :profile
  belongs_to :organization, optional: true

  # Callbacks
  before_save :normalize_email

  private

  def normalize_email
    self.email = email.downcase.strip
  end
end
```

### CRUD Operations

```ruby
# Create
User.create(name: "Alice", email: "alice@example.com")
user = User.new(name: "Bob"); user.save

# Read
User.all                           # All records
User.find(1)                       # By ID (raises if not found)
User.find_by(email: "a@b.com")     # First match (nil if none)
User.where(active: true)           # Collection
User.where("age > ?", 18)          # With conditions
User.order(created_at: :desc)      # Sorted

# Update
user.update(name: "New Name")
User.where(active: false).update_all(archived: true)

# Delete
user.destroy                       # With callbacks
User.where(spam: true).destroy_all
```

## Migrations

### Creating Migrations

```bash
# Add column
bin/rails g migration AddAgeToUsers age:integer

# Remove column
bin/rails g migration RemoveAgeFromUsers age:integer

# Create table
bin/rails g migration CreateProducts name:string price:decimal{8,2}

# Add reference
bin/rails g migration AddUserToProducts user:references
```

### Migration DSL

```ruby
class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 8, scale: 2
      t.references :category, foreign_key: true
      t.timestamps
    end

    add_index :products, :name, unique: true
  end
end
```

## Controllers

### RESTful Controller

```ruby
class ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit update destroy]
  before_action :authenticate_user!, except: %i[index show]

  def index
    @products = Product.all
  end

  def show
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to @product, notice: "Product created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @product.update(product_params)
      redirect_to @product, notice: "Product updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to products_path, notice: "Product deleted."
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.expect(product: [:name, :description, :price, :category_id])
  end
end
```

## Routing

### Resource Routes

```ruby
Rails.application.routes.draw do
  root "home#index"

  resources :products do
    resources :reviews, only: [:create, :destroy]
    member do
      post :publish
    end
    collection do
      get :search
    end
  end

  namespace :admin do
    resources :users
  end

  # Custom routes
  get "/about", to: "pages#about"
end
```

Resource routes generate: `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`

## Views and ERB

### Template Syntax

```erb
<%# Evaluate without output %>
<% @products.each do |product| %>
  <%# Evaluate and output (escaped) %>
  <h2><%= product.name %></h2>
  <p><%= product.description %></p>
<% end %>

<%# Render partial %>
<%= render "form", product: @product %>
<%= render @products %>  <%# renders _product.html.erb for each %>
```

### Forms

```erb
<%= form_with model: @product do |form| %>
  <% if @product.errors.any? %>
    <div id="errors">
      <% @product.errors.full_messages.each do |msg| %>
        <p><%= msg %></p>
      <% end %>
    </div>
  <% end %>

  <%= form.label :name %>
  <%= form.text_field :name %>

  <%= form.label :price %>
  <%= form.number_field :price, step: 0.01 %>

  <%= form.label :category_id %>
  <%= form.collection_select :category_id, Category.all, :id, :name %>

  <%= form.submit %>
<% end %>
```

## Testing

### Model Test

```ruby
class UserTest < ActiveSupport::TestCase
  test "should not save without email" do
    user = User.new(name: "Test")
    assert_not user.save
  end

  test "email should be unique" do
    User.create!(name: "A", email: "test@example.com")
    user = User.new(name: "B", email: "test@example.com")
    assert_not user.valid?
  end
end
```

### Controller Test

```ruby
class ProductsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get products_url
    assert_response :success
  end

  test "should create product" do
    assert_difference("Product.count") do
      post products_url, params: { product: { name: "New", price: 10 } }
    end
    assert_redirected_to product_url(Product.last)
  end
end
```

### System Test

```ruby
class ProductsTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit products_url
    assert_selector "h1", text: "Products"
  end

  test "creating a product" do
    visit new_product_url
    fill_in "Name", with: "Test Product"
    fill_in "Price", with: 19.99
    click_on "Create Product"
    assert_text "Product created"
  end
end
```

## Rails 8 Features

### Built-in Authentication

```bash
bin/rails generate authentication
```

Generates User/Session models with secure password handling via `has_secure_password`.

### Solid Queue (Default Job Backend)

Database-backed job queuing without Redis dependency:

```ruby
class ProcessOrderJob < ApplicationJob
  queue_as :default

  def perform(order)
    order.process!
  end
end

ProcessOrderJob.perform_later(order)
ProcessOrderJob.set(wait: 1.hour).perform_later(order)
```

### Hotwire (Turbo + Stimulus)

Default frontend stack without heavy JavaScript:

- **Turbo Drive** - Accelerates navigation
- **Turbo Frames** - Partial page updates
- **Turbo Streams** - Real-time updates
- **Stimulus** - Lightweight JS controllers

### Import Maps

JavaScript package management without bundlers:

```ruby
# config/importmap.rb
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
```

## Security Best Practices

1. **Strong Parameters** - Always use `params.expect` or `params.permit`
2. **CSRF Protection** - Enabled by default, never disable
3. **SQL Injection** - Use parameterized queries, never string interpolation
4. **XSS Prevention** - ERB escapes output by default
5. **Mass Assignment** - Only permit known attributes
6. **Session Security** - Call `reset_session` after login

## Additional Resources

### Reference Files

For detailed patterns and techniques, consult:

**Core Framework:**

- **`references/active-record.md`** - Models, validations, associations, callbacks, queries
- **`references/controllers-routing.md`** - Controllers, routing, strong parameters
- **`references/views-helpers.md`** - Layouts, partials, view helpers, ERB
- **`references/forms.md`** - form_with, fields, nested forms, Turbo integration
- **`references/testing-security.md`** - Testing strategies, security patterns

**Rails Components:**

- **`references/active-job.md`** - Background jobs, Solid Queue, callbacks, retries
- **`references/action-mailer.md`** - Email sending, attachments, previews
- **`references/active-storage.md`** - File uploads, variants, direct uploads
- **`references/action-text-cable.md`** - Rich text editing, WebSockets
- **`references/caching-i18n.md`** - Fragment caching, internationalization

**Frontend & Tools:**

- **`references/hotwire-javascript.md`** - Turbo, Stimulus, Import Maps
- **`references/generators-commands.md`** - Rails CLI, generators, rake tasks
