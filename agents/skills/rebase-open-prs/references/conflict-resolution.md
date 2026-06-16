# Rebase Conflict Resolution & Edge Cases

Detailed guidance for the per-PR agent. The goal is a correct rebase onto the
latest base branch — never a fast, destructive one. When a conflict cannot be
resolved with confidence, stop and report rather than guess.

## The rebase loop

All git commands run against the assigned worktree via `git -C "$WORKTREE_PATH"`.
Never touch the main checkout or another agent's worktree.

```bash
git -C "$WT" rebase "origin/$BASE"
```

If it exits non-zero, a conflict (or other stop) occurred. Drive the loop:

1. List conflicted files: `git -C "$WT" diff --name-only --diff-filter=U`
2. For each file, open it and resolve every `<<<<<<<` / `=======` / `>>>>>>>`
   marker (see "How to resolve" below).
3. Stage resolved files: `git -C "$WT" add <file>`
4. Continue: `GIT_EDITOR=true git -C "$WT" rebase --continue`
   (`GIT_EDITOR=true` accepts the existing commit message non-interactively.)
5. Repeat until the rebase completes or a stop condition below is hit.

Never run `git rebase --skip` to make conflicts disappear — it silently drops
the PR's commit. Use it only when a commit is genuinely empty because its change
already landed in base (git will say "patch is empty").

## How to resolve a conflict correctly

A rebase replays the PR's commits on top of new base code. In each conflict:

- **`ours` (`<<<<<<< HEAD`)** is the base branch's version (already on main).
- **`theirs` (`>>>>>>> <commit>`)** is the PR's change being replayed.

This is the reverse of a merge — do not blindly keep one side.

Principles:

- **Preserve the PR's intent.** The PR exists to make a change; keep it, adapted
  to the new base. Re-apply the PR's logic on top of base's refactors.
- **Keep both when both are additive.** Two new functions, two new imports, two
  list entries — usually both belong. Merge them, don't choose.
- **Understand before editing.** Read enough surrounding code to know what each
  side does. A conflict in a lockfile, generated file, or migration is resolved
  differently than one in business logic (see below).
- **Match surrounding style** — imports ordering, formatting, naming.
- After resolving, re-read the whole hunk to confirm it compiles logically (no
  leftover markers, no duplicated declarations, no half-merged statements).

## File-type-specific handling

- **Lockfiles** (`package-lock.json`, `yarn.lock`, `Cargo.lock`, `Gemfile.lock`,
  `poetry.lock`): do not hand-merge. Take base's version, finish the rebase, then
  regenerate (`npm install`, `bundle lock`, `cargo build`, etc.) and amend.
- **Generated files / snapshots**: regenerate from source rather than merging.
- **Migrations / ordered sequences**: keep both, but verify ordering/IDs/
  timestamps don't collide; renumber the PR's entry to come after base's.
- **`CHANGELOG.md`**: keep both entries; place the PR's under the right heading.
- **Imports / dependency manifests**: union both sides, then de-duplicate.

## Verify before pushing

A clean rebase (no conflicts) is low-risk — push directly.

If conflicts were resolved, do a lightweight sanity check before force-pushing,
when a fast one is available in the repo (do not run full slow suites across
every PR):

- Typecheck / compile (e.g. `tsc --noEmit`, `go build ./...`, `cargo check`).
- Linter on changed files.
- The single most relevant fast test, if obvious.

If the check fails because of the resolution, fix it. If it fails for unrelated
pre-existing reasons, note it and proceed.

## Pushing

```bash
git -C "$WT" push --force-with-lease origin "$BRANCH"
```

`--force-with-lease` refuses to overwrite if the remote branch advanced since the
last fetch — a safety net against clobbering someone else's push. Never downgrade
to plain `--force`.

If the push is rejected:

- **stale lease / remote moved**: someone pushed to the PR branch. Do NOT
  force. Report it for human review.
- **protected branch / permission denied**: report; cannot push.

## Stop conditions — report, don't force

Abort the PR (leave it un-pushed, run cleanup only if this run created the
worktree) and report when:

- A conflict requires a **product/semantic decision** (two incompatible
  intents), not a mechanical merge.
- Resolution confidence is **low** — guessing risks shipping broken code to an
  open PR.
- The rebase **empties the PR** (all commits already in base) — the PR is
  effectively merged; suggest closing instead.
- The PR's base branch **no longer exists** or the branch is **already current**
  with base (nothing to do — report "already up to date", skip the push).
- Tests/typecheck fail **because of** the resolution and the fix isn't obvious.

Surface these clearly with the affected files and a one-line reason. Per the
fail-loud principle, a flagged PR a human can finish beats a forced bad rebase.

## Per-PR result contract

**The durable result file is the system of record — not the returned message.**
Before cleanup and before returning, ALWAYS write `$RUN_DIR/<pr>.json` (valid
JSON via `jq -n`, per step 7 of the per-PR procedure) to the shared run dir the
orchestrator passed in — never inside the worktree, which cleanup deletes. The
orchestrator reconciles outcomes from this file plus git remote state, so a
dropped completion notification never loses your work.

JSON fields: `pr`, `branch`, `base`, `status`, `conflicts` (count of files
resolved), `verify` (`passed|skipped|failed(why)`), `worktree`
(`created|reused`), `head` (post-rebase HEAD OID), `note` (one line — e.g.
which files needed judgment, why flagged). `status` is one of:
`pushed | already-up-to-date | conflicts-flagged | push-rejected | skipped | error`.

Returning the same summary as a message is a convenience for the orchestrator's
live view; if the harness drops it, reconciliation still recovers the outcome.
