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
- **Ground truth over notifications.** A PR's outcome is authoritatively
  observable on the git remote and in its on-disk result file — never inferred
  from whether an agent's completion notification arrived. Notifications are an
  optimization; their absence means *reconcile*, not *stall*.
- **Never tail agent `.output` files.** They are full JSONL transcripts and will
  overflow the orchestrator's context. Verify outcomes ONLY via git remote state
  (`reconcile.sh`) or the per-PR result JSON — never by reading agent transcripts.

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
the shared `$RUN_DIR` (below), and the **exact per-PR procedure** below plus a
pointer to `references/conflict-resolution.md`.

#### Before dispatching: durable run dir + pre-rebase OID manifest

Agents work in isolated worktrees, so the run directory MUST be a shared,
absolute path that lives *outside* every worktree — anchor it at the git common
dir (the single `.git` shared by all worktrees). A relative path like
`.rebase-run/` is a trap: it resolves inside each agent's own worktree and gets
deleted by cleanup. Derive `$RUN_DIR` once and hand the absolute value to every
agent:

```bash
RUN_DIR="$(git rev-parse --path-format=absolute --git-common-dir)/rebase-run"
rm -rf "$RUN_DIR" && mkdir -p "$RUN_DIR"      # clear any stale prior-run files
: > "$RUN_DIR/manifest.tsv"
```

Capture each rebaseable PR's PRE-REBASE remote OID into the manifest — one
TAB-separated line `pr⇥branch⇥base⇥pre_oid`. This baseline makes later
verification mechanical (OID changed + base now an ancestor ⇒ rebased+pushed;
OID unchanged ⇒ not pushed):

```bash
# for each rebaseable PR's pr/branch/base from step 2 (origin/* is current after preflight):
if oid=$(git rev-parse --verify --quiet "origin/$branch^{commit}"); then
  printf '%s\t%s\t%s\t%s\n' "$pr" "$branch" "$base" "$oid" >> "$RUN_DIR/manifest.tsv"
else
  echo "skip PR #$pr — branch $branch not found on origin" >&2   # vanished at dispatch
fi
```

Guard the OID lookup with `--verify --quiet`: a bare `git rev-parse "origin/$ghost"`
prints the literal string back and exits non-zero, which would write a non-OID
`pre_oid` and make that branch read `OID_CHANGED=yes` forever.

#### Per-PR procedure (hand this to each agent)

```text
You own PR #<n>, branch <branch>, base <base>. RUN_DIR=<absolute run dir>.
Work ONLY inside your worktree via `git -C "$WT" ...`. Read ~/.claude/skills/
rebase-open-prs/references/conflict-resolution.md before resolving anything.

1. Prepare an isolated worktree (reuses one if it already exists):
     eval "$(~/.claude/skills/rebase-open-prs/scripts/prepare-worktree.sh <branch>)"
   This sets WORKTREE_PATH, CREATED, BRANCH. Use WT="$WORKTREE_PATH".
2. Rebase: `git -C "$WT" rebase origin/<base>`.
3. If conflicts: run the rebase loop in the reference — list conflicted files,
   resolve each with real understanding (ours = base, theirs = the PR's change),
   stage, `GIT_EDITOR=true git -C "$WT" rebase --continue`, repeat.
   If a conflict needs a product decision or confidence is low: STOP, leave the
   PR un-pushed, and record status conflicts-flagged in step 7.
4. If the rebase made no change (already up to date) or emptied the PR: skip the
   push and record which case in step 7.
5. Verify (only if conflicts were resolved and a fast check exists): typecheck/
   lint/most-relevant test. Fix resolution-caused failures.
6. Push: `git -C "$WT" push --force-with-lease origin <branch>`.
   On stale-lease or permission rejection: do NOT force — record push-rejected.
7. PERSIST THE RESULT — do this ALWAYS (even on flag/failure) and BEFORE
   cleanup or returning. Write valid JSON to the SHARED $RUN_DIR (never inside
   $WT — step 8 deletes it). This file, not the returned message, is the system
   of record:
     jq -n --argjson pr <n> --arg branch "<branch>" --arg base "<base>" \
       --arg status "<pushed|already-up-to-date|conflicts-flagged|push-rejected|skipped|error>" \
       --argjson conflicts <files-resolved-count> \
       --arg verify "<passed|skipped|failed(reason)>" --arg created "$CREATED" \
       --arg head "$(git -C "$WT" rev-parse HEAD 2>/dev/null || echo unknown)" \
       --arg note "<one line>" \
       '{pr:$pr,branch:$branch,base:$base,status:$status,conflicts:$conflicts,
         verify:$verify,worktree:(if $created=="true" then "created" else "reused" end),
         head:$head,note:$note}' \
       > "$RUN_DIR/<n>.json"
8. Clean up (run from the main repo, not inside the worktree):
     ~/.claude/skills/rebase-open-prs/scripts/cleanup-worktree.sh "$WT" <branch> "$CREATED"
   (no-op for reused worktrees; removes only what step 1 created).
9. Returning a structured message is a convenience — if the harness drops it,
   the orchestrator still recovers your outcome from $RUN_DIR/<n>.json + git.
```

### 5. Reconcile against ground truth, then report

Do NOT decide a PR is done because a notification arrived, and do NOT wait on
notifications indefinitely — they are dropped sometimes. The git remote and the
on-disk result files are the system of record. Reconciliation is **mandatory**
before reporting, and it is independent of notifications.

Run reconciliation (read-only and idempotent — safe to re-run while agents are
still finishing):

```bash
"$SK/reconcile.sh" "$RUN_DIR/manifest.tsv"
```

For each dispatched PR, combine its reconcile line with `$RUN_DIR/<pr>.json` and
derive status from THAT — never from notification presence. Two precedence rules
resolve every case and keep failures loud:

- **The result file owns the agent's action; git owns remote truth.** A terminal
  failure status in the file (`conflicts-flagged`, `push-rejected`, `error`,
  `skipped`) is authoritative — git showing the branch contains base does NOT
  upgrade it to `pushed` (the branch may already have contained base, e.g. via an
  earlier merge). Report the file's status.
- **Any disagreement is surfaced, never silently resolved.** When git contradicts
  the file (a claimed `pushed` not reflected on the remote; a remote move the file
  didn't claim), report **`needs-review`** with both signals — do not guess.

Result file present:

| result file `status` | expected reconcile | derived status |
| -------------------- | ------------------ | -------------- |
| `pushed` | `REBASED=yes OID_CHANGED=yes` | **pushed** (confirmed by git, notification or not) |
| `pushed` | anything else | **needs-review** (claimed push not on remote) |
| `already-up-to-date` | `REBASED=yes OID_CHANGED=no` | **already-up-to-date** |
| `conflicts-flagged`/`push-rejected`/`error`/`skipped` | any | **take the file's status** (append `needs-review` only if `OID_CHANGED=yes` — remote moved unexpectedly) |

Result file missing (agent died before persisting — fall back to git alone):

| reconcile signal | derived status |
| ---------------- | -------------- |
| `REBASED=yes OID_CHANGED=yes` | **pushed** (push is real; agent died after) |
| `REBASED=yes OID_CHANGED=no` | **already-up-to-date** |
| `REBASED=no OID_CHANGED=yes` | **needs-review** (pushed but base not contained — wrong/stale base, or origin/base advanced after the agent fetched) |
| `REBASED=no OID_CHANGED=no` | **in-progress / died** — probe liveness (below) |

Independent of the result file: `CURRENT_OID=missing` ⇒ **branch-gone**
(merged/closed during the run); `REBASED=base-missing` ⇒ **needs-review** (the
PR's base branch no longer exists — an orphaned stacked PR).

**Bounded wait + liveness probe.** After dispatching a batch, give agents time to
work, then reconcile — do not block on a notification that may never arrive. For a
PR still showing no result file and no remote change, probe that agent with
`SendMessage`: a reply of **"had no active task"** means it has already come to
rest (done, not hung) — trust git/result files and stop waiting. A live agent
means give it longer, then reconcile again. **Bound the probe**: retry at most ~3
times (a few minutes total); if a PR still has no result file, no remote change,
and the agent never returns "had no active task", declare it **`error` (agent
unresponsive — verify manually)** and move on. Never loop forever — that is the
stall this whole design exists to prevent.

Then produce the summary table (every PR — including skipped, flagged, failed,
needs-review, and branch-gone):

| PR | Branch | Status | Conflicts | Verify | Worktree | Note |
| -- | ------ | ------ | --------- | ------ | -------- | ---- |

Statuses: `pushed`, `already-up-to-date`, `conflicts-flagged`, `push-rejected`,
`skipped`, `needs-review`, `branch-gone`, `error`. Call out any PR needing human
follow-up.

Optionally remove `$RUN_DIR` when done — it lives under `.git`, so it never
pollutes the working tree even if left.

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
- **`reconcile.sh <manifest>`** — the orchestrator's source of truth. Fetches
  `--prune`, then per dispatched branch emits `PR=… BRANCH=… CURRENT_OID=…
  REBASED=… OID_CHANGED=… LAST_PUSH=…` so final status is derived from git, not
  from completion notifications. Consumes the `pr⇥branch⇥base⇥pre_oid` manifest
  written at dispatch.

### Reference (`references/`)

- **`conflict-resolution.md`** — the rebase loop, how to resolve conflicts
  correctly (ours/theirs semantics), file-type-specific handling (lockfiles,
  generated files, migrations), verification, push rejection handling, and the
  stop conditions that mean "flag for a human, don't force."
