---
name: rebase-dependabots
user-invokable: true
argument-hint: "[PR numbers] [--dry-run]"
description: This skill should be used when the user asks to "rebase dependabot PRs", "rebase dependabots", "refresh stale dependabot branches", or wants to comment "@dependabot rebase" on open Dependabot PRs to trigger a rebase.
---

# Rebase Dependabots

Find all open Dependabot PRs and comment "@dependabot rebase" on each to trigger a rebase of stale branches.

## Arguments

- **PR numbers** (optional): Space-separated PR numbers to process. If omitted, discover all open Dependabot PRs.
- **--dry-run** (optional): List PRs that would be rebased without commenting.

## Procedure

1. **Find open Dependabot PRs**

   If PR numbers were provided, use those. Otherwise discover all:

   ```bash
   gh pr list --author "app/dependabot" --state open --json number,title
   ```

2. **If `--dry-run`: list and stop**

   Print the PRs that would receive the rebase comment, then exit without commenting.

3. **For each PR, comment to trigger rebase**

   ```bash
   gh pr comment <PR_NUMBER> --body "@dependabot rebase"
   ```

4. **Report results**: List each PR that received the rebase comment. Report any failures.

## Notes

- This triggers Dependabot to rebase each PR against the base branch
- Useful when PRs become stale due to main branch updates
- Safe operation — only adds a comment, does not merge anything
