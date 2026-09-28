#!/usr/bin/env bash
################################################################################
# update_npm_packages -- Regression Tests
#
# DESCRIPTION:
#   Exercises scripts/update_npm_packages against a stubbed `npm` so it never
#   touches the real global package tree.
#
#   Regression coverage for: the updater parsed `npm outdated -g --parseable`
#   with `cut -d: -f4`, which yields `name@version`, and then called
#   `npm update -g name@version`. npm rejects versioned arguments with
#   EUPDATEARGS ("Update arguments must only contain package names"), so
#   every outdated package reported "Failed to update". The updater must
#   call `npm update -g` with bare package names (scoped names included).
#
# USAGE:
#   ./tests/test_update_npm_packages.sh   (or run the whole suite via: scripts/test)
#
# EXIT CODE:
#   0 - All tests passed
#   1 - One or more tests failed
#
################################################################################

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="${UPDATE_NPM_PACKAGES:-$REPO_ROOT/scripts/update_npm_packages}"

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

# Stub npm. It speaks both output formats (`--json` for the fixed script,
# `--parseable` for the buggy revision) and rejects update arguments that
# carry a version, exactly as real npm does with EUPDATEARGS.
mkdir -p "$SCRATCH/bin"
cat > "$SCRATCH/bin/npm" <<STUB
#!/bin/bash
case "\$1" in
    outdated)
        for arg in "\$@"; do
            case "\$arg" in
                --json)      cat "$SCRATCH/outdated.json"; exit 1 ;;
                --parseable) cat "$SCRATCH/outdated.parseable"; exit 1 ;;
            esac
        done
        exit 0
        ;;
    update)
        echo "\$*" >> "$SCRATCH/update-calls.log"
        for arg in "\${@:3}"; do
            if [[ "\$arg" == *@[0-9]* ]]; then
                echo "npm error code EUPDATEARGS" >&2
                echo "npm error Update arguments must only contain package names" >&2
                exit 1
            fi
        done
        exit 0
        ;;
esac
exit 0
STUB
chmod +x "$SCRATCH/bin/npm"

cat > "$SCRATCH/outdated.json" <<'JSON'
{
  "@playwright/cli": {
    "current": "0.1.19",
    "wanted": "0.1.21",
    "latest": "0.1.21",
    "dependent": "global"
  },
  "prettier": {
    "current": "3.8.1",
    "wanted": "3.9.9",
    "latest": "3.9.9",
    "dependent": "global"
  }
}
JSON

cat > "$SCRATCH/outdated.parseable" <<'PARSEABLE'
/prefix/lib/node_modules/@playwright/cli:@playwright/cli@0.1.21:@playwright/cli@0.1.19:@playwright/cli@0.1.21:global
/prefix/lib/node_modules/prettier:prettier@3.9.9:prettier@3.8.1:prettier@3.9.9:global
PARSEABLE

run_script() {
    rm -f "$SCRATCH/update-calls.log"
    set +e
    output=$(PATH="$SCRATCH/bin:$PATH" bash "$SCRIPT" 2>&1)
    status=$?
    set -e
}

echo "update_npm_packages:"

# Two outdated packages, including a scoped one.
run_script

if [[ $status -eq 0 ]]; then
    pass "exits 0 when updates succeed"
else
    fail "exits 0 when updates succeed" "status: $status; $output"
fi

if ! grep -q '\[WARN\]' <<<"$output"; then
    pass "reports no warnings"
else
    fail "reports no warnings" "$output"
fi

if [[ -e "$SCRATCH/update-calls.log" ]]; then
    calls="$(cat "$SCRATCH/update-calls.log")"
else
    calls=""
fi

if [[ -z "$calls" ]] || ! grep -q '@[0-9]' <<<"$calls"; then
    pass "passes bare package names to npm update"
else
    fail "passes bare package names to npm update" "$calls"
fi

expected=$'@playwright/cli\nprettier'
actual=""
if [[ -n "$calls" ]]; then
    actual=$(sed 's/^update -g //' <<<"$calls" | LC_ALL=C sort)
fi
if [[ "$actual" == "$expected" ]]; then
    pass "updates each outdated package once"
else
    fail "updates each outdated package once" "expected: $expected; actual: ${actual:-<none>}"
fi

# Everything up to date: no update calls, no warnings.
echo '{}' > "$SCRATCH/outdated.json"
: > "$SCRATCH/outdated.parseable"
run_script

if [[ $status -eq 0 ]] && grep -q 'All npm packages are up to date' <<<"$output"; then
    pass "reports up to date when nothing is outdated"
else
    fail "reports up to date when nothing is outdated" "status: $status; $output"
fi

if [[ ! -e "$SCRATCH/update-calls.log" ]]; then
    pass "makes no update calls when nothing is outdated"
else
    fail "makes no update calls when nothing is outdated" "$(cat "$SCRATCH/update-calls.log")"
fi

summary
