#!/bin/bash
################################################################################
# Interactive Alias Guard -- Acceptance Tests
#
# DESCRIPTION:
#   Verifies that aliases which shadow standard commands (ls, cat, grep, cc,
#   ...) are installed only when ZSH_INTERACTIVE_ALIASES is 1. Each case
#   sources zsh/zshenv and zsh/bostonaholic.plugin.zsh in an isolated ZDOTDIR
#   and reports the resulting flag and alias table.
#
#   The interactive cases need a pty, which script(1) can only allocate when
#   this script's own stdin is a terminal. They skip otherwise.
#
# USAGE:
#   ./tests/test_shell_guard.sh   (or run the whole suite via: scripts/test)
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
skip_count=0

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
    echo -e "  ${YELLOW}SKIP${NC}  $1 ($2)"
    skip_count=$((skip_count + 1))
}

AGENT_MARKERS=(CLAUDECODE CLAUDE_CODE_ENTRYPOINT AI_AGENT CURSOR_AGENT CODEX_SANDBOX)
SHADOWED=(ls cat grep find man top ping df du cc ip)

SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

# Prints "flag:<0|1>" then one "alias:<name>" line per shadowing alias defined.
PROBE="$SCRATCH/probe.zsh"
{
    printf 'source %q/zsh/zshenv\n' "$REPO_ROOT"
    printf 'source %q/zsh/bostonaholic.plugin.zsh 2>/dev/null\n' "$REPO_ROOT"
    printf 'print "flag:$ZSH_INTERACTIVE_ALIASES"\n'
    printf 'for a in %s; do alias $a >/dev/null 2>&1 && print "alias:$a"; done\n' "${SHADOWED[*]}"
    printf 'true\n'
} > "$PROBE"

run_plain() {
    env "$@" ZDOTDIR="$SCRATCH" /bin/zsh -c "source $PROBE" 2>/dev/null
}

# zsh refuses to enable interactive mode without a pty, so script(1) supplies
# one. It also echoes the terminal EOF character into its output.
run_interactive() {
    env "$@" ZDOTDIR="$SCRATCH" \
        script -q /dev/null /bin/zsh -i -c "source $PROBE" 2>/dev/null |
        tr -d '\r\004'
}

has_pty() { [[ -t 0 ]]; }

# Neither field is anchored, to tolerate script(1)'s echoed EOF character.
flag_of() { awk -F'flag:' 'NF > 1 { print $2; exit }' <<<"$1"; }
aliases_of() { sed -n 's/.*alias://p' <<<"$1" | sort | tr '\n' ' '; }

cleared() { printf -- '-u %s ' "${AGENT_MARKERS[@]}"; }
all_shadowed() { printf '%s\n' "${SHADOWED[@]}" | sort | tr '\n' ' '; }

echo "=== Interactive Alias Guard -- Acceptance Tests ==="
echo "    Repo: $REPO_ROOT"
echo ""

# ---------------------------------------------------------------------------
# T1: A non-interactive shell gets no shadowing alias
# ---------------------------------------------------------------------------
echo "T1: non-interactive shell has no shadowing aliases"
out="$(run_plain CLAUDECODE=1)"
if [[ "$(flag_of "$out")" == "0" && -z "$(aliases_of "$out")" ]]; then
    pass "T1"
else
    fail "T1" "flag=$(flag_of "$out") aliases=$(aliases_of "$out")"
fi

# ---------------------------------------------------------------------------
# T2: Clearing every marker is not enough on its own -- interactivity is
#     required too, so scripts and cron never pick these up
# ---------------------------------------------------------------------------
echo "T2: non-interactive shell with no agent marker still has none"
# shellcheck disable=SC2046  # word splitting of the -u flag list is intended
out="$(run_plain $(cleared))"
if [[ "$(flag_of "$out")" == "0" && -z "$(aliases_of "$out")" ]]; then
    pass "T2"
else
    fail "T2" "flag=$(flag_of "$out") aliases=$(aliases_of "$out")"
fi

# ---------------------------------------------------------------------------
# T3: The case that matters -- agents capture this config from an interactive
#     shell, so interactivity alone cannot be the test
# ---------------------------------------------------------------------------
echo "T3: interactive shell with an agent marker has no shadowing aliases"
if ! has_pty; then
    skip "T3" "no tty on stdin"
else
    out="$(run_interactive CLAUDECODE=1)"
    if [[ "$(flag_of "$out")" == "0" && -z "$(aliases_of "$out")" ]]; then
        pass "T3"
    else
        fail "T3" "flag=$(flag_of "$out") aliases=$(aliases_of "$out")"
    fi
fi

# ---------------------------------------------------------------------------
# T4: An interactive shell with no agent marker gets every shadowing alias
# ---------------------------------------------------------------------------
echo "T4: interactive shell with no agent marker gets the shadowing aliases"
if ! has_pty; then
    skip "T4" "no tty on stdin"
else
    # shellcheck disable=SC2046  # word splitting of the -u flag list is intended
    out="$(run_interactive $(cleared))"
    if [[ "$(flag_of "$out")" == "1" && "$(aliases_of "$out")" == "$(all_shadowed)" ]]; then
        pass "T4"
    else
        fail "T4" "flag=$(flag_of "$out") aliases=$(aliases_of "$out") expected=$(all_shadowed)"
    fi
fi

# ---------------------------------------------------------------------------
# T5: common-aliases (rm -i, global aliases) is loaded behind the same guard
# ---------------------------------------------------------------------------
echo "T5: common-aliases is loaded behind the guard"
guarded="$(sed -n '/if (( ZSH_INTERACTIVE_ALIASES ))/,/^fi$/p' "$REPO_ROOT/zsh/zshrc" | sed 's/^ *//')"
if grep -q '^plugins+=(common-aliases)$' <<<"$guarded"; then
    pass "T5"
else
    fail "T5" "zsh/zshrc does not add common-aliases inside a ZSH_INTERACTIVE_ALIASES guard"
fi

echo ""
echo "=== Summary: $pass_count passed, $fail_count failed, $skip_count skipped ==="
[[ $fail_count -eq 0 ]]
