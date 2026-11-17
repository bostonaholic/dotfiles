#!/bin/bash
################################################################################
# git-ai-commit-msg -- Acceptance Tests
#
# DESCRIPTION:
#   Verifies bin/git-ai-commit-msg sends the staged diff to Apple's fm CLI and
#   reports failures. Uses a stub fm, so it runs on Macs without macOS 27.
#
# USAGE:
#   ./tests/test_git_ai_commit_msg.sh   (or run the whole suite via: scripts/test)
#
################################################################################

set -euo pipefail

# Isolate the sandbox from any inherited git repository environment. Git hooks
# (e.g. pre-push) export GIT_DIR/GIT_WORK_TREE/GIT_INDEX_FILE/etc; left set,
# `git init` would re-init the caller's repo instead of the sandbox and
# corrupt its config. Clear git's own list of repo-local env vars up front.
# shellcheck disable=SC2046  # intentional word-splitting: one var name per word
unset $(git rev-parse --local-env-vars) 2>/dev/null || true

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO_ROOT/bin/git-ai-commit-msg"
MAX_INPUT_CHARS=8000

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Stub fm: records stdin and args, prints a fixed message.
mkdir "$WORK/stub" "$WORK/record"
cat > "$WORK/stub/fm" <<'EOF'
#!/bin/bash
cat > "$FM_RECORD/stdin"
printf '%s\n' "$@" > "$FM_RECORD/args"
echo "feat: stub message"
exit "${FM_STUB_EXIT:-0}"
EOF
chmod +x "$WORK/stub/fm"

# A PATH holding only the tools the script needs, so fm is absent even on
# Macs that ship /usr/bin/fm.
mkdir "$WORK/nofm"
for tool in bash env git tr head cat dirname; do
    ln -s "$(command -v "$tool")" "$WORK/nofm/$tool"
done

# Temp repo (no commits needed) with a staged change larger than the input cap.
mkdir "$WORK/repo"
cd "$WORK/repo"
git init -q
for i in $(seq 1 1000); do
    echo "line $i of a file long enough to exceed the fm input cap"
done > big.txt
git add big.txt

fails=0
pass() { echo "  PASS  $1"; }
fail() { echo "  FAIL  $1"; fails=1; }

run() { FM_RECORD="$WORK/record" PATH="$WORK/stub:$PATH" "$SCRIPT" "$@"; }

out="$(run "extra context")"
args="$(cat "$WORK/record/args")"
stdin_chars="$(wc -c < "$WORK/record/stdin")"

# check NAME DETAIL STATUS: PASS when STATUS (exit code of the condition) is 0.
check() { if [[ "$3" -eq 0 ]]; then pass "$1"; else fail "$1: $2"; fi; }

[[ "$out" == "feat: stub message" ]] && rc=0 || rc=1
check "prints fm's message" "$out" "$rc"

[[ "$args" == *"--no-stream"* && "$args" == *"--instructions"* ]] && rc=0 || rc=1
check "passes --no-stream and --instructions" "$args" "$rc"

[[ "$args" == *"extra context"* ]] && rc=0 || rc=1
check "instructions include user context" "$args" "$rc"

[[ "$(head -1 "$WORK/record/stdin")" == *"big.txt"* ]] && rc=0 || rc=1
check "stdin starts with the --stat block" "$(head -1 "$WORK/record/stdin")" "$rc"

(( stdin_chars <= MAX_INPUT_CHARS )) && rc=0 || rc=1
check "stdin capped at $MAX_INPUT_CHARS chars" "$stdin_chars" "$rc"

if FM_STUB_EXIT=69 run >/dev/null 2>&1; then
    fail "fm exit 69 was ignored"
else
    pass "fm failure exits non-zero"
fi

if err="$(PATH="$WORK/nofm" "$SCRIPT" 2>&1)"; then
    fail "missing fm exited 0"
elif [[ "$err" == *"fm not found"* ]]; then
    pass "missing fm reports 'fm not found'"
else
    fail "missing fm message: $err"
fi

git rm -q --cached big.txt
if run >/dev/null 2>&1; then
    fail "no staged changes exited 0"
else
    pass "no staged changes exits non-zero"
fi

exit "$fails"
