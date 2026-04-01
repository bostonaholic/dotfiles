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
  --json number,title,author,mergeable \
  --limit 100
```

**Parse output:**

```json
[
  {"number": 123, "title": "Bump nokogiri from 1.13.0 to 1.13.10", "mergeable": "MERGEABLE"},
  {"number": 124, "title": "Bump react from 18.2.0 to 19.0.0", "mergeable": "CONFLICTING"},
  {"number": 125, "title": "Bump lodash from 4.17.20 to 4.17.21", "mergeable": "MERGEABLE"}
]
```

If `pr_numbers` provided, fetch their mergeable status:

```bash
gh pr view $PR_NUMBER --json number,title,mergeable
```

**Triage PRs into two queues:**

- **ready**: `mergeable` is `MERGEABLE` or `UNKNOWN` → process immediately
- **needs_rebase**: `mergeable` is `CONFLICTING` → request rebase first

**Report to user:**

```text
Discovering Dependabot PRs...
Found 5 open Dependabot PRs: #123, #124, #125, #126, #127
  Ready: #123, #125, #126, #127
  Needs rebase: #124
```

### Phase 1.5: Request Rebases

For each PR in the `needs_rebase` queue:

```bash
gh pr comment $PR_NUMBER --body "@dependabot rebase"
```

**Report to user:**

```text
Requesting rebase for #124...
  ├─ Commented @dependabot rebase on #124
```

Track the timestamp when rebase was requested. These PRs will be re-checked in Phase 4.

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

If `recommendation` is "merge", continue to test execution (Step 2.3).

If `recommendation` is "skip" or "manual-review" **due to MAJOR version or breaking changes**, continue to Step 2.2a (Breaking Change Investigation).

If `recommendation` is "skip" or "manual-review" for other reasons (dependency conflicts, missing context):

- Record skip reason
- Continue to next PR
- Report:

```text
  └─ Decision: SKIP - {reasoning}
```

#### Step 2.2a: Investigate Breaking Changes

When a PR is flagged MAJOR or has breaking changes, investigate whether the codebase is actually affected before skipping.

```markdown
Use Agent tool to dispatch breaking-change-investigator:
- description: "Investigate breaking changes for PR #124"
- prompt: |
    Investigate whether the codebase is affected by breaking changes in PR #124.

    1. Fetch the changelog/release notes for the new version:
       - Check the PR body for linked release notes
       - Check the package's CHANGELOG.md or GitHub releases via `gh api`
       - Identify the specific breaking changes listed

    2. For each breaking change, search the codebase:
       - grep for affected API names, removed functions, changed signatures
       - Check import statements for deprecated modules
       - Look for usage patterns that match the migration guide

    3. Return JSON:
       {
         "breaking_changes": [
           {
             "description": "Removed `widget()` function",
             "codebase_affected": true|false,
             "affected_files": ["src/foo.ts:42", "lib/bar.ts:17"],
             "trivially_fixable": true|false,
             "fix_description": "Replace widget() with newWidget()"
           }
         ],
         "overall_affected": true|false,
         "overall_trivially_fixable": true|false,
         "recommendation": "merge"|"fix-and-merge"|"skip",
         "reasoning": "..."
       }
- subagent_type: general-purpose
- model: sonnet
```

**Wait for response and parse JSON.**

**Decision logic:**

If `overall_affected` is false:

```text
  ├─ Breaking changes: Not affected by any listed changes ✓
```

→ Continue to test execution (Step 2.3). If tests pass, merge.

If `overall_affected` is true AND `overall_trivially_fixable` is true:

```text
  ├─ Breaking changes: Codebase affected, applying trivial fixes...
```

→ Continue to Step 2.2b (Apply Fixes).

If `overall_affected` is true AND `overall_trivially_fixable` is false:

```text
  ├─ Breaking changes: Codebase affected, non-trivial changes required
  │   {list of affected files and descriptions}
  └─ Decision: SKIP - Non-trivial breaking changes require manual review
```

→ Record skip reason with detailed impact report. Continue to next PR.

#### Step 2.2b: Apply Trivial Fixes in PR Branch

When breaking changes are trivially fixable, make the changes directly in the PR branch.

```markdown
Use Agent tool to dispatch fix-applier:
- description: "Apply breaking change fixes for PR #124"
- prompt: |
    Apply trivial breaking change fixes for PR #124.

    1. Check out the PR branch:
       gh pr checkout 124

    2. Apply the following fixes:
       {breaking_changes with trivially_fixable=true, including fix_description and affected_files}

    3. Commit the changes:
       git add -A
       git commit -m "fix: update usage for {package} {new_version} breaking changes"

    4. Push the changes:
       git push

    5. Switch back to the original branch.

    Return JSON:
    {
      "fixes_applied": true|false,
      "files_changed": ["src/foo.ts", "lib/bar.ts"],
      "error": null
    }
- subagent_type: general-purpose
- model: sonnet
```

**Wait for response.**

If `fixes_applied` is true:

```text
  ├─ Fixes applied: {files_changed} ✓
```

→ Continue to test execution (Step 2.3). Tests validate the fixes.

If `fixes_applied` is false:

```text
  ├─ Fix application failed: {error}
  └─ Decision: SKIP - Could not apply breaking change fixes
```

→ Record skip. Continue to next PR.

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

#### Step 2.5: Dispatch dependabot-security-checker (optional)

If PR body or pr-analyzer indicates security fix:

```markdown
Use Task tool to dispatch dependabot-security-checker agent:
- description: "Check security advisories for PR #123"
- prompt: "Check security advisories for PR #123. Return JSON with: is_security_fix, cves, severity, fix_verified"
- subagent_type: general-purpose
- model: haiku
```

**Wait for dependabot-security-checker response.**

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
- dependabot-security-checker: verified (if applicable)

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

### Phase 3: Poll Pending Rebases

If the `needs_rebase` queue is empty, skip to Phase 4.

For each PR in the `needs_rebase` queue, poll until rebase completes or timeout:

```text
Waiting for rebases to complete...
```

**Polling loop** (max 5 minutes per PR, check every 30 seconds):

```bash
gh pr view $PR_NUMBER --json mergeable,mergeStateStatus -q '{mergeable: .mergeable, status: .mergeStateStatus}'
```

**Check result:**

- `mergeable` is `MERGEABLE` → rebase complete, process this PR
- `mergeable` is `CONFLICTING` → still rebasing, wait and retry
- `mergeable` is `UNKNOWN` → GitHub still computing, wait and retry

**When rebase completes:**

```text
  ├─ PR #124: Rebase complete ✓
```

→ Run the full analysis pipeline (Steps 2.1 through 2.7) on this PR, same as any ready PR.

**When rebase times out (5 minutes):**

```text
  ├─ PR #124: Rebase still pending after 5m
  └─ Decision: SKIP - Rebase timed out, retry later
```

→ Record as skipped with note to retry.

**Report after all rebases processed:**

```text
Rebase results:
  ├─ #124: Rebase complete → analyzed and merged ✓
  ├─ #126: Rebase complete → analyzed, tests failed, skipped
  └─ #128: Rebase timed out, skipped
```

### Phase 4: Final Summary Report

After processing all PRs (including rebased ones), generate summary:

```text
═══════════════════════════════════════════════════════════
                    Summary Report
═══════════════════════════════════════════════════════════

✓ Merged: 4 PRs
  - PR #123: nokogiri 1.13.0 → 1.13.10 (PATCH, security fix)
  - PR #124: react 18.2.0 → 19.0.0 (MAJOR, not affected by breaking changes)
  - PR #125: rack 2.2.3 → 2.2.8 (PATCH)
  - PR #127: rubocop 1.50.0 → 1.50.2 (PATCH)

🔧 Merged with fixes: 1 PR
  - PR #129: webpack 5.x → 6.0.0 (MAJOR, trivial fixes applied)
    Fixed: updated config key in webpack.config.js

⏭️  Skipped: 2 PRs
  - PR #126: rspec 3.11.0 → 3.12.0 (MINOR - test failures)
    Diagnostics: 3 tests failed due to deprecated API usage
  - PR #130: typescript 5.x → 6.0.0 (MAJOR - non-trivial breaking changes)
    Impact: 12 files use removed CompilerOptions.importsNotUsedAsValues

⏳ Rebase timed out: 1 PR
  - PR #128: sass 1.70.0 → 1.71.0 (rebase requested, retry later)

═══════════════════════════════════════════════════════════

Total Time: 12m 18s
Next Actions:
  - Review skipped PRs manually: gh pr view 126, gh pr view 130
  - Retry timed-out rebases: /safely-merge-dependabots 128
  - Monitor auto-merge PRs: gh pr checks 123, 124, 125, 127, 129
```

If dry-run mode:

```text
═══════════════════════════════════════════════════════════
                Summary Report (DRY RUN)
═══════════════════════════════════════════════════════════

Would Merge: 3 PRs
  - PR #123: nokogiri 1.13.0 → 1.13.10 (PATCH, security fix)
  - PR #124: react 18.2.0 → 19.0.0 (MAJOR, not affected)
  - PR #125: rack 2.2.3 → 2.2.8 (PATCH)

Would Fix & Merge: 1 PR
  - PR #129: webpack 5.x → 6.0.0 (MAJOR, trivial fixes needed)

Would Skip: 1 PR
  - PR #126: rspec 3.11.0 → 3.12.0 (test failures)

Pending Rebase: 1 PR
  - PR #128: sass 1.70.0 → 1.71.0 (would process after rebase)

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

**Breaking change investigation fails:**

- Log error
- Fall back to skip (same as before these improvements)
- Report: "Could not determine breaking change impact, skipping for safety"

**Fix application fails (Step 2.2b):**

- Do not merge
- Record as skipped with error details
- Report the attempted fix and failure reason
- Continue to next PR

**Rebase polling errors:**

- GitHub API returns error during poll → skip PR, note to retry
- PR closed or merged during rebase → remove from queue, note in report
- All rebases time out → include all in "timed out" section of report

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
  Found 4 PRs: #123, #124, #125, #126
  Ready: #123, #124, #125
  Needs rebase: #126

Phase 1.5: Request Rebases
  Commented @dependabot rebase on #126

Phase 2: Process ready PRs

PR #123 (PATCH):
  - Dispatch pr-analyzer → {safe: true, risk: "low", semver: "PATCH"}
  - Dispatch test-runner → {passed: true, tests_run: 847}
  - Decision: MERGE
  - Execute: gh pr merge 123 --auto --squash --delete-branch
  - Result: Success ✓

PR #124 (MAJOR - not affected):
  - Dispatch pr-analyzer → {safe: false, risk: "high", semver: "MAJOR", recommendation: "skip"}
  - Dispatch breaking-change-investigator → {overall_affected: false}
  - Codebase not affected by breaking changes, proceeding to tests
  - Dispatch test-runner → {passed: true, tests_run: 847}
  - Decision: MERGE
  - Execute: gh pr merge 124 --auto --squash --delete-branch
  - Result: Success ✓

PR #125 (MAJOR - trivial fix):
  - Dispatch pr-analyzer → {safe: false, risk: "high", semver: "MAJOR", recommendation: "skip"}
  - Dispatch breaking-change-investigator → {overall_affected: true, overall_trivially_fixable: true}
  - Dispatch fix-applier → {fixes_applied: true, files_changed: ["config/settings.ts"]}
  - Dispatch test-runner → {passed: true, tests_run: 847}
  - Decision: MERGE (with fixes)
  - Execute: gh pr merge 125 --auto --squash --delete-branch
  - Result: Success ✓

Phase 3: Poll Pending Rebases
  PR #126: polling... rebase complete after 90s
  PR #126 (PATCH):
    - Dispatch pr-analyzer → {safe: true, risk: "low", semver: "PATCH"}
    - Dispatch test-runner → {passed: true, tests_run: 203}
    - Decision: MERGE
    - Execute: gh pr merge 126 --auto --squash --delete-branch
    - Result: Success ✓

Phase 4: Final Summary
  Merged: 3 PRs (#123, #124, #126)
  Merged with fixes: 1 PR (#125)
  Skipped: 0 PRs
  Total time: 7m 42s
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
