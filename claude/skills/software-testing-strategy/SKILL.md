---
name: software-testing-strategy
description: Strategic testing framework: testing pyramid, test design patterns, anti-patterns. Complements tdd-enforcement (tactical) with comprehensive strategy.
---

# Software Testing Strategy

## Purpose

Strategic guidance for designing effective test suites: what to test, where to test it, how to structure it. Use `tdd-enforcement` for tactical test-first workflow.

## Iron Laws

1. **Fast Feedback** - Unit tests in milliseconds, integration in seconds, full e2e under 30 minutes
2. **Deterministic** - No random inputs, no real clocks, no network timing. Every run identical.
3. **Test Behavior, Not Implementation** - Verify what code does, not how it does it
4. **Test at Appropriate Level** - Don't use e2e for business logic, don't mock everything in unit tests
5. **Tests Are Production Code** - Same quality standards: readability, maintainability, simplicity
6. **Risk-Based Coverage** - Focus on critical paths and edge cases, not percentage targets

## The Testing Pyramid

| Level | % | Speed | Scope | Cost |
|-------|---|-------|-------|------|
| Unit | 70% | <100ms | Single function/class | $ |
| Integration | 20% | Seconds | Multiple components | $$ |
| E2E | 10% | Minutes | Full user journey | $$$ |

**Unit (70%):** Business logic, algorithms, validations. No I/O. Hundreds/thousands of tests.

**Integration (20%):** Component interactions, database queries, API contracts. Real dependencies.

**E2E (10%):** Critical user journeys only. Top 20% of journeys = 80% of business value.

## Architecture for Testability

**Problem:** Logic tangled with I/O requires heavy mocking and slow tests.

**Solution:** Separate decisions from effects (see `writing-code` skill for full pattern).

```python
# Decision (pure, fast unit test)
def users_needing_reminder(users, cutoff_date):
    return [u for u in users if u.expires_at <= cutoff_date and not u.reminded]

# Effect (thin orchestration, integration test)
def send_reminders():
    users = db.find_all()
    to_remind = users_needing_reminder(users, today() + 7.days)
    email.send_batch(generate_emails(to_remind))
```

**Result:** More logic in pure functions = more fast unit tests = testing pyramid economics.

## Test Design Patterns

### AAA Pattern (Arrange-Act-Assert)

```python
def test_withdrawing_more_than_balance_raises_error():
    account = Account(balance=100)          # Arrange
    with pytest.raises(InsufficientFundsError):
        account.withdraw(150)               # Act + Assert
```

### Test Builder Pattern

```typescript
const admin = new UserBuilder().withRoles('admin').build();
const minor = new UserBuilder().withAge(17).build();
```

Use for complex object creation. Provides defaults, fluent interface, reusability.

### Test Doubles

**Rule: Never mock what you can use for real.** Use real implementations whenever possible—real databases, real queues, real collaborators. Mocks hide bugs and couple tests to implementation details. Reserve test doubles only for things you truly cannot use in tests (third-party APIs, payment gateways, external services with no sandbox).

| Type | When to Use | Example |
|------|-------------|---------|
| Real | Default choice—always prefer | Real database, real queue, real collaborator objects |
| Fake | When real thing is too slow or unavailable | In-memory database for CI, local S3-compatible store |
| Stub | External service with no test mode | Third-party API returns canned response |
| Mock | Verify interaction with unreachable external | Assert payment gateway was called with correct amount |

**If you're mocking your own code, your design needs work.** Separate decisions from effects (see `writing-code` skill) so logic is testable without doubles.

### Parameterized Tests

```python
@pytest.mark.parametrize("input,expected", [
    ("Hello World", "hello-world"),
    ("HELLO WORLD", "hello-world"),
    ("Hello, World!", "hello-world"),
])
def test_slugify(input, expected):
    assert slugify(input) == expected
```

## Anti-Patterns

| Anti-Pattern | Symptom | Fix |
|--------------|---------|-----|
| Flaky Tests | Pass/fail randomly | Control time, isolate tests, use fakes |
| Slow Tests | Unit tests take seconds | Remove I/O, test pure logic |
| Test Interdependencies | Fail in different order | Isolate tests, complete setup per test |
| Over-Mocking | Breaks when refactoring | Never mock what you can use for real |
| Logic in Tests | Tests have if/loops | Simplify, use parameterized tests |
| Unclear Names | Can't tell what broke | `test_<scenario>_<expected_behavior>` |

## Test Level Selection

| What to Test | Unit | Integration | E2E |
|--------------|------|-------------|-----|
| Business logic | ✓ | | |
| Calculations | ✓ | | |
| Database queries | | ✓ | |
| API contracts | | ✓ | |
| Critical user journey | | | ✓ |
| Edge cases | ✓ | | |

## Legacy Code Testing

### Characterization Tests

When you don't know what code should do, capture what it currently does:

```python
def test_legacy_calculator_current_behavior():
    calc = LegacyCalculator()
    assert calc.calculate(5, "A") == 47.50  # Document current behavior
```

### Finding Seams

Add injection points for tests:

```ruby
# Before: Hard to test
def process(order)
  gateway = PaymentGateway.new(ENV['KEY'])
  gateway.charge(order.amount)
end

# After: Testable via injection
def process(order, gateway: PaymentGateway.new(ENV['KEY']))
  gateway.charge(order.amount)
end
```

## Test Quality Checklist

- [ ] Names describe behavior, not implementation
- [ ] Tests are isolated (no shared state)
- [ ] Setup is clear and minimal
- [ ] Assertions are simple and focused
- [ ] Critical paths have multiple test cases
- [ ] Edge cases covered
- [ ] Error paths tested
- [ ] No complex logic in tests
- [ ] Tests run fast at appropriate level

## Key Takeaways

1. **Testing pyramid 70/20/10** - Unit base, integration middle, e2e top
2. **Test behavior, not implementation** - Tests survive refactoring
3. **Risk-based coverage** - Focus on critical paths, not percentages
4. **Separate decisions from effects** - Enables fast unit tests (see writing-code skill)
5. **Never mock what you can use for real** - Use real implementations; reserve doubles for truly external systems
6. **Zero tolerance for flaky tests** - Fix immediately or delete
