---
name: test-driven-bug-fix
description: Use when fixing a bug to enforce a red-green-refactor discipline. Write a failing test that reproduces the bug BEFORE touching any production code, then make the minimal fix to turn it green. Trigger phrases: "fix this bug", "debug this issue", "reproduce and fix", "TDD bug fix".
---

# Test-Driven Bug Fix

Fix bugs by writing a failing test first, then making the minimal code
change to pass it. This prevents over-scoped refactors and ensures the bug
stays fixed.

## Workflow

```text
1. READ   — Understand the bug and relevant source code
2. RED    — Write a failing test that reproduces the exact bug
3. VERIFY — Run the test suite to confirm it fails for the right reason
4. GREEN  — Implement the minimal fix (no refactors, no cleanups)
5. VERIFY — Run the full test suite to confirm everything passes
6. COMMIT — Commit with a conventional commit message referencing the issue
```

## Rules

- **Never skip the failing test.** If you can't reproduce it in a test,
  explain why before proceeding with a manual fix.
- **Minimal fix only.** Do NOT refactor types, rename interfaces, or
  restructure surrounding code. Only change what is strictly necessary to
  fix the reported issue.
- **Update tests, don't revert code.** If an existing test assertion doesn't
  match current intentional behavior, update the test — do not revert the
  code to satisfy old tests.
- **One concern per fix.** If you discover other issues while debugging,
  note them as separate issues — do not fix them in this change.

## Test Location

Follow the project's existing test conventions:

- Look for existing test files adjacent to the source or in a `test/`,
  `spec/`, or `__tests__/` directory
- Match the naming convention used in the project (e.g., `*.test.ts`,
  `*_spec.rb`, `*_test.go`)
- Add the new test case to the most relevant existing test file

## Example Interaction

```text
User: "The game crashes when a player joins with an emoji in their name"

1. Read the join handler and existing tests
2. Write a test: "should handle player names with emoji characters"
3. Run tests — confirm the new test fails with the reported error
4. Fix: add emoji handling to the name validation function
5. Run full test suite — all green
6. Commit: "fix(game): handle emoji characters in player names"
```

## Anti-Patterns

| Do Not | Instead |
| ------ | ------- |
| Fix the bug first, write tests after | Write the failing test first |
| Refactor the module while fixing | Make the minimal targeted change |
| Change type signatures or interfaces | Only modify what the fix requires |
| Revert intentional code to pass old tests | Update test assertions |
| Fix unrelated issues you discover | File them as separate issues |
