#!/usr/bin/env bash
################################################################################
# lint_claude_plugins -- Regression Tests
#
# DESCRIPTION:
#   Runs scripts/lint_claude_plugins against the repo's files and against
#   fixtures, so the lint passes on sorted lists and fails on unsorted ones.
#
# USAGE:
#   ./tests/test_lint_claude_plugins.sh   (or run the whole suite via: scripts/test)
#
# EXIT CODE:
#   0 - All tests passed
#   1 - One or more tests failed
#
################################################################################

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LINT="$REPO_ROOT/scripts/lint_claude_plugins"

pass_count=0
fail_count=0

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

SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

printf '{"enabledPlugins": {"a@m": true, "b@m": true}}\n' >"$SCRATCH/sorted.json"
printf '{"enabledPlugins": {"b@m": true, "a@m": true}}\n' >"$SCRATCH/unsorted.json"
printf 'packages:\n  claude:\n    plugins:\n      - a@m\n      - b@m\n' >"$SCRATCH/sorted.yaml"
printf 'packages:\n  claude:\n    plugins:\n      - b@m\n      - a@m\n' >"$SCRATCH/unsorted.yaml"

echo "=== lint_claude_plugins -- Regression Tests ==="
echo ""

echo "T1: the repo's plugin lists are sorted"
if out="$("$LINT" 2>&1)"; then pass "T1"; else fail "T1" "$out"; fi

echo "T2: sorted fixtures pass"
if out="$("$LINT" "$SCRATCH/sorted.json" "$SCRATCH/sorted.yaml" 2>&1)"; then
    pass "T2"
else
    fail "T2" "$out"
fi

echo "T3: unsorted enabledPlugins fails"
if "$LINT" "$SCRATCH/unsorted.json" "$SCRATCH/sorted.yaml" >/dev/null 2>&1; then
    fail "T3" "lint passed on unsorted settings.json"
else
    pass "T3"
fi

echo "T4: unsorted packages.claude.plugins fails"
if "$LINT" "$SCRATCH/sorted.json" "$SCRATCH/unsorted.yaml" >/dev/null 2>&1; then
    fail "T4" "lint passed on unsorted dotfiles.yaml"
else
    pass "T4"
fi

echo "T5: missing enabledPlugins key fails"
printf '{}\n' >"$SCRATCH/empty.json"
if "$LINT" "$SCRATCH/empty.json" "$SCRATCH/sorted.yaml" >/dev/null 2>&1; then
    fail "T5" "lint passed with no enabledPlugins"
else
    pass "T5"
fi

echo ""
echo "passed: $pass_count  failed: $fail_count"
[[ $fail_count -eq 0 ]]
