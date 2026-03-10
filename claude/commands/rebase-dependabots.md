---
name: rebase-dependabots
model: haiku
description: Comment "@dependabot rebase" on all open Dependabot PRs to rebase stale branches
---

# Rebase Dependabots

Finds all open Dependabot PRs and comments "@dependabot rebase" on each to trigger a rebase of stale branches.

## Arguments

$ARGUMENTS

### Supported Arguments

- **PR numbers** (optional): Space-separated PR numbers to process (e.g., `123 124`)
  - If omitted, discovers all open Dependabot PRs
  - Example: `/rebase-dependabots 123 124`

- **--dry-run** (optional): List PRs that would be rebased, without commenting
  - Example: `/rebase-dependabots --dry-run`

### Argument Parsing

Parse arguments to extract:

- PR numbers: Any numeric arguments
- Dry-run flag: Check for `--dry-run` in arguments

## Actions

1. **Find open Dependabot PRs**

   If PR numbers were provided, use those. Otherwise discover all:

   ```bash
   gh pr list --author "app/dependabot" --state open --json number,title
   ```

2. **If `--dry-run`: list and stop**

   Print the PRs that would receive the rebase comment, then exit without
   commenting.

3. **For each PR, comment to trigger rebase**

   ```bash
   gh pr comment <PR_NUMBER> --body "@dependabot rebase"
   ```

4. **Report results**
   - List each PR that received the rebase comment
   - Report any failures

## Example Output

```text
Finding open Dependabot PRs...
Found 3 open Dependabot PRs

Requesting rebase for PR #123: Bump rails from 7.0.0 to 7.0.1
Requesting rebase for PR #124: Bump nokogiri from 1.13.0 to 1.13.10
Requesting rebase for PR #125: Bump rspec from 3.12.0 to 3.13.0

Done! Requested rebase on 3 PRs.
```

### Dry-run Output

```text
Finding open Dependabot PRs...
Found 3 open Dependabot PRs

Would rebase:
  - PR #123: Bump rails from 7.0.0 to 7.0.1
  - PR #124: Bump nokogiri from 1.13.0 to 1.13.10
  - PR #125: Bump rspec from 3.12.0 to 3.13.0

Dry run complete. No comments were posted.
```

## Notes

- This triggers Dependabot to rebase each PR against the base branch
- Useful when PRs become stale due to main branch updates
- Safe operation - only adds a comment, does not merge anything
