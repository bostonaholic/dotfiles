#!/usr/bin/env bash
################################################################################
# Single Source for Plugins and MCP Servers -- Acceptance Tests
#
# DESCRIPTION:
#   dotfiles.yaml is the one list of Claude Code plugins and MCP servers.
#   Checks that claude/settings.json enables exactly the plugins it declares,
#   and runs scripts/install_mcp_servers against a stub claude.
#
# USAGE:
#   ./tests/test_single_source.sh   (or run the whole suite via: scripts/test)
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

if ! command -v yq >/dev/null 2>&1; then
    echo "  SKIP  yq not installed"
    exit 0
fi

echo "=== Single Source for Plugins and MCP Servers -- Acceptance Tests ==="
echo ""

echo "T1: claude/settings.json enables exactly the plugins in dotfiles.yaml"
declared="$(yq eval '.packages.claude.plugins[]' "$REPO_ROOT/dotfiles.yaml" | sort)"
enabled="$(jq -r '.enabledPlugins | to_entries[] | select(.value) | .key' "$REPO_ROOT/claude/settings.json" | sort)"
if [[ "$declared" == "$enabled" ]]; then
    pass "T1"
else
    fail "T1" "differs (< dotfiles.yaml, > settings.json): $(diff <(echo "$declared") <(echo "$enabled") | grep '^[<>]' | tr '\n' ' ')"
fi

SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
mkdir -p "$SCRATCH/dotfiles" "$SCRATCH/bin"
ln -s "$REPO_ROOT/scripts" "$SCRATCH/dotfiles/scripts"
cat > "$SCRATCH/dotfiles/dotfiles.yaml" <<'YAML'
mcp:
  claude:
    existing: old-server
    example: npx @example/mcp@latest
YAML

# Stub claude: "existing" is already registered; every call is recorded.
cat > "$SCRATCH/bin/claude" <<STUB
#!/bin/bash
echo "\$*" >> "$SCRATCH/calls.log"
[[ "\$1 \$2" == "mcp get" ]] && { [[ "\$3" == existing ]]; exit; }
exit 0
STUB
chmod +x "$SCRATCH/bin/claude"

# PATH holds the stub and the system tools only, so mcp-guardrail-proxy is
# found only when a test adds a stub for it.
run_installer() {
    env "$@" DOTFILES_DIR="$SCRATCH/dotfiles" \
        PATH="$SCRATCH/bin:$(dirname "$(command -v yq)"):/usr/bin:/bin" \
        "$REPO_ROOT/scripts/install_mcp_servers" 2>&1
}

echo "T2: registers a missing server at user scope and leaves a registered one"
: > "$SCRATCH/calls.log"
out="$(run_installer)"
if grep -qx 'mcp add --scope user example -- npx @example/mcp@latest' "$SCRATCH/calls.log" &&
   ! grep -q 'mcp add .* existing' "$SCRATCH/calls.log"; then
    pass "T2"
else
    fail "T2" "$out | calls: $(tr '\n' ';' < "$SCRATCH/calls.log")"
fi

echo "T3: puts mcp-guardrail-proxy in front of the command when installed"
: > "$SCRATCH/calls.log"
printf '#!/bin/bash\n' > "$SCRATCH/bin/mcp-guardrail-proxy"
chmod +x "$SCRATCH/bin/mcp-guardrail-proxy"
out="$(run_installer XDG_STATE_HOME=/state)"
rm "$SCRATCH/bin/mcp-guardrail-proxy"
if grep -qx 'mcp add --scope user example -- mcp-guardrail-proxy proxy --audit-log /state/mcp-guardrail/audit.jsonl -- npx @example/mcp@latest' "$SCRATCH/calls.log"; then
    pass "T3"
else
    fail "T3" "$out | calls: $(tr '\n' ';' < "$SCRATCH/calls.log")"
fi

echo "T4: dry run registers nothing"
: > "$SCRATCH/calls.log"
out="$(run_installer DRY_RUN=1)"
if ! grep -q 'mcp add' "$SCRATCH/calls.log" && grep -q 'Would register MCP server: example' <<< "$out"; then
    pass "T4"
else
    fail "T4" "$out"
fi

echo ""
echo "  passed: $pass_count  failed: $fail_count"
[[ $fail_count -eq 0 ]]
