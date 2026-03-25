# SOLID Principles — Detailed Patterns

In-depth guidance for each principle with before/after examples (Ruby),
composition strategies, and common misconceptions. The explanations apply
to any object-oriented language.

---

## Single Responsibility Principle (SRP)

### How to Identify Responsibilities

A "responsibility" is a reason to change. Ask: "Who would request a change
to this code?" If the answer includes multiple stakeholders (e.g., the
billing team AND the reporting team), the module has multiple
responsibilities.

**Heuristic:** Count the number of unrelated concepts a class touches. If
it touches persistence AND formatting AND validation, those are three
responsibilities.

### Decomposition Strategies

**Extract class:** Move each responsibility into its own class.

```ruby
# Before: UserService handles auth, profile updates, and email
class UserService
  def authenticate(credentials)
    # ...
  end

  def update_profile(user, data)
    # ...
  end

  def send_welcome_email(user)
    # ...
  end
end

# After: Three focused classes
class Authenticator
  def authenticate(credentials)
    # ...
  end
end

class ProfileManager
  def update(user, data)
    # ...
  end
end

class WelcomeMailer
  def send(user)
    # ...
  end
end
```

**Facade pattern:** If callers need a single entry point, create a thin
coordinator that delegates to focused classes. The coordinator itself has
one responsibility: orchestration.

```ruby
class UserOnboarding
  def initialize(authenticator:, profile_manager:, mailer:)
    @authenticator = authenticator
    @profile_manager = profile_manager
    @mailer = mailer
  end

  def onboard(credentials, profile_data)
    user = @authenticator.authenticate(credentials)
    @profile_manager.update(user, profile_data)
    @mailer.send(user)
  end
end
```

### SRP Misconception: "One Method Per Class"

SRP does not mean a class should have only one method. It means a class
should have one *reason to change*. A class with ten methods that all serve
the same stakeholder and change together is perfectly cohesive.

---

## Open/Closed Principle (OCP)

### Extension Mechanisms

| Mechanism | When to Use |
|-----------|-------------|
| Polymorphism (duck typing) | New variants of a behavior |
| Strategy pattern | Swappable algorithms |
| Registry pattern | Discovered-at-runtime extensions |
| Closures/lambdas | Parameterized behavior |
| Decorator/wrapper | Adding behavior around existing code |

### Registry Pattern Example

```ruby
# A registry maps keys to handlers. Adding a new handler
# requires no changes to existing code.
class ExporterRegistry
  def initialize
    @handlers = {}
  end

  def register(format, handler)
    @handlers[format] = handler
  end

  def export(format, data)
    handler = @handlers.fetch(format) { raise "Unknown format: #{format}" }
    handler.export(data)
  end
end

class CsvExporter
  def export(data)
    data.map { |row| row.join(",") }.join("\n")
  end
end

class JsonExporter
  def export(data)
    data.to_json
  end
end

registry = ExporterRegistry.new
registry.register(:csv, CsvExporter.new)
registry.register(:json, JsonExporter.new)
# Adding PDF requires zero changes to existing handlers:
registry.register(:pdf, PdfExporter.new)
```

### Duck Typing Example

```ruby
# Before: case statement that must be edited for each new type
class NotificationService
  def notify(user, message, channel)
    case channel
    when :email then send_email(user, message)
    when :sms   then send_sms(user, message)
    when :slack  then send_slack(user, message)
    end
  end
end

# After: each channel is its own object, open for extension
class EmailNotifier
  def notify(user, message)
    # send email
  end
end

class SmsNotifier
  def notify(user, message)
    # send SMS
  end
end

# Adding a new channel requires no changes to existing code:
class SlackNotifier
  def notify(user, message)
    # send Slack message
  end
end

class NotificationService
  def initialize(notifier)
    @notifier = notifier
  end

  def notify(user, message)
    @notifier.notify(user, message)
  end
end
```

### OCP Misconception: "Never Modify Existing Code"

OCP does not mean existing code is frozen forever. It means *design for
extension* so that the common case (adding a new variant) does not require
modifying tested code. Bug fixes, performance improvements, and interface
evolution are legitimate reasons to modify existing code.

---

## Liskov Substitution Principle (LSP)

### The Contract Model

Every type has a contract: preconditions (what it requires), postconditions
(what it guarantees), and invariants (what is always true). A subtype must:

- Accept the same or weaker preconditions
- Guarantee the same or stronger postconditions
- Preserve all invariants

### Classic Violations

**Square/Rectangle problem:**

```ruby
class Rectangle
  attr_accessor :width, :height

  def area
    width * height
  end
end

class Square < Rectangle
  def width=(value)
    @width = value
    @height = value
  end

  def height=(value)
    @width = value
    @height = value
  end
end

def test_area(rect)
  rect.width = 5
  rect.height = 4
  raise "Broken!" unless rect.area == 20 # Fails for Square
end
```

**Fix:** Square is not a behavioral subtype of Rectangle. Model them as
siblings sharing a module or common interface.

```ruby
module Shape
  def area
    raise NotImplementedError
  end
end

class Rectangle
  include Shape

  def initialize(width, height)
    @width = width
    @height = height
  end

  def area
    @width * @height
  end
end

class Square
  include Shape

  def initialize(side)
    @side = side
  end

  def area
    @side * @side
  end
end
```

**Throwing on inherited methods:**

```ruby
# Before: violates LSP — callers expect save to work
class Repository
  def save(entity)
    # persist to database
  end
end

class ReadOnlyRepository < Repository
  def save(_entity)
    raise NotImplementedError, "Read-only repository" # Violates LSP
  end
end

# After: split into focused modules
module Readable
  def find(id)
    raise NotImplementedError
  end
end

module Writable
  def save(entity)
    raise NotImplementedError
  end
end

class FullRepository
  include Readable
  include Writable

  def find(id) = # ...
  def save(entity) = # ...
end

class ReadOnlyRepository
  include Readable

  def find(id) = # ...
  # No save method — callers never expect it
end
```

### LSP Misconception: "Inheritance is Bad"

LSP does not prohibit inheritance. It constrains it: only inherit when the
subtype can fully honor the parent's contract. When in doubt, prefer
composition — it avoids the contract obligation entirely.

---

## Interface Segregation Principle (ISP)

### Detecting Fat Interfaces

Signs an interface is too broad:

- Implementors leave methods as no-ops or raise `NotImplementedError`
- Consumers call only one or two methods on a large object
- A change to one method forces retesting of unrelated consumers
- Test doubles implement many unused methods

### Splitting Strategies

**Role-based modules:** Define modules by the role the consumer plays.

```ruby
# Before: one large class with many capabilities
class DataStore
  def read(key) = # ...
  def write(key, value) = # ...
  def delete(key) = # ...
  def list_keys(prefix) = # ...
  def subscribe(callback) = # ...
  def export_to_csv(path) = # ...
end

# After: role-based modules
module Readable
  def read(key)
    raise NotImplementedError
  end
end

module Writable
  def write(key, value)
    raise NotImplementedError
  end

  def delete(key)
    raise NotImplementedError
  end
end

module Listable
  def list_keys(prefix)
    raise NotImplementedError
  end
end

# A full store implements all modules
class RedisStore
  include Readable
  include Writable
  include Listable

  def read(key) = # ...
  def write(key, value) = # ...
  def delete(key) = # ...
  def list_keys(prefix) = # ...
end

# A consumer that only reads depends only on Readable
class CacheWarmer
  def initialize(store) # expects Readable
    @store = store
  end

  def warm(keys)
    keys.each { |k| @store.read(k) }
  end
end
```

**Parameter narrowing:** Instead of passing a full object, pass only what
the function needs.

```ruby
# Before: method takes full User but only needs email
def send_reminder(user)
  Mailer.deliver(user.email, "Reminder")
end

# After: method takes only what it needs
def send_reminder(email)
  Mailer.deliver(email, "Reminder")
end
```

**Using duck typing:** In dynamically typed languages, ISP is often
achieved through duck typing. Instead of formal interfaces, depend on the
specific methods needed.

```ruby
# Any object that responds to #call works here
class Pipeline
  def initialize(steps)
    @steps = steps
  end

  def run(input)
    @steps.reduce(input) { |data, step| step.call(data) }
  end
end

# Lambdas, procs, and objects with #call all work
pipeline = Pipeline.new([
  ->(data) { data.strip },
  ->(data) { data.downcase },
  Sanitizer.new # responds to #call
])
```

### ISP Misconception: "Every Method Gets Its Own Module"

ISP does not mean one-method modules everywhere. It means group methods
by *which consumers use them together*. If three methods always appear
together from the consumer's perspective, they belong in one module.

---

## Dependency Inversion Principle (DIP)

### The Composition Root

All concrete wiring should happen in one place: the composition root. This
is typically the application entry point or a configuration initializer.

```ruby
# config/initializers/dependencies.rb (composition root)
db = PostgresDatabase.new(ENV.fetch("DATABASE_URL"))
cache = RedisCache.new(ENV.fetch("REDIS_URL"))
repo = UserRepository.new(db: db, cache: cache)
service = UserService.new(repo: repo)

# High-level modules never reference low-level modules directly.
# Only the composition root knows the concrete types.
```

### Injection Patterns

| Pattern | Mechanism | Best For |
|---------|-----------|----------|
| Constructor injection | Pass dependencies at creation | Most cases — clear, testable |
| Method injection | Pass dependency per call | When dependency varies by call |
| Default with override | Optional parameter with default | Convenience + testability |
| Higher-order functions | Pass function as dependency | Functional codebases |

```ruby
# Constructor injection (preferred)
class OrderService
  def initialize(repo:, notifier:)
    @repo = repo
    @notifier = notifier
  end

  def place(order)
    @repo.save(order)
    @notifier.notify(order.customer, "Order placed")
  end
end

# Default with override — convenient in production, swappable in tests
class ReportGenerator
  def initialize(formatter: HtmlFormatter.new)
    @formatter = formatter
  end

  def generate(data)
    @formatter.format(data)
  end
end

# Test with a stub
generator = ReportGenerator.new(formatter: FakeFormatter.new)
```

### Testing Benefit

DIP makes testing dramatically simpler. Instead of mocking a database
driver deep inside a module, inject a test double at the boundary:

```ruby
# Production: inject real database
service = OrderService.new(
  repo: PostgresOrderRepo.new,
  notifier: EmailNotifier.new
)

# Test: inject in-memory stubs
service = OrderService.new(
  repo: InMemoryOrderRepo.new,
  notifier: NullNotifier.new
)
```

No monkey-patching. No complex mock frameworks. Dependencies are explicit
and swappable.

### DIP Misconception: "Everything Needs an Abstraction"

DIP applies at *architectural boundaries* — where high-level policy meets
low-level detail (database, network, file system, external API). Internal
helpers within a single module do not need abstraction layers. Over-applying
DIP creates indirection without value.

---

## Principle Interactions

The five principles reinforce each other:

| Interaction | How |
|-------------|-----|
| SRP + OCP | Single-responsibility classes are easier to extend without modification |
| OCP + LSP | Extension through polymorphism only works if subtypes are substitutable |
| LSP + ISP | Narrow interfaces make it easier to honor contracts |
| ISP + DIP | Small interfaces are easier to abstract and inject |
| DIP + SRP | Injected dependencies make responsibilities explicit |

### Warning Signs of Over-Application

- **Abstraction explosion:** More modules/classes than concrete implementations
- **Indirection maze:** Following a call requires jumping through 5+ files
- **Configuration ceremony:** Wiring takes longer than the logic it connects
- **Test fragility:** Tests break from refactoring internal structure, not
  behavior changes

When these appear, step back and simplify. SOLID is a means to
maintainability, not an end in itself.

---

## Decision Framework

When deciding whether to apply a SOLID refactor:

```text
1. Is there a concrete pain? (frequent changes, hard to test, bugs from coupling)
   No  → Leave it alone
   Yes → Continue

2. Which principle addresses the pain?
   Identify the specific violation

3. Will the refactor make the code simpler to understand?
   No  → The cure is worse than the disease. Skip it.
   Yes → Continue

4. Is this code likely to change again?
   No  → Note the violation, defer the fix
   Yes → Apply the refactor

5. Apply incrementally. Test between each step.
```
