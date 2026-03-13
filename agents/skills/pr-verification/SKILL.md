---
name: pr-verification
description: "Use when verifying pull requests by checking out code in an isolated git worktree, running the full test suite, and reporting results."
---

# PR Verification

Verify pull requests by running the full test suite in an isolated git
worktree. This prevents interference with your working directory and
enables parallel verification of multiple PRs.

## Workflow

```text
1. CREATE   — Set up an isolated git worktree for the PR
2. INSTALL  — Install dependencies in the worktree
3. TEST     — Run the full test suite
4. REPORT   — Report results with pass/fail status
5. CLEANUP  — Remove the worktree and tracking branch
```

## Step Details

### 1. Create Isolated Worktree

```bash
# Manually create a worktree for the PR branch
wt add <branch>
```

When using Claude Code's `isolation: "worktree"` for agents, the worktree
is created automatically.

### 2. Install Dependencies

Detect the package manager and install:

```bash
# Node.js projects
[ -f package-lock.json ] && npm ci
[ -f yarn.lock ] && yarn install --frozen-lockfile
[ -f pnpm-lock.yaml ] && pnpm install --frozen-lockfile
[ -f bun.lockb ] && bun install

# Ruby projects
[ -f Gemfile.lock ] && bundle install

# Copy .env files if needed (worktrees don't inherit them)
[ -f ../.env ] && cp ../.env .env
```

### 3. Run Tests

Run the project's full test suite:

```bash
# Detect and run appropriate test command
npm test              # Node.js
bundle exec rspec     # Ruby/RSpec
bundle exec rails test  # Rails
pytest                # Python
go test ./...         # Go
```

Include linting and type checking if available:

```bash
npm run lint          # Linting
npm run typecheck     # TypeScript type checking
npx playwright test   # E2E tests (if applicable)
```

### 4. Report Results

Always report results as a structured summary:

```text
PR #<number>: <title>
Branch: <branch-name>
Tests: PASS/FAIL (<count> passed, <count> failed)
Lint: PASS/FAIL
Types: PASS/FAIL
Duration: <time>
```

If tests fail, include the specific failure output.

### 5. Cleanup

```bash
cd -
git worktree remove /tmp/pr-<PR_NUMBER>
# Remove auto-created tracking branch if applicable
git branch -D <tracking-branch> 2>/dev/null
```

## Parallel Verification

When verifying multiple PRs, use parallel agents with isolated worktrees:

```yaml
# Each agent gets its own worktree via isolation: "worktree"
Agent 1: PR #123 → /tmp/pr-123
Agent 2: PR #124 → /tmp/pr-124
Agent 3: PR #125 → /tmp/pr-125
```

After all agents complete, present results as a summary table:

| PR | Title | Tests | Lint | Types | Verdict |
| -- | ----- | ----- | ---- | ----- | ------- |

## Environment Caveats

- **Husky hooks** may not be available in worktrees — this is expected
- **`.env` files** must be copied from the main worktree
- **Lock files** must exist for deterministic installs (`npm ci` vs
  `npm install`)
- **Tracking branches** created by `gh pr checkout` should be cleaned up
  after verification

## Anti-Patterns

| Do Not | Instead |
| ------ | ------- |
| Test PRs in your working directory | Use an isolated worktree |
| Skip dependency installation | Always run a clean install |
| Merge without running full test suite | Run all tests, lint, and type checks |
| Leave worktrees after verification | Clean up worktrees and tracking branches |
| Verify PRs sequentially when independent | Use parallel agents with worktree isolation |
