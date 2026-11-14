#!/bin/bash
################################################################################
# Zsh Config Audit -- Acceptance Tests
#
# DESCRIPTION:
#   Checks the zsh startup files zsh/zshrc and zsh/zprofile.
#
# USAGE:
#   ./tests/test_zsh_audit.sh   (or run the whole suite via: scripts/test)
#
# EXIT CODE:
#   0 - All tests passed
#   1 - One or more tests failed
#
################################################################################

set -euo pipefail

# Resolve repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

echo "=== Zsh Config Audit -- Acceptance Tests ==="
echo "    Repo: $REPO_ROOT"
echo ""

# ---------------------------------------------------------------------------
# T2: tail -2 zsh/zprofile shows 'typeset -U path'
#     Verifies: PATH deduplication added (Step 1.2)
# ---------------------------------------------------------------------------
echo "T2: typeset -U path added at end of zprofile"
if tail -2 "$REPO_ROOT/zsh/zprofile" | grep -q 'typeset -U path'; then
    pass "T2"
else
    fail "T2" "Last 2 lines of zsh/zprofile do not contain 'typeset -U path'"
fi

# ---------------------------------------------------------------------------
# T3: grep -rn '/Users/matthew' zsh/ returns nothing
#     Verifies: No hardcoded paths remain (Step 1.3)
# ---------------------------------------------------------------------------
echo "T3: No hardcoded /Users/matthew paths in zsh/"
if grep -rn '/Users/matthew' "$REPO_ROOT/zsh/" >/dev/null 2>&1; then
    fail "T3" "Hardcoded '/Users/matthew' path found in zsh/"
else
    pass "T3"
fi

# ---------------------------------------------------------------------------
# T4: head -1 zsh/zshrc and head -1 zsh/zprofile both show #!/usr/bin/env zsh
#     Verifies: Shebangs corrected (Step 2.1)
# ---------------------------------------------------------------------------
echo "T4: Shebangs are #!/usr/bin/env zsh"
zshrc_shebang=$(head -1 "$REPO_ROOT/zsh/zshrc")
zprofile_shebang=$(head -1 "$REPO_ROOT/zsh/zprofile")
t4_ok=true
if [[ "$zshrc_shebang" != "#!/usr/bin/env zsh" ]]; then
    t4_ok=false
fi
if [[ "$zprofile_shebang" != "#!/usr/bin/env zsh" ]]; then
    t4_ok=false
fi
if $t4_ok; then
    pass "T4"
else
    fail "T4" "zshrc shebang='$zshrc_shebang', zprofile shebang='$zprofile_shebang'"
fi

# ---------------------------------------------------------------------------
# T6: grep '/usr/local' zsh/zprofile returns nothing;
#     grep 'HOMEBREW_PREFIX' zsh/zprofile matches PATH line
#     Verifies: Intel-era paths removed, curl uses $HOMEBREW_PREFIX (Step 2.3)
# ---------------------------------------------------------------------------
echo "T6: Intel-era /usr/local paths removed, HOMEBREW_PREFIX used"
t6_ok=true
t6_reasons=""
if grep '/usr/local' "$REPO_ROOT/zsh/zprofile" >/dev/null 2>&1; then
    t6_ok=false
    t6_reasons="/usr/local still present in zprofile"
fi
if ! grep 'HOMEBREW_PREFIX' "$REPO_ROOT/zsh/zprofile" >/dev/null 2>&1; then
    t6_ok=false
    t6_reasons="${t6_reasons:+$t6_reasons; }HOMEBREW_PREFIX not found in zprofile"
fi
if $t6_ok; then
    pass "T6"
else
    fail "T6" "$t6_reasons"
fi

# ---------------------------------------------------------------------------
# T7: pyenv is configured with static exports: shims on PATH, no pyenv call
#     at startup (`pyenv init` forks a process on every login shell)
# ---------------------------------------------------------------------------
echo "T7: pyenv configured without running pyenv"
t7_ok=true
t7_reasons=""
if grep -v '^[[:space:]]*#' "$REPO_ROOT/zsh/zprofile" | grep -q 'pyenv init\|$(pyenv'; then
    t7_ok=false
    t7_reasons="zprofile runs pyenv at startup"
fi
if ! grep -q 'export PATH="$PYENV_ROOT/shims:' "$REPO_ROOT/zsh/zprofile"; then
    t7_ok=false
    t7_reasons="${t7_reasons:+$t7_reasons; }pyenv shims not added to PATH"
fi
if $t7_ok; then
    pass "T7"
else
    fail "T7" "$t7_reasons"
fi

# ---------------------------------------------------------------------------
# M3: $(brew --prefix openssl@3) replaced with ${HOMEBREW_PREFIX}/opt/openssl@3
#     Verifies: No subprocess call to brew --prefix in zprofile
# ---------------------------------------------------------------------------
echo "M3: brew --prefix openssl@3 replaced with HOMEBREW_PREFIX variable"
m3_ok=true
m3_reasons=""
if grep -q 'brew --prefix' "$REPO_ROOT/zsh/zprofile" 2>/dev/null; then
    m3_ok=false
    m3_reasons="'brew --prefix openssl@3' subprocess call still present"
fi
if ! grep -q 'HOMEBREW_PREFIX.*/opt/openssl@3' "$REPO_ROOT/zsh/zprofile" 2>/dev/null; then
    m3_ok=false
    m3_reasons="${m3_reasons:+$m3_reasons; }HOMEBREW_PREFIX/opt/openssl@3 not found"
fi
if $m3_ok; then
    pass "M3"
else
    fail "M3" "$m3_reasons"
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
