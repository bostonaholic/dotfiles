#!/usr/bin/env bash
################################################################################
# site/build -- Regression Tests
#
# DESCRIPTION:
#   site/build joins site/index.html and bootstrap.sh into the one file served
#   at dotfiles.bostonaholic.dev. It must stay both a web page and a runnable
#   script, so these tests check each side of the published file.
#
#   Coverage:
#   - The built file opens with the bash heredoc, then the HTML page
#   - Piped into /bin/bash (bash 3.2 on a fresh Mac) it runs bootstrap.sh
#   - The build refuses a bootstrap.sh containing '-->' (ends the HTML comment)
#
# USAGE:
#   ./tests/test_site.sh   (or run the whole suite via: scripts/test)
#
# EXIT CODE:
#   0 - All tests passed
#   1 - One or more tests failed
#
################################################################################

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
    [[ -n "${2:-}" ]] && echo "        $2"
    fail_count=$((fail_count + 1))
}

summary() {
    echo ""
    echo "  passed: $pass_count  failed: $fail_count"
    [[ $fail_count -eq 0 ]]
}

SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

echo "site/build"

"$REPO_ROOT/site/build" "$SCRATCH/out" > /dev/null
BUILT="$SCRATCH/out/index.html"

if [[ "$(sed -n 1p "$BUILT")" == ": <<'__INIT_PAGE__'" ]] \
    && [[ "$(sed -n 2p "$BUILT")" == "<!DOCTYPE html>" ]]; then
    pass "opens with the bash heredoc, then the HTML page"
else
    fail "opens with the bash heredoc, then the HTML page" "$(head -2 "$BUILT")"
fi

if /bin/bash -s -- --help < "$BUILT" 2>&1 | grep -q "^Usage: curl dotfiles.bostonaholic.dev"; then
    pass "piped into /bin/bash, runs bootstrap.sh"
else
    fail "piped into /bin/bash, runs bootstrap.sh" "$(/bin/bash -s -- --help < "$BUILT" 2>&1 | head -3)"
fi

# A copy of the repo layout whose bootstrap.sh would break the HTML comment.
mkdir -p "$SCRATCH/repo/site"
cp "$REPO_ROOT/site/build" "$REPO_ROOT/site/index.html" "$SCRATCH/repo/site/"
printf '#!/bin/bash\necho "-->"\n' > "$SCRATCH/repo/bootstrap.sh"
if "$SCRATCH/repo/site/build" "$SCRATCH/bad" > /dev/null 2>&1; then
    fail "refuses a bootstrap.sh containing '-->'"
else
    pass "refuses a bootstrap.sh containing '-->'"
fi

summary
