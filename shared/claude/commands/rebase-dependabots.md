---
name: rebase-dependabots
model: haiku
description: Comment "@dependabot rebase" on all open Dependabot PRs to rebase stale branches
---

# Rebase Dependabots

Finds all open Dependabot PRs and comments "@dependabot rebase" on each to trigger a rebase of stale branches.

## Actions

1. **Find all open Dependabot PRs**

   ```bash
   gh pr list --author "app/dependabot" --state open --json number,title
   ```

2. **For each PR, comment to trigger rebase**

   ```bash
   gh pr comment <PR_NUMBER> --body "@dependabot rebase"
   ```

3. **Report results**
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

## Notes

- This triggers Dependabot to rebase each PR against the base branch
- Useful when PRs become stale due to main branch updates
- Safe operation - only adds a comment, does not merge anything
