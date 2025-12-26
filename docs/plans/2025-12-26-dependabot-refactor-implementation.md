# Dependabot Merger Refactoring - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Refactor 741-line monolithic dependabot-merger agent into modular orchestrator-worker pattern with reusable skills

**Architecture:** Transform into 1 orchestrator (Haiku) + 3 workers (Sonnet/Haiku) + 3 reusable skills following December 2025 best practices

**Tech Stack:** Claude Code agents, skills, GitHub CLI

---

## Task 1: Create dependency-analysis skill

**Files:**
- Create: `claude/skills/dependency-analysis/SKILL.md`
- Create: `claude/skills/dependency-analysis/patterns/breaking-change-keywords.txt`
- Create: `claude/skills/dependency-analysis/patterns/changelog-sections.txt`
- Create: `claude/skills/dependency-analysis/templates/safety-report.md`

**Step 1: Create skill directory structure**

```bash
mkdir -p claude/skills/dependency-analysis/{patterns,templates}
```

**Step 2: Write SKILL.md**

Create `claude/skills/dependency-analysis/SKILL.md`:

```markdown
---
name: dependency-analysis
description: Breaking change detection patterns and dependency safety analysis for PR reviews
---

# Dependency Analysis Skill

Provides expertise in detecting breaking changes, analyzing dependency safety, and assessing upgrade risks.

## Purpose

This skill equips agents with patterns and techniques for:
- Detecting breaking changes in changelogs
- Analyzing semantic versioning implications
- Identifying risky dependency updates
- Scoring upgrade risk levels

## When to Use

Use this skill when:
- Analyzing dependency update PRs (Dependabot, Renovate, etc.)
- Reviewing semantic version changes
- Assessing breaking change risk
- Making merge/skip decisions for automated dependency updates

## Breaking Change Detection Strategy

### Four-Layer Analysis

**Layer 1: Changelog Analysis**
Parse release notes and changelogs for explicit breaking change indicators:
- Section headers: "Breaking Changes", "Migration Guide", "Upgrading", "BREAKING"
- Version jump patterns with substantial changes

**Layer 2: Keyword Analysis**
Search for breaking change keywords in context (see `patterns/breaking-change-keywords.txt`):
- High severity: BREAKING CHANGE, backwards incompatible, migration required
- Medium severity: removed, deprecated, no longer supported
- Low severity: changed default, renamed, moved

**Layer 3: Semantic Versioning**
Apply semver rules to classify risk:
- MAJOR (X.0.0): Incompatible API changes - HIGH RISK
- MINOR (0.X.0): Backwards compatible features - MEDIUM RISK
- PATCH (0.0.X): Backwards compatible fixes - LOW RISK

**Layer 4: Community Signals**
Check for warning signs:
- High issue activity around release date
- Multiple "breaking" mentions in discussions
- Migration guide present (implies breaking changes)

## Risk Scoring Rubric

Combine signals into risk score:

**HIGH RISK (Skip - Manual Review Required):**
- MAJOR version bump
- Explicit "BREAKING CHANGE" in changelog
- Migration guide present
- Removed APIs used in codebase

**MEDIUM RISK (Extra Scrutiny):**
- MINOR version with "removed"/"deprecated" keywords
- Substantial changelog with multiple changes
- Community reports of issues

**LOW RISK (Safe to Merge):**
- PATCH version bump
- Security fix with no breaking changes
- Minor bugfixes only
- Clean changelog

## Changelog Parsing

Expected changelog sections (see `patterns/changelog-sections.txt`):
- Breaking Changes / BREAKING / Migration Guide
- Added / New Features
- Changed / Updates
- Deprecated
- Removed
- Fixed / Bug Fixes
- Security

## Output Format

Use the safety report template (`templates/safety-report.md`) to structure findings:
- Risk level (low/medium/high)
- Semver classification
- Breaking changes detected (with evidence)
- Recommendation (merge/skip/manual-review)
- Reasoning

## Example Usage

```markdown
Agent using this skill:

1. Fetch changelog for dependency update
2. Apply Layer 1: Parse changelog structure
3. Apply Layer 2: Search for breaking keywords
4. Apply Layer 3: Classify semver change
5. Apply Layer 4: Check community signals
6. Score risk using rubric
7. Generate safety report using template
```

## Supporting Files

- `patterns/breaking-change-keywords.txt` - Keyword lists by severity
- `patterns/changelog-sections.txt` - Common section names
- `templates/safety-report.md` - Output template
```

**Step 3: Write breaking-change-keywords.txt**

Create `claude/skills/dependency-analysis/patterns/breaking-change-keywords.txt`:

```text
# Breaking Change Keywords
# Used for Layer 2 analysis in dependency safety assessment

## HIGH SEVERITY (Strong indicators)
BREAKING CHANGE
BREAKING:
breaking change
backwards incompatible
backward incompatible
not backwards compatible
migration required
migration guide
requires migration
incompatible with
must upgrade
required upgrade

## MEDIUM SEVERITY (Caution indicators)
removed
deprecated
no longer
no longer supported
dropped support
end of support
API removed
function removed
method removed
class removed
module removed
package removed
replaced with
renamed from
moved to
changed behavior
behavior change
default changed
breaking in

## LOW SEVERITY (Watch indicators)
changed default
renamed
moved
updated to require
now requires
minimum version
peer dependency
```

**Step 4: Write changelog-sections.txt**

Create `claude/skills/dependency-analysis/patterns/changelog-sections.txt`:

```text
# Common Changelog Section Names
# Used for Layer 1 analysis to identify changelog structure

## Breaking Changes Sections
BREAKING CHANGES
Breaking Changes
BREAKING
⚠️ Breaking Changes
💥 Breaking Changes
Migration Guide
Upgrade Guide
Upgrading
How to Upgrade

## Feature Sections
Added
New Features
Features
Additions
Enhancements

## Change Sections
Changed
Changes
Updates
Modified
Improvements

## Deprecation Sections
Deprecated
Deprecations
Deprecation Warnings

## Removal Sections
Removed
Removals
Deleted

## Fix Sections
Fixed
Bug Fixes
Fixes
Bugfixes
Patches

## Security Sections
Security
Security Fixes
Security Updates
CVE
Vulnerabilities
```

**Step 5: Write safety-report.md template**

Create `claude/skills/dependency-analysis/templates/safety-report.md`:

```markdown
# Dependency Safety Report

**Dependency:** {package_name}
**Version Change:** {old_version} → {new_version}
**Semver Classification:** {MAJOR|MINOR|PATCH}

## Risk Assessment

**Risk Level:** {LOW|MEDIUM|HIGH}

## Analysis Results

### Semantic Versioning
- Type: {MAJOR|MINOR|PATCH}
- Implication: {description}

### Breaking Changes Detected
{list breaking changes found, or "None detected"}

### Changelog Analysis
{summary of changelog findings}

### Community Signals
{any warning signs from issues/discussions}

## Recommendation

**Action:** {MERGE|SKIP|MANUAL_REVIEW}

**Reasoning:**
{explain why this recommendation was made}

## Evidence

### Changelog Excerpts
```
{relevant changelog sections}
```

### Keywords Found
{list any breaking change keywords detected}

## Next Steps

{if SKIP or MANUAL_REVIEW, provide guidance}
```

**Step 6: Verify skill structure**

```bash
ls -R claude/skills/dependency-analysis/
```

Expected output:
```
claude/skills/dependency-analysis/:
SKILL.md  patterns/  templates/

claude/skills/dependency-analysis/patterns:
breaking-change-keywords.txt  changelog-sections.txt

claude/skills/dependency-analysis/templates:
safety-report.md
```

**Step 7: Commit**

```bash
git add claude/skills/dependency-analysis/
git commit -m "feat(claude): add dependency-analysis skill for breaking change detection

Provides portable expertise for analyzing dependency safety:
- Four-layer breaking change detection strategy
- Risk scoring rubric (low/medium/high)
- Breaking change keyword patterns
- Changelog section identification
- Safety report template

Enables reusable dependency analysis across agents and workflows."
```

---

## Task 2: Create project-context-discovery skill

**Files:**
- Create: `claude/skills/project-context-discovery/SKILL.md`
- Create: `claude/skills/project-context-discovery/patterns/package-managers.yaml`
- Create: `claude/skills/project-context-discovery/patterns/test-frameworks.yaml`
- Create: `claude/skills/project-context-discovery/patterns/ci-configs.yaml`

**Step 1: Create skill directory structure**

```bash
mkdir -p claude/skills/project-context-discovery/patterns
```

**Step 2: Write SKILL.md**

Create `claude/skills/project-context-discovery/SKILL.md`:

```markdown
---
name: project-context-discovery
description: Discover project structure, package managers, test frameworks, and automation without hardcoded assumptions
---

# Project Context Discovery Skill

Provides expertise in discovering project characteristics through exploration rather than assumptions.

## Purpose

This skill equips agents with strategies for:
- Identifying package managers and build systems
- Discovering test frameworks and commands
- Finding automation scripts and tooling
- Learning project conventions from configuration

## When to Use

Use this skill when:
- Need to run tests but don't know the framework
- Setting up a new project environment
- Installing dependencies without hardcoded assumptions
- Discovering how CI/CD runs commands

## Discovery Strategy

### Phase 1: Project Structure Exploration

1. **List root directory contents**
   ```bash
   ls -la
   ```

2. **Identify language(s) from file extensions**
   - `.rb` → Ruby
   - `.js`/`.ts` → JavaScript/TypeScript
   - `.py` → Python
   - `.go` → Go
   - `.rs` → Rust
   - Multiple languages? Note all

3. **Find configuration files** (see `patterns/package-managers.yaml`)
   - `package.json` → npm/yarn/pnpm
   - `Gemfile` → Bundler (Ruby)
   - `Cargo.toml` → Cargo (Rust)
   - `go.mod` → Go modules
   - `pyproject.toml` → Poetry/pip
   - `requirements.txt` → pip

### Phase 2: Test Framework Discovery

1. **Check CI configuration first** (see `patterns/ci-configs.yaml`)
   - `.github/workflows/*.yml` → GitHub Actions
   - `.circleci/config.yml` → CircleCI
   - `.travis.yml` → Travis CI
   - `Jenkinsfile` → Jenkins

   CI config is **source of truth** for what actually runs.

2. **Parse CI test commands**
   Look for `run:` or `script:` sections with test commands.

3. **Check package manager configuration** (see `patterns/test-frameworks.yaml`)
   - `package.json` → check `scripts.test`
   - `Gemfile` → check for test gems (rspec, minitest)
   - `Cargo.toml` → check for test dependencies
   - `pyproject.toml` → check test tools

4. **Look for test directories**
   ```bash
   ls -d test/ tests/ spec/ __tests__/ 2>/dev/null
   ```

5. **Check for framework config files**
   - `jest.config.js` → Jest
   - `.rspec` → RSpec
   - `pytest.ini` → pytest
   - `phpunit.xml` → PHPUnit

### Phase 3: Automation Script Discovery

1. **Check documented commands** (prefer explicit over implicit)
   - `README.md` → look for "Testing", "Development", "Getting Started"
   - `CONTRIBUTING.md` → look for contribution workflow
   - `Makefile` → look for test targets

2. **Check automation directories**
   ```bash
   ls bin/ scripts/ script/ .local/bin/ 2>/dev/null
   ```

3. **Check package manager scripts**
   - npm: `npm run` (lists all scripts)
   - Bundler: `bundle exec rake -T`
   - Make: `make help` or `make -n`

### Phase 4: Dependency Installation

Based on discovered package manager:

**Node.js:**
```bash
if [ -f package-lock.json ]; then npm ci
elif [ -f yarn.lock ]; then yarn install --frozen-lockfile
elif [ -f pnpm-lock.yaml ]; then pnpm install --frozen-lockfile
else npm install; fi
```

**Ruby:**
```bash
bundle install
```

**Python:**
```bash
if [ -f pyproject.toml ]; then poetry install
elif [ -f requirements.txt ]; then pip install -r requirements.txt; fi
```

**Go:**
```bash
go mod download
```

**Rust:**
```bash
cargo build
```

### Phase 5: Test Command Construction

**Preference order:**
1. **Explicit documentation** (README/CONTRIBUTING)
2. **CI configuration** (source of truth)
3. **Package manager scripts** (npm test, rake test)
4. **Framework defaults** (only as fallback)

**Examples:**

If CI config shows:
```yaml
run: npm run test:ci
```
Use: `npm run test:ci`

If package.json shows:
```json
"scripts": {
  "test": "jest --coverage"
}
```
Use: `npm test`

If no explicit command, framework defaults:
- Jest: `npx jest`
- RSpec: `bundle exec rspec`
- pytest: `pytest`
- Go: `go test ./...`
- Rust: `cargo test`

## Graceful Degradation

If discovery fails at any phase:
1. Note what couldn't be determined
2. Make best-effort guess with caveats
3. Provide fallback options
4. Report incomplete discovery to user

**Never fail completely** - always provide a path forward.

## Example Usage

```markdown
Agent using this skill:

1. Read project root directory
2. Identify languages: JavaScript (package.json found)
3. Check CI: .github/workflows/test.yml exists
4. Parse CI: runs "npm run test:unit && npm run test:integration"
5. Check package.json scripts: confirms test:unit and test:integration
6. Discovery complete:
   - Package manager: npm
   - Install command: npm ci (package-lock.json exists)
   - Test command: npm run test:unit && npm run test:integration
7. Execute: npm ci && npm run test:unit && npm run test:integration
```

## Supporting Files

- `patterns/package-managers.yaml` - Package manager detection rules
- `patterns/test-frameworks.yaml` - Test framework indicators
- `patterns/ci-configs.yaml` - CI configuration file paths
```

**Step 3: Write package-managers.yaml**

Create `claude/skills/project-context-discovery/patterns/package-managers.yaml`:

```yaml
# Package Manager Detection Rules
# Used to identify package managers from project files

package_managers:
  npm:
    indicators:
      - package.json
      - package-lock.json
    install_command: "npm ci"
    install_fallback: "npm install"
    test_script_key: "scripts.test"
    list_scripts: "npm run"

  yarn:
    indicators:
      - package.json
      - yarn.lock
    install_command: "yarn install --frozen-lockfile"
    install_fallback: "yarn install"
    test_script_key: "scripts.test"
    list_scripts: "yarn run"

  pnpm:
    indicators:
      - package.json
      - pnpm-lock.yaml
    install_command: "pnpm install --frozen-lockfile"
    install_fallback: "pnpm install"
    test_script_key: "scripts.test"
    list_scripts: "pnpm run"

  bundler:
    indicators:
      - Gemfile
      - Gemfile.lock
    install_command: "bundle install"
    test_command_prefix: "bundle exec"
    list_tasks: "bundle exec rake -T"

  cargo:
    indicators:
      - Cargo.toml
      - Cargo.lock
    install_command: "cargo build"
    test_command: "cargo test"

  go_modules:
    indicators:
      - go.mod
      - go.sum
    install_command: "go mod download"
    test_command: "go test ./..."

  poetry:
    indicators:
      - pyproject.toml
      - poetry.lock
    install_command: "poetry install"
    test_command_prefix: "poetry run"

  pip:
    indicators:
      - requirements.txt
      - setup.py
    install_command: "pip install -r requirements.txt"
    test_command: "pytest"

# Priority order when multiple indicators present
priority:
  - pnpm  # Check pnpm before npm/yarn
  - yarn  # Check yarn before npm
  - npm
  - poetry  # Check poetry before pip
  - pip
  - bundler
  - cargo
  - go_modules
```

**Step 4: Write test-frameworks.yaml**

Create `claude/skills/project-context-discovery/patterns/test-frameworks.yaml`:

```yaml
# Test Framework Detection Rules
# Used to identify test frameworks and construct test commands

test_frameworks:
  jest:
    language: javascript
    indicators:
      config_files:
        - jest.config.js
        - jest.config.ts
        - jest.config.json
      package_json_deps:
        - jest
      directories:
        - __tests__
    default_command: "npx jest"
    common_scripts:
      - test
      - test:unit
      - test:ci

  vitest:
    language: javascript
    indicators:
      config_files:
        - vitest.config.js
        - vitest.config.ts
      package_json_deps:
        - vitest
    default_command: "npx vitest"

  rspec:
    language: ruby
    indicators:
      config_files:
        - .rspec
        - spec/spec_helper.rb
      gemfile_gems:
        - rspec
        - rspec-rails
      directories:
        - spec
    default_command: "bundle exec rspec"

  minitest:
    language: ruby
    indicators:
      gemfile_gems:
        - minitest
      directories:
        - test
      files:
        - test/test_helper.rb
    default_command: "bundle exec rake test"

  pytest:
    language: python
    indicators:
      config_files:
        - pytest.ini
        - pyproject.toml  # [tool.pytest]
        - setup.cfg  # [tool:pytest]
      directories:
        - tests
        - test
    default_command: "pytest"

  go_test:
    language: go
    indicators:
      files:
        - "*_test.go"
    default_command: "go test ./..."

  cargo_test:
    language: rust
    indicators:
      directories:
        - tests
      files:
        - "src/**/*_test.rs"
    default_command: "cargo test"

  mocha:
    language: javascript
    indicators:
      config_files:
        - .mocharc.js
        - .mocharc.json
      package_json_deps:
        - mocha
    default_command: "npx mocha"

# Framework detection strategy
detection_strategy:
  1: "Check CI configuration (most reliable)"
  2: "Check package manager test scripts"
  3: "Look for config files"
  4: "Check for framework dependencies"
  5: "Look for test directories"
  6: "Fall back to framework defaults"
```

**Step 5: Write ci-configs.yaml**

Create `claude/skills/project-context-discovery/patterns/ci-configs.yaml`:

```yaml
# CI Configuration File Paths
# Used to find CI configs that define the source of truth for test commands

ci_systems:
  github_actions:
    config_paths:
      - .github/workflows/*.yml
      - .github/workflows/*.yaml
    test_command_pattern: "run:\\s*(.+)"
    priority: high  # Most common

  gitlab_ci:
    config_paths:
      - .gitlab-ci.yml
    test_command_pattern: "script:\\s*-\\s*(.+)"
    priority: high

  circleci:
    config_paths:
      - .circleci/config.yml
    test_command_pattern: "run:\\s*(.+)"
    priority: medium

  travis_ci:
    config_paths:
      - .travis.yml
    test_command_pattern: "script:\\s*-\\s*(.+)"
    priority: low  # Less common now

  jenkins:
    config_paths:
      - Jenkinsfile
      - jenkins/Jenkinsfile
    test_command_pattern: "sh\\s+['\"](.+)['\"]"
    priority: medium

  azure_pipelines:
    config_paths:
      - azure-pipelines.yml
      - .azure-pipelines/*.yml
    test_command_pattern: "script:\\s*(.+)"
    priority: medium

# What to look for in CI configs
ci_analysis:
  test_job_names:
    - test
    - tests
    - unit-test
    - integration-test
    - test-suite
    - ci

  test_command_indicators:
    - npm test
    - npm run test
    - bundle exec rspec
    - pytest
    - go test
    - cargo test
    - make test

  setup_commands:
    - npm ci
    - npm install
    - bundle install
    - pip install
    - go mod download
    - cargo build
```

**Step 6: Verify skill structure**

```bash
ls -R claude/skills/project-context-discovery/
```

Expected output:
```
claude/skills/project-context-discovery/:
SKILL.md  patterns/

claude/skills/project-context-discovery/patterns:
ci-configs.yaml  package-managers.yaml  test-frameworks.yaml
```

**Step 7: Commit**

```bash
git add claude/skills/project-context-discovery/
git commit -m "feat(claude): add project-context-discovery skill

Provides portable expertise for discovering project characteristics:
- Package manager detection (npm, bundler, cargo, etc.)
- Test framework identification (jest, rspec, pytest, etc.)
- CI configuration parsing for test commands
- Dependency installation strategies
- Five-phase discovery process with graceful degradation

Enables context-aware testing without hardcoded assumptions."
```

---

## Task 3: Extend gh-cli skill with merge workflow

**Files:**
- Create: `claude/skills/gh-cli/workflows/merge-pr.md`

**Step 1: Check if gh-cli skill exists**

```bash
ls claude/skills/gh-cli/ 2>/dev/null || echo "Skill not found"
```

If skill doesn't exist, note that we'll create a minimal gh-cli skill structure.

**Step 2: Create workflows directory if needed**

```bash
mkdir -p claude/skills/gh-cli/workflows
```

**Step 3: Write merge-pr.md workflow**

Create `claude/skills/gh-cli/workflows/merge-pr.md`:

```markdown
# GitHub PR Merge Workflow

Safe PR merging strategies using GitHub CLI.

## Purpose

Provides patterns for safely merging pull requests with appropriate merge strategies and verification.

## Merge Strategy Detection

### Check Repository Settings

```bash
# Get repository's default merge method
gh repo view --json mergeCommitAllowed,squashMergeAllowed,rebaseMergeAllowed
```

### Strategy Selection

**Prefer in this order:**
1. **Squash** - Clean history for dependency updates
2. **Merge commit** - Preserves PR structure
3. **Rebase** - Linear history

For automated dependency updates (Dependabot, Renovate):
- **Always use squash** if available
- Single logical change = single commit

## Safe Merge Commands

### Auto-merge (Preferred)

Enables auto-merge once checks pass:

```bash
# Squash merge (recommended for dependency updates)
gh pr merge <number> --auto --squash --delete-branch

# Regular merge commit
gh pr merge <number> --auto --merge --delete-branch

# Rebase merge
gh pr merge <number> --auto --rebase --delete-branch
```

**Why auto-merge:**
- Waits for CI checks to pass
- Waits for required reviews
- Safer than immediate merge
- Non-blocking workflow

### Immediate Merge

Only use if checks already passed and urgent:

```bash
# Squash merge
gh pr merge <number> --squash --delete-branch

# Regular merge
gh pr merge <number> --merge --delete-branch

# Rebase merge
gh pr merge <number> --rebase --delete-branch
```

## Verification After Merge

Always verify merge succeeded:

```bash
# Check PR status
gh pr view <number> --json state,merged,mergedAt

# Expected output:
# {
#   "state": "MERGED",
#   "merged": true,
#   "mergedAt": "2025-12-26T..."
# }
```

## Error Handling

### Merge Conflicts

```bash
# Check for conflicts before attempting merge
gh pr view <number> --json mergeable

# If mergeable: "MERGEABLE"
# If conflicts: "CONFLICTING"
# If unknown: "UNKNOWN" (checks pending)
```

If conflicting:
- Skip merge
- Report conflict to user
- Recommend manual resolution

### Failing Checks

```bash
# Check CI status
gh pr checks <number>

# Wait for checks to complete (--watch)
gh pr checks <number> --watch
```

Never merge with failing checks.

### Permission Errors

If merge fails with permission error:
- Report to user
- Provide PR URL for manual merge
- Don't retry automatically

## Best Practices

1. **Always use --delete-branch** for dependency updates
   - Keeps repository clean
   - No orphaned branches

2. **Prefer --auto over immediate merge**
   - Safer (waits for checks)
   - Non-blocking
   - Handles race conditions

3. **Verify merge succeeded**
   - Don't assume success
   - Check actual state
   - Report failures clearly

4. **Handle dry-run mode**
   - Show what would be merged
   - Don't execute actual merge
   - Provide clear indication

## Example: Safe Merge Flow

```bash
# 1. Check if PR is mergeable
mergeable=$(gh pr view 123 --json mergeable -q .mergeable)

if [ "$mergeable" != "MERGEABLE" ]; then
  echo "PR has conflicts, skipping"
  exit 1
fi

# 2. Check CI status
checks=$(gh pr checks 123 --json state -q .[].state)

if echo "$checks" | grep -q "FAILURE\|ERROR"; then
  echo "PR has failing checks, skipping"
  exit 1
fi

# 3. Enable auto-merge (squash for dependency updates)
gh pr merge 123 --auto --squash --delete-branch

# 4. Verify auto-merge enabled
status=$(gh pr view 123 --json autoMergeRequest -q .autoMergeRequest)

if [ -n "$status" ]; then
  echo "Auto-merge enabled, will merge when checks pass"
else
  echo "Failed to enable auto-merge"
  exit 1
fi
```

## Dry-Run Mode

For --dry-run mode, show intended actions without executing:

```bash
echo "Would merge PR #123:"
echo "  Strategy: squash"
echo "  Delete branch: yes"
echo "  Method: auto-merge (wait for checks)"
```

## Integration with Agents

Agents using this workflow should:
1. Check merge strategy availability
2. Verify PR is mergeable
3. Check CI status
4. Enable auto-merge (preferred)
5. Verify auto-merge enabled
6. Report success/failure clearly
```

**Step 4: Verify workflow created**

```bash
ls -la claude/skills/gh-cli/workflows/merge-pr.md
```

Expected: File exists with merge workflow content.

**Step 5: Commit**

```bash
git add claude/skills/gh-cli/
git commit -m "feat(claude): add merge-pr workflow to gh-cli skill

Extends gh-cli skill with safe PR merging patterns:
- Merge strategy detection (squash/merge/rebase)
- Auto-merge preferred (wait for checks)
- Conflict and CI status checking
- Verification after merge
- Dry-run mode support

Enables safe automated PR merging in agents."
```

---

## Task 4: Create pr-analyzer worker agent

**Files:**
- Create: `claude/agents/pr-analyzer.md`

**Step 1: Write pr-analyzer agent**

Create `claude/agents/pr-analyzer.md`:

```markdown
---
name: pr-analyzer
description: Analyze a single Dependabot PR for safety - semver, breaking changes, dependencies
model: sonnet
---

# PR Analyzer Agent

Specialized agent for analyzing a single Dependabot PR to determine if it's safe to merge.

## Input

- **PR number** (required)
- **Repository context** (from current directory)

## Output

Structured safety report with recommendation.

## Skills Used

- `dependency-analysis` - Breaking change detection
- `gh-cli` - GitHub API operations

## Analysis Workflow

### Phase 1: Gather PR Details

```bash
# Fetch PR information
gh pr view $PR_NUMBER --json title,author,body,files

# Expected: PR title like "Bump nokogiri from 1.13.0 to 1.13.10"
```

**Extract:**
- Package name
- Old version
- New version

**Parse from title:** `Bump <package> from <old> to <new>`

### Phase 2: Semver Classification

Parse version numbers:
- Old: `1.13.0` → [1, 13, 0]
- New: `1.13.10` → [1, 13, 10]

**Apply semver rules:**
- If major (first number) changed → MAJOR
- Else if minor (second number) changed → MINOR
- Else if patch (third number) changed → PATCH

**Risk by semver:**
- MAJOR → HIGH RISK (always skip)
- MINOR → MEDIUM RISK (needs analysis)
- PATCH → LOW RISK (safe if no breaking changes)

**Decision:**
- MAJOR → Return immediately with "skip" recommendation
- MINOR/PATCH → Continue to next phase

### Phase 3: Breaking Change Detection

**Use `dependency-analysis` skill** for four-layer analysis.

**Layer 1: Fetch Changelog**

```bash
# Try to fetch release notes from GitHub
# Pattern: owner/repo can be extracted from git remote
remote=$(git remote get-url origin)
# Parse: git@github.com:owner/repo.git → owner/repo
#     or https://github.com/owner/repo.git → owner/repo

# Get release notes
gh release view "v$NEW_VERSION" --repo "$PACKAGE_REPO" --json body -q .body
```

If release notes found:
- Parse markdown structure
- Look for breaking change sections (use skill patterns)

**Layer 2: Keyword Search**

Search changelog/release notes for keywords from `dependency-analysis` skill:
- High severity: "BREAKING CHANGE", "backwards incompatible"
- Medium severity: "removed", "deprecated", "no longer"
- Low severity: "changed default", "renamed"

**Layer 3: API Surface Analysis**

For MINOR/MAJOR versions:
```bash
# Fetch the diff or commit messages
gh pr diff $PR_NUMBER

# Look for patterns in lockfile/manifest changes:
# - Dependencies removed
# - Dependencies with major version bumps
# - New peer dependencies
```

**Layer 4: Community Signals**

```bash
# Check recent issues mentioning "breaking"
gh issue list --repo "$PACKAGE_REPO" --search "breaking" --limit 5 --json number,title,createdAt

# Look for issues created around release date
# High issue volume = potential problems
```

**Risk Scoring (use dependency-analysis skill rubric):**

HIGH RISK if:
- MAJOR version
- "BREAKING CHANGE" found
- Migration guide present
- Removed APIs detected

MEDIUM RISK if:
- MINOR version with "removed"/"deprecated"
- Substantial changelog with many changes

LOW RISK if:
- PATCH version
- Security fix only
- Minor bugfixes

### Phase 4: Dependency Conflicts Check

```bash
# Check for dependency conflicts
# This varies by package manager

# For npm:
npm ls 2>&1 | grep -i "conflict\|unmet"

# For bundler:
bundle check 2>&1 | grep -i "conflict"

# For cargo:
cargo check 2>&1 | grep -i "conflict"

# If any conflicts found → HIGH RISK
```

### Phase 5: Generate Safety Report

Use `dependency-analysis` skill template (`templates/safety-report.md`):

```json
{
  "pr_number": 123,
  "package": "nokogiri",
  "old_version": "1.13.0",
  "new_version": "1.13.10",
  "semver": "PATCH",
  "risk": "low",
  "breaking_changes": [],
  "dependency_conflicts": [],
  "recommendation": "merge",
  "reasoning": "PATCH version with security fixes, no breaking changes detected",
  "evidence": {
    "changelog_excerpt": "...",
    "keywords_found": [],
    "community_signals": "Clean release, no issues reported"
  }
}
```

## Output Format

Return structured JSON for orchestrator:

```json
{
  "safe": true,
  "risk": "low",
  "semver": "PATCH",
  "breaking_changes": [],
  "dependency_conflicts": [],
  "recommendation": "merge",
  "reasoning": "PATCH version bump with security fixes, no breaking changes detected in changelog or community signals",
  "evidence": {
    "changelog_url": "https://github.com/...",
    "keywords_found": [],
    "community_issues": 0
  }
}
```

## Error Handling

**Changelog fetch fails:**
- Note in report
- Increase scrutiny for MINOR/MAJOR
- Still analyze what's available
- Continue with analysis

**GitHub API rate limit:**
- Report to orchestrator
- Return incomplete analysis
- Recommendation: "manual-review"

**Cannot parse version:**
- Report error
- Recommendation: "manual-review"

**Unknown package repository:**
- Skip Layer 1, 4 (no changelog/community check)
- Rely on semver + Layer 2 (keyword search in PR body)
- Note limitation in report

## Example Execution

```markdown
Input: PR #123

Step 1: Fetch PR details
  Title: "Bump nokogiri from 1.13.0 to 1.13.10"
  Package: nokogiri
  Old: 1.13.0, New: 1.13.10

Step 2: Semver classification
  Type: PATCH (third number changed)
  Risk: LOW

Step 3: Breaking change detection
  Layer 1: Fetched changelog
    - Found: Security fixes for CVE-2023-XXXX
    - No breaking change sections
  Layer 2: Keyword search
    - No breaking keywords found
  Layer 3: API surface
    - No API removals
  Layer 4: Community signals
    - 0 issues mentioning "breaking"

Step 4: Dependency conflicts
  npm ls: No conflicts

Step 5: Generate report
  Risk: LOW
  Recommendation: MERGE

Output: {safe: true, risk: "low", ...}
```

## Integration with Orchestrator

Orchestrator invokes this agent with:
```markdown
Analyze PR #123 for safety. Return structured JSON report.
```

Agent returns JSON for orchestrator to make merge decision.
```

**Step 2: Verify agent file**

```bash
wc -l claude/agents/pr-analyzer.md
```

Expected: ~250 lines

**Step 3: Test agent structure**

```bash
# Check YAML frontmatter
head -5 claude/agents/pr-analyzer.md
```

Expected output:
```
---
name: pr-analyzer
description: Analyze a single Dependabot PR for safety - semver, breaking changes, dependencies
model: sonnet
---
```

**Step 4: Commit**

```bash
git add claude/agents/pr-analyzer.md
git commit -m "feat(claude): add pr-analyzer worker agent

Specialized agent for analyzing single Dependabot PR:
- Semver classification (MAJOR/MINOR/PATCH)
- Four-layer breaking change detection (uses dependency-analysis skill)
- Dependency conflict checking
- Returns structured safety report with recommendation

Model: Sonnet (adequate for analysis tasks)
Output: JSON report for orchestrator decision-making"
```

---

## Task 5: Create test-runner worker agent

**Files:**
- Create: `claude/agents/test-runner.md`

**Step 1: Write test-runner agent**

Create `claude/agents/test-runner.md`:

```markdown
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
# Fetch PR ref from GitHub
git fetch origin pull/$PR_NUMBER/head:pr-$PR_NUMBER

# Create worktree path
WORKTREE_PATH=".worktrees/pr-$PR_NUMBER"
mkdir -p .worktrees

# Create worktree from fetched ref
git worktree add "$WORKTREE_PATH" "pr-$PR_NUMBER"

# Verify worktree created
if [ ! -d "$WORKTREE_PATH" ]; then
  echo "ERROR: Failed to create worktree"
  exit 1
fi

echo "Worktree created at: $WORKTREE_PATH"
```

### Phase 3: Dependency Installation

```bash
# Change to worktree directory
cd "$WORKTREE_PATH"

# Install dependencies based on discovered package manager
case $PKG_MGR in
  npm)
    npm ci || npm install
    ;;
  yarn)
    yarn install --frozen-lockfile || yarn install
    ;;
  pnpm)
    pnpm install --frozen-lockfile || pnpm install
    ;;
  bundler)
    bundle install
    ;;
  cargo)
    cargo build
    ;;
  # ... other package managers
esac

# Check installation succeeded
if [ $? -ne 0 ]; then
  echo "ERROR: Dependency installation failed"
  cd - && git worktree remove "$WORKTREE_PATH" --force
  exit 1
fi
```

### Phase 4: Test Execution

```bash
# Run tests with timeout
timeout ${TIMEOUT:-10m} $TEST_CMD

# Capture exit code
TEST_EXIT_CODE=$?

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
   ```
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
```

**Step 2: Verify agent file**

```bash
wc -l claude/agents/test-runner.md
```

Expected: ~300 lines

**Step 3: Test agent structure**

```bash
# Check YAML frontmatter
head -5 claude/agents/test-runner.md
```

**Step 4: Commit**

```bash
git add claude/agents/test-runner.md
git commit -m "feat(claude): add test-runner worker agent

Specialized agent for running tests in isolated worktree:
- Project context discovery (uses project-context-discovery skill)
- Git worktree isolation for safe test execution
- Dependency installation based on package manager
- Test execution with timeout protection
- Failure diagnosis (uses systematic-debugging skill)
- Guaranteed cleanup even on failure

Model: Sonnet (adequate for execution + diagnosis)
Output: JSON with test results and diagnostics"
```

---

## Task 6: Create security-checker worker agent

**Files:**
- Create: `claude/agents/security-checker.md`

**Step 1: Write security-checker agent**

Create `claude/agents/security-checker.md`:

```markdown
---
name: security-checker
description: Verify security advisories for Dependabot PRs via GitHub API
model: haiku
---

# Security Checker Agent

Lightweight agent for verifying security advisories in Dependabot PRs.

## Input

- **PR number** (required)

## Output

Security information including CVEs and severity.

## Skills Used

- `gh-cli` - GitHub security API access

## Security Verification Workflow

### Phase 1: Check if Security Fix

```bash
# Get PR details including body
gh pr view $PR_NUMBER --json body -q .body

# Check for security indicators in PR body
# Dependabot adds security warnings like:
# "**Vulnerabilities fixed**"
# "Fixes [CVE-2023-XXXX]"
```

**Look for patterns:**
- "Vulnerabilities fixed"
- "CVE-" followed by year and number
- "Security update"
- "Security fix"

If no security indicators found:
- Return: `{is_security_fix: false}`
- Skip remaining phases

### Phase 2: Extract CVE Information

```bash
# Parse CVE identifiers from PR body
# Pattern: CVE-YYYY-NNNNN
CVE_IDS=$(echo "$PR_BODY" | grep -o 'CVE-[0-9]\{4\}-[0-9]\+')

# For each CVE, fetch details
for CVE in $CVE_IDS; do
  gh api /advisories/$CVE --jq '{
    cve: .cve_id,
    severity: .severity,
    summary: .summary,
    published: .published_at
  }'
done
```

**Expected output format:**
```json
{
  "cve": "CVE-2023-12345",
  "severity": "high",
  "summary": "Nokogiri vulnerable to XXE via libxml2",
  "published": "2023-04-15T00:00:00Z"
}
```

### Phase 3: Verify Fix Applied

```bash
# Check the version being updated to
# PR title: "Bump nokogiri from 1.13.0 to 1.13.10"
NEW_VERSION=$(echo "$PR_TITLE" | grep -o 'to [0-9][^ ]*' | cut -d' ' -f2)

# Check if this version includes the fix
# From CVE advisory: "Fixed in version 1.13.10"
FIXED_IN=$(gh api /advisories/$CVE --jq '.patched_versions[]')

# Simple version comparison
# If NEW_VERSION >= FIXED_IN, fix is included
```

**Verification result:**
- Fix verified: New version meets or exceeds patched version
- Fix not verified: Version too old or info unavailable

## Output Format

Return structured JSON for orchestrator:

**Security fix found:**
```json
{
  "is_security_fix": true,
  "cves": [
    {
      "id": "CVE-2023-12345",
      "severity": "high",
      "summary": "Nokogiri vulnerable to XXE",
      "fixed_in": "1.13.10"
    }
  ],
  "severity": "high",
  "fix_verified": true,
  "details": "This update addresses 1 high severity vulnerability"
}
```

**Not a security fix:**
```json
{
  "is_security_fix": false,
  "cves": [],
  "severity": null,
  "fix_verified": null,
  "details": "No security advisories found for this update"
}
```

**Security fix but verification failed:**
```json
{
  "is_security_fix": true,
  "cves": [
    {
      "id": "CVE-2023-12345",
      "severity": "high",
      "summary": "Nokogiri vulnerable to XXE"
    }
  ],
  "severity": "high",
  "fix_verified": false,
  "details": "Unable to verify fix version"
}
```

## Error Handling

**GitHub API rate limit:**
- Return: `{is_security_fix: null, error: "Rate limit exceeded"}`
- Orchestrator should skip or manual-review

**CVE not found:**
- Note in output
- Return what's available
- Fix_verified: false

**Cannot parse PR body:**
- Return: `{is_security_fix: false}`
- Continue (not critical)

## Example Execution

```markdown
Input: PR #123

Phase 1: Check if security fix
  - PR body contains: "**Vulnerabilities fixed**"
  - Found: "CVE-2023-12345"
  - Result: IS security fix

Phase 2: Extract CVE info
  - Fetch CVE-2023-12345 from GitHub API
  - Severity: high
  - Summary: "Nokogiri vulnerable to XXE"
  - Fixed in: 1.13.10

Phase 3: Verify fix applied
  - PR updates to: 1.13.10
  - Fixed in: 1.13.10
  - Result: Fix VERIFIED

Output: {is_security_fix: true, severity: "high", fix_verified: true}
```

## Integration with Orchestrator

Orchestrator invokes this agent when:
- PR analyzer indicates potential security fix
- Always check for Dependabot PRs (adds context)

```markdown
Check security advisories for PR #123. Return structured JSON.
```

Agent returns JSON for orchestrator reporting.

## Performance Notes

- Uses Haiku model (simple API calls, cheap)
- Lightweight (only 3 phases, mostly API calls)
- Fast execution (< 10 seconds typical)
- Optional (only called when relevant)
```

**Step 2: Verify agent file**

```bash
wc -l claude/agents/security-checker.md
```

Expected: ~180 lines

**Step 3: Test agent structure**

```bash
head -5 claude/agents/security-checker.md
```

**Step 4: Commit**

```bash
git add claude/agents/security-checker.md
git commit -m "feat(claude): add security-checker worker agent

Lightweight agent for verifying security advisories:
- Check if PR is security fix (parse PR body)
- Extract CVE information via GitHub API
- Verify fix version matches advisory
- Returns structured security report

Model: Haiku (simple API calls, cost-effective)
Output: JSON with CVE details and verification status"
```

---

## Task 7: Create orchestrator agent

**Files:**
- Create: `claude/agents/dependabot-orchestrator.md`

**Step 1: Write orchestrator agent**

Create `claude/agents/dependabot-orchestrator.md`:

```markdown
---
name: dependabot-orchestrator
description: Lightweight orchestrator for coordinating Dependabot PR analysis and merging via worker agents
model: haiku
---

# Dependabot Orchestrator Agent

Coordinates analysis of Dependabot PRs by dispatching specialized worker agents and making merge decisions.

## Input Context

Receives from command:
- `pr_numbers`: Array of PR numbers (or empty for discovery)
- `dry_run`: Boolean (true = don't merge, just report)
- `timeout`: Test timeout (e.g., "10m")

## Skills Used

- `gh-cli` - PR discovery and merging

## Orchestration Workflow

### Phase 1: Discover Dependabot PRs

If `pr_numbers` is empty, discover all open Dependabot PRs:

```bash
gh pr list \
  --author app/dependabot \
  --state open \
  --json number,title,author \
  --limit 100
```

**Parse output:**
```json
[
  {"number": 123, "title": "Bump nokogiri from 1.13.0 to 1.13.10"},
  {"number": 124, "title": "Bump react from 18.2.0 to 19.0.0"}
]
```

If `pr_numbers` provided, use those directly.

**Report to user:**
```
🔍 Discovering Dependabot PRs...
Found 5 open Dependabot PRs: #123, #124, #125, #126, #127
```

### Phase 2: Process PRs Sequentially

For each PR in list:

```markdown
📦 PR #123: Bump nokogiri from 1.13.0 to 1.13.10
```

#### Step 2.1: Dispatch pr-analyzer

```markdown
Use Task tool to dispatch pr-analyzer agent:
- description: "Analyze PR #123 for safety"
- prompt: "Analyze PR #123. Return JSON safety report with: safe, risk, semver, breaking_changes, dependency_conflicts, recommendation, reasoning"
- subagent_type: general-purpose
- model: sonnet
```

**Wait for pr-analyzer response.**

**Parse JSON response:**
```json
{
  "safe": true,
  "risk": "low",
  "semver": "PATCH",
  "breaking_changes": [],
  "dependency_conflicts": [],
  "recommendation": "merge",
  "reasoning": "PATCH version with security fixes, no breaking changes"
}
```

**Report to user:**
```
  ├─ Semver: PATCH (safe)
  ├─ Changelog: No breaking changes detected ✓
  ├─ Dependencies: No conflicts ✓
```

#### Step 2.2: Check Recommendation

If `recommendation` is "skip" or "manual-review":
- Record skip reason
- Continue to next PR
- Report:
```
  └─ Decision: SKIP - {reasoning}
```

If `recommendation` is "merge", continue to test execution.

#### Step 2.3: Dispatch test-runner

```markdown
Use Task tool to dispatch test-runner agent:
- description: "Run tests for PR #123"
- prompt: "Run tests for PR #123 with timeout {timeout}. Return JSON with: passed, tests_run, failures, duration, timeout, diagnostics"
- subagent_type: general-purpose
- model: sonnet
```

**Wait for test-runner response.**

**Parse JSON response:**
```json
{
  "passed": true,
  "tests_run": 847,
  "failures": 0,
  "duration": "2m 14s",
  "timeout": false,
  "diagnostics": ""
}
```

**Report to user:**
```
  ├─ Tests: Running test suite...
  ├─ Tests: 847 passed in 2m 14s ✓
```

#### Step 2.4: Check Test Results

If `passed` is false:
- Record skip reason with diagnostics
- Continue to next PR
- Report:
```
  └─ Decision: SKIP - Tests failed
      Diagnostics: {diagnostics}
```

If `passed` is true, continue to security check (optional).

#### Step 2.5: Dispatch security-checker (optional)

If PR body or pr-analyzer indicates security fix:

```markdown
Use Task tool to dispatch security-checker agent:
- description: "Check security advisories for PR #123"
- prompt: "Check security advisories for PR #123. Return JSON with: is_security_fix, cves, severity, fix_verified"
- subagent_type: general-purpose
- model: haiku
```

**Wait for security-checker response.**

**Parse JSON response:**
```json
{
  "is_security_fix": true,
  "cves": [{"id": "CVE-2023-12345", "severity": "high"}],
  "severity": "high",
  "fix_verified": true
}
```

**Report to user:**
```
  ├─ Security: Fixes CVE-2023-12345 (high) ✓
```

If not security fix, skip this step.

#### Step 2.6: Make Merge Decision

**All checks passed:**
- pr-analyzer: safe = true
- test-runner: passed = true
- security-checker: verified (if applicable)

**Decision: MERGE**

#### Step 2.7: Execute Merge (if not dry-run)

If `dry_run` is false:

```bash
# Use gh-cli skill merge-pr workflow
# Enable auto-merge with squash strategy
gh pr merge $PR_NUMBER --auto --squash --delete-branch
```

**Verify auto-merge enabled:**
```bash
gh pr view $PR_NUMBER --json autoMergeRequest -q .autoMergeRequest
```

If auto-merge enabled:
```
  └─ Decision: MERGE ✓ (auto-merge enabled, will merge when checks pass)
```

If auto-merge failed:
```
  └─ Decision: MERGE FAILED - {error}
```

**Record merge success/failure.**

If `dry_run` is true:
```
  └─ Decision: WOULD MERGE (dry-run mode)
```

**Record would-merge count.**

### Phase 3: Final Summary Report

After processing all PRs, generate summary:

```
═══════════════════════════════════════════════════════════
                    Summary Report
═══════════════════════════════════════════════════════════

✓ Merged: 3 PRs
  - PR #123: nokogiri 1.13.0 → 1.13.10 (PATCH, security fix)
  - PR #125: rack 2.2.3 → 2.2.8 (PATCH)
  - PR #127: rubocop 1.50.0 → 1.50.2 (PATCH)

⏭️  Skipped: 2 PRs
  - PR #124: react 18.2.0 → 19.0.0 (MAJOR version - requires manual review)
  - PR #126: rspec 3.11.0 → 3.12.0 (MINOR - test failures)
    Diagnostics: 3 tests failed due to deprecated API usage

═══════════════════════════════════════════════════════════

Total Time: 8m 43s
Next Actions:
  - Review skipped PRs manually: gh pr view 124, gh pr view 126
  - Monitor auto-merge PRs: gh pr checks 123, 125, 127
```

If dry-run mode:
```
═══════════════════════════════════════════════════════════
                Summary Report (DRY RUN)
═══════════════════════════════════════════════════════════

Would Merge: 3 PRs
  - PR #123: nokogiri 1.13.0 → 1.13.10 (PATCH, security fix)
  - PR #125: rack 2.2.3 → 2.2.8 (PATCH)
  - PR #127: rubocop 1.50.0 → 1.50.2 (PATCH)

Would Skip: 2 PRs
  - PR #124: react 18.2.0 → 19.0.0 (MAJOR version)
  - PR #126: rspec 3.11.0 → 3.12.0 (test failures)

═══════════════════════════════════════════════════════════

No PRs were actually merged (dry-run mode).
To merge, run: /safely-merge-dependabots
```

## Error Handling

**Worker agent fails to respond:**
- Log error
- Record PR as "needs manual review"
- Continue to next PR
- Include in skip report

**GitHub API errors:**
- PR discovery fails → report error, exit
- PR merge fails → record failure, continue to next PR
- Rate limit hit → report clearly, suggest wait time

**Worker returns invalid JSON:**
- Log parsing error
- Record PR as "needs manual review"
- Continue to next PR

**Timeout (orchestrator level):**
- If entire workflow takes > 30 minutes
- Report progress so far
- Recommend continuing with remaining PRs

## Design Principles

**Pure Orchestration:**
- No implementation details
- Dispatch to workers
- Make decisions based on worker results
- Report progress clearly

**Lightweight Context:**
- Only coordination logic
- Workers handle complexity
- Minimal lines (~150)

**Sequential Processing:**
- One PR at a time
- Clear audit trail
- Failure isolation

**Clear Reporting:**
- Real-time progress
- Visual separators
- Actionable next steps

## Example Execution

```markdown
Input: pr_numbers: [], dry_run: false, timeout: "10m"

Phase 1: Discover PRs
  Found 3 PRs: #123, #124, #125

Phase 2: Process each PR

PR #123:
  - Dispatch pr-analyzer → {safe: true, risk: "low"}
  - Dispatch test-runner → {passed: true, tests_run: 847}
  - Dispatch security-checker → {is_security_fix: true, severity: "high"}
  - Decision: MERGE
  - Execute: gh pr merge 123 --auto --squash --delete-branch
  - Result: Success ✓

PR #124:
  - Dispatch pr-analyzer → {safe: false, risk: "high", recommendation: "skip"}
  - Decision: SKIP (MAJOR version)

PR #125:
  - Dispatch pr-analyzer → {safe: true, risk: "low"}
  - Dispatch test-runner → {passed: true, tests_run: 203}
  - Decision: MERGE
  - Execute: gh pr merge 125 --auto --squash --delete-branch
  - Result: Success ✓

Phase 3: Final Summary
  Merged: 2 PRs (#123, #125)
  Skipped: 1 PR (#124 - MAJOR version)
  Total time: 5m 12s
```

## Integration with Command

Command invokes orchestrator with parsed arguments:
```markdown
Analyze and merge Dependabot PRs with:
- PR numbers: {pr_numbers or "all"}
- Dry run: {true|false}
- Timeout: {timeout}
```

Orchestrator handles everything and reports final results.
```

**Step 2: Verify agent file**

```bash
wc -l claude/agents/dependabot-orchestrator.md
```

Expected: ~320 lines (still lightweight for an orchestrator!)

**Step 3: Test agent structure**

```bash
head -5 claude/agents/dependabot-orchestrator.md
```

**Step 4: Commit**

```bash
git add claude/agents/dependabot-orchestrator.md
git commit -m "feat(claude): add dependabot-orchestrator agent

Lightweight orchestrator for coordinating PR analysis and merging:
- Discovers open Dependabot PRs (or uses specified list)
- Dispatches worker agents sequentially per PR:
  - pr-analyzer (safety analysis)
  - test-runner (test execution)
  - security-checker (CVE verification)
- Makes merge decisions based on worker results
- Executes merges via gh CLI (auto-merge preferred)
- Generates comprehensive summary report

Model: Haiku (cheap, fast coordination)
Design: Pure orchestration, no implementation details (~320 lines)"
```

---

## Task 8: Update command to use orchestrator

**Files:**
- Modify: `claude/commands/safely-merge-dependabots.md`

**Step 1: Read current command file**

```bash
cat claude/commands/safely-merge-dependabots.md
```

Review current agent invocation section.

**Step 2: Update agent invocation**

Modify the "Agent Invocation" section in `claude/commands/safely-merge-dependabots.md`:

**OLD:**
```yaml
agent: dependabot-merger
model: opus
```

**NEW:**
```yaml
agent: dependabot-orchestrator
model: haiku
```

**Exact change:**

Find:
```markdown
## Agent Invocation

Invoke the `dependabot-merger` agent with parsed arguments:

```yaml
agent: dependabot-merger
model: opus
```

Replace with:
```markdown
## Agent Invocation

Invoke the `dependabot-orchestrator` agent with parsed arguments:

```yaml
agent: dependabot-orchestrator
model: haiku
```

**Step 3: Update expected output note (optional improvement)**

Find the "Expected Output" section and update the intro note:

**Add before the example output:**
```markdown
**Note:** Performance improved in v2 with modular architecture:
- Haiku orchestrator (3x cheaper, 2x faster coordination)
- Specialized worker agents (Sonnet for analysis, Haiku for simple tasks)
- Enables future parallel PR analysis
```

**Step 4: Verify changes**

```bash
git diff claude/commands/safely-merge-dependabots.md
```

Should show:
- `dependabot-merger` → `dependabot-orchestrator`
- `opus` → `haiku`
- Added performance note

**Step 5: Commit**

```bash
git add claude/commands/safely-merge-dependabots.md
git commit -m "refactor(claude): update command to use orchestrator architecture

Switch from monolithic dependabot-merger to modular orchestrator:
- Agent: dependabot-orchestrator (replaces dependabot-merger)
- Model: haiku (replaces opus - cheaper/faster for coordination)
- Architecture: Orchestrator dispatches specialized workers
- Benefits: 3x cost reduction, 2x speed improvement

Command interface unchanged - transparent to users."
```

---

## Task 9: Deprecate old monolithic agent

**Files:**
- Rename: `claude/agents/dependabot-merger.md` → `claude/agents/dependabot-merger.deprecated.md`
- Modify: `claude/agents/dependabot-merger.deprecated.md` (add deprecation notice)

**Step 1: Add deprecation notice to file**

Add at the very top of `claude/agents/dependabot-merger.md` (before YAML frontmatter):

```markdown
> **⚠️ DEPRECATED:** This monolithic agent has been replaced by the modular architecture.
>
> **Use instead:** `dependabot-orchestrator` + worker agents
> - Orchestrator: `claude/agents/dependabot-orchestrator.md`
> - Workers: `pr-analyzer`, `test-runner`, `security-checker`
>
> **Why deprecated:**
> - Monolithic design (741 lines, single responsibility violation)
> - Expensive (Opus for everything, including simple coordination)
> - Slow (large context window, single model)
> - Not extensible (no reusable components)
>
> **New architecture benefits:**
> - 3x cost reduction (Haiku orchestrator vs Opus monolith)
> - 2-3x speed improvement (lighter models, smaller contexts)
> - Modular (single responsibility per component)
> - Extensible (reusable skills and worker agents)
>
> **Kept for:** Reference and rollback during transition period.
> **Delete after:** 2 weeks validation or 20 successful runs of new architecture.
>
> **Date deprecated:** 2025-12-26

---
name: dependabot-merger
...
```

**Step 2: Rename file**

```bash
git mv claude/agents/dependabot-merger.md claude/agents/dependabot-merger.deprecated.md
```

**Step 3: Verify rename**

```bash
git status
```

Should show:
```
renamed: claude/agents/dependabot-merger.md -> claude/agents/dependabot-merger.deprecated.md
```

**Step 4: Commit**

```bash
git add claude/agents/dependabot-merger.deprecated.md
git commit -m "refactor(claude): deprecate monolithic dependabot-merger agent

Mark as deprecated in favor of modular orchestrator architecture:
- Renamed: dependabot-merger.md → dependabot-merger.deprecated.md
- Added deprecation notice with migration guide
- Kept for rollback during 2-week validation period
- Delete after validation confirms new architecture stable

Replacement: dependabot-orchestrator + 3 worker agents + 3 skills"
```

---

## Task 10: Create validation plan

**Files:**
- Create: `docs/plans/2025-12-26-dependabot-refactor-validation.md`

**Step 1: Write validation plan**

Create `docs/plans/2025-12-26-dependabot-refactor-validation.md`:

```markdown
# Dependabot Refactor Validation Plan

**Date:** 2025-12-26
**Purpose:** Validate modular orchestrator architecture before permanently removing old monolith

## Validation Criteria

### Functional Parity

- [ ] Discovers same PRs as monolith
- [ ] Makes same merge decisions (safe vs skip)
- [ ] Handles all error cases gracefully
- [ ] Produces equivalent final reports
- [ ] Respects --dry-run mode
- [ ] Respects --timeout override
- [ ] Respects PR number selection

### Performance Improvements

- [ ] Reduce cost per PR by >50% (measure: token usage)
- [ ] Reduce latency by >30% (measure: total execution time)
- [ ] Orchestrator uses Haiku model
- [ ] Workers use appropriate models (Sonnet/Haiku)

### Code Quality

- [ ] Each component <350 lines
- [ ] Each component has single responsibility
- [ ] Skills reusable outside this workflow
- [ ] Clear interfaces between components
- [ ] Comprehensive error handling per component

## Validation Method

### Phase 1: Dry-Run Comparison (Week 1)

Run both architectures side-by-side on same PRs in dry-run mode:

```bash
# Temporarily enable old agent for comparison
cp claude/agents/dependabot-merger.deprecated.md claude/agents/dependabot-merger.md

# Run old architecture
/safely-merge-dependabots --dry-run > old-results.txt

# Switch to new architecture
rm claude/agents/dependabot-merger.md

# Run new architecture
/safely-merge-dependabots --dry-run > new-results.txt

# Compare results
diff old-results.txt new-results.txt
```

**Expected:** Same PRs would be merged/skipped.

**If differences found:**
- Document discrepancies
- Determine if new architecture is safer (acceptable)
- Fix if new architecture is less safe (required)

### Phase 2: Live Validation (Week 2)

Run new architecture on real PRs:

```bash
# Run with actual merges
/safely-merge-dependabots

# Monitor merged PRs
# - Do they pass CI after merge?
# - Any introduced bugs?
# - Any rollbacks required?
```

**Success Criteria:**
- 20 successful PR processing runs, OR
- 2 weeks without issues, whichever comes first

**Track:**
- Total PRs processed
- PRs merged successfully
- PRs skipped correctly
- False positives (should skip but merged)
- False negatives (should merge but skipped)
- Execution time per run
- Cost per run (estimate from model usage)

### Phase 3: Performance Measurement

**Collect metrics:**

| Metric | Monolith | Modular | Improvement |
|--------|----------|---------|-------------|
| Avg time per PR | ? | ? | ? |
| Cost per PR (est.) | Opus tokens | Haiku/Sonnet tokens | ? |
| Lines of code | 741 | <350 each | ? |
| Reusable components | 0 | 3 skills | ∞ |

**Calculate:**
- Cost reduction: `(Monolith - Modular) / Monolith * 100%`
- Speed improvement: `(Monolith - Modular) / Monolith * 100%`

**Target:**
- Cost: >50% reduction
- Speed: >30% improvement

## Decision Criteria

### ✅ Safe to Delete Monolith If:

- All functional parity checks pass
- 20+ successful runs OR 2 weeks validation
- No false positives (unsafe merges)
- Performance improvements meet targets
- No critical issues found
- Team comfortable with new architecture

### ⚠️ Keep Monolith Longer If:

- <20 runs OR <2 weeks elapsed
- Performance targets not met (investigate why)
- Functional differences require discussion
- Team wants more validation time

### ❌ Rollback to Monolith If:

- False positives found (merged unsafe PRs)
- Critical bugs in workers or orchestrator
- Performance worse than monolith
- Workers fail frequently
- Can't determine merge decisions reliably

## Rollback Procedure

If rollback needed:

```bash
# Restore old agent
cp claude/agents/dependabot-merger.deprecated.md claude/agents/dependabot-merger.md

# Update command
# Change agent: dependabot-orchestrator → dependabot-merger
# Change model: haiku → opus

# Test old agent works
/safely-merge-dependabots --dry-run

# Commit rollback
git add claude/commands/safely-merge-dependabots.md
git commit -m "revert: rollback to monolithic dependabot-merger due to {reason}"
```

## Permanent Deletion Procedure

After validation passes:

```bash
# Remove deprecated agent
git rm claude/agents/dependabot-merger.deprecated.md

# Commit deletion
git commit -m "refactor(claude): remove deprecated dependabot-merger

Validation complete:
- 20+ successful runs over 2 weeks
- All functional parity checks passed
- Performance targets met (50%+ cost reduction, 30%+ speed improvement)
- No critical issues found

Modular orchestrator architecture is now the sole implementation."
```

## Monitoring During Validation

**What to watch:**
- CI status on merged PRs
- User reports of issues
- Error messages in orchestrator/workers
- Skipped PRs (review manually to confirm correct)
- Worker agent failures

**Where to check:**
- GitHub Actions logs
- Merged PR CI status
- Manual review of skipped PRs
- User feedback

## Documentation

After validation, update docs:

- Remove deprecation notices from code
- Update README if mentions old architecture
- Document new architecture in CLAUDE.md (if appropriate)
- Archive this validation plan

## Timeline

**Week 1 (Dec 26 - Jan 2):**
- Dry-run comparisons
- Fix any discrepancies
- Begin live validation

**Week 2 (Jan 2 - Jan 9):**
- Continue live validation
- Collect performance metrics
- Monitor merged PRs

**End of Week 2:**
- Review validation results
- Make decision: keep, extend validation, or rollback
- Delete monolith if validation passes

## Sign-Off

After validation complete, document decision:

```markdown
## Validation Results

**Date:** YYYY-MM-DD
**Decision:** [Delete monolith | Extend validation | Rollback]

**Metrics:**
- Total runs: X
- PRs processed: Y
- Merged: A
- Skipped: B
- False positives: 0
- False negatives: C
- Avg time: X min (Y% improvement)
- Avg cost: $Z (W% reduction)

**Conclusion:**
[Explanation of decision]

**Signed-off by:** [Name]
```
```

**Step 2: Verify validation plan**

```bash
wc -l docs/plans/2025-12-26-dependabot-refactor-validation.md
```

Expected: ~250 lines

**Step 3: Commit**

```bash
git add docs/plans/2025-12-26-dependabot-refactor-validation.md
git commit -m "docs(claude): add validation plan for refactored architecture

Comprehensive validation strategy for modular orchestrator:
- Functional parity checks (same decisions as monolith)
- Performance measurements (cost, speed)
- Two-week validation period (20+ successful runs)
- Rollback procedure if issues found
- Deletion procedure after validation passes

Target: 50%+ cost reduction, 30%+ speed improvement"
```

---

## Summary

This implementation creates a modular orchestrator-worker architecture following December 2025 best practices:

**Created:**
- 3 reusable skills (dependency-analysis, project-context-discovery, gh-cli/merge-pr)
- 3 specialized workers (pr-analyzer, test-runner, security-checker)
- 1 lightweight orchestrator (dependabot-orchestrator)
- Validation plan

**Modified:**
- Command invocation (orchestrator + haiku model)

**Deprecated:**
- Old monolithic agent (kept for rollback)

**Expected Benefits:**
- 3x cost reduction
- 2-3x speed improvement
- Modular, extensible components
- Reusable skills across workflows

**Next Steps:**
- Execute validation plan
- Monitor performance
- Delete monolith after 2 weeks / 20 successful runs
