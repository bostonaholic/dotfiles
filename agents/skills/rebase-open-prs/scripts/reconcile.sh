#!/usr/bin/env bash
set -euo pipefail

# reconcile.sh — determine the TRUE outcome of a rebase-open-prs run from git,
# independent of any agent completion notification. This is the orchestrator's
# source of truth: a PR is "done" because the remote says so, not because a
# notification arrived.
#
# Usage: reconcile.sh <manifest>
#
# The manifest is a TAB-separated file, one dispatched PR per line, captured at
# dispatch time (BEFORE any agent ran):
#     <pr>\t<branch>\t<base>\t<pre_rebase_oid>
#
# Fetches the remote (--prune), then for every manifest line emits ONE
# machine-parseable line to stdout:
#     PR=<n> BRANCH=<branch> CURRENT_OID=<oid|missing> REBASED=yes|no|base-missing \
#       OID_CHANGED=yes|no LAST_PUSH=<relative>
# where, per branch:
#   REBASED      yes/no = origin/<base> is now an ancestor of origin/<branch>
#                (rebase landed); base-missing = origin/<base> no longer exists
#                (e.g. a stacked PR whose base was deleted/merged) — flag it, do
#                NOT collapse it into "not rebased".
#   OID_CHANGED  origin/<branch> tip differs from the manifest pre-rebase OID (a push happened)
#   LAST_PUSH    committer-date-relative of the branch tip. A rebase rewrites the
#                committer date, so this approximates when the push happened; for
#                an already-up-to-date branch that was never re-committed it
#                reflects the original commit time. LAST_PUSH is the LAST field
#                and may contain spaces — parse it as everything after "LAST_PUSH=".
# Diagnostics go to stderr; only the data lines go to stdout.

manifest="${1:?usage: reconcile.sh <manifest>}"
[ -f "$manifest" ] || { echo "manifest not found: $manifest" >&2; exit 2; }

echo "Fetching latest remote state…" >&2
git fetch --prune origin >/dev/null 2>&1 \
  || echo "warning: git fetch failed; reporting from local remote-tracking refs" >&2

total=0
rebased_count=0

while IFS=$'\t' read -r pr branch base pre_oid || [ -n "${pr:-}" ]; do
  if [ -z "${pr// /}" ]; then continue; fi      # skip blank lines
  case "$pr" in \#*) continue ;; esac           # skip comments
  total=$((total + 1))

  ref="refs/remotes/origin/$branch"
  if ! current_oid=$(git rev-parse --verify --quiet "${ref}^{commit}"); then
    echo "PR=$pr BRANCH=$branch CURRENT_OID=missing REBASED=no OID_CHANGED=no LAST_PUSH=gone"
    echo "  $branch not found on origin (deleted/merged during the run?)" >&2
    continue
  fi

  base_ref="refs/remotes/origin/$base"
  if ! git rev-parse --verify --quiet "${base_ref}^{commit}" >/dev/null; then
    rebased="base-missing"
    echo "  base $base for $branch not found on origin (deleted/merged stacked base?)" >&2
  elif git merge-base --is-ancestor "$base_ref" "$ref"; then
    rebased=yes
    rebased_count=$((rebased_count + 1))
  else
    rebased=no
  fi

  if [ "$current_oid" = "$pre_oid" ]; then oid_changed=no; else oid_changed=yes; fi

  last_push=$(git log -1 --format=%cr "$ref" 2>/dev/null || echo unknown)

  echo "PR=$pr BRANCH=$branch CURRENT_OID=$current_oid REBASED=$rebased OID_CHANGED=$oid_changed LAST_PUSH=$last_push"
done < "$manifest"

echo "Reconciled $total branch(es); $rebased_count now contain their base." >&2
