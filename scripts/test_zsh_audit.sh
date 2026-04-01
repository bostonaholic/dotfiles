#!/bin/bash
################################################################################
# Zsh Config Audit -- Acceptance Tests
#
# DESCRIPTION:
#   Runs all verification tests (T1-T13) from the zsh config audit plan.
#   Tests verify the state of zsh configuration files after implementation.
#   Before implementation, all tests should FAIL (confirming issues exist).
#   After implementation, all tests should PASS.
#
# USAGE:
#   ./scripts/test_zsh_audit.sh
#
# EXIT CODE:
#   0 - All tests passed
#   1 - One or more tests failed
#
# PLAN:
#   docs/plans/2026-04-01-zsh-config-audit-plan.md
#
################################################################################

set -euo pipefail

# Resolve repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Counters
pass_count=0
fail_count=0
skip_count=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
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

skip() {
    echo -e "  ${YELLOW}SKIP${NC}  $1 (manual)"
    skip_count=$((skip_count + 1))
}

echo "=== Zsh Config Audit -- Acceptance Tests ==="
echo "    Repo: $REPO_ROOT"
echo ""

# ---------------------------------------------------------------------------
# T1: grep -rn HISTCONTROL zsh/ returns nothing
#     Verifies: Bash-ism removed (Step 1.1)
# ---------------------------------------------------------------------------
echo "T1: HISTCONTROL bash-ism removed from plugin"
if grep -rn HISTCONTROL "$REPO_ROOT/zsh/" >/dev/null 2>&1; then
    fail "T1" "HISTCONTROL still present in zsh/"
else
    pass "T1"
fi

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
# T5: bostonaholic.zsh-theme file deleted; no references in dotfiles.yaml
#     Verifies: Dead theme and directory entry removed (Step 2.2)
# ---------------------------------------------------------------------------
echo "T5: Dead theme file and dotfiles.yaml entries removed"
t5_ok=true
t5_reasons=""
if [[ -f "$REPO_ROOT/zsh/bostonaholic.zsh-theme" ]]; then
    t5_ok=false
    t5_reasons="theme file still exists"
fi
if grep -q 'zsh-theme' "$REPO_ROOT/dotfiles.yaml" 2>/dev/null; then
    t5_ok=false
    t5_reasons="${t5_reasons:+$t5_reasons; }dotfiles.yaml still references zsh-theme"
fi
if grep -q 'custom/themes' "$REPO_ROOT/dotfiles.yaml" 2>/dev/null; then
    t5_ok=false
    t5_reasons="${t5_reasons:+$t5_reasons; }dotfiles.yaml still references custom/themes"
fi
if $t5_ok; then
    pass "T5"
else
    fail "T5" "$t5_reasons"
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
# T7: pyenv guard with command -v check and standalone elif fallback;
#     Homebrew branch uses 'pyenv root', standalone branch uses $HOME/.pyenv
#     Verifies: pyenv guard handles Homebrew and standalone (Step 2.4)
# ---------------------------------------------------------------------------
echo "T7: pyenv block has defensive guard"
t7_ok=true
t7_reasons=""
if ! grep -A1 'pyenv configuration' "$REPO_ROOT/zsh/zprofile" | grep -q 'command -v pyenv'; then
    t7_ok=false
    t7_reasons="missing 'command -v pyenv' guard"
fi
if ! grep -q 'elif.*-d.*\.pyenv' "$REPO_ROOT/zsh/zprofile" 2>/dev/null; then
    t7_ok=false
    t7_reasons="${t7_reasons:+$t7_reasons; }missing elif fallback for standalone ~/.pyenv"
fi
if $t7_ok; then
    pass "T7"
else
    fail "T7" "$t7_reasons"
fi

# ---------------------------------------------------------------------------
# T8: grep '#pyenv\|#python' zsh/zshrc returns nothing
#     Verifies: Commented-out plugin entries removed (Step 2.5)
# ---------------------------------------------------------------------------
echo "T8: Commented-out plugin entries removed"
if grep -E '#pyenv|#python' "$REPO_ROOT/zsh/zshrc" >/dev/null 2>&1; then
    fail "T8" "#pyenv or #python still present in zshrc"
else
    pass "T8"
fi

# ---------------------------------------------------------------------------
# T9: shellcheck scripts/install_fzf_tab passes; file is executable
#     Verifies: Install script valid (Step 3.1)
# ---------------------------------------------------------------------------
echo "T9: scripts/install_fzf_tab exists, passes shellcheck, is executable"
t9_ok=true
t9_reasons=""
if [[ ! -f "$REPO_ROOT/scripts/install_fzf_tab" ]]; then
    t9_ok=false
    t9_reasons="file does not exist"
else
    if [[ ! -x "$REPO_ROOT/scripts/install_fzf_tab" ]]; then
        t9_ok=false
        t9_reasons="file is not executable"
    fi
    if command -v shellcheck >/dev/null 2>&1; then
        if ! shellcheck "$REPO_ROOT/scripts/install_fzf_tab" >/dev/null 2>&1; then
            t9_ok=false
            t9_reasons="${t9_reasons:+$t9_reasons; }shellcheck failed"
        fi
    else
        t9_ok=false
        t9_reasons="shellcheck not installed"
    fi
fi
if $t9_ok; then
    pass "T9"
else
    fail "T9" "$t9_reasons"
fi

# ---------------------------------------------------------------------------
# T10: grep 'install_fzf_tab' dotfiles.yaml matches
#      Verifies: Automation wired up in dotfiles.yaml (Step 3.2)
# ---------------------------------------------------------------------------
echo "T10: fzf-tab install wired into dotfiles.yaml"
if grep -q 'install_fzf_tab' "$REPO_ROOT/dotfiles.yaml" 2>/dev/null; then
    pass "T10"
else
    fail "T10" "install_fzf_tab not referenced in dotfiles.yaml"
fi

# ---------------------------------------------------------------------------
# T11: grep 'fzf-tab' zsh/zshrc shows no trailing comment
#      Verifies: Manual clone note removed (Step 3.3)
# ---------------------------------------------------------------------------
echo "T11: fzf-tab plugin line has no trailing comment"
fzf_tab_line=$(grep 'fzf-tab' "$REPO_ROOT/zsh/zshrc" 2>/dev/null || true)
if [[ -z "$fzf_tab_line" ]]; then
    fail "T11" "fzf-tab not found in zshrc at all"
elif echo "$fzf_tab_line" | grep -q '#'; then
    fail "T11" "fzf-tab line still has a trailing comment"
else
    pass "T11"
fi

# ---------------------------------------------------------------------------
# T12: ./install.sh --dry-run completes without error
#      SKIP: Requires full install.sh execution environment
# ---------------------------------------------------------------------------
echo "T12: install.sh --dry-run completes without error"
skip "T12"

# ---------------------------------------------------------------------------
# T13: New terminal starts without errors
#      SKIP: Cannot be automated in a script
# ---------------------------------------------------------------------------
echo "T13: New terminal starts without errors"
skip "T13"

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
total=$((pass_count + fail_count + skip_count))
echo -e "  ${GREEN}PASS: $pass_count${NC}  ${RED}FAIL: $fail_count${NC}  ${YELLOW}SKIP: $skip_count${NC}  TOTAL: $total"
echo ""

if [[ $fail_count -gt 0 ]]; then
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed.${NC}"
    exit 0
fi
