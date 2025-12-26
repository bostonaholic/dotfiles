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

This command invokes the `dependabot-orchestrator` agent to coordinate specialized worker agents:

1. **Discover PRs**: Find all open Dependabot PRs (or use specified PR numbers)
2. **Analyze Each PR**: Dispatch worker agents for comprehensive analysis
   - **pr-analyzer**: Semver classification, breaking change detection, dependency conflicts
   - **test-runner**: Test suite execution in isolated worktree
   - **security-checker**: CVE verification (when applicable)
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

Invoke the `dependabot-orchestrator` agent with parsed arguments:

```yaml
agent: dependabot-orchestrator
model: haiku
context:
  pr_numbers: [extracted PR numbers or empty for discovery]
  dry_run: [true/false based on --dry-run flag]
  timeout: [extracted timeout or "10m" default]
  arguments: "$ARGUMENTS"
```

The orchestrator will:
- Discover Dependabot PRs using `gh-cli` skill
- Dispatch specialized worker agents per PR:
  - **pr-analyzer** (Sonnet): Deep safety analysis
  - **test-runner** (Sonnet): Test execution with diagnostics
  - **security-checker** (Haiku): CVE verification
- Make merge decisions based on worker results
- Execute merges via `gh-cli` merge-pr workflow
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

**Architecture Benefits:**
- **Orchestrator** (Haiku): Lightweight coordination - 3x cheaper than monolithic Opus
- **Worker Agents**: Specialized models per task (Sonnet for analysis, Haiku for API calls)
- **Modular Design**: Each worker is independently testable and upgradeable
- **Clear Audit Trail**: Sequential PR processing with detailed per-worker results

**Safety Guarantees:**
- Each PR analyzed sequentially for safety
- All decisions logged with detailed reasoning from each worker
- Never merges if any safety check fails
- Worker failures result in skip (safe default)
