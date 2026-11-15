#!/usr/bin/env bash
################################################################################
# Claude Code Settings -- Acceptance Tests
#
# DESCRIPTION:
#   Checks claude/settings.json: the permission rules that keep an unattended
#   agent inside the global git rules, and the hooks that notify the person.
#   Also runs bin/claude-notify against a stub alerter.
#
# USAGE:
#   ./tests/test_claude_settings.sh   (or run the whole suite via: scripts/test)
#
# EXIT CODE:
#   0 - All tests passed
#   1 - One or more tests failed
#
################################################################################

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETTINGS="$REPO_ROOT/claude/settings.json"

pass_count=0
fail_count=0

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

echo "=== Claude Code Settings -- Acceptance Tests ==="
echo ""

echo "T1: deny list covers unsigned commits, merge commits, force push, bare stash"
missing=""
for rule in \
    'Bash(git commit *--no-gpg-sign*)' \
    'Bash(git -c commit.gpgsign=false *)' \
    'Bash(git tag -a *)' \
    'Bash(git merge --no-ff *)' \
    'Bash(git push --force *)' \
    'Bash(git stash)'; do
    jq -e --arg r "$rule" '.permissions.deny | index($r)' "$SETTINGS" >/dev/null ||
        missing="$missing [$rule]"
done
if [[ -z "$missing" ]]; then pass "T1"; else fail "T1" "missing:$missing"; fi

echo "T2: no rule is both allowed and denied"
both="$(jq -r '.permissions | (.allow - (.allow - .deny)) | join(" ")' "$SETTINGS")"
if [[ -z "$both" ]]; then pass "T2"; else fail "T2" "in both lists: $both"; fi

echo "T3: no deny rule matches git push --force-with-lease"
if jq -e '.permissions.deny | any(test("force-with-lease") or test("--force\\*"))' "$SETTINGS" >/dev/null; then
    fail "T3" "a deny rule would block --force-with-lease"
else
    pass "T3"
fi

echo "T4: Stop and Notification hooks run an executable tracked in bin/"
t4_fail=""
for event in Stop Notification; do
    cmd="$(jq -r --arg e "$event" '.hooks[$e][0].hooks[0].command // ""' "$SETTINGS")"
    script="$REPO_ROOT/bin/${cmd#\$HOME/bin/}"
    [[ "$cmd" == "\$HOME/bin/"* && -x "$script" ]] || t4_fail="$t4_fail $event='$cmd'"
done
if [[ -z "$t4_fail" ]]; then pass "T4"; else fail "T4" "$t4_fail"; fi

echo "T5: claude-notify passes the directory name and message to alerter"
if [[ "$(uname)" != Darwin ]]; then
    echo -e "  ${YELLOW}SKIP${NC}  T5 (claude-notify does nothing off macOS)"
else
    SCRATCH="$(mktemp -d)"
    trap 'rm -rf "$SCRATCH"' EXIT
    cp "$REPO_ROOT/bin/claude-notify" "$SCRATCH/"
    printf '#!/bin/bash\nprintf "%%s\\n" "$@" > "%s/args"\n' "$SCRATCH" > "$SCRATCH/alerter"
    chmod +x "$SCRATCH/alerter"
    echo '{"cwd":"/tmp/myrepo","message":"Needs permission"}' | "$SCRATCH/claude-notify"
    waiting="$(tr '\n' '|' < "$SCRATCH/args")"
    echo '{"cwd":"/tmp/myrepo"}' | "$SCRATCH/claude-notify"
    finished="$(tr '\n' '|' < "$SCRATCH/args")"
    if [[ "$waiting" == "-title|Claude: myrepo|-message|Needs permission|-group|claude-/tmp/myrepo|" &&
          "$finished" == "-title|Claude: myrepo|-message|Finished|-group|claude-/tmp/myrepo|" ]]; then
        pass "T5"
    else
        fail "T5" "waiting='$waiting' finished='$finished'"
    fi
fi

echo ""
echo "=== Summary: $pass_count passed, $fail_count failed ==="
[[ $fail_count -eq 0 ]]
