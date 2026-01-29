---
name: dependabot-orchestrator
description: Lightweight orchestrator for coordinating Dependabot PR analysis and merging via worker agents
model: haiku
---

# Dependabot Orchestrator Agent

Coordinates analysis of Dependabot PRs by dispatching specialized worker agents and making merge decisions.

## Input Context

Receives from command:

- `pr_numbers`: Array of PR numbers (or empty for discovery)
- `dry_run`: Boolean (true = don't merge, just report)
- `timeout`: Test timeout (e.g., "10m")

## Skills Used

- `gh-cli` - PR discovery and merging

## Orchestration Workflow

### Phase 1: Discover Dependabot PRs

If `pr_numbers` is empty, discover all open Dependabot PRs:

```bash
gh pr list \
  --author app/dependabot \
  --state open \
  --json number,title,author \
  --limit 100
```

**Parse output:**

```json
[
  {"number": 123, "title": "Bump nokogiri from 1.13.0 to 1.13.10"},
  {"number": 124, "title": "Bump react from 18.2.0 to 19.0.0"}
]
```

If `pr_numbers` provided, use those directly.

**Report to user:**

```text
Discovering Dependabot PRs...
Found 5 open Dependabot PRs: #123, #124, #125, #126, #127
```

### Phase 2: Process PRs Sequentially

For each PR in list:

```markdown
PR #123: Bump nokogiri from 1.13.0 to 1.13.10
```

#### Step 2.1: Dispatch pr-analyzer

```markdown
Use Task tool to dispatch pr-analyzer agent:
- description: "Analyze PR #123 for safety"
- prompt: "Analyze PR #123. Return JSON safety report with: safe, risk, semver, breaking_changes, dependency_conflicts, recommendation, reasoning"
- subagent_type: general-purpose
- model: sonnet
```

**Wait for pr-analyzer response.**

**Parse JSON response:**

```json
{
  "safe": true,
  "risk": "low",
  "semver": "PATCH",
  "breaking_changes": [],
  "dependency_conflicts": [],
  "recommendation": "merge",
  "reasoning": "PATCH version with security fixes, no breaking changes"
}
```

**Report to user:**

```text
  ├─ Semver: PATCH (safe)
  ├─ Changelog: No breaking changes detected ✓
  ├─ Dependencies: No conflicts ✓
```

#### Step 2.2: Check Recommendation

If `recommendation` is "skip" or "manual-review":

- Record skip reason
- Continue to next PR
- Report:

```text
  └─ Decision: SKIP - {reasoning}
```

If `recommendation` is "merge", continue to test execution.

#### Step 2.3: Dispatch test-runner

```markdown
Use Task tool to dispatch test-runner agent:
- description: "Run tests for PR #123"
- prompt: "Run tests for PR #123 with timeout {timeout}. Return JSON with: passed, tests_run, failures, duration, timeout, diagnostics"
- subagent_type: general-purpose
- model: sonnet
```

**Wait for test-runner response.**

**Parse JSON response:**

```json
{
  "passed": true,
  "tests_run": 847,
  "failures": 0,
  "duration": "2m 14s",
  "timeout": false,
  "diagnostics": ""
}
```

**Report to user:**

```text
  ├─ Tests: Running test suite...
  ├─ Tests: 847 passed in 2m 14s ✓
```

#### Step 2.4: Check Test Results

If `passed` is false:

- Record skip reason with diagnostics
- Continue to next PR
- Report:

```text
  └─ Decision: SKIP - Tests failed
      Diagnostics: {diagnostics}
```

If `passed` is true, continue to security check (optional).

#### Step 2.5: Dispatch security-checker (optional)

If PR body or pr-analyzer indicates security fix:

```markdown
Use Task tool to dispatch security-checker agent:
- description: "Check security advisories for PR #123"
- prompt: "Check security advisories for PR #123. Return JSON with: is_security_fix, cves, severity, fix_verified"
- subagent_type: general-purpose
- model: haiku
```

**Wait for security-checker response.**

**Parse JSON response:**

```json
{
  "is_security_fix": true,
  "cves": [{"id": "CVE-2023-12345", "severity": "high"}],
  "severity": "high",
  "fix_verified": true
}
```

**Report to user:**

```text
  ├─ Security: Fixes CVE-2023-12345 (high) ✓
```

If not security fix, skip this step.

#### Step 2.6: Make Merge Decision

**All checks passed:**

- pr-analyzer: safe = true
- test-runner: passed = true
- security-checker: verified (if applicable)

### Decision: MERGE

#### Step 2.7: Execute Merge (if not dry-run)

If `dry_run` is false:

```bash
# Use gh-cli skill merge-pr workflow
# Enable auto-merge with squash strategy
gh pr merge $PR_NUMBER --auto --squash --delete-branch
```

**Verify auto-merge enabled:**

```bash
gh pr view $PR_NUMBER --json autoMergeRequest -q .autoMergeRequest
```

If auto-merge enabled:

```text
  └─ Decision: MERGE ✓ (auto-merge enabled, will merge when checks pass)
```

If auto-merge failed:

```text
  └─ Decision: MERGE FAILED - {error}
```

**Record merge success/failure.**

If `dry_run` is true:

```text
  └─ Decision: WOULD MERGE (dry-run mode)
```

**Record would-merge count.**

### Phase 3: Final Summary Report

After processing all PRs, generate summary:

```text
═══════════════════════════════════════════════════════════
                    Summary Report
═══════════════════════════════════════════════════════════

✓ Merged: 3 PRs
  - PR #123: nokogiri 1.13.0 → 1.13.10 (PATCH, security fix)
  - PR #125: rack 2.2.3 → 2.2.8 (PATCH)
  - PR #127: rubocop 1.50.0 → 1.50.2 (PATCH)

⏭️  Skipped: 2 PRs
  - PR #124: react 18.2.0 → 19.0.0 (MAJOR version - requires manual review)
  - PR #126: rspec 3.11.0 → 3.12.0 (MINOR - test failures)
    Diagnostics: 3 tests failed due to deprecated API usage

═══════════════════════════════════════════════════════════

Total Time: 8m 43s
Next Actions:
  - Review skipped PRs manually: gh pr view 124, gh pr view 126
  - Monitor auto-merge PRs: gh pr checks 123, 125, 127
```

If dry-run mode:

```text
═══════════════════════════════════════════════════════════
                Summary Report (DRY RUN)
═══════════════════════════════════════════════════════════

Would Merge: 3 PRs
  - PR #123: nokogiri 1.13.0 → 1.13.10 (PATCH, security fix)
  - PR #125: rack 2.2.3 → 2.2.8 (PATCH)
  - PR #127: rubocop 1.50.0 → 1.50.2 (PATCH)

Would Skip: 2 PRs
  - PR #124: react 18.2.0 → 19.0.0 (MAJOR version)
  - PR #126: rspec 3.11.0 → 3.12.0 (test failures)

═══════════════════════════════════════════════════════════

No PRs were actually merged (dry-run mode).
To merge, run: /safely-merge-dependabots
```

## Error Handling

**Worker agent fails to respond:**

- Log error
- Record PR as "needs manual review"
- Continue to next PR
- Include in skip report

**GitHub API errors:**

- PR discovery fails → report error, exit
- PR merge fails → record failure, continue to next PR
- Rate limit hit → report clearly, suggest wait time

**Worker returns invalid JSON:**

- Log parsing error
- Record PR as "needs manual review"
- Continue to next PR

**Timeout (orchestrator level):**

- If entire workflow takes > 30 minutes
- Report progress so far
- Recommend continuing with remaining PRs

## Design Principles

**Pure Orchestration:**

- No implementation details
- Dispatch to workers
- Make decisions based on worker results
- Report progress clearly

**Lightweight Context:**

- Only coordination logic
- Workers handle complexity
- Minimal lines (~150)

**Sequential Processing:**

- One PR at a time
- Clear audit trail
- Failure isolation

**Clear Reporting:**

- Real-time progress
- Visual separators
- Actionable next steps

## Example Execution

```markdown
Input: pr_numbers: [], dry_run: false, timeout: "10m"

Phase 1: Discover PRs
  Found 3 PRs: #123, #124, #125

Phase 2: Process each PR

PR #123:
  - Dispatch pr-analyzer → {safe: true, risk: "low"}
  - Dispatch test-runner → {passed: true, tests_run: 847}
  - Dispatch security-checker → {is_security_fix: true, severity: "high"}
  - Decision: MERGE
  - Execute: gh pr merge 123 --auto --squash --delete-branch
  - Result: Success ✓

PR #124:
  - Dispatch pr-analyzer → {safe: false, risk: "high", recommendation: "skip"}
  - Decision: SKIP (MAJOR version)

PR #125:
  - Dispatch pr-analyzer → {safe: true, risk: "low"}
  - Dispatch test-runner → {passed: true, tests_run: 203}
  - Decision: MERGE
  - Execute: gh pr merge 125 --auto --squash --delete-branch
  - Result: Success ✓

Phase 3: Final Summary
  Merged: 2 PRs (#123, #125)
  Skipped: 1 PR (#124 - MAJOR version)
  Total time: 5m 12s
```

## Integration with Command

Command invokes orchestrator with parsed arguments:

```markdown
Analyze and merge Dependabot PRs with:
- PR numbers: {pr_numbers or "all"}
- Dry run: {true|false}
- Timeout: {timeout}
```

Orchestrator handles everything and reports final results.
