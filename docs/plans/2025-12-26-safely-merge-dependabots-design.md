# Safely Merge Dependabots - Design Document

**Date:** 2025-12-26
**Command:** `/safely-merge-dependabots`
**Purpose:** Autonomous analysis and safe merging of Dependabot PRs

## Overview

An autonomous Claude Code command that discovers open Dependabot PRs, deeply analyzes them for breaking changes and safety, runs comprehensive tests, and automatically merges safe updates while flagging risky ones for manual review.

## Design Principles

- **Fail Safe:** Never merge if any safety check fails
- **Context-Aware:** Adapt to any project structure without hardcoded assumptions
- **Comprehensive Analysis:** Multiple layers of breaking change detection
- **Sequential Processing:** Process PRs one at a time in dependency order
- **Transparent Reporting:** Clear progress updates and detailed final report

## Architecture

### Component 1: Command (`/safely-merge-dependabots`)

User-facing entry point that:

- Triggers the autonomous agent
- Accepts optional arguments:
  - Specific PR numbers: `/safely-merge-dependabots 123 124`
  - Dry-run mode: `/safely-merge-dependabots --dry-run`
  - Timeout override: `/safely-merge-dependabots --timeout 20m`
- Sets context for the agent

### Component 2: Autonomous Agent (`dependabot-merger`)

Core orchestrator that:

- Discovers all open Dependabot PRs via `gh pr list`
- Processes each PR sequentially
- Leverages existing skills (gh-cli, systematic-debugging)
- Makes merge decisions based on comprehensive analysis
- Reports results with clear summary
- Uses Opus model for deep analysis capabilities

### Component 3: Analysis Workflow

Five-phase analysis per PR:

1. **Semver Classification** - Identify patch/minor/major updates
2. **Changelog & Breaking Change Detection** - Multi-layered analysis
3. **Dependency Tree Impact** - Check for conflicts and transitive issues
4. **Test Suite Execution** - Context-aware test running with failure diagnosis
5. **Security Advisory Check** - Verify security fixes via GitHub

## Merge Policy

**Conservative approach for patch/minor updates:**

- **Auto-merge conditions:**
  - Semver: PATCH or MINOR version only
  - Tests: All tests must pass
  - Changelog: No breaking changes detected
  - Dependencies: No conflicts in dependency tree
  - Security: If security fix, verify it's properly applied

- **Always skip (require manual review):**
  - MAJOR version updates
  - Breaking changes detected in any layer
  - Test failures
  - Dependency conflicts
  - Missing critical context (no changelog AND major/minor update)

## Decision Logic

```text
For each Dependabot PR:
├─ Is it a major version update?
│  └─ YES → SKIP (report: "Requires manual review")
│  └─ NO → Continue to analysis
│
├─ Phase 1: Changelog Analysis
│  ├─ Fetch release notes from GitHub
│  ├─ Search for breaking change indicators
│  └─ BREAKING DETECTED → SKIP (report findings)
│  └─ CLEAN → Continue
│
├─ Phase 2: Dependency Tree Check
│  ├─ Run package manager's dependency analysis
│  └─ CONFLICTS FOUND → SKIP (report conflicts)
│  └─ CLEAN → Continue
│
├─ Phase 3: Test Execution
│  ├─ Build project context
│  ├─ Detect test framework and command
│  ├─ Run full test suite
│  └─ TESTS FAIL → SKIP (use systematic-debugging skill)
│  └─ TESTS PASS → Continue
│
├─ Phase 4: Security Advisory Check
│  ├─ Check if PR addresses security vulnerability
│  ├─ Verify fix is actually applied
│  └─ Continue
│
└─ ALL CHECKS PASS → MERGE ✓
   └─ Use `gh pr merge --auto --squash` or `--merge` based on repo config
```

## Context-Aware Test Execution

**Project Understanding Strategy:**

### Phase 1: Project Discovery

1. Explore project structure - read root directory contents
2. Build context about the project:
   - What language(s) are used?
   - What's the package manager?
   - What's the build system?
   - What testing framework is configured?
   - Are there development automation scripts?
3. Learn the project's conventions:
   - How does CI run tests? (check CI config)
   - Are there documented commands? (check README, CONTRIBUTING)
   - What commands exist in automation directories? (bin/, scripts/, script/)

### Phase 2: Test Command Discovery

Based on the context built above:

1. **Prefer explicit documentation** - If README or docs mention test commands, use those
2. **Check CI configuration** - This is the source of truth for what actually runs
3. **Look for automation scripts** - Many projects have wrapper scripts
4. **Fall back to framework defaults** - Only if no explicit commands found

### Phase 3: Test Execution

- Use git worktree for branch isolation
- Install dependencies if needed (detected from context)
- Run tests with appropriate timeout (default: 10 minutes, configurable)
- Capture and parse results
- If failure: Use systematic-debugging skill to diagnose

## Breaking Change Detection

**Multi-Layered Analysis:**

### Layer 1: Changelog Analysis

- Fetch release notes from GitHub API
- Parse markdown structure (headers, lists, sections)
- Look for breaking change indicators:
  - Explicit sections: "Breaking Changes", "Migration Guide", "Upgrading"
  - Keywords in context: "removed", "deprecated", "no longer", "incompatible"
  - Version jump patterns: 1.x → 2.0 with substantial changes listed

### Layer 2: API Surface Analysis

- Grep the dependency's diff (if available via GitHub) for:
  - Removed public methods/functions/classes
  - Changed function signatures
  - Removed exports/public APIs
- Cross-reference with your project's usage:
  - Search codebase for imports/requires of the updated dependency
  - Check if removed APIs are actually used in your code

### Layer 3: Dependency Behavior Check

- Review the dependency's own dependencies for major updates
- Check if transitive dependencies introduce breaking changes
- Validate that dependency resolution still works

### Layer 4: Community Signals

- Check PR comments for warning signs from other users
- Look for high issue activity on the release
- GitHub Discussions or Issues mentioning "breaking" near release date

### Risk Scoring

Combine signals into a risk score:

- Major version + breaking changes keyword = HIGH RISK → Skip
- Minor version + "removed" in changelog = MEDIUM RISK → Extra scrutiny
- Patch version + security fix = LOW RISK → Fast path
- Minor version + clean changelog + passing tests = LOW RISK → Merge

## Error Handling and Recovery

**Failure Isolation:**

- Each PR analysis is completely isolated
- One failure doesn't stop the entire workflow
- All errors are logged with context

**Per-PR Error Handling:**

- PR checkout fails → Log error, skip to next PR
- Dependency install fails → Mark as "needs manual review", continue
- Tests fail → Use systematic-debugging skill to diagnose, report findings, skip merge
- Changelog fetch fails → Note missing changelog, increase scrutiny for minor/major versions
- Any phase times out → Fail safely, report timeout, skip merge

**Graceful Degradation:**

- Missing CI config → Use best-effort test discovery
- Missing README → Skip documentation check, rely on other signals
- GitHub API rate limits → Report clearly, suggest retry timing
- Network issues → Retry with exponential backoff (3 attempts max)

## Progress Reporting

**Real-time updates as agent works:**

```text
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

📦 PR #124: Bump react from 18.2.0 to 19.0.0
  ├─ Semver: MAJOR (requires review)
  └─ Decision: SKIP - Manual review required for major version

...

Summary Report:
✓ Merged: 3 PRs
⏭️  Skipped: 2 PRs (1 major version, 1 test failure)
```

**Final Summary Report:**

- Count of PRs processed/merged/skipped
- Links to merged PRs
- Detailed skip reasons with recommendations
- Total time taken
- Next actions (if any PRs need manual review)

## Safety Rails

1. **Never merge if tests fail** - No exceptions
2. **Never merge major version updates automatically** - Always require human review
3. **Always create summary report before any merges** - User visibility
4. **Use `--dry-run` flag** - Preview without merging
5. **Log all decisions with reasoning** - Audit trail for review
6. **Use git worktree isolation** - Don't pollute working directory
7. **Timeout protection** - No hanging on infinite tests

## Implementation Components

### Files to Create

1. **`claude/commands/safely-merge-dependabots.md`**
   - Command definition and documentation
   - Argument parsing and validation
   - Agent invocation

2. **`claude/agents/dependabot-merger.md`**
   - Autonomous agent definition
   - Five-phase analysis workflow
   - Decision logic implementation
   - Progress reporting
   - Error handling

### Skills to Leverage

- `gh-cli` - GitHub PR operations
- `systematic-debugging` - Test failure diagnosis
- Potentially create new: `dependency-analysis` - Breaking change detection patterns

## Usage Examples

```bash
# Analyze and merge all safe Dependabot PRs
/safely-merge-dependabots

# Dry-run mode (analyze only, don't merge)
/safely-merge-dependabots --dry-run

# Process specific PRs only
/safely-merge-dependabots 123 124 125

# Override timeout for slow test suites
/safely-merge-dependabots --timeout 30m
```

## Success Criteria

1. ✅ Discovers all open Dependabot PRs correctly
2. ✅ Builds accurate project context for any project type
3. ✅ Detects breaking changes through multi-layered analysis
4. ✅ Runs tests successfully using project's conventions
5. ✅ Makes correct merge decisions (safe = merge, risky = skip)
6. ✅ Provides clear, actionable reporting
7. ✅ Handles errors gracefully without stopping workflow
8. ✅ Never merges unsafe updates

## Future Enhancements (Not in Initial Version)

- Parallel PR analysis (with sequential merging)
- Integration with CI/CD pipelines
- Customizable risk thresholds via config file
- Performance regression detection
- Notification integration (Slack, email)
- Historical analysis (track merge success rates)
