# Testing Conventions

## Philosophy

Use minitest and fixtures exclusively. Minitest is "just Ruby" -- no DSL, no
magic matchers, one way to express each assertion. Fixtures provide real-world
data loaded once for speed. Each test runs inside a transaction that rolls back.

### Why Minitest Over RSpec

- Plain Ruby with no DSL to learn
- Ships with Ruby itself -- zero dependencies
- Faster execution (no DSL overhead)
- One way to express each concept (`assert_equal` vs RSpec's `eq`, `==`, `eql`, `equal`)
- The Rails default ("omakase")

### Why Fixtures Over Factories

- Inserted once at suite start, not per-test (much faster)
- YAML data format -- no random generation, no branching, no looping
- No database_cleaner complexity with Capybara
- Encourage building a coherent test world mirroring production
- Transaction rollback makes cleanup automatic

## Test Organization

### Directory Structure

```text
test/
  test_helper.rb
  application_system_test_case.rb
  models/           # Unit tests
  controllers/      # Request tests
  integration/      # Multi-step workflow tests
  system/           # Browser tests (Capybara)
  mailers/          # Email tests
  jobs/             # Background job tests
  helpers/          # View helper tests
  fixtures/         # YAML fixture data
    files/          # Attached file fixtures
  support/          # Shared helpers and modules
```

### What to Test at Each Level

**Model tests** (`ActiveSupport::TestCase`) -- the bulk of tests:

- Validations, associations, scopes
- Business logic methods
- Edge cases and boundary conditions

**Controller/request tests** (`ActionDispatch::IntegrationTest`):

- HTTP response codes
- Redirects after create/update/destroy
- Authentication and authorization
- Strong parameter filtering
- Record creation/update/deletion

**Integration tests** (`ActionDispatch::IntegrationTest`):

- Multi-step user workflows
- Cross-controller flows
- Guest vs authenticated access

**System tests** (`ApplicationSystemTestCase`):

- Critical user paths ONLY (login, checkout, core CRUD)
- JavaScript-dependent interactions
- Turbo/Stimulus behavior
- Complex form interactions

### Testing Pyramid

Many model tests (fast, isolated). Fewer integration tests (medium speed).
Very few system tests (slow, brittle). Do not write system tests for things
controller tests can cover.

## Assertions

### Purpose-Built Assertions

Always use specific assertions, never generic `assert` with booleans:

```ruby
# GOOD -- specific, clear failure messages
assert_equal "expected", actual       # expected FIRST
assert_nil actual
assert_includes collection, item
assert_empty collection
assert_predicate user, :active?
assert_respond_to user, :full_name
assert_instance_of User, record
assert_match /pattern/, string
assert_in_delta Math::PI, calculated, 0.01
assert_raises(ActiveRecord::RecordInvalid) { user.save! }

# BAD -- generic, poor failure messages
assert actual == "expected"
assert actual.nil?
assert collection.include?(item)
assert user.active?
```

Every `assert_*` has a corresponding `refute_*`:

```ruby
refute_nil actual
refute_equal "unexpected", actual
refute_includes collection, item
refute_empty collection
refute_predicate user, :banned?
```

Always specify the exception type in `assert_raises`:

```ruby
# GOOD
assert_raises(ActiveRecord::RecordNotFound) { User.find(-1) }

# BAD -- catches any exception
assert_raises { User.find(-1) }
```

### Rails-Specific Assertions

```ruby
# Record count changes
assert_difference "Article.count" do
  post articles_url, params: { article: { title: "New" } }
end

assert_difference "Article.count", -1 do
  delete article_url(@article)
end

assert_no_difference "Article.count" do
  post articles_url, params: { article: { name: "" } }
end

# Attribute changes
assert_changes -> { user.reload.name }, from: "Old", to: "New" do
  user.update!(name: "New")
end

# HTTP response
assert_response :success
assert_response :redirect
assert_response :not_found
assert_response :unprocessable_entity
assert_redirected_to article_path(@article)

# HTML content
assert_select "h1", "Title"
assert_select "form" do
  assert_select "input[type=text]"
end

# Database queries (Rails 7.1+)
assert_queries_count(1) { User.find(1) }
assert_no_queries { cached_result }

# Enqueued emails
assert_enqueued_email_with OrderMailer, :confirmation do
  Order.create!(user: users(:one), total: 100)
end
```

## Fixtures

### Core Principles

- Keep 1-2 default fixtures per model with boring, sane defaults
- Name generic fixtures `:one` and `:two`
- Name specialized fixtures descriptively (`:admin`, `:expired_subscription`)
- Reference associations by label, never by ID
- Customize fixtures inline in tests rather than creating dozens of specialized ones

### YAML Format

```yaml
# test/fixtures/users.yml

# YAML anchors for DRY defaults (Rails ignores DEFAULTS fixture)
DEFAULTS: &DEFAULTS
  confirmed_at: <%= 1.week.ago %>
  role: user

one:
  <<: *DEFAULTS
  name: Regular User
  email: user@example.com

two:
  <<: *DEFAULTS
  name: Another User
  email: another@example.com

admin:
  <<: *DEFAULTS
  name: Admin User
  email: admin@example.com
  role: admin
```

### Association References

```yaml
# test/fixtures/posts.yml
first:
  title: Hello World
  body: Content here
  user: one                   # label reference, NOT user_id: 1

# Polymorphic belongs_to
comment:
  body: Great post
  commentable: first (Post)   # label with type in parentheses

# HABTM / has_many :through
editor:
  name: Editor User
  roles: admin, editor        # comma-separated labels
```

### ERB in Fixtures

```yaml
# Dynamic dates
old_post:
  title: Archive Post
  created_at: <%= 2.weeks.ago %>

# $LABEL interpolation
acme:
  name: $LABEL
  subdomain: $LABEL
  email: $LABEL@example.com

# Bulk fixtures
<% 20.times do |n| %>
user_<%= n %>:
  name: User <%= n %>
  email: user<%= n %>@example.com
<% end %>
```

### Password Digest Helper

```ruby
# test/support/test_password_helper.rb
require "bcrypt"

module TestPasswordHelper
  def default_password_digest
    BCrypt::Password.create(default_password, cost: 4)
  end

  def default_password
    "password"
  end
end
```

```ruby
# test/test_helper.rb
require "support/test_password_helper"

class ActiveSupport::TestCase
  include TestPasswordHelper
end

ActiveRecord::FixtureSet.context_class.include TestPasswordHelper
```

```yaml
# test/fixtures/users.yml
one:
  name: Regular User
  email: user@example.com
  password_digest: <%= default_password_digest %>
```

### Fixture Tips

- Omit IDs -- Rails generates stable IDs from fixture labels via hashing
- Use `null` for nil values
- Timestamps (`created_at`, `updated_at`) auto-fill with `Time.now`
- Use `ActiveRecord::FixtureSet.identify(:label)` for cross-reference IDs

### Customizing Fixtures in Tests

Rather than creating specialized fixtures, modify defaults inline:

```ruby
test "available developers" do
  available = developers(:one)
  unavailable = developers(:two)

  available.update!(available_on: Date.yesterday)
  unavailable.update!(available_on: Date.tomorrow)

  assert_includes Developer.available, available
  refute_includes Developer.available, unavailable
end
```

## Setup and Teardown

```ruby
class ArticleTest < ActiveSupport::TestCase
  setup do
    @article = articles(:one)
  end

  teardown do
    Rails.cache.clear
  end

  test "valid article" do
    assert @article.valid?
  end
end
```

Define `setup` before `teardown` to match execution order.

## System Tests

### Configuration

```ruby
# test/application_system_test_case.rb
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
end
```

### Pattern

```ruby
class CheckoutFlowTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @product = products(:widget)
  end

  test "authenticated user completes purchase" do
    sign_in_as @user

    visit product_url(@product)
    click_on "Add to Cart"
    assert_text "Added to cart"

    visit cart_url
    click_on "Checkout"
    click_on "Pay"

    assert_text "Order confirmed"
  end

  private

  def sign_in_as(user)
    visit login_url
    fill_in "Email", with: user.email
    fill_in "Password", with: default_password
    click_on "Log in"
    assert_text "Logged in"
  end
end
```

Reserve system tests for critical business paths. Do not write system tests
for every feature.

## Integration Tests

```ruby
class UserFlowsTest < ActionDispatch::IntegrationTest
  test "user signs up and creates first post" do
    get signup_url
    assert_response :success

    assert_difference "User.count" do
      post users_url, params: {
        user: { name: "New User", email: "new@example.com", password: "secret123" }
      }
    end
    assert_redirected_to root_url
    follow_redirect!
    assert_select "div.notice", /Welcome/

    get new_post_url
    assert_response :success

    assert_difference "Post.count" do
      post posts_url, params: { post: { title: "My First Post", body: "Hello" } }
    end
    assert_redirected_to post_url(Post.last)
  end
end
```

### Authentication Helper

```ruby
# test/support/authentication_helper.rb
module AuthenticationHelper
  def sign_in_as(user)
    post session_url, params: {
      email_address: user.email_address,
      password: default_password
    }
  end

  def sign_out
    delete session_url
  end
end

# Include in test_helper.rb
class ActionDispatch::IntegrationTest
  include AuthenticationHelper
end
```

## Custom Assertions

```ruby
# test/support/custom_assertions.rb
module CustomAssertions
  def assert_valid(record, msg = nil)
    msg = message(msg) {
      "Expected #{record.class} to be valid: #{record.errors.full_messages.join(', ')}"
    }
    assert record.valid?, msg
  end

  def assert_invalid(record, *attributes)
    refute record.valid?, "Expected #{record.class} to be invalid"
    attributes.each do |attr|
      assert record.errors[attr].any?, "Expected errors on :#{attr}"
    end
  end
end
```

## Testing Anti-Patterns

### 1. Testing Private Methods

Never test private methods directly. Test the public interface:

```ruby
# BAD
user.send(:normalize_email, "TEST@EXAMPLE.COM")

# GOOD
user = User.create!(name: "Test", email: "  TEST@EXAMPLE.COM  ")
assert_equal "test@example.com", user.email
```

### 2. Testing Implementation Instead of Behavior

Test observable outcomes, not internal method calls.

### 3. Overspecification

Test the essential behavior, not every attribute:

```ruby
# BAD -- fragile, tests too many things
test "creates user" do
  post users_url, params: { user: { name: "Alice", email: "a@b.com" } }
  user = User.last
  assert_equal "Alice", user.name
  assert_equal "a@b.com", user.email
  assert_not_nil user.created_at
  assert_equal 0, user.posts_count
  assert_redirected_to user_url(user)
end

# GOOD -- essential behavior
test "creates user and redirects" do
  assert_difference "User.count" do
    post users_url, params: { user: { name: "Alice", email: "a@b.com" } }
  end
  assert_redirected_to user_url(User.last)
end
```

### 4. Testing Rails Framework Behavior

Do not test that `validates :name, presence: true` works. Test business rules.

### 5. Excessive Mocking

Fixtures reduce the need for mocks. Tests running against realistic data give
more confidence than mocked interactions.

### 6. Shared State Between Tests

Tests must be independent. Never rely on test ordering. Rails randomizes
order by default.

### 7. Subclassing Test Classes

Never inherit test classes from other test classes -- parent tests run
multiple times.

## Parallel Testing

```ruby
# test/test_helper.rb
class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)
  fixtures :all
end
```

Rails creates namespaced databases per worker (`myapp_test-0`, `myapp_test-1`).
Override with `PARALLEL_WORKERS=1 bin/rails test` to disable.

Worker-specific setup:

```ruby
parallelize_setup do |worker|
  ActiveStorage::Blob.service.root = "#{ActiveStorage::Blob.service.root}-#{worker}"
end

parallelize_teardown do |worker|
  FileUtils.rm_rf(ActiveStorage::Blob.service.root)
end
```

Pitfalls: fork overhead exceeds savings for small suites; shared resources
(filesystem, Redis) cause flakiness; parallel testing amplifies an
already-optimized suite, not a substitute for fast tests.
