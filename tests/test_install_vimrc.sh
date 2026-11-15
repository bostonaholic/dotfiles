#!/usr/bin/env bash
################################################################################
# install_vimrc -- Regression Tests
#
# DESCRIPTION:
#   Runs install.sh (symlinks, then post_install scripts) against an empty
#   fake HOME. The fixture dotfiles.yaml copies the vim symlink and the vim
#   post_install entries from the real dotfiles.yaml, so the real conditions
#   are the ones under test. `git` and `pip3` are stubs: nothing is cloned.
#
#   The symlinks step creates ~/.vim_runtime to hold my_configs.vim before
#   post_install runs, so that directory existing does not mean vimrc is
#   installed.
#
#   Coverage:
#   - A fresh HOME gets the vimrc clone, its installer run, the Catppuccin
#     clone, and keeps the my_configs.vim symlink.
#   - A second run clones nothing.
#
# USAGE:
#   ./tests/test_install_vimrc.sh   (or run the whole suite via: scripts/test)
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

mkdir -p "$SCRATCH/dotfiles" "$SCRATCH/bin" "$SCRATCH/home"
ln -s "$REPO_ROOT/scripts" "$SCRATCH/dotfiles/scripts"
ln -s "$REPO_ROOT/vim" "$SCRATCH/dotfiles/vim"
yq eval '{
  "symlinks": {"vim/my_configs.vim": .symlinks."vim/my_configs.vim"},
  "scripts": {"post_install": [.scripts.post_install[] | select(.command | test("vim"))]}
}' "$REPO_ROOT/dotfiles.yaml" > "$SCRATCH/dotfiles/dotfiles.yaml"

# `git clone ... <dest>` records the call and creates <dest> holding a .git
# directory and an installer that leaves a marker in HOME, as the real vimrc
# clone would. Like real git, it refuses a destination that is not empty.
cat > "$SCRATCH/bin/git" <<STUB
#!/bin/bash
echo "git \$*" >> "$SCRATCH/calls.log"
[[ "\$1" == clone ]] || exit 0
dest="\${!#}"
if [[ -d "\$dest" && -n "\$(ls -A "\$dest")" ]]; then
    echo "fatal: destination path '\$dest' already exists and is not an empty directory." >&2
    exit 128
fi
mkdir -p "\$dest/.git"
echo 'touch "\$HOME/.vimrc"' > "\$dest/install_awesome_vimrc.sh"
STUB
cat > "$SCRATCH/bin/pip3" <<'STUB'
#!/bin/bash
exit 0
STUB
chmod +x "$SCRATCH/bin/git" "$SCRATCH/bin/pip3"

VIM_RUNTIME="$SCRATCH/home/.vim_runtime"

run_install() {
    out=$(env -i HOME="$SCRATCH/home" PATH="$SCRATCH/bin:$PATH" DOTFILES_DIR="$SCRATCH/dotfiles" \
        bash "$REPO_ROOT/install.sh" -f --no-backup --only symlinks,scripts 2>&1) && status=0 || status=$?
    clones=$(grep -c '^git clone ' "$SCRATCH/calls.log" 2>/dev/null || true)
}

echo "install_vimrc"

run_install
if [[ $status -eq 0 && -d "$VIM_RUNTIME/.git" && -e "$SCRATCH/home/.vimrc" ]]; then
    pass "a fresh HOME gets vimrc cloned and its installer run"
else
    fail "a fresh HOME gets vimrc cloned and its installer run" "exit $status: $out"
fi

if [[ -L "$VIM_RUNTIME/my_configs.vim" ]]; then
    pass "the my_configs.vim symlink survives the vimrc install"
else
    fail "the my_configs.vim symlink survives the vimrc install" "exit $status: $out"
fi

if [[ -d "$VIM_RUNTIME/my_plugins/catppuccin" ]]; then
    pass "Catppuccin is installed after vimrc"
else
    fail "Catppuccin is installed after vimrc" "exit $status: $out"
fi

run_install
if [[ $status -eq 0 && $clones -eq 2 ]]; then
    pass "a second run clones nothing"
else
    fail "a second run clones nothing" "exit $status, $clones clones: $out"
fi

summary
