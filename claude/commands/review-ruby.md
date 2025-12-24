---
name: review-ruby
description: Audit Ruby codebase for over-engineering and unnecessary abstractions with actionable refactoring steps
---

# Ruby Code Review & Refactoring Guide

Analyze Ruby code for unnecessary custom objects, class bloat, and insufficient usage of Ruby's generic data structures. Provides specific refactoring steps with before/after code examples for libraries, gems, CLI tools, and Ruby applications.

## Additional Context

$ARGUMENTS

**Instructions for using additional context:**

- If **file paths** are provided (e.g., `lib/parser.rb`), analyze only those files
- If **directory paths** are provided (e.g., `lib/services/`), analyze all Ruby files in that directory
- If a **branch name** is provided, compare current branch against it to review only changed files
- If **no arguments** are provided, perform full codebase audit of `lib/` directory
- If a **focus area** is specified (e.g., "command objects", "data structures"), prioritize that aspect

## Analysis Process

### STEP 1: Determine Scope

```bash
# If no arguments provided, scan lib directory
# If branch name provided, get changed files
git diff <branch>...HEAD --name-only '*.rb'

# If directory provided, list Ruby files
find <directory> -name '*.rb'
```

### STEP 2: Analyze Anti-Patterns

Scan for these Ruby-specific issues:

#### A. Unnecessary Class Hierarchies

- [ ] Deep inheritance trees (>2 levels) for simple behavior
- [ ] Abstract base classes with single implementations
- [ ] Classes that could be modules or simple functions
- [ ] Template method pattern where blocks would suffice

#### B. Over-Engineered Data Objects

- [ ] Custom classes for simple data pairs (coordinates, ranges, tuples)
- [ ] Value objects without behavior, validation, or transformation
- [ ] Objects that just wrap primitives without adding value
- [ ] Missing Ruby protocol implementations (`each`, `to_h`, `to_a`, `to_json`, `to_s`)
- [ ] Data objects that should be Struct, Data, or Hash

#### C. Stateful Objects Where Functions Would Work

- [ ] Classes with only class methods (should be modules)
- [ ] Single-method classes (`call`, `run`, `execute`, `perform`)
- [ ] Command objects without state
- [ ] Builder patterns for simple object construction
- [ ] Stateful service objects that could be pure functions

#### D. Complexity That Could Be Simplified

- [ ] Custom DSLs that reinvent Ruby syntax
- [ ] Wrapper classes around standard library
- [ ] Reimplementing Enumerable or Array/Hash methods
- [ ] Complex metaprogramming where simple code would work
- [ ] Unnecessary dependencies (pulling in gems for simple tasks)

### STEP 3: Provide Specific Refactorings

For each issue found, provide:

1. **File and location** with line numbers
2. **Problem** - Why it violates simplicity principles
3. **Before code** - Current implementation
4. **After code** - Refactored version
5. **Migration steps** - How to safely refactor
6. **Test considerations** - What tests need updating

## Output Format

Structure findings as:

---

## Ruby Code Review: [Scope Description]

### 🔴 Critical Issues (Fix First)

#### 1. [Issue Type] - [File:Line]

**Problem:** [Description of why this is over-engineered]

**Current Code:**

```ruby
# Current implementation
```

**Refactored Code:**

```ruby
# Simplified version
```

**Migration Steps:**

1. [Step 1 with code examples]
2. [Step 2 with code examples]
3. [Step 3 with code examples]

**Tests to Update:**

- [Test file and what needs changing]

**Impact:** [Performance, maintainability, or complexity improvements]

---

### 🟡 Improvements (Consider for Refactoring)

[Same format as Critical Issues]

---

### ✅ Good Patterns Found

List examples of:

- Proper use of Structs, Data, Hashes, or simple classes
- Well-implemented Ruby protocols
- Functional approaches with modules
- Effective use of blocks and Enumerable
- Appropriate abstractions with clear value

Include file locations so developers can reference these patterns.

---

### 📊 Summary

**Files Analyzed:** [count]
**Critical Issues:** [count]
**Improvements:** [count]
**Good Patterns:** [count]

**Recommended Refactoring Order:**

1. [First priority with reasoning]
2. [Second priority with reasoning]
3. [Third priority with reasoning]

**Estimated Complexity:** [Simple/Moderate/Complex] based on:

- Number of call sites affected
- Test coverage requirements
- Inter-dependencies

---

## Refactoring Guidelines

Follow these principles when implementing suggestions:

### 1. Rich Hickey's Simplicity

- Prefer simple, immutable data structures (Hash, Array, Struct, Data)
- Separate data from behavior
- Use pure functions without side effects
- Avoid complecting concerns
- Choose simple over easy

### 2. Ruby Idioms

- Implement Ruby protocols (`each`, `to_h`, `to_a`, `to_json`, `to_s`, `<=>`)
- Use modules for mixins and namespacing
- Prefer composition over inheritance
- Use blocks instead of callbacks or templates
- Leverage Enumerable methods
- Use keyword arguments for clarity
- Follow the principle of least surprise

### 3. Functional Programming in Ruby

- Prefer pure functions (same input → same output, no side effects)
- Use immutable data where possible (freeze constants, use Data)
- Separate data transformation from I/O
- Use method chaining for data pipelines
- Avoid mutable class/instance variables when functions work

### 4. Safe Refactoring

- Make changes incrementally
- Run tests after each change
- Use Rubocop or StandardRB for consistency
- Keep both old and new code paths temporarily if needed
- Add deprecation warnings for gradual migrations

## Examples of Common Refactorings

### Example 1: Command Object → Simple Function

**Before:**

```ruby
# lib/commands/file_processor.rb
class FileProcessor
  def initialize(filename)
    @filename = filename
  end

  def call
    File.read(@filename).upcase
  end
end

# Usage
FileProcessor.new("data.txt").call
```

**After:**

```ruby
# lib/file_processor.rb
module FileProcessor
  module_function

  def process(filename)
    File.read(filename).upcase
  end
end

# Usage
FileProcessor.process("data.txt")
```

### Example 2: Custom Data Class → Data

**Before:**

```ruby
# lib/models/point.rb
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
end
```

**After:**

```ruby
# lib/models/point.rb
Point = Data.define(:x, :y)

# Or use Struct if mutability is needed
Point = Struct.new(:x, :y, keyword_init: true)

# Or just use a Hash for simple cases
{x: 10, y: 20}
```

### Example 3: Deep Inheritance → Composition

**Before:**

```ruby
# lib/parsers/base_parser.rb
class BaseParser
  def parse(input)
    validate(input)
    transform(process(input))
  end

  def validate(input)
    raise NotImplementedError
  end

  def process(input)
    raise NotImplementedError
  end

  def transform(data)
    data
  end
end

class JsonParser < BaseParser
  def validate(input)
    # validation logic
  end

  def process(input)
    JSON.parse(input)
  end
end
```

**After:**

```ruby
# lib/parsers/json_parser.rb
module JsonParser
  module_function

  def parse(input)
    validate(input)
    transform(process(input))
  end

  def validate(input)
    # validation logic
  end

  def process(input)
    JSON.parse(input)
  end

  def transform(data)
    data
  end
end
```

### Example 4: Builder Pattern → Keyword Arguments

**Before:**

```ruby
# lib/builders/query_builder.rb
class QueryBuilder
  def initialize
    @conditions = []
    @limit = nil
  end

  def where(condition)
    @conditions << condition
    self
  end

  def limit(n)
    @limit = n
    self
  end

  def build
    {conditions: @conditions, limit: @limit}
  end
end

# Usage
QueryBuilder.new.where("active").where("verified").limit(10).build
```

**After:**

```ruby
# lib/query.rb
module Query
  module_function

  def build(conditions: [], limit: nil)
    {conditions: Array(conditions), limit: limit}
  end
end

# Usage
Query.build(conditions: ["active", "verified"], limit: 10)
```

### Example 5: Missing Protocol → Implementing Protocols

**Before:**

```ruby
# lib/collection.rb
class Collection
  def initialize(items)
    @items = items
  end

  def get_items
    @items
  end

  def size
    @items.size
  end
end
```

**After:**

```ruby
# lib/collection.rb
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

# Now Collection works with all Enumerable methods
# collection.map, .select, .reject, .find, etc.
```

### Example 6: Stateful Utility → Pure Function

**Before:**

```ruby
# lib/calculator.rb
class Calculator
  def initialize
    @result = 0
  end

  def add(n)
    @result += n
  end

  def multiply(n)
    @result *= n
  end

  def result
    @result
  end
end

# Usage
calc = Calculator.new
calc.add(5)
calc.multiply(2)
calc.result # => 10
```

**After:**

```ruby
# lib/calculator.rb
module Calculator
  module_function

  def add(a, b)
    a + b
  end

  def multiply(a, b)
    a * b
  end

  def calculate
    -> (initial) { yield(initial) }
  end
end

# Usage (functional approach)
result = Calculator.add(5, 0)
result = Calculator.multiply(result, 2) # => 10

# Or use method chaining with a pipeline
result = 0.then { |n| Calculator.add(n, 5) }
           .then { |n| Calculator.multiply(n, 2) }
```

## Best Practices

1. **Prefer data over objects** - Use Hashes, Arrays, Structs, and Data for simple data

2. **Prefer functions over classes** - Use modules with `module_function` for stateless operations

3. **Implement Ruby protocols** - Make objects work with Ruby's built-in methods and Enumerable

4. **Use blocks effectively** - Blocks are Ruby's lambdas; use them instead of callback objects

5. **Keep inheritance shallow** - Prefer composition and modules over deep inheritance

6. **Avoid premature abstraction** - Don't create frameworks; write simple code first

7. **Leverage standard library** - Ruby's stdlib is rich; don't reinvent Array, Hash, Set, etc.

8. **Measure complexity** - Use tools like Flog, Reek, or Rubocop metrics to track improvements

9. **Reference principles** - Cite [Ruby Style Guide](https://rubystyle.guide), Sandi Metz's rules, and CLAUDE.md principles

---

Return the structured improvement report with specific, actionable refactoring steps as specified above.
