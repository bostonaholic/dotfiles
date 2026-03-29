---
name: safely-merge-dependabots
user-invocable: true
argument-hint: "[PR numbers] [--dry-run] [--timeout <duration>]"
description: This skill should be used when the user asks to "merge dependabot PRs", "safely merge dependabots", "auto-merge safe dependency updates", "process dependabot PRs", or wants to autonomously analyze and merge Dependabot PRs with comprehensive safety checks.
---

# Safely Merge Dependabots

Autonomously discover, analyze, and safely merge Dependabot PRs. Uses multi-layered analysis to detect breaking changes, runs the full test suite, and only merges patch/minor updates that pass all safety checks.

## Arguments

- **PR numbers** (optional): Space-separated PR numbers to process. If omitted, discover all open Dependabot PRs.
- **--dry-run** (optional): Analyze only, do not merge anything. Shows what would be merged.
- **--timeout `<duration>`** (optional): Override test timeout (default: 10m). Format: 5m, 10m, 20m, 30m.

## Procedure

Invoke the `dependabot-orchestrator` agent to coordinate specialized worker agents:

1. **Discover PRs**: Find all open Dependabot PRs (or use specified PR numbers)
2. **Analyze Each PR**: Dispatch worker agents for comprehensive analysis
   - **pr-analyzer**: Semver classification, breaking change detection, dependency conflicts
   - **test-runner**: Test suite execution in isolated worktree
   - **dependabot-security-checker**: CVE verification (when applicable)
3. **Make Decisions**: Auto-merge safe updates, skip risky ones
4. **Report Results**: Detailed summary with merge/skip counts and reasoning

## Safety Policy

**Auto-merge when ALL conditions met:**
- PATCH or MINOR version update only
- All tests pass
- No breaking changes detected
- No dependency conflicts
- Security fixes verified (if applicable)

**Always skip (require manual review):**
- MAJOR version updates
- Breaking changes detected
- Test failures
- Dependency conflicts
- Missing critical context

## Architecture

- **Orchestrator** (Haiku): Lightweight coordination
- **Worker Agents**: Specialized models per task (Sonnet for analysis, Haiku for API calls)
- Each PR analyzed sequentially for safety
- All decisions logged with detailed reasoning
- Worker failures result in skip (safe default)
