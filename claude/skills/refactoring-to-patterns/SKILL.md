---
name: refactoring-to-patterns
description: Use when refactoring code with duplication, complex conditionals, or long methods - applies proven design patterns from Martin Fowler's "Refactoring to Patterns" to improve code structure systematically
---

# Refactoring to Patterns

## Overview

**Refactoring to patterns means improving code design by applying proven solutions from Martin Fowler's "Refactoring to Patterns".**

Core principle: Patterns solve recurring design problems. Know the patterns, recognize the code smells, apply the right transformation.

**MANDATORY: When refactoring, always name the Fowler pattern explicitly.** Don't just say "extract methods" - say "I'm applying Compose Method pattern." Pattern names create shared vocabulary and make intent clear.

## When to Use

Use this skill when you encounter:

- **Long methods** doing multiple things → Compose Method
- **Switch/if chains on type** → Replace Conditional with Polymorphism
- **Duplicate code in subclasses** → Form Template Method
- **Null checks scattered everywhere** → Introduce Null Object
- **Type codes determining behavior** → Replace Type Code with State/Strategy
- **Object decorated with conditionals** → Move Embellishment to Decorator

**When NOT to use:**
- Code is already clear and simple
- Pattern would add complexity without benefit
- Team unfamiliar with the pattern (document first)
- You're guessing at future requirements

## Quick Reference: Pattern Selection

| Code Smell | Pattern | Key Indicator |
|------------|---------|---------------|
| Long method with multiple responsibilities | Compose Method | Can't describe method in one sentence |
| Switch/if-else on object type | Replace Conditional with Polymorphism | Each case handles different type |
| Duplicate structure, varying details | Form Template Method | Same steps, different implementations |
| Repeated null checks | Introduce Null Object | `if (obj != null)` appears frequently |
| Type field drives behavior | Replace Type Code with State/Strategy | Behavior changes based on `type` field |
| Multiple conditional decorations | Move Embellishment to Decorator | Stacked if statements adding features |

## Core Patterns

### 1. Compose Method

**Problem:** Long method doing multiple things at different levels of abstraction.

**Solution:** Break into small, well-named methods at same abstraction level.

**Before:**
```ruby
def process_order(order)
  # Validation (low-level details)
  raise "Order must have items" if order.items.nil? || order.items.empty?

  # Calculate total (arithmetic details)
  subtotal = 0
  order.items.each do |item|
    subtotal += item.price * item.quantity
  end

  # Send email (formatting details)
  body = "Dear #{order.customer.name}..."
  send_email(order.customer.email, "Confirmation", body)

  # Update inventory (database details)
  order.items.each do |item|
    product = get_product(item.product_id)
    product.stock -= item.quantity
    save_product(product)
  end
end
```

**After:**
```ruby
def process_order(order)
  validate_order(order)
  pricing = calculate_pricing(order)
  send_order_confirmation(order, pricing)
  update_inventory(order.items)
  log_order_analytics(order, pricing[:total])
end

# Each method now operates at single level of abstraction
```

**When to use:** Method has multiple sections with comments explaining each section.

**Fowler's rule:** Each method does one thing at one level of abstraction.

### 2. Replace Conditional with Polymorphism

**Problem:** Switch statement or if-else chain based on object type.

**Solution:** Create subclasses/implementations for each type, move logic into them.

**Before:**
```ruby
def process_payment(payment)
  case payment.type
  when 'credit_card'
    charge_credit_card(payment.card_number, payment.amount)
  when 'paypal'
    charge_paypal(payment.email, payment.amount)
  when 'crypto'
    charge_crypto(payment.wallet, payment.amount)
  end
end
```

**After:**
```ruby
# Define polymorphic interface through duck typing
class CreditCardPayment
  def process(payment)
    charge_credit_card(payment.card_number, payment.amount)
  end
end

class PaypalPayment
  def process(payment)
    charge_paypal(payment.email, payment.amount)
  end
end

class CryptoPayment
  def process(payment)
    charge_crypto(payment.wallet, payment.amount)
  end
end

# Processor becomes simple
def process_payment(method, payment)
  method.process(payment)
end
```

**When to use:** Adding new types requires modifying the switch. Each case contains distinct logic.

**Benefits:** Open/Closed Principle, easier testing, isolated changes.

### 3. Form Template Method

**Problem:** Subclasses have duplicate code with small variations.

**Solution:** Pull common code to base class, extract varying parts as abstract methods.

**Before:**
```ruby
class PdfReport
  def generate(data)
    output = generate_header(data)  # Same
    output += '<PDF>...</PDF>'      # Different
    output += generate_footer(data) # Same
    output
  end
end

class HtmlReport
  def generate(data)
    output = generate_header(data)  # Same (duplicated!)
    output += '<html>...</html>'    # Different
    output += generate_footer(data) # Same (duplicated!)
    output
  end
end
```

**After:**
```ruby
class Report
  def generate(data)
    output = generate_header(data)
    output += generate_body(data)  # Hook method
    output += generate_footer(data)
    output
  end

  private

  def generate_header(data)
    # Common header logic
  end

  def generate_footer(data)
    # Common footer logic
  end

  def generate_body(data)
    raise NotImplementedError, 'Subclasses must implement generate_body'
  end
end

class PdfReport < Report
  private

  def generate_body(data)
    '<PDF>...</PDF>'
  end
end
```

**When to use:** Multiple classes share algorithm structure but differ in specific steps.

**Key insight:** Define the skeleton in base class, let subclasses fill in the details.

### 4. Introduce Null Object

**Problem:** Scattered null checks throughout codebase.

**Solution:** Create a null object that provides default behavior.

**Before:**
```ruby
customer = find_customer(id)
discount = customer ? customer.discount : 0
name = customer ? customer.name : "Guest"
email = customer ? customer.email : "noreply@example.com"
```

**After:**
```ruby
class NullCustomer
  def discount
    0
  end

  def name
    "Guest"
  end

  def email
    "noreply@example.com"
  end
end

def find_customer(id)
  customer = database.find(id)
  customer || NullCustomer.new
end

# Client code becomes simple
customer = find_customer(id)
discount = customer.discount  # No null check needed
```

**When to use:** Null checks for same object appear in multiple places. Default behavior is clear.

**Warning:** Don't use if null means "error" - use for "absent but valid" cases.

### 5. Replace Type Code with State/Strategy

**Problem:** Object has type field that determines behavior. Adding types requires changes everywhere.

**Solution:** Replace type field with polymorphic object.

**Before:**
```ruby
class Employee
  def initialize(type)
    @type = type
  end

  def calculate_bonus(base)
    case @type
    when 'engineer' then base * 1.5
    when 'manager' then base * 2.0
    when 'sales' then base * 1.8
    end
  end

  def responsibilities
    case @type
    when 'engineer' then ['code', 'review']
    when 'manager' then ['plan', 'coordinate']
    when 'sales' then ['sell', 'support']
    end
  end
end
```

**After:**
```ruby
# Duck-typed interface through common method names
class Engineer
  def calculate_bonus(base)
    base * 1.5
  end

  def responsibilities
    ['code', 'review']
  end
end

class Manager
  def calculate_bonus(base)
    base * 2.0
  end

  def responsibilities
    ['plan', 'coordinate']
  end
end

class Employee
  def initialize(employee_type)
    @type = employee_type
  end

  def calculate_bonus(base)
    @type.calculate_bonus(base)
  end

  def responsibilities
    @type.responsibilities
  end
end
```

**When to use:** Type field used in multiple switch statements. Behavior varies by type.

**Use State when:** Object changes type over time. Use Strategy when: Type is fixed.

### 6. Move Embellishment to Decorator

**Problem:** Base functionality gets wrapped in conditional "enhancements".

**Solution:** Use Decorator pattern for optional features.

**Before:**
```ruby
def render_text(text, bold: false, italic: false, underline: false)
  result = text
  result = "<b>#{result}</b>" if bold
  result = "<i>#{result}</i>" if italic
  result = "<u>#{result}</u>" if underline
  result
end
```

**After:**
```ruby
# Base renderer
class PlainText
  def render(text)
    text
  end
end

# Decorators
class BoldDecorator
  def initialize(wrapped)
    @wrapped = wrapped
  end

  def render(text)
    "<b>#{@wrapped.render(text)}</b>"
  end
end

class ItalicDecorator
  def initialize(wrapped)
    @wrapped = wrapped
  end

  def render(text)
    "<i>#{@wrapped.render(text)}</i>"
  end
end

# Compose decorators
renderer = BoldDecorator.new(ItalicDecorator.new(PlainText.new))
```

**When to use:** Multiple optional features that can be combined. Each feature is independent.

## Recognition Workflow

When refactoring, follow this process:

1. **Identify the smell:**
   - Long method → Compose Method
   - Type-based switching → Replace Conditional with Polymorphism
   - Duplicate algorithm → Form Template Method
   - Null checks everywhere → Introduce Null Object
   - Type field + switches → Replace Type Code
   - Stacked conditionals → Move Embellishment to Decorator

2. **Confirm the pattern fits:**
   - Will it reduce complexity?
   - Is the pattern well-understood by the team?
   - Does it solve a real problem (not hypothetical)?

3. **Apply incrementally:**
   - Extract smaller pieces first
   - Run tests after each step
   - Don't refactor and change behavior simultaneously

4. **Verify improvement:**
   - Is the code easier to read?
   - Are responsibilities clearer?
   - Is it easier to extend?

## Common Mistakes

### ❌ Premature Pattern Application

**Bad:**
```ruby
# One simple calculation, but "let's use Strategy!"
class StandardDiscount
  def calculate(amount)
    0
  end
end

class PremiumDiscount
  def calculate(amount)
    amount * 0.1
  end
end

# Overkill for: discount = is_premium ? amount * 0.1 : 0
```

**Why bad:** Pattern adds complexity without solving actual problem. No switches to replace, no extension needed.

**Rule:** Three strikes - don't abstract until you see the pattern repeated 3+ times.

### ❌ Wrong Pattern for the Problem

**Bad:** Using Strategy when Template Method fits better (or vice versa).

**How to choose:**
- **Template Method:** Common algorithm structure, varying steps → inheritance-based
- **Strategy:** Swappable algorithms, runtime selection → composition-based

### ❌ Not Naming Extracted Methods Well

**Bad:**
```ruby
def process_order(order)
  do_step1(order)
  do_step2(order)
  do_step3(order)
end
```

**Good:**
```ruby
def process_order(order)
  validate_order(order)
  calculate_pricing(order)
  send_confirmation(order)
end
```

**Rule:** Method names should reveal intent. Reader shouldn't need to look at implementation.

### ❌ Extracting Single-Use Methods

**Bad:**
```ruby
def process_order(order)
  validate_order(order)
  calculate_total(order)  # Only called here
end

def calculate_total(order)
  order.items.sum { |item| item.price }
end
```

**When it's okay:** If extraction improves clarity or testability. Not okay if it just adds indirection.

### ❌ Mixing Levels of Abstraction

**Bad:**
```ruby
def process_order(order)
  validate_order(order)

  # Low-level detail suddenly appears
  total = 0
  order.items.each do |item|
    total += item.price * item.quantity
  end

  send_confirmation(order)
end
```

**Good:** Keep all operations at same level:
```ruby
def process_order(order)
  validate_order(order)
  total = calculate_total(order)  # Same level now
  send_confirmation(order)
end
```

## Balancing Pattern Use

**Apply patterns when:**
- Code smell is clear and recurring
- Pattern simplifies the code
- Team understands the pattern
- Extension point is needed now (not "might be someday")

**Avoid patterns when:**
- Code is already simple
- Pattern adds more complexity than it removes
- You're guessing at future requirements
- Team would need training to maintain it

**John Ousterhout's test:** Does the pattern create a deep module (simple interface, complex implementation hidden) or does it expose complexity?

**Rich Hickey's test:** Does the pattern reduce incidental complexity or add it?

## Real-World Impact

**Before:** 300-line method handling order processing. Changes to email formatting require understanding entire flow.

**After (Compose Method):** Six 20-30 line methods. Email changes isolated to `sendOrderConfirmation()`.

**Before:** Payment processor with 4-case switch. Adding cryptocurrency required changes to 8 locations.

**After (Replace Conditional with Polymorphism):** Adding new payment type = one new class implementing `PaymentMethod`. Zero changes to processor.

**Before:** Three report generators with 80% duplicate code.

**After (Form Template Method):** One base class with common code, three tiny subclasses for variations. DRY achieved.

## Common Rationalizations (And Why They're Wrong)

| Excuse | Reality |
|--------|---------|
| "I'll just extract methods without naming the pattern" | Unnamed patterns = lost knowledge. Future maintainers won't recognize the design. Always name it. |
| "The pattern is obvious, no need to mention it" | If it's obvious to you now, it won't be obvious in 6 months. Name it. |
| "Naming patterns feels pedantic" | Pattern names are professional vocabulary. Using them is clarity, not pedantry. |
| "I applied the pattern, that's what matters" | Communication matters as much as code. Name the pattern so others understand your intent. |
| "Time pressure - just fix it quickly" | Naming the pattern takes 5 seconds and prevents future confusion. Always worth it. |
| "Pattern name might be wrong, safer to avoid" | Check the Quick Reference table. If still unsure, use the closest match and note uncertainty. |

**Rule: Every refactoring should mention the pattern by name. No exceptions.**

## Key Takeaways

1. **Name patterns explicitly** - "I'm applying Compose Method" is clearer than "extracting some methods"
2. **Recognize smells systematically** - each smell maps to specific patterns
3. **Don't over-engineer** - patterns solve problems, not vice versa
4. **Test the pattern fits** - will it simplify or complicate?
5. **Extract incrementally** - small steps with tests between

Martin Fowler's patterns are battle-tested solutions. Use them deliberately, not dogmatically.
