#!/bin/bash
################################################################################
# macOS Full Disk Access Check -- Acceptance Tests
#
# DESCRIPTION:
#   Exercises scripts/install_macos_permissions against a scratch
#   dotfiles.yaml in DRY_RUN mode with a stubbed `open`, so it never launches
#   System Settings and never depends on this machine's actual grants.
#   Skips on non-macOS hosts.
#
# USAGE:
#   ./tests/test_macos_permissions.sh   (or run the whole suite via: scripts/test)
#
# EXIT CODE:
#   0 - All tests passed (or skipped)
#   1 - One or more tests failed
#
################################################################################

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/install_macos_permissions"

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
    echo -e "  passed: $pass_count  failed: $fail_count  skipped: $skip_count"
    [[ $fail_count -eq 0 ]]
}

echo "macOS Full Disk Access check:"

if [[ "$OSTYPE" != darwin* ]]; then
    skip "all cases" "not macOS"
    summary
    exit 0
fi

SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

# Stub `open` first in PATH so the script can never launch System Settings.
# It leaves a marker so the test can prove it was not called under DRY_RUN.
mkdir -p "$SCRATCH/bin"
cat > "$SCRATCH/bin/open" <<STUB
#!/bin/bash
touch "$SCRATCH/open-called"
STUB
chmod +x "$SCRATCH/bin/open"

# Runs the script against the given dotfiles.yaml content. Sets $output and
# $status. DOTFILES_DIR is honoured by scripts/lib.sh, which derives
# CONFIG_FILE from it, so the real dotfiles.yaml is never read.
run_script() {
    printf '%s\n' "$1" > "$SCRATCH/dotfiles.yaml"
    set +e
    output=$(PATH="$SCRATCH/bin:$PATH" DOTFILES_DIR="$SCRATCH" DRY_RUN=1 VERBOSE=true \
        bash "$SCRIPT" 2>&1)
    status=$?
    set -e
}

# Case 1: one real app, one missing app, dry run
run_script "macos:
  full_disk_access:
    - /System/Applications/Utilities/Terminal.app
    - /Applications/Definitely Not Here.app"

if [[ $status -eq 0 || $status -eq 1 ]]; then
    pass "exits 0 or 1 (no crash)"
else
    fail "exits 0 or 1 (no crash)" "exit status: $status"
fi

if grep -q 'Not installed, skipping: /Applications/Definitely Not Here.app' <<<"$output"; then
    pass "skips an app that is not installed"
else
    fail "skips an app that is not installed" "$output"
fi

terminal_lines=$(grep -cE '(granted|missing|unverifiable) +Terminal\.app \(com\.apple\.Terminal\)' <<<"$output" || true)
if [[ "$terminal_lines" == "1" ]]; then
    pass "reports exactly one status line for Terminal.app"
else
    fail "reports exactly one status line for Terminal.app" "$output"
fi

if grep -q 'granted +Terminal\.app' <<<"$output"; then
    pass "no instructions when the app is already granted"
elif grep -q '\[DRY RUN\] Would open System Settings' <<<"$output"; then
    pass "dry run prints the settings pane it would open"
else
    fail "dry run prints the settings pane it would open" "$output"
fi

if [[ ! -e "$SCRATCH/open-called" ]]; then
    pass "dry run never calls open"
else
    fail "dry run never calls open"
fi

# Case 2: empty allowlist
run_script "macos:
  full_disk_access: []"

if [[ $status -eq 0 ]] && grep -q 'No apps listed under macos.full_disk_access' <<<"$output"; then
    pass "empty allowlist exits 0 with a notice"
else
    fail "empty allowlist exits 0 with a notice" "status: $status; $output"
fi

# Case 3: no macos key at all
run_script "symlinks: {}"

if [[ $status -eq 0 ]] && grep -q 'No apps listed under macos.full_disk_access' <<<"$output"; then
    pass "missing macos key exits 0 with a notice"
else
    fail "missing macos key exits 0 with a notice" "status: $status; $output"
fi

summary
