#!/usr/bin/env bash
################################################################################
# migrate_native_plugins -- Regression Tests
#
# DESCRIPTION:
#   Exercises scripts/migrate_native_plugins against a fake HOME, a stubbed
#   `claude` and `codex`, and a fixture dotfiles.yaml with no plugins, so it
#   never touches real files or plugin state.
#
#   Coverage:
#   - The stale bostonaholic-skills@bostonaholic plugin and its 'bostonaholic'
#     marketplace are removed.
#   - ~/.claude/agents is unlinked only when it is a symlink.
#   - Listed skill copies move to ~/.agents/skills-retired; others stay.
#   - A second run changes nothing and succeeds.
#   - A name already in skills-retired stops the run instead of overwriting.
#   - DRY_RUN=true changes nothing.
#
# USAGE:
#   ./tests/test_migrate_native_plugins.sh   (or via: scripts/test)
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
printf 'packages: {}\n' > "$SCRATCH/dotfiles/dotfiles.yaml"

# Stub claude: state/claude-plugins and state/claude-markets hold what is installed.
cat > "$SCRATCH/bin/claude" <<STUB
#!/bin/bash
state="$SCRATCH/state"
echo "claude \$*" >> "\$state/calls.log"
touch "\$state/claude-plugins" "\$state/claude-markets"
case "\$1 \${2:-} \${3:-}" in
    "--version  ") echo "2.0.0 (Claude Code)" ;;
    "plugin list ") sed 's/^/  ❯ /' "\$state/claude-plugins" ;;
    "plugin marketplace list") sed 's/^/  ❯ /' "\$state/claude-markets" ;;
    "plugin marketplace update") exit 0 ;;
    "plugin uninstall "*) grep -vx "\$3" "\$state/claude-plugins" > "\$state/t" || true; mv "\$state/t" "\$state/claude-plugins"; echo "✔ Successfully uninstalled plugin" ;;
    "plugin marketplace remove") grep -vx "\$4" "\$state/claude-markets" > "\$state/t" || true; mv "\$state/t" "\$state/claude-markets"; echo "✔ Successfully removed marketplace: \$4" ;;
    *) echo "unexpected: \$*" >&2; exit 2 ;;
esac
STUB
cat > "$SCRATCH/bin/codex" <<STUB
#!/bin/bash
echo "codex \$*" >> "$SCRATCH/state/calls.log"
case "\$1 \${2:-} \${3:-}" in
    "--version  ") echo "codex-cli 0.160.0" ;;
    "plugin marketplace upgrade") exit 0 ;;
    *) echo "unexpected: \$*" >&2; exit 2 ;;
esac
STUB
chmod +x "$SCRATCH/bin/claude" "$SCRATCH/bin/codex"

setup_home() {
    rm -rf "${SCRATCH:?}/home" "${SCRATCH:?}/state/"*
    mkdir -p "$SCRATCH/home/.claude" "$SCRATCH/home/.agents/skills" "$SCRATCH/home/agents-target"
    ln -s "$SCRATCH/home/agents-target" "$SCRATCH/home/.claude/agents"
    for name in shipit gh-cli wrangler loops-lmx pricing-creativity humanizer frontend-design; do
        mkdir -p "$SCRATCH/home/.agents/skills/$name"
        echo "$name" > "$SCRATCH/home/.agents/skills/$name/SKILL.md"
    done
    printf 'bostonaholic-skills@bostonaholic\nbostonaholic@claude-mods\n' > "$SCRATCH/state/claude-plugins"
    printf 'bostonaholic\nclaude-mods\n' > "$SCRATCH/state/claude-markets"
}

run_migration() {
    env -i HOME="$SCRATCH/home" PATH="$SCRATCH/bin:$PATH" DOTFILES_DIR="$SCRATCH/dotfiles" "$@" \
        bash "$REPO_ROOT/scripts/migrate_native_plugins" 2>&1
}

listing() {
    (cd "$SCRATCH/home/.agents/$1" 2>/dev/null && ls | tr '\n' ' ')
}

echo "migrate_native_plugins"

# 1. Full migration.
setup_home
out=$(run_migration) && status=0 || status=$?
if [[ $status -eq 0 ]] && ! grep -q bostonaholic-skills "$SCRATCH/state/claude-plugins" \
    && ! grep -qx bostonaholic "$SCRATCH/state/claude-markets" \
    && grep -q 'bostonaholic@claude-mods' "$SCRATCH/state/claude-plugins"; then
    pass "removes the stale plugin and marketplace, keeps claude-mods"
else
    fail "removes the stale plugin and marketplace, keeps claude-mods" "$out"
fi
if [[ ! -e "$SCRATCH/home/.claude/agents" && -d "$SCRATCH/home/agents-target" ]]; then
    pass "unlinks the ~/.claude/agents symlink and keeps its target"
else
    fail "unlinks the ~/.claude/agents symlink and keeps its target"
fi
if [[ "$(listing skills)" == "frontend-design humanizer " \
    && "$(listing skills-retired)" == "gh-cli loops-lmx pricing-creativity shipit wrangler " ]]; then
    pass "retires listed copies and keeps the rest"
else
    fail "retires listed copies and keeps the rest" "skills: $(listing skills) | retired: $(listing skills-retired)"
fi

# 2. Second run: idempotent.
out=$(run_migration) && status=0 || status=$?
if [[ $status -eq 0 ]] && grep -q "retired 0 skill copies" <<< "$out" \
    && [[ "$(listing skills)" == "frontend-design humanizer " ]]; then
    pass "a second run changes nothing and succeeds"
else
    fail "a second run changes nothing and succeeds" "$out"
fi

# 3. Never overwrites an existing retired copy.
mkdir -p "$SCRATCH/home/.agents/skills/shipit"
out=$(run_migration) && status=0 || status=$?
if [[ $status -ne 0 ]] && grep -q "already exists" <<< "$out" && [[ -d "$SCRATCH/home/.agents/skills/shipit" ]]; then
    pass "stops instead of overwriting an existing retired copy"
else
    fail "stops instead of overwriting an existing retired copy" "status=$status $out"
fi

# 4. A real ~/.claude/agents directory is left alone.
setup_home
rm "$SCRATCH/home/.claude/agents" && mkdir "$SCRATCH/home/.claude/agents"
out=$(run_migration) && status=0 || status=$?
if [[ -d "$SCRATCH/home/.claude/agents" ]] && grep -q "real directory" <<< "$out"; then
    pass "leaves a real ~/.claude/agents directory in place"
else
    fail "leaves a real ~/.claude/agents directory in place" "$out"
fi

# 5. Dry run changes nothing.
setup_home
out=$(run_migration DRY_RUN=true) && status=0 || status=$?
if [[ -L "$SCRATCH/home/.claude/agents" && "$(listing skills-retired)" == "" ]] \
    && grep -q bostonaholic-skills "$SCRATCH/state/claude-plugins"; then
    pass "dry run changes nothing"
else
    fail "dry run changes nothing" "$out"
fi

summary
