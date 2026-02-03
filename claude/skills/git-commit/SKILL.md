---
name: git-commit
description: Commit with clear messages explaining WHY, following repository conventions
---

# Git Commit

## Iron Law

- **NO COMMITS WITHOUT REVIEWING GIT DIFF FIRST**
- **NO COMMIT MESSAGES WITHOUT EXPLAINING WHY**
- **ONLY COMMIT WHEN USER EXPLICITLY REQUESTS**

## Process

### 1. Gather Context (parallel)

```bash
git status                    # Staged/unstaged files
git diff                      # Unstaged changes
git diff --staged             # Staged changes
git log --oneline -5          # Recent commit style
```

### 2. Review Changes

- Understand every change in diff
- No secrets (.env, credentials, keys)
- No debug code, console.logs
- Related changes only (one logical unit)

### 3. Stage and Commit

```bash
git add path/to/file1 path/to/file2

git commit -m "$(cat <<'EOF'
feat: add user authentication middleware

Previous implementation left API endpoints unprotected. Adds JWT
validation middleware ensuring only authenticated requests reach
protected endpoints.
EOF
)"
```

### 4. Verify

```bash
git status        # Working tree state
git log -1 --stat # Confirm commit
```

## Message Format

```text
<type>: <subject - imperative mood, 50 chars>

<body - explain WHY, wrap at 72 chars>
```

**Types:** `feat:` `fix:` `refactor:` `docs:` `test:` `chore:`

**Subject:** Imperative mood ("Add" not "Added"), no period, ≤50 chars

**Body:** Explain WHY, what problem it solves, non-obvious decisions

## Pre-commit Hook Changes

If hooks modify files:

1. Check authorship: `git log -1 --format='%an %ae'`
2. Check not pushed: `git status` shows "ahead"
3. If both true: `git add <files> && git commit --amend --no-edit`
4. Otherwise: Create NEW commit

## Safety Rules

**Never without explicit request:**

- `--force`, `--force-with-lease`
- `--amend` on others' commits or pushed commits
- `--no-verify`, `--no-gpg-sign`
- `git reset --hard`
- `git config` changes

**Never commit:**

- `.env`, credentials, secrets, keys
- Broken code (tests must pass)
- Unrelated changes mixed together

## Examples

```text
fix: prevent race condition in session creation

Sessions were created before user validation completed, allowing
invalid users to briefly access protected resources. Moves session
creation to after validation succeeds.
```

```text
refactor: extract validation using Replace Conditional with Polymorphism

Payment processor had 4-level nested conditionals. Applied Fowler's
pattern to create PaymentMethod interface. New payment types now
require zero changes to processor.
```

## Key Takeaways

1. **Review diff before committing** - Never commit unread code
2. **Explain WHY, not WHAT** - Diff shows what; message explains why
3. **One logical change per commit** - Multiple files OK if related
4. **Only commit when requested** - Don't be proactive
5. **Use heredoc for messages** - Ensures proper formatting
