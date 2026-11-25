#!/usr/bin/env bash
################################################################################
# Claude Code Settings -- Acceptance Tests
#
# DESCRIPTION:
#   Checks claude/settings.json: the permission rules that keep an unattended
#   agent inside the global git rules, the hooks that notify the person, and
#   the hook that blocks a stacked PR with no GitHub stack. Also runs
#   bin/claude-notify against a stub alerter and bin/claude-guard-pr-base
#   against sample commands.
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

# Isolate the sandbox from any inherited git repository environment. Git hooks
# (e.g. pre-push) export GIT_DIR/GIT_WORK_TREE/GIT_INDEX_FILE/etc; left set,
# T7's `git -C "$GUARD_REPO" init` would re-init the caller's repo instead of
# the sandbox and corrupt its config. Clear git's own list of repo-local env
# vars up front.
# shellcheck disable=SC2046  # intentional word-splitting: one var name per word
unset $(git rev-parse --local-env-vars) 2>/dev/null || true

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

echo "T4: Notification hook runs an executable tracked in bin/"
cmd="$(jq -r '.hooks.Notification[0].hooks[0].command // ""' "$SETTINGS")"
script="$REPO_ROOT/bin/${cmd#\$HOME/bin/}"
if [[ "$cmd" == "\$HOME/bin/"* && -x "$script" ]]; then pass "T4"; else fail "T4" "Notification='$cmd'"; fi

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

echo "T6: PreToolUse Bash hooks run claude-guard-pr-base and claude-guard-acceptance from bin/"
cmd="$(jq -r '.hooks.PreToolUse[]? | select(.matcher == "Bash") | .hooks[].command' "$SETTINGS" | tr '\n' ' ')"
if [[ "$cmd" == "\$HOME/bin/claude-guard-pr-base \$HOME/bin/claude-guard-acceptance " &&
      -x "$REPO_ROOT/bin/claude-guard-pr-base" && -x "$REPO_ROOT/bin/claude-guard-acceptance" ]]; then
    pass "T6"
else
    fail "T6" "PreToolUse Bash='$cmd'"
fi

echo "T7: claude-guard-pr-base blocks a stacked gh pr create with no gh stack link"
GUARD_REPO="$(mktemp -d)"
trap 'rm -rf "${SCRATCH:-}" "$GUARD_REPO"' EXIT
git -C "$GUARD_REPO" init -q
git -C "$GUARD_REPO" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/develop

guard_exit() {
    jq -n --arg cwd "$GUARD_REPO" --arg c "$1" '{cwd: $cwd, tool_input: {command: $c}}' |
        "$REPO_ROOT/bin/claude-guard-pr-base" 2>/dev/null && echo 0 || echo $?
}

chained='gh pr create --draft --base main --head a --title A --body-file 1.md || exit 1
gh pr create --draft --base a --head b --title B --body-file 2.md || exit 1'
bad=""
expect() { [[ "$(guard_exit "$2")" == "$1" ]] || bad="$bad [want $1: $2]"; }
expect 2 "$chained"
expect 2 "gh pr create --draft -B feature/api --title X"
expect 2 "gh pr create --base='feature/api' --title X"
expect 0 "gh pr create --draft --base main --title X"
expect 0 "gh pr create --draft --base develop --title X"
expect 0 "gh pr create --draft --title X"
expect 0 "gh pr create --draft --base a --title X && GH_FORCE_TTY= gh stack link --base main --remote origin 1 2"
expect 0 "PR_BASE_OK=1 gh pr create --base release/2.0 --title X"
expect 0 "ls -la"
if [[ -z "$bad" ]]; then pass "T7"; else fail "T7" "$bad"; fi

echo "T8: claude-guard-acceptance blocks merge or close while an issue has an unchecked box"
GH_STUB="$(mktemp -d)"
trap 'rm -rf "${SCRATCH:-}" "$GUARD_REPO" "$GH_STUB"' EXIT
cat > "$GH_STUB/gh" <<'STUB'
#!/bin/bash
[[ -n "${GH_FAIL:-}" ]] && exit 1
case "$1 $2 $3" in
    "pr view 94") echo "acme/app 93" ;;
    "pr view 95") echo "acme/app 96" ;;
    "pr view 97") ;;
    "issue view 93") printf '%s\n' '## Acceptance' '' '- [x] done' '- [ ] not done' ;;
    "issue view 96") printf '%s\n' '- [x] a' '  - [x] b' ;;
    *) exit 1 ;;
esac
STUB
chmod +x "$GH_STUB/gh"

accept_exit() {
    jq -n --arg cwd "$GUARD_REPO" --arg c "$1" '{cwd: $cwd, tool_input: {command: $c}}' |
        PATH="$GH_STUB:$PATH" GH_FAIL="${2:-}" "$REPO_ROOT/bin/claude-guard-acceptance" 2>/dev/null &&
        echo 0 || echo $?
}

bad=""
want() { [[ "$(accept_exit "$2" "${3:-}")" == "$1" ]] || bad="$bad [want $1: $2 ${3:-}]"; }
want 2 "gh pr merge 94 --squash --delete-branch"
want 2 "gh pr merge 94 --auto --squash"
want 2 "gh issue close 93"
want 2 "gh issue close 93 --reason completed"
want 0 "gh pr merge 95 --squash"
want 0 "gh pr merge 97 --squash"
want 0 "gh issue close 96"
want 0 "gh issue close 93 --reason \"not planned\""
want 0 "gh issue close 93 -r 'not planned'"
want 0 "ls -la"
want 0 "git commit -m 'blocks gh pr merge 94 while boxes are open'"
want 0 "echo gh issue close 93"
want 2 "cd /x && gh pr merge 94 --squash"
want 2 "GH_TOKEN=x gh issue close 93"
want 2 "gh pr merge 95 --squash" fail
want 2 "gh issue close 96" fail
if [[ -z "$bad" ]]; then pass "T8"; else fail "T8" "$bad"; fi

echo ""
echo "=== Summary: $pass_count passed, $fail_count failed ==="
[[ $fail_count -eq 0 ]]
