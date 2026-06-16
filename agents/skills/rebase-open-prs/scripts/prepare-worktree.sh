#!/usr/bin/env bash
set -euo pipefail

# prepare-worktree.sh — find or create an isolated worktree for a PR branch.
#
# Usage: prepare-worktree.sh <branch>
#
# Reuses an existing worktree if the branch is already checked out in one
# (including worktrees created by other tools such as `wt`). Otherwise creates
# a fresh worktree under $PR_WORKTREE_ROOT (default: a hidden sibling dir of
# the repo, ".pr-rebase-worktrees").
#
# Output (stdout), one KEY=VALUE per line — parse these, ignore everything else:
#   WORKTREE_PATH=<absolute path>
#   CREATED=true|false        # true only when this run created the worktree
#   BRANCH=<branch>
#
# CREATED governs cleanup: only worktrees this run created should be removed.

branch="${1:?usage: prepare-worktree.sh <branch>}"

repo_root=$(git rev-parse --show-toplevel)
worktree_root="${PR_WORKTREE_ROOT:-$(dirname "$repo_root")/.pr-rebase-worktrees}"
sanitized=${branch//\//-}
target="$worktree_root/$sanitized"

# Get the latest remote state so the rebase target and branch tip are current.
git fetch --quiet origin || true

# Reuse if the branch is already checked out in ANY worktree of this repo.
existing=$(git worktree list --porcelain | awk -v b="refs/heads/$branch" '
  $1=="worktree"{p=substr($0, index($0,$2))}
  $1=="branch" && $2==b {print p}
')

if [ -n "$existing" ]; then
  echo "Reusing existing worktree for '$branch' at $existing" >&2
  echo "WORKTREE_PATH=$existing"
  echo "CREATED=false"
  echo "BRANCH=$branch"
  exit 0
fi

mkdir -p "$worktree_root"

# Create the worktree from the local branch if present, else from origin.
if git show-ref --verify --quiet "refs/heads/$branch"; then
  git worktree add "$target" "$branch" >&2
else
  git worktree add -b "$branch" "$target" "origin/$branch" >&2
fi

# Best-effort upstream so a later plain `git push` targets origin/<branch>.
git -C "$target" branch --set-upstream-to="origin/$branch" "$branch" >/dev/null 2>&1 || true

echo "WORKTREE_PATH=$target"
echo "CREATED=true"
echo "BRANCH=$branch"
