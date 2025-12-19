---
name: "software-testing-strategy"
description: "Strategic testing framework covering the testing pyramid, test design patterns, and testing best practices from industry leaders - complements TDD workflow with comprehensive strategy."
tags:
  - testing
  - quality
  - strategy
  - test-design
  - testing-pyramid
version: 1.0.0
---

# Software Testing Strategy

## Purpose

This skill provides comprehensive strategic guidance for designing effective test suites. It covers:

- **The Testing Pyramid**: Economic justification for the 70/20/10 distribution
- **Test Design Patterns**: AAA, Test Builders, Test Doubles, Property-Based Testing
- **Testing by Level**: When to use unit, integration, e2e, and property-based tests
- **Anti-Patterns**: How to recognize and fix common testing mistakes
- **Legacy Code Testing**: Practical techniques from Michael Feathers
- **Legendary Wisdom**: Testing principles from Kent Beck, Martin Fowler, and others

This skill is **strategic** (what to test, where to test it, how to structure it) and complements the `tdd-enforcement` skill which is **tactical** (test-first workflow execution).

Use this skill when planning testing approaches, choosing test types, designing test patterns, or expanding test coverage. Use `tdd-enforcement` when actively writing code test-first.

## When to Use This Skill

Use this skill when you need to:

- Design a testing strategy for a new feature or system
- Choose which test types to write (unit, integration, e2e)
- Understand test design patterns (AAA, Test Builders, Test Doubles)
- Recognize and fix test anti-patterns (flaky tests, slow tests, over-mocking)
- Test legacy code without existing test coverage
- Expand test coverage using risk-based prioritization
- Evaluate test quality in code reviews

## When NOT to Use This Skill

Do NOT use this skill when:

- Actively writing code test-first (use `tdd-enforcement` instead)
- Writing simple one-off tests (just write them)
- The testing approach is already clear and straightforward

## The Iron Law of Testing

These principles are non-negotiable for effective testing:

### 1. Tests Must Provide Fast Feedback

Slow tests don't get run. Unit tests should complete in milliseconds, integration tests in seconds, full e2e suite under 30 minutes.

### 2. Tests Must Be Deterministic

Flaky tests destroy trust. No random inputs, no real clocks, no network timing dependencies. Every run must produce identical results.

### 3. Test Behavior, Not Implementation

Tests should verify what the code does, not how it does it. Implementation details change; behavior contracts don't.

### 4. Test at the Appropriate Level

Don't use e2e tests for business logic. Don't mock everything in unit tests. Each test type has a purpose.

### 5. Tests Are Production Code

Apply the same quality standards: readability, maintainability, simplicity. Test code lives longer than production code.

### 6. Risk-Based Coverage Beats Percentage Coverage

100% coverage means nothing if you're asserting the wrong things. Focus on critical paths, edge cases, and high-risk areas.

## Testing Philosophy: First Principles

Each CLAUDE.md principle applies directly to testing:

### Clarity Over Cleverness

**In Testing:** Tests are executable documentation. A test should read like a specification:

```python
def test_withdrawing_more_than_balance_raises_insufficient_funds_error():
    account = Account(balance=100)

    with pytest.raises(InsufficientFundsError):
        account.withdraw(150)
```

Not: `test_withdraw_2()` with complex setup and unclear assertions.

### Strong Boundaries, Loose Coupling

**In Testing:** Test isolation. Each test should be completely independent with its own setup and teardown. Tests that depend on each other create fragile suites.

```ruby
# Good: Isolated test with complete setup
RSpec.describe Order do
  it "calculates total with tax" do
    order = Order.new(items: [Item.new(price: 100)])
    expect(order.total_with_tax(rate: 0.08)).to eq(108)
  end
end

# Bad: Depends on previous test state
# it "applies discount after tax" do
#   expect(@order.with_discount(0.1).total_with_tax).to eq(97.2)
# end
```

### Fail Fast, Fail Loud

**In Testing:** Fast feedback from failures. Tests should run quickly and fail clearly with actionable error messages.

```javascript
// Good: Clear assertion with context
expect(user.age).toBe(21,
  `User ${user.name} must be 21 to purchase alcohol, got ${user.age}`);

// Bad: Silent failure or unclear message
// assert(user.age >= 21);
```

### Simplicity Wins

**In Testing:** Simple test setup, clear assertions, no complex logic. If your test needs comments to explain what it's testing, simplify it.

```python
# Good: Simple, clear test
def test_empty_cart_has_zero_total():
    cart = Cart()
    assert cart.total() == 0

# Bad: Complex test with logic
# def test_cart_totals():
#     for i in range(10):
#         if i % 2 == 0:
#             cart.add(Item(price=i * 10))
#     assert cart.total() == sum([i * 10 for i in range(10) if i % 2 == 0])
```

### Design for Change

**In Testing:** Tests should enable refactoring, not prevent it. Test behaviors through public APIs, not internal implementation details.

```typescript
// Good: Tests behavior through public API
test('login redirects to dashboard on success', async () => {
  await loginPage.submitCredentials('user', 'pass');
  expect(browser.url()).toContain('/dashboard');
});

// Bad: Tests internal implementation
// test('login sets auth token in localStorage', async () => {
//   await loginPage.submitCredentials('user', 'pass');
//   expect(localStorage.getItem('authToken')).toBeTruthy();
// });
```

### Test at the Right Levels

**In Testing:** This is the Testing Pyramid principle. Unit tests for correctness, integration tests for contracts, e2e tests for critical journeys.

### Operational Excellence is a Feature

**In Testing:** Test observability matters. Clear test names, structured output, actionable failures, execution time tracking.

## The Testing Pyramid: Economics and Strategy

```text
        /\
       /  \  E2E Tests (10%)
      /    \
     /      \ - Slow (minutes)
    /--------\ - Expensive ($$$)
   /          \ - Critical journeys only
  / Integration\ (20%)
 /    Tests     \
/                \ - Moderate speed (seconds)
/                 \ - Contract verification
/-------------------\
|   Unit Tests     | (70%)
|   - Fast (<100ms)
|   - Cheap ($)
|   - Many tests
+---------------------+
```

### The 70/20/10 Distribution

**70% Unit Tests:**

- Test business logic, algorithms, validations
- No I/O, no network, no database
- Each test completes in milliseconds
- Hundreds or thousands of tests

**20% Integration Tests:**

- Test component interactions
- Verify contracts between modules
- Real dependencies (database, message queue)
- Each test completes in seconds
- Dozens to hundreds of tests

**10% E2E Tests:**

- Test critical user journeys
- Full stack: frontend → backend → database
- Each test completes in seconds to minutes
- Keep suite under 30 minutes total
- Top 20% of journeys = 80% of business value

### Economic Justification

**Testing Pyramid Approach (70/20/10):**

- CI/CD infrastructure: ~$100/month
- Fast feedback: 5-10 minutes for full suite
- Developer velocity: High (tests run frequently)
- Maintenance: Low (unit tests rarely break)

**Inverted Pyramid (Heavy E2E):**

- CI/CD infrastructure: ~$10,000/month
- Slow feedback: 2-4 hours for full suite
- Developer velocity: Low (developers skip tests)
- Maintenance: High (e2e tests brittle)

**Source:** Industry research (TestRail, FullScale 2025)

### 2025 Adaptations

**Microservices Architecture:** Adjust to 65/25/10

- More integration tests for service contracts
- Contract testing (Pact, Spring Cloud Contract)
- Still maintain fast unit test majority

**Cloud-Native Systems:** Preview Environments

- Deploy PR branches to temporary environments
- Run e2e tests against preview before merge
- Faster feedback than full production-like environment

**Focus on Value:** 20% of Journeys = 80% of Business Value

- Identify critical paths: authentication, checkout, data submission
- E2E test only these high-value journeys
- Don't test every edge case at e2e level

## Legendary Testing Wisdom

### Kent Beck (TDD Pioneer)

#### "Test-first is about design, not testing."

- Writing tests first forces you to design clear interfaces
- If it's hard to test, the design needs improvement
- Red-Green-Refactor cycle: fail → pass → improve

**Tests as Executable Specifications:**

```python
# Test describes what the code should do
def test_account_prevents_overdraft():
    """Account.withdraw() should raise InsufficientFundsError
    when withdrawal amount exceeds balance."""
    account = Account(balance=100)

    with pytest.raises(InsufficientFundsError):
        account.withdraw(150)
```

### Martin Fowler (Testing Patterns)

#### "Tests should be FIRST: Fast, Isolated, Repeatable, Self-validating, Timely."

- **Fast:** Unit tests in milliseconds
- **Isolated:** No shared state between tests
- **Repeatable:** Same result every time
- **Self-validating:** Pass/fail, no manual inspection
- **Timely:** Written with (or before) production code

**Test Doubles Taxonomy:**

- **Mock:** Verifies interactions (assert method was called)
- **Stub:** Returns predetermined values
- **Fake:** Working implementation (in-memory database)
- **Spy:** Records calls for later inspection

**Testing Pyramid Principle:**

- Unit tests form the base (many, fast, cheap)
- Integration tests in the middle (fewer, slower)
- E2E tests at the top (fewest, slowest, expensive)

### Michael Feathers (Legacy Code)

#### "Legacy code is code without tests."

#### Characterization Tests

When you don't know what the code should do, write tests that capture what it currently does:

```ruby
# Characterization test for legacy code
RSpec.describe LegacyPriceCalculator do
  it "calculates price with current behavior" do
    calculator = LegacyPriceCalculator.new

    # Document current behavior, even if unclear
    expect(calculator.calculate(quantity: 5, item_code: "A")).to eq(47.50)
    expect(calculator.calculate(quantity: 5, item_code: "B")).to eq(50.00)
  end
end
```

**Finding Seams:** Identify injection points for tests in untestable code.

**Cover and Modify:** Add characterization tests, then refactor safely.

### Rich Hickey (Simplicity)

#### "Simplicity is not easy, but it's essential."

#### In Testing (Simplicity)

- Use simple, immutable data structures in tests
- Avoid test complexity (if/else, loops in tests)
- Pure functions are trivially testable

```clojure
;; Simple test with immutable data
(deftest test-cart-total
  (let [cart {:items [{:price 10} {:price 20}]}]
    (is (= 30 (calculate-total cart)))))
```

### John Carmack (Performance)

#### "Measure, don't guess."

#### In Testing (Performance)

- Benchmark critical paths
- Performance regression tests
- Measure test execution time

```python
import pytest

@pytest.mark.benchmark
def test_search_performance(benchmark):
    large_dataset = generate_dataset(10000)

    result = benchmark(search_function, large_dataset, "query")

    assert result is not None
    assert benchmark.stats.mean < 0.1  # Must complete in <100ms
```

## Test Design Patterns

### AAA Pattern (Arrange-Act-Assert)

The fundamental structure for readable tests:

```python
def test_user_registration_sends_welcome_email():
    # Arrange: Set up test data and dependencies
    email_service = FakeEmailService()
    user_service = UserService(email_service)
    user_data = {"email": "user@example.com", "name": "Alice"}

    # Act: Execute the behavior being tested
    user = user_service.register(user_data)

    # Assert: Verify the expected outcome
    assert user.id is not None
    assert email_service.sent_emails[0].recipient == "user@example.com"
    assert "Welcome" in email_service.sent_emails[0].subject
```

**Benefits:**

- Clear structure: setup → action → verification
- Easy to read and understand
- Separates concerns within the test

### Test Builder Pattern

For complex object creation in tests:

```typescript
class UserBuilder {
  private name = "Test User";
  private email = "test@example.com";
  private age = 25;
  private roles: string[] = [];

  withName(name: string): UserBuilder {
    this.name = name;
    return this;
  }

  withEmail(email: string): UserBuilder {
    this.email = email;
    return this;
  }

  withAge(age: number): UserBuilder {
    this.age = age;
    return this;
  }

  withRoles(...roles: string[]): UserBuilder {
    this.roles = roles;
    return this;
  }

  build(): User {
    return new User(this.name, this.email, this.age, this.roles);
  }
}

// Usage in tests
test('admin users can delete posts', () => {
  const admin = new UserBuilder()
    .withRoles('admin')
    .build();

  expect(admin.canDelete(post)).toBe(true);
});

test('underage users cannot purchase alcohol', () => {
  const minor = new UserBuilder()
    .withAge(17)
    .build();

  expect(minor.canPurchaseAlcohol()).toBe(false);
});
```

**Benefits:**

- Readable test setup with fluent interface
- Default values for unimportant fields
- Reusable across tests

### Test Doubles (Fowler Taxonomy)

#### Mock: Verifies Interactions

Use when you need to verify a method was called:

```python
def test_successful_order_sends_confirmation_email():
    email_service_mock = Mock()
    order_service = OrderService(email_service_mock)

    order_service.place_order(customer_id=123, items=[{"sku": "ABC"}])

    email_service_mock.send_email.assert_called_once_with(
        to="customer@example.com",
        subject="Order Confirmation"
    )
```

#### Stub: Returns Predetermined Values

Use when you need to control dependencies' return values:

```ruby
RSpec.describe PaymentProcessor do
  it "retries on temporary payment gateway failure" do
    gateway_stub = double("PaymentGateway")
    allow(gateway_stub).to receive(:charge)
      .and_return(
        { success: false, error: "Timeout" },  # First call fails
        { success: true, transaction_id: "123" }  # Second call succeeds
      )

    processor = PaymentProcessor.new(gateway_stub)
    result = processor.process_payment(amount: 100)

    expect(result.success).to be true
    expect(gateway_stub).to have_received(:charge).twice
  end
end
```

#### Fake: Working Implementation

Use for complex dependencies like databases:

```javascript
class FakeUserRepository {
  constructor() {
    this.users = new Map();
    this.nextId = 1;
  }

  save(user) {
    const id = this.nextId++;
    this.users.set(id, { ...user, id });
    return { ...user, id };
  }

  findById(id) {
    return this.users.get(id) || null;
  }

  findByEmail(email) {
    return Array.from(this.users.values())
      .find(u => u.email === email) || null;
  }
}

// Usage in tests
test('user registration prevents duplicate emails', async () => {
  const repo = new FakeUserRepository();
  const service = new UserService(repo);

  await service.register({ email: 'user@example.com', name: 'Alice' });

  await expect(
    service.register({ email: 'user@example.com', name: 'Bob' })
  ).rejects.toThrow('Email already registered');
});
```

#### Spy: Records Calls

Use when you need to verify calls after the fact:

```python
class EmailServiceSpy:
    def __init__(self):
        self.sent_emails = []

    def send_email(self, to, subject, body):
        self.sent_emails.append({
            'to': to,
            'subject': subject,
            'body': body
        })

def test_order_confirmation_email_contains_order_details():
    email_spy = EmailServiceSpy()
    order_service = OrderService(email_spy)

    order = order_service.place_order(
        customer_id=123,
        items=[{"sku": "ABC", "quantity": 2}]
    )

    assert len(email_spy.sent_emails) == 1
    email = email_spy.sent_emails[0]
    assert email['to'] == order.customer_email
    assert "ABC" in email['body']
    assert "quantity: 2" in email['body']
```

### Test Double Selection Guide

**Decision Tree:**

1. **Do you need to verify a method was called?** → Use Mock
2. **Do you need to control return values?** → Use Stub
3. **Is the dependency complex (database, file system)?** → Use Fake
4. **Do you need to inspect calls after execution?** → Use Spy

**Rule of Thumb:** Mock external systems, not your own components. Test state, not interactions (Google standard).

### Parameterized/Table-Driven Tests

Reduce duplication for multiple inputs with same logic:

```python
import pytest

@pytest.mark.parametrize("input_text,expected_slug", [
    ("Hello World", "hello-world"),
    ("Hello  World", "hello-world"),  # Multiple spaces
    ("HELLO WORLD", "hello-world"),  # Uppercase
    ("Hello, World!", "hello-world"),  # Punctuation
    ("Café au Lait", "cafe-au-lait"),  # Accents
    ("  Hello World  ", "hello-world"),  # Leading/trailing spaces
])
def test_slugify(input_text, expected_slug):
    assert slugify(input_text) == expected_slug
```

**Benefits:**

- Clear table of inputs and expected outputs
- Easy to add new test cases
- Reduces code duplication

## Testing by Level

### Unit Testing

**Characteristics:**

- **Speed:** <100ms per test
- **Isolation:** No I/O, no network, no database
- **Scope:** Single function, class, or module
- **Deterministic:** Same inputs always produce same outputs
- **Quantity:** Hundreds to thousands

**What to Test:**

- Business logic and algorithms
- Input validation and edge cases
- Error handling and exceptions
- Data transformations
- Calculations and computations

**Google Standard:** "Test via public APIs"

Don't test private methods directly. Test behaviors through public interfaces.

```python
# Good: Tests behavior through public API
def test_account_applies_interest():
    account = SavingsAccount(balance=1000, interest_rate=0.05)

    account.apply_monthly_interest()

    assert account.balance == 1004.17  # 1000 * (1.05^(1/12))

# Bad: Tests private implementation detail
# def test_calculate_monthly_interest_rate():
#     account = SavingsAccount(balance=1000, interest_rate=0.05)
#     assert account._calculate_monthly_rate() == 0.004074
```

#### Example: Testing Edge Cases

```javascript
describe('divideNumbers', () => {
  it('divides positive numbers', () => {
    expect(divideNumbers(10, 2)).toBe(5);
  });

  it('divides negative numbers', () => {
    expect(divideNumbers(-10, 2)).toBe(-5);
  });

  it('throws error when dividing by zero', () => {
    expect(() => divideNumbers(10, 0)).toThrow('Cannot divide by zero');
  });

  it('handles floating point division', () => {
    expect(divideNumbers(10, 3)).toBeCloseTo(3.333, 2);
  });
});
```

### Integration Testing

**Characteristics:**

- **Speed:** Seconds per test
- **Isolation:** Real dependencies (database, message queue, external services)
- **Scope:** Multiple components working together
- **Setup:** Requires test database, docker containers, or service mocks
- **Quantity:** Dozens to hundreds

**What to Test:**

- Component interactions and contracts
- Database queries and transactions
- API endpoints (request → response)
- Message queue publishers/consumers
- External service integrations

#### Example: API Integration Test

```ruby
RSpec.describe "POST /api/orders" do
  it "creates order and returns 201 with order details" do
    customer = Customer.create!(email: "customer@example.com")
    product = Product.create!(sku: "ABC", price: 25.00)

    post "/api/orders", params: {
      customer_id: customer.id,
      items: [
        { sku: "ABC", quantity: 2 }
      ]
    }

    expect(response).to have_http_status(201)
    expect(json_response['total']).to eq(50.00)
    expect(Order.count).to eq(1)
    expect(Order.last.customer_id).to eq(customer.id)
  end
end
```

#### Example: Database Integration Test

```typescript
describe('UserRepository', () => {
  beforeEach(async () => {
    await database.migrate.latest();
  });

  afterEach(async () => {
    await database.migrate.rollback();
  });

  it('finds users by email with case insensitivity', async () => {
    const repo = new UserRepository(database);
    await repo.save({ email: 'Alice@Example.com', name: 'Alice' });

    const user = await repo.findByEmail('alice@example.com');

    expect(user).not.toBeNull();
    expect(user.name).toBe('Alice');
  });
});
```

### E2E Testing

**Characteristics:**

- **Speed:** Seconds to minutes per test
- **Isolation:** Full stack (browser → backend → database)
- **Scope:** Complete user journeys
- **Setup:** Running application, test database, browser automation
- **Quantity:** Dozens (keep suite under 30 minutes)

**What to Test:**

- Critical user journeys (top 20% = 80% of business value)
- Authentication and authorization flows
- Checkout and payment processes
- Data submission workflows
- Cross-browser compatibility (if needed)

**2025 Best Practice:** Run e2e tests in parallel, keep total suite under 30 minutes.

#### Example: E2E User Journey

```python
def test_user_completes_checkout_journey(browser):
    # Navigate to product page
    browser.visit("https://shop.example.com/products/laptop")
    browser.click("Add to Cart")

    # View cart
    browser.click("Cart")
    assert browser.find("Laptop").is_visible()
    assert browser.find("$999.99").is_visible()

    # Checkout
    browser.click("Checkout")
    browser.fill("email", "customer@example.com")
    browser.fill("card_number", "4242424242424242")
    browser.fill("expiry", "12/25")
    browser.fill("cvc", "123")
    browser.click("Place Order")

    # Confirmation
    assert browser.find("Order Confirmed").is_visible()
    assert browser.find("#123456").is_visible()  # Order number
```

**Anti-Pattern:** Testing business logic at e2e level

```javascript
// Bad: Don't test edge cases in e2e tests
test('empty cart shows correct message', async () => {
  await page.goto('/cart');
  expect(await page.textContent('.cart-message')).toBe('Your cart is empty');
});

// Good: Test this at unit level instead
test('Cart.isEmpty returns true when no items', () => {
  const cart = new Cart();
  expect(cart.isEmpty()).toBe(true);
});
```

### Property-Based Testing

**When to Use:**

- Input validation with many edge cases
- Parser correctness
- Mathematical properties (commutativity, associativity)
- Serialization/deserialization roundtrips

**Example Using Hypothesis (Python):**

```python
from hypothesis import given
from hypothesis.strategies import text

@given(text())
def test_slugify_roundtrip_property(input_text):
    """Slugifying twice should produce the same result as slugifying once."""
    assert slugify(slugify(input_text)) == slugify(input_text)

@given(text(), text())
def test_slugify_concatenation(text1, text2):
    """Slugifying concatenated strings should match concatenating slugs."""
    combined = slugify(text1 + " " + text2)
    separate = slugify(text1) + "-" + slugify(text2)
    assert combined == separate
```

**Benefits:** Discovers edge cases you didn't think to test manually.

## Anti-Patterns and Code Smells

### 1. Flaky Tests (Non-Deterministic)

**Symptom:** Tests pass sometimes, fail other times with no code changes.

**Causes:**

- Real system clocks
- Random number generators without seeds
- Network timing dependencies
- Shared state between tests
- Asynchronous code without proper waits

**Fix:**

```python
# Bad: Real clock makes test non-deterministic
def test_token_expires_after_one_hour():
    token = create_token()
    time.sleep(3601)  # Wait 1 hour + 1 second
    assert is_expired(token)  # May fail due to timing

# Good: Control time with test doubles
def test_token_expires_after_one_hour():
    fake_clock = FakeClock(now=datetime(2025, 1, 1, 12, 0, 0))
    token = create_token(clock=fake_clock)

    fake_clock.advance(hours=1, seconds=1)

    assert is_expired(token, clock=fake_clock)
```

### 2. Slow Tests (Wrong Level)

**Symptom:** Unit tests taking seconds instead of milliseconds.

**Causes:**

- Database queries in unit tests
- Network calls in unit tests
- File I/O in unit tests
- Testing at wrong level (e2e test for business logic)

**Fix:**

```ruby
# Bad: Unit test with database call (slow)
RSpec.describe Order do
  it "calculates total" do
    order = Order.create!(customer_id: 123)
    order.items.create!(sku: "ABC", price: 25, quantity: 2)

    expect(order.total).to eq(50)
  end
end

# Good: Pure unit test (fast)
RSpec.describe Order do
  it "calculates total" do
    order = Order.new
    order.items = [
      OrderItem.new(price: 25, quantity: 2)
    ]

    expect(order.total).to eq(50)
  end
end
```

### 3. Test Interdependencies

**Symptom:** Tests pass when run in one order, fail when run in different order.

**Causes:**

- Shared mutable state
- Tests depending on previous test setup
- Database state not cleaned between tests
- Global variables

**Fix:**

```javascript
// Bad: Tests depend on shared state
let user;

beforeAll(() => {
  user = createUser({ email: 'test@example.com' });
});

test('user can login', () => {
  expect(login(user)).toBe(true);
  user.loginCount++;  // Mutates shared state
});

test('new users have zero logins', () => {
  expect(user.loginCount).toBe(0);  // Fails: depends on previous test
});

// Good: Each test isolated with own setup
test('user can login', () => {
  const user = createUser({ email: 'test@example.com' });
  expect(login(user)).toBe(true);
});

test('new users have zero logins', () => {
  const user = createUser({ email: 'test@example.com' });
  expect(user.loginCount).toBe(0);
});
```

### 4. Over-Mocking (Testing Implementation)

**Symptom:** Tests break when refactoring internal implementation, even though behavior unchanged.

**Rule:** Mock external systems, not your own components. Test state, not interactions.

**Fix:**

```python
# Bad: Over-mocking internal components
def test_place_order():
    inventory_mock = Mock()
    payment_mock = Mock()
    email_mock = Mock()
    order_service = OrderService(inventory_mock, payment_mock, email_mock)

    order_service.place_order(customer_id=123, items=[{"sku": "ABC"}])

    inventory_mock.check_availability.assert_called_once()
    inventory_mock.reserve_items.assert_called_once()
    payment_mock.charge.assert_called_once()
    email_mock.send_confirmation.assert_called_once()
    # Tests implementation details, brittle

# Good: Test behavior with minimal mocking
def test_place_order():
    fake_inventory = FakeInventory(items={"ABC": 10})
    fake_payment = FakePaymentGateway()
    email_spy = EmailServiceSpy()
    order_service = OrderService(fake_inventory, fake_payment, email_spy)

    order = order_service.place_order(
        customer_id=123,
        items=[{"sku": "ABC", "quantity": 2}]
    )

    # Test state and critical behavior
    assert order.status == "confirmed"
    assert fake_inventory.available("ABC") == 8
    assert len(email_spy.sent_emails) == 1
```

### 5. Logic in Tests

**Symptom:** Tests contain conditionals, loops, or complex calculations.

**Problem:** Who tests the tests? Test logic can have bugs.

**Fix:**

```typescript
// Bad: Logic in test
test('all users can view public posts', () => {
  const users = [admin, moderator, guest];

  for (const user of users) {
    if (user.role !== 'banned') {
      expect(user.canView(publicPost)).toBe(true);
    }
  }
});

// Good: Simple, explicit tests (or parameterized)
test('admin can view public posts', () => {
  expect(admin.canView(publicPost)).toBe(true);
});

test('moderator can view public posts', () => {
  expect(moderator.canView(publicPost)).toBe(true);
});

test('guest can view public posts', () => {
  expect(guest.canView(publicPost)).toBe(true);
});
```

### 6. Unclear Test Names

**Symptom:** Test name like `test_user_2` or `test_edge_case`.

**Problem:** When test fails, unclear what broke.

**Fix:**

```ruby
# Bad: Unclear names
def test_withdraw_1
  # ...
end

def test_withdraw_2
  # ...
end

# Good: Behavioral names
def test_withdraw_deducts_amount_from_balance
  # ...
end

def test_withdraw_raises_error_when_insufficient_funds
  # ...
end
```

## Test Quality Checklist

Beyond the TDD enforcement checklist, evaluate tests for:

### Maintainability

- [ ] Test names describe behavior, not implementation
- [ ] Tests are isolated (no shared state)
- [ ] Setup is clear and minimal
- [ ] Assertions are simple and focused
- [ ] Test data is meaningful (not `foo`, `bar`, `test123`)

### Risk-Based Coverage

- [ ] Critical paths have multiple test cases
- [ ] Edge cases are covered
- [ ] Error paths are tested
- [ ] High-risk areas (security, payments) have thorough coverage
- [ ] Low-risk areas (UI text) have minimal coverage

### Test Code Quality

- [ ] No duplication (use builders, factories, helpers)
- [ ] No magic numbers (use named constants)
- [ ] No complex logic (conditionals, loops)
- [ ] Test doubles are appropriate (mock external systems only)
- [ ] Tests run fast at appropriate level

### Behavioral Naming

```python
# Good naming pattern: test_<scenario>_<expected_behavior>
test_withdrawing_more_than_balance_raises_error()
test_valid_coupon_code_applies_discount()
test_expired_coupon_code_returns_error()
```

### Clear Assertions

```javascript
// Bad: Unclear assertion
expect(result).toBe(true);

// Good: Clear assertion with context
expect(user.canAccessAdminPanel()).toBe(true);
expect(order.status).toBe('completed');
```

## Testing Legacy Code

### Characterization Tests (Michael Feathers)

When dealing with code without tests, start by documenting current behavior:

```python
def test_legacy_price_calculator_current_behavior():
    """
    Characterization test for legacy calculator.
    This documents CURRENT behavior, which may not be correct.
    Once we understand it, we can refactor safely.
    """
    calculator = LegacyPriceCalculator()

    # Document what the code currently does
    assert calculator.calculate(quantity=1, item="A") == 10.00
    assert calculator.calculate(quantity=5, item="A") == 45.00  # Bulk discount?
    assert calculator.calculate(quantity=1, item="B") == 15.00
    assert calculator.calculate(quantity=1, item="X") == 0.00  # Returns 0 for unknown?
```

### Finding Seams

**Seam:** A place where you can alter behavior without editing the code.

#### Example: Dependency Injection Seam

```ruby
# Legacy code (hard to test)
class OrderProcessor
  def process(order)
    gateway = PaymentGateway.new(api_key: ENV['PAYMENT_KEY'])
    result = gateway.charge(order.amount)

    if result.success?
      order.mark_paid
    end
  end
end

# Add seam with dependency injection (backward compatible)
class OrderProcessor
  def initialize(gateway: nil)
    @gateway = gateway || PaymentGateway.new(api_key: ENV['PAYMENT_KEY'])
  end

  def process(order)
    result = @gateway.charge(order.amount)

    if result.success?
      order.mark_paid
    end
  end
end

# Now testable
RSpec.describe OrderProcessor do
  it "marks order as paid when payment succeeds" do
    fake_gateway = FakePaymentGateway.new(success: true)
    processor = OrderProcessor.new(gateway: fake_gateway)
    order = Order.new(amount: 100)

    processor.process(order)

    expect(order.paid?).to be true
  end
end
```

### Cover and Modify

Strategy for legacy code:

1. **Write characterization tests** to capture current behavior
2. **Verify tests fail** when you break the code (tests actually test something)
3. **Refactor safely** with tests protecting against regressions
4. **Improve tests** as you understand intended behavior
5. **Add new tests** for new features

### Approval Testing Pattern

For complex outputs (JSON, HTML, reports):

```python
def test_invoice_generation_approval():
    """Approval test: Captures full output for human review."""
    order = Order(
        id=123,
        customer="Alice",
        items=[Item(sku="ABC", price=25, quantity=2)]
    )

    invoice_html = generate_invoice(order)

    # First run: approve_file creates approved/invoice.html
    # Subsequent runs: compare against approved version
    approval.verify(invoice_html, name="invoice")
```

Benefits: Tests complex output without writing assertions for every detail.

## Test Maintenance and Refactoring

### When to Refactor Tests

Refactor tests when:

- Tests are duplicated (extract shared setup to builders/factories)
- Tests are fragile (break with irrelevant changes)
- Tests are unclear (rename for clarity, simplify setup)
- Tests are slow at wrong level (move to unit tests)

### Keeping Tests Valuable as Code Evolves

**Tests Enable Refactoring:**

Good tests allow you to refactor production code confidently. If refactoring breaks tests that shouldn't break, tests are too coupled to implementation.

**Test Behavior, Not Implementation:**

```javascript
// Bad: Tests implementation (breaks when refactoring)
test('UserService.findById calls repository.query with SELECT statement', () => {
  const repo = mock(UserRepository);
  const service = new UserService(repo);

  service.findById(123);

  expect(repo.query).toHaveBeenCalledWith('SELECT * FROM users WHERE id = ?', [123]);
});

// Good: Tests behavior (survives refactoring)
test('UserService.findById returns user with matching ID', async () => {
  const repo = new FakeUserRepository();
  await repo.save({ id: 123, name: 'Alice' });
  const service = new UserService(repo);

  const user = await service.findById(123);

  expect(user.name).toBe('Alice');
});
```

### Test Code is Production Code

Apply same standards:

- Clear naming
- No duplication
- Simple structure
- Easy to understand

### Removing Obsolete Tests

Delete tests that:

- Test removed features
- Duplicate other tests
- Provide no value (tautological assertions)

### Test Data Builder Pattern

For maintainable test data:

```python
class OrderBuilder:
    def __init__(self):
        self.customer_id = 1
        self.items = []
        self.status = "pending"

    def for_customer(self, customer_id):
        self.customer_id = customer_id
        return self

    def with_item(self, sku, quantity=1, price=10.0):
        self.items.append({"sku": sku, "quantity": quantity, "price": price})
        return self

    def confirmed(self):
        self.status = "confirmed"
        return self

    def build(self):
        return Order(
            customer_id=self.customer_id,
            items=self.items,
            status=self.status
        )

# Usage
def test_confirmed_orders_charge_customer():
    order = (OrderBuilder()
        .for_customer(123)
        .with_item("ABC", quantity=2, price=25.0)
        .confirmed()
        .build())

    payment_service.charge(order)

    assert payment_service.charged_amount == 50.0
```

## Workflow: Designing a Test Strategy

Step-by-step process for new features:

### 1. Understand Requirements

What is the feature? What are acceptance criteria? What are edge cases?

### 2. Risk Assessment

Identify high-risk areas:

- Security boundaries (authentication, authorization)
- Financial calculations (payments, refunds)
- Data integrity (database writes, transactions)
- External integrations (payment gateways, email services)

### 3. Choose Test Levels (Bottom-Up)

**Start with Unit Tests (70%):**

- Business logic
- Calculations
- Input validation
- Edge cases

**Add Integration Tests (20%):**

- Database interactions
- API contracts
- External service integrations

**Add E2E Tests (10%):**

- Critical user journeys only
- Top 20% of user flows

### 4. Coverage Planning (Risk-Based)

Prioritize by risk, not by percentage:

- High-risk: Multiple test cases, thorough edge case coverage
- Medium-risk: Happy path + critical errors
- Low-risk: Smoke test only (if any)

### 5. Design Test Cases

For each test:

- Clear name describing behavior
- Arrange-Act-Assert structure
- Appropriate test doubles
- Simple, focused assertions

### 6. CI/CD Integration

- Unit tests run on every commit
- Integration tests run on PR creation
- E2E tests run before merge (or on preview environment)
- Keep feedback loop under 10 minutes

## Example: E-Commerce Checkout Feature

**Feature:** User can add items to cart and complete checkout.

**Risk Assessment:**

- **High-risk:** Payment processing, order creation
- **Medium-risk:** Cart calculations, inventory checks
- **Low-risk:** UI text, button labels

**Test Strategy:**

**Unit Tests (70%):**

```python
# test_cart.py
def test_empty_cart_has_zero_total()
def test_cart_sums_item_prices()
def test_cart_applies_quantity_discounts()
def test_cart_rejects_invalid_coupon_codes()
def test_cart_applies_valid_coupon_discounts()

# test_order.py
def test_order_calculates_tax()
def test_order_validates_shipping_address()
def test_order_prevents_negative_quantities()
```

**Integration Tests (20%):**

```python
# test_checkout_api.py
def test_post_checkout_creates_order_in_database()
def test_post_checkout_charges_payment_gateway()
def test_post_checkout_returns_400_for_invalid_payment()
def test_post_checkout_rolls_back_on_payment_failure()
```

**E2E Tests (10%):**

```python
# test_checkout_journey.py
def test_user_completes_successful_checkout()
def test_user_sees_error_for_declined_payment()
```

## Common Mistakes to Avoid

### Mistake 1: 100% Coverage as Goal

**Why Bad:** Coverage percentage is a vanity metric. You can have 100% coverage with meaningless assertions.

**Why Good:** Risk-based coverage focuses on critical paths. 80% coverage on high-value code beats 100% coverage on trivial code.

### Mistake 2: Testing Implementation Details

**Why Bad:** Tests break when refactoring, even though behavior unchanged. Creates maintenance burden.

**Why Good:** Testing behaviors through public APIs enables safe refactoring. Tests survive implementation changes.

### Mistake 3: Inverted Pyramid (Heavy E2E)

**Why Bad:** Slow feedback (hours), expensive infrastructure ($10k/month), brittle tests, high maintenance.

**Why Good:** Testing pyramid (70/20/10) provides fast feedback (minutes), low cost ($100/month), stable tests.

### Mistake 4: No Test Isolation

**Why Bad:** Tests that depend on each other fail in unpredictable ways. Debugging is nightmare. Can't run tests in parallel.

**Why Good:** Isolated tests with complete setup can run in any order, in parallel, and failures are clear.

### Mistake 5: Accepting Flaky Tests

**Why Bad:** Flaky tests destroy trust. Teams start ignoring test failures. Defeats entire purpose of testing.

**Why Good:** Zero tolerance for flaky tests. Fix immediately or delete. Deterministic tests provide reliable feedback.

### Mistake 6: Writing Tests After Production Code

**Why Bad:** Code becomes hard to test. Tests are an afterthought. Untestable designs emerge.

**Why Good:** Test-first (TDD) forces testable design. Tests drive good architecture. Prevents untestable code.

## Common Rationalizations

| Excuse | Reality | Remedy |
| --- | --- | --- |
| "We don't have time to test" | Bugs in production cost 100x more to fix. Manual testing takes longer than automated tests. | Start with critical path unit tests. Add tests incrementally. |
| "Tests slow us down" | Bad tests slow you down. Good tests speed you up by catching regressions early. | Follow testing pyramid. Keep unit tests under 100ms. |
| "100% coverage means quality" | Coverage ≠ quality. Can have 100% coverage with meaningless assertions like `expect(result).toBeTruthy()`. | Risk-based testing. Focus on critical paths and edge cases. |
| "We'll add tests later" | Later never comes. Technical debt compounds. Untestable code grows. | Use TDD. Write tests first. Make testability non-negotiable. |
| "Code is too complex to test" | Untestable code is poorly designed code. Complexity is design smell. | Refactor for testability. Extract dependencies. Break down complex functions. |
| "Integration tests are enough" | Integration tests are slow and don't catch all edge cases. Debugging integration test failures is hard. | Add fast unit tests for business logic and edge cases. |
| "Mocking is too hard" | Mocking internal components is hard (and wrong). Mocking external systems is straightforward. | Mock only external systems. Use fakes for complex dependencies. |

## Quick Reference Tables

### Table 1: Test Type Characteristics

| Test Type | Speed | Isolation | Coverage Scope | Cost | Feedback Loop | Quantity |
| --- | --- | --- | --- | --- | --- | --- |
| Unit | <100ms | High (no I/O) | Single function/class | $ | Seconds | Hundreds/thousands |
| Integration | Seconds | Medium (real dependencies) | Multiple components | $$ | Minutes | Dozens/hundreds |
| E2E | Minutes | Low (full stack) | Complete user journey | $$$ | 30+ minutes | Dozens |
| Property-Based | <1s | High | Input space coverage | $ | Seconds | Hundreds of generated cases |

### Table 2: Test Double Selection Guide

| Scenario | Test Double | Rationale | Example |
| --- | --- | --- | --- |
| Verify method was called | Mock | Need to assert on interactions | Email service sent notification |
| Control return values | Stub | Need predetermined responses | API returns success, then failure |
| Complex dependency | Fake | Need working in-memory implementation | In-memory database for tests |
| Inspect calls after execution | Spy | Need to verify calls and arguments | Logger recorded error messages |

### Table 3: Anti-Pattern Recognition

| Anti-Pattern | Symptom | Root Cause | Fix | Priority |
| --- | --- | --- | --- | --- |
| Flaky Tests | Passes sometimes, fails randomly | Real clock, network timing, shared state | Control time, isolate tests, use fakes | Critical |
| Slow Tests | Unit tests take seconds | I/O, database, network in unit tests | Remove dependencies, test pure logic | High |
| Test Interdependencies | Fails in different order | Shared mutable state | Isolate tests, complete setup per test | High |
| Over-Mocking | Breaks when refactoring internals | Mocking own components | Mock external systems only | Medium |
| Logic in Tests | Tests have if/loops | Complex test setup | Simplify tests, use parameterized tests | Medium |
| Unclear Names | Can't tell what broke | Generic test names | Behavioral naming: `test_<scenario>_<behavior>` | Low |

### Table 4: Test Level Selection Matrix

| Feature Characteristic | Unit | Integration | E2E | Rationale |
| --- | --- | --- | --- | --- |
| Business logic | ✓ | - | - | Fast, isolated, many edge cases |
| Calculations | ✓ | - | - | Pure functions, no dependencies |
| Database queries | - | ✓ | - | Need real database for SQL semantics |
| API contracts | - | ✓ | - | Verify request/response structure |
| Critical user journey | - | - | ✓ | Full stack, business-critical path |
| Edge cases | ✓ | - | - | Too slow to test at higher levels |
| Error handling | ✓ | ✓ | - | Unit for logic, integration for failure modes |

### Table 5: Testing Legacy Code Strategy

| Situation | Technique | Steps | Outcome |
| --- | --- | --- | --- |
| No tests, unclear behavior | Characterization Tests | Write tests documenting current behavior, verify tests fail when code breaks, refactor with test protection | Safe refactoring baseline |
| Untestable code | Find Seams | Identify injection points (constructor, parameters), extract dependencies, inject test doubles | Testable architecture |
| Complex output | Approval Testing | Capture output to approved file, human review and approve, future runs compare against approved | Test complex outputs easily |
| High-risk change | Cover and Modify | Add characterization tests, make change, verify tests still pass, improve tests | Safe modification of legacy code |

## Integration with Other Skills

### tdd-enforcement (Tactical Execution)

**Relationship:** Complementary

- **tdd-enforcement:** WORKFLOW for test-first development (red-green-refactor cycle)
- **software-testing-strategy:** STRATEGY for test design and planning

**When to Use Each:**

- Use `software-testing-strategy` when designing testing approach for a feature
- Use `tdd-enforcement` when actively writing code test-first

**Example Flow:**

1. New feature: "Add user registration"
2. Load `software-testing-strategy` to design test strategy:
   - Unit tests: Password validation, email format validation
   - Integration tests: Database user creation, unique email constraint
   - E2E tests: Registration form submission journey
3. Switch to `tdd-enforcement` for test-first implementation:
   - Red: Write failing test for password validation
   - Green: Implement password validation
   - Refactor: Extract validation logic
   - Repeat for each component

### systematic-code-review (Evaluation)

**Relationship:** Testing criteria in reviews

- `systematic-code-review` evaluates test quality in PRs
- References anti-patterns from `software-testing-strategy`

#### Example: Code Review Integration

During code review (Step 5: Evaluate Tests), reviewer references this skill:

```text
[test/order_test.py:45-60]
**issue (blocking, tests)**: This test exhibits the Flaky Test anti-pattern.

The test uses `time.sleep(1)` to wait for async operation, which creates non-deterministic behavior. Per software-testing-strategy Iron Law #2, tests must be deterministic.

**Suggestion:** Use a FakeClock or await the async operation properly with timeouts.
```

### refactoring-to-patterns

**Relationship:** Test patterns support refactoring

- Test Data Builder is Builder pattern applied to tests
- Strategy pattern for test doubles (Mock, Stub, Fake, Spy)

#### Example: Refactoring with Tests

When refactoring introduces patterns, tests adapt:

```python
# Before: Simple function
def calculate_price(quantity, item_type):
    if item_type == "book":
        return quantity * 10 * 0.9  # 10% discount
    elif item_type == "electronics":
        return quantity * 100 * 0.95  # 5% discount

# Test before
def test_book_price():
    assert calculate_price(2, "book") == 18

# After: Strategy pattern
class BookPricing:
    def calculate(self, quantity):
        return quantity * 10 * 0.9

# Test after (tests behavior through interface)
def test_book_pricing_applies_discount():
    pricing = BookPricing()
    assert pricing.calculate(quantity=2) == 18
```

## Key Takeaways

1. **Follow testing pyramid:** 70% unit, 20% integration, 10% e2e for optimal economics and feedback speed
2. **Test behavior, not implementation:** Tests should survive refactoring of internal details
3. **Fast feedback:** Unit tests <100ms, integration tests in seconds, full e2e suite under 30 minutes
4. **Risk-based coverage beats percentage targets:** Focus on critical paths and high-risk areas
5. **Tests are production code:** Apply same quality standards to test code
6. **Test at the appropriate level:** Don't use e2e for business logic, don't mock everything in unit tests
7. **Mock external systems, not your own code:** Test state, not interactions (Google standard)
8. **Tests enable refactoring:** Good tests provide confidence to change production code
9. **Flaky tests destroy trust:** Fix immediately or delete. Zero tolerance for non-deterministic tests.
10. **Legacy code is code without tests:** Use characterization tests, find seams, cover and modify
