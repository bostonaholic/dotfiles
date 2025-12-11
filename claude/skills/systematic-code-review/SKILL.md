---
name: "systematic-code-review"
description: "A structured code review framework that evaluates design, correctness, security, reliability, and long-term maintainability, using Conventional Comments for clear, actionable feedback."
tags:
  - code-review
  - quality
  - mentoring
  - conventional-comments
version: 1.1.0
---

# Systematic Code Review Framework

## Purpose

Use this skill to perform deep code reviews that go far beyond style and syntax. The goals are to:

- Protect architecture and system qualities (reliability, scalability, security).
- Catch correctness and edge-case issues early.
- Provide mentoring-quality feedback that grows the author’s skills.
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

3. **Evaluate correctness and behavior**

   - Does the code actually solve the described problem?
   - Are edge cases, error conditions, and boundary inputs handled?
   - Are assumptions explicit (comments, contracts, assertions)?

4. **Evaluate design and architecture impact**

   - Does this align with existing architecture and conventions?
   - Is this introducing a new pattern where an existing one would suffice?
   - Is this a local change or an architecture decision in disguise?

5. **Evaluate tests**

   - Are there tests for the critical paths and edge cases?
   - Do tests read like executable specifications of behavior?
   - Are tests stable, isolated, and fast enough for regular runs?

6. **Evaluate security and safety**

   - Any user input crossing trust boundaries?
   - Data access, authorization, and privacy concerns?
   - Secrets, keys, tokens, or sensitive data handling?

7. **Evaluate operability and observability**

   - Logging, metrics, and traces where they matter?
   - Clear error messages and actionable logs?
   - Impact on existing alerts and SLOs?

8. **Evaluate maintainability**

   - Readability: can a mid-level engineer understand this in one sitting?
   - Coupling and cohesion: is the change localized or spreading complexity?
   - Naming, structure, and comments: do they carry their weight?

9. **Provide feedback and decision**

   - Write comments using **Conventional Comments syntax**.
   - Classify feedback as blocking vs non-blocking via decorations.
   - Explain **why** each major point matters (principle or risk).
   - End with a clear status: approve / approve with nits / request changes.

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

Good examples for this skill:

```text
**praise**: This extraction of the validation logic into a separate function makes the flow much easier to follow.
```

```text
**issue (blocking, security)**: We are interpolating user input directly into this SQL query.
Could we switch to parameterized queries here?
```

```text
**suggestion (non-blocking, readability)**: The nested conditionals here are hard to scan.
Consider early returns to flatten this branch.
```

```text
**todo**: Please add a regression test that fails without this fix and passes with it.
```

```text
**question (non-blocking)**: Do we expect this operation to be on the hot path?
If so, have we considered the allocation cost in this loop?
```

```text
**thought (non-blocking)**: This pattern shows up in a few places.
Might be worth extracting into a shared helper in a follow-up.
```
