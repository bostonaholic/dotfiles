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

## Terminal States

Every PR ends in exactly one state. Infrastructure failures never borrow a safety state.

- **MERGED** (or **WOULD MERGE** in dry-run): every check passed.
- **SKIPPED**: we successfully determined this PR should not be merged — test failures, non-trivial breaking changes, fixes could not be applied.
- **ERRORED**: we failed to determine anything — unparseable worker output, worker non-response, worker crash, or harness error. Never merge an ERRORED PR, and never report it as a skip.
- **RECREATED**: Dependabot will replace the PR; the new one is picked up on the next run.

**Phase result ledger:** record each phase's result for a PR the moment that phase completes (analysis, breaking-change investigation, fixes, tests, security). A later phase erroring does not erase earlier results. When a phase errors, report which phase failed and what the completed phases already established. Established evidence never promotes a PR to merge on its own — a PR whose test phase ERRORED stays unmerged.

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

#### Check for Dependabot retry instructions

For each discovered PR, fetch comments from Dependabot looking for retry instructions:

```bash
gh pr view $PR_NUMBER --json comments --jq '[.comments[] | select(.author.login == "dependabot[bot]") | .body] | last'
```

**Look for patterns** in the most recent Dependabot comment:

- `commenting \x60@dependabot rebase\x60` → needs rebase
- `commenting \x60@dependabot recreate\x60` → needs recreate (Dependabot failed to update)
- `commenting \x60@dependabot retry\x60` → needs retry
- Any other `@dependabot <command>` in a "you can retry" context → extract and follow

These instructions take precedence over the `mergeable` status. A PR may show `MERGEABLE` but still have a Dependabot error comment requesting `@dependabot recreate`.

**Triage PRs into three queues:**

- **ready**: `mergeable` is `MERGEABLE` or `UNKNOWN`, no Dependabot retry instructions → process immediately
- **needs_rebase**: `mergeable` is `CONFLICTING` OR Dependabot comment suggests `@dependabot rebase` → request rebase first
- **needs_action**: Dependabot comment suggests `@dependabot recreate`, `@dependabot retry`, or other command → follow instruction first

**Report to user:**

```text
Discovering Dependabot PRs...
Found 5 open Dependabot PRs: #123, #124, #125, #126, #127
  Ready: #123, #125, #127
  Needs rebase: #124
  Needs action: #126 (@dependabot recreate)
```

### Phase 1.5: Follow Dependabot Instructions

#### Rebases

For each PR in the `needs_rebase` queue:

```bash
gh pr comment $PR_NUMBER --body "@dependabot rebase"
```

```text
  ├─ Commented @dependabot rebase on #124
```

Track the timestamp when rebase was requested. These PRs will be re-checked in Phase 3.

#### Other actions (recreate, retry, etc.)

For each PR in the `needs_action` queue, comment the exact command Dependabot requested:

```bash
gh pr comment $PR_NUMBER --body "@dependabot recreate"
```

```text
  ├─ Commented @dependabot recreate on #126
```

**Behavior by command:**

- **`@dependabot rebase`**: Moves to `needs_rebase` queue for polling in Phase 3.
- **`@dependabot recreate`**: Dependabot will close this PR and open a new one. Record as "recreated" — the new PR will be picked up on the next run of the skill.
- **`@dependabot retry`**: Dependabot will retry the failed update. Record as "retried" — poll the same PR in Phase 3 (same as rebase).
- **Unknown command**: Comment it anyway, record as "action taken", skip further processing.

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
- No phase ERRORED — an errored phase blocks the merge even when earlier phases established safety

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

❌ Errored: 1 PR (nothing determined - NOT a safety decision)
  - PR #132: openai 6.45.0 → 7.1.0 (MAJOR)
    Failed phase: test-runner (unparseable output after 1 retry)
    Established before failure: pr-analyzer flagged MAJOR;
      breaking-change-investigator verified codebase not affected
    Raw output (first 200 chars): Sure! I'll run the test suite for PR #132 now. Let me
      start by checking out the branch...

⏭️  Skipped: 2 PRs
  - PR #126: rspec 3.11.0 → 3.12.0 (MINOR - test failures)
    Diagnostics: 3 tests failed due to deprecated API usage
  - PR #130: typescript 5.x → 6.0.0 (MAJOR - non-trivial breaking changes)
    Impact: 12 files use removed CompilerOptions.importsNotUsedAsValues

⏳ Rebase timed out: 1 PR
  - PR #128: sass 1.70.0 → 1.71.0 (rebase requested, retry later)

🔄 Recreated: 1 PR
  - PR #131: lint-staged 16.3.3 → 16.4.0 (commented @dependabot recreate, re-run to process new PR)

═══════════════════════════════════════════════════════════

Total Time: 12m 18s
Next Actions:
  - Re-run errored PRs (no determination was reached): /safely-merge-dependabots 132
  - Review skipped PRs manually: gh pr view 126, gh pr view 130
  - Retry timed-out rebases: /safely-merge-dependabots 128
  - Re-run to pick up recreated PRs: /safely-merge-dependabots
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

Would Recreate: 1 PR
  - PR #131: lint-staged 16.3.3 → 16.4.0 (would comment @dependabot recreate)

═══════════════════════════════════════════════════════════

No PRs were actually merged (dry-run mode).
To merge, run: /safely-merge-dependabots
```

The **Errored** section appears in both reports whenever any PR ERRORED.

#### Pipeline failure invariant

If zero PRs were merged (or, in dry-run mode, marked WOULD MERGE) **and** one or more PRs
ERRORED, the run failed. Do not present it as a tidy list of skips. Lead the summary with the
failure banner, then the normal sections:

```text
═══════════════════════════════════════════════════════════
        PIPELINE FAILURE - 0 merged, 9 errored
═══════════════════════════════════════════════════════════

Nothing was determined for 9 of 9 PRs and nothing was merged.
Failed phase: test-runner (unparseable output on every PR, after retry).
This is an orchestrator failure, not a verdict on the PRs. Diagnostics below.
```

Never report a run that merged nothing and errored on something as a success, and never end
such a run silently — the summary is required output, not an option.

## Error Handling

**Worker agent fails to respond (or crashes):**

- Log error
- Record PR as ERRORED, noting the phase that failed
- Continue to next PR
- Include in the **Errored** section — never in the skip report

**GitHub API errors:**

- PR discovery fails → report error, exit
- PR merge fails → record failure, continue to next PR
- Rate limit hit → report clearly, suggest wait time

**Worker returns invalid JSON:**

- Log parsing error, keeping the first 200 characters of the raw output as the diagnostic
- Re-dispatch that same worker **once**, appending to the prompt: "Return ONLY valid JSON
  matching the schema above. No prose, no explanation, no markdown fences."
- If the retry parses, continue the pipeline normally
- If the retry also fails to parse, record PR as ERRORED for that phase and continue to next PR
- One retry only — no backoff, no third attempt
- Report:

```text
  ├─ Tests: worker returned unparseable output, retrying once...
  └─ Decision: ERRORED - test-runner returned unparseable output (retried once)
      Established before failure: {results of completed phases}
      Raw output (first 200 chars): {raw}
```

**Breaking change investigation fails:**

- Log error
- Do not merge (same safety outcome as before these improvements)
- Record PR as ERRORED, failed phase: breaking-change-investigator
- Report: "Could not determine breaking change impact, not merged"

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
  Found 5 PRs: #123, #124, #125, #126, #131
  Ready: #123, #124, #125
  Needs rebase: #126
  Needs action: #131 (@dependabot recreate - "something went wrong")

Phase 1.5: Follow Dependabot Instructions
  Commented @dependabot rebase on #126
  Commented @dependabot recreate on #131 (will be closed and reopened)

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
  Recreated: 1 PR (#131 - re-run to process new PR)
  Skipped: 0 PRs
  Errored: 0 PRs
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
