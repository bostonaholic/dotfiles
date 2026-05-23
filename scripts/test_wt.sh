#!/usr/bin/env bash
################################################################################
# wt Worktree Resolution -- Regression Tests
#
# DESCRIPTION:
#   Behavioral tests for bin/wt. Builds a throwaway git repo (with a local bare
#   remote) under a temp directory, creates worktrees both inside and outside
#   the .worktrees/ convention, then exercises `wt cd`, `wt path`, and `wt rm`.
#
#   Regression coverage for:
#     - f6f18cb  `wt cd main` resolves to the repo root
#     - 2e44842  worktrees outside .worktrees/ are resolved by basename
#
# USAGE:
#   ./scripts/test_wt.sh
#
# EXIT CODE:
#   0 - All tests passed
#   1 - One or more tests failed
#
# RELATED:
#   bd-5s6 (Add regression tests for bin/wt worktree resolution)
#
################################################################################

set -euo pipefail

# Resolve repo root and the wt binary under test.
# WT_BIN overrides the binary (handy for validating the tests against an older
# revision of wt to confirm they fail on the bugs they guard).
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WT="${WT_BIN:-$REPO_ROOT/bin/wt}"

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

# ---------------------------------------------------------------------------
# Sandbox: a self-contained git repo with worktrees, removed on exit.
# pwd -P canonicalizes away the /var -> /private/var symlink on macOS so the
# paths git records match the literals we assert against.
# ---------------------------------------------------------------------------
SANDBOX="$(cd "$(mktemp -d)" && pwd -P)"
REPO="$SANDBOX/repo"
REMOTE="$SANDBOX/remote.git"

# shellcheck disable=SC2329  # invoked indirectly via trap
cleanup() {
    rm -rf "$SANDBOX"
}
trap cleanup EXIT

setup_sandbox() {
    git init --bare -b main "$REMOTE" >/dev/null
    git init -b main "$REPO" >/dev/null

    # Deterministic identity; disable signing (global config signs via 1Password).
    git -C "$REPO" config user.email "test@example.com"
    git -C "$REPO" config user.name "wt test"
    git -C "$REPO" config commit.gpgsign false
    git -C "$REPO" config tag.gpgsign false

    echo "hello" >"$REPO/README.md"
    git -C "$REPO" add README.md
    git -C "$REPO" commit -m "init" >/dev/null

    # Wire up origin/HEAD so `wt`'s main-branch detection exercises the real
    # `symbolic-ref refs/remotes/origin/HEAD` path rather than the fallback.
    git -C "$REPO" remote add origin "$REMOTE"
    git -C "$REPO" push -u origin main >/dev/null 2>&1
    git -C "$REPO" remote set-head origin main >/dev/null

    # A worktree under the .worktrees/ convention...
    git -C "$REPO" worktree add "$REPO/.worktrees/feature" -b feature >/dev/null 2>&1
    # ...and one outside it (mirrors the Team plugin's .claude/worktrees/).
    git -C "$REPO" worktree add "$REPO/.claude/worktrees/external" -b external >/dev/null 2>&1
}

echo "=== wt Worktree Resolution -- Regression Tests ==="
echo "    Binary:  $WT"
echo "    Sandbox: $SANDBOX"
echo ""

setup_sandbox

# ---------------------------------------------------------------------------
# T1: `wt cd <name>` resolves a .worktrees/ worktree to its path
# ---------------------------------------------------------------------------
echo "T1: wt cd resolves a .worktrees/ worktree"
expected="$REPO/.worktrees/feature"
if out=$(cd "$REPO" && "$WT" cd feature 2>/dev/null); then
    if [[ "$out" == "$expected" ]]; then
        pass "T1"
    else
        fail "T1" "expected '$expected', got '$out'"
    fi
else
    fail "T1" "wt cd feature exited non-zero"
fi

# ---------------------------------------------------------------------------
# T2: `wt path <name>` matches `wt cd <name>` (path delegates to cd)
# ---------------------------------------------------------------------------
echo "T2: wt path matches wt cd"
expected="$REPO/.worktrees/feature"
if out=$(cd "$REPO" && "$WT" path feature 2>/dev/null); then
    if [[ "$out" == "$expected" ]]; then
        pass "T2"
    else
        fail "T2" "expected '$expected', got '$out'"
    fi
else
    fail "T2" "wt path feature exited non-zero"
fi

# ---------------------------------------------------------------------------
# T3: `wt cd <name>` resolves a worktree OUTSIDE .worktrees/ by basename
#     Regression: 2e44842
# ---------------------------------------------------------------------------
echo "T3: wt cd resolves a worktree outside .worktrees/ (regression 2e44842)"
expected="$REPO/.claude/worktrees/external"
if out=$(cd "$REPO" && "$WT" cd external 2>/dev/null); then
    if [[ "$out" == "$expected" ]]; then
        pass "T3"
    else
        fail "T3" "expected '$expected', got '$out'"
    fi
else
    fail "T3" "wt cd external exited non-zero"
fi

# ---------------------------------------------------------------------------
# T4: `wt cd main` resolves to the repo root
#     Regression: f6f18cb
# ---------------------------------------------------------------------------
echo "T4: wt cd main resolves to repo root (regression f6f18cb)"
if out=$(cd "$REPO" && "$WT" cd main 2>/dev/null); then
    if [[ "$out" == "$REPO" ]]; then
        pass "T4"
    else
        fail "T4" "expected '$REPO', got '$out'"
    fi
else
    fail "T4" "wt cd main exited non-zero"
fi

# ---------------------------------------------------------------------------
# T5: `wt cd <unknown>` exits non-zero and reports "Worktree not found"
# ---------------------------------------------------------------------------
echo "T5: wt cd <unknown> fails with a clear error"
errfile="$SANDBOX/t5.err"
if (cd "$REPO" && "$WT" cd does-not-exist) >/dev/null 2>"$errfile"; then
    fail "T5" "expected non-zero exit for unknown worktree"
elif grep -q "Worktree not found" "$errfile"; then
    pass "T5"
else
    fail "T5" "exited non-zero but error message missing: $(cat "$errfile")"
fi

# ---------------------------------------------------------------------------
# T6: `wt rm <name>` removes a .worktrees/ worktree and deletes its branch
# ---------------------------------------------------------------------------
echo "T6: wt rm removes a .worktrees/ worktree and its branch"
if (cd "$REPO" && "$WT" rm feature) >/dev/null 2>&1; then
    if [[ -d "$REPO/.worktrees/feature" ]]; then
        fail "T6" "worktree directory still exists"
    elif git -C "$REPO" show-ref --verify --quiet refs/heads/feature; then
        fail "T6" "local branch 'feature' was not deleted"
    else
        pass "T6"
    fi
else
    fail "T6" "wt rm feature exited non-zero"
fi

# ---------------------------------------------------------------------------
# T7: `wt rm <name>` removes a worktree OUTSIDE .worktrees/
#     Regression: 2e44842 (previously failed with "Worktree not found")
# ---------------------------------------------------------------------------
echo "T7: wt rm removes a worktree outside .worktrees/ (regression 2e44842)"
if (cd "$REPO" && "$WT" rm external) >/dev/null 2>&1; then
    if [[ -d "$REPO/.claude/worktrees/external" ]]; then
        fail "T7" "worktree directory still exists"
    elif git -C "$REPO" show-ref --verify --quiet refs/heads/external; then
        fail "T7" "local branch 'external' was not deleted"
    else
        pass "T7"
    fi
else
    fail "T7" "wt rm external exited non-zero"
fi

# ---------------------------------------------------------------------------
# T8: `wt rm main` refuses to remove the main branch and leaves it intact
# ---------------------------------------------------------------------------
echo "T8: wt rm main is refused"
errfile="$SANDBOX/t8.err"
if (cd "$REPO" && "$WT" rm main) >/dev/null 2>"$errfile"; then
    fail "T8" "expected non-zero exit when removing main"
elif ! grep -q "Cannot remove the main branch" "$errfile"; then
    fail "T8" "wrong error message: $(cat "$errfile")"
elif [[ ! -d "$REPO" ]] || [[ ! -e "$REPO/README.md" ]]; then
    fail "T8" "repo root was damaged"
else
    pass "T8"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
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
