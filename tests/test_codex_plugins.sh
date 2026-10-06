#!/usr/bin/env bash
################################################################################
# install_codex_plugins / update_codex_plugins -- Regression Tests
#
# DESCRIPTION:
#   Exercises scripts/install_codex_plugins and scripts/update_codex_plugins
#   against a stubbed `codex` and a fixture dotfiles.yaml, so they never touch
#   the real plugin state.
#
#   Coverage:
#   - Every GitHub marketplace in packages.codex.marketplaces is registered
#     before any plugin installs from it.
#   - Every plugin in packages.codex.plugins installs, and a re-run still
#     counts each as installed.
#   - The updater refreshes marketplace snapshots before reinstalling, so each
#     plugin installs at its marketplace's latest version.
#   - DRY_RUN=true registers, refreshes, and installs nothing.
#
# USAGE:
#   ./tests/test_codex_plugins.sh   (or run the whole suite via: scripts/test)
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
  codex:
    marketplaces:
      - example/team
      - example/skills
    plugins:
      - team@team-dev
      - example@skills
YAML

# Stub codex. Snapshot version per marketplace lives in state/snapshot-<name>;
# `marketplace upgrade` bumps every snapshot to 2.0.0, `plugin add` installs the
# snapshot's version, as the real CLI does.
cat > "$SCRATCH/bin/codex" <<STUB
#!/bin/bash
state="$SCRATCH/state"
echo "\$*" >> "\$state/calls.log"
case "\$1 \${2:-} \${3:-}" in
    "--version  ") echo "codex-cli 0.160.0" ;;
    "plugin marketplace add")
        name="\${4#*/}"
        [[ -f "\$state/snapshot-\$name" ]] || echo "1.0.0" > "\$state/snapshot-\$name"
        echo "Added marketplace \\\`\$name\\\` from https://github.com/\$4.git."
        ;;
    "plugin marketplace upgrade")
        for f in "\$state"/snapshot-*; do [[ -e "\$f" ]] && echo "2.0.0" > "\$f"; done
        echo "Upgraded marketplace(s)."
        ;;
    "plugin add "*)
        market="\${3#*@}"
        [[ "\$market" == team-dev ]] && market=team
        if [[ ! -f "\$state/snapshot-\$market" ]]; then
            echo "Error: marketplace \\\`\$market\\\` not found" >&2
            exit 1
        fi
        version=\$(cat "\$state/snapshot-\$market")
        echo "\$3 \$version" >> "\$state/installed"
        echo "Added plugin \\\`\${3%@*}\\\` from marketplace \\\`\${3#*@}\\\`."
        echo "Installed plugin root: /cache/\${3#*@}/\${3%@*}/\$version"
        ;;
    *) echo "unexpected: \$*" >&2; exit 2 ;;
esac
STUB
chmod +x "$SCRATCH/bin/codex"

run_script() {
    local name=$1
    shift
    env -i HOME="$SCRATCH" PATH="$SCRATCH/bin:$PATH" DOTFILES_DIR="$SCRATCH/dotfiles" "$@" \
        bash "$REPO_ROOT/scripts/$name" 2>&1
}

reset_state() {
    rm -f "$SCRATCH/state/"*
}

echo "install_codex_plugins / update_codex_plugins"

# 1. Fresh machine: marketplaces registered before any plugin installs.
reset_state
out=$(run_script install_codex_plugins || true)
last_add=$(grep -n '^plugin marketplace add' "$SCRATCH/state/calls.log" | tail -1 | cut -d: -f1 || true)
first_install=$(grep -n '^plugin add' "$SCRATCH/state/calls.log" | head -1 | cut -d: -f1 || true)
if [[ -n "$last_add" && -n "$first_install" && $last_add -lt $first_install ]]; then
    pass "registers every marketplace before installing plugins"
else
    fail "registers every marketplace before installing plugins" "$(cat "$SCRATCH/state/calls.log" 2>/dev/null)"
fi
if grep -q "2/2 installed" <<< "$out" && grep -q "team@team-dev installed (1.0.0)" <<< "$out"; then
    pass "installs every declared plugin and reports its version"
else
    fail "installs every declared plugin and reports its version" "$out"
fi

# 2. Re-run: still reported as installed, nothing failed.
out=$(run_script install_codex_plugins || true)
if grep -q "2/2 installed" <<< "$out" && ! grep -q "failed" <<< "$out"; then
    pass "re-running counts every plugin as installed"
else
    fail "re-running counts every plugin as installed" "$out"
fi

# 3. Update: snapshots refresh before reinstall, so plugins land at 2.0.0.
out=$(run_script update_codex_plugins || true)
upgrade_line=$(grep -n '^plugin marketplace upgrade' "$SCRATCH/state/calls.log" | tail -1 | cut -d: -f1 || true)
last_install=$(grep -n '^plugin add' "$SCRATCH/state/calls.log" | tail -1 | cut -d: -f1 || true)
if [[ -n "$upgrade_line" && $upgrade_line -lt $last_install ]] \
    && grep -q "team@team-dev installed (2.0.0)" <<< "$out" \
    && grep -q "example@skills installed (2.0.0)" <<< "$out"; then
    pass "update refreshes snapshots, then reinstalls at the latest version"
else
    fail "update refreshes snapshots, then reinstalls at the latest version" "$out"
fi

# 4. Dry run: nothing registered, refreshed, or installed.
reset_state
out=$(run_script update_codex_plugins DRY_RUN=true || true)
if ! grep -q '^plugin \(marketplace add\|marketplace upgrade\|add\)' "$SCRATCH/state/calls.log" 2>/dev/null \
    && grep -q "Would install Codex plugin: team@team-dev" <<< "$out"; then
    pass "dry run registers, refreshes, and installs nothing"
else
    fail "dry run registers, refreshes, and installs nothing" "$(cat "$SCRATCH/state/calls.log" 2>/dev/null)"
fi

summary
