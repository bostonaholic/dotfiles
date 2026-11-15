#!/usr/bin/env bash
################################################################################
# lint_sorted -- Regression Tests
#
# DESCRIPTION:
#   Runs scripts/lint_sorted against the repo's files, then sources it and
#   calls its two checkers (check_json, check_lines) on fixtures, so each
#   passes on sorted input and fails on unsorted input.
#
# USAGE:
#   ./tests/test_lint_sorted.sh   (or run the whole suite via: scripts/test)
#
# EXIT CODE:
#   0 - All tests passed
#   1 - One or more tests failed
#
################################################################################

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LINT="$REPO_ROOT/scripts/lint_sorted"

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

# shellcheck source=scripts/lint_sorted
source "$LINT"

# expect WANT NAME CHECKER ARGS...: run one checker on a fixture and compare
# the status it leaves (0 sorted, 1 not) with WANT.
expect() {
    local want="$1" name="$2" out
    shift 2
    status=0
    out="$("$@" 2>&1; echo "status=$status")"
    if [[ "${out##*status=}" == "$want" ]]; then pass "$name"; else fail "$name" "$out"; fi
}

SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
cd "$SCRATCH"

echo "=== lint_sorted -- Regression Tests ==="
echo ""

echo "T1: the repo's lists are sorted"
if out="$("$LINT" 2>&1)"; then pass "T1"; else fail "T1" "$out"; fi

echo "T2: check_json on a YAML list"
printf 'pkgs:\n  - a\n  - b\n' >sorted.yaml
printf 'pkgs:\n  - b\n  - a\n' >unsorted.yaml
expect 0 "T2 sorted" check_json sorted.yaml '.pkgs'
expect 1 "T2 unsorted" check_json unsorted.yaml '.pkgs'

echo "T3: check_json on JSON object keys"
printf '{"m": {"a": 1, "b": 2}}\n' >sorted.json
printf '{"m": {"b": 1, "a": 2}}\n' >unsorted.json
expect 0 "T3 sorted" check_json sorted.json '.m | keys'
expect 1 "T3 unsorted" check_json unsorted.json '.m | keys'

echo "T4: check_json fails on a missing key or file"
expect 1 "T4 missing key" check_json sorted.json '.absent'
expect 1 "T4 missing file" check_json absent.json '.m'

echo "T5: check_lines compares within a group; comments and blanks end it"
printf '# one\nb\nc\n\n# two\na\nd\n' >groups.txt
printf '# one\nc\nb\n' >bad-group.txt
expect 0 "T5 sorted groups" check_lines groups.txt
expect 1 "T5 unsorted group" check_lines bad-group.txt

echo "T6: check_lines --flat ignores comments and blanks"
expect 1 "T6" check_lines groups.txt --flat

echo "T7: check_lines --entry and --key"
printf "cask 'a'\nbrew 'b'\nother 'A'\nbrew 'c'\n" >keyed.txt
printf "brew 'b'\ncask 'a'\n" >bad-keyed.txt
expect 0 "T7 sorted by key" check_lines keyed.txt --entry '^(brew|cask) ' --key "'[^']*'"
expect 1 "T7 unsorted by key" check_lines bad-keyed.txt --entry '^(brew|cask) ' --key "'[^']*'"

echo "T8: check_lines --from/--to limits the range"
printf 'z\na\n[alias]\na\nb\n[other]\nz\na\n' >range.txt
printf '[alias]\nb\na\n[other]\n' >bad-range.txt
expect 0 "T8 sorted range" check_lines range.txt --from '^\[alias\]' --to '^\['
expect 1 "T8 unsorted range" check_lines bad-range.txt --from '^\[alias\]' --to '^\['

echo "T9: check_lines fails when it finds no entries or no file"
expect 1 "T9 --from never matches" check_lines range.txt --from '^\[absent\]'
expect 1 "T9 missing file" check_lines absent.txt

echo ""
echo "passed: $pass_count  failed: $fail_count"
[[ $fail_count -eq 0 ]]
