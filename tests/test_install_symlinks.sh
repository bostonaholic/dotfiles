#!/usr/bin/env bash
################################################################################
# install_symlinks -- Regression Tests
#
# DESCRIPTION:
#   Exercises scripts/install_symlinks against a fake HOME and a fixture
#   dotfiles.yaml whose targets (one symlinks entry, one symlink_contents
#   entry) already exist as regular files, so it never touches real files.
#
#   FORCE, NO_BACKUP and VERBOSE are on when set to any non-empty value and
#   off when unset or empty.
#
#   Coverage:
#   - FORCE=1 and FORCE=false overwrite without prompting and back up the
#     old file.
#   - FORCE=1 with NO_BACKUP=1 overwrites without a backup.
#   - An empty FORCE prompts for both entries, and answering no keeps the old
#     files. Building the prompts references no undefined variable.
#   - VERBOSE=1 prints debug output; an empty VERBOSE does not.
#
# USAGE:
#   ./tests/test_install_symlinks.sh   (or run the whole suite via: scripts/test)
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

if ! command -v yq >/dev/null 2>&1; then
    echo "  SKIP  yq not installed"
    exit 0
fi

SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

mkdir -p "$SCRATCH/dotfiles/dir"
echo "new" > "$SCRATCH/dotfiles/source"
echo "new" > "$SCRATCH/dotfiles/dir/file"
cat > "$SCRATCH/dotfiles/dotfiles.yaml" <<'YAML'
symlinks:
  source: ~/target
symlink_contents:
  dir: ~/dir
YAML

TARGET="$SCRATCH/home/target"
CONTENTS_TARGET="$SCRATCH/home/dir/file"
BACKUP="$SCRATCH/backup/target"

# Fresh HOME whose targets are regular files, then run install_symlinks with
# the given env assignments, answering "n" to every overwrite prompt.
run_symlinks() {
    rm -rf "${SCRATCH:?}/home" "${SCRATCH:?}/backup"
    mkdir -p "$SCRATCH/home/dir"
    echo "old" > "$TARGET"
    echo "old" > "$CONTENTS_TARGET"
    out=$(printf 'n\nn\n' | env -i HOME="$SCRATCH/home" PATH="$PATH" DOTFILES_DIR="$SCRATCH/dotfiles" \
        BACKUP_DIR="$SCRATCH/backup" "$@" bash "$REPO_ROOT/scripts/install_symlinks" 2>&1) \
        && status=0 || status=$?
}

echo "install_symlinks"

for value in 1 false; do
    run_symlinks FORCE="$value"
    if [[ $status -eq 0 && -L "$TARGET" && "$(cat "$BACKUP" 2>/dev/null)" == "old" ]]; then
        pass "FORCE=$value overwrites without prompting and backs up"
    else
        fail "FORCE=$value overwrites without prompting and backs up" "exit $status: $out"
    fi
done

run_symlinks FORCE=1 NO_BACKUP=1
if [[ $status -eq 0 && -L "$TARGET" && ! -e "$BACKUP" ]]; then
    pass "NO_BACKUP=1 overwrites without a backup"
else
    fail "NO_BACKUP=1 overwrites without a backup" "exit $status: $out"
fi

run_symlinks FORCE=
if [[ $status -eq 0 && "$(cat "$TARGET")" == "old" && "$(cat "$CONTENTS_TARGET")" == "old" ]] \
    && [[ ! -L "$TARGET" && ! -L "$CONTENTS_TARGET" ]] \
    && [[ $(grep -c "Skipping" <<< "$out") -eq 2 ]] && ! grep -q "unbound variable" <<< "$out"; then
    pass "empty FORCE prompts for both entries and keeps the files on no"
else
    fail "empty FORCE prompts for both entries and keeps the files on no" "exit $status: $out"
fi

run_symlinks FORCE=1 VERBOSE=1
if grep -q "\[DEBUG\]" <<< "$out"; then
    pass "VERBOSE=1 prints debug output"
else
    fail "VERBOSE=1 prints debug output" "$out"
fi

run_symlinks FORCE=1 VERBOSE=
if ! grep -q "\[DEBUG\]" <<< "$out"; then
    pass "empty VERBOSE prints no debug output"
else
    fail "empty VERBOSE prints no debug output" "$out"
fi

summary
