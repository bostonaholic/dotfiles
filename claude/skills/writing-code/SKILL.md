---
name: writing-code
description: Essential principles for writing clear, testable, maintainable code - separate decisions from effects, organize by concern, and design for change
tags:
  - code-organization
  - architecture
  - separation-of-concerns
  - testability
  - maintainability
  - first-principles
version: 2.0.0
---

# Writing Code: The One Essential Principle

## Overview

**Separate decisions from effects.**

This is THE fundamental principle for writing readable, maintainable, testable, and changeable code. Every quality attribute you care about—clarity, testability, flexibility, reliability—follows from this single organizing principle.

**Decisions** are pure logic: calculations, validations, filtering, transformations, business rules. They take data as input and return data as output, with no side effects.

**Effects** are world-changing operations: database access, API calls, file I/O, sending emails, logging. They fetch data, call decision functions, and execute operations based on results.

When you separate decisions from effects, you create strong boundaries that make your code:

- **Testable:** Pure decision logic tests instantly without mocks or
  infrastructure
- **Readable:** Clear separation makes code purpose obvious
- **Maintainable:** Change effects without touching decisions, and vice versa
- **Changeable:** Swap databases, APIs, or services without rewriting business
  logic
- **Reliable:** Deterministic logic reduces bugs; isolated effects contain
  failures

**MANDATORY: When implementing features, explicitly identify decisions vs effects. Don't mix them.**

This principle works across all languages and paradigms. It scales from individual functions to system architecture. It underlies every other practice—TDD, code review, refactoring—because it creates the boundaries that enable those practices to work.

**Historical note:** This skill builds on Gary Bernhardt's "Functional Core, Imperative Shell" pattern, generalizing it into a universal code organization principle applicable to all languages and contexts.

**Testing Advantage (Google Testing Blog, October 2025):**

> "Mixing database calls, network requests, and other external interactions
> directly with your core logic can lead to code that's difficult to test."

Separating decisions from effects solves this: pure decision logic = fast unit tests without mocks. This is the architectural foundation for the testing pyramid (70% unit, 20% integration, 10% e2e).

**For comprehensive testing strategy using this architecture, see the `software-testing-strategy` skill.**

## When to Use

Use this principle when:

- **Writing new features** - Structure code correctly from the start
- **Adding business logic** - Keep decision-making separate from I/O
- **Code has complex conditionals** - Extract pure logic from side effects
- **Testing is difficult** - Extensive mocking indicates mixed concerns
- **Side effects scattered throughout** - Database calls, API requests mixed
  with logic
- **Reusability needed** - Pure decisions compose and reuse naturally
- **Building web handlers** - Separate request processing from business logic
- **Processing events** - Separate event handling from decision logic
- **Writing CLI tools** - Separate argument parsing/output from core operations
- **Data pipelines** - Separate transformations from I/O operations

## When NOT to Use

Skip strict separation when:

- **Simple CRUD operations** - Direct database access is fine for simple
  reads/writes with no logic
- **Pure I/O scripts** - If there's no business logic, no separation needed
- **Prototypes or spikes** - Don't over-engineer exploratory code
- **Trivial calculations** - A single arithmetic operation doesn't need ceremony
- **Team unfamiliar with pattern** - Discuss and document first before applying
  everywhere

**Rule:** Apply separation when there's actual decision logic to isolate. Don't force the pattern where it adds no value.

## Understanding Decisions vs Effects

### Decisions (Pure Logic)

**Contains:** Business logic, calculations, validations, filtering, transformations, routing decisions, formatting, data structure manipulation.

**Characteristics:**

- Takes data as input (parameters)
- Returns data as output
- No database calls, API requests, file I/O, or external state
- Deterministic: same inputs always produce same outputs
- No side effects
- Easy to test without mocks
- Fast execution (no I/O latency)

**Examples:**

- Filter items meeting eligibility criteria
- Calculate pricing with discounts and taxes
- Validate business rules
- Transform data structures
- Format output data (not sending it)
- Determine routing based on conditions
- Generate reports (data, not delivery)

### Effects (Orchestration & I/O)

**Contains:** All side effects, orchestration, I/O operations, external system interactions.

**Characteristics:**

- Fetches data from databases, APIs, files, sensors
- Calls decision functions with fetched data
- Executes side effects based on decision results
- Thin and simple—mostly coordination
- Handles external system errors and retries
- Integration tested, not unit tested
- Slower execution (I/O latency)

**Examples:**

- Query databases
- Call REST APIs
- Read/write files
- Send emails or messages
- Publish events
- Update persistent state
- Log operational metrics
- Interact with hardware

### Decision Tree

When writing code, ask these questions:

```text
┌─────────────────────────────────────────────────┐
│ Does this code interact with the outside world? │
│ (database, file, API, clock, random, etc.)     │
└────────────┬────────────────────────────────────┘
             │
       ┌─────┴─────┐
       │           │
      YES         NO
       │           │
       │           └──> Does it transform data, calculate,
       │                validate, filter, or decide?
       │                      │
       │                ┌─────┴─────┐
       │                │           │
       │               YES         NO
       │                │           │
       │                │           └──> Consider if it's needed
       │                │
       │                └──> DECISION (Pure Function)
       │                     - Take data as parameters
       │                     - Return data
       │                     - No side effects
       │                     - Test with simple assertions
       │
       └──> EFFECT (Orchestration)
            - Fetch from external systems
            - Call decision functions
            - Execute side effects
            - Test with integration tests

┌──────────────────────────────────────┐
│ Does it mix both?                    │
│ → SPLIT IT: Extract decisions to     │
│   pure functions, keep effects thin  │
└──────────────────────────────────────┘
```

## The Principle in Practice

### How Decisions and Effects Interact

The relationship is simple: **effects orchestrate, decisions transform.**

Effects fetch data → pass to decisions → execute based on results.

```python
// DECISION: Pure calculation
function calculateOrderTotal(items, discountRate, taxRate):
  subtotal = sum(items, item => item.price * item.quantity)
  discount = subtotal * discountRate
  taxable = subtotal - discount
  tax = taxable * taxRate

  return {
    subtotal: subtotal,
    discount: discount,
    tax: tax,
    total: taxable + tax
  }

// EFFECT: Orchestration
function processOrder(orderId):
  // Fetch data (effect)
  order = database.findOrder(orderId)
  customer = database.findCustomer(order.customerId)

  // Make decision (pure)
  pricing = calculateOrderTotal(
    order.items,
    customer.discountRate,
    TAX_RATE
  )

  // Execute effects
  database.updateOrderTotal(orderId, pricing.total)
  paymentGateway.charge(order.paymentMethod, pricing.total)
  emailService.sendReceipt(customer.email, orderId, pricing)

  return pricing
```

**Notice:**

- Decision function has no dependencies—just data in, data out
- Can test `calculateOrderTotal` with simple assertions (no mocks)
- Can reuse pricing logic in quotes, invoices, reports
- Can swap database, payment gateway, email service without changing calculation
- Effect function is thin—mostly coordination

### Reusability Through Separation

Pure decision functions naturally compose and reuse:

**Scenario:** You implemented order processing. Now you need to add quote generation.

```python
// Reuse existing decision function
function generateQuote(customerId, items):
  customer = database.findCustomer(customerId)

  // Reuse the pricing decision!
  pricing = calculateOrderTotal(items, customer.discountRate, TAX_RATE)

  quote = {
    customerId: customerId,
    items: items,
    pricing: pricing,
    expiresAt: currentDate() + 30.days
  }

  database.saveQuote(quote)
  emailService.sendQuote(customer.email, quote)

  return quote
```

**Without separation:** You'd copy-paste the pricing logic or refactor tangled code.

**With separation:** Just call the existing decision function. No changes needed.

## Implementation Guide

### Step 1: Identify Decisions vs Effects

When writing a feature, classify each operation:

**Ask for each piece of code:**

- Does this calculate, filter, validate, transform, or decide? → **Decision**
- Does this read/write external systems? → **Effect**
- Does it do both? → **Split it**

**Operations that belong in decisions:**

- Business rules (pricing, eligibility, validation)
- Filtering or sorting logic
- Data transformations
- Conditional logic based on business requirements
- Report calculations
- Route determination

**Operations that belong in effects:**

- Database queries and updates
- API calls
- Email sending
- File operations
- Event publishing
- Operational logging
- Current time/random values

### Step 2: Write Pure Decision Functions First

Start by expressing business logic as pure functions:

```python
// DECISION: Filter eligible users
function usersNeedingReminder(users, cutoffDate):
  return users.filter(user =>
    user.expiresAt <= cutoffDate && !user.reminded
  )

// DECISION: Generate email content
function generateReminderEmails(users):
  return users.map(user => ({
    to: user.email,
    subject: "Account Expiry Reminder",
    body: `Your account expires on ${formatDate(user.expiresAt)}.`
  }))

// DECISION: Calculate discount
function calculateDiscount(subtotal, customerTier):
  discountRates = {
    "basic": 0.0,
    "premium": 0.1,
    "enterprise": 0.2
  }

  rate = discountRates[customerTier] || 0.0
  return subtotal * rate
```

**Key characteristics:**

- Parameters are data (not fetched inside function)
- Return values are data (not executed inside function)
- No external dependencies
- Deterministic
- Fast (no I/O)

### Step 3: Write Thin Effect Layer

Orchestrate decisions with a thin effect layer:

```python
// EFFECT: Send reminder emails
function sendReminderEmails():
  // Fetch data
  users = database.findUsersExpiringSoon()
  cutoffDate = currentDate() + 7.days

  // Call decisions
  usersToRemind = usersNeedingReminder(users, cutoffDate)
  emails = generateReminderEmails(usersToRemind)

  // Execute effects
  emailService.sendBatch(emails)
  database.markUsersAsReminded(usersToRemind.map(u => u.id))
  logger.info(`Sent ${emails.length} reminder emails`)

// EFFECT: Process payment
function processPayment(orderId):
  // Fetch
  order = database.findOrder(orderId)
  customer = database.findCustomer(order.customerId)

  // Decide
  subtotal = calculateOrderSubtotal(order.items)
  discount = calculateDiscount(subtotal, customer.tier)
  total = subtotal - discount

  // Execute
  paymentResult = paymentGateway.charge(order.paymentMethod, total)
  database.updateOrderStatus(orderId, "paid")
  emailService.sendReceipt(customer.email, orderId, total)

  return paymentResult
```

**Key characteristics:**

- Fetches data from external systems
- Delegates all logic to decision functions
- Executes side effects
- Thin—mostly coordination
- Handles external errors

### Step 4: Test Appropriately

#### Testing Strategy: Decisions vs Effects Architecture

Separating decisions from effects enables optimal test distribution per the testing pyramid:

##### 70% Unit Tests → Decision Functions

- Fast (<100ms), no I/O, no mocks needed
- Test business logic, calculations, filtering, transformations
- Deterministic (same input → same output)
- Can run thousands of tests in seconds

##### 20% Integration Tests → Effect Functions

- Slower (seconds), real dependencies
- Test that effects fetch correctly and call decisions appropriately
- Verify database queries, API contracts

##### 10% E2E Tests → Full Stack

- Slowest (minutes), full system
- Test critical user journeys only

**Testing Economics:** More logic in decisions = more fast unit tests = lower CI costs and faster feedback.

**For complete testing strategy (pyramid, patterns, anti-patterns), see `software-testing-strategy` skill. For test-first workflow on decision functions, see `tdd-enforcement` skill.**

---

#### Decision functions: Unit test extensively

```pseudocode
test "usersNeedingReminder filters correctly":
  users = [
    { email: "a@example.com", expiresAt: "2025-12-25", reminded: false },
    { email: "b@example.com", expiresAt: "2025-12-30", reminded: false },
    { email: "c@example.com", expiresAt: "2025-12-23", reminded: true }
  ]
  cutoff = "2025-12-26"

  result = usersNeedingReminder(users, cutoff)

  assert result.length == 1
  assert result[0].email == "a@example.com"
```

**No mocks needed.** Just pass data and assert on output. Tests run instantly.

#### Effect functions: Integration test lightly

```pseudocode
test "sendReminderEmails sends to eligible users":
  // Setup: Create test users in database
  createTestUser(email: "test@example.com", expiresAt: 5.daysFromNow)

  // Execute
  sendReminderEmails()

  // Verify
  assert lastEmailSentTo("test@example.com")
  assert lastEmailSubject.includes("Expiry Reminder")
```

Effect tests are slower and fewer. That's expected—the decision logic is where complexity lives and gets thoroughly tested.

## Universal Patterns Across Languages

The principle "separate decisions from effects" manifests differently in various paradigms, but the core idea remains the same.

### Object-Oriented (OOP)

**Pattern:** Domain model (decisions) + Service layer (effects)

```pseudocode
// DECISION: Domain model with pure methods
class Order:
  constructor(items, discountRate, taxRate):
    this.items = items
    this.discountRate = discountRate
    this.taxRate = taxRate

  calculateTotal():
    subtotal = sum(this.items, item => item.price * item.quantity)
    discount = subtotal * this.discountRate
    taxable = subtotal - discount
    tax = taxable * this.taxRate
    return taxable + tax

// EFFECT: Service layer orchestrates
class OrderService:
  processOrder(orderId):
    // Fetch
    orderData = this.repository.find(orderId)
    customerData = this.repository.findCustomer(orderData.customerId)

    // Decide
    order = new Order(
      orderData.items,
      customerData.discountRate,
      TAX_RATE
    )
    total = order.calculateTotal()

    // Execute
    this.repository.updateTotal(orderId, total)
    this.paymentGateway.charge(orderData.paymentMethod, total)
    this.emailService.sendReceipt(customerData.email, orderId, total)
```

### Functional Programming

**Pattern:** Pure functions + IO monad/action wrappers

```pseudocode
// DECISION: Pure functions
calculateTotal = (items, discountRate, taxRate) =>
  pipe(
    items,
    sumBy(item => item.price * item.quantity),
    applyDiscount(discountRate),
    applyTax(taxRate)
  )

// EFFECT: IO action that wraps pure functions
processOrder = (orderId) =>
  IO.do(
    orderData <- IO(database.findOrder(orderId)),
    customerData <- IO(database.findCustomer(orderData.customerId)),
    total <- IO.of(calculateTotal(
      orderData.items,
      customerData.discountRate,
      TAX_RATE
    )),
    _ <- IO(repository.updateTotal(orderId, total)),
    _ <- IO(paymentGateway.charge(orderData.paymentMethod, total)),
    _ <- IO(emailService.sendReceipt(customerData.email, orderId, total))
  )
```

### Procedural

**Pattern:** Data structures + Calculation functions + I/O functions

```pseudocode
// DECISION: Calculation functions
function calculateTotal(items, discountRate, taxRate):
  subtotal = 0
  for item in items:
    subtotal += item.price * item.quantity

  discount = subtotal * discountRate
  taxable = subtotal - discount
  tax = taxable * taxRate
  return taxable + tax

// EFFECT: I/O function
function processOrder(orderId):
  orderData = databaseFindOrder(orderId)
  customerData = databaseFindCustomer(orderData.customerId)

  total = calculateTotal(
    orderData.items,
    customerData.discountRate,
    TAX_RATE
  )

  databaseUpdateTotal(orderId, total)
  paymentGatewayCharge(orderData.paymentMethod, total)
  emailServiceSendReceipt(customerData.email, orderId, total)
```

**Common theme:** Regardless of paradigm, decisions are pure (data in, data out) and effects orchestrate I/O.

## Separation at Different Scales

The principle applies at every level of system design:

### Function Level

Individual functions are either decisions or effects.

```pseudocode
// DECISION function
function isEligibleForDiscount(accountAge, tier, failureCount):
  return accountAge >= 30 && tier == "basic" && failureCount == 0

// EFFECT function
function checkEligibility(userId):
  user = database.findUser(userId)
  return isEligibleForDiscount(user.accountAge, user.tier, user.failureCount)
```

### Module Level

Modules organize related decisions and effects.

```pseudocode
Module: OrderPricing (decisions)
  - calculateSubtotal(items)
  - applyDiscount(subtotal, rate)
  - calculateTax(amount, rate)
  - calculateTotal(items, discountRate, taxRate)

Module: OrderService (effects)
  - fetchOrder(orderId)
  - processOrder(orderId)
  - cancelOrder(orderId)
  - refundOrder(orderId)
```

### System Level

Services separate decision logic from integration adapters.

```pseudocode
┌─────────────────────────────────────┐
│     Business Logic Service          │
│     (Pure decisions)                 │
│  - Pricing calculations              │
│  - Eligibility rules                 │
│  - Validation logic                  │
│  - Report generation                 │
└─────────────────────────────────────┘
                  ▲
                  │ data
                  │
┌─────────────────┴───────────────────┐
│     Integration/Adapter Layer        │
│     (Effects)                        │
│  - Database repositories             │
│  - External API clients              │
│  - Message queue publishers          │
│  - Email service adapters            │
└─────────────────────────────────────┘
```

**Benefits at system scale:**

- Business logic service tests without infrastructure
- Swap databases without touching business logic
- Add new adapters without changing decisions
- Deploy business logic changes independently

## Anti-Patterns

### ❌ Mixing Decisions and Effects

**Bad:**

```pseudocode
function sendReminderEmails():
  users = database.findAll()

  for user in users:
    // Decision logic mixed with I/O
    if user.expiresAt <= (currentDate() + 7.days) && !user.reminded:
      emailService.send({
        to: user.email,
        subject: "Account Expiry",
        body: "Your account expires soon"
      })
      database.update(user.id, { reminded: true })
```

**Why bad:**

- Can't test filtering logic without database and email service
- Can't reuse reminder logic in other contexts
- Business rules buried in I/O operations
- Changes to email format require touching database code

**Good:**

```pseudocode
// DECISION: Pure filtering
function usersNeedingReminder(users, cutoffDate):
  return users.filter(u => u.expiresAt <= cutoffDate && !u.reminded)

// DECISION: Pure email generation
function generateReminderEmails(users):
  return users.map(u => ({
    to: u.email,
    subject: "Account Expiry",
    body: "Your account expires soon"
  }))

// EFFECT: Thin orchestration
function sendReminderEmails():
  users = database.findAll()
  toRemind = usersNeedingReminder(users, currentDate() + 7.days)
  emails = generateReminderEmails(toRemind)

  emailService.sendBatch(emails)
  database.markAsReminded(toRemind.map(u => u.id))
```

### ❌ Decisions That Read External State

**Bad:**

```pseudocode
// This is NOT pure - reads from database
function calculateDiscount(userId):
  user = database.findUser(userId)  // Side effect!
  return user.isPremium ? 0.2 : 0.1
```

**Why bad:**

- Not testable without database
- Not deterministic (database could change)
- Hidden dependency (not obvious from signature)
- Can't reuse in contexts where you already have user data

**Good:**

```pseudocode
// DECISION: Pure function
function calculateDiscountRate(isPremium):
  return isPremium ? 0.2 : 0.1

// EFFECT: Fetches and calls decision
function getDiscountForUser(userId):
  user = database.findUser(userId)
  return calculateDiscountRate(user.isPremium)
```

### ❌ Effects Containing Business Logic

**Bad:**

```pseudocode
function processPayment(orderId):
  order = database.findOrder(orderId)

  // Business logic in effect function!
  if order.customer.isPremium:
    discount = order.total * 0.2
  else:
    discount = 0

  finalTotal = order.total - discount
  paymentGateway.charge(order.paymentMethod, finalTotal)
```

**Why bad:**

- Business rules (discount calculation) in effect layer
- Can't test discount logic without database and payment gateway
- Can't reuse discount logic elsewhere
- Mixing concerns makes both harder to change

**Good:**

```pseudocode
// DECISION: Business logic
function calculateOrderTotal(items, discountRate):
  subtotal = sum(items, item => item.price * item.quantity)
  discount = subtotal * discountRate
  return subtotal - discount

// EFFECT: Thin orchestration
function processPayment(orderId):
  order = database.findOrder(orderId)
  discountRate = order.customer.isPremium ? 0.2 : 0
  total = calculateOrderTotal(order.items, discountRate)

  paymentGateway.charge(order.paymentMethod, total)
  database.updateOrderTotal(orderId, total)
```

### ❌ Over-Engineering Simple Operations

**Bad:**

```pseudocode
// No business logic, pointless separation
function getUserDecision(userData):
  return userData  // Does nothing

function getUserEffect(userId):
  data = database.findUser(userId)
  return getUserDecision(data)
```

**Why bad:**

- No business logic to separate
- Adds unnecessary indirection
- Decision function provides no value

**Good:**

```pseudocode
// Simple operations don't need separation
function getUser(userId):
  return database.findUser(userId)
```

**Rule:** Only separate when there's actual decision logic. Don't create ceremony for its own sake.

## Applying the Principle

### Example 1: User Eligibility Check

**Before (Mixed):**

```pseudocode
function checkUserEligibleForUpgrade(userId):
  user = database.findUser(userId)
  subscription = subscriptionService.getCurrent(userId)

  if user.accountAgeDays >= 30 &&
     subscription.tier == "basic" &&
     user.paymentFailures == 0:
    return true

  return false
```

**Problem:** Can't test eligibility logic without database and subscription
service.

**After (Separated):**

```pseudocode
// DECISION: Pure eligibility logic
function isEligibleForUpgrade(accountAgeDays, tier, paymentFailures):
  return accountAgeDays >= 30 &&
         tier == "basic" &&
         paymentFailures == 0

// EFFECT: Fetch and orchestrate
function checkUserEligibleForUpgrade(userId):
  user = database.findUser(userId)
  subscription = subscriptionService.getCurrent(userId)

  return isEligibleForUpgrade(
    user.accountAgeDays,
    subscription.tier,
    user.paymentFailures
  )
```

**Test (Easy):**

```pseudocode
test "eligibility requires 30 days, basic tier, no failures":
  assert isEligibleForUpgrade(30, "basic", 0) == true
  assert isEligibleForUpgrade(29, "basic", 0) == false
  assert isEligibleForUpgrade(30, "premium", 0) == false
  assert isEligibleForUpgrade(30, "basic", 1) == false
```

### Example 2: Report Generation

**Before (Mixed):**

```pseudocode
function generateSalesReport(startDate, endDate):
  sales = database.findSalesBetween(startDate, endDate)

  total = 0
  for sale in sales:
    total += sale.amount

  report = "Sales Report\n"
  report += "Total: " + total + "\n"

  fileSystem.write("report.txt", report)
  emailService.send(to: "manager@example.com", body: report)
```

**Problem:** Can't test calculation or formatting without database, file system, and email.

**After (Separated):**

```pseudocode
// DECISION: Calculate summary
function calculateSalesSummary(sales):
  return {
    total: sum(sales, s => s.amount),
    count: sales.length,
    average: sum(sales, s => s.amount) / sales.length
  }

// DECISION: Format report
function formatSalesReport(summary, startDate, endDate):
  return `
    Sales Report (${startDate} to ${endDate})
    Total: $${summary.total}
    Count: ${summary.count}
    Average: $${summary.average.toFixed(2)}
  `

// EFFECT: Orchestrate
function generateSalesReport(startDate, endDate):
  sales = database.findSalesBetween(startDate, endDate)
  summary = calculateSalesSummary(sales)
  report = formatSalesReport(summary, startDate, endDate)

  fileSystem.write("report.txt", report)
  emailService.send(to: "manager@example.com", body: report)
```

**Test (Easy):**

```pseudocode
test "calculates correct summary":
  sales = [
    { amount: 100 },
    { amount: 200 },
    { amount: 300 }
  ]

  summary = calculateSalesSummary(sales)

  assert summary.total == 600
  assert summary.average == 200.0
```

### Migration Strategy for Existing Code

When refactoring tangled code:

1. **Identify the tangled function** - Find code mixing logic and I/O
2. **Extract pure logic first** - Create decision functions with data parameters
3. **Test the decisions** - Ensure logic works in isolation
4. **Simplify the effect layer** - Remove logic, keep only I/O and orchestration
5. **Verify behavior unchanged** - Integration tests should still pass

**Don't refactor everything at once.** Do it incrementally, one function at a time. Let the pattern prove its value gradually.

## Integration with First Principles

This principle directly enables every first principle from CLAUDE.md:

### Clarity Over Cleverness

Separated concerns make code purpose obvious. When you see a decision function, you know it's pure logic. When you see an effect function, you know it orchestrates I/O.

**Application:** Code that separates decisions from effects documents itself.

### Strong Boundaries, Loose Coupling

The decision/effect boundary is THE fundamental boundary in code. Decisions depend on nothing but data. Effects depend on external systems. This creates loose coupling by design.

**Application:** Decisions and effects are the primary boundaries for all systems.

### Fail Fast, Fail Loud

Pure decisions fail deterministically with clear errors. Effects isolate I/O failures to the orchestration layer. No silent failures.

**Application:** Test decisions exhaustively for logical errors. Handle effect failures explicitly.

### Design for Change

When decisions are pure, you can swap effect implementations (databases, APIs, services) without rewriting any logic. The interface is just data.

**Application:** Effect implementations change frequently. Decision logic remains stable.

### Test at the Right Levels

Unit test decisions extensively (70% of tests). Integration test effects lightly (20% of tests). E2E test complete workflows (10% of tests).

**Application:** Testing pyramid naturally follows decision/effect separation.

### Simplicity Wins

Separation reduces moving parts. Decision functions are simple: data in, data out. Effect functions are simple: fetch, decide, execute.

**Application:** Both decisions and effects become simpler when separated.

### Operational Excellence is a Feature

Effect isolation enables observability. You can log, monitor, trace, and retry effects independently. Decision purity enables confidence in correctness.

**Application:** Instrument effect layers. Trust decision layers.

## Integration with Legendary Programmers

### Rich Hickey: Simple, Immutable Data, Pure Functions

**Principle:** Emphasize simple, immutable data structures and author code using pure functions (no side effects).

**Connection:** Separating decisions from effects IS Hickey's principle in action. Decision functions are pure by definition. They take immutable data, return immutable data, have no side effects.

**Application:** Every decision function embodies Hickey's philosophy.

### John Carmack: Direct Implementation, Measure Performance

**Principle:** Implement features directly, avoiding unnecessary abstraction. Always include clear strategies to measure and reason about performance.

**Connection:** Separated code makes implementation and performance obvious. Decision functions are straightforward calculations with predictable performance. Effects are where latency lives, making measurement clear.

**Application:** Profile effects (I/O latency). Optimize decisions (algorithmic complexity).

### Joe Armstrong: Isolate Failures

**Principle:** Isolate failures through rigorous error handling. Ensure faults/crashes in one module do not propagate to others.

**Connection:** Effect isolation IS failure isolation. Decision functions can't crash from database errors (they don't touch databases). Effect functions handle external failures explicitly.

**Application:** Decision functions fail on invalid data (fast, deterministic). Effect functions retry and handle I/O failures (isolated, explicit).

### Alan Kay: Message-Passing, Late-Binding Design

**Principle:** Favor message-passing, late-binding design (prefer to communicate between loosely coupled components and defer binding decisions when possible).

**Connection:** Decisions and effects communicate through data (messages). Decision functions don't know which database or API effects use (late binding). The interface is pure data.

**Application:** Effects send data to decisions. Decisions return data to effects. No tight coupling.

### Donald Knuth: Readable and Maintainable Above All

**Principle:** Code must be readable and maintainable above all else. Choose clarity before cleverness.

**Connection:** Separated code is maximally readable. Decision functions are easy to understand (no hidden dependencies). Effect functions are easy to understand (obvious I/O).

**Application:** Separation creates clarity. Mixed code creates confusion.

### Barbara Liskov: Respect Interface Contracts

**Principle:** Respect interface contracts. Ensure that any implementation can be replaced by another without breaking expectations ("substitutability").

**Connection:** Decision functions have perfect interface contracts (data only). Effect implementations are substitutable (mock database, real database, different database—decision doesn't care).

**Application:** Test decisions with simple data. Swap effect implementations freely.

### John Ousterhout: Deep Modules, Simple Interfaces

**Principle:** Fight complexity by designing deep modules with simple interfaces. Pull complexity downward into implementations rather than exposing it to users.

**Connection:** Decision functions are deep modules (complex logic) with simple interfaces (just data). Effect functions hide infrastructure complexity behind thin orchestration.

**Application:** Complex business logic in decision functions. Complex I/O in effect functions. Both have simple interfaces (data).

## Integration with Other Skills

### TDD-Enforcement

**Relationship:** TDD naturally creates separated code. When you write tests first, you're forced to make code testable. Testable code separates decisions from effects.

**Integration:**

- Write tests for decision functions first (unit tests, no mocks)
- Decision functions emerge naturally from test-first workflow
- Effect functions wrap decisions with I/O (integration tests)

**Application:** Use TDD to drive separation. If tests need extensive mocks, you're mixing concerns.

### Systematic-Code-Review

**Relationship:** Code review checks for mixed concerns. Primary review question: "Are decisions mixed with effects?"

**Integration:**

- Code smell: Testing requires extensive mocking → mixed concerns
- Review comment: "suggestion: Extract decision logic to pure function"
- Quality check: Are business rules in effect layer?

**Application:** In reviews, flag mixed concerns immediately. Suggest separation.

### Refactoring-to-Patterns

**Relationship:** Many refactorings extract decisions from effects.

**Integration:**

- Extract Method: Often reveals mixed concerns to separate
- Strategy Pattern: Effect layer, decision strategies
- Template Method: Effect orchestration, decision steps

**Application:** When refactoring tangled code, separate decisions first.

### Software-Testing-Strategy

**Relationship:** Testing strategy follows separation. Unit test decisions, integration test effects.

**Integration:**

- Unit tests (70%): For pure decision functions
- Integration tests (20%): For effect orchestration
- E2E tests (10%): For complete workflows
- Test doubles: Only needed in effect layer

**Application:** Testing pyramid naturally aligns with decision/effect separation.

## Common Questions and Misconceptions

### "Isn't this just MVC or layered architecture?"

**No, it's orthogonal.** MVC separates UI, logic, and data. Layered architecture separates presentation, business, and persistence. Decision/effect separation works WITHIN any of those layers. You can have decisions and effects in controllers, models, views, services, etc.

**Application:** Use decision/effect separation everywhere, regardless of architecture.

### "Doesn't this create performance overhead?"

**Negligible, often faster.** Pure decision functions are fast (no I/O). Thin effect functions are just coordination. The overhead of function calls is trivial compared to I/O latency. Often, separated code is faster because you can optimize decisions independently.

**Application:** Profile first. Separation rarely causes performance issues.

### "What about simple CRUD operations?"

**Direct access is fine.** If there's no business logic, no need to separate. Simple reads and writes don't need ceremony.

```pseudocode
// This is fine for simple CRUD
function getUser(userId):
  return database.findUser(userId)
```

Only separate when there's actual decision logic involved.

### "How pure is pure enough?"

**Pragmatic guidance:**

- Zero side effects in decisions (strict)
- Deterministic for same inputs (strict)
- No I/O in decisions (strict)
- Immutability preferred but not required (pragmatic)
- Small exceptions for logging/debugging (pragmatic)

**Application:** Be strict about I/O and side effects. Be pragmatic about immutability in non-functional languages.

### "Won't I have too many small functions?"

**Small functions are a feature, not a bug.** Small, focused functions are easier to understand, test, and reuse. If a function seems too small to separate, it probably is—don't force it. But most business logic benefits from separation.

**Application:** Prefer small functions. Combine only when there's no reuse or testing benefit.

### "What about testing—don't I still need integration tests?"

**Yes, but fewer.** You still need integration tests for effect functions. But most of your test effort goes to decision functions (fast, no mocks). This is the Testing Pyramid: many unit tests, fewer integration tests, few E2E tests.

**Application:** 70% unit tests (decisions), 20% integration tests (effects), 10% E2E tests (workflows).

## Quick Reference

### Decision Checklist

When writing a decision function, ensure:

- [ ] Takes data as parameters (not fetching internally)
- [ ] Returns data (not executing side effects)
- [ ] No database, API, file, network, or external state access
- [ ] Deterministic (same input → same output)
- [ ] No side effects
- [ ] Easy to test without mocks
- [ ] Fast execution (no I/O latency)

### Effect Checklist

When writing an effect function, ensure:

- [ ] Fetches data from external systems
- [ ] Calls decision functions with fetched data
- [ ] Executes side effects based on decision results
- [ ] Thin and simple (mostly coordination)
- [ ] Handles external system errors explicitly
- [ ] Integration tested (not unit tested)
- [ ] Delegates all logic to decision functions

### Red Flags

Watch for these warning signs:

- **Business logic in effects** → Move to decision functions
- **I/O operations in decisions** → Move to effect functions
- **Testing requires extensive mocks** → Likely mixed concerns
- **Can't reuse logic** → Probably tangled with I/O
- **Function does calculation AND I/O** → Split it
- **Hidden dependencies** → Pass data explicitly to decisions

### Troubleshooting Guide

| Problem | Diagnosis | Solution |
| ------- | --------- | -------- |
| Tests need many mocks | Mixed concerns | Extract pure functions |
| Can't reuse logic | Tangled with I/O | Separate decision/effect |
| Hard to understand code | Unclear boundaries | Identify decisions/effects |
| Slow tests | Testing I/O-heavy code | Test decisions separately |
| Changing DB breaks logic | Logic coupled to I/O | Move logic to decisions |

## Key Takeaways

1. **The one essential principle:** Separate decisions from effects—this underlies all code quality attributes (testability, readability, maintainability, changeability)

2. **Decisions are pure:** Take data as input, return data as output, no side effects or external dependencies—deterministic and fast

3. **Effects orchestrate:** Fetch data from external systems, call decision functions, execute operations based on results—thin and simple

4. **Testability follows separation:** Pure decision functions test instantly without mocks or infrastructure (unit tests), effects need integration tests

5. **Clarity follows separation:** When concerns are separated, code purpose becomes obvious—decisions decide, effects act

6. **Changeability follows separation:** Swap databases, APIs, or services without rewriting business logic—the interface is just data

7. **Apply at all scales:** Same principle works at function level, module level, and system architecture level

8. **Pragmatism over purity:** Simple operations need no separation; complex logic demands it—use judgment

9. **Strong boundaries enable quality:** Separation creates clear interfaces that enable all other quality attributes (reliability, performance, operability)

10. **Integration is natural:** TDD drives separation, code review checks for it, refactoring extracts it, testing strategy follows it

**Remember:** If your tests need extensive mocks, your code probably mixes decisions and effects. Separate them, and testing becomes trivial. This is THE organizing principle for quality code.

## Further Reading

### Original Sources

- Gary Bernhardt: "Boundaries" talk (original Functional Core, Imperative Shell
  presentation)
- ["Simplify Your Code: Functional Core, Imperative
  Shell"](https://testing.googleblog.com/2025/10/simplify-your-code-functional-core.html)
  (Google Testing Blog, October 2025)
- Rich Hickey: "Simple Made Easy" (simplicity and pure functions)
- Martin Fowler: "Refactoring" (Extract Method, separating concerns)

### Related Skills

For comprehensive guidance on leveraging the decisions-vs-effects architecture:

- **`software-testing-strategy`**: Complete testing strategy framework (pyramid,
  test patterns, anti-patterns). Shows
  how separating decisions from effects enables 70/20/10 distribution.
- **`tdd-enforcement`**: Test-first workflow. Separating decisions from effects
  makes TDD effortless by eliminating
  heavy mocking requirements.
- **`systematic-code-review`**: Use decisions-vs-effects principles when
  reviewing code for testability and separation
  of concerns.

**Integration:** Use writing-code (architecture) + software-testing-strategy (strategy) + tdd-enforcement (execution) for complete testing approach.
