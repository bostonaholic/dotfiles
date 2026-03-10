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
1. SCOPE  — Define the bug and declare what will and will NOT change
2. READ   — Understand the bug and relevant source code
3. RED    — Write a failing test that reproduces the exact bug
4. VERIFY — Run the test suite to confirm it fails for the right reason
5. GREEN  — Implement the minimal fix (no refactors, no cleanups)
6. VERIFY — Run the full test suite to confirm everything passes
7. REVIEW — Diff review against declared scope
8. COMMIT — Commit with a conventional commit message referencing the issue
```

## Scope Declaration

Before reading code or writing tests, state the scope explicitly:

1. **Bug statement**: Describe the bug in one sentence
2. **Files to change**: List the files you expect to modify (reject if > 3
   without justification)
3. **Will NOT change**: Explicitly list what is out of scope — types,
   interfaces, adjacent modules, formatting, naming

This declaration is your contract. If the fix grows beyond the declared
scope, stop and reassess before continuing.

## Diff Review

After all tests pass and before committing, review the diff against your
scope declaration:

- Does every changed file appear in your "files to change" list?
- Did you modify anything listed in "will NOT change"?
- Are there changes unrelated to the bug statement?

If scope was exceeded, revert the out-of-scope changes and file them as
separate issues.

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

1. Scope declaration:
   - Bug: Game crashes on emoji characters in player names
   - Files to change: src/validation.ts, src/__tests__/validation.test.ts
   - Will NOT change: Player model, join handler interface, other validators
2. Read the join handler and existing tests
3. Write a test: "should handle player names with emoji characters"
4. Run tests — confirm the new test fails with the reported error
5. Fix: add emoji handling to the name validation function
6. Run full test suite — all green
7. Diff review — only validation.ts and its test changed, matches scope
8. Commit: "fix(game): handle emoji characters in player names"
```

## Anti-Patterns

| Do Not | Instead |
| ------ | ------- |
| Fix the bug first, write tests after | Write the failing test first |
| Refactor the module while fixing | Make the minimal targeted change |
| Change type signatures or interfaces | Only modify what the fix requires |
| Revert intentional code to pass old tests | Update test assertions |
| Fix unrelated issues you discover | File them as separate issues |
