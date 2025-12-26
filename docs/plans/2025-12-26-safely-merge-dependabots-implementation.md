# Safely Merge Dependabots Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement autonomous command that safely analyzes and merges Dependabot PRs

**Architecture:** Command invokes autonomous agent (Opus) that discovers PRs, performs 5-phase analysis, makes merge decisions, and reports results

**Tech Stack:** Claude Code commands/agents, GitHub CLI, git worktrees

**Design Reference:** `docs/plans/2025-12-26-safely-merge-dependabots-design.md`

---

## Task 1: Create Command Definition

**Files:**
- Create: `claude/commands/safely-merge-dependabots.md`

**Step 1: Create command file with metadata and documentation**

Create `claude/commands/safely-merge-dependabots.md`:

```markdown
---
name: safely-merge-dependabots
description: Autonomously analyze and safely merge Dependabot PRs with comprehensive testing
---

# Safely Merge Dependabots Command

Autonomously discover, analyze, and safely merge Dependabot PRs. Uses comprehensive multi-layered analysis to detect breaking changes, runs full test suite, and only merges patch/minor updates that pass all safety checks.

## Arguments

$ARGUMENTS

### Supported Arguments

- **PR numbers** (optional): Space-separated PR numbers to process (e.g., `123 124 125`)
  - If omitted, discovers all open Dependabot PRs
  - Example: `/safely-merge-dependabots 123 124`

- **--dry-run** (optional): Analyze only, don't merge anything
  - Shows what would be merged
  - Example: `/safely-merge-dependabots --dry-run`

- **--timeout <duration>** (optional): Override test timeout (default: 10m)
  - Format: 5m, 10m, 20m, 30m
  - Example: `/safely-merge-dependabots --timeout 20m`

### Argument Parsing

Parse arguments to extract:
- PR numbers: Any numeric arguments
- Dry-run flag: Check for `--dry-run` in arguments
- Timeout: Extract value after `--timeout` flag

## Overview

This command invokes the `dependabot-merger` autonomous agent to:

1. **Discover PRs**: Find all open Dependabot PRs (or use specified PR numbers)
2. **Analyze Each PR**: Run comprehensive 5-phase analysis
   - Semver classification
   - Changelog & breaking change detection
   - Dependency tree impact analysis
   - Test suite execution
   - Security advisory check
3. **Make Decisions**: Auto-merge safe updates, skip risky ones
4. **Report Results**: Detailed summary with merge/skip counts and reasoning

## Safety Policy

**Auto-merge conditions:**
- ✓ PATCH or MINOR version updates only
- ✓ All tests must pass
- ✓ No breaking changes detected
- ✓ No dependency conflicts
- ✓ Security fixes verified (if applicable)

**Always skip (require manual review):**
- ✗ MAJOR version updates
- ✗ Breaking changes detected
- ✗ Test failures
- ✗ Dependency conflicts
- ✗ Missing critical context

## Usage Examples

```bash
# Analyze and merge all safe Dependabot PRs
/safely-merge-dependabots

# Dry-run mode (preview only)
/safely-merge-dependabots --dry-run

# Process specific PRs only
/safely-merge-dependabots 123 124 125

# Override timeout for slow test suites
/safely-merge-dependabots --timeout 30m

# Combine options
/safely-merge-dependabots 123 --dry-run --timeout 20m
```

## Agent Invocation

Invoke the `dependabot-merger` agent with parsed arguments:

```yaml
agent: dependabot-merger
model: opus
context:
  pr_numbers: [extracted PR numbers or empty for discovery]
  dry_run: [true/false based on --dry-run flag]
  timeout: [extracted timeout or "10m" default]
  arguments: "$ARGUMENTS"
```

The agent will:
- Load the `gh-cli` skill for GitHub operations
- Load the `systematic-debugging` skill for test failure diagnosis
- Execute the complete analysis and merge workflow
- Report progress and final results

## Expected Output

```
🔍 Discovering Dependabot PRs...
Found 5 open Dependabot PRs

📦 PR #123: Bump nokogiri from 1.13.0 to 1.13.10
  ├─ Semver: PATCH (safe)
  ├─ Changelog: Reviewing release notes...
  ├─ Breaking changes: None detected ✓
  ├─ Dependencies: No conflicts ✓
  ├─ Tests: Running test suite...
  ├─ Tests: 847 passed in 2m 14s ✓
  ├─ Security: Fixes CVE-2023-XXXX ✓
  └─ Decision: MERGE ✓

...

Summary Report:
✓ Merged: 3 PRs (#123, #456, #789)
⏭️  Skipped: 2 PRs
  - PR #124: Major version (requires manual review)
  - PR #125: Test failures (see details above)

Total time: 8m 43s
```

## Notes

- Agent uses Opus model for deep analysis capabilities
- Each PR analyzed sequentially for safety and clear audit trail
- All decisions logged with detailed reasoning
- Never merges if any safety check fails
```

**Step 2: Verify command file follows naming conventions**

Check against existing commands:
```bash
ls -la claude/commands/
```

Expected: File exists, follows .md convention, has proper frontmatter

**Step 3: Commit command definition**

```bash
git add claude/commands/safely-merge-dependabots.md
git commit -m "feat(claude): add safely-merge-dependabots command definition

Creates user-facing command that invokes dependabot-merger agent to
autonomously analyze and safely merge Dependabot PRs with comprehensive
safety checks."
```

---

## Task 2: Create Autonomous Agent - Part 1 (Setup & Discovery)

**Files:**
- Create: `claude/agents/dependabot-merger.md`

**Step 1: Create agent file with metadata and overview**

Create `claude/agents/dependabot-merger.md`:

```markdown
---
name: dependabot-merger
model: opus
description: Autonomous agent that discovers, analyzes, and safely merges Dependabot PRs using comprehensive multi-layered analysis
skills: gh-cli, systematic-debugging
---

# Dependabot Merger Agent

You are an autonomous agent that safely analyzes and merges Dependabot pull requests. You perform comprehensive multi-layered analysis to detect breaking changes, run full test suites, and only merge updates that pass all safety checks.

**Design Reference:** See `docs/plans/2025-12-26-safely-merge-dependabots-design.md` for complete design

## Agent Workflow

### Prerequisites

Before starting, load required skills:
- Load `gh-cli` skill for GitHub operations
- Load `systematic-debugging` skill for test failure diagnosis

### Phase 0: Parse Input and Initialize

**Extract context from command arguments:**

```bash
# Arguments provided by command in $ARGUMENTS or context
PR_NUMBERS=""        # Space-separated PR numbers (empty = discover all)
DRY_RUN="false"      # true = analyze only, false = merge safe PRs
TIMEOUT="10m"        # Test timeout duration
```

Parse the arguments string to extract:
- PR numbers: Any numeric values
- `--dry-run` flag presence
- `--timeout <value>` value

**Report configuration:**

```
Configuration:
  Mode: [Dry-run / Live merge]
  PR Filter: [All Dependabot PRs / Specific PRs: #123, #124]
  Test Timeout: [10m / custom value]
```

### Phase 1: Discover Dependabot PRs

**Step 1: Fetch open PRs**

```bash
# If specific PR numbers provided
if [ -n "$PR_NUMBERS" ]; then
  # Validate each PR is from Dependabot
  for pr in $PR_NUMBERS; do
    gh pr view $pr --json author,title,number
  done
else
  # Discover all open Dependabot PRs
  gh pr list --author app/dependabot --state open --json number,title,author --limit 100
fi
```

**Step 2: Filter and validate**

- Verify PRs are actually from Dependabot (author: `app/dependabot`)
- Filter out draft PRs
- Sort by PR number (process in order)

**Step 3: Report discovery results**

```
🔍 Discovering Dependabot PRs...
Found 5 open Dependabot PRs:
  - PR #123: Bump nokogiri from 1.13.0 to 1.13.10
  - PR #124: Bump react from 18.2.0 to 19.0.0
  - PR #125: Bump rspec from 3.12.0 to 3.13.0
  - PR #126: Bump eslint from 8.45.0 to 8.46.0
  - PR #127: Bump pytest from 7.3.0 to 7.4.0
```

If no PRs found:
```
🔍 Discovering Dependabot PRs...
No open Dependabot PRs found. Nothing to process.
```

Exit gracefully with success status.

### Phase 2: Process Each PR Sequentially

For each PR in the list:

1. Report starting analysis
2. Execute 5-phase analysis (detailed below)
3. Make merge decision
4. Execute merge (if safe and not dry-run)
5. Report results
6. Continue to next PR (failures don't stop workflow)

```
📦 PR #123: Bump nokogiri from 1.13.0 to 1.13.10
  Processing...
```
```

**Step 2: Commit agent setup and discovery**

```bash
git add claude/agents/dependabot-merger.md
git commit -m "feat(claude): add dependabot-merger agent - setup and PR discovery

Implements Phase 0-2 of agent workflow:
- Argument parsing and configuration
- Dependabot PR discovery via gh CLI
- Sequential processing initialization"
```

---

## Task 3: Create Autonomous Agent - Part 2 (Analysis Phase 1-2)

**Files:**
- Modify: `claude/agents/dependabot-merger.md`

**Step 1: Add Phase 3 - Per-PR Analysis (Semver & Changelog)**

Append to `claude/agents/dependabot-merger.md`:

```markdown
### Phase 3: Five-Phase Analysis Per PR

#### Analysis Phase 1: Semver Classification

**Extract version information from PR title:**

PR titles follow pattern: `Bump <package> from <old> to <new>`

```bash
# Extract old and new versions from PR title
gh pr view $PR_NUMBER --json title
# Parse: "Bump nokogiri from 1.13.0 to 1.13.10"
# OLD: 1.13.0, NEW: 1.13.10
```

**Classify version change:**

Use semantic versioning rules (MAJOR.MINOR.PATCH):
- PATCH: Third number increases (1.13.0 → 1.13.10) - Low risk
- MINOR: Second number increases (1.13.0 → 1.14.0) - Medium risk
- MAJOR: First number increases (1.13.0 → 2.0.0) - High risk

**Decision:**
- MAJOR version → SKIP immediately, report: "Requires manual review for major version update"
- MINOR or PATCH → Continue to next phase

```
  ├─ Semver: PATCH (safe) ✓
  or
  ├─ Semver: MAJOR (requires review)
  └─ Decision: SKIP - Manual review required for major version
```

#### Analysis Phase 2: Changelog & Breaking Change Detection

**Multi-layered analysis to detect breaking changes:**

**Layer 1: Fetch and Parse Changelog**

```bash
# Get PR body which often contains changelog excerpt
gh pr view $PR_NUMBER --json body

# Extract release notes URL if present
# Common patterns:
#   - Release notes: https://github.com/owner/repo/releases/tag/vX.Y.Z
#   - Changelog: https://github.com/owner/repo/blob/master/CHANGELOG.md
```

**Layer 2: Keyword Analysis**

Search changelog/release notes for breaking change indicators:

**High-severity keywords (immediate SKIP):**
- "BREAKING CHANGE"
- "BREAKING:"
- "breaking change"
- "backwards incompatible"
- "not backwards compatible"
- "Migration guide"
- "Upgrading from"

**Medium-severity keywords (extra scrutiny):**
- "removed"
- "deprecated"
- "no longer"
- "replaced"
- "renamed"
- "changed behavior"

**Context matters:**
- "removed deprecated feature" → Breaking if you use that feature
- "removed internal method" → Likely safe (internal API)
- "fixed bug in X" → Safe (bug fixes are usually safe)

**Layer 3: API Surface Analysis**

For the dependency, check what changed:

```bash
# Get the diff of the PR to see what files changed in YOUR project
gh pr diff $PR_NUMBER

# Common safe changes:
# - Lockfile only (Gemfile.lock, package-lock.json, yarn.lock)
# - Version constraint only (Gemfile, package.json)

# Risky changes:
# - Code changes alongside dependency update (might be adapting to breaking change)
# - Multiple dependency updates in one PR (complex to analyze)
```

**Layer 4: Community Signals**

```bash
# Check PR comments for warnings
gh pr view $PR_NUMBER --json comments

# Look for:
# - Other users reporting issues
# - Bot warnings about breaking changes
# - Failed CI checks with error messages
```

**Risk Scoring:**

Combine all signals:
- High-severity keyword found → HIGH RISK → SKIP
- Medium-severity keyword + MINOR version → MEDIUM RISK → Extra scrutiny
- Clean changelog + PATCH version → LOW RISK → Continue
- No changelog found + MINOR/MAJOR → SKIP (missing context)

**Report:**

```
  ├─ Changelog: Reviewing release notes...
  ├─ Breaking changes: None detected ✓
  or
  ├─ Breaking changes: DETECTED - "removed deprecated API" ✗
  └─ Decision: SKIP - Breaking changes detected
```
```

**Step 2: Commit analysis phases 1-2**

```bash
git add claude/agents/dependabot-merger.md
git commit -m "feat(claude): add semver classification and changelog analysis

Implements Analysis Phase 1-2:
- Semver classification (MAJOR/MINOR/PATCH)
- Multi-layered breaking change detection
- Risk scoring based on changelog and community signals"
```

---

## Task 4: Create Autonomous Agent - Part 3 (Analysis Phase 3-5)

**Files:**
- Modify: `claude/agents/dependabot-merger.md`

**Step 1: Add Analysis Phase 3 - Dependency Tree Check**

Append to `claude/agents/dependabot-merger.md`:

```markdown
#### Analysis Phase 3: Dependency Tree Impact

**Build project context first (if not already done):**

Understand the project structure:
- What's the package manager? (Gemfile→Bundler, package.json→npm/yarn, requirements.txt→pip, etc.)
- Where are dependency files?
- Are there lockfiles?

**Run dependency analysis:**

Execute package-manager-specific commands:

**Ruby/Bundler:**
```bash
# Check for dependency conflicts
bundle check

# Run security audit
bundle audit check
```

**Node/npm:**
```bash
# Check for dependency conflicts
npm ls <package-name>

# Run security audit
npm audit
```

**Node/Yarn:**
```bash
# Check for dependency conflicts
yarn why <package-name>

# Run security audit
yarn audit
```

**Python/pip:**
```bash
# Check if dependencies resolve
pip check

# Try installing in isolated environment
pip install -r requirements.txt --dry-run
```

**Evaluate results:**
- No conflicts → Continue ✓
- Conflicts detected → SKIP with details
- Security vulnerabilities in other deps → Report but continue (this PR might fix them)

**Report:**

```
  ├─ Dependencies: No conflicts ✓
  or
  ├─ Dependencies: Conflicts detected ✗
  │  └─ Package X requires Y < 2.0, but this update brings Y 2.1
  └─ Decision: SKIP - Dependency conflicts
```

#### Analysis Phase 4: Test Suite Execution

**This is the most critical phase. Use git worktree for isolation.**

**Step 1: Build project context**

If not already done, understand:
- Project structure (source, tests, configs)
- Programming language(s)
- Testing framework
- How to run tests

**Discovery strategy:**

1. **Check CI configuration** (source of truth):
   ```bash
   # GitHub Actions
   cat .github/workflows/*.yml | grep -A 10 "test"

   # Circle CI
   cat .circleci/config.yml | grep -A 10 "test"

   # Travis CI
   cat .travis.yml | grep -A 10 "script"
   ```

2. **Check documentation:**
   ```bash
   # README usually documents test commands
   grep -i "test\|running\|development" README.md

   # CONTRIBUTING guide
   grep -i "test" CONTRIBUTING.md
   ```

3. **Check for automation scripts:**
   ```bash
   # Common locations
   ls -la bin/ script/ scripts/ | grep -i test

   # Common names: test, test.sh, run_tests, etc.
   ```

4. **Check package manager scripts:**
   - `package.json` → `scripts.test`
   - `Gemfile` + `Rakefile` → `rake -T` (list tasks)
   - `Makefile` → `make help` or `cat Makefile | grep test`
   - `pyproject.toml` → test command config

5. **Fall back to framework defaults:**
   - Ruby: `rspec` or `rake test` or `ruby -Itest test/**/*_test.rb`
   - Node: `npm test` or `jest` or `mocha`
   - Python: `pytest` or `python -m unittest`
   - Go: `go test ./...`

**Step 2: Create isolated test environment**

```bash
# Create worktree for isolated testing
WORKTREE_PATH=".worktrees/pr-$PR_NUMBER-test"
git worktree add "$WORKTREE_PATH" "pull/$PR_NUMBER/head"
cd "$WORKTREE_PATH"
```

**Step 3: Install dependencies**

Based on package manager:
- Bundler: `bundle install`
- npm: `npm install`
- yarn: `yarn install`
- pip: `pip install -r requirements.txt`
- poetry: `poetry install`

**Step 4: Run tests with timeout**

```bash
# Use timeout command with configured duration
timeout $TIMEOUT <test-command>

# Capture exit code
EXIT_CODE=$?
```

**Step 5: Parse results**

- Exit code 0 → Tests passed ✓
- Exit code 124 → Timeout (tests too slow or hanging)
- Other exit codes → Tests failed

**If tests fail:**
- Use `systematic-debugging` skill to diagnose
- Capture test output
- Parse for specific failures
- Report findings
- SKIP merge

**Step 6: Clean up worktree**

```bash
cd ../..  # Back to main worktree
git worktree remove "$WORKTREE_PATH" --force
```

**Report:**

```
  ├─ Tests: Running test suite...
  ├─ Tests: 847 passed in 2m 14s ✓
  or
  ├─ Tests: FAILED - 3 failures ✗
  │  └─ test_user_authentication: Expected true, got false
  │  └─ test_data_validation: NoMethodError: undefined method 'validate'
  │  └─ test_edge_case: ArgumentError: wrong number of arguments
  └─ Decision: SKIP - Test failures detected
```

#### Analysis Phase 5: Security Advisory Check

**Check if PR addresses security vulnerability:**

```bash
# PR body often mentions security
gh pr view $PR_NUMBER --json body | grep -i "security\|CVE\|vulnerability"

# Check GitHub security advisories for the package
# This info is usually in Dependabot PR description
```

**If security fix:**
- Note in report: "Fixes CVE-XXXX-YYYY"
- Increases priority (security patches should merge ASAP)
- Does not override other safety checks (tests must still pass)

**Report:**

```
  ├─ Security: Fixes CVE-2023-12345 ✓
  or
  ├─ Security: No security advisories
```
```

**Step 2: Commit analysis phases 3-5**

```bash
git add claude/agents/dependabot-merger.md
git commit -m "feat(claude): add dependency, testing, and security analysis phases

Implements Analysis Phase 3-5:
- Dependency tree conflict detection
- Context-aware test execution with git worktree isolation
- Security advisory verification"
```

---

## Task 5: Create Autonomous Agent - Part 4 (Decision & Merge)

**Files:**
- Modify: `claude/agents/dependabot-merger.md`

**Step 1: Add decision logic and merge execution**

Append to `claude/agents/dependabot-merger.md`:

```markdown
### Phase 4: Make Merge Decision

**Evaluate all analysis results:**

Decision tree:
1. Is it a MAJOR version? → SKIP
2. Are breaking changes detected? → SKIP
3. Are there dependency conflicts? → SKIP
4. Did tests fail? → SKIP
5. All checks passed? → MERGE (if not dry-run)

**Report decision:**

```
  └─ Decision: MERGE ✓
  or
  └─ Decision: SKIP - <reason>
```

**Create decision record:**

Track for final summary:
```javascript
{
  pr_number: 123,
  title: "Bump nokogiri from 1.13.0 to 1.13.10",
  decision: "merge" | "skip",
  reason: "All checks passed" | "Major version update" | "Test failures" | etc,
  semver: "PATCH" | "MINOR" | "MAJOR",
  breaking_changes: true | false,
  tests_passed: true | false,
  security_fix: true | false
}
```

### Phase 5: Execute Merge (If Approved)

**Only if:**
- Decision is MERGE
- DRY_RUN is false

**Detect merge strategy from repository:**

```bash
# Check repo settings for preferred merge method
gh repo view --json defaultMergeMethod

# Common strategies:
# - SQUASH: Squash all commits into one
# - MERGE: Create merge commit
# - REBASE: Rebase and fast-forward
```

**Execute merge:**

```bash
# Use detected or default strategy (squash is safest for Dependabot)
gh pr merge $PR_NUMBER --squash --auto

# Or if repo prefers merge commits:
gh pr merge $PR_NUMBER --merge --auto

# The --auto flag waits for required checks if they're still running
```

**Handle merge errors:**

If merge fails:
- Capture error message
- Report clearly
- Mark as SKIP in final summary
- Continue to next PR

**Report:**

```
  └─ Action: Merged successfully ✓
  or
  └─ Action: Merge failed - <error message>
  or
  └─ Action: Would merge (dry-run mode)
```

### Phase 6: Report Results and Continue

**After each PR:**

1. Add result to summary tracking
2. Print blank line for readability
3. Continue to next PR

**Don't stop on failures:**
- One PR failure doesn't affect others
- Process all PRs in the list
- Collect all results for final summary

```

**Step 2: Commit decision and merge logic**

```bash
git add claude/agents/dependabot-merger.md
git commit -m "feat(claude): add merge decision logic and execution

Implements Phase 4-5:
- Decision tree based on all analysis results
- Merge strategy detection from repository settings
- Merge execution with error handling
- Per-PR result tracking"
```

---

## Task 6: Create Autonomous Agent - Part 5 (Error Handling & Reporting)

**Files:**
- Modify: `claude/agents/dependabot-merger.md`

**Step 1: Add error handling and final reporting**

Append to `claude/agents/dependabot-merger.md`:

```markdown
### Phase 7: Error Handling Strategy

**Failure isolation principles:**

1. **Each PR is independent** - One failure doesn't stop workflow
2. **Fail safely** - Errors always result in SKIP, never in bad merge
3. **Log everything** - All errors captured with context
4. **Graceful degradation** - Missing info increases scrutiny, doesn't crash

**Error categories and responses:**

**GitHub API errors:**
```
Error: Rate limit exceeded
Response: Report clearly, show reset time, suggest retry
Action: Stop processing (can't continue without API)
```

**Git errors:**
```
Error: Worktree creation failed
Response: Report error, skip PR, continue to next
Action: Clean up any partial worktree, continue
```

**Test errors:**
```
Error: Test command not found
Response: Report unable to verify tests, SKIP for safety
Action: Continue to next PR
```

**Timeout errors:**
```
Error: Tests exceeded timeout
Response: Report timeout, SKIP (might be hanging)
Action: Kill test process, clean up worktree, continue
```

**Network errors:**
```
Error: Failed to fetch changelog
Response: Note missing changelog, increase scrutiny
Action: Continue analysis with available info
```

**Dependency install errors:**
```
Error: Bundle install failed
Response: Report error, SKIP (can't run tests without deps)
Action: Clean up worktree, continue to next PR
```

**Merge errors:**
```
Error: PR has conflicts
Response: Report conflicts, SKIP, suggest manual resolution
Action: Continue to next PR
```

**Retry strategy:**

- Network errors: Retry up to 3 times with exponential backoff
- GitHub API rate limit: Stop and report (can't continue)
- All other errors: No retry, fail safely, continue

### Phase 8: Final Summary Report

**After processing all PRs, generate comprehensive summary:**

**Structure:**

```
═══════════════════════════════════════════════════════════
SUMMARY: Dependabot PR Analysis Complete
═══════════════════════════════════════════════════════════

Processed: 5 PRs
✓ Merged: 3 PRs
⏭️  Skipped: 2 PRs

───────────────────────────────────────────────────────────
MERGED PRs:
───────────────────────────────────────────────────────────

✓ PR #123: Bump nokogiri from 1.13.0 to 1.13.10
  • Semver: PATCH
  • Security: Fixes CVE-2023-12345
  • Tests: 847 passed in 2m 14s
  • Merged: Yes

✓ PR #126: Bump eslint from 8.45.0 to 8.46.0
  • Semver: MINOR
  • Breaking changes: None detected
  • Tests: 234 passed in 45s
  • Merged: Yes

✓ PR #127: Bump pytest from 7.3.0 to 7.4.0
  • Semver: MINOR
  • Breaking changes: None detected
  • Tests: 156 passed in 1m 32s
  • Merged: Yes

───────────────────────────────────────────────────────────
SKIPPED PRs:
───────────────────────────────────────────────────────────

⏭️  PR #124: Bump react from 18.2.0 to 19.0.0
  • Reason: Major version update
  • Recommendation: Review manually for breaking changes
  • Link: https://github.com/owner/repo/pull/124

⏭️  PR #125: Bump rspec from 3.12.0 to 3.13.0
  • Reason: Test failures (3 failures)
  • Tests: 244 passed, 3 failed in 2m 8s
  • Failures:
    - test_user_authentication
    - test_data_validation
    - test_edge_case
  • Recommendation: Investigate test failures before merging
  • Link: https://github.com/owner/repo/pull/125

───────────────────────────────────────────────────────────
NEXT ACTIONS:
───────────────────────────────────────────────────────────

1. Review PR #124 manually (major version update)
2. Fix test failures in PR #125 and re-run analysis
3. Monitor merged PRs for issues in production

───────────────────────────────────────────────────────────
Total time: 8m 43s
Mode: [Live merge / Dry-run]
───────────────────────────────────────────────────────────
```

**Include in summary:**
- Total PRs processed
- Count of merged vs skipped
- Details for each merged PR (version, security, test results)
- Details for each skipped PR (reason, recommendation, link)
- Next actions for the user
- Total execution time
- Mode (dry-run or live)

**If dry-run mode:**
```
NOTE: Dry-run mode - No PRs were actually merged.
To merge, run: /safely-merge-dependabots
```

### Agent Completion

**Report completion:**

```
Agent execution complete. Summary report above.
```

**Exit status:**
- Success: Even if some PRs skipped (that's expected behavior)
- Failure: Only if agent couldn't execute at all (GitHub API unavailable, etc.)

## Agent Guidelines

**Communication style:**
- Use emoji for visual progress (🔍 📦 ✓ ✗)
- Progress updates after each phase
- Clear decision reasoning
- Technical details without overwhelming

**Autonomous operation:**
- No user prompts during execution
- Make decisions based on defined criteria
- Report progress clearly
- Only stop if critical error (GitHub API down, etc.)

**Safety first:**
- When in doubt, SKIP (fail safe)
- Never merge if any check fails
- All decisions logged and auditable
- Dry-run mode for risk-free preview

**Performance:**
- Process PRs sequentially (not parallel)
- Clean up resources (worktrees) after each PR
- Timeout protection on tests
- Efficient Git operations

## Skills Integration

**Use `gh-cli` skill for:**
- All GitHub PR operations
- Repository settings queries
- PR viewing, diffing, merging

**Use `systematic-debugging` skill for:**
- Diagnosing test failures
- Parsing test output
- Identifying root causes

**Never:**
- Merge without running tests
- Merge major version updates
- Merge with failing tests
- Skip safety checks
- Proceed with missing critical context
```

**Step 2: Commit error handling and reporting**

```bash
git add claude/agents/dependabot-merger.md
git commit -m "feat(claude): add error handling and final reporting

Implements Phase 7-8:
- Comprehensive error handling for all failure modes
- Failure isolation strategy
- Final summary report with merged and skipped PRs
- Next actions and recommendations"
```

---

## Task 7: Update Dotfiles Configuration

**Files:**
- Read: `dotfiles.yaml`

**Step 1: Check if claude/ symlinks are already configured**

```bash
cat dotfiles.yaml | grep -A 20 "symlinks:" | grep claude
```

**Step 2: If not present, add claude symlinks**

If `claude/commands` and `claude/agents` are not symlinked, they need to be added to `dotfiles.yaml`:

```yaml
symlinks:
  # ... existing symlinks ...

  # Claude Code configuration
  - path: claude
    target: ~/.claude
    recursive: true
```

If already configured, skip this step.

**Step 3: If modified, commit the change**

```bash
# Only if dotfiles.yaml was modified
git add dotfiles.yaml
git commit -m "feat(dotfiles): ensure claude directory is symlinked

Adds claude directory symlink to ensure commands and agents are
available to Claude Code."
```

---

## Task 8: Test Command Manually

**Files:**
- Test: `claude/commands/safely-merge-dependabots.md`
- Test: `claude/agents/dependabot-merger.md`

**Step 1: Verify files are in place**

```bash
ls -la claude/commands/safely-merge-dependabots.md
ls -la claude/agents/dependabot-merger.md
```

Expected: Both files exist

**Step 2: Check command syntax**

```bash
# Verify frontmatter is valid YAML
head -5 claude/commands/safely-merge-dependabots.md
head -5 claude/agents/dependabot-merger.md
```

Expected: Valid YAML frontmatter with name, description, model

**Step 3: Verify markdown formatting**

```bash
# Check for common markdown issues
# (If markdown-quality skill is available, use it)

# Manual check:
cat claude/commands/safely-merge-dependabots.md | grep -E "^#{1,6} " | head
cat claude/agents/dependabot-merger.md | grep -E "^#{1,6} " | head
```

Expected: Proper heading hierarchy

**Step 4: Manual integration test (if in a repo with Dependabot PRs)**

If you have access to a repository with Dependabot PRs:

```bash
# Try dry-run mode first
/safely-merge-dependabots --dry-run
```

Expected: Agent executes, discovers PRs, analyzes, reports (no actual merges)

If successful, note in commit message. If not available, note that testing should be done in a target repository.

**Step 5: Document testing status**

Create a note about testing:

```bash
git add -A
git commit -m "feat(claude): complete safely-merge-dependabots implementation

Implements complete autonomous Dependabot PR merger:

Components created:
- Command: claude/commands/safely-merge-dependabots.md
- Agent: claude/agents/dependabot-merger.md

Features:
- Auto-discovery of Dependabot PRs via gh CLI
- 5-phase comprehensive analysis:
  1. Semver classification
  2. Breaking change detection (multi-layered)
  3. Dependency tree impact analysis
  4. Context-aware test execution
  5. Security advisory verification
- Conservative merge policy (patch/minor only)
- Failure isolation and error handling
- Comprehensive final reporting

Safety rails:
- Never merges major versions
- Never merges with test failures
- Never merges with breaking changes
- Git worktree isolation for testing
- Dry-run mode for preview

Testing: Ready for integration testing in target repositories with
Dependabot PRs. Use --dry-run flag for risk-free initial testing."
```

---

## Task 9: Update Documentation

**Files:**
- Modify: `claude/CLAUDE.md` (or appropriate project documentation)

**Step 1: Add command to documentation**

If there's a section listing Claude commands, add entry:

```markdown
### Available Commands

...

#### /safely-merge-dependabots

Autonomously analyze and safely merge Dependabot PRs with comprehensive testing.

- Discovers all open Dependabot PRs
- Performs 5-phase analysis (semver, breaking changes, dependencies, tests, security)
- Auto-merges safe patch/minor updates
- Skips risky changes with detailed reasoning
- Supports dry-run mode and custom timeouts

Usage:
- `/safely-merge-dependabots` - Process all Dependabot PRs
- `/safely-merge-dependabots --dry-run` - Preview without merging
- `/safely-merge-dependabots 123 124` - Process specific PRs
- `/safely-merge-dependabots --timeout 20m` - Override test timeout

See: `claude/commands/safely-merge-dependabots.md` for full documentation
```

**Step 2: Commit documentation update**

```bash
git add claude/CLAUDE.md  # or appropriate file
git commit -m "docs(claude): document safely-merge-dependabots command

Adds documentation for the new autonomous Dependabot PR merger command
to the project's Claude Code command reference."
```

---

## Task 10: Final Verification and Cleanup

**Files:**
- Review: All created files

**Step 1: Review all commits**

```bash
git log --oneline feature/safely-merge-dependabots ^main
```

Expected: Clean commit history with descriptive messages

**Step 2: Verify all files are committed**

```bash
git status
```

Expected: Clean working tree

**Step 3: Review file structure**

```bash
ls -la claude/commands/safely-merge-dependabots.md
ls -la claude/agents/dependabot-merger.md
cat docs/plans/2025-12-26-safely-merge-dependabots-design.md | head -20
cat docs/plans/2025-12-26-safely-merge-dependabots-implementation.md | head -20
```

Expected: All files exist and are well-formed

**Step 4: Create summary of implementation**

Document what was built:

```
Implementation complete:

Files created:
1. claude/commands/safely-merge-dependabots.md (command definition)
2. claude/agents/dependabot-merger.md (autonomous agent)
3. docs/plans/2025-12-26-safely-merge-dependabots-design.md (design doc)
4. docs/plans/2025-12-26-safely-merge-dependabots-implementation.md (this plan)

Features implemented:
✓ PR discovery (auto or specific PRs)
✓ 5-phase comprehensive analysis
✓ Multi-layered breaking change detection
✓ Context-aware test execution
✓ Conservative merge policy
✓ Comprehensive error handling
✓ Detailed final reporting
✓ Dry-run mode
✓ Custom timeout support

Ready for:
- Integration testing in repositories with Dependabot PRs
- Dry-run testing for safe evaluation
- Production use with conservative merge policy

Next steps:
1. Test in a repository with open Dependabot PRs
2. Start with --dry-run mode to validate behavior
3. Review first few merge decisions carefully
4. Adjust timeout if project has slow test suites
```

---

## Implementation Complete

All tasks completed. The `/safely-merge-dependabots` command is ready for use.

**Testing recommendations:**
1. Find a repository with Dependabot PRs (or create test PRs)
2. Run `/safely-merge-dependabots --dry-run` first
3. Review the analysis and decisions
4. If satisfied, run `/safely-merge-dependabots` for real merges
5. Monitor first few merges closely

**Rollout strategy:**
1. Test in low-risk personal projects first
2. Test with patch updates only
3. Gradually trust with minor updates
4. Never allow major updates (by design)
5. Build confidence over multiple successful merges
