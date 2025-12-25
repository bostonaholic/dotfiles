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

## Required Skill

**MANDATORY: Use the `simplifying-ruby-code` skill** to evaluate code complexity and provide refactorings.

This skill provides:

- Rich Hickey's simplicity principles (immutable data, pure functions)
- Separating decisions from effects for testability
- Ruby-specific patterns (Struct/Data/Hash, protocols, module functions)
- Safe refactoring steps with migration guidance

Apply the skill's principles throughout your analysis. Reference specific patterns explicitly (e.g., "Pattern 1: Command Objects → Module Functions").

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

## Rails-Specific Considerations

When applying the `simplifying-ruby-code` skill to Rails applications:

### ActiveRecord Models

- **Keep as classes** - ActiveRecord models benefit from OOP (associations, validations, callbacks)
- **Extract business logic** - Move calculations and transformations to pure functions/modules
- **Use concerns wisely** - For shared behavior across models, not as a dumping ground

### Service Objects in Rails

- **Single method, no state** → Move to model class method or module function
- **Complex orchestration** → Keep as service object but separate decisions from effects
- **Background jobs** → Appropriate use case for service objects (need serialization)

### Rails Helpers vs Modules

- **View helpers** - Use Rails helper modules for view-specific formatting
- **Business logic** - Extract to separate modules with `module_function`
- **Don't mix** - View helpers should format, not contain business rules

### Testing Rails Code

- **Models** - Test pure methods without database when possible
- **Integration** - Test full Rails stack for complex workflows
- **Separate concerns** - Pure business logic should test without Rails

**For detailed refactoring examples and principles, refer to the `simplifying-ruby-code` skill.**

---

## Best Practices

1. **Start with the most impactful changes** - Fix critical issues that affect multiple call sites first

2. **Measure before and after** - Use benchmarks for performance claims, run test suite timing

3. **Update documentation** - Remove references to deleted patterns, add examples of new patterns

4. **Communicate changes** - Write clear commit messages explaining the simplification

5. **Reference principles** - Cite [Ruby Style Guide](https://rubystyle.guide), Rails guides, and CLAUDE.md principles

---

Return the structured improvement report with specific, actionable refactoring steps as specified above.
