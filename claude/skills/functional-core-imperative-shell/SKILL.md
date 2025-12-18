---
name: functional-core-imperative-shell
description: Use when writing or restructuring code - separates pure business
  logic (functional core) from side effects (imperative shell) to create testable,
  maintainable systems
---

# Functional Core, Imperative Shell

## Overview

**Separate what you calculate from what you do.**

Core principle: Business logic should be pure functions operating on data.
Side effects (I/O, database, network) belong in a thin shell that orchestrates
the core.

This architectural pattern, introduced by Gary Bernhardt, solves the
fundamental problem: "Is your code a tangled mess of business logic and
side effects?"

**MANDATORY: When implementing features, explicitly identify core vs shell.**
Don't mix them. The core should never touch external systems.

## When to Use

Use this skill when:

- **Writing new features** - Structure code correctly from the start
- **Adding business logic** - Keep decision-making separate from I/O
- **Code has complex conditionals** - Extract pure logic from side effects
- **Testing is difficult** - Mocking everything indicates mixed concerns
- **Side effects scattered throughout** - Database calls, API requests mixed
  with logic
- **Reusability needed** - Pure core can be reused in different contexts

## When NOT to Use

Skip this pattern when:

- **Simple CRUD operations** - Direct database access is fine for simple reads
- **Pure I/O scripts** - If there's no business logic, no core needed
- **Prototypes or spikes** - Don't over-engineer exploratory code
- **Team unfamiliar with pattern** - Discuss and document first

## The Pattern

### Functional Core

**Contains:** Pure business logic, calculations, filtering, transformations,
decision-making.

**Characteristics:**

- Takes data as input, returns data as output
- No database calls, no API requests, no file I/O, no external state
- Deterministic: same inputs always produce same outputs
- Easy to test without mocks
- No side effects

**Examples of core operations:**

- Filter users meeting expiry criteria
- Calculate pricing with discounts
- Validate business rules
- Transform data structures
- Generate output data (not sending it)

### Imperative Shell

**Contains:** All side effects, orchestration, I/O operations.

**Characteristics:**

- Fetches data from databases, APIs, files
- Calls functional core with fetched data
- Executes side effects based on core results (send emails, update database)
- Thin and simple - mostly coordination
- Difficult to unit test (but that's okay - core has the logic)

**Examples of shell operations:**

- Fetch users from database
- Send emails via SMTP
- Write to files
- Make HTTP requests
- Update database records

## Implementation Guide

### Step 1: Identify the Layers

When writing a feature, separate concerns:

**Ask for each operation:**

- Does this calculate, filter, or decide? → **Core**
- Does this read/write external systems? → **Shell**

**Red flags that belong in core, not shell:**

- Business rules (pricing, eligibility, validation)
- Filtering or sorting logic
- Data transformations
- Conditional logic based on business requirements

**Red flags that belong in shell, not core:**

- Database queries
- API calls
- Email sending
- File operations
- Logging (operational, not business logic)

### Step 2: Write the Functional Core First

Start with pure functions that express business logic:

```ruby
# Core: Pure functions
def users_needing_expiry_reminder(users, cutoff_date)
  users.select { |user| user.expires_at <= cutoff_date && !user.reminded }
end

def generate_expiry_emails(users)
  users.map do |user|
    {
      to: user.email,
      subject: "Account Expiry Reminder",
      body: "Your account expires on #{user.expires_at.strftime('%Y-%m-%d')}."
    }
  end
end

def calculate_pricing(items, discount_rate, tax_rate)
  subtotal = items.sum { |item| item.price * item.quantity }
  discount = subtotal * discount_rate
  taxable = subtotal - discount
  tax = taxable * tax_rate
  {
    subtotal: subtotal,
    discount: discount,
    tax: tax,
    total: taxable + tax
  }
end
```

**Notice:**

- No database, no I/O, no external dependencies
- Easy to test: pass data in, assert on data out
- Can run thousands of times instantly
- Deterministic: same inputs → same outputs

### Step 3: Write the Imperative Shell

Orchestrate the core with a thin shell:

```ruby
# Shell: Orchestrates side effects and calls core
def send_expiry_reminders
  # Fetch data (side effect)
  users = UserRepository.find_expiring_soon
  cutoff_date = Date.today + 7.days

  # Call core (pure)
  users_to_remind = users_needing_expiry_reminder(users, cutoff_date)
  emails = generate_expiry_emails(users_to_remind)

  # Execute side effects
  EmailService.send_bulk(emails)
  UserRepository.mark_as_reminded(users_to_remind.map(&:id))

  # Operational logging (side effect)
  Logger.info("Sent #{emails.count} expiry reminders")
end

def process_order(order_id)
  # Fetch (shell)
  order = OrderRepository.find(order_id)
  discount = DiscountService.get_discount_for_customer(order.customer_id)

  # Calculate (core)
  pricing = calculate_pricing(order.items, discount.rate, TAX_RATE)

  # Execute (shell)
  OrderRepository.update_total(order_id, pricing[:total])
  PaymentGateway.charge(order.payment_method, pricing[:total])
  EmailService.send_receipt(order.customer.email, order_id, pricing)

  pricing
end
```

**Notice:**

- Shell is thin - mostly fetching, calling core, executing
- All business logic delegated to core functions
- Shell can be swapped (different database, different email service)
- Core remains unchanged when infrastructure changes

### Step 4: Test Appropriately

#### Core Functions: Unit Test Extensively

```ruby
describe "users_needing_expiry_reminder" do
  it "includes users expiring before cutoff who haven't been reminded" do
    users = [
      User.new(email: "a@example.com", expires_at: 5.days.from_now, reminded: false),
      User.new(email: "b@example.com", expires_at: 10.days.from_now, reminded: false),
      User.new(email: "c@example.com", expires_at: 3.days.from_now, reminded: true)
    ]

    result = users_needing_expiry_reminder(users, 7.days.from_now)

    expect(result.map(&:email)).to eq(["a@example.com"])
  end
end
```

**No mocks needed!** Just pass data and assert.

#### Shell: Integration or E2E Tests

```ruby
# Integration test
it "sends expiry reminders to eligible users" do
  create_user(email: "test@example.com", expires_at: 5.days.from_now)

  send_expiry_reminders

  expect(last_email.to).to eq("test@example.com")
  expect(last_email.subject).to include("Expiry Reminder")
end
```

Shell tests are slower and fewer. That's fine - the logic is in the core.

## Anti-Patterns

### ❌ Mixing Core and Shell

**Bad:**

```ruby
def send_expiry_reminders
  # Everything mixed together
  users = UserRepository.find_all
  users.each do |user|
    # Logic mixed with I/O
    if user.expires_at <= Date.today + 7.days && !user.reminded
      EmailService.send(
        to: user.email,
        subject: "Account Expiry",
        body: "Your account expires soon"
      )
      UserRepository.update(user.id, reminded: true)
    end
  end
end
```

**Why bad:**

- Can't test logic without database and email service
- Can't reuse logic in different contexts
- Business rules buried in I/O operations
- Changes to email service require touching business logic

**Good:**

```ruby
# Core: Pure
def users_needing_reminder(users, cutoff_date)
  users.select { |user| user.expires_at <= cutoff_date && !user.reminded }
end

def generate_reminder_emails(users)
  users.map { |u| { to: u.email, subject: "Account Expiry", body: "..." } }
end

# Shell: Thin
def send_expiry_reminders
  users = UserRepository.find_all
  to_remind = users_needing_reminder(users, Date.today + 7.days)
  emails = generate_reminder_emails(to_remind)
  EmailService.send_bulk(emails)
  UserRepository.mark_reminded(to_remind.map(&:id))
end
```

### ❌ Core Functions That Read External State

**Bad:**

```ruby
# This is NOT pure - reads from database
def calculate_discount(user_id)
  user = UserRepository.find(user_id)  # Side effect!
  user.premium? ? 0.2 : 0.1
end
```

**Why bad:**

- Not testable without database
- Not deterministic (database could change)
- Hard to reason about (hidden dependency)

**Good:**

```ruby
# Core: Pure function
def calculate_discount_rate(is_premium)
  is_premium ? 0.2 : 0.1
end

# Shell: Fetches and calls core
def get_discount_for_user(user_id)
  user = UserRepository.find(user_id)
  calculate_discount_rate(user.premium?)
end
```

### ❌ Shell Containing Business Logic

**Bad:**

```ruby
# Shell should be thin, but this has logic
def process_payment(order_id)
  order = OrderRepository.find(order_id)

  # Business logic in shell!
  if order.customer.premium?
    discount = order.total * 0.2
  else
    discount = 0
  end

  final_total = order.total - discount
  PaymentGateway.charge(order.payment_method, final_total)
end
```

**Why bad:**

- Business rules (discount calculation) in shell
- Can't test discount logic without database and payment gateway
- Can't reuse discount logic elsewhere

**Good:**

```ruby
# Core: Business logic
def calculate_order_total(items, discount_rate)
  subtotal = items.sum { |item| item.price * item.quantity }
  discount = subtotal * discount_rate
  subtotal - discount
end

# Shell: Thin orchestration
def process_payment(order_id)
  order = OrderRepository.find(order_id)
  discount_rate = order.customer.premium? ? 0.2 : 0
  total = calculate_order_total(order.items, discount_rate)
  PaymentGateway.charge(order.payment_method, total)
end
```

### ❌ Over-Engineering Simple Operations

**Bad:**

```ruby
# Just fetching a user - no logic, no need for separation
def get_user_core(user_data)
  user_data  # This adds nothing
end

def get_user_shell(user_id)
  data = UserRepository.find(user_id)
  get_user_core(data)
end
```

**Why bad:**

- No business logic to separate
- Adds unnecessary indirection
- Core function does nothing

**Good:**

```ruby
# Simple operations don't need the pattern
def get_user(user_id)
  UserRepository.find(user_id)
end
```

**Rule:** Use FCIS when there's actual business logic. Don't force the pattern
where it doesn't fit.

## Reusability Benefits

The pattern makes logic reusable across contexts:

**Scenario:** Need to add a "send reminder email" feature after implementing
"send expiry email".

**With FCIS (Easy):**

```ruby
# Reuse existing core function
def send_reminder_emails
  users = UserRepository.find_all
  to_remind = users_needing_reminder(users, Date.today + 14.days)  # Reuse!
  emails = generate_reminder_emails(to_remind)  # New core function
  EmailService.send_bulk(emails)
end

# New pure function for reminder content
def generate_reminder_emails(users)
  users.map { |u| { to: u.email, subject: "Reminder", body: "..." } }
end
```

**Without FCIS (Hard):**

Would need to copy-paste filtering logic from old function or refactor
tangled code.

## Decision Tree

When writing a function, ask:

1. **Does it read/write external systems?**
   - Yes → Shell (or calls shell)
   - No → Continue to #2

2. **Does it make business decisions or transform data?**
   - Yes → Core (pure function)
   - No → Might be unnecessary

3. **Does it mix logic and I/O?**
   - Yes → Split it: extract logic to core, keep I/O in shell
   - No → You're good!

## Integration with First Principles

### Rich Hickey: Simple, Immutable Data, Pure Functions

FCIS directly applies Rich Hickey's principles:

- Core uses pure functions (no side effects)
- Data flows through core as immutable values
- Separation of data and behavior

**When reviewing code:** Ask "Is this function pure? Could it be?"

### John Carmack: Direct Implementation, Measure Performance

FCIS enables direct implementation:

- Core functions are straightforward calculations
- No hidden database calls or network requests
- Easy to profile and optimize (core is fast, shell is where time goes)

**When reviewing code:** Core should be obviously fast. Shell is where you
measure.

### Joe Armstrong: Isolate Failures

FCIS naturally isolates failures:

- Core can't crash from database errors (it doesn't touch database)
- Shell handles errors from external systems
- Failures contained to shell, core keeps working

**When reviewing code:** Check that shell handles external failures gracefully.

### Barbara Liskov: Interface Contracts

FCIS creates clear contracts:

- Core functions have explicit input/output contracts (just data)
- No hidden dependencies or side effects
- Easy to substitute implementations (different shell, same core)

**When reviewing code:** Core functions should have clear, data-only contracts.

## Common Rationalizations

| Excuse | Reality |
| ------ | ------- |
| "It's just one database call" | One becomes many. Keep core pure. |
| "Extracting logic is extra work" | Testing tangled code is more work. |
| "Shell is too thin to bother" | Thin shell is the goal. That's success. |
| "We don't have complex logic" | Even simple logic benefits from testability. |
| "Pattern is overkill for this" | FCIS isn't heavy - it's organization. |

## Real-World Examples

### Example 1: User Eligibility Check

**Before (Mixed):**

```ruby
def check_user_eligible_for_upgrade(user_id)
  user = UserRepository.find(user_id)
  subscription = SubscriptionService.get_current(user_id)

  if user.account_age_days >= 30 &&
     subscription.tier == "basic" &&
     user.payment_failures == 0
    return true
  end

  false
end
```

**After (FCIS):**

```ruby
# Core: Pure eligibility logic
def eligible_for_upgrade?(account_age_days, tier, payment_failures)
  account_age_days >= 30 &&
    tier == "basic" &&
    payment_failures == 0
end

# Shell: Fetch and orchestrate
def check_user_eligible_for_upgrade(user_id)
  user = UserRepository.find(user_id)
  subscription = SubscriptionService.get_current(user_id)

  eligible_for_upgrade?(
    user.account_age_days,
    subscription.tier,
    user.payment_failures
  )
end
```

**Test (Easy):**

```ruby
it "requires 30 days, basic tier, no failures" do
  expect(eligible_for_upgrade?(30, "basic", 0)).to be true
  expect(eligible_for_upgrade?(29, "basic", 0)).to be false
  expect(eligible_for_upgrade?(30, "premium", 0)).to be false
  expect(eligible_for_upgrade?(30, "basic", 1)).to be false
end
```

### Example 2: Report Generation

**Before (Mixed):**

```ruby
def generate_sales_report(start_date, end_date)
  sales = SalesRepository.find_between(start_date, end_date)

  total = 0
  sales.each { |s| total += s.amount }

  report = "Sales Report\n"
  report += "Total: #{total}\n"

  File.write("report.txt", report)
  EmailService.send(to: "manager@example.com", body: report)
end
```

**After (FCIS):**

```ruby
# Core: Calculate summary
def calculate_sales_summary(sales)
  {
    total: sales.sum { |s| s.amount },
    count: sales.count,
    average: sales.sum { |s| s.amount } / sales.count.to_f
  }
end

# Core: Format report
def format_sales_report(summary, start_date, end_date)
  <<~REPORT
    Sales Report (#{start_date} to #{end_date})
    Total: $#{summary[:total]}
    Count: #{summary[:count]}
    Average: $#{summary[:average].round(2)}
  REPORT
end

# Shell: Orchestrate
def generate_sales_report(start_date, end_date)
  sales = SalesRepository.find_between(start_date, end_date)
  summary = calculate_sales_summary(sales)
  report = format_sales_report(summary, start_date, end_date)

  File.write("report.txt", report)
  EmailService.send(to: "manager@example.com", body: report)
end
```

**Test (Easy):**

```ruby
it "calculates correct summary" do
  sales = [
    Sale.new(amount: 100),
    Sale.new(amount: 200),
    Sale.new(amount: 300)
  ]

  summary = calculate_sales_summary(sales)

  expect(summary[:total]).to eq(600)
  expect(summary[:average]).to eq(200.0)
end
```

## Migration Strategy

When refactoring existing code to FCIS:

1. **Identify the tangled function** - Mixed logic and I/O
2. **Extract pure logic first** - Create core functions
3. **Test the core** - Ensure logic works in isolation
4. **Simplify the shell** - Remove logic, keep only I/O and orchestration
5. **Verify behavior unchanged** - Integration tests should still pass

**Don't refactor everything at once.** Do it incrementally, one function at a
time.

## Quick Reference

**Core Checklist:**

- [ ] Takes data as parameters (not fetching)
- [ ] Returns data (not executing side effects)
- [ ] No database, API, file, or network calls
- [ ] Deterministic (same input → same output)
- [ ] Easy to test without mocks

**Shell Checklist:**

- [ ] Fetches data from external systems
- [ ] Calls core functions with fetched data
- [ ] Executes side effects based on core results
- [ ] Thin and simple (mostly coordination)
- [ ] Handles external system errors

**Red Flags:**

- Business logic in shell → Move to core
- I/O operations in core → Move to shell
- Testing requires mocks → Likely mixed concerns
- Can't reuse logic → Probably tangled with I/O

## Key Takeaways

1. **Separate calculation from action** - Core calculates, shell acts
2. **Core is pure, shell is not** - Never mix them
3. **Test core extensively, shell lightly** - Core has the logic
4. **Core is fast, shell is slow** - I/O takes time, logic doesn't
5. **Shell can change, core stays stable** - Swap databases, keep logic
6. **Reusability comes free** - Pure functions compose easily
7. **Start with core** - Write pure functions first, wrap in shell
8. **Don't over-engineer** - Only use when there's actual logic to separate

**Remember:** If your tests need mocks, your code probably mixes core and
shell. Separate them, and testing becomes trivial.

## Further Reading

- Gary Bernhardt's talk "Boundaries" (original FCIS presentation)
- "Functional Core, Imperative Shell" - Google Testing Blog
- Rich Hickey's talks on simplicity and pure functions
