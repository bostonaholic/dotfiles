#!/bin/bash
################################################################################
# Human-Shell Guard -- Acceptance Tests
#
# DESCRIPTION:
#   Verifies that aliases which shadow standard commands (ls, cat, grep, cc,
#   ...) are installed only when ZSH_HUMAN_SHELL is 1, i.e. when a person is
#   driving the shell. Coding agents shell out through this config and expect
#   POSIX behavior, so those aliases must be absent for them.
#
#   Each case sources zsh/zshenv and zsh/bostonaholic.plugin.zsh in an isolated
#   ZDOTDIR and reports the resulting flag and aliases.
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

# Shadowing aliases the guard is responsible for. `wt`/`compdef` noise from the
# plugin is irrelevant here, so only the alias table is inspected.
SHADOWED=(ls cat grep find man top ping df du cc ip)

SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

# The probe sources the two files under test and prints "flag:<0|1>" followed
# by one "alias:<name>" line per shadowing alias that ended up defined.
PROBE="$SCRATCH/probe.zsh"
{
    printf 'source %q/zsh/zshenv\n' "$REPO_ROOT"
    printf 'source %q/zsh/bostonaholic.plugin.zsh 2>/dev/null\n' "$REPO_ROOT"
    printf 'print "flag:$ZSH_HUMAN_SHELL"\n'
    printf 'for a in %s; do alias $a >/dev/null 2>&1 && print "alias:$a"; done\n' "${SHADOWED[*]}"
    printf 'true\n'
} > "$PROBE"

# Run the probe in a non-interactive zsh.
run_plain() {
    env "$@" ZDOTDIR="$SCRATCH" /bin/zsh -c "source $PROBE" 2>/dev/null
}

# Run the probe in an interactive zsh attached to a pty. zsh refuses to enable
# interactive mode without one, so script(1) supplies it; it also echoes the
# terminal EOF character, which is stripped along with the CRs it inserts.
run_interactive() {
    env "$@" ZDOTDIR="$SCRATCH" \
        script -q /dev/null /bin/zsh -i -c "source $PROBE" 2>/dev/null |
        tr -d '\r\004'
}

# script(1) prefixes its first line of output with the echoed EOF character
# rendered as "^D", so neither field is anchored to the start of the line.
flag_of() { sed -n 's/.*flag://p' <<<"$1" | head -1; }
aliases_of() { sed -n 's/.*alias://p' <<<"$1" | sort | tr '\n' ' '; }

echo "=== Human-Shell Guard -- Acceptance Tests ==="
echo "    Repo: $REPO_ROOT"
echo ""

# ---------------------------------------------------------------------------
# T1: A non-interactive shell is not a human shell and gets no shadowing alias
# ---------------------------------------------------------------------------
echo "T1: non-interactive shell has no shadowing aliases"
out="$(run_plain CLAUDECODE=1)"
if [[ "$(flag_of "$out")" == "0" && -z "$(aliases_of "$out")" ]]; then
    pass "T1"
else
    fail "T1" "flag=$(flag_of "$out") aliases=$(aliases_of "$out")"
fi

# ---------------------------------------------------------------------------
# T2: An interactive shell with an agent marker is still not a human shell.
#     This is the case that matters: agents capture this config from an
#     interactive shell, so interactivity alone cannot be the test.
# ---------------------------------------------------------------------------
echo "T2: interactive shell with CLAUDECODE set has no shadowing aliases"
if [[ "$(uname -s)" != "Darwin" ]]; then
    skip "T2" "needs BSD script(1) for a pty"
else
    out="$(run_interactive CLAUDECODE=1)"
    if [[ "$(flag_of "$out")" == "0" && -z "$(aliases_of "$out")" ]]; then
        pass "T2"
    else
        fail "T2" "flag=$(flag_of "$out") aliases=$(aliases_of "$out")"
    fi
fi

# ---------------------------------------------------------------------------
# T3: An interactive shell with no agent marker is a human shell and gets
#     every shadowing alias
# ---------------------------------------------------------------------------
echo "T3: interactive shell with no agent marker gets the shadowing aliases"
if [[ "$(uname -s)" != "Darwin" ]]; then
    skip "T3" "needs BSD script(1) for a pty"
else
    out="$(run_interactive -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT -u AI_AGENT \
                           -u CURSOR_AGENT -u CODEX_SANDBOX)"
    expected="$(printf '%s\n' "${SHADOWED[@]}" | sort | tr '\n' ' ')"
    if [[ "$(flag_of "$out")" == "1" && "$(aliases_of "$out")" == "$expected" ]]; then
        pass "T3"
    else
        fail "T3" "flag=$(flag_of "$out") aliases=$(aliases_of "$out") expected=$expected"
    fi
fi

# ---------------------------------------------------------------------------
# T4: common-aliases (rm -i, global aliases) is loaded behind the same guard
# ---------------------------------------------------------------------------
echo "T4: common-aliases is loaded only for human shells"
if grep -q '^plugins+=(common-aliases)$' <(sed -n '/if (( ZSH_HUMAN_SHELL ))/,/^fi$/p' "$REPO_ROOT/zsh/zshrc" | sed 's/^ *//'); then
    pass "T4"
else
    fail "T4" "zsh/zshrc does not add common-aliases inside a ZSH_HUMAN_SHELL guard"
fi

echo ""
echo "=== Summary: $pass_count passed, $fail_count failed, $skip_count skipped ==="
[[ $fail_count -eq 0 ]]
