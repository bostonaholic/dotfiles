# GitHub PR Merge Workflow

Safe PR merging strategies using GitHub CLI.

## Purpose

Provides patterns for safely merging pull requests with appropriate merge
strategies and verification.

## Merge Strategy Detection

### Check Repository Settings

```bash
# Get repository's default merge method
gh repo view --json mergeCommitAllowed,squashMergeAllowed,rebaseMergeAllowed
```

### Strategy Selection

**Prefer in this order:**

1. **Squash** - Clean history for dependency updates
2. **Merge commit** - Preserves PR structure
3. **Rebase** - Linear history

For automated dependency updates (Dependabot, Renovate):

- **Always use squash** if available
- Single logical change = single commit

## Safe Merge Commands

### Auto-merge (Preferred)

Enables auto-merge once checks pass:

```bash
# Squash merge (recommended for dependency updates)
gh pr merge <number> --auto --squash --delete-branch

# Regular merge commit
gh pr merge <number> --auto --merge --delete-branch

# Rebase merge
gh pr merge <number> --auto --rebase --delete-branch
```

**Why auto-merge:**

- Waits for CI checks to pass
- Waits for required reviews
- Safer than immediate merge
- Non-blocking workflow

### Immediate Merge

Only use if checks already passed and urgent:

```bash
# Squash merge
gh pr merge <number> --squash --delete-branch

# Regular merge
gh pr merge <number> --merge --delete-branch

# Rebase merge
gh pr merge <number> --rebase --delete-branch
```

## Verification After Merge

Always verify merge succeeded:

```bash
# Check PR status
gh pr view <number> --json state,merged,mergedAt

# Expected output:
# {
#   "state": "MERGED",
#   "merged": true,
#   "mergedAt": "2025-12-26T..."
# }
```

## Error Handling

### Merge Conflicts

```bash
# Check for conflicts before attempting merge
gh pr view <number> --json mergeable

# If mergeable: "MERGEABLE"
# If conflicts: "CONFLICTING"
# If unknown: "UNKNOWN" (checks pending)
```

If conflicting:

- Skip merge
- Report conflict to user
- Recommend manual resolution

### Failing Checks

```bash
# Check CI status
gh pr checks <number>

# Wait for checks to complete (--watch)
gh pr checks <number> --watch
```

Never merge with failing checks.

### Permission Errors

If merge fails with permission error:

- Report to user
- Provide PR URL for manual merge
- Don't retry automatically

## Best Practices

1. **Always use --delete-branch** for dependency updates
   - Keeps repository clean
   - No orphaned branches

2. **Prefer --auto over immediate merge**
   - Safer (waits for checks)
   - Non-blocking
   - Handles race conditions

3. **Verify merge succeeded**
   - Don't assume success
   - Check actual state
   - Report failures clearly

4. **Handle dry-run mode**
   - Show what would be merged
   - Don't execute actual merge
   - Provide clear indication

## Example: Safe Merge Flow

```bash
# 1. Check if PR is mergeable
mergeable=$(gh pr view 123 --json mergeable -q .mergeable)

if [ "$mergeable" != "MERGEABLE" ]; then
  echo "PR has conflicts, skipping"
  exit 1
fi

# 2. Check CI status
checks=$(gh pr checks 123 --json state -q .[].state)

if echo "$checks" | grep -q "FAILURE\|ERROR"; then
  echo "PR has failing checks, skipping"
  exit 1
fi

# 3. Enable auto-merge (squash for dependency updates)
gh pr merge 123 --auto --squash --delete-branch

# 4. Verify auto-merge enabled
status=$(gh pr view 123 --json autoMergeRequest -q .autoMergeRequest)

if [ -n "$status" ]; then
  echo "Auto-merge enabled, will merge when checks pass"
else
  echo "Failed to enable auto-merge"
  exit 1
fi
```

## Dry-Run Mode

For --dry-run mode, show intended actions without executing:

```bash
echo "Would merge PR #123:"
echo "  Strategy: squash"
echo "  Delete branch: yes"
echo "  Method: auto-merge (wait for checks)"
```

## Integration with Agents

Agents using this workflow should:

1. Check merge strategy availability
2. Verify PR is mergeable
3. Check CI status
4. Enable auto-merge (preferred)
5. Verify auto-merge enabled
6. Report success/failure clearly
