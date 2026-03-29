---
name: review-ruby
user-invokable: true
argument-hint: "[file paths, directory paths, branch name, or focus area]"
description: This skill should be used when the user asks to "review ruby code", "audit ruby codebase", "find over-engineering in ruby", "simplify ruby classes", "review lib/", or wants to analyze Ruby code (libraries, gems, CLI tools) for unnecessary abstractions with actionable refactoring steps.
---

# Ruby Code Review & Refactoring Guide

Analyze Ruby code for unnecessary custom objects, class bloat, and insufficient usage of Ruby's generic data structures. Provide specific refactoring steps with before/after code examples for libraries, gems, CLI tools, and Ruby applications.

## Scope Determination

Determine scope from the user's request:

- **File paths** (e.g., `lib/parser.rb`): analyze only those files
- **Directory paths** (e.g., `lib/services/`): analyze all Ruby files in that directory
- **Branch name**: compare current branch against it to review only changed files
- **No scope specified**: perform full codebase audit of `lib/` directory
- **Focus area** (e.g., "command objects", "data structures"): prioritize that aspect

## Required Skill

**MANDATORY: Load the `simplifying-ruby-code` skill** and apply its principles throughout the analysis. Reference specific patterns explicitly (e.g., "Pattern 1: Command Objects -> Module Functions").

## Anti-Patterns to Scan

### Unnecessary Class Hierarchies
- Deep inheritance trees (>2 levels) for simple behavior
- Abstract base classes with single implementations
- Classes that could be modules or simple functions
- Template method pattern where blocks would suffice

### Over-Engineered Data Objects
- Custom classes for simple data pairs (coordinates, ranges, tuples)
- Value objects without behavior, validation, or transformation
- Missing Ruby protocol implementations (`each`, `to_h`, `to_a`, `to_json`, `to_s`)
- Data objects that should be Struct, Data, or Hash

### Stateful Objects Where Functions Would Work
- Classes with only class methods (should be modules)
- Single-method classes (`call`, `run`, `execute`, `perform`)
- Builder patterns for simple object construction
- Stateful service objects that could be pure functions

### Complexity That Could Be Simplified
- Custom DSLs that reinvent Ruby syntax
- Wrapper classes around standard library
- Complex metaprogramming where simple code would work
- Unnecessary dependencies (pulling in gems for simple tasks)

## Output Format

For each issue found, provide:

1. **File and location** with line numbers
2. **Problem** — why it violates simplicity principles
3. **Before code** — current implementation
4. **After code** — refactored version
5. **Migration steps** — how to safely refactor
6. **Test considerations** — what tests need updating

Structure findings into: Critical Issues (fix first), Improvements (consider for refactoring), Good Patterns Found, and Summary with recommended refactoring order and estimated complexity.

## Best Practices

1. Prefer data over objects — use Hashes, Arrays, Structs, and Data for simple data
2. Prefer functions over classes — use modules with `module_function` for stateless operations
3. Implement Ruby protocols — make objects work with Ruby's built-in methods and Enumerable
4. Use blocks effectively — blocks are Ruby's lambdas; use them instead of callback objects
5. Keep inheritance shallow — prefer composition and modules over deep inheritance
6. Leverage standard library — Ruby's stdlib is rich; do not reinvent Array, Hash, Set, etc.
