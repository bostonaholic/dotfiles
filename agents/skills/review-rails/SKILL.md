---
name: review-rails
user-invokable: true
argument-hint: "[file paths, directory paths, branch name, or focus area]"
description: This skill should be used when the user asks to "review rails code", "audit rails app", "find over-engineering in rails", "simplify rails services", "review app/services", or wants to analyze a Rails codebase for unnecessary abstractions with actionable refactoring steps.
---

# Rails Code Review & Refactoring Guide

Analyze Ruby/Rails code for unnecessary custom objects, class bloat, and insufficient usage of Ruby's generic data structures. Provide specific refactoring steps with before/after code examples.

## Scope Determination

Determine scope from the user's request:

- **File paths** (e.g., `app/models/user.rb`): analyze only those files
- **Directory paths** (e.g., `app/services/`): analyze all Ruby files in that directory
- **Branch name**: compare current branch against it to review only changed files
- **No scope specified**: perform full codebase audit
- **Focus area** (e.g., "service objects", "value objects"): prioritize that aspect

## Required Skill

**MANDATORY: Load the `simplifying-ruby-code` skill** and apply its principles throughout the analysis. Reference specific patterns explicitly (e.g., "Pattern 1: Command Objects -> Module Functions").

## Anti-Patterns to Scan

### Service Object Proliferation
- Single-method service classes (`call`, `perform`, `execute`)
- Services with no state or instance variables
- Services that are just wrappers around other methods

### Value Object Overuse
- Custom classes for simple data pairs (coordinates, ranges)
- Value objects without behavior or validation
- Missing Ruby protocol implementations (`to_h`, `to_a`, `to_json`)

### Custom DSLs and Unnecessary Abstractions
- Reinventing ActiveRecord patterns
- Deep inheritance hierarchies (>3 levels)
- Abstract base classes with single implementations

### Anti-Functional Patterns
- Stateful utility classes that could be modules
- Classes with only class methods (should be modules)
- Mutable objects where immutable would work

## Output Format

For each issue found, provide:

1. **File and location** with line numbers
2. **Problem** — why it violates simplicity principles
3. **Before code** — current implementation
4. **After code** — refactored version
5. **Migration steps** — how to safely refactor
6. **Test considerations** — what tests need updating

Structure findings into: Critical Issues (fix first), Improvements (consider for refactoring), Good Patterns Found, and Summary with recommended refactoring order.

## Rails-Specific Considerations

### ActiveRecord Models
- Keep as classes — benefit from OOP (associations, validations, callbacks)
- Extract business logic to pure functions/modules
- Use concerns for shared behavior across models, not as a dumping ground

### Service Objects in Rails
- **Single method, no state** -> move to model class method or module function
- **Complex orchestration** -> keep as service object but separate decisions from effects
- **Background jobs** -> appropriate use case for service objects (need serialization)

### Rails Helpers vs Modules
- View helpers for view-specific formatting only
- Business logic belongs in separate modules with `module_function`
- Do not mix view formatting with business rules
