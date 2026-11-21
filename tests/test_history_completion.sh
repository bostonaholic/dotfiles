#!/bin/bash
################################################################################
# Shell History and Completion -- Acceptance Tests
#
# DESCRIPTION:
#   Verifies that zsh/zshrc gives a person at an interactive prompt a large,
#   persisted history, prefix recall on Up and Down, and Tab completion with
#   Homebrew completions in a case-insensitive menu. Agent shells, `zsh -c`
#   and non-interactive shells get no history file and no completion setup.
#
#   Every zsh starts through detach.py, a python3 helper written to the
#   scratch directory. It gives zsh no controlling terminal and stops it at
#   a deadline, so no case can wait on the keyboard. Every case skips when
#   python3 is not installed.
#
# USAGE:
#   ./tests/test_history_completion.sh   (or run the whole suite via: scripts/test)
#   Takes no arguments.
#
# EXIT CODE:
#   0 - Every case passed or skipped
#   1 - One or more cases failed
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

summary() {
    echo ""
    echo "=== Summary: $pass_count passed, $fail_count failed, $skip_count skipped ==="
    [[ $fail_count -eq 0 ]]
}

SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

# More entries than the old 10000-entry limit keeps, and past its 20%
# rewrite threshold, so a trim to 10000 shows in the file.
SEED_COUNT=30000

CASES=(
    "H1 person session reports HISTSIZE and SAVEHIST of 100000"
    "H2 entries older than the newest 10000 survive a write"
    "session history-file effects [H3 a command is saved to a new file]"
    "session history-file effects [H5 a command with a leading space is not saved]"
    "session history-file effects [A2 an agent session leaves the file byte-identical]"
    "C5 person shell with no Homebrew and no HISTFILE"
    "H4 two concurrent sessions lose no entries"
    "A3 env -i zsh -c prints only its own output"
    "K1 arrow keys run the beginning-search widgets [TERM=xterm-256color]"
    "K1 arrow keys run the beginning-search widgets [TERM unset]"
    "completion styles in a person shell [C1 menu select]"
    "completion styles in a person shell [C2 case-insensitive matcher]"
    "C4 Homebrew completions load"
    "no completion setup outside an interactive person shell [F1 plain person probe]"
    "no completion setup outside an interactive person shell [A1 interactive agent probe]"
)

echo "=== Shell History and Completion -- Acceptance Tests ==="
echo "    Repo: $REPO_ROOT"
echo ""

if ! command -v python3 >/dev/null 2>&1; then
    for c in "${CASES[@]}"; do skip "$c" "python3 not installed"; done
    summary
    exit 0
fi

# Runs a command with no controlling terminal, so it cannot read or wait on
# the keyboard. Exits 2 when fd 0, 1 or 2 is a terminal, and 124 when the
# command still runs at the deadline.
cat > "$SCRATCH/detach.py" <<'DETACH'
import os, signal, sys, time
DEADLINE_SECONDS = 20
for fd in (0, 1, 2):
    if os.isatty(fd):
        sys.stderr.write("detach.py: fd %d is a terminal\n" % fd)
        sys.exit(2)
pid = os.fork()
if pid == 0:
    os.setsid()
    os.execvp(sys.argv[1], sys.argv[1:])
deadline = time.time() + DEADLINE_SECONDS
while time.time() < deadline:
    done, status = os.waitpid(pid, os.WNOHANG)
    if done:
        sys.exit(os.waitstatus_to_exitcode(status))
    time.sleep(0.05)
os.killpg(pid, signal.SIGKILL)
os.waitpid(pid, 0)
sys.exit(124)
DETACH

# Person cases clear every agent marker, because the suite can run inside an
# agent shell. Every case clears the Terminal.app variables, so /etc/zshrc
# loads no /etc/zshrc_Apple_Terminal.
AGENT_MARKERS=(CLAUDECODE CLAUDE_CODE_ENTRYPOINT AI_AGENT CURSOR_AGENT CODEX_SANDBOX DOTFILES_AGENT_SHELL)
CLEAN_ENV=(-u TERM_PROGRAM -u TERM_SESSION_ID)
for m in "${AGENT_MARKERS[@]}"; do CLEAN_ENV+=(-u "$m"); done

# Writes <count> synthetic extended-history lines: seed-1 is the oldest.
seed_history() {
    awk -v n="$2" 'BEGIN { for (i = 1; i <= n; i++) printf ": 1700000000:0;seed-%d\n", i }' > "$1"
}

# A ZDOTDIR whose .zshenv and .zshrc link to this repo's files, so a session
# runs the real startup chain, /etc/zshrc included.
session_dir() {
    local dir="$SCRATCH/$1"
    mkdir -p "$dir"
    ln -s "$REPO_ROOT/zsh/zshenv" "$dir/.zshenv"
    ln -s "$REPO_ROOT/zsh/zshrc" "$dir/.zshrc"
    echo "$dir"
}

# Session: an interactive zsh that reads commands from <cmds> on stdin.
# Writes <out>.stdout and <out>.stderr. Extra arguments are env assignments.
run_session() {
    local dir="$1" cmds="$2" out="$3"
    shift 3
    env "${CLEAN_ENV[@]}" "$@" ZDOTDIR="$dir" \
        python3 "$SCRATCH/detach.py" /bin/zsh -i \
        <"$cmds" >"$out.stdout" 2>"$out.stderr"
}

# An empty ZDOTDIR for a probe, which sources this repo's files itself.
probe_dir() {
    local dir="$SCRATCH/$1"
    mkdir -p "$dir"
    echo "$dir"
}

# Interactive probe: `zsh -ic <commands>`. Prints the probe's stdout and
# writes its stderr to <dir>.stderr. Extra arguments are env assignments.
interactive_probe() {
    local dir="$1" commands="$2"
    shift 2
    env "${CLEAN_ENV[@]}" "$@" ZDOTDIR="$dir" \
        python3 "$SCRATCH/detach.py" /bin/zsh -ic "$commands" \
        </dev/null 2>"$dir.stderr"
}

# Plain probe: `zsh -c <commands>`, with the same capture rules.
plain_probe() {
    local dir="$1" commands="$2"
    shift 2
    env "${CLEAN_ENV[@]}" "$@" ZDOTDIR="$dir" \
        python3 "$SCRATCH/detach.py" /bin/zsh -c "$commands" \
        </dev/null 2>"$dir.stderr"
}

# Prints the value after "<label>=" on the first matching line.
field() { sed -n "s/^$2=//p" <<<"$1" | head -n 1; }

# ===========================================================================
# Slice 1: Person shells keep 100000 history entries
# ===========================================================================

echo "H1: a person session keeps 100000 entries in memory and on disk"
dir="$(session_dir h1)"
printf '%s\n' 'print -r -- "$HISTSIZE:$SAVEHIST"' > "$SCRATCH/h1.cmds"
status=0
run_session "$dir" "$SCRATCH/h1.cmds" "$SCRATCH/h1" || status=$?
if grep -qx '100000:100000' "$SCRATCH/h1.stdout"; then
    pass "${CASES[0]}"
else
    fail "${CASES[0]}" "exit=$status stdout='$(cat "$SCRATCH/h1.stdout")'"
fi

echo "H2: the oldest of $SEED_COUNT entries survives a write and a new session finds it"
dir="$(session_dir h2)"
seed_history "$dir/.zsh_history" "$SEED_COUNT"
printf 'true\n' > "$SCRATCH/h2-write.cmds"
printf 'fc -ln 1 1\n' > "$SCRATCH/h2-read.cmds"
status=0
run_session "$dir" "$SCRATCH/h2-write.cmds" "$SCRATCH/h2-write" || status=$?
if ! grep -qxF ': 1700000000:0;seed-1' "$dir/.zsh_history"; then
    fail "${CASES[1]}" "exit=$status: seed-1 is gone after one write; file has $(wc -l <"$dir/.zsh_history" | tr -d ' ') lines, first: $(head -n 1 "$dir/.zsh_history")"
else
    run_session "$dir" "$SCRATCH/h2-read.cmds" "$SCRATCH/h2-read" || status=$?
    if [[ "$(cat "$SCRATCH/h2-read.stdout")" == "seed-1" ]]; then
        pass "${CASES[1]}"
    else
        fail "${CASES[1]}" "exit=$status: fc -ln 1 1 printed '$(cat "$SCRATCH/h2-read.stdout")', want 'seed-1'"
    fi
fi

echo "session history-file effects: one session per row, then read the file"

# H3: no history file yet. Also shows that sessions write, so H5 and A2
# cannot pass on a shell that writes nothing.
dir="$(session_dir h3)"
printf 'echo kept-marker\n' > "$SCRATCH/h3.cmds"
status=0
run_session "$dir" "$SCRATCH/h3.cmds" "$SCRATCH/h3" || status=$?
if [[ -f "$dir/.zsh_history" ]] && grep -q ';echo kept-marker$' "$dir/.zsh_history"; then
    pass "${CASES[2]}"
else
    fail "${CASES[2]}" "exit=$status history file: '$(cat "$dir/.zsh_history" 2>&1)'"
fi

# H5: bin/pass tells the person to start a command with a space to keep it
# out of history.
dir="$(session_dir h5)"
printf ' echo hidden-marker\ntrue\n' > "$SCRATCH/h5.cmds"
status=0
run_session "$dir" "$SCRATCH/h5.cmds" "$SCRATCH/h5" || status=$?
if ! grep -q 'hidden-marker' "$dir/.zsh_history" 2>/dev/null; then
    pass "${CASES[3]}"
else
    fail "${CASES[3]}" "exit=$status history file: '$(cat "$dir/.zsh_history")'"
fi

# A2: an agent session must not append to the person's history file.
dir="$(session_dir a2)"
seed_history "$dir/.zsh_history" 100
cp "$dir/.zsh_history" "$SCRATCH/a2.before"
printf 'true\n' > "$SCRATCH/a2.cmds"
status=0
run_session "$dir" "$SCRATCH/a2.cmds" "$SCRATCH/a2" CLAUDECODE=1 || status=$?
if cmp -s "$SCRATCH/a2.before" "$dir/.zsh_history"; then
    pass "${CASES[4]}"
else
    fail "${CASES[4]}" "exit=$status file changed; last line: '$(tail -n 1 "$dir/.zsh_history")'"
fi

# ===========================================================================
# Slice 2: History persists in every person shell
# ===========================================================================

echo "C5: a person shell with no Homebrew and no system HISTFILE saves history"
dir="$(probe_dir c5)"
status=0
out="$(interactive_probe "$dir" "
    print -r -- \"fpath-before=\${(j.:.)fpath}\"
    unset HISTFILE
    source '$REPO_ROOT/zsh/zshrc' >'$dir.source' 2>&1
    print -r -- \"histfile=\${HISTFILE-<unset>}\"
    print -r -- \"fpath-after=\${(j.:.)fpath}\"" -u HOMEBREW_PREFIX)" || status=$?
if [[ "$(field "$out" histfile)" == "$dir/.zsh_history" &&
      "$(field "$out" fpath-after)" == "$(field "$out" fpath-before)" &&
      ! -s "$dir.source" ]]; then
    pass "${CASES[5]}"
else
    fail "${CASES[5]}" "exit=$status want histfile=$dir/.zsh_history and fpath unchanged; got: $out; source output: '$(cat "$dir.source" 2>&1)'"
fi

echo "H4: two person sessions at once both reach the file and drop no entries"
dir="$(session_dir h4)"
seed_history "$dir/.zsh_history" "$SEED_COUNT"
printf 'echo h4-marker-a\n' > "$SCRATCH/h4-a.cmds"
printf 'echo h4-marker-b\n' > "$SCRATCH/h4-b.cmds"
run_session "$dir" "$SCRATCH/h4-a.cmds" "$SCRATCH/h4-a" &
pid_a=$!
run_session "$dir" "$SCRATCH/h4-b.cmds" "$SCRATCH/h4-b" &
pid_b=$!
status_a=0
wait "$pid_a" || status_a=$?
status_b=0
wait "$pid_b" || status_b=$?
lines="$(wc -l <"$dir/.zsh_history" | tr -d ' ')"
if [[ $status_a -eq 0 && $status_b -eq 0 ]] &&
   grep -q ';echo h4-marker-a$' "$dir/.zsh_history" &&
   grep -q ';echo h4-marker-b$' "$dir/.zsh_history" &&
   [[ $lines -ge $((SEED_COUNT + 2)) ]]; then
    pass "${CASES[6]}"
else
    fail "${CASES[6]}" "exit a=$status_a b=$status_b lines=$lines (want >= $((SEED_COUNT + 2))); last lines: $(tail -n 3 "$dir/.zsh_history" | tr '\n' '|')"
fi

echo "A3: env -i zsh -c reads only zshenv, prints only its own output, writes no history"
dir="$(probe_dir a3)"
ln -s "$REPO_ROOT/zsh/zshenv" "$dir/.zshenv"
status=0
out="$(python3 "$SCRATCH/detach.py" env -i HOME="$HOME" ZDOTDIR="$dir" /bin/zsh -c 'print ok' </dev/null 2>&1)" || status=$?
if [[ "$out" == "ok" && ! -e "$dir/.zsh_history" ]]; then
    pass "${CASES[7]}"
else
    fail "${CASES[7]}" "exit=$status stdout+stderr='$out' history file exists: $([[ -e "$dir/.zsh_history" ]] && echo yes || echo no)"
fi

# ===========================================================================
# Slice 3: Up and Down recall by typed prefix
# ===========================================================================

echo "K1: Up and Down run the beginning-search widgets, with and without TERM"

dir="$(probe_dir k1-xterm)"
status=0
out="$(plain_probe "$dir" "
    { source '$REPO_ROOT/zsh/zshenv'; source '$REPO_ROOT/zsh/zshrc'; } >'$dir.source' 2>&1
    print -r -- \"csi-up=\$(bindkey '^[[A')\"
    print -r -- \"csi-down=\$(bindkey '^[[B')\"
    print -r -- \"kcuu1=\${(V)terminfo[kcuu1]}\"
    print -r -- \"kcud1=\${(V)terminfo[kcud1]}\"
    [[ -n \"\${terminfo[kcuu1]}\" ]] && print -r -- \"terminfo-up=\$(bindkey -- \"\${terminfo[kcuu1]}\")\"
    [[ -n \"\${terminfo[kcud1]}\" ]] && print -r -- \"terminfo-down=\$(bindkey -- \"\${terminfo[kcud1]}\")\"
    true" TERM=xterm-256color)" || status=$?
if [[ "$(field "$out" csi-up)" == *' up-line-or-beginning-search' &&
      "$(field "$out" csi-down)" == *' down-line-or-beginning-search' &&
      "$(field "$out" terminfo-up)" == *' up-line-or-beginning-search' &&
      "$(field "$out" terminfo-down)" == *' down-line-or-beginning-search' ]]; then
    pass "${CASES[8]}"
else
    fail "${CASES[8]}" "exit=$status got: $out; source output: '$(cat "$dir.source" 2>&1)'"
fi

dir="$(probe_dir k1-noterm)"
status=0
out="$(plain_probe "$dir" "
    { source '$REPO_ROOT/zsh/zshenv'; source '$REPO_ROOT/zsh/zshrc'; } >'$dir.source' 2>&1
    print -r -- \"csi-up=\$(bindkey '^[[A')\"
    print -r -- \"csi-down=\$(bindkey '^[[B')\"
    print -r -- \"kcuu1=\${(V)terminfo[kcuu1]}\"
    print -r -- \"kcud1=\${(V)terminfo[kcud1]}\"" -u TERM)" || status=$?
if [[ "$(field "$out" csi-up)" == *' up-line-or-beginning-search' &&
      "$(field "$out" csi-down)" == *' down-line-or-beginning-search' &&
      -z "$(field "$out" kcuu1)" && -z "$(field "$out" kcud1)" &&
      ! -s "$dir.source" ]]; then
    pass "${CASES[9]}"
else
    fail "${CASES[9]}" "exit=$status got: $out; source output: '$(cat "$dir.source" 2>&1)'"
fi

# ===========================================================================
# Slice 4: Tab completes Homebrew tools from a case-insensitive menu
# ===========================================================================

echo "completion styles in a person shell: one interactive probe per row"

# C1: Tab shows a list that arrow keys move through.
dir="$(probe_dir c1)"
status=0
out="$(interactive_probe "$dir" "
    { source '$REPO_ROOT/zsh/zshenv'; source '$REPO_ROOT/zsh/zshrc'; } >'$dir.source' 2>&1
    zstyle -s ':completion:*' menu value
    print -r -- \"menu=\${value-}\"")" || status=$?
if [[ "$(field "$out" menu)" == "select" ]]; then
    pass "${CASES[10]}"
else
    fail "${CASES[10]}" "exit=$status want menu=select; got: $out; source output: '$(cat "$dir.source" 2>&1)'"
fi

# C2: a prefix that differs from a match only in letter case still matches.
dir="$(probe_dir c2)"
status=0
out="$(interactive_probe "$dir" "
    { source '$REPO_ROOT/zsh/zshenv'; source '$REPO_ROOT/zsh/zshrc'; } >'$dir.source' 2>&1
    zstyle -s ':completion:*' matcher-list value
    print -r -- \"matcher-list=\${value-}\"")" || status=$?
if [[ "$(field "$out" matcher-list)" == 'm:{a-zA-Z}={A-Za-z}' ]]; then
    pass "${CASES[11]}"
else
    fail "${CASES[11]}" "exit=$status want matcher-list=m:{a-zA-Z}={A-Za-z}; got: $out; source output: '$(cat "$dir.source" 2>&1)'"
fi

echo "C4: Tab completes brew, and op when Homebrew installs it"
dir="$(probe_dir c4)"
status=0
out="$(interactive_probe "$dir" "
    print -r -- \"fpath-before=\${(j.:.)fpath}\"
    { source '$REPO_ROOT/zsh/zshenv'; source '$REPO_ROOT/zsh/zshrc'; } >'$dir.source' 2>&1
    site=\"\${HOMEBREW_PREFIX-}/share/zsh/site-functions\"
    print -r -- \"prefix=\${HOMEBREW_PREFIX-}\"
    [[ -r \"\$site/_brew\" ]] && print brew-readable=1 || print brew-readable=0
    [[ -r \"\$site/_op\" ]] && print op-readable=1 || print op-readable=0
    print -r -- \"fpath-after=\${(j.:.)fpath}\"
    print -r -- \"comps-brew=\${_comps[brew]-}\"
    print -r -- \"op-path=\${commands[op]-}\"
    print -r -- \"comps-op=\${_comps[op]-}\"")" || status=$?
prefix="$(field "$out" prefix)"
site="$prefix/share/zsh/site-functions"
before="$(field "$out" fpath-before)"
after="$(field "$out" fpath-after)"
op_path="$(field "$out" op-path)"
c4_detail="exit=$status got: $out; source output: '$(cat "$dir.source" 2>&1)'"
if [[ -z "$prefix" || "$(field "$out" brew-readable)" != 1 ]]; then
    skip "${CASES[12]}" "Homebrew _brew not found"
elif [[ ":$before:" == *":$site:"* && "$after" != "$before" ]]; then
    fail "${CASES[12]}" "fpath changed but already held $site; $c4_detail"
elif [[ ":$before:" != *":$site:"* && "$after" != "$before:$site" ]]; then
    fail "${CASES[12]}" "fpath does not end with $site after its default entries; $c4_detail"
elif [[ "$(field "$out" comps-brew)" != "_brew" ]]; then
    fail "${CASES[12]}" "\$_comps[brew] is not _brew; $c4_detail"
elif [[ "$op_path" == "$prefix/"* && "$(field "$out" op-readable)" != 1 ]]; then
    fail "${CASES[12]}" "op is under $prefix but $site/_op is not readable; $c4_detail"
elif [[ "$op_path" == "$prefix/"* && "$(field "$out" comps-op)" != "_op" ]]; then
    fail "${CASES[12]}" "op is under $prefix but \$_comps[op] is not _op; $c4_detail"
else
    pass "${CASES[12]}"
fi

echo "no completion setup outside an interactive person shell: one probe per row"

# F1: a person script that sources ~/.zshrc runs no compinit, so it cannot
# stop on the insecure-directory question.
dir="$(probe_dir f1)"
status=0
out="$(plain_probe "$dir" "
    { source '$REPO_ROOT/zsh/zshenv'; source '$REPO_ROOT/zsh/zshrc'; } >'$dir.source' 2>&1
    print -r -- \"comps=\${+_comps}\"
    print -r -- \"styles=\$(zstyle -L ':completion:*')\"")" || status=$?
if [[ ! -s "$dir.source" &&
      "$(field "$out" comps)" == 0 &&
      "$(field "$out" styles)" == "" &&
      ! -e "$dir/.zsh_history" ]]; then
    pass "${CASES[13]}"
else
    fail "${CASES[13]}" "exit=$status want comps=0, no styles, no history file (exists: $([[ -e "$dir/.zsh_history" ]] && echo yes || echo no)); got: $out; source output: '$(cat "$dir.source" 2>&1)'"
fi

# A1: an interactive agent shell, such as a Cursor agent terminal.
dir="$(probe_dir a1)"
status=0
out="$(interactive_probe "$dir" "
    { source '$REPO_ROOT/zsh/zshenv'; source '$REPO_ROOT/zsh/zshrc'; } >'$dir.source' 2>&1
    print -r -- \"comps=\${+_comps}\"
    print -r -- \"styles=\$(zstyle -L ':completion:*')\"
    print -r -- \"histfile-set=\${+HISTFILE}\"" CLAUDECODE=1)" || status=$?
if [[ ! -s "$dir.source" &&
      "$(field "$out" comps)" == 0 &&
      "$(field "$out" styles)" == "" &&
      "$(field "$out" histfile-set)" == 0 ]]; then
    pass "${CASES[14]}"
else
    fail "${CASES[14]}" "exit=$status want comps=0, no styles, histfile-set=0; got: $out; source output: '$(cat "$dir.source" 2>&1)'"
fi

summary
