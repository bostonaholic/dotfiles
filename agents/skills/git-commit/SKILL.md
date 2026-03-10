---
name: git-commit
description: >-
  This skill should be used when the user asks to "commit changes", "create a
  commit", "git commit", "commit my work", or when committing code changes.
  Follows the 50/72 rule, conventional commits, and atomic commit principles.
---

# Git Commit

## Iron Laws

- **NO COMMITS WITHOUT REVIEWING GIT DIFF FIRST**
- **NO COMMIT MESSAGES WITHOUT EXPLAINING WHY**
- **ONLY COMMIT WHEN USER EXPLICITLY REQUESTS**
- **NEVER BREAK THE BUILD** - Every commit must leave the project in a working state

## Process

### 1. Gather Context (parallel)

```bash
git status                    # Staged/unstaged files
git diff                      # Unstaged changes
git diff --staged             # Staged changes
git log --oneline -5          # Recent commit style
```

### 2. Review Changes

- Understand every change in the diff
- No secrets (.env, credentials, API keys)
- No debug code or console.logs
- No generated files (binaries, node_modules, build artifacts)
- Related changes only (one logical unit)
- Verify tests pass and linting is clean before committing

### 3. Stage and Commit

Stage specific files by name. Avoid `git add -A` or `git add .` unless the user
explicitly requests it, as these risk including sensitive or generated files.

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

## The 50/72 Rule

```text
<type>[scope]: <subject>               ← 50 chars max
                                        ← blank line (required)
<body - explain WHY, wrap at 72 chars>  ← 72 chars per line
```

The subject line appears in `git log --oneline`, GitHub PR lists, and email
notifications. 50 characters keeps it readable everywhere. Wrapping the body
at 72 characters prevents awkward line breaks in terminals and `git log`.

### Subject Line

- **Imperative mood:** "Add" not "Added" or "Adds"
- **Litmus test:** "If applied, this commit will _[your subject]_"
- **No trailing period**
- **50 characters max** (type prefix counts toward the limit)
- **Capitalize** first word after the type prefix

### Body

- **Blank line** between subject and body (required - omitting it breaks tooling)
- **Explain WHY, not WHAT** - the diff shows what changed; the message explains reasoning
- **Wrap at 72 characters** per line
- Include what problem this solves, non-obvious decisions, and tradeoffs

## Conventional Commit Types

| Type | Purpose |
| ----------- | ----------------------------------------- |
| `feat:` | New feature |
| `fix:` | Bug fix |
| `refactor:` | Code restructuring (no behavior change) |
| `docs:` | Documentation only |
| `test:` | Adding or updating tests |
| `chore:` | Maintenance, dependencies, tooling |
| `style:` | Formatting, whitespace (no logic change) |
| `perf:` | Performance improvement |
| `ci:` | CI/CD pipeline changes |
| `build:` | Build system or external dependencies |

**Optional scope:** `feat(auth):`, `fix(api):` narrows the area of change.

**Breaking changes:** Append `!` after type — `feat!: remove legacy auth` — or
include `BREAKING CHANGE:` in the body footer.

## Atomic Commits

Each commit represents **one logical change**:

- **Single responsibility** - One bug fix OR one feature, never both
- **Never break the build** - Every commit must compile and pass tests, keeping `git bisect` effective
- **Multiple files are fine** when they serve the same logical change
- **Split unrelated changes** into separate commits

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

- `.env`, credentials, secrets, API keys
- Generated files (binaries, `node_modules/`, build output)
- Broken code (run tests and linting first)
- Unrelated changes mixed together

## Repository Hygiene

- **Maintain `.gitignore`** - Generated files, build artifacts, and secrets must be excluded
- **Test before committing** - Run tests and linting locally to catch errors before they enter history
- **Review staged files** - Confirm only intended files are staged before committing

## Examples

```text
fix: prevent race condition in session creation

Sessions were created before user validation completed, allowing
invalid users to briefly access protected resources. Moves session
creation to after validation succeeds.
```

```text
refactor: extract validation with Replace Conditional with Polymorphism

Payment processor had 4-level nested conditionals. Applied Fowler's
pattern to create PaymentMethod interface. New payment types now
require zero changes to processor.
```

```text
feat!: replace OAuth1 with OAuth2 authentication

OAuth1 library is unmaintained with known CVEs. OAuth2 simplifies
the token refresh flow and aligns with the upstream provider
deprecation timeline. Existing tokens invalidated on deploy.

BREAKING CHANGE: All API clients must re-authenticate after deploy.
```

## Key Takeaways

1. **Review diff before committing** - Never commit unread code
2. **Explain WHY, not WHAT** - Diff shows what; message explains why
3. **50/72 rule** - Subject ≤50 chars, body wrapped at 72
4. **Imperative mood** - "If applied, this commit will [subject]"
5. **One logical change per commit** - Atomic, never breaks the build
6. **Test before committing** - Run tests and linting first
7. **Only commit when requested** - Don't be proactive
8. **Use heredoc for messages** - Ensures proper formatting
