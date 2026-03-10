# Testing and Security Reference

## Testing Framework

Rails uses Minitest by default. Tests live in the `test/` directory.

### Test Types

| Type | Location | Base Class | Purpose |
|------|----------|------------|---------|
| Model | `test/models/` | `ActiveSupport::TestCase` | Unit tests |
| Controller | `test/controllers/` | `ActionDispatch::IntegrationTest` | HTTP requests |
| Integration | `test/integration/` | `ActionDispatch::IntegrationTest` | Workflows |
| System | `test/system/` | `ApplicationSystemTestCase` | Browser tests |
| Mailer | `test/mailers/` | `ActionMailer::TestCase` | Email tests |
| Job | `test/jobs/` | `ActiveJob::TestCase` | Background jobs |

### Running Tests

```bash
bin/rails test                      # All tests
bin/rails test:models               # Model tests only
bin/rails test:controllers          # Controller tests
bin/rails test:system               # System tests (browser)
bin/rails test test/models/user_test.rb  # Specific file
bin/rails test test/models/user_test.rb:10  # Specific line
bin/rails test -n test_user_valid   # By name pattern
bin/rails test -v                   # Verbose output
bin/rails test -f                   # Fail fast
```

### Fixtures

```yaml
# test/fixtures/users.yml
admin:
  name: Admin User
  email: admin@example.com
  role: admin

regular:
  name: Regular User
  email: user@example.com
  role: user
  organization: acme  # Reference to organizations fixture

# test/fixtures/organizations.yml
acme:
  name: Acme Corp
```

```ruby
# Access in tests
class UserTest < ActiveSupport::TestCase
  test "admin has correct role" do
    admin = users(:admin)
    assert_equal "admin", admin.role
  end
end
```

### Model Tests

```ruby
class UserTest < ActiveSupport::TestCase
  # Validation tests
  test "should not save without email" do
    user = User.new(name: "Test")
    assert_not user.save
    assert_includes user.errors[:email], "can't be blank"
  end

  test "email should be unique" do
    User.create!(name: "A", email: "test@example.com")
    user = User.new(name: "B", email: "test@example.com")
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  # Association tests
  test "destroying user destroys posts" do
    user = users(:regular)
    user.posts.create!(title: "Test", body: "Content")
    assert_difference "Post.count", -1 do
      user.destroy
    end
  end

  # Callback tests
  test "email is normalized before save" do
    user = User.create!(name: "Test", email: "  TEST@EXAMPLE.COM  ")
    assert_equal "test@example.com", user.email
  end

  # Scope tests
  test "active scope returns only active users" do
    active = User.create!(name: "Active", email: "a@b.com", active: true)
    inactive = User.create!(name: "Inactive", email: "c@d.com", active: false)
    assert_includes User.active, active
    assert_not_includes User.active, inactive
  end
end
```

### Controller Tests

```ruby
class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @product = products(:widget)
    @user = users(:admin)
  end

  test "should get index" do
    get products_url
    assert_response :success
    assert_select "h1", "Products"
  end

  test "should get show" do
    get product_url(@product)
    assert_response :success
  end

  test "should require login for create" do
    post products_url, params: { product: { name: "New" } }
    assert_redirected_to login_url
  end

  test "should create product when logged in" do
    sign_in @user  # Helper method
    assert_difference "Product.count" do
      post products_url, params: {
        product: { name: "New Product", price: 19.99 }
      }
    end
    assert_redirected_to product_url(Product.last)
    follow_redirect!
    assert_select "div.notice", "Product created."
  end

  test "should not create invalid product" do
    sign_in @user
    assert_no_difference "Product.count" do
      post products_url, params: { product: { name: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "should update product" do
    sign_in @user
    patch product_url(@product), params: {
      product: { name: "Updated Name" }
    }
    assert_redirected_to product_url(@product)
    @product.reload
    assert_equal "Updated Name", @product.name
  end

  test "should destroy product" do
    sign_in @user
    assert_difference "Product.count", -1 do
      delete product_url(@product)
    end
    assert_redirected_to products_url
  end

  private

  def sign_in(user)
    post login_url, params: { email: user.email, password: "password" }
  end
end
```

### Integration Tests

```ruby
class UserFlowsTest < ActionDispatch::IntegrationTest
  test "user can sign up and create post" do
    # Sign up
    get signup_url
    assert_response :success

    post users_url, params: {
      user: { name: "New User", email: "new@example.com", password: "secret123" }
    }
    assert_redirected_to root_url
    follow_redirect!
    assert_select "div.notice", /Welcome/

    # Create post
    get new_post_url
    assert_response :success

    post posts_url, params: {
      post: { title: "My First Post", body: "Hello World" }
    }
    assert_redirected_to post_url(Post.last)
    follow_redirect!
    assert_select "h1", "My First Post"
  end

  test "browsing products as guest" do
    get products_url
    assert_response :success

    get product_url(products(:widget))
    assert_response :success

    # Cannot access admin
    get admin_products_url
    assert_redirected_to login_url
  end
end
```

### System Tests

```ruby
class ProductsTest < ApplicationSystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  setup do
    @user = users(:admin)
    sign_in @user
  end

  test "visiting the index" do
    visit products_url
    assert_selector "h1", text: "Products"
    assert_selector "table tbody tr", count: Product.count
  end

  test "creating a product" do
    visit new_product_url

    fill_in "Name", with: "New Product"
    fill_in "Price", with: "29.99"
    select "Electronics", from: "Category"
    attach_file "Image", Rails.root.join("test/fixtures/files/product.jpg")
    check "Active"

    click_on "Create Product"

    assert_text "Product created"
    assert_selector "h1", text: "New Product"
  end

  test "updating a product" do
    product = products(:widget)
    visit edit_product_url(product)

    fill_in "Name", with: "Updated Name"
    click_on "Update Product"

    assert_text "Product updated"
    assert_selector "h1", text: "Updated Name"
  end

  test "deleting a product" do
    product = products(:widget)
    visit product_url(product)

    accept_confirm do
      click_on "Delete"
    end

    assert_text "Product deleted"
    assert_no_selector "h1", text: product.name
  end

  test "searching products" do
    visit products_url
    fill_in "Search", with: "widget"
    click_on "Search"

    assert_selector "table tbody tr", count: 1
    assert_text "Widget"
  end

  private

  def sign_in(user)
    visit login_url
    fill_in "Email", with: user.email
    fill_in "Password", with: "password"
    click_on "Log in"
    assert_text "Logged in successfully"
  end
end
```

### Test Assertions

```ruby
# Basic assertions
assert expression                    # Truthy
assert_not expression               # Falsy
assert_equal expected, actual
assert_not_equal expected, actual
assert_nil value
assert_not_nil value
assert_raises(Exception) { block }
assert_nothing_raised { block }
assert_includes collection, item
assert_match /regex/, string
assert_instance_of Class, object

# Rails-specific
assert_difference "Model.count" do
  # action that creates record
end

assert_difference "Model.count", -1 do
  # action that deletes record
end

assert_no_difference "Model.count" do
  # action that doesn't change count
end

assert_changes -> { model.attribute }, from: "old", to: "new" do
  # action
end

# Controller assertions
assert_response :success             # 200
assert_response :redirect            # 3xx
assert_response :not_found           # 404
assert_response 422                  # Specific code
assert_redirected_to url
assert_redirected_to action: :show

# View assertions (in integration/system tests)
assert_select "h1", "Title"
assert_select "div.notice"
assert_select "form" do
  assert_select "input[type=text]"
end
```

### Mailer Tests

```ruby
class UserMailerTest < ActionMailer::TestCase
  test "welcome email" do
    user = users(:regular)
    email = UserMailer.welcome(user)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ["noreply@example.com"], email.from
    assert_equal [user.email], email.to
    assert_equal "Welcome to Our App", email.subject
    assert_match /Hi #{user.name}/, email.body.encoded
  end
end
```

### Job Tests

```ruby
class ProcessOrderJobTest < ActiveJob::TestCase
  test "processes order" do
    order = orders(:pending)

    assert_enqueued_with(job: ProcessOrderJob, args: [order]) do
      ProcessOrderJob.perform_later(order)
    end

    perform_enqueued_jobs

    order.reload
    assert_equal "completed", order.status
  end

  test "sends notification email" do
    order = orders(:pending)

    assert_enqueued_emails 1 do
      ProcessOrderJob.perform_now(order)
    end
  end
end
```

## Security

### CSRF Protection

Enabled by default for all non-GET requests:

```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception  # Default in Rails
end

# In views, forms automatically include CSRF token
<%= form_with model: @product do |f| %>
  <!-- csrf_token included automatically -->
<% end %>

# In layouts for AJAX
<%= csrf_meta_tags %>

# Skip for API endpoints (use token auth instead)
class Api::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token
end
```

### Strong Parameters

Always whitelist permitted parameters:

```ruby
# Rails 8 recommended
def product_params
  params.expect(product: [:name, :price, :description])
end

# With nested attributes
def order_params
  params.expect(order: [
    :customer_id,
    :notes,
    items: [:product_id, :quantity, :price]
  ])
end

# Never do this
params.permit!  # Permits everything - dangerous
```

### SQL Injection Prevention

```ruby
# SAFE - parameterized queries
User.where("email = ?", params[:email])
User.where(email: params[:email])
User.find_by(email: params[:email])

# UNSAFE - string interpolation
User.where("email = '#{params[:email]}'")  # Never do this
User.where("email = #{params[:email]}")    # Never do this

# Safe ordering
User.order(:name)
User.order(name: :desc)

# Safe with dynamic column (whitelist)
ALLOWED_COLUMNS = %w[name email created_at]
column = params[:sort] if ALLOWED_COLUMNS.include?(params[:sort])
User.order(column => :asc) if column
```

### XSS Prevention

```erb
<%# Safe - escaped by default %>
<%= user.name %>
<%= user.bio %>

<%# Dangerous - only use with trusted content %>
<%= raw user.bio %>
<%= user.bio.html_safe %>

<%# Sanitize user content %>
<%= sanitize user.bio, tags: %w[p br strong em] %>
<%= strip_tags user.bio %>
```

### Session Security

```ruby
class SessionsController < ApplicationController
  def create
    user = User.authenticate_by(email: params[:email], password: params[:password])
    if user
      reset_session  # Prevent session fixation
      session[:user_id] = user.id
      redirect_to root_path
    else
      flash.now[:alert] = "Invalid credentials"
      render :new
    end
  end

  def destroy
    reset_session
    redirect_to root_path
  end
end
```

```ruby
# config/initializers/session_store.rb
Rails.application.config.session_store :cookie_store,
  key: "_app_session",
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax
```

### Password Security

```ruby
class User < ApplicationRecord
  has_secure_password  # Requires bcrypt gem

  # Automatically provides:
  # - password= (hashes to password_digest)
  # - password_confirmation
  # - authenticate(password)
  # - Validates password presence on create
  # - Validates password length (max 72 bytes)
end

# Authentication
user = User.find_by(email: params[:email])
if user&.authenticate(params[:password])
  # Login successful
end

# Rails 8: authenticate_by (timing-safe)
user = User.authenticate_by(email: params[:email], password: params[:password])
```

### Content Security Policy

```ruby
# config/initializers/content_security_policy.rb
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data
    policy.img_src     :self, :data, "https:"
    policy.object_src  :none
    policy.script_src  :self
    policy.style_src   :self

    # Report violations
    policy.report_uri "/csp-violation-report"
  end

  # Generate nonces for inline scripts
  config.content_security_policy_nonce_generator = ->(request) {
    SecureRandom.base64(16)
  }
end
```

### Logging Security

```ruby
# config/initializers/filter_parameter_logging.rb
Rails.application.config.filter_parameters += [
  :password,
  :password_confirmation,
  :credit_card,
  :ssn,
  :token,
  :secret,
  :api_key
]
```

### Force SSL

```ruby
# config/environments/production.rb
Rails.application.configure do
  config.force_ssl = true
end
```

### Secure Headers

```ruby
# config/application.rb
config.action_dispatch.default_headers = {
  "X-Frame-Options" => "SAMEORIGIN",
  "X-XSS-Protection" => "0",  # Disabled, CSP is better
  "X-Content-Type-Options" => "nosniff",
  "X-Permitted-Cross-Domain-Policies" => "none",
  "Referrer-Policy" => "strict-origin-when-cross-origin"
}
```

### File Upload Security

```ruby
class UploadsController < ApplicationController
  def create
    # Validate file type
    unless valid_content_type?(params[:file])
      return render json: { error: "Invalid file type" }, status: :unprocessable_entity
    end

    # Generate safe filename
    filename = sanitize_filename(params[:file].original_filename)

    # Store outside web root or use Active Storage
    @upload = current_user.uploads.create!(
      file: params[:file],
      filename: filename
    )
  end

  private

  def valid_content_type?(file)
    %w[image/jpeg image/png image/gif application/pdf].include?(file.content_type)
  end

  def sanitize_filename(filename)
    # Remove path traversal attempts
    filename = File.basename(filename)
    # Remove special characters
    filename.gsub(/[^\w\.\-]/, "_")
  end
end
```

### Rate Limiting (Rails 8)

```ruby
class ApplicationController < ActionController::Base
  rate_limit to: 10, within: 1.minute, only: :create
end

# Or using Rack::Attack
# config/initializers/rack_attack.rb
Rack::Attack.throttle("requests/ip", limit: 100, period: 1.minute) do |req|
  req.ip
end

Rack::Attack.throttle("logins/email", limit: 5, period: 20.seconds) do |req|
  if req.path == "/login" && req.post?
    req.params["email"].presence
  end
end
```
