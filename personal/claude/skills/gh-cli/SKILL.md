---
name: gh-cli
description: Use when working with GitHub PRs, issues, workflows, or CI/CD - automates GitHub operations from terminal
---

# GitHub CLI

## Overview

GitHub operations should be fast, scriptable, and verifiable. Stay in terminal flow—use web UI only for complex reviews.

**MANDATORY:** Always verify gh operations succeeded. Never assume commands worked.

## Iron Law

- NO PR CREATION WITHOUT REVIEWING ALL COMMITS IN BRANCH
- NO PR MERGING WITHOUT USER CONFIRMATION
- NO FORCE OPERATIONS WITHOUT EXPLICIT REQUEST
- ALWAYS VERIFY GH OPERATIONS SUCCEEDED

## When to Use / Not Use

**Use gh CLI for:** Creating PRs, monitoring CI, managing issues, checking out PRs for review, routine operations.

**Use web UI for:** Complex PR reviews, large diffs, repository settings, visual context.

## Workflow 1: Creating a Pull Request

### 1. Gather Context (parallel)
```bash
git status
git diff main...HEAD
git log main..HEAD --oneline
```

### 2. Analyze
- Understand every change in diff
- No "wip" or "debug" commits
- Branch has clear purpose
- Tests exist for new functionality

### 3. Create PR
```bash
git push -u origin HEAD

gh pr create --title "feat: add auth middleware" --body "$(cat <<'EOF'
## Summary
- Implements JWT authentication middleware
- Adds login/logout endpoints

## Test plan
- [x] Unit tests pass
- [x] Integration tests cover auth flow

Fixes #142
EOF
)"
```

### 4. Verify
```bash
gh pr view      # Confirm PR created
gh pr checks    # Verify CI started
```

## Workflow 2: Monitor CI

```bash
gh run list --limit 5     # Recent runs
gh run view               # Latest run details
gh run view --log-failed  # Failed job logs
gh run watch              # Real-time monitoring
```

## Workflow 3: Issue Management

```bash
gh issue list --assignee @me
gh issue view 123
gh issue create --title "bug: login fails" --body "..."
gh issue comment 123 --body "Fixed in PR #456"
```

## Workflow 4: Review PR Locally

```bash
gh pr list
gh pr view 456
gh pr checkout 456
git log main..HEAD
git diff main...HEAD
# Test locally
gh pr review --approve
# or
gh pr review --request-changes --body "Needs unit tests"
```

## Workflow 5: Check PR Status

```bash
gh pr status              # Your PR dashboard
gh pr view 123            # Full details
gh pr checks              # CI status
gh pr view 123 --json mergeable,mergeStateStatus
```

## Safety Protocols

**Never do without explicit user request:**
- `gh pr merge` - Always confirm first
- `gh pr close` / `gh issue close`
- `gh pr merge --admin` - Bypasses checks
- Operations on repos you don't own

**Always verify before operations:**
- `gh auth status` - Check authentication
- `gh repo view` - Confirm correct repo
- `gh pr checks` - CI must pass before merge

## Quick Reference

```bash
# Pull Requests
gh pr create --fill                    # From commit messages
gh pr create --title "..." --body "..."
gh pr list
gh pr view 123
gh pr view --web
gh pr checkout 123
gh pr checks
gh pr review --approve
gh pr review --request-changes --body "..."
gh pr merge --squash
gh pr status

# Workflow Runs
gh run list --limit 10
gh run watch
gh run view
gh run view --log-failed

# Issues
gh issue list
gh issue list --assignee @me
gh issue view 456
gh issue create --title "..." --body "..."
gh issue comment 123 --body "..."

# Repository
gh repo view
gh repo view --web

# Auth
gh auth status
gh auth login
```

## PR Body Template

```markdown
## Summary
- [Main change and why]
- [Secondary change]

## Test plan
- [ ] Unit tests pass
- [ ] Integration tests cover new behavior

Fixes #[issue]
```

## Key Takeaways

1. **Review all branch changes before PR** - Not just latest commit
2. **Verify CI before merge** - `gh pr checks` must show green
3. **Descriptive PR titles and bodies** - High-level summary, not commit list
4. **Terminal for routine, web for complex** - Know when to switch
5. **Confirm destructive operations** - Merge, close, delete need user confirmation
6. **Link issues to PRs** - "Fixes #123" auto-closes on merge
