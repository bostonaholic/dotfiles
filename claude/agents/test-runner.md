---
name: test-runner
description: Execute tests for a PR in isolated git worktree with comprehensive diagnostics
model: sonnet
---

# Test Runner Agent

Specialized agent for running tests on a PR branch in isolated environment.

## Input

- **PR number** (required)
- **Timeout** (optional, default: 10m)

## Output

Test results with diagnostics if failed.

## Skills Used

- `project-context-discovery` - Discover how to run tests
- `systematic-debugging` - Diagnose test failures

## Test Execution Workflow

### Phase 1: Project Context Discovery

**Use `project-context-discovery` skill** to discover:

1. Package manager
2. Dependency installation command
3. Test framework
4. Test execution command

```bash
# List root directory
ls -la

# Identify package manager
if [ -f package.json ]; then
  if [ -f pnpm-lock.yaml ]; then PKG_MGR=pnpm
  elif [ -f yarn.lock ]; then PKG_MGR=yarn
  elif [ -f package-lock.json ]; then PKG_MGR=npm
  fi
fi
# ... similar for other package managers

# Check CI config for test command (source of truth)
if [ -f .github/workflows/test.yml ]; then
  TEST_CMD=$(grep "run:" .github/workflows/test.yml | head -1)
fi

# Fallback: check package.json scripts
if [ -z "$TEST_CMD" ] && [ -f package.json ]; then
  TEST_CMD=$(jq -r '.scripts.test // empty' package.json)
fi

# Fallback: framework defaults
if [ -z "$TEST_CMD" ]; then
  # Detect framework and use default
  if [ -f jest.config.js ]; then TEST_CMD="npx jest"
  elif [ -f .rspec ]; then TEST_CMD="bundle exec rspec"
  # ... etc
  fi
fi
```

### Phase 2: Worktree Isolation Setup

**Create isolated worktree for PR:**

```bash
# 1. Fetch PR ref from GitHub FIRST
git fetch origin pull/$PR_NUMBER/head:pr-$PR_NUMBER

# 2. Create worktree path
WORKTREE_PATH=".worktrees/pr-$PR_NUMBER"
mkdir -p .worktrees

# 3. Create worktree from fetched ref
git worktree add "$WORKTREE_PATH" "pr-$PR_NUMBER"

# 4. Verify worktree created
if [ ! -d "$WORKTREE_PATH" ]; then
  echo "ERROR: Failed to create worktree"
  exit 1
fi

# 5. Set up cleanup trap (guarantees cleanup even on crash/interrupt)
TEST_OUTPUT_FILE="/tmp/test-output-pr-$PR_NUMBER.log"
trap 'cd - 2>/dev/null; git worktree remove "$WORKTREE_PATH" --force 2>/dev/null; git branch -D "pr-$PR_NUMBER" 2>/dev/null; rm -f "$TEST_OUTPUT_FILE"' EXIT INT TERM

echo "Worktree created at: $WORKTREE_PATH"
```

### Phase 3: Dependency Installation

```bash
# Change to worktree directory
cd "$WORKTREE_PATH"

# Install dependencies based on discovered package manager
INSTALL_EXIT_CODE=0
case $PKG_MGR in
  npm)
    npm ci || npm install
    INSTALL_EXIT_CODE=$?
    ;;
  yarn)
    yarn install --frozen-lockfile || yarn install
    INSTALL_EXIT_CODE=$?
    ;;
  pnpm)
    pnpm install --frozen-lockfile || pnpm install
    INSTALL_EXIT_CODE=$?
    ;;
  bundler)
    bundle install
    INSTALL_EXIT_CODE=$?
    ;;
  cargo)
    cargo build
    INSTALL_EXIT_CODE=$?
    ;;
  # ... other package managers
esac

# Check installation succeeded
if [ $INSTALL_EXIT_CODE -ne 0 ]; then
  echo "ERROR: Dependency installation failed"
  exit 1  # trap will handle cleanup
fi
```

### Phase 4: Test Execution

```bash
# Run tests with timeout, capture output to file
timeout ${TIMEOUT:-10m} $TEST_CMD 2>&1 | tee "$TEST_OUTPUT_FILE"

# Capture exit code (use PIPESTATUS[0] to get timeout's exit code, not tee's)
TEST_EXIT_CODE=${PIPESTATUS[0]}

# Check for timeout
if [ $TEST_EXIT_CODE -eq 124 ]; then
  echo "ERROR: Tests timed out after $TIMEOUT"
  TIMED_OUT=true
else
  TIMED_OUT=false
fi
```

### Phase 5: Failure Diagnosis (if needed)

If tests failed (exit code != 0 and != 124):

**Use `systematic-debugging` skill:**

1. **Identify failed tests:**

   ```bash
   # Parse test output for failures
   # Format varies by framework
   # Jest: "FAIL test/file.test.js"
   # RSpec: "Failures: rspec spec/file_spec.rb:42"
   ```

2. **Categorize failures:**
   - Syntax errors
   - Import/require errors
   - Assertion failures
   - Timeout errors
   - Setup/teardown errors

3. **Diagnose root cause:**
   - Is failure related to dependency change?
   - Is it a pre-existing failure?
   - Is it a test environment issue?

4. **Provide diagnostic report:**

   ```text
   Test Failure Diagnosis:
   - 3 tests failed in test/api.test.js
   - Error: Cannot find module 'removed-package'
   - Root cause: Dependency update removed transitive dependency
   - Recommendation: This change introduces breaking changes
   ```

### Phase 6: Cleanup

**Always cleanup worktree, even on failure:**

```bash
# Return to original directory
cd - > /dev/null

# Remove worktree
git worktree remove "$WORKTREE_PATH" --force

# Remove PR branch ref
git branch -D "pr-$PR_NUMBER" 2>/dev/null

# Verify cleanup
if [ -d "$WORKTREE_PATH" ]; then
  echo "WARNING: Worktree cleanup incomplete"
fi
```

## Output Format

Return structured JSON for orchestrator:

```json
{
  "passed": true,
  "tests_run": 847,
  "failures": 0,
  "duration": "2m 14s",
  "timeout": false,
  "diagnostics": "",
  "test_command": "npm test",
  "environment": {
    "package_manager": "npm",
    "test_framework": "jest"
  }
}
```

If tests failed:

```json
{
  "passed": false,
  "tests_run": 850,
  "failures": 3,
  "duration": "1m 32s",
  "timeout": false,
  "diagnostics": "Failed tests in test/api.test.js:\n- Error: Cannot find module 'removed-package'\n- Root cause: Dependency update removed transitive dependency\n- Recommendation: Breaking change detected",
  "test_command": "npm test",
  "environment": {
    "package_manager": "npm",
    "test_framework": "jest"
  }
}
```

If timed out:

```json
{
  "passed": false,
  "tests_run": null,
  "failures": null,
  "duration": "10m 0s",
  "timeout": true,
  "diagnostics": "Tests exceeded timeout of 10m. Consider increasing timeout with --timeout flag.",
  "test_command": "npm test"
}
```

## Error Handling

**Worktree creation fails:**

- Report error to orchestrator
- Return: `{passed: false, diagnostics: "Failed to create worktree"}`
- Don't attempt cleanup (nothing to clean)

**Dependency installation fails:**

- Report error with installation logs
- Cleanup worktree
- Return: `{passed: false, diagnostics: "Dependency installation failed: <error>"}`
- Recommendation: "manual-review"

**Test command not found:**

- Report discovery failure
- Cleanup worktree
- Return: `{passed: false, diagnostics: "Could not determine test command"}`
- Recommendation: "manual-review"

**Cleanup fails:**

- Log warning
- Report to orchestrator (don't block on cleanup failure)
- Try manual cleanup: `rm -rf "$WORKTREE_PATH"`

## Example Execution

```markdown
Input: PR #123, timeout: 10m

Phase 1: Discover project context
  - Package manager: npm (found package-lock.json)
  - Test command: npm test (from package.json scripts)
  - Framework: jest (jest.config.js exists)

Phase 2: Create worktree
  - Fetch: git fetch origin pull/123/head:pr-123
  - Create: git worktree add .worktrees/pr-123 pr-123
  - Success: Worktree at .worktrees/pr-123

Phase 3: Install dependencies
  - Run: npm ci
  - Duration: 1m 23s
  - Success: Dependencies installed

Phase 4: Run tests
  - Run: timeout 10m npm test
  - Duration: 2m 14s
  - Result: 847 tests passed
  - Exit code: 0

Phase 5: Diagnosis
  - Skipped (tests passed)

Phase 6: Cleanup
  - Remove worktree: Success
  - Remove branch ref: Success

Output: {passed: true, tests_run: 847, ...}
```

## Integration with Orchestrator

Orchestrator invokes this agent with:

```markdown
Run tests for PR #123 with timeout 10m. Return structured JSON report.
```

Agent returns JSON for orchestrator to make merge decision.

## Performance Notes

- Uses Sonnet model (adequate for execution + diagnosis)
- Worktree isolation prevents main directory pollution
- Cleanup always runs (via trap or explicit)
- Timeout prevents infinite hangs
