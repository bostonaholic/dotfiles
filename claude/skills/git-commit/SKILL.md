---
name: git-commit
description: Use when committing code changes - ensures commits follow repository conventions, have clear messages explaining the why, and include proper attribution
---

# Git Commit

## Overview

**Every commit tells a story. Make it worth reading.**

Core principle: Commits should explain *why* the change exists, follow repository conventions, and provide context for future maintainers (including yourself in 6 months).

**MANDATORY: Always review git status and diff before committing.** Never commit code you haven't read.

## When to Use

Use this skill when:

- **User explicitly asks to commit** - "commit these changes", "create a commit", "git commit"
- **Completing a logical unit of work** - Feature complete, bug fixed, refactoring finished
- **Before switching branches** - Save work before context switching
- **User says "save this"** - Implies wanting a commit checkpoint

## When NOT to Use

Skip this skill when:

- **User only said "save the file"** - Write tool is sufficient, don't commit
- **Work is incomplete** - Half-implemented features create broken history
- **Tests are failing** - Never commit broken code (verify first)
- **Code hasn't been reviewed** - For multi-file changes, read what you're committing
- **Just ran pre-commit hooks** - Check if you should amend instead

## The Iron Law

**NO COMMITS WITHOUT REVIEWING GIT DIFF FIRST**

**NO COMMIT MESSAGES WITHOUT EXPLAINING WHY**

Commit messages that only describe *what* changed (visible in the diff) waste the opportunity to explain *why* it changed (invisible in the diff).

## The Process

### Phase 1: Understand Current State

Run these commands in parallel to gather context:

```bash
git status                    # See staged/unstaged files
git diff                      # See unstaged changes
git diff --staged             # See staged changes
git log --oneline -10         # See recent commit style
```

### Analysis checklist

- Are there untracked files that should be committed?
- Are there files staged that shouldn't be committed? (.env, credentials, etc.)
- Do you understand every change in the diff?
- What's the repository's commit message style?

### Phase 2: Draft the Commit Message

**Structure:**

```text
<type>: <subject line - imperative mood, 50 chars max>

<body - explain WHY, not WHAT. Wrap at 72 chars.>
```

**Subject line rules:**

- Use imperative mood: "Add feature" not "Added feature" or "Adds feature"
- No period at the end
- 50 characters or less
- Start with type prefix if repository uses conventional commits

### Common types (if repository uses them)

- `feat:` - New feature
- `fix:` - Bug fix
- `refactor:` - Code restructuring without behavior change
- `docs:` - Documentation only
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks

### Body rules

- Explain *why* the change was needed
- Describe *what* problem it solves
- Note any gotchas or non-obvious decisions
- Wrap at 72 characters
- Separate from subject with blank line

### Phase 3: Stage and Commit

```bash
# Stage relevant files (never git add . blindly)
git add path/to/file1 path/to/file2

# Commit with message via heredoc for proper formatting
git commit -m "$(cat <<'EOF'
feat: add user authentication middleware

Previous implementation left API endpoints unprotected. This adds
JWT validation middleware that runs before route handlers, ensuring
only authenticated requests reach protected endpoints.
EOF
)"

# Verify commit succeeded
git status
git log -1 --stat
```

### Phase 4: Handle Pre-commit Hook Changes

If pre-commit hooks modify files (formatters, linters):

1. **Check authorship:** `git log -1 --format='%an %ae'`
2. **Check not pushed:** `git status` shows "Your branch is ahead"
3. **If both true:** Amend the commit with hook changes
4. **Otherwise:** Create NEW commit (never amend other developers' commits)

```bash
# Safe amend (only if you authored it and haven't pushed)
git add <files-modified-by-hook>
git commit --amend --no-edit
```

## Common Mistakes

### ❌ Vague Commit Messages

**Bad:**

```text
fix: update code
```

**Why bad:** Explains nothing. What was broken? Why did this fix it?

**Good:**

```text
fix: prevent race condition in user session creation

Sessions were being created before user validation completed, allowing
invalid users to briefly access protected resources. This moves session
creation to after validation succeeds.
```

**Rule:** If your commit message could apply to any commit, it's too vague.

### ❌ Committing Without Reading the Diff

**Bad:**

```bash
# Just committing everything without review
git add .
git commit -m "updates"
```

**Why bad:** You might commit secrets, debug code, or unintended changes.

**Rule:** Always read `git diff` before staging. Always read `git diff --staged` before committing.

### ❌ Mixing Unrelated Changes

**Bad:**

```text
feat: add dark mode and fix typo in README and refactor auth logic
```

**Why bad:** Three separate concerns. If dark mode needs reverting, typo fix gets reverted too.

**Rule:** One logical change per commit. Multiple files is fine if they're part of the same logical change.

### ❌ Committing Broken Code

**Bad:**

```bash
# Tests failing but committing anyway
npm test  # 3 tests failing
git commit -m "fix: address security issue"  # Don't do this!
```

**Why bad:** Breaks git bisect, makes history untrustworthy, fails CI.

**Rule:** Only commit code that works. If tests exist, they must pass.

### ❌ Describing What Instead of Why

**Bad:**

```text
refactor: extract validateUser function
```

**Why bad:** The diff shows you extracted a function. WHY did you extract it?

**Good:**

```text
refactor: extract validateUser to enable reuse in API and webhook handlers

User validation logic was duplicated in 3 places. Extracting to shared
function ensures consistent validation rules and makes security updates
easier to apply everywhere.
```

**Rule:** Diff shows WHAT. Commit message explains WHY.

### ❌ Committing Without User Request

**Bad:**

```bash
# User asked to implement feature
# You implement it and immediately commit
# User never asked for a commit!
```

**Why bad:** Commits are permanent history. User might want to review first.

**Rule:** Only commit when user explicitly requests it or asks you to "save" work.

### ❌ Including Secrets or Credentials

**Bad:**

```bash
git add .env
git commit -m "add environment config"
```

**Why bad:** Secrets in git history are compromised forever. Even if deleted later, they're in history.

**Rule:** Never commit files like `.env`, `credentials.json`, `*.key`, `secrets.*`. If user insists, warn them first.

## Common Rationalizations (And Why They're Wrong)

| Excuse | Reality |
|--------|---------|
| "The diff is obvious, no need to review" | Obvious changes still hide secrets, debug code, or unintended edits. Review takes 10 seconds. |
| "I'll write a better message later with --amend" | You won't. Later means never. Write it correctly now. |
| "Commit message doesn't matter for small changes" | Small changes become big problems. Every commit deserves context. |
| "Tests will be fixed in next commit" | Never commit broken code. Fix tests first, or don't commit. |
| "Git log shows what changed, message is redundant" | Diff shows WHAT. Message explains WHY. Both are necessary. |
| "Just this once, I'll skip the review" | Security leaks happen "just this once". Review is non-negotiable. |
| "User didn't explicitly say commit, but I think they want it" | Ask. Don't assume. Commits are permanent. |

## Git Safety Protocol

NEVER do these without explicit user request:

- `--force` or `--force-with-lease` (except on your own feature branches)
- `--amend` on commits you didn't author
- `--amend` on commits already pushed to main/master
- Skip hooks with `--no-verify` or `--no-gpg-sign`
- `git reset --hard` (destructive and irreversible)
- `git push --force` to main/master (warn user if they ask)

Git config changes are forbidden:

- Never run `git config` commands
- Never update `.gitconfig` or `.git/config`
- Users control their own git identity

## Template for Commit Messages

Use this as your default structure:

```text
<type>: <summary in imperative mood>

<Why this change was needed>
<What problem it solves>
<Any non-obvious decisions or gotchas>
```

**Good examples:**

```text
feat: add request rate limiting to API endpoints

Without rate limiting, API was vulnerable to abuse. This implements
token bucket algorithm (100 req/min per IP) with Redis backing store
for distributed rate limit tracking across multiple servers.
```

```text
fix: correct timezone handling in report generation

Reports were displaying UTC times regardless of user timezone setting.
Now converts to user's configured timezone before rendering. Fixes
issue #142.
```

```text
refactor: replace nested conditionals with polymorphism (Replace Conditional with Polymorphism pattern)

Payment processor had 4-level nested if-else based on payment type.
Applied Replace Conditional with Polymorphism pattern to create
PaymentMethod interface with concrete implementations. New payment
types now require zero changes to processor.
```

## Verification Before Completion

After committing, always verify:

```bash
git log -1 --stat    # Confirm commit exists with correct files
git status           # Confirm working tree is clean (or shows expected remaining changes)
```

Success criteria:

- Commit appears in log with correct message
- Changed files match your intent
- No unexpected files included
- Working tree state is what you expect

## Key Takeaways

1. **Review diff before committing** - Never commit code you haven't read
2. **Explain WHY, not WHAT** - Diff shows what; message explains why
3. **Follow repository conventions** - Match existing commit style
4. **One logical change per commit** - Multiple files OK if related
5. **Never commit broken code** - Tests must pass
6. **Only commit when requested** - Don't be proactive about commits
7. **Use heredoc for messages** - Ensures proper formatting
8. **Verify after committing** - Confirm it worked as expected

**Remember:** Commits are permanent history. Take 30 seconds to get them right.
