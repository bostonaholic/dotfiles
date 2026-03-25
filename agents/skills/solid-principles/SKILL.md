---
name: solid-principles
description: >-
  This skill should be used when the user asks to "check SOLID", "review for
  SOLID", "apply SOLID principles", "single responsibility", "open/closed
  principle", "Liskov substitution", "interface segregation", "dependency
  inversion", "dependency injection", "reduce coupling", "improve cohesion",
  or "design review". Also activate proactively when editing or creating class
  files, modules with multiple responsibilities, or code with tight coupling
  between components.
---

# SOLID Design Principles

Guide software engineers toward SOLID design principles during both code
review and new code design. Activate proactively when editing classes or
modules — do not wait for an explicit request.

## When to Activate

**Proactive triggers** — activate when any of these are observed:

- Creating or editing a class, module, or service
- A file grows beyond ~200 lines of logic
- A class or module accepts dependencies it only partially uses
- A change requires modifying code unrelated to the feature being built
- An interface or abstract type is being defined
- A constructor or initializer has 4+ parameters

**Explicit triggers** — activate when the user mentions SOLID, any
individual principle by name, coupling, cohesion, or design review.

## The Five Principles — Quick Reference

| # | Principle | One-Liner | Smell |
|---|-----------|-----------|-------|
| S | Single Responsibility | One reason to change | Class changes for unrelated features |
| O | Open/Closed | Extend without modifying | Adding a feature requires editing existing code |
| L | Liskov Substitution | Subtypes are substitutable | Subclass overrides break caller expectations |
| I | Interface Segregation | No unused dependencies | Client depends on methods it never calls |
| D | Dependency Inversion | Depend on abstractions | High-level module imports low-level concrete class |

## Review Workflow

When reviewing existing code for SOLID adherence:

```text
1. SCAN    — Identify classes/modules and their responsibilities
2. MAP     — For each, list reasons it would need to change
3. DETECT  — Match against smell indicators (see table above)
4. RANK    — Prioritize violations by impact (coupling depth, change frequency)
5. PROPOSE — Suggest targeted refactors with before/after sketches
6. VERIFY  — Confirm refactor reduces complexity without over-engineering
```

### Severity Classification

| Severity | Criteria | Action |
|----------|----------|--------|
| High | Violation causes cascading changes across modules | Fix now |
| Medium | Violation adds friction but is contained | Fix when touching this code |
| Low | Violation is minor, code is simple enough | Note for awareness |

## Design Workflow

When designing new code, apply SOLID as a design checklist:

```text
1. RESPONSIBILITY — Can this class/module be described in one sentence
   without "and"?
2. EXTENSION — If a new variant is needed, can it be added without modifying
   existing code?
3. SUBSTITUTION — Can any implementation be swapped for another without
   breaking callers?
4. INTERFACE — Does each consumer depend only on what it actually uses?
5. DIRECTION — Do dependencies point from high-level policy toward
   low-level detail, mediated by abstractions?
```

If any answer is "no," redesign before writing code.

## Applying Each Principle

### S — Single Responsibility

**Test:** "Describe what this class does. If you use 'and', it has too many
responsibilities."

**Common violations:**

- A class that fetches data AND formats output
- A service that validates input AND persists records AND sends notifications
- A module that parses config AND manages runtime state

**Fix pattern:** Extract each responsibility into its own module. Connect
them through composition.

### O — Open/Closed

**Test:** "Can I add a new behavior without editing existing, tested code?"

**Common violations:**

- Adding a new payment type requires editing a switch/case block
- Supporting a new file format requires modifying the parser
- A new notification channel requires changing the notification service

**Fix pattern:** Define an abstraction (interface, protocol, base class).
Each variant implements the abstraction. Use a registry, map, or dependency
injection to select the implementation at runtime.

### L — Liskov Substitution

**Test:** "Can every subtype be used where the parent type is expected
without surprising behavior?"

**Common violations:**

- A subclass that throws on a method the parent declares
- An override that silently ignores parameters the parent uses
- A subtype that tightens preconditions or loosens postconditions

**Fix pattern:** If a subtype cannot honor the full contract, it should not
inherit. Prefer composition over inheritance when the relationship is
"uses" rather than "is-a."

### I — Interface Segregation

**Test:** "Does every consumer use every method of the interface it depends
on?"

**Common violations:**

- A class depends on a large service but calls only one method
- A function accepts a full database connection but only needs a query method
- A module imports a utility library for a single helper

**Fix pattern:** Split large interfaces into focused ones. Pass only the
capability each consumer needs (a function, a small interface, a protocol).

### D — Dependency Inversion

**Test:** "Do high-level modules import low-level modules directly?"

**Common violations:**

- A business rule module imports a specific database driver
- A controller instantiates its own service dependencies
- A domain model references infrastructure (HTTP clients, file system)

**Fix pattern:** Define abstractions at the high-level boundary. Inject
concrete implementations from the composition root (main, entrypoint,
factory).

## Pragmatic Guardrails

SOLID is a tool, not a religion. Apply these guardrails to avoid
over-engineering:

- **Three strikes rule** — Do not abstract until the third occurrence of a
  pattern. Premature abstraction is worse than duplication.
- **Complexity budget** — If applying a principle adds more indirection than
  the violation costs, skip it. Name the trade-off explicitly.
- **Scope match** — A 50-line script does not need dependency injection. Scale
  the rigor to the lifespan and team size of the codebase.
- **Test litmus** — If the refactored code is harder to test than the
  original, the design went wrong. SOLID should make testing easier.

## Output Format

When reporting SOLID findings, use this structure:

```text
### SOLID Review: [file or module name]

**Principle:** [S/O/L/I/D] — [Principle Name]
**Severity:** [High/Medium/Low]
**Violation:** [One sentence describing the problem]
**Impact:** [What breaks or becomes painful as a result]
**Suggestion:** [Concrete refactor with before/after sketch]
```

Group findings by file. Lead with high-severity violations.

## Additional Resources

For detailed patterns, code examples, and edge cases, consult:

- **`references/detailed-patterns.md`** — In-depth examples for each
  principle with before/after Ruby code, composition strategies, and common
  misconceptions
