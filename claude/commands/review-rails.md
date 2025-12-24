---
name: review-rails
description: Audit Rails codebase for over-engineering and unnecessary abstractions with actionable refactoring steps
---

# Rails Code Review & Refactoring Guide

Analyze Ruby/Rails code for unnecessary custom objects, class bloat, and insufficient usage of Ruby's generic data structures. Provides specific refactoring steps with before/after code examples.

## Additional Context

$ARGUMENTS

**Instructions for using additional context:**

- If **file paths** are provided (e.g., `app/models/user.rb`), analyze only those files
- If **directory paths** are provided (e.g., `app/services/`), analyze all Ruby files in that directory
- If a **branch name** is provided, compare current branch against it to review only changed files
- If **no arguments** are provided, perform full codebase audit
- If a **focus area** is specified (e.g., "service objects", "value objects"), prioritize that aspect

## Analysis Process

### STEP 1: Determine Scope

```bash
# If no arguments provided, scan full application and tests
# If branch name provided, get changed files
git diff <branch>...HEAD --name-only '*.rb'

# If directory provided, list Ruby files
find <directory> -name '*.rb'
```

### STEP 2: Analyze Anti-Patterns

Scan for these Rails-specific issues:

#### A. Service Object Proliferation

- [ ] Single-method service classes (`call`, `perform`, `execute`)
- [ ] Services with no state or instance variables
- [ ] Services that are just wrappers around other methods
- [ ] Command objects that could be simple methods

#### B. Value Object Overuse

- [ ] Custom classes for simple data pairs (coordinates, ranges)
- [ ] Value objects without behavior or validation
- [ ] Objects that just wrap primitives without transformation
- [ ] Missing Ruby protocol implementations (`to_h`, `to_a`, `to_json`)

#### C. Custom DSLs and Unnecessary Abstractions

- [ ] Reinventing ActiveRecord patterns
- [ ] Custom configuration frameworks
- [ ] Deep inheritance hierarchies (>3 levels)
- [ ] Abstract base classes with single implementations
- [ ] Wrapper classes around standard library

#### D. Anti-Functional Patterns

- [ ] Stateful utility classes that could be modules
- [ ] Classes with only class methods (should be modules)
- [ ] Mutable objects where immutable would work

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

## Rails Code Review: [Scope Description]

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

- Proper use of Structs, Hashes, or simple classes
- Well-implemented Ruby protocols
- Functional approaches with modules
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

- Prefer simple, immutable data structures (Hash, Array, Struct)
- Separate data from behavior
- Use pure functions without side effects
- Avoid complecting concerns

### 2. Rails Conventions

- Use ActiveRecord callbacks and scopes appropriately
- Leverage Rails' built-in methods before creating custom ones
- Follow "Convention over Configuration"
- Use concerns for shared behavior, not inheritance

### 3. Ruby Idioms

- Implement Ruby protocols (`each`, `to_h`, `to_a`, `to_json`)
- Use modules for mixins and namespacing
- Prefer composition over inheritance
- Use blocks and Enumerable methods

### 4. Safe Refactoring

- Make changes incrementally
- Run tests after each change
- Use deprecation warnings for gradual migrations
- Keep both old and new code paths temporarily if needed

## Examples of Common Refactorings

### Example 1: Service Object → Simple Method

**Before:**

```ruby
# app/services/user_creator.rb
class UserCreator
  def initialize(params)
    @params = params
  end

  def call
    User.create(@params)
  end
end

# Usage
UserCreator.new(params).call
```

**After:**

```ruby
# app/models/user.rb
class User < ApplicationRecord
  def self.create_from_params(params)
    create(params)
  end
end

# Usage
User.create_from_params(params)
```

### Example 2: Value Object → Struct

**Before:**

```ruby
# app/value_objects/coordinate.rb
class Coordinate
  attr_reader :lat, :lng

  def initialize(lat, lng)
    @lat = lat
    @lng = lng
  end
end
```

**After:**

```ruby
# Inline where needed
Coordinate = Struct.new(:lat, :lng, keyword_init: true)

# Or just use a Hash
{lat: 40.7128, lng: -74.0060}
```

### Example 3: Utility Class → Module

**Before:**

```ruby
# app/utils/date_formatter.rb
class DateFormatter
  def self.format_for_display(date)
    date.strftime("%B %d, %Y")
  end

  def self.format_for_api(date)
    date.iso8601
  end
end
```

**After:**

```ruby
# app/helpers/date_helper.rb
module DateHelper
  module_function

  def format_for_display(date)
    date.strftime("%B %d, %Y")
  end

  def format_for_api(date)
    date.iso8601
  end
end
```

## Best Practices

1. **Start with the most impactful changes** - Fix critical issues that affect multiple call sites first

2. **Measure before and after** - Use benchmarks for performance claims, run test suite timing

3. **Update documentation** - Remove references to deleted patterns, add examples of new patterns

4. **Communicate changes** - Write clear commit messages explaining the simplification

5. **Reference principles** - Cite [Ruby Style Guide](https://rubystyle.guide), Rails guides, and CLAUDE.md principles

---

Return the structured improvement report with specific, actionable refactoring steps as specified above.
