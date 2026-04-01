---
name: safely-merge-dependabots
user-invokable: true
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

1. **Discover PRs**: Find all open Dependabot PRs (or use specified PR numbers), detect merge conflicts
2. **Request Rebases**: Comment `@dependabot rebase` on PRs with merge conflicts
3. **Analyze Each PR**: Dispatch worker agents for comprehensive analysis
   - **pr-analyzer**: Semver classification, breaking change detection, dependency conflicts
   - **breaking-change-investigator** (when MAJOR): Search codebase for actual usage of affected APIs
   - **test-runner**: Test suite execution in isolated worktree
   - **dependabot-security-checker**: CVE verification (when applicable)
4. **Make Decisions**: Auto-merge safe updates, fix trivial breaking changes, skip truly risky ones
5. **Poll Pending Rebases**: Re-check PRs that were rebasing, run full analysis when ready
6. **Report Results**: Detailed summary with merge/skip/rebase counts and reasoning

## Safety Policy

**Auto-merge when ALL conditions met:**
- PATCH or MINOR version update
- All tests pass
- No breaking changes detected
- No dependency conflicts
- Security fixes verified (if applicable)

**Investigate before skipping (MAJOR / breaking changes):**
- Fetch changelog and identify specific breaking changes
- Search codebase for actual usage of affected APIs
- If codebase is NOT impacted: proceed to test and merge
- If impacted but trivially fixable: make changes in PR branch, test, merge
- If impacted and non-trivial: skip with detailed impact report

**Pending rebase:**
- Comment `@dependabot rebase` on PRs with merge conflicts
- Poll until rebase completes (up to 5 minutes per PR)
- Re-run full analysis pipeline after rebase
- If rebase times out: skip with note to retry later

**Always skip (require manual review):**
- Non-trivial breaking changes that affect the codebase
- Test failures
- Dependency conflicts
- Missing critical context

## Architecture

- **Orchestrator** (Haiku): Lightweight coordination
- **Worker Agents**: Specialized models per task (Sonnet for analysis, Haiku for API calls)
- Each PR analyzed sequentially for safety
- All decisions logged with detailed reasoning
- Worker failures result in skip (safe default)
