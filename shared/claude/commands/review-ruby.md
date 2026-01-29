---
name: review-ruby
model: opus
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

**For detailed refactoring guidelines, principles, and examples, refer to the `simplifying-ruby-code` skill.**

The skill provides:

- Rich Hickey's simplicity principles
- Separating decisions from effects
- Ruby protocols and idioms
- Safe refactoring steps with before/after examples
- Common patterns: Command Objects, Value Objects, Utility Classes, Inheritance

Apply those principles throughout your analysis, explicitly referencing pattern names.

---

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
