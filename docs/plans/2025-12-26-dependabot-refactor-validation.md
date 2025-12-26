# Dependabot Refactor Validation Plan

**Date:** 2025-12-26
**Purpose:** Validate modular orchestrator architecture before permanently
removing old monolith

## Validation Criteria

### Functional Parity

- [ ] Discovers same PRs as monolith
- [ ] Makes same merge decisions (safe vs skip)
- [ ] Handles all error cases gracefully
- [ ] Produces equivalent final reports
- [ ] Respects --dry-run mode
- [ ] Respects --timeout override
- [ ] Respects PR number selection

### Performance Improvements

- [ ] Reduce cost per PR by >50% (measure: token usage)
- [ ] Reduce latency by >30% (measure: total execution time)
- [ ] Orchestrator uses Haiku model
- [ ] Workers use appropriate models (Sonnet/Haiku)

### Code Quality

- [ ] Each component <350 lines
- [ ] Each component has single responsibility
- [ ] Skills reusable outside this workflow
- [ ] Clear interfaces between components
- [ ] Comprehensive error handling per component

## Validation Method

### Phase 1: Dry-Run Comparison (Week 1)

Run both architectures side-by-side on same PRs in dry-run mode:

```bash
# Temporarily enable old agent for comparison
cp claude/agents/dependabot-merger.deprecated.md claude/agents/dependabot-merger.md

# Run old architecture
/safely-merge-dependabots --dry-run > old-results.txt

# Switch to new architecture
rm claude/agents/dependabot-merger.md

# Run new architecture
/safely-merge-dependabots --dry-run > new-results.txt

# Compare results
diff old-results.txt new-results.txt
```

**Expected:** Same PRs would be merged/skipped.

**If differences found:**

- Document discrepancies
- Determine if new architecture is safer (acceptable)
- Fix if new architecture is less safe (required)

### Phase 2: Live Validation (Week 2)

Run new architecture on real PRs:

```bash
# Run with actual merges
/safely-merge-dependabots

# Monitor merged PRs
# - Do they pass CI after merge?
# - Any introduced bugs?
# - Any rollbacks required?
```

**Success Criteria:**

- 20 successful PR processing runs, OR
- 2 weeks without issues, whichever comes first

**Track:**

- Total PRs processed
- PRs merged successfully
- PRs skipped correctly
- False positives (should skip but merged)
- False negatives (should merge but skipped)
- Execution time per run
- Cost per run (estimate from model usage)

### Phase 3: Performance Measurement

**Collect metrics:**

| Metric              | Monolith    | Modular             | Improvement |
| ------------------- | ----------- | ------------------- | ----------- |
| Avg time per PR     | ?           | ?                   | ?           |
| Cost per PR (est.)  | Opus tokens | Haiku/Sonnet tokens | ?           |
| Lines of code       | 741         | <350 each           | ?           |
| Reusable components | 0           | 3 skills            | ∞           |

**Calculate:**

- Cost reduction: `(Monolith - Modular) / Monolith * 100%`
- Speed improvement: `(Monolith - Modular) / Monolith * 100%`

**Target:**

- Cost: >50% reduction
- Speed: >30% improvement

## Decision Criteria

### ✅ Safe to Delete Monolith If

- All functional parity checks pass
- 20+ successful runs OR 2 weeks validation
- No false positives (unsafe merges)
- Performance improvements meet targets
- No critical issues found
- Team comfortable with new architecture

### ⚠️ Keep Monolith Longer If

- <20 runs OR <2 weeks elapsed
- Performance targets not met (investigate why)
- Functional differences require discussion
- Team wants more validation time

### ❌ Rollback to Monolith If

- False positives found (merged unsafe PRs)
- Critical bugs in workers or orchestrator
- Performance worse than monolith
- Workers fail frequently
- Can't determine merge decisions reliably

## Rollback Procedure

If rollback needed:

```bash
# Restore old agent
cp claude/agents/dependabot-merger.deprecated.md claude/agents/dependabot-merger.md

# Update command
# Change agent: dependabot-orchestrator → dependabot-merger
# Change model: haiku → opus

# Test old agent works
/safely-merge-dependabots --dry-run

# Commit rollback
git add claude/commands/safely-merge-dependabots.md
git commit -m "revert: rollback to monolithic dependabot-merger due to {reason}"
```

## Permanent Deletion Procedure

After validation passes:

```bash
# Remove deprecated agent
git rm claude/agents/dependabot-merger.deprecated.md

# Commit deletion
git commit -m "refactor(claude): remove deprecated dependabot-merger

Validation complete:
- 20+ successful runs over 2 weeks
- All functional parity checks passed
- Performance targets met (50%+ cost reduction, 30%+ speed improvement)
- No critical issues found

Modular orchestrator architecture is now the sole implementation."
```

## Monitoring During Validation

**What to watch:**

- CI status on merged PRs
- User reports of issues
- Error messages in orchestrator/workers
- Skipped PRs (review manually to confirm correct)
- Worker agent failures

**Where to check:**

- GitHub Actions logs
- Merged PR CI status
- Manual review of skipped PRs
- User feedback

## Documentation

After validation, update docs:

- Remove deprecation notices from code
- Update README if mentions old architecture
- Document new architecture in CLAUDE.md (if appropriate)
- Archive this validation plan

## Timeline

**Week 1 (Dec 26 - Jan 2):**

- Dry-run comparisons
- Fix any discrepancies
- Begin live validation

**Week 2 (Jan 2 - Jan 9):**

- Continue live validation
- Collect performance metrics
- Monitor merged PRs

**End of Week 2:**

- Review validation results
- Make decision: keep, extend validation, or rollback
- Delete monolith if validation passes

## Sign-Off

After validation complete, document decision:

```markdown
## Validation Results

**Date:** YYYY-MM-DD
**Decision:** [Delete monolith | Extend validation | Rollback]

**Metrics:**
- Total runs: X
- PRs processed: Y
- Merged: A
- Skipped: B
- False positives: 0
- False negatives: C
- Avg time: X min (Y% improvement)
- Avg cost: $Z (W% reduction)

**Conclusion:**
[Explanation of decision]

**Signed-off by:** [Name]
```
