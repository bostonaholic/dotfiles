---
name: gh-cli
description: Use when working with GitHub PRs, issues, workflows, or CI/CD - automates GitHub operations without leaving the terminal, reduces context switching, and maintains consistency
---

# GitHub CLI

## Overview

**GitHub operations should be fast, scriptable, and verifiable.**

Core principle: Stay in your terminal flow. GitHub CLI (`gh`) eliminates
context switching to the web UI for routine operations while maintaining
safety, verification, and consistency.

This skill complements the git-commit skill: git manages local code,
gh-cli manages GitHub operations (PRs, issues, workflows, CI).

**MANDATORY: Always verify gh operations succeeded.** Never assume commands
worked—check the output.

## When to Use

Use this skill when:

- **Creating or managing pull requests** - "create a PR", "check PR status",
  "merge this PR"
- **Monitoring CI/workflow status** - "check if CI passed", "watch the
  workflow run"
- **Managing issues** - "create an issue", "list my issues", "view issue 123"
- **Checking out PRs for review** - "checkout PR 456 for review"
- **Viewing repository information** - "show repo info", "list recent PRs"
- **User explicitly requests gh operations** - Any mention of GitHub
  operations

## When NOT to Use

Skip this skill when:

- **Complex PR reviews** - Use web UI for file tree navigation, inline
  comments, multiple files
- **Viewing large diffs** - Web UI shows syntax highlighting, file structure
  better than terminal
- **Repository settings/webhooks** - Use web UI for configuration (gh CLI
  can't access these)
- **Operations requiring screenshots** - Web UI needed for visual artifacts
- **Not authenticated** - Check `gh auth status` first, guide user to
  authenticate
- **Operations user hasn't requested** - Don't proactively create PRs or
  close issues

## The Iron Law

These principles are non-negotiable:

- NO PR CREATION WITHOUT REVIEWING ALL COMMITS IN THE BRANCH
- NO PR MERGING WITHOUT USER CONFIRMATION
- NO FORCE OPERATIONS WITHOUT EXPLICIT REQUEST
- ALWAYS VERIFY GH OPERATIONS SUCCEEDED

Pull requests are permanent and public. Merging affects the entire team.
Closing issues impacts project tracking. These operations require deliberate
action, not automation.

## Core Workflows

### Workflow 1: Creating a Pull Request

The most common gh operation. Do this right, and PRs become clear,
consistent, and easy to review.

#### Phase 1: Gather Context

Run these commands in parallel to understand what you're PRing:

```bash
git status                    # Branch state, staged/unstaged files
git diff main...HEAD          # All changes in branch vs main
git log main..HEAD --oneline  # All commits in branch
# Check if branch is pushed
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null
```

#### Phase 2: Analyze Changes

**Critical:** Review ALL commits that will be in the PR, not just the
latest one.

Analysis checklist:

- Do you understand every change in the diff?
- Are all commits ready for review (no "wip" or "debug" commits)?
- Does the branch have a clear purpose (one feature/fix, not mixed concerns)?
- Are there tests for new functionality?
- Is the branch name descriptive?

#### Phase 3: Draft PR Description

**Structure:**

```markdown
## Summary
- [Bullet point describing main change]
- [Bullet point describing secondary change]
- [Additional context or decisions]

## Test plan
- [ ] Unit tests pass
- [ ] Integration tests cover new behavior
- [ ] Manual testing completed
- [ ] Edge cases considered

## Deployment notes
[Any special considerations for deploying this change]

Fixes #[issue-number]
```

**PR Title:**

- Use imperative mood (same as commit messages): "Add feature" not
  "Added feature"
- Follow repository conventions (check existing PRs with
  `gh pr list --limit 5`)
- Include type prefix if repo uses conventional commits: `feat:`, `fix:`,
  `refactor:`
- 50 characters or less

#### Phase 4: Create PR

```bash
# Push branch if not already pushed
git push -u origin HEAD

# Create PR with structured body via heredoc
gh pr create --title "feat: add user authentication middleware" --body "$(cat <<'EOF'
## Summary
- Implements JWT-based authentication middleware
- Adds login and logout endpoints
- Updates API routes to require authentication

## Test plan
- [x] Unit tests pass for auth middleware
- [x] Integration tests cover login/logout flow
- [x] Manual testing of protected endpoints
- [x] Tested token expiration handling

## Deployment notes
Requires JWT_SECRET environment variable to be set in production.

Fixes #142
EOF
)"
```

#### Phase 5: Verify and Report

```bash
gh pr view           # Confirm PR created with correct title/body
gh pr checks         # Verify CI started running
```

Success criteria:

- PR appears with correct title and description
- CI/workflows started (if configured)
- Issue is linked (if using "Fixes #123")
- PR URL returned to user for easy access

**Safety checks before creating:**

- ❌ Never create PR from main/master branch
- ❌ Never create PR without reviewing all commits
- ✅ Confirm branch is up-to-date: `git pull --rebase origin main`
- ✅ Check for merge conflicts: `git merge-base --is-ancestor main HEAD`

### Workflow 2: Monitoring Workflow Runs

Stay on top of CI without leaving the terminal. Catch failures early.

#### Check Status

```bash
gh run list --limit 5     # Recent workflow runs
gh run view               # Latest run details (status, jobs, timing)
gh run view --log-failed  # Only failed job logs (when debugging)
```

#### Watch Active Runs

```bash
gh run watch  # Real-time monitoring until completion
# Use this after pushing commits to catch CI failures immediately
```

Combine with notifications:

```bash
gh run watch && osascript -e 'display notification "CI run completed" \
  with title "GitHub Actions"'
```

#### When to use

- After pushing commits
- After creating a PR
- When CI fails and you need logs
- Before requesting PR review (ensure CI passes)

### Workflow 3: Issue Management

Track work, report bugs, request features—all from the terminal.

#### List Issues

```bash
gh issue list --assignee @me           # Your assigned issues
gh issue list --label bug --state open # Open bugs
gh issue list --limit 10               # Recent 10 issues
```

#### View Issue Details

```bash
gh issue view 123        # Full issue description and comments
gh issue view 123 --web  # Open in browser for complex discussions
```

#### Create New Issue

```bash
gh issue create --title "bug: login fails for OAuth users" --body "$(cat <<'EOF'
## Problem
Users authenticating via OAuth cannot log in. Error message: "Invalid token format."

## Expected behavior
OAuth users should successfully authenticate and receive a session token.

## Actual behavior
Login endpoint returns 400 error with "Invalid token format" message.

## Steps to reproduce
1. Navigate to /login
2. Click "Sign in with Google"
3. Complete OAuth flow
4. Observe error on redirect

## Environment
- Browser: Chrome 131
- OS: macOS 15.1
- API version: v2.3.1
EOF
)"
```

#### Update Issue Status

Link issues to PRs by including in PR body:

```markdown
Fixes #123
Closes #456
Resolves #789
```

When PR merges, issues auto-close.

**Comment on issues:**

```bash
gh issue comment 123 --body "Fixed in PR #456. Will deploy with next release."
```

### Workflow 4: Checking Out PRs for Review

Review teammates' code locally before approving.

#### Phase 1: Find PR

```bash
gh pr list                    # All open PRs
gh pr list --author username  # Specific author's PRs
gh pr view 456                # Check description before checkout
```

#### Phase 2: Check Out Locally

```bash
gh pr checkout 456  # Creates or switches to PR branch
```

This automatically:

- Fetches the PR branch from remote
- Creates local branch if needed
- Switches to the branch

#### Phase 3: Review Changes

```bash
git log main..HEAD --oneline   # See commits in PR
git diff main...HEAD           # See all changes
# Make local edits, run tests, verify functionality
```

#### Phase 4: Leave Review

```bash
# Approve
gh pr review --approve

# Request changes
gh pr review --request-changes \
  --body "Needs unit tests for edge case when user is null"

# Comment without approval
gh pr review --comment --body "LGTM after CI passes"
```

**Verify review posted:**

```bash
gh pr view 456  # Check review appears in PR
```

### Workflow 5: Viewing PR Status

Quick overview of your PRs and what needs attention.

#### Your PR Dashboard

```bash
gh pr status  # Shows:
              # - PRs you created
              # - PRs assigned to you
              # - PRs requesting your review
```

#### Specific PR Details

```bash
gh pr view 123        # Full details (title, body, comments, status)
gh pr checks          # CI status for current branch's PR
gh pr checks 123      # CI status for specific PR
gh pr view 123 --web  # Open in browser
```

#### Check if Ready to Merge

```bash
gh pr view 123 --json mergeable,mergeStateStatus
# Returns: mergeable (true/false), mergeStateStatus (CLEAN, BEHIND, BLOCKED, etc.)
```

**When to use:**

- Daily standup prep (what PRs need attention?)
- Before requesting review (is CI green?)
- Before merging (all checks passed?)
- When user asks "what's the status of PR 123?"

## Common Patterns

Quick reference for frequent operations:

```bash
# Quick PR creation (uses commit messages as description)
gh pr create --fill

# View PR in browser (when terminal view insufficient)
gh pr view --web
gh pr view 123 --web

# Check if your branch's PR passed CI
gh pr checks

# Approve and enable auto-merge
gh pr review --approve
gh pr merge --auto --squash

# List PRs that need your review
gh pr list --search "review-requested:@me"

# Clone repository and cd into it
gh repo clone owner/repo -- && cd repo

# View repository in browser
gh repo view --web

# Link issue to PR (in PR body)
Fixes #123
Closes #456, #789
```

## Anti-Patterns

Common mistakes and how to avoid them.

### ❌ Creating PR Without Reviewing Branch Changes

**Bad:**

```bash
# Just finished coding
gh pr create --fill  # Don't do this!
```

**Why bad:**

- Might PR debug code, console.logs, commented-out experiments
- Could include unrelated changes from other work
- Commit messages might not be polished for review

**Good:**

```bash
git log main..HEAD --oneline  # Review all commits
git diff main...HEAD          # Review all changes
# Verify everything is intentional
# Then create PR with thoughtful description
gh pr create --title "..." --body "..."
```

**Rule:** Review the full branch diff and commit history before creating a
PR. Not just the latest commit—ALL commits.

### ❌ Merging PR Without Checking CI

**Bad:**

```bash
gh pr merge 123 --squash  # Don't do this without verification!
```

**Why bad:**

- CI might be failing
- Required checks might not have run yet
- Could merge broken code that fails in production

**Good:**

```bash
gh pr checks 123      # Verify all checks pass (look for ✓)
gh pr view 123        # Confirm approvals received
# Only merge if both green
gh pr merge 123 --squash
```

**Rule:** Always check CI status before merging. If checks are failing or
pending, wait.

### ❌ Using gh for Operations Better Suited to Web UI

**Bad:**

```bash
gh pr diff 123  # Bad for large PRs
```

**Why bad:**

- Terminal diff doesn't show file tree structure
- Can't navigate between files easily
- No syntax highlighting or inline comments
- Difficult to see overall PR scope

**Good:**

```bash
gh pr view 123 --web  # Opens browser for visual review
```

**Rule:** Use gh CLI for routine operations and scripting. Use web UI for
complex reviews, file navigation, or when visual context helps.

### ❌ Creating PRs from main Branch

**Bad:**

```bash
git checkout main
# Make changes and commit
git commit -m "fix bug"
gh pr create  # Error: can't create PR from default branch
```

**Why bad:**

- PRs must come from feature branches, not main/master
- Direct commits to main should only happen in emergencies (and even then, use branches)

**Good:**

```bash
git checkout -b fix/auth-bug
# Make changes and commit
git commit -m "fix: resolve OAuth token validation"
gh pr create
```

**Rule:** Always work in feature branches. Name them descriptively:
`feat/user-auth`, `fix/memory-leak`, `refactor/api-client`.

### ❌ Using --fill for PRs That Need Context

**Bad:**

```bash
gh pr create --fill  # Uses commit messages as PR body
```

**Why bad:**

- Commit messages describe individual changes, not the overall PR purpose
- Reviewers need high-level summary and test plan
- No opportunity to add deployment notes or link issues

**Good:**

```bash
gh pr create --title "..." --body "$(cat <<'EOF'
## Summary
[High-level overview of what this PR does and why]

## Test plan
- [ ] Unit tests pass
- [ ] Integration tests added

Fixes #123
EOF
)"
```

**Rule:** Use `--fill` only for trivial PRs (typos, small doc updates).
For feature work, write a proper description.

## Safety Protocols

NEVER do these without explicit user request:

- **`gh pr merge`** - Always ask user to confirm before merging
- **`gh pr close`** - Closing PRs affects team visibility; confirm first
- **`gh issue close`** - Issues might not be resolved; don't auto-close
- **`gh pr merge --admin`** - Bypasses required checks; extremely dangerous
- **`gh repo delete`** - Destructive and irreversible; never do this
- **Operations on repos you don't own** - Ask user before modifying other
  people's repos

ALWAYS verify before operations:

- **Check authentication:** `gh auth status` (if not authenticated, guide user
  to run `gh auth login`)
- **Confirm correct repository:** `gh repo view` shows current repo context
- **Verify branch is pushed:** Check output of
  `git rev-parse --abbrev-ref --symbolic-full-name @{u}`
- **Check CI status before merge:** `gh pr checks` must show passing (✓) for
  all required checks

Integration with git-commit skill:

- If user asks to "commit and create PR", use git-commit skill first, then
  gh-cli
- Both skills share principles: verify operations, explain why, use heredocs
  for multi-line content
- Sequential workflow: commit → push → create PR

## Templates

### PR Body Template

```markdown
## Summary
- [Main change: what and why]
- [Secondary change: what and why]
- [Any non-obvious decisions or trade-offs]

## Test plan
- [ ] Unit tests pass
- [ ] Integration tests cover new behavior
- [ ] Manual testing completed
- [ ] Edge cases tested

## Deployment notes
[Any special considerations: env vars, migrations, feature flags]

Fixes #[issue-number]
```

### Issue Template (Bug Report)

```markdown
## Problem
[Clear, concise description of the bug]

## Expected behavior
[What should happen]

## Actual behavior
[What currently happens]

## Steps to reproduce
1. [Step 1]
2. [Step 2]
3. [Observe error]

## Environment
- OS: [macOS/Linux/Windows]
- Browser: [if applicable]
- Version: [relevant version info]

## Additional context
[Screenshots, error logs, related issues]
```

### Issue Template (Feature Request)

```markdown
## Problem
[What problem does this feature solve?]

## Proposed solution
[Describe the feature you'd like]

## Alternatives considered
[Other approaches you've thought about]

## Additional context
[Why is this important? Who benefits?]
```

## Verification Checklist

After creating PR:

```bash
gh pr view        # Confirm PR exists with correct title and body
gh pr checks      # Verify CI started running (or shows "no checks")
# Report PR URL to user
```

Success criteria:

- PR title matches your intent
- PR body has structured content (Summary, Test plan)
- Issue is linked (if using "Fixes #123")
- CI workflows started (if configured in repo)

After merging PR:

```bash
gh pr view 123                    # Confirm status shows "Merged"
git checkout main && git pull     # Update local main branch
gh pr view 123 --json closed,closedAt  # Verify merge timestamp
```

Success criteria:

- PR status is "Merged" (not "Closed")
- Local main branch includes the merged changes
- Linked issues auto-closed (if using "Fixes #123")

After creating issue:

```bash
gh issue view <number>  # Confirm issue created with correct content
# Report issue URL to user
```

## Troubleshooting

### "gh: command not found"

**Solution:** Install gh CLI via Homebrew:

```bash
brew install gh
```

(Already in your Brewfile, so this should not happen.)

### "gh: authentication required"

**Solution:** Authenticate with GitHub:

```bash
gh auth login
# Follow interactive prompts
# Choose HTTPS or SSH
# Authenticate via browser
```

**Check authentication status:**

```bash
gh auth status
```

**Refresh authentication with more scopes:**

```bash
gh auth refresh -s repo,workflow,read:org
```

### "gh: could not create pull request: GraphQL: not authorized"

**Possible causes:**

- Don't have write access to repository
- Token lacks required scopes

**Solution:**

```bash
gh auth status  # Check current scopes
gh auth refresh -s repo,workflow  # Add missing scopes
```

### "PR creation fails: already exists"

**Cause:** A PR already exists for this branch.

**Solution:**

```bash
gh pr list --head <branch-name>  # Find existing PR
gh pr view <number>              # Check if it's your PR
# Either continue with existing PR or close it first
```

### "gh run watch: no workflow runs found"

**Possible causes:**

- Repository doesn't have GitHub Actions configured
- Workflow hasn't been triggered yet
- Branch doesn't match workflow trigger conditions

**Solution:**

```bash
gh workflow list           # See available workflows
gh run list --limit 10     # Check recent runs
# If no workflows exist, repo might not use GitHub Actions
```

### "gh pr checks: no checks reported"

**Causes:**

- Repository doesn't have required status checks
- CI hasn't started yet (wait a moment)
- Branch protection rules don't require checks

**Solution:**

```bash
gh pr view  # Check if "Checks" section shows anything
# If legitimately no checks, PR can be merged without CI
```

## Common Rationalizations

| Excuse | Reality |
| ------ | ------- |
| "I'll check CI after creating the PR" | Create PR only when CI will pass. |
| "Small change doesn't need description" | Small PRs need context too. |
| "gh pr create --fill is good enough" | Write proper descriptions. |
| "I can merge without checking CI" | Always verify CI status first. |
| "Web UI is easier for this" | Use web for complex, gh for routine. |
| "I'll add proper description later" | Later means never. Do it now. |
| "Issues don't need detailed steps" | Clear repro steps save team time. |

## Integration Points

### With git-commit skill

**Sequential workflow:**

1. Make changes to code
2. Use git-commit skill to commit changes (reviews diff, writes clear commit message)
3. Push commits
4. Use gh-cli skill to create PR (reviews all commits, writes PR description)

**Shared principles:**

- Both emphasize verification (review before committing/PRing)
- Both explain "why" (commit messages explain why, PR descriptions explain why)
- Both use heredocs for multi-line structured content

**When user asks to "commit and create PR":**

- Use git-commit skill first
- After commit succeeds, push branch
- Then use gh-cli skill to create PR

### With git commands

**Clear separation:**

- **git** for local operations: commit, branch, diff, log, merge
- **gh** for GitHub operations: PR, issue, workflow, repo

**Common sequences:**

```bash
# Feature development
git checkout -b feat/new-feature  # git
# ... make changes ...
git commit -m "..."               # git
git push -u origin HEAD           # git
gh pr create                      # gh

# Review teammate's PR
gh pr checkout 456                # gh
git log main..HEAD                # git
git diff main...HEAD              # git
# ... test locally ...
gh pr review --approve            # gh
```

### With implement-feature command

The implement-feature command references GitHub operations:

- Creating issues at project start
- Moving issues through project states
- Creating PRs when feature complete

gh-cli skill automates these operations:

- `gh issue create` for new issues
- `gh pr create` for completed features
- Link issues to PRs via "Fixes #123"

## Quick Reference

```bash
# Pull Requests
gh pr create --fill                    # Create PR from commit messages
gh pr create --title "..." --body "..." # Create PR with custom description
gh pr list                             # All open PRs
gh pr list --author @me                # Your PRs
gh pr list --search "review-requested:@me" # PRs awaiting your review
gh pr view 123                         # View PR details
gh pr view --web                       # Open current branch's PR in browser
gh pr checkout 123                     # Check out PR locally
gh pr checks                           # CI status for current branch
gh pr review --approve                 # Approve PR
gh pr review --request-changes --body "..." # Request changes
gh pr merge --squash                   # Merge PR (after verification!)
gh pr status                           # Your PR dashboard

# Workflow Runs
gh run list --limit 10                 # Recent workflow runs
gh run watch                           # Watch latest run until completion
gh run view                            # View latest run details
gh run view --log-failed               # Show only failed job logs

# Issues
gh issue list                          # All open issues
gh issue list --assignee @me           # Your assigned issues
gh issue list --label bug              # Issues with "bug" label
gh issue view 456                      # View issue details
gh issue create                        # Create issue interactively
gh issue create --title "..." \
  --body "..."                         # Create issue with content
gh issue comment 123 --body "..."      # Comment on issue
gh issue close 456                     # Close issue (ask user first!)

# Repository
gh repo view                           # View current repo info
gh repo view --web                     # Open repo in browser
gh repo clone owner/repo               # Clone repo

# Authentication
gh auth status                         # Check auth status
gh auth login                          # Authenticate with GitHub
gh auth refresh -s repo,workflow       # Refresh with more scopes
```

## Key Takeaways

1. **Review all branch changes before creating PR** - Not just latest commit,
   ALL commits in the branch
2. **Verify CI passes before suggesting merge** - Check `gh pr checks` shows
   green (✓) for required checks
3. **Use descriptive PR titles and bodies** - Commit messages are granular,
   PR descriptions are high-level
4. **Stay in terminal for routine operations** - Use web UI only for complex
   reviews or visual context
5. **Always confirm destructive operations** - Merging, closing, deleting
   require explicit user confirmation
6. **Check authentication first** - Many gh failures are auth issues; verify
   with `gh auth status`
7. **Link issues to PRs** - Use "Fixes #123" in PR body to auto-close issues
   on merge
8. **Monitor workflow runs after pushing** - Catch CI failures early with
   `gh run watch`

**Remember:** gh CLI is for automation and routine operations. Web UI is for
complex reviews and configuration. Know when to use each.
