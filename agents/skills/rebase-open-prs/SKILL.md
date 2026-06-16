---
name: rebase-open-prs
description: This skill should be used when the user asks to "rebase all open PRs", "update all PRs with latest main", "make sure every open PR is up to date with main", "sync all open PRs onto main", "rebase all my PRs", or wants to bring every open pull request current with its base branch by rebasing in parallel git worktrees, resolving conflicts with a team of agents, and force-pushing.
---

# Rebase Open PRs onto Main

Bring every open pull request up to date with the latest base branch. Each PR is
rebased in its own isolated git worktree by a dedicated agent, conflicts are
resolved with real understanding of the code, the result is force-pushed with
`--force-with-lease`, and the worktree is cleaned up afterward. Worktrees give
each agent a private working tree, so all PRs are processed in parallel without
fighting over a shared index.

## Iron laws

- **Confirm before executing.** Force-pushing to open PRs is outward-facing and
  hard to reverse. Always show the PR list and get the go-ahead first.
- **One worktree per PR, fully isolated.** Every agent operates only via
  `git -C "$WORKTREE_PATH"`. Never touch the main checkout or another agent's
  worktree.
- **`--force-with-lease`, never `--force`.** Preserve the safety net against
  clobbering concurrent pushes.
- **Resolve, don't guess.** When a conflict needs a product decision or
  confidence is low, flag it for a human instead of forcing a bad rebase.
- **Reuse, then clean up what you created.** If a worktree already exists for the
  branch, use it and leave it in place. Only remove worktrees this run created.
  Never delete the remote branch — only the local worktree and local branch.

## Workflow

Seed a todo per numbered step; mark each complete as you go.

Scripts live in this skill's directory. Invoke them from the target repo
(diagnostics go to stderr; parse the `KEY=VALUE` / JSON on stdout):

```bash
SK=~/.claude/skills/rebase-open-prs/scripts   # fallback: .claude/skills/...
```

### 1. Preflight

Confirm the working directory is the target repo and is clean enough to work in.
Fetch and identify the default branch:

```bash
git fetch --prune origin
gh repo view --json defaultBranchRef -q .defaultBranchRef.name   # the "main"
```

Rebase each PR onto its **own base branch** (`baseRefName`), which is `main` for
normal PRs. This deliberately avoids breaking PRs stacked on a different base. If
the user insists every PR retarget `main` regardless, note the override.

### 2. Discover open PRs

```bash
"$SK/list-prs.sh"            # add --author @me to limit to your PRs
```

Returns a JSON array. Each item has `rebaseable` and (when skipped) `skipReason`.
Defaults: drafts included, forks excluded (contributor fork branches usually
can't be pushed to — pass `--include-forks` only if push access is known).

### 3. Confirm scope with the user

Present the rebaseable PRs (number, branch, base, title, author) and the skipped
ones with reasons. State plainly: each will be rebased and **force-pushed**.
Get confirmation, and ask whether to include any skipped drafts. Do not proceed
without a clear go-ahead.

### 4. Dispatch a team of agents — one per PR

Spawn one subagent per rebaseable PR (Task/Agent tool, `general-purpose`). Cap
concurrency at ~4–6 at a time and batch the rest, so resolution stays careful and
the machine stays responsive. Give each agent its PR number, branch, and base,
and the **exact per-PR procedure** below plus a pointer to
`references/conflict-resolution.md`.

#### Per-PR procedure (hand this to each agent)

```text
You own PR #<n>, branch <branch>, base <base>. Work ONLY inside your worktree
via `git -C "$WT" ...`. Read ~/.claude/skills/rebase-open-prs/references/
conflict-resolution.md before resolving anything.

1. Prepare an isolated worktree (reuses one if it already exists):
     eval "$(~/.claude/skills/rebase-open-prs/scripts/prepare-worktree.sh <branch>)"
   This sets WORKTREE_PATH, CREATED, BRANCH. Use WT="$WORKTREE_PATH".
2. Rebase: `git -C "$WT" rebase origin/<base>`.
3. If conflicts: run the rebase loop in the reference — list conflicted files,
   resolve each with real understanding (ours = base, theirs = the PR's change),
   stage, `GIT_EDITOR=true git -C "$WT" rebase --continue`, repeat.
   If a conflict needs a product decision or confidence is low: STOP, leave the
   PR un-pushed, and report it for human review.
4. If the rebase made no change (already up to date) or emptied the PR: skip the
   push and report which case.
5. Verify (only if conflicts were resolved and a fast check exists): typecheck/
   lint/most-relevant test. Fix resolution-caused failures.
6. Push: `git -C "$WT" push --force-with-lease origin <branch>`.
   On stale-lease or permission rejection: do NOT force — report it.
7. Clean up (run from the main repo, not inside the worktree):
     ~/.claude/skills/rebase-open-prs/scripts/cleanup-worktree.sh "$WT" <branch> "$CREATED"
   (no-op for reused worktrees; removes only what step 1 created).
8. Return the structured result described in the reference.
```

### 5. Aggregate and report

Collect every agent's result into a summary table — include every PR, including
skipped, flagged, and failed ones:

| PR | Branch | Status | Conflicts | Verify | Worktree | Note |
| -- | ------ | ------ | --------- | ------ | -------- | ---- |

Statuses: `pushed`, `already-up-to-date`, `conflicts-flagged`, `push-rejected`,
`skipped`, `error`. Call out any PR needing human follow-up with its reason.

## Additional resources

### Scripts (`scripts/`)

- **`list-prs.sh`** — open PRs as JSON, annotated with `rebaseable`/`skipReason`
  (`--author`, `--include-forks`, `--skip-drafts`, `--limit`).
- **`prepare-worktree.sh <branch>`** — find-or-create an isolated worktree;
  prints `WORKTREE_PATH`, `CREATED`, `BRANCH`. Reuses any existing worktree for
  the branch (including `wt`-created ones). Override location with
  `PR_WORKTREE_ROOT`.
- **`cleanup-worktree.sh <path> <branch> <created>`** — remove the worktree and
  local branch only when this run created them; reused worktrees are left alone.

### Reference (`references/`)

- **`conflict-resolution.md`** — the rebase loop, how to resolve conflicts
  correctly (ours/theirs semantics), file-type-specific handling (lockfiles,
  generated files, migrations), verification, push rejection handling, and the
  stop conditions that mean "flag for a human, don't force."
