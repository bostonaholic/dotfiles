---
name: simplifying-ruby-code
description: Use when reviewing Ruby code for over-engineering, unnecessary abstractions, or complex objects that could be simpler data structures and functions - applies Rich Hickey's simplicity principles to Ruby
---

# Simplifying Ruby Code

## Overview

**Simplifying Ruby code means preferring simple data structures (Hash, Array, Struct, Data) and pure functions over unnecessary classes and abstractions.**

Core principle: Ruby makes it easy to create classes, but most problems are better solved with simple data and functions. Over-engineering happens when we wrap simple data in custom classes without adding real value.

**MANDATORY: When reviewing Ruby code, explicitly identify whether each piece of code is a decision (pure logic) or an effect (I/O). Keep them separate.**

This skill applies Rich Hickey's simplicity philosophy, functional programming principles, and Ruby idioms to create maintainable, testable code.

## When to Use

Use this skill when you encounter:

- **Command objects** with single `call` method and no state
- **Value objects** that just wrap data without behavior
- **Service classes** that could be module functions
- **Custom classes** for simple data (coordinates, ranges, tuples)
- **Complex inheritance** where composition or modules would work
- **Missing Ruby protocols** (`to_h`, `to_a`, `to_json`, `each`)
- **Mixed concerns** - business logic tangled with I/O operations
- **Testing difficulties** - tests require extensive mocking

**When NOT to use:**

- Code is already simple and clear
- Custom class adds genuine value (validation, behavior, encapsulation)
- Domain model benefits from OOP (ActiveRecord models, domain entities)
- Team unfamiliar with functional approaches (educate first)

## Core Principles

### 1. Rich Hickey: Simple, Immutable Data & Pure Functions

**Philosophy:** Prefer simple, immutable data structures. Separate data from behavior. Use pure functions without side effects.

**In Ruby:**

```ruby
# ❌ Complex: Custom class for simple data
class UserFilter
  attr_accessor :role, :active, :created_after

  def initialize(role:, active:, created_after:)
    @role = role
    @active = active
    @created_after = created_after
  end
end

# ✅ Simple: Hash with keyword arguments
def filter_users(users, role:, active:, created_after:)
  users.select do |user|
    user.role == role &&
    user.active == active &&
    user.created_at > created_after
  end
end
```

### 2. Separate Decisions from Effects

**Philosophy:** Pure logic (decisions) should be separate from I/O operations (effects). This enables testability and reusability.

**In Ruby:**

```ruby
# ❌ Mixed: Logic tangled with I/O
class OrderProcessor
  def process(order_id)
    order = Database.find(order_id)  # Effect
    total = order.items.sum { |i| i.price * i.quantity }  # Decision
    PaymentGateway.charge(order.card, total)  # Effect
  end
end

# ✅ Separated: Pure decisions, thin effects
module OrderCalculations
  module_function

  def calculate_total(items)  # Decision: Pure function
    items.sum { |item| item.price * item.quantity }
  end
end

def process_order(order_id)  # Effect: Thin orchestration
  order = Database.find(order_id)
  total = OrderCalculations.calculate_total(order.items)
  PaymentGateway.charge(order.card, total)
end
```

### 3. Ruby Protocols and Idioms

**Philosophy:** Implement Ruby's duck-typing protocols so objects work with built-in methods and Enumerable.

**Core protocols:**

- `to_h` - Convert to Hash
- `to_a` - Convert to Array
- `to_json` - JSON serialization
- `to_s` - String representation
- `each` - Enable Enumerable
- `<=>` - Enable comparisons and sorting
- `hash` + `eql?` - Enable use in Sets and as Hash keys

```ruby
# ❌ Missing protocols: Can't use with standard Ruby methods
class Collection
  def initialize(items)
    @items = items
  end

  def size
    @items.size
  end
end

# ✅ Implements protocols: Works everywhere
class Collection
  include Enumerable

  def initialize(items)
    @items = items
  end

  def each(&block)
    @items.each(&block)
  end

  def to_a
    @items.dup
  end

  def to_h
    @items.to_h
  end
end

# Now works with: map, select, reject, find, etc.
collection.map { |item| item.upcase }
```

## Identifying Over-Engineering Patterns

### Pattern 1: Command Objects → Module Functions

**Smell:** Class with single `call` method, no instance state.

```ruby
# ❌ Over-engineered: Command object with no state
class UserCreator
  def initialize(params)
    @params = params
  end

  def call
    User.create(@params)
  end
end

UserCreator.new(params).call
```

**Refactoring:**

```ruby
# ✅ Simple: Module function (if needed at all)
module UserCreation
  module_function

  def create_user(params)
    User.create(params)
  end
end

UserCreation.create_user(params)

# ✅ Even simpler: Just call directly
User.create(params)
```

**When command object IS appropriate:**

- Has meaningful state (retries, configuration)
- Implements complex multi-step algorithm
- Needs to be queued/serialized (background jobs)

### Pattern 2: Value Objects → Struct or Data

**Smell:** Custom class that just holds data with no behavior or validation.

```ruby
# ❌ Over-engineered: Manual value object
class Point
  attr_reader :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end

  def ==(other)
    x == other.x && y == other.y
  end

  def hash
    [x, y].hash
  end

  alias eql? ==
end
```

**Refactoring:**

```ruby
# ✅ Simple: Struct (mutable if needed)
Point = Struct.new(:x, :y, keyword_init: true)

# ✅ Simple: Data (immutable, Ruby 3.2+)
Point = Data.define(:x, :y)

# ✅ Even simpler: Just use Hash
point = {x: 10, y: 20}
```

**Decision tree:**

- **No behavior needed?** → Use Hash
- **Need behavior but mutable okay?** → Use Struct
- **Need immutability?** → Use Data (Ruby 3.2+) or freeze Struct
- **Complex validation or methods?** → Custom class

### Pattern 3: Utility Classes → Modules

**Smell:** Class with only class methods (no instances ever created).

```ruby
# ❌ Over-engineered: Utility class
class DateFormatter
  def self.format_for_display(date)
    date.strftime("%B %d, %Y")
  end

  def self.format_for_api(date)
    date.iso8601
  end
end
```

**Refactoring:**

```ruby
# ✅ Simple: Module with module_function
module DateFormatter
  module_function

  def format_for_display(date)
    date.strftime("%B %d, %Y")
  end

  def format_for_api(date)
    date.iso8601
  end
end

# Now callable as:
DateFormatter.format_for_display(Date.today)
# or
include DateFormatter
format_for_display(Date.today)
```

### Pattern 4: Deep Inheritance → Composition

**Smell:** Inheritance hierarchy deeper than 2 levels for simple behavior sharing.

```ruby
# ❌ Over-engineered: Deep inheritance
class Animal
  def speak
    raise NotImplementedError
  end
end

class Mammal < Animal
  def warm_blooded?
    true
  end
end

class Dog < Mammal
  def speak
    "Woof"
  end
end
```

**Refactoring:**

```ruby
# ✅ Simple: Composition with modules
module WarmBlooded
  def warm_blooded?
    true
  end
end

class Dog
  include WarmBlooded

  def speak
    "Woof"
  end
end

# ✅ Or just use data + functions
Dog = Data.define(:name, :breed)

def dog_speak(dog)
  "Woof"
end
```

## Safe Refactoring Steps

When simplifying complex code, follow these steps:

### Step 1: Identify Decisions vs Effects

Mark each piece of code:

- **Decision:** Calculations, validations, filtering, transformations → Pure functions
- **Effect:** Database, API, files, email, logging → I/O operations
- **Mixed:** Contains both → Needs splitting

### Step 2: Extract Pure Functions First

Pull out decision logic into standalone functions that take data as parameters:

```ruby
# Before: Mixed
class OrderService
  def process(order_id)
    order = db.find(order_id)
    if order.items.sum { |i| i.price } > 100
      discount = 0.1
    else
      discount = 0
    end
    total = order.items.sum { |i| i.price } * (1 - discount)
    gateway.charge(total)
  end
end

# Step 1: Extract decision
module OrderPricing
  module_function

  def calculate_discount_rate(subtotal)
    subtotal > 100 ? 0.1 : 0
  end

  def calculate_total(items, discount_rate)
    subtotal = items.sum(&:price)
    subtotal * (1 - discount_rate)
  end
end

# Step 2: Thin effect layer
def process_order(order_id)
  order = db.find(order_id)
  subtotal = order.items.sum(&:price)
  discount_rate = OrderPricing.calculate_discount_rate(subtotal)
  total = OrderPricing.calculate_total(order.items, discount_rate)
  gateway.charge(total)
end
```

### Step 3: Test Pure Functions

Write simple tests for decision functions (no mocks needed):

```ruby
RSpec.describe OrderPricing do
  describe ".calculate_discount_rate" do
    it "returns 0.1 for orders over 100" do
      expect(OrderPricing.calculate_discount_rate(150)).to eq(0.1)
    end

    it "returns 0 for orders under 100" do
      expect(OrderPricing.calculate_discount_rate(50)).to eq(0)
    end
  end
end
```

### Step 4: Simplify Data Structures

Replace custom classes with Struct/Data/Hash where appropriate:

```ruby
# Before: Custom class
class CartItem
  attr_reader :product_id, :quantity, :price

  def initialize(product_id:, quantity:, price:)
    @product_id = product_id
    @quantity = quantity
    @price = price
  end

  def total
    quantity * price
  end
end

# After: Struct with method
CartItem = Struct.new(:product_id, :quantity, :price, keyword_init: true) do
  def total
    quantity * price
  end
end

# Or even simpler: Function operating on Hash
def cart_item_total(item)
  item[:quantity] * item[:price]
end
```

### Step 5: Remove Unnecessary Layers

Inline wrapper methods that provide no value:

```ruby
# Before: Unnecessary wrappers
class UserService
  def find_user(id)
    database.find_user(id)
  end

  def create_user(params)
    database.create_user(params)
  end
end

# After: Direct calls
database.find_user(id)
database.create_user(params)
```

## Ruby-Specific Patterns

### Pattern: Data vs Struct vs Hash

**Use Hash when:**

- Temporary, local data
- Varying keys (not fixed structure)
- Interfacing with JSON/external APIs

```ruby
config = {host: "localhost", port: 3000, ssl: true}
```

**Use Struct when:**

- Fixed attributes
- Need methods
- Mutable is acceptable
- Want positional and keyword access

```ruby
Person = Struct.new(:name, :age, keyword_init: true) do
  def adult?
    age >= 18
  end
end
```

**Use Data when:** (Ruby 3.2+)

- Fixed attributes
- Immutable by design
- Value equality semantics
- Replacing frozen Structs

```ruby
Person = Data.define(:name, :age) do
  def adult?
    age >= 18
  end
end

person = Person.new(name: "Alice", age: 30)
person.name = "Bob"  # NoMethodError - immutable!
```

**Use Custom Class when:**

- Complex validation
- Rich behavior
- Encapsulation important
- Implements domain concepts

### Pattern: Implementing Ruby Protocols

Always implement protocols for objects that need to interoperate with Ruby's standard library:

```ruby
class CustomCollection
  include Enumerable  # Gives you map, select, find, etc.

  def initialize(items)
    @items = items
  end

  # Protocol: Enumerable
  def each(&block)
    @items.each(&block)
  end

  # Protocol: Conversion
  def to_a
    @items.dup
  end

  def to_h
    @items.to_h if @items.respond_to?(:to_h)
  end

  def to_json(*args)
    @items.to_json(*args)
  end

  # Protocol: String representation
  def to_s
    "<CustomCollection: #{@items.size} items>"
  end

  def inspect
    "<CustomCollection #{@items.inspect}>"
  end

  # Protocol: Equality (if used as Hash key or in Set)
  def ==(other)
    other.is_a?(CustomCollection) && @items == other.instance_variable_get(:@items)
  end

  def hash
    @items.hash
  end

  alias eql? ==
end
```

## Quick Reference

### Over-Engineering Detection Checklist

- [ ] Command object with single method and no state → Module function
- [ ] Value object with no behavior → Struct/Data/Hash
- [ ] Class with only class methods → Module
- [ ] Service class wrapping single operation → Direct call or function
- [ ] Deep inheritance for behavior sharing → Modules/composition
- [ ] Missing `to_h`, `to_a`, `to_json` → Add protocols
- [ ] Business logic mixed with I/O → Separate decisions from effects
- [ ] Tests need heavy mocking → Logic and I/O not separated

### Simplification Decision Tree

```text
Is this a class?
├─ Yes: Does it have instance state?
│   ├─ No: Should be module function or removed
│   └─ Yes: Does it have behavior beyond accessors?
│       ├─ No: Use Struct/Data/Hash
│       └─ Yes: Is behavior complex?
│           ├─ No: Use Struct with methods
│           └─ Yes: Keep class but check protocols
└─ No: Is it already simple?
    ├─ Yes: Done!
    └─ No: What's the complexity?
```

### Refactoring Safety

| Before Changing               | Action                       | Why                                 |
|-------------------------------|------------------------------|-------------------------------------|
| Read existing tests           | Understand current behavior  | Tests document expected outcomes    |
| Identify decisions vs effects | Mark pure logic vs I/O       | Guides separation strategy          |
| Extract pure functions first  | Create new functions         | Establishes testable foundation     |
| Write tests for pure functions| Test without mocks           | Validates business logic            |
| Update effect layer           | Thin orchestration           | Completes separation                |
| Run full test suite           | Verify no regression         | Ensures behavior unchanged          |

## Common Mistakes

### ❌ Mistake 1: Over-Using Struct/Data

**Bad:**

```ruby
# Every little thing becomes a Struct
Config = Struct.new(:host)
port = Struct.new(:number)
setting = Struct.new(:value)
```

**Why bad:** Struct for single-value data is overkill. Just use the value directly.

**Good:**

```ruby
# Use Struct when multiple related attributes
Config = Struct.new(:host, :port, :ssl, keyword_init: true)
```

### ❌ Mistake 2: Forcing Functional Style Everywhere

**Bad:**

```ruby
# Functional zealotry - rejecting all OOP
class User < ApplicationRecord
end

# NO! Don't avoid ActiveRecord for "functional purity"
```

**Why bad:** Ruby is multi-paradigm. Use OOP where it fits (Rails models, domain objects).

**Good:**

```ruby
# OOP for domain models, functional for business logic
class User < ApplicationRecord
  # Domain model with rich associations
end

module UserAnalytics
  module_function

  # Pure function for calculations
  def calculate_engagement_score(user_events)
    user_events.count * 10
  end
end
```

### ❌ Mistake 3: Removing All Abstractions

**Bad:**

```ruby
# "Simplification" that loses clarity
def process(data)
  db.query("SELECT * FROM users WHERE status = 'active'").each do |user|
    if user["role"] == "admin"
      api.post("/admin/notify", {user_id: user["id"]})
    elsif user["role"] == "user"
      email.send(user["email"], "notification")
    end
  end
end
```

**Why bad:** No abstractions = hard to understand, test, and maintain. This is "simple" in lines of code but complex in understanding.

**Good:**

```ruby
# Right level of abstraction
def process_active_users
  active_users = find_active_users
  active_users.each do |user|
    notify_user(user)
  end
end

def find_active_users
  db.query("SELECT * FROM users WHERE status = 'active'")
end

def notify_user(user)
  case user["role"]
  when "admin" then api.post("/admin/notify", {user_id: user["id"]})
  when "user" then email.send(user["email"], "notification")
  end
end
```

## Integration with Other Skills

**This skill provides core Ruby simplification principles. For related topics:**

- **writing-code skill:** Architectural foundation (separating decisions from effects) - use when designing new features
- **refactoring-to-patterns skill:** Named patterns (Compose Method, Replace Conditional with Polymorphism) - use when applying specific refactorings
- **tdd-enforcement skill:** Test-first workflow - use when implementing refactorings with confidence
- **systematic-code-review skill:** Review framework - use this skill when reviewing Ruby code for simplicity

**When to use each:**

- **During review:** Use this skill (simplifying-ruby-code) to identify over-engineering
- **During implementation:** Use writing-code skill for architecture, TDD for workflow
- **During refactoring:** Use refactoring-to-patterns for specific transformations

## Key Takeaways

1. **Prefer simple data structures** - Hash, Array, Struct, Data over custom classes for simple data
2. **Separate decisions from effects** - Pure logic separate from I/O enables testability
3. **Implement Ruby protocols** - `to_h`, `to_a`, `each` make objects work with standard methods
4. **Command objects → module functions** - Classes with single call method rarely justified
5. **Value objects → Struct/Data** - Manual implementation only when behavior is complex
6. **Test pure functions easily** - No mocks needed for pure decision functions
7. **Use right tool for job** - OOP for domain models, functional for calculations
8. **Don't over-simplify** - Some abstractions improve clarity and maintainability

**Remember:** Simplicity ≠ fewer lines. Simplicity = easier to understand, test, and change. Apply Rich Hickey's philosophy: prefer simple, immutable data and pure functions. Separate decisions from effects. Implement Ruby protocols for interoperability.
