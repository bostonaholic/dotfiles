---
name: writing-code
description: Essential principle for writing clear, testable, maintainable code - separate decisions from effects
tags:
  - code-organization
  - architecture
  - testability
version: 3.0.0
---

# Writing Code: Separate Decisions from Effects

## The Principle

**Decisions** = pure logic: calculations, validations, filtering, transformations. Data in, data out, no side effects.

**Effects** = I/O operations: database, API calls, files, email. Fetch data, call decisions, execute results.

**MANDATORY:** When implementing features, explicitly identify decisions vs effects. Don't mix them.

## Why This Matters

| Quality | How Separation Enables It |
|---------|--------------------------|
| Testable | Pure decisions test instantly without mocks |
| Readable | Clear separation makes purpose obvious |
| Maintainable | Change effects without touching decisions |
| Changeable | Swap databases/APIs without rewriting logic |
| Reliable | Deterministic logic reduces bugs |

## Decision vs Effect Identification

**Decisions (pure functions):**
- Calculations, business rules
- Filtering, sorting, transformations
- Validations, formatting
- Route determination

**Effects (orchestration):**
- Database queries/updates
- API calls, file I/O
- Email, messages, events
- Logging, current time, random values

**If code does both → Split it.**

## The Pattern

```python
# DECISION: Pure calculation
def calculate_total(items, discount_rate, tax_rate):
    subtotal = sum(item.price * item.quantity for item in items)
    discount = subtotal * discount_rate
    tax = (subtotal - discount) * tax_rate
    return subtotal - discount + tax

# EFFECT: Thin orchestration
def process_order(order_id):
    order = db.find_order(order_id)              # Fetch
    customer = db.find_customer(order.customer_id)
    total = calculate_total(                      # Decide
        order.items, customer.discount_rate, TAX_RATE
    )
    db.update_total(order_id, total)             # Execute
    payment.charge(order.payment_method, total)
    email.send_receipt(customer.email, total)
```

**Notice:** Decision has no dependencies—just data in, data out. Testable without mocks. Reusable across contexts.

## Testing Strategy

**70% Unit tests → Decision functions**
- Fast (<100ms), no I/O, no mocks
- Test all edge cases here

**20% Integration tests → Effect functions**
- Verify effects fetch correctly and call decisions
- Real dependencies

**10% E2E → Full workflows**

## Anti-Patterns

### ❌ Mixing Decisions and Effects

```python
# Bad: Logic tangled with I/O
def send_reminders():
    for user in db.find_all():
        if user.expires_at <= today() + 7.days and not user.reminded:
            email.send(user.email, "Reminder")
            db.update(user.id, reminded=True)
```

```python
# Good: Separated
def users_needing_reminder(users, cutoff):
    return [u for u in users if u.expires_at <= cutoff and not u.reminded]

def send_reminders():
    users = db.find_all()
    to_remind = users_needing_reminder(users, today() + 7.days)
    email.send_batch(generate_emails(to_remind))
    db.mark_reminded([u.id for u in to_remind])
```

### ❌ Decisions That Read External State

```python
# Bad: Hidden dependency
def calculate_discount(user_id):
    user = db.find(user_id)  # Side effect!
    return 0.2 if user.is_premium else 0.1

# Good: Pure function
def calculate_discount(is_premium):
    return 0.2 if is_premium else 0.1
```

### ❌ Effects Containing Business Logic

```python
# Bad: Business rules in effect layer
def process_payment(order_id):
    order = db.find(order_id)
    if order.customer.is_premium:  # Logic here!
        discount = order.total * 0.2
    else:
        discount = 0
    payment.charge(order.total - discount)

# Good: Logic extracted
def calculate_order_total(items, discount_rate):
    subtotal = sum(i.price for i in items)
    return subtotal * (1 - discount_rate)

def process_payment(order_id):
    order = db.find(order_id)
    rate = 0.2 if order.customer.is_premium else 0
    total = calculate_order_total(order.items, rate)
    payment.charge(total)
```

## Paradigm Variants

**OOP:** Domain model (decisions) + Service layer (effects)

**Functional:** Pure functions + IO monad/action wrappers

**Procedural:** Calculation functions + I/O functions

Core pattern is identical: decisions are pure, effects orchestrate.

## Scale

**Function level:** Individual functions are either decisions or effects.

**Module level:** Group related decisions together, effects together.

**System level:** Business logic service (pure) + Integration adapters (effects).

## Checklists

### Decision Function
- [ ] Takes data as parameters
- [ ] Returns data
- [ ] No database/API/file access
- [ ] Deterministic (same input → same output)
- [ ] No side effects
- [ ] Easy to test without mocks

### Effect Function
- [ ] Fetches from external systems
- [ ] Calls decision functions with fetched data
- [ ] Executes side effects based on results
- [ ] Thin—mostly coordination
- [ ] Handles external errors

### Red Flags
- Business logic in effects → Move to decisions
- I/O in decisions → Move to effects
- Tests need extensive mocks → Mixed concerns
- Can't reuse logic → Tangled with I/O

## Key Takeaways

1. **Separate decisions from effects** - The one essential organizing principle
2. **Decisions are pure** - Data in, data out, no side effects
3. **Effects orchestrate** - Fetch, decide, execute
4. **Testability follows** - Pure functions test instantly without mocks
5. **Apply at all scales** - Functions, modules, systems
6. **If tests need mocks, concerns are mixed** - Separate them
