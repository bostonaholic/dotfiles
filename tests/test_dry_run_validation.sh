#!/usr/bin/env bash
################################################################################
# DRY_RUN validation -- Regression Tests
#
# DESCRIPTION:
#   Scripts gate real work on `[[ $DRY_RUN == 1 ]]` and
#   `[[ $DRY_RUN == 0 ]]` separately, so a value that is neither (true, yes)
#   would skip the previews yet still run the real commands. scripts/lib.sh
#   rejects any DRY_RUN other than 1 or 0.
#
#   Runs each plugin script against a stubbed `claude` and `codex` and a
#   fixture dotfiles.yaml, so it never touches the real plugin state.
#
#   Coverage:
#   - DRY_RUN=1 previews and runs no plugin or marketplace command.
#   - DRY_RUN=true and DRY_RUN=yes exit non-zero with an error naming DRY_RUN
#     and run no plugin or marketplace command.
#
# USAGE:
#   ./tests/test_dry_run_validation.sh   (or run the whole suite via: scripts/test)
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

mkdir -p "$SCRATCH/dotfiles" "$SCRATCH/bin" "$SCRATCH/state"
ln -s "$REPO_ROOT/scripts" "$SCRATCH/dotfiles/scripts"
cat > "$SCRATCH/dotfiles/dotfiles.yaml" <<'YAML'
packages:
  claude:
    marketplaces:
      - example/skills
    plugins:
      - example@skills
  codex:
    marketplaces:
      - example/skills
    plugins:
      - example@skills
YAML

# Stubs record every call and succeed, so a script that ignores DRY_RUN runs
# to completion and leaves its plugin commands in the log.
for cli in claude codex; do
    cat > "$SCRATCH/bin/$cli" <<STUB
#!/bin/bash
echo "$cli \$*" >> "$SCRATCH/state/calls.log"
[[ "\$1" == --version ]] && echo "2.0.0"
exit 0
STUB
    chmod +x "$SCRATCH/bin/$cli"
done

echo "DRY_RUN validation"

run_script() {
    rm -f "$SCRATCH/state/"*
    out=$(env -i HOME="$SCRATCH" PATH="$SCRATCH/bin:$PATH" DOTFILES_DIR="$SCRATCH/dotfiles" \
        DRY_RUN="$2" bash "$REPO_ROOT/scripts/$1" 2>&1) && status=0 || status=$?
    calls=$(grep ' plugin ' "$SCRATCH/state/calls.log" 2>/dev/null || true)
}

for script in install_claude_plugins update_claude_plugins install_codex_plugins update_codex_plugins; do
    run_script "$script" 1
    if [[ $status -eq 0 && -z "$calls" ]] && grep -q "Would " <<< "$out"; then
        pass "$script previews under DRY_RUN=1 without running a plugin command"
    else
        fail "$script previews under DRY_RUN=1 without running a plugin command" "exit $status: $out$calls"
    fi

    for value in true yes; do
        run_script "$script" "$value"
        if [[ $status -ne 0 ]] && grep -q "DRY_RUN" <<< "$out"; then
            pass "$script rejects DRY_RUN=$value"
        else
            fail "$script rejects DRY_RUN=$value" "exit $status: $out"
        fi
        if [[ -z "$calls" ]]; then
            pass "$script runs no plugin command under DRY_RUN=$value"
        else
            fail "$script runs no plugin command under DRY_RUN=$value" "$calls"
        fi
    done
done

summary
