#!/usr/bin/env bash
################################################################################
# statusline Repo Name -- Regression Tests
#
# DESCRIPTION:
#   Behavioral tests for the Claude Code status line. Builds a throwaway git
#   repo under a temp directory with a worktree, then feeds each implementation
#   a workspace JSON and asserts the 📁 segment shows the *repo* name.
#
#   Regression coverage for: a worktree must display the parent repo's name
#   (e.g. "myrepo") rather than the worktree directory, whose basename is
#   usually the branch name. The fix derives the name from
#   `git rev-parse --git-common-dir` instead of `--show-toplevel`.
#
#   Both implementations are exercised: claude/statusline.sh (always) and
#   claude/statusline.clj (only when `bb` is on PATH).
#
# USAGE:
#   ./tests/test_statusline.sh        (or run the whole suite via: scripts/test)
#
#   STATUSLINE_SH / STATUSLINE_CLJ override the scripts under test (handy for
#   validating these tests against an older revision to confirm they fail on
#   the bug they guard).
#
# EXIT CODE:
#   0 - All tests passed
#   1 - One or more tests failed
#
################################################################################

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SL_SH="${STATUSLINE_SH:-$REPO_ROOT/claude/statusline.sh}"
SL_CLJ="${STATUSLINE_CLJ:-$REPO_ROOT/claude/statusline.clj}"

# Counters
pass_count=0
fail_count=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass() {
    echo -e "  ${GREEN}PASS${NC}  $1"
    pass_count=$((pass_count + 1))
}

fail() {
    echo -e "  ${RED}FAIL${NC}  $1"
    [[ -n "${2:-}" ]] && echo -e "        $2"
    fail_count=$((fail_count + 1))
}

# Strip ANSI color escapes (BSD/macOS sed has no \x1b, so use a literal ESC).
ESC=$'\033'
strip_ansi() { sed "s/${ESC}\[[0-9;]*m//g"; }

# render <impl> <current_dir> -> color-stripped status line on stdout
render() {
    local impl="$1" dir="$2" json raw
    json=$(jq -n --arg d "$dir" '{workspace: {current_dir: $d}}')
    case "$impl" in
        sh) raw=$(printf '%s' "$json" | bash "$SL_SH") ;;
        clj) raw=$(printf '%s' "$json" | bb "$SL_CLJ") ;;
    esac
    printf '%s' "$raw" | strip_ansi
}

# The 📁 segment label: the token after "📁 " up to the next space.
project_label() { sed -n 's/.*📁 \([^ ]*\).*/\1/p'; }

# Implementations to exercise: the bash script always, the Clojure script only
# when babashka is available.
declare -a IMPLS=(sh)
if command -v bb >/dev/null 2>&1; then
    IMPLS+=(clj)
fi

# ---------------------------------------------------------------------------
# Sandbox: a self-contained git repo with a worktree, removed on exit.
# pwd -P canonicalizes away the /var -> /private/var symlink on macOS.
# ---------------------------------------------------------------------------
SANDBOX="$(cd "$(mktemp -d)" && pwd -P)"
REPO="$SANDBOX/myrepo"
WORKTREE="$REPO/.worktrees/cool-feature"
PLAIN="$SANDBOX/plain/subdir"

# shellcheck disable=SC2329  # invoked indirectly via trap
cleanup() {
    rm -rf "$SANDBOX"
}
trap cleanup EXIT

setup_sandbox() {
    git init -b main "$REPO" >/dev/null

    # Deterministic identity; disable signing (global config signs via 1Password).
    git -C "$REPO" config user.email "test@example.com"
    git -C "$REPO" config user.name "statusline test"
    git -C "$REPO" config commit.gpgsign false
    git -C "$REPO" config tag.gpgsign false

    echo "hello" >"$REPO/README.md"
    git -C "$REPO" add README.md
    git -C "$REPO" commit -m "init" >/dev/null

    # A worktree whose directory basename equals its branch name -- the case
    # where the old --show-toplevel logic lost the repo name.
    git -C "$REPO" worktree add "$WORKTREE" -b cool-feature >/dev/null 2>&1

    # A directory that is not inside any git repo.
    mkdir -p "$PLAIN"
}

echo "=== statusline Repo Name -- Regression Tests ==="
echo "    sh:      $SL_SH"
if [[ " ${IMPLS[*]} " == *" clj "* ]]; then
    echo "    clj:     $SL_CLJ"
else
    echo "    clj:     (skipped: bb not found)"
fi
echo "    Sandbox: $SANDBOX"
echo ""

setup_sandbox

for impl in "${IMPLS[@]}"; do
    echo "--- impl: $impl ---"

    # -----------------------------------------------------------------------
    # T1: a normal checkout shows the repo name and a branch segment
    # -----------------------------------------------------------------------
    line=$(render "$impl" "$REPO")
    label=$(printf '%s' "$line" | project_label)
    if [[ "$label" == "myrepo" ]]; then
        pass "[$impl] T1 repo root shows repo name 'myrepo'"
    else
        fail "[$impl] T1" "expected '📁 myrepo', got label '$label' in: $line"
    fi
    if printf '%s' "$line" | grep -q '🌿'; then
        pass "[$impl] T1 shows a branch segment"
    else
        fail "[$impl] T1" "expected a 🌿 segment in: $line"
    fi

    # -----------------------------------------------------------------------
    # T2: inside a worktree, 📁 shows the REPO name (not the worktree dir /
    #     branch name), and the branch segment shows the worktree's branch.
    #     Regression: worktrees previously showed the branch name as the repo.
    # -----------------------------------------------------------------------
    line=$(render "$impl" "$WORKTREE")
    label=$(printf '%s' "$line" | project_label)
    if [[ "$label" == "myrepo" ]]; then
        pass "[$impl] T2 worktree shows repo name 'myrepo'"
    else
        fail "[$impl] T2" "expected '📁 myrepo', got label '$label' in: $line"
    fi
    if printf '%s' "$line" | grep -q 'cool-feature'; then
        pass "[$impl] T2 worktree shows its branch 'cool-feature'"
    else
        fail "[$impl] T2" "expected branch 'cool-feature' in: $line"
    fi

    # -----------------------------------------------------------------------
    # T3: outside any git repo, show the directory and no branch segment.
    # -----------------------------------------------------------------------
    line=$(render "$impl" "$PLAIN")
    label=$(printf '%s' "$line" | project_label)
    if [[ "$label" == "plain/subdir" ]]; then
        pass "[$impl] T3 non-git dir shows the directory name"
    else
        fail "[$impl] T3" "expected '📁 plain/subdir', got label '$label' in: $line"
    fi
    if printf '%s' "$line" | grep -q '🌿'; then
        fail "[$impl] T3" "expected no 🌿 segment outside a git repo, got: $line"
    else
        pass "[$impl] T3 non-git dir omits the branch segment"
    fi

    echo ""
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo "=== Results ==="
total=$((pass_count + fail_count))
echo -e "  ${GREEN}PASS: $pass_count${NC}  ${RED}FAIL: $fail_count${NC}  TOTAL: $total"
echo ""

if [[ $fail_count -gt 0 ]]; then
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed.${NC}"
    exit 0
fi
