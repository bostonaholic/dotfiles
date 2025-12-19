---
name: "systematic-code-review"
description: "A structured code review framework that evaluates design, correctness, security, reliability, and long-term maintainability, using Conventional Comments for clear, actionable feedback."
tags:
  - code-review
  - quality
  - mentoring
  - conventional-comments
version: 1.2.0
---

# Systematic Code Review Framework

## Purpose

Use this skill to perform deep code reviews that go far beyond style and syntax. The goals are to:

- Protect architecture and system qualities (reliability, scalability, security).
- Catch correctness and edge-case issues early.
- Provide mentoring-quality feedback that grows the author's skills.
- Express feedback using **Conventional Comments** so intent and severity are always explicit.

This framework is **opinionated but adaptable**. When in doubt, optimize for clarity, safety, and long-term maintainability.

---

## When to Use

Use this framework when:

- Reviewing non-trivial changes (new features, refactors, infra or schema changes).
- Evaluating code that touches cross-cutting concerns: auth, data access, concurrency, resilience, observability.
- The change will be reused broadly (libraries, APIs, shared components).

Use lightly or skip for:

- Purely mechanical changes (renames, comment fixes, auto-generated code).
- Bulk formatting-only PRs.

---

## Review Philosophy: First Principles

Every review comment should align with these foundational principles:

### Clarity Over Cleverness

- **Look for:** Code that is straightforward, well-named, and easy to understand
- **Flag:** Clever tricks, cryptic one-liners, unnecessary complexity
- **Comment:** `issue (blocking, readability): This clever approach sacrifices clarity. Can we use a straightforward implementation?`

### Strong Boundaries, Loose Coupling

- **Look for:** Well-defined interfaces, minimal dependencies, clear module responsibilities
- **Flag:** Tight coupling, unclear boundaries, hidden dependencies
- **Comment:** `issue (non-blocking, design): This creates tight coupling between X and Y. Consider message-passing or dependency injection.`

### Fail Fast, Fail Loud

- **Look for:** Early validation, explicit error handling, clear error messages
- **Flag:** Silent failures, swallowed errors, unclear failure modes
- **Comment:** `issue (blocking, reliability): This silently ignores the error. Fail fast with a clear exception.`

### Simplicity Wins

- **Look for:** Minimal moving parts, straightforward solutions, avoided over-engineering
- **Flag:** Unnecessary layers, premature abstractions, complex solutions to simple problems
- **Comment:** `suggestion (non-blocking): This adds complexity. Is the simpler approach sufficient?`

### Design for Change

- **Look for:** Flexible interfaces, adaptable patterns, extensibility without modification
- **Flag:** Hardcoded assumptions, brittle dependencies, change-resistant design
- **Comment:** `issue (non-blocking, maintainability): This is hardcoded. Consider making it configurable for future requirements.`

### Test at the Right Levels

- **Look for:** Unit tests for correctness, integration tests for contracts, e2e tests for business outcomes
- **Flag:** Testing at wrong granularity, over-mocking, under-testing critical paths
- **Comment:** `todo: Add integration test to verify the contract between these services.`

### Operational Excellence is a Feature

- **Look for:** Observability, actionable logs, alerting, graceful degradation
- **Flag:** Missing metrics, poor error messages, no operational considerations
- **Comment:** `issue (blocking, operability): Add logging and metrics to monitor this critical path.`

---

## Legendary Programmer Standards

Use these standards as evaluation criteria during review. Attribute principles by name to create shared vocabulary and teaching moments.

### Rich Hickey: Simplicity and Immutability

**Philosophy:** Emphasize simple, immutable data structures and pure functions (no side effects).

- **Look for:** Immutable data structures, pure functions, separation of data and behavior
- **Flag:** Mutable shared state, complex intertwined data structures, side effects in business logic
- **Example comment:** `issue (blocking, design): This mutates shared state. Following Rich Hickey's principle, consider pure function returning new value.`

### John Carmack: Direct Implementation and Performance

**Philosophy:** Implement features directly, avoiding unnecessary abstraction. Always reason about performance.

- **Look for:** Direct implementations, stated performance considerations, profiling justification for optimizations
- **Flag:** Unnecessary abstraction layers, unaddressed performance implications, optimizations without measurement
- **Example comment:** `suggestion (non-blocking): Following Carmack's principle, is this abstraction necessary? Direct implementation may be clearer and faster.`

### Joe Armstrong: Failure Isolation

**Philosophy:** Isolate failures through rigorous error handling. Ensure faults don't propagate.

- **Look for:** Rigorous error handling, failure boundaries, contained blast radius
- **Flag:** Error propagation, cascading failures, missing error boundaries
- **Example comment:** `issue (blocking, reliability): Following Joe Armstrong's isolation principle, this error could cascade. Add boundary handling.`

### Alan Kay: Message Passing and Late Binding

**Philosophy:** Favor message-passing, loosely coupled components, defer binding decisions.

- **Look for:** Loose coupling, message-passing design, late-bound decisions, protocol-oriented interfaces
- **Flag:** Tight coupling, early binding, direct method calls across boundaries
- **Example comment:** `suggestion (non-blocking, design): Alan Kay's principle suggests message-passing here. Could this be late-bound for flexibility?`

### Donald Knuth: Readability and Maintainability

**Philosophy:** Code must be readable and maintainable above all else. Choose clarity before cleverness.

- **Look for:** Clear naming, well-structured code, helpful comments, literate programming
- **Flag:** Clever tricks, unclear intent, poor naming, missing documentation for non-obvious logic
- **Example comment:** `issue (blocking, readability): Following Knuth's principle: clarity over cleverness. This is hard to understand. Please simplify.`

### Barbara Liskov: Contract Respect (Substitutability)

**Philosophy:** Respect interface contracts. Ensure implementations can be replaced without breaking expectations.

- **Look for:** Interface contract adherence, substitutability, consistent behavior across implementations
- **Flag:** Liskov Substitution Principle (LSP) violations, unexpected behavior changes, contract breaches
- **Example comment:** `issue (blocking, design): This violates Liskov Substitution - implementation changes expected contract behavior. Subclasses must honor base class contracts.`

### John Ousterhout: Deep Modules, Simple Interfaces

**Philosophy:** Fight complexity by designing deep modules with simple interfaces. Pull complexity downward.

- **Look for:** Simple interfaces hiding complexity, strategic design, complexity pushed into implementations
- **Flag:** Exposed complexity, complex interfaces, tactical patches, leaky abstractions
- **Example comment:** `suggestion (non-blocking, design): Following Ousterhout's principle, pull this complexity into the implementation. Simplify the interface.`

---

## Industry Best Practices 2025

Modern code review integrates research-backed practices and industry standards.

### Atomic Changes Principle

**Industry standard:** 200-400 lines of code per review (Google engineering culture standard).

- **< 200 lines:** Ideal size, full detailed review
- **200-400 lines:** Sweet spot, full detailed review with high effectiveness
- **400-1000 lines:** Consider splitting, focus review on high-impact areas
- **> 1000 lines:** Strong recommendation to split, architectural review only

**Comment template:** `suggestion (non-blocking): This PR has 1,247 lines. Following Google's atomic change principle, consider splitting into smaller PRs (200-400 lines) for effective review.`

### SOLID Principles Checklist

Explicitly verify adherence to SOLID principles:

### Single Responsibility Principle (SRP)

- Each class/module has one reason to change
- **Flag:** Classes doing multiple unrelated things

### Open-Closed Principle (OCP)

- Open for extension, closed for modification
- **Flag:** Need to modify existing code to add behavior

### Liskov Substitution Principle (LSP)

- Subtypes must be substitutable for base types
- **Flag:** Subclass changes expected behavior (see Liskov section above)

### Interface Segregation Principle (ISP)

- Clients shouldn't depend on interfaces they don't use
- **Flag:** Fat interfaces forcing unnecessary dependencies

### Dependency Inversion Principle (DIP)

- Depend on abstractions, not concretions
- **Flag:** High-level modules depending on low-level details

**Comment template:** `issue (blocking, design): Violates SRP - this class handles both data validation AND external API calls. Split responsibilities.`

### Cross-Referencing

Systematically review dependencies and relationships between code elements.

- **Check:** How does this change affect calling code?
- **Check:** What dependencies does this introduce or modify?
- **Check:** Are there hidden coupling points?

**Comment template:** `question (non-blocking): This changes the signature. Have we checked all callers? Cross-reference shows usage in payment-service.`

### Continuous Improvement Over Perfection

Modern review philosophy emphasizes pragmatism:

- **Technical facts and data overrule opinions**
- **Style guide is absolute authority on style matters**
- Seek improvement, not perfection
- Focus on impact, not preferences

**Comment template:** `nitpick (non-blocking): Style preference - consider renaming per style guide §3.2, but non-blocking.`

---

## Review Workflow

Follow this order; do not jump straight to nits.

1. **Understand the context**

   - What business or technical problem is this change solving?
   - Is there a linked ticket / design doc / ADR?
   - What is the minimal mental model needed to review this safely?

2. **Scan the change at a high level**

   - Files and directories touched.
   - New public APIs or endpoints.
   - New dependencies or infra resources.
   - Migrations and data shape changes.
   - **Check change size:** Note if > 400 lines (consider atomic change principle).

3. **Evaluate correctness and behavior**

   - Does the code actually solve the described problem?
   - Are edge cases, error conditions, and boundary inputs handled?
   - Are assumptions explicit (comments, contracts, assertions)?
   - **Checklist-based verification:** Use domain-specific checklists (security, performance, etc.).

4. **Evaluate design and architecture impact**

   - Does this align with existing architecture and conventions?
   - Is this introducing a new pattern where an existing one would suffice?
   - Is this a local change or an architecture decision in disguise?

   **Pattern Recognition (Fowler's Refactoring to Patterns):**
   - **Long methods:** Suggest **Compose Method** pattern
   - **Type-based conditionals:** Suggest **Replace Conditional with Polymorphism** pattern
   - **Duplicate algorithms:** Suggest **Form Template Method** pattern
   - **Scattered null checks:** Suggest **Introduce Null Object** pattern
   - **Type field drives behavior:** Suggest **Replace Type Code with State/Strategy** pattern

   **When suggesting refactoring, ALWAYS name the pattern explicitly.**

   **Example:** `suggestion (non-blocking): This switch on payment type is a classic case for the Replace Conditional with Polymorphism pattern (Fowler). See payment-processor.ts for existing example.`

   **SOLID Check:** Verify SRP, OCP, LSP, ISP, DIP (see Industry Best Practices section).

5. **Evaluate tests**

   - Are there tests for the critical paths and edge cases?
   - Do tests read like executable specifications of behavior?
   - Are tests stable, isolated, and fast enough for regular runs?

   **TDD Quality Checklist:**
   - **Behavioral:** Do tests describe what the system does, not how it does it?
   - **Isolated:** Does each test have a single clear purpose with minimal setup?
   - **Readable:** Can someone new to the code understand behavior from tests alone?
   - **Deterministic:** No reliance on real clocks, randomness, or uncontrolled external services?
   - **Fast enough:** Can core unit tests run frequently during development?

   **Red Flags:**
   - Tests added after implementation (not TDD)
   - Testing private methods instead of observable behavior
   - Over-mocking internals (testing implementation details)
   - Tests that are slower than necessary

   **Example:** `issue (blocking, tests): These tests check implementation details (private methods) rather than behavior. Following TDD principles and Knuth's "tests as documentation," rewrite to test observable outcomes.`

   For detailed TDD workflow guidance, see the `tdd-enforcement` skill. For test strategy, patterns, and anti-patterns (testing pyramid, test doubles, flaky tests), see the `software-testing-strategy` skill.

6. **Evaluate security and safety**

   - Any user input crossing trust boundaries?
   - Data access, authorization, and privacy concerns?
   - Secrets, keys, tokens, or sensitive data handling?
   - **Joe Armstrong principle:** Are failures isolated and not propagating?

7. **Evaluate operability and observability**

   - Logging, metrics, and traces where they matter?
   - Clear error messages and actionable logs?
   - Impact on existing alerts and SLOs?
   - **Operational Excellence principle:** Is monitoring built in, not bolted on?

8. **Evaluate maintainability**

   - Readability: can a mid-level engineer understand this in one sitting?
   - Coupling and cohesion: is the change localized or spreading complexity?
   - Naming, structure, and comments: do they carry their weight?
   - **Knuth principle:** Is this optimized for human reading?
   - **Ousterhout principle:** Are interfaces simple, with complexity hidden in implementation?

9. **Provide feedback and decision**

   - Write comments using **Conventional Comments syntax**.
   - Classify feedback as blocking vs non-blocking via decorations.
   - Explain **why** each major point matters (principle or risk).
   - End with a clear status: approve / approve with nits / request changes.

   **Review Commit Messages:**
   - Do commits explain WHY, not just WHAT?
   - Is the commit history clean and logical?
   - Are commits atomic (one logical change each)?
   - Do they follow repository conventions?

   **If commit messages are poor, include feedback:**

   `chore (non-blocking): Commit messages should explain WHY. Example: "Update code" → "Add rate limiting to prevent API abuse per incident INC-1234"`

   For detailed commit message guidance, see the git-commit skill.

---

## Conventional Comments in This Skill

All review comments should follow the Conventional Comments format:

```text
<label> [decorations]: <subject>
[discussion]
```

### Core Labels to Use

Use these labels by default:

- `praise:`
  Highlight something positive. Aim for at least one sincere praise per review.

- `nitpick:`
  Trivial, preference-based requests. These are non-blocking by default.

- `suggestion:`
  Propose an improvement. Be explicit about *what* to change and *why* it is better.

- `issue:`
  Point out a concrete problem (correctness, security, performance, UX, etc.). Pair with a `suggestion:` where possible.

- `todo:`
  Small, necessary but trivial changes (e.g., update a comment, add a missing test case).

- `question:`
  Use when you are unsure or need clarification; often a good alternative to a premature `issue:`.

- `thought:`
  Non-blocking ideas that could lead to future improvements or mentoring moments.

- `chore:`
  Process-related tasks that must be done before acceptance (e.g., run a CI job, update a checklist).

- `note:`
  Non-blocking information you want the reader to be aware of.

You may also use these optional labels if they match team norms:

- `typo:`
- `polish:`
- `quibble:`

### Decorations

Decorations appear in parentheses after the label:

- `(blocking)`
  Must be resolved before the change is accepted.

- `(non-blocking)`
  Helpful but not required for merge.

- `(if-minor)`
  Resolve only if the change is minor/trivial.

Domains or categories can also be used as decorations, for example:

- `(security)`
- `(performance)`
- `(tests)`
- `(readability)`
- `(maintainability)`

### Examples

Good examples for this skill (file location first, then conventional comment):

```text
[src/validation.ts:34]
**praise**: This extraction of the validation logic into a separate function makes the flow much easier to follow.
```

```text
[api/users.py:127]
**issue (blocking, security)**: We are interpolating user input directly into this SQL query.
Could we switch to parameterized queries here?
```

```text
[handlers/payment.js:89-105]
**suggestion (non-blocking, readability)**: The nested conditionals here are hard to scan.
Consider early returns to flatten this branch.
```

```text
[tests/auth_test.py]
**todo**: Please add a regression test that fails without this fix and passes with it.
```

```text
[core/processor.go:234]
**question (non-blocking)**: Do we expect this operation to be on the hot path?
If so, have we considered the allocation cost in this loop?
```

```text
[lib/helpers.rb:45]
**thought (non-blocking)**: This pattern shows up in a few places.
Might be worth extracting into a shared helper in a follow-up.
```

---

## Integrated Review Examples

Real-world examples showing multi-principle reviews with explicit attribution.

### Example 1: Multiple Principle Violations

**Code:**

```python
def process_user(user_type, data):
    if user_type == 'admin':
        # Complex admin logic here
        result = perform_admin_operations(data)
        audit_log(result)
    elif user_type == 'regular':
        # Complex regular logic here
        result = perform_regular_operations(data)
    elif user_type == 'guest':
        result = perform_guest_operations(data)
    return result
```

**Review Comment:**

```text
[src/user_processor.py:15-28]
**issue (blocking, design)**: This function violates multiple principles:

1. **John Ousterhout (Deep Modules, Simple Interfaces):** Type switching exposes complexity that should be hidden behind an interface.

2. **Barbara Liskov (Substitutability):** Can't replace user type handling without modifying this function. Violates Open-Closed Principle.

3. **Fowler Pattern:** Classic **Replace Conditional with Polymorphism** opportunity.

**Suggestion:** Create UserProcessor interface with AdminUserProcessor, RegularUserProcessor, and GuestUserProcessor implementations. Then:

```python
def process_user(user_processor: UserProcessor, data):
    result = user_processor.process(data)
    user_processor.audit(result)
    return result
```

This follows Liskov Substitution, hides complexity (Ousterhout), and uses proven pattern (Fowler).

See payment-processor.py:45 for existing polymorphic pattern in this codebase.

```text

### Example 2: TDD Violation

**Test:**
```python
def test_calculate_discount():
    calculator = DiscountCalculator()
    assert calculator._apply_percentage(100, 10) == 90  # Testing private method
```

**Review Comment:**

```text
[tests/test_calculator.py:12]
**issue (blocking, tests)**: This test violates TDD and documentation principles:

1. **Testing implementation details:** Tests private method `_apply_percentage` instead of public behavior
2. **Donald Knuth principle:** Tests should serve as documentation. This doesn't explain user-observable behavior
3. **TDD principle:** Tests should be behavioral (what the system does), not implementation-focused (how it does it)
4. **Refactoring impediment:** Can't change discount calculation implementation without breaking test

**Suggestion - Behavioral test:**

```python
def test_premium_users_receive_ten_percent_discount():
    """Premium users get 10% discount on all orders."""
    calculator = DiscountCalculator()
    order = Order(subtotal=100, user_type='premium')

    discount = calculator.calculate_discount(order)

    assert discount == 10, "Premium users should receive 10% discount"
```

This tests observable behavior, serves as documentation, and doesn't couple to implementation.

See tdd-enforcement skill for complete test quality checklist.

```text

### Example 3: Performance Without Measurement (Carmack)

**Code:**
```python
def find_user(users, email):
    """Optimized lookup using binary search."""
    # Complex binary search implementation
    left, right = 0, len(users) - 1
    while left <= right:
        mid = (left + right) // 2
        if users[mid].email == email:
            return users[mid]
        elif users[mid].email < email:
            left = mid + 1
        else:
            right = mid - 1
    return None
```

**Review Comment:**

```text
[utils/search.py:45-59]
**question (non-blocking, performance)**: Following **John Carmack's principle** (measure and reason about performance):

1. What's the typical size of `users`?
2. Have we profiled to confirm binary search is faster than dict lookup here?
3. Are `users` guaranteed to be sorted?

For n < 1000, a dict lookup (`users_by_email[email]`) is likely simpler, faster, and more maintainable.

**First Principles conflict:**
- **Clarity Over Cleverness:** Binary search adds complexity
- **Simplicity Wins:** Dict lookup is simpler

Suggest profiling before committing to complex optimization. Include benchmark results in PR description if keeping binary search.
```text

### Example 4: Mutable Shared State (Hickey)

**Code:**

```python
class UserSession:
    shared_config = {}  # Mutable class variable

    def update_setting(self, key, value):
        self.shared_config[key] = value  # Mutates shared state
```

**Review Comment:**

```text
[models/session.py:10-14]
**issue (blocking, design)**: This violates **Rich Hickey's immutability principle** and creates dangerous shared mutable state.

**Problems:**
1. All UserSession instances share the same `shared_config` dict
2. Mutations in one instance affect all others (spooky action at a distance)
3. Makes reasoning about state impossible
4. Creates race conditions in concurrent code

**Suggestion - Immutable approach:**

```python
class UserSession:
    def __init__(self, config=None):
        self._config = config or {}  # Instance variable, not class variable

    def with_setting(self, key, value):
        """Returns new UserSession with updated setting."""
        new_config = {**self._config, key: value}
        return UserSession(new_config)
```

This follows Hickey's principle: simple, immutable data structures with pure functions.

```text

### Example 5: Security and Failure Isolation (Armstrong)

**Code:**
```javascript
async function processPayment(userId, amount) {
    const user = await db.getUser(userId);
    const result = await stripe.charge(user.card, amount);
    return result;
}
```

**Review Comment:**

```text
[api/payments.js:45-49]
**issue (blocking, security)**: Multiple security and reliability issues following **Joe Armstrong's failure isolation principle**:

**Security issues:**
1. No authorization check - any userId can be charged
2. No input validation on amount (could be negative, huge, or NaN)
3. Missing trust boundary validation

**Failure isolation issues:**
1. Stripe API failure crashes entire request (doesn't isolate)
2. Database failure propagates uncaught
3. No error boundary or circuit breaker

**Suggestion:**

```javascript
async function processPayment(currentUserId, userId, amount) {
    // Authorization boundary
    if (currentUserId !== userId) {
        throw new AuthorizationError('Cannot charge another user');
    }

    // Input validation boundary
    if (amount <= 0 || amount > MAX_CHARGE) {
        throw new ValidationError('Invalid amount');
    }

    try {
        const user = await db.getUser(userId);

        try {
            const result = await stripe.charge(user.card, amount);
            return { success: true, result };
        } catch (stripeError) {
            // Isolate Stripe failures
            logger.error('Stripe charge failed', { userId, error: stripeError });
            return { success: false, error: 'Payment processing failed' };
        }
    } catch (dbError) {
        // Isolate DB failures
        logger.error('Database error', { userId, error: dbError });
        throw new SystemError('Unable to process payment');
    }
}
```

This implements multiple boundaries (Armstrong), fails fast on validation (First Principles), and isolates external service failures.

```text

---

## Quick Reference Tables

### Table 1: Principle-Based Review Checks

| Code Characteristic | Principle Violated | Review Action | Comment Label |
|-------------------|-------------------|---------------|--------------|
| Mutable shared state | Rich Hickey (Immutability) | Suggest pure functions with new values | issue (blocking, design) |
| Unnecessary abstraction | John Carmack (Directness) | Question the indirection, suggest direct implementation | suggestion (non-blocking) |
| Error swallowing | Joe Armstrong (Failure Isolation) | Require proper handling and boundaries | issue (blocking, reliability) |
| Type-based switches | Barbara Liskov (Substitutability) | Suggest polymorphism pattern | suggestion (non-blocking, design) |
| Clever one-liner | Donald Knuth (Readability) | Request clarity and explicit intent | issue (blocking, readability) |
| Complex public API | John Ousterhout (Simple Interfaces) | Suggest hiding complexity in implementation | suggestion (non-blocking, design) |
| Tight coupling | Alan Kay (Message Passing) | Suggest message-passing or late binding | suggestion (non-blocking, design) |

### Table 2: Fowler Pattern Detection

| Code Smell | Pattern to Suggest | Blocking? | When to Apply |
|------------|-------------------|-----------|--------------|
| Long method (>20 lines) | Compose Method | Only if unmaintainable | Method can't be described in one sentence |
| Type switch/conditional | Replace Conditional with Polymorphism | If extensibility needed | Each case handles different type/behavior |
| Scattered null checks | Introduce Null Object | If scattered widely | `if (obj != null)` appears >3 times |
| Duplicate algorithm structure | Form Template Method | No | Same steps, different implementations |
| Type code drives behavior | Replace Type Code with State/Strategy | If behavior varies | Enum/type field determines behavior |

**Critical rule:** ALWAYS name the Fowler pattern explicitly when suggesting refactoring.

### Table 3: SOLID Violation Detection

| Violation | Indicator | Comment Template | Severity |
|----------|----------|-----------------|---------|
| SRP violation | Class has multiple unrelated responsibilities | `issue (blocking, design): Violates SRP - handles both X and Y. Split responsibilities.` | Blocking if major |
| OCP violation | Need to modify existing code to add behavior | `suggestion (non-blocking, design): Violates OCP - consider strategy pattern for extension.` | Non-blocking |
| LSP violation | Subclass changes expected behavior | `issue (blocking, design): Violates Liskov Substitution - subclass must honor base contract.` | Blocking |
| ISP violation | Interface forces unused dependencies | `suggestion (non-blocking, design): Violates ISP - split into smaller, focused interfaces.` | Non-blocking |
| DIP violation | High-level depends on low-level details | `suggestion (non-blocking, design): Violates DIP - depend on abstraction, not concrete implementation.` | Non-blocking |

### Table 4: Change Size Guidelines (Atomic Change Principle)

| Lines Changed | Review Depth | Recommendation | Comment Template |
|--------------|-------------|---------------|-----------------|
| < 200 | Full detailed review | Ideal size | `praise: Perfect size for thorough review.` |
| 200-400 | Full detailed review | Industry sweet spot | `praise: Good PR size following atomic change principle.` |
| 400-1000 | Focus on high-impact areas | Consider splitting | `suggestion (non-blocking): Consider splitting for more effective review (current: 650 lines).` |
| > 1000 | Architectural review only | Strong recommendation to split | `suggestion (blocking): This PR (1,450 lines) exceeds reviewable size. Please split per Google's atomic change principle (200-400 lines optimal).` |

### Table 5: TDD Test Quality Checklist

| Quality | Good | Bad | Review Action |
|---------|------|-----|--------------|
| Behavioral | `test_premium_users_receive_discount()` | `test_calculate()` | Request behavior-describing names |
| Isolated | One assertion per test | Multiple unrelated assertions | Request test splitting |
| Readable | Test reads like specification | Unclear setup and assertions | Request clarification |
| Deterministic | Mocked time/randomness | `new Date()` in test | Require determinism |
| Fast | Unit test <100ms | Slow integration-style test | Suggest faster approach or different level |

---

## Integration with Other Skills

This skill provides comprehensive review methodology. For specialized deep dives:

- **git-commit skill:** Detailed commit message conventions and WHY-focused guidance
- **tdd-enforcement skill:** Complete TDD workflow (tests first, red-green-refactor cycle)
- **software-testing-strategy skill:** Strategic testing framework (testing pyramid, test patterns, anti-patterns, legacy code testing)
- **refactoring-to-patterns skill:** Full catalog of Fowler patterns with before/after examples
- **architecture-decision-record skill:** ADR structure for architectural decisions

Use this systematic-code-review skill for reviewing code. Use the specialized skills when actively performing those activities (committing, writing tests, refactoring, documenting decisions).

---

## Common Mistakes to Avoid

**Jumping to style nits first**
- **Why bad:** Misses critical issues (security, correctness, architecture)
- **Why good:** Follow workflow order - context, correctness, design, then style

**Vague feedback without reasoning**
- **Why bad:** "Fix this code" - no learning, no principle
- **Why good:** "Following Knuth's readability principle, this needs clearer naming. Consider: `calculateMonthlyRecurringRevenue` instead of `calc`"

**Reviewing without understanding context**
- **Why bad:** Miss the WHY, suggest wrong solutions
- **Why good:** Always start with: What problem does this solve?

**Forgetting at least one praise**
- **Why bad:** Demoralizing, feels like nitpicking
- **Why good:** Recognition builds trust and reinforces good practices

**Not naming patterns explicitly**
- **Why bad:** "Consider polymorphism here" - vague
- **Why good:** "Classic Replace Conditional with Polymorphism pattern (Fowler)" - precise, educational

**Blocking on preferences vs principles**
- **Why bad:** Wastes time on subjective style
- **Why good:** "Technical facts and data overrule opinions. Style guide is authority on style."

---

## Takeaways

1. **Follow the 9-step workflow in order** - Don't skip to nits
2. **Always include at least one sincere praise** - Build trust
3. **Use Conventional Comments** - Make intent and severity explicit
4. **Attribute principles by name** - Create shared vocabulary and teach
5. **Name Fowler patterns explicitly** - Precision over vagueness
6. **Atomic change principle** - 200-400 lines is the sweet spot
7. **Context-aware review** - Understand intent, not just diffs
8. **Continuous improvement over perfection** - Technical facts beat opinions
9. **Fail fast, fail loud** - Surface issues early
10. **Clarity over cleverness** - Always

The goal is not just catching bugs - it's protecting architecture, growing engineers, and building institutional knowledge through principled, mentoring-quality feedback.
