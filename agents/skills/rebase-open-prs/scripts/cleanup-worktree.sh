#!/usr/bin/env bash
set -euo pipefail

# cleanup-worktree.sh — remove a worktree and local branch created for a rebase.
#
# Usage: cleanup-worktree.sh <worktree-path> <branch> <created-flag>
#
# Run this from the MAIN repo checkout, not from inside the worktree being
# removed. Only worktrees this skill created (created-flag=true) are removed;
# pre-existing/reused worktrees are left untouched. The REMOTE PR branch is
# never deleted — only the local worktree and local branch are cleaned up.

worktree_path="${1:?usage: cleanup-worktree.sh <path> <branch> <created>}"
branch="${2:?missing branch}"
created="${3:?missing created flag}"

if [ "$created" != "true" ]; then
  echo "Reused pre-existing worktree at $worktree_path — leaving it in place." >&2
  exit 0
fi

git worktree remove --force "$worktree_path" 2>/dev/null || true
git worktree prune >/dev/null 2>&1 || true
# Delete the local branch only; the remote branch backing the PR is untouched.
git branch -D "$branch" >/dev/null 2>&1 || true

echo "Cleaned up worktree $worktree_path and local branch $branch." >&2
