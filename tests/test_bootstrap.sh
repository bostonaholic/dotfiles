#!/usr/bin/env bash
################################################################################
# bootstrap.sh -- Regression Tests
#
# DESCRIPTION:
#   Behavioral tests for bootstrap.sh, the script served at
#   init.bostonaholic.dev. Pipes the script into bash the way
#   `curl ... | bash -s -- [options]` does, with stubbed `uname`,
#   `xcode-select` and `git` on PATH. The stubbed clone writes a fake
#   install.sh that records its arguments, so nothing real is installed.
#
#   Coverage:
#   - Flags map to the right install.sh --only list and pass-through args
#   - --dir wins over an inherited DOTFILES_DIR
#   - An existing checkout is updated with `git pull --ff-only`
#   - Unknown flags, non-macOS hosts, and non-git target dirs fail
#   - Under a real terminal, install.sh gets the terminal as stdin and bash
#     exits after main instead of waiting on the keyboard
#
# USAGE:
#   ./tests/test_bootstrap.sh   (or run the whole suite via: scripts/test)
#
# EXIT CODE:
#   0 - All tests passed
#   1 - One or more tests failed
#
################################################################################

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOTSTRAP="$REPO_ROOT/bootstrap.sh"

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

mkdir -p "$SCRATCH/bin"

cat > "$SCRATCH/bin/uname" <<'STUB'
#!/bin/bash
echo "${FAKE_UNAME:-Darwin}"
STUB

cat > "$SCRATCH/bin/xcode-select" <<'STUB'
#!/bin/bash
echo /Library/Developer/CommandLineTools
STUB

# git clone <...> DIR creates DIR with a fake install.sh; every call is logged.
cat > "$SCRATCH/bin/git" <<'STUB'
#!/bin/bash
echo "git $*" >> "$GIT_LOG"
if [[ "$1" == "clone" ]]; then
    dir="${!#}"
    mkdir -p "$dir/.git"
    cat > "$dir/install.sh" <<'INSTALL'
#!/bin/bash
echo "DOTFILES_DIR=$DOTFILES_DIR ARGS=$*" > "$INSTALL_LOG"
INSTALL
    chmod +x "$dir/install.sh"
fi
STUB

chmod +x "$SCRATCH/bin/"*

export GIT_LOG="$SCRATCH/git.log"
export INSTALL_LOG="$SCRATCH/install.log"

# run_bootstrap DIR [ARGS...] -- pipe bootstrap.sh into /bin/bash (bash 3.2 on
# a fresh Mac) the way curl | bash does
run_bootstrap() {
    local dir=$1
    shift
    rm -f "$GIT_LOG" "$INSTALL_LOG"
    PATH="$SCRATCH/bin:$PATH" HOME="$SCRATCH/home" DOTFILES_DIR="$dir" \
        /bin/bash -s -- "$@" < "$BOOTSTRAP" > "$SCRATCH/out.log" 2>&1
}

assert_install_args() {
    local name=$1 expected=$2 actual
    actual="$(cat "$INSTALL_LOG" 2>/dev/null || echo "<install.sh not run>")"
    if [[ "$actual" == *"ARGS=$expected" ]]; then
        pass "$name"
    else
        fail "$name" "expected ARGS=$expected, got: $actual"
    fi
}

echo "bootstrap.sh"

ALL="symlinks,homebrew,npm,pipx,uv,claude,scripts"

run_bootstrap "$SCRATCH/d1"
assert_install_args "default installs every component" "--only $ALL"

run_bootstrap "$SCRATCH/d2" --minimal
assert_install_args "--minimal installs symlinks only" "--only symlinks"

run_bootstrap "$SCRATCH/d3" --no-apps --no-plugins
assert_install_args "--no-apps --no-plugins drop homebrew and claude" \
    "--only symlinks,npm,pipx,uv,scripts"

run_bootstrap "$SCRATCH/d4" --minimal -n -y
assert_install_args "-n -y pass through as --dry-run --yes" \
    "--only symlinks --dry-run --yes"

run_bootstrap "$SCRATCH/ignored" --dir "$SCRATCH/d5" --minimal
if grep -q "DOTFILES_DIR=$SCRATCH/d5 " "$INSTALL_LOG" 2>/dev/null; then
    pass "--dir overrides an inherited DOTFILES_DIR"
else
    fail "--dir overrides an inherited DOTFILES_DIR" "$(cat "$INSTALL_LOG" 2>/dev/null)"
fi

run_bootstrap "$SCRATCH/d1" --minimal
if grep -q "pull --ff-only" "$GIT_LOG" && ! grep -q "clone" "$GIT_LOG"; then
    pass "existing checkout is pulled, not re-cloned"
else
    fail "existing checkout is pulled, not re-cloned" "$(cat "$GIT_LOG")"
fi

if run_bootstrap "$SCRATCH/d6" --bogus; then
    fail "unknown flag exits non-zero"
elif grep -q "Unknown option: --bogus" "$SCRATCH/out.log"; then
    pass "unknown flag exits non-zero"
else
    fail "unknown flag exits non-zero" "$(cat "$SCRATCH/out.log")"
fi

if FAKE_UNAME=Linux run_bootstrap "$SCRATCH/d7"; then
    fail "non-macOS host exits non-zero"
elif [[ ! -e "$GIT_LOG" ]]; then
    pass "non-macOS host exits non-zero"
else
    fail "non-macOS host exits non-zero" "git ran: $(cat "$GIT_LOG")"
fi

mkdir -p "$SCRATCH/notgit"
if run_bootstrap "$SCRATCH/notgit"; then
    fail "non-git target dir exits non-zero"
elif grep -q "not a git checkout" "$SCRATCH/out.log"; then
    pass "non-git target dir exits non-zero"
else
    fail "non-git target dir exits non-zero" "$(cat "$SCRATCH/out.log")"
fi

# Run under a pseudo-terminal, so /dev/tty exists the way it does for a person
# running `curl ... | bash`. Exits 124 if the command is still running at 10s.
cat > "$SCRATCH/pty_run.py" <<'PTY'
import os, pty, select, sys, time
pid, fd = pty.fork()
if pid == 0:
    os.execvp(sys.argv[1], sys.argv[1:])
out, deadline = b"", time.time() + 10
while time.time() < deadline:
    done, status = os.waitpid(pid, os.WNOHANG)
    if done:
        sys.stdout.write(out.decode(errors="replace"))
        sys.exit(os.waitstatus_to_exitcode(status))
    if select.select([fd], [], [], 0.2)[0]:
        try:
            out += os.read(fd, 4096)
        except OSError:
            time.sleep(0.1)
os.kill(pid, 9)
sys.stdout.write(out.decode(errors="replace"))
sys.exit(124)
PTY

if command -v python3 >/dev/null 2>&1; then
    # Clone a probe install.sh that reports whether its stdin is a terminal.
    cat > "$SCRATCH/bin/git" <<'STUB'
#!/bin/bash
dir="${!#}"
mkdir -p "$dir/.git"
printf '#!/bin/bash\nif [ -t 0 ]; then echo "stdin: tty"; else echo "stdin: pipe"; fi\n' > "$dir/install.sh"
chmod +x "$dir/install.sh"
STUB

    status=0
    out="$(python3 "$SCRATCH/pty_run.py" /bin/bash -c \
        "cat '$BOOTSTRAP' | PATH='$SCRATCH/bin':\$PATH DOTFILES_DIR='$SCRATCH/tty' /bin/bash -s -- --minimal")" \
        || status=$?
    if [[ $status -eq 124 ]]; then
        fail "piped from a terminal, exits after main" "still running after 10s: $out"
    elif [[ $status -ne 0 ]]; then
        fail "piped from a terminal, exits after main" "exit $status: $out"
    else
        pass "piped from a terminal, exits after main"
    fi
    if [[ "$out" == *"stdin: tty"* ]]; then
        pass "piped from a terminal, install.sh reads the terminal"
    else
        fail "piped from a terminal, install.sh reads the terminal" "$out"
    fi
else
    echo "  SKIP  python3 not installed (terminal tests)"
fi

summary
