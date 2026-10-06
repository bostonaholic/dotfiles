#!/usr/bin/env bash
################################################################################
# install_claude_plugins / update_claude_plugins -- Regression Tests
#
# DESCRIPTION:
#   Exercises scripts/install_claude_plugins and scripts/update_claude_plugins
#   against a stubbed `claude` and a fixture dotfiles.yaml, so they never touch
#   the real plugin state.
#
#   Coverage:
#   - Every GitHub marketplace in packages.claude.marketplaces is registered
#     before any plugin installs from it.
#   - Re-running the installer counts an already-installed plugin as
#     installed, not failed.
#   - The updater installs a plugin newly declared in dotfiles.yaml before
#     updating, so an existing machine picks it up from update.sh.
#   - DRY_RUN=true registers and installs nothing.
#
# USAGE:
#   ./tests/test_claude_plugins.sh   (or run the whole suite via: scripts/test)
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

# A fake dotfiles root: the real scripts, a fixture config.
mkdir -p "$SCRATCH/dotfiles" "$SCRATCH/bin" "$SCRATCH/state"
ln -s "$REPO_ROOT/scripts" "$SCRATCH/dotfiles/scripts"
cat > "$SCRATCH/dotfiles/dotfiles.yaml" <<'YAML'
packages:
  claude:
    marketplaces:
      - example/skills
    plugins:
      - existing@official
      - example@skills
YAML

# Stub claude. It records every call and keeps registered marketplaces and
# installed plugins in files, answering the way the real CLI does.
cat > "$SCRATCH/bin/claude" <<STUB
#!/bin/bash
state="$SCRATCH/state"
echo "\$*" >> "\$state/calls.log"
touch "\$state/marketplaces" "\$state/installed"
case "\$1 \$2 \${3:-}" in
    "--version  ") echo "2.0.0 (Claude Code)" ;;
    "plugin marketplace update") exit 0 ;;
    "plugin marketplace add")
        if grep -qx "\$4" "\$state/marketplaces"; then
            echo "✔ Marketplace '\${4#*/}' already on disk — declared in user settings"
        else
            echo "\$4" >> "\$state/marketplaces"
            echo "✔ Successfully added marketplace: \${4#*/} (declared in user settings)"
        fi
        ;;
    "plugin install "*)
        if grep -qx "\$3" "\$state/installed"; then
            echo "✔ Plugin \"\$3\" is already installed (scope: user)"
        else
            echo "\$3" >> "\$state/installed"
            echo "✔ Successfully installed plugin: \$3 (scope: user)"
        fi
        ;;
    "plugin update "*)
        if grep -qx "\$3" "\$state/installed"; then
            echo "✔ \${3%@*} is already at the latest version (1.0.0)."
        else
            echo "✘ Failed to update plugin \"\$3\": Plugin \"\${3%@*}\" not found" >&2
            exit 1
        fi
        ;;
    *) echo "unexpected: \$*" >&2; exit 2 ;;
esac
STUB
chmod +x "$SCRATCH/bin/claude"

run_script() {
    local name=$1
    shift
    env -i HOME="$SCRATCH" PATH="$SCRATCH/bin:$PATH" DOTFILES_DIR="$SCRATCH/dotfiles" "$@" \
        bash "$REPO_ROOT/scripts/$name" 2>&1
}

reset_state() {
    rm -f "$SCRATCH/state/"*
}

echo "install_claude_plugins / update_claude_plugins"

# 1. Fresh machine: marketplace registered before any install, all plugins installed.
reset_state
out=$(run_script install_claude_plugins || true)
first_add=$(grep -n '^plugin marketplace add example/skills' "$SCRATCH/state/calls.log" | head -1 | cut -d: -f1 || true)
first_install=$(grep -n '^plugin install' "$SCRATCH/state/calls.log" | head -1 | cut -d: -f1 || true)
if [[ -n "$first_add" && -n "$first_install" && $first_add -lt $first_install ]]; then
    pass "registers the marketplace before installing plugins"
else
    fail "registers the marketplace before installing plugins" "$(cat "$SCRATCH/state/calls.log")"
fi
if [[ "$(sort "$SCRATCH/state/installed" | tr '\n' ' ')" == "example@skills existing@official " ]]; then
    pass "installs every declared plugin"
else
    fail "installs every declared plugin" "installed: $(tr '\n' ' ' < "$SCRATCH/state/installed")"
fi

# 2. Re-run: already-installed plugins count as installed, not failed.
out=$(run_script install_claude_plugins || true)
if grep -q "2/2 installed" <<< "$out" && ! grep -q "failed" <<< "$out"; then
    pass "counts already-installed plugins as installed on re-run"
else
    fail "counts already-installed plugins as installed on re-run" "$out"
fi

# 3. Existing machine: update installs the newly declared plugin, then updates.
reset_state
echo "existing@official" > "$SCRATCH/state/installed"
out=$(run_script update_claude_plugins || true)
if grep -qx "example@skills" "$SCRATCH/state/installed" && ! grep -q "Failed to update" <<< "$out" \
    && grep -q "All Claude plugins are up to date" <<< "$out"; then
    pass "update installs a newly declared plugin before updating"
else
    fail "update installs a newly declared plugin before updating" "$out"
fi

# 4. Dry run: nothing registered or installed.
reset_state
out=$(run_script install_claude_plugins DRY_RUN=true || true)
if ! grep -q '^plugin \(marketplace add\|install\)' "$SCRATCH/state/calls.log" 2>/dev/null \
    && grep -q "Would register Claude marketplace: example/skills" <<< "$out"; then
    pass "dry run registers and installs nothing"
else
    fail "dry run registers and installs nothing" "$(cat "$SCRATCH/state/calls.log" 2>/dev/null)"
fi

summary
