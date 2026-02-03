# Dependabot Merger Refactoring Plan

**Date:** 2025-12-26
**Purpose:** Refactor 741-line monolithic agent into modular, single-responsibility components
**Based on:** December 2025 Claude Code best practices research

## Research Summary

### Key Findings from Best Practices Research

**Architecture Patterns:**

- [Anthropic's multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) uses **orchestrator-worker pattern** with lead agent coordinating specialized subagents operating in parallel
- [Orchestrator's Dilemma](https://responseawareness.substack.com/p/claude-code-subagents-the-orchestrators): Keep main agent in **pure orchestration mode** to avoid implementation noise accumulating in context
- Multi-agent with Opus lead + Sonnet subagents [outperformed single-agent Opus by 90.2%](https://www.anthropic.com/engineering/multi-agent-research-system)

**Component Types & Hierarchy:**

- [Skills](https://claude.com/blog/skills-explained): Model-invoked, reusable, persistent across conversations, portable expertise
- [Commands](https://danielmiessler.com/blog/when-to-use-skills-vs-commands-vs-agents): User-invoked (slash commands), should move to ~/.claude/skills/{domain}/workflows/
- [Agents](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk): Can invoke skills and commands, specialized with own context windows
- [Subagents cannot spawn other subagents](https://dev.to/bredmond1019/multi-agent-orchestration-running-10-claude-instances-in-parallel-part-3-29da) (architectural limitation)

**Single Responsibility Principle:**

- [Each component should have one clear purpose](https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/)
- [Modular composition with clear boundaries](https://jannesklaas.github.io/ai/2025/07/20/claude-code-agent-design.html)
- [Skills enable progressive disclosure](https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/): load information in stages as needed

**Model Selection Strategy (Late 2025):**

- [Haiku 4.5 delivers 90% of Sonnet performance at 2x speed, 3x cost savings](https://skywork.ai/blog/claude-code-2-0-checkpoints-subagents-autonomous-coding/)
- Emerging pattern: [start with Haiku 4.5, escalate to Sonnet if validation fails](https://www.anthropic.com/engineering/claude-code-best-practices)
- Use Opus only for deep analysis requiring maximum capability

**Skills as Reusable Components:**

- [Package domain expertise into discoverable capabilities](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
- [Skills can be composed together by Claude](https://claude.com/blog/skills-explained)
- [Model field defaults to inheriting from session](https://github.com/anthropics/skills)
- [Now cross-platform: GitHub Copilot supports Agent Skills](https://github.blog/changelog/2025-12-18-github-copilot-now-supports-agent-skills/) (Dec 18, 2025)

**Security & Performance:**

- [Permission sprawl is fastest path to unsafe autonomy](https://www.anthropic.com/engineering/claude-code-best-practices): start deny-all, allowlist only what's needed
- [Skills have 2-3x latency penalty](https://www.youngleaders.tech/p/claude-skills-commands-subagents-plugins) (3-5 sec vs 1-2 sec) but justified for autonomous decision-making

## Current Architecture Problems

### Monolithic Agent (741 lines)

**File:** `claude/agents/dependabot-merger.md`

**Responsibilities (violates SRP):**

1. Argument parsing and initialization
2. PR discovery via GitHub API
3. Semantic versioning analysis
4. Breaking change detection (4 layers)
5. Dependency tree analysis
6. Test execution in worktrees
7. Security advisory checking
8. Merge decision logic
9. Git merge execution
10. Progress tracking and reporting
11. Error handling for all phases

**Problems:**

- Single massive context window (741 lines all loaded at once)
- Cannot parallelize PR analysis (sequential only)
- Mixing orchestration with implementation
- No reusable components (expertise locked in agent)
- Expensive: Uses Opus for entire workflow (including simple tasks)
- Difficult to test individual phases
- Changes to one phase require reloading entire agent
- Cannot compose with other workflows

## Proposed Modular Architecture

### Overview

Transform monolithic agent into **orchestrator-worker pattern** with:

- **1 orchestrator agent** (lightweight, Haiku 4.5)
- **3 specialized worker agents** (focused responsibilities, Sonnet 4.5)
- **3 reusable skills** (portable expertise, model-inheriting)
- **1 user-facing command** (entry point, unchanged interface)

### Architecture Diagram

```text
User invokes: /safely-merge-dependabots [args]
                        ↓
┌─────────────────────────────────────────────────────┐
│  Command: safely-merge-dependabots                  │
│  (claude/commands/safely-merge-dependabots.md)     │
│  - Parse arguments (PR numbers, --dry-run, etc.)   │
│  - Invoke orchestrator agent with context          │
└────────────────────┬────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────┐
│  Orchestrator Agent: dependabot-orchestrator        │
│  Model: Haiku 4.5 (cheap, fast coordination)       │
│  Responsibilities:                                   │
│  - Discover open Dependabot PRs (gh CLI)           │
│  - For each PR: dispatch worker subagents          │
│  - Collect results from workers                     │
│  - Make final merge decisions                       │
│  - Generate summary report                          │
│  Skills used: gh-cli                                │
└────────────────────┬────────────────────────────────┘
                     ↓
        ┌────────────┴────────────┬──────────────────┐
        ↓                         ↓                  ↓
┌─────────────────┐    ┌────────────────────┐    ┌──────────────────┐
│  Worker Agent:  │    │  Worker Agent:     │    │  Worker Agent:   │
│  pr-analyzer    │    │  test-runner       │    │  security-checker│
│                 │    │                    │    │                  │
│  Model: Sonnet  │    │  Model: Sonnet     │    │  Model: Haiku    │
│                 │    │                    │    │                  │
│  Analyze single │    │  Execute tests in  │    │  Check security  │
│  PR for safety: │    │  isolated worktree │    │  advisories      │
│  - Semver       │    │  - Discovery       │    │  via GitHub API  │
│  - Breaking     │    │  - Isolation       │    │                  │
│    changes      │    │  - Execution       │    │  Returns: CVE    │
│  - Dependencies │    │  - Diagnosis       │    │  info, severity  │
│                 │    │                    │    │                  │
│  Skills used:   │    │  Skills used:      │    │  Skills used:    │
│  - dependency-  │    │  - project-context-│    │  - gh-cli        │
│    analysis     │    │    discovery       │    │                  │
│  - gh-cli       │    │  - systematic-     │    │                  │
│                 │    │    debugging       │    │                  │
│  Returns:       │    │                    │    │                  │
│  Safety report  │    │  Returns: Pass/Fail│    │                  │
│  + risk level   │    │  + diagnostics     │    │                  │
└─────────────────┘    └────────────────────┘    └──────────────────┘
        ↓                         ↓                         ↓
        └─────────────────────────┴─────────────────────────┘
                                  ↓
                    Results flow back to orchestrator
```

### Component Breakdown

#### 1. Command (Entry Point)

**File:** `claude/commands/safely-merge-dependabots.md` (KEEP - minimal changes)

**Responsibilities:**

- Parse user arguments (PR numbers, --dry-run, --timeout)
- Validate inputs
- Invoke orchestrator agent with structured context
- Return immediately (orchestrator handles everything)

**Changes from current:**

- Change agent invocation from `dependabot-merger` → `dependabot-orchestrator`
- Add model hint: `model: haiku` (orchestration is cheap)

#### 2. Orchestrator Agent (NEW)

**File:** `claude/agents/dependabot-orchestrator.md`
**Model:** `haiku` (default, can override)
**Lines:** ~150 (lightweight!)

**Responsibilities:**

- Discover open Dependabot PRs (direct gh CLI usage)
- Loop through PRs sequentially
- For each PR:
  - Dispatch `pr-analyzer` subagent → get safety report
  - If safe: dispatch `test-runner` subagent → get test results
  - If security fix: dispatch `security-checker` subagent → verify
  - Make merge decision based on worker results
  - Execute merge if safe (direct gh CLI)
- Generate final summary report
- Handle dry-run mode

**Skills Used:**

- `gh-cli` (for PR operations)

**Key Design:**

- Pure orchestration (no implementation details)
- Minimal context (only coordination logic)
- Workers return structured data
- Decision logic stays in orchestrator
- No detailed analysis (delegates to workers)

**Example Flow:**

```markdown
For each PR:
  1. Dispatch pr-analyzer with PR number
  2. Receive: {safe: true/false, risk: "low/medium/high", reasons: [...]}
  3. If safe:
     - Dispatch test-runner with PR number
     - Receive: {passed: true/false, details: "..."}
  4. If tests pass:
     - Execute merge (gh pr merge)
     - Record success
  5. Else:
     - Record skip with reason
```

#### 3. Worker Agent: PR Analyzer (NEW)

**File:** `claude/agents/pr-analyzer.md`
**Model:** `sonnet` (default)
**Lines:** ~200

**Single Responsibility:** Analyze one PR for safety concerns

**Input:** PR number
**Output:** Structured safety report

**Phases:**

1. **Semver Classification** (MAJOR/MINOR/PATCH)
2. **Breaking Change Detection** (uses `dependency-analysis` skill)
3. **Dependency Tree Analysis** (check for conflicts)

**Skills Used:**

- `dependency-analysis` (breaking change detection patterns)
- `gh-cli` (fetch PR details, changelogs)

**Returns:**

```json
{
  "safe": true/false,
  "risk": "low|medium|high",
  "semver": "MAJOR|MINOR|PATCH",
  "breaking_changes": ["list of concerns"],
  "dependency_conflicts": ["list of conflicts"],
  "recommendation": "merge|skip|manual-review",
  "reasoning": "explanation"
}
```

**Key Design:**

- No test execution (delegates to test-runner)
- No merge decisions (returns recommendation)
- Focused context window (only analysis logic)
- Reusable for other workflows

#### 4. Worker Agent: Test Runner (NEW)

**File:** `claude/agents/test-runner.md`
**Model:** `sonnet` (default)
**Lines:** ~180

**Single Responsibility:** Execute tests in isolated environment

**Input:** PR number, timeout (optional)
**Output:** Test results + diagnostics

**Phases:**

1. **Project Context Discovery** (uses `project-context-discovery` skill)
2. **Worktree Isolation**
   - Fetch PR ref: `git fetch origin pull/$PR/head:pr-$PR`
   - Create worktree
3. **Dependency Installation** (based on discovered context)
4. **Test Execution** (with timeout)
5. **Failure Diagnosis** (uses `systematic-debugging` skill if failures)
6. **Cleanup** (remove worktree)

**Skills Used:**

- `project-context-discovery` (detect test framework, commands)
- `systematic-debugging` (diagnose test failures)

**Returns:**

```json
{
  "passed": true/false,
  "tests_run": 847,
  "failures": 0,
  "duration": "2m 14s",
  "diagnostics": "detailed failure analysis if failed",
  "timeout": false
}
```

**Key Design:**

- No analysis of what changed (that's pr-analyzer's job)
- No merge decisions (just reports results)
- Reusable for any branch/PR testing
- Handles cleanup even on failure

#### 5. Worker Agent: Security Checker (NEW)

**File:** `claude/agents/security-checker.md`
**Model:** `haiku` (simple API calls)
**Lines:** ~80

**Single Responsibility:** Verify security advisories

**Input:** PR number
**Output:** Security info

**Phases:**

1. Check if PR addresses security vulnerability
2. Fetch CVE details if applicable
3. Verify fix is included in PR changes

**Skills Used:**

- `gh-cli` (GitHub security API)

**Returns:**

```json
{
  "is_security_fix": true/false,
  "cves": ["CVE-2023-XXXX"],
  "severity": "critical|high|medium|low",
  "fix_verified": true/false
}
```

**Key Design:**

- Cheapest worker (Haiku sufficient)
- Optional (only called for security fixes)
- Focused on verification, not analysis

#### 6. Skill: Dependency Analysis (NEW)

**File:** `claude/skills/dependency-analysis/SKILL.md`
**Type:** Reusable skill (model-invoked)

**Purpose:** Breaking change detection patterns and analysis techniques

**Contains:**

- Changelog parsing patterns (markdown structure)
- Breaking change keywords (4-layer strategy)
- API surface analysis techniques
- Community signal indicators
- Risk scoring rubric

**Supporting Files:**

- `patterns/breaking-change-keywords.txt` (high/medium/low severity)
- `patterns/changelog-sections.txt` (section names to check)
- `templates/safety-report.md` (output template)

**Used By:**

- `pr-analyzer` agent (for breaking change detection)
- Potentially other agents analyzing dependencies

**Key Design:**

- Portable expertise (works in any agent)
- No agent-specific logic (pure patterns/guidance)
- Progressive disclosure (only loads files needed)

#### 7. Skill: Project Context Discovery (NEW)

**File:** `claude/skills/project-context-discovery/SKILL.md`
**Type:** Reusable skill (model-invoked)

**Purpose:** Discover project structure, test frameworks, package managers

**Contains:**

- Detection strategies for package managers
- Test framework identification patterns
- CI config parsing guidance
- Script discovery (bin/, scripts/, package.json scripts)

**Supporting Files:**

- `patterns/package-managers.yaml` (detection rules)
- `patterns/test-frameworks.yaml` (framework indicators)
- `patterns/ci-configs.yaml` (where to look for CI config)

**Used By:**

- `test-runner` agent (to discover how to run tests)
- Potentially other agents needing project understanding

**Key Design:**

- Generalizable (no hardcoded project types)
- Discovery over assumptions
- Graceful degradation (fallbacks if can't detect)

#### 8. Skill: GitHub CLI Operations (EXTEND EXISTING)

**File:** `claude/skills/gh-cli/workflows/merge-pr.md` (NEW)

**Purpose:** Add workflow for safe PR merging

**Contains:**

- Merge strategies (squash vs merge vs rebase)
- Repository config detection
- Auto-merge setup
- Verification after merge

**Changes:**

- Extend existing `gh-cli` skill with new workflow
- Keep all existing gh-cli functionality
- Add merge-specific patterns

## Migration Strategy

### Phase 1: Create Skills (Parallel, No Breaking Changes)

Create three new skills without touching existing agent:

1. **Skill: dependency-analysis**
   - Create directory structure
   - Write SKILL.md with breaking change detection patterns
   - Add supporting pattern files
   - Test: Can be loaded by test agent

2. **Skill: project-context-discovery**
   - Create directory structure
   - Write SKILL.md with project discovery strategies
   - Add supporting pattern files
   - Test: Can be loaded by test agent

3. **Skill: gh-cli/workflows/merge-pr.md**
   - Add workflow to existing gh-cli skill
   - Document merge strategies
   - Test: Existing gh-cli still works

**Deliverables:**

- `claude/skills/dependency-analysis/` (complete)
- `claude/skills/project-context-discovery/` (complete)
- `claude/skills/gh-cli/workflows/merge-pr.md` (added)

### Phase 2: Create Worker Agents (Parallel, No Breaking Changes)

Create three specialized worker agents:

1. **Agent: pr-analyzer**
   - Write agent file using `dependency-analysis` skill
   - Test: Can analyze a single PR and return safety report
   - Verify: Uses Sonnet model effectively

2. **Agent: test-runner**
   - Write agent file using `project-context-discovery` skill
   - Test: Can run tests in worktree for a PR
   - Verify: Cleanup works on both success and failure

3. **Agent: security-checker**
   - Write agent file using `gh-cli` skill
   - Test: Can fetch and verify security advisories
   - Verify: Haiku model sufficient for this task

**Deliverables:**

- `claude/agents/pr-analyzer.md` (complete)
- `claude/agents/test-runner.md` (complete)
- `claude/agents/security-checker.md` (complete)

### Phase 3: Create Orchestrator Agent (Sequential)

Create lightweight orchestrator that uses worker agents:

1. **Agent: dependabot-orchestrator**
   - Write orchestration logic (discover PRs, dispatch workers)
   - Use Haiku 4.5 model
   - Implement decision logic based on worker results
   - Implement final reporting
   - Test: Can coordinate workers and produce same results as monolith

**Deliverables:**

- `claude/agents/dependabot-orchestrator.md` (complete)

### Phase 4: Update Command (Breaking Change - Careful!)

Update command to invoke new orchestrator:

1. **Command: safely-merge-dependabots**
   - Change agent from `dependabot-merger` → `dependabot-orchestrator`
   - Add model hint: `haiku`
   - Keep all argument parsing unchanged
   - Update expected output section (same format, note improved performance)

**Deliverables:**

- `claude/commands/safely-merge-dependabots.md` (updated)

### Phase 5: Deprecate Old Agent (After Validation)

Only after new architecture is proven:

1. Rename old agent: `dependabot-merger.md` → `dependabot-merger.deprecated.md`
2. Add deprecation notice at top
3. Keep file for reference/rollback
4. Eventually delete after confidence period

**Deliverables:**

- `claude/agents/dependabot-merger.deprecated.md` (archived)

## Expected Improvements

### Performance

**Before (Monolithic):**

- Model: Opus for everything
- PRs: Sequential processing only
- Cost: ~$X per PR (high token count)
- Speed: Slow (large context, expensive model)

**After (Modular):**

- Orchestrator: Haiku 4.5 (3x cheaper, 2x faster)
- Workers: Sonnet 4.5 (adequate for analysis)
- Security checker: Haiku (simple API calls)
- PRs: Can parallelize in future (workers independent)
- Cost: ~$X/3 per PR (estimated)
- Speed: 2-3x faster (lighter orchestrator, faster models)

### Maintainability

**Before:**

- 741 lines in one file
- All phases tightly coupled
- Change one phase → reload entire agent
- No reusable components
- Difficult to test individual phases

**After:**

- Orchestrator: ~150 lines (coordination only)
- Workers: ~200 lines each (focused responsibilities)
- Skills: Reusable across agents and projects
- Test individual components
- Change worker → orchestrator unaffected
- Skills portable to other workflows

### Extensibility Improvements

**Before:**

- Add new analysis phase → edit monolith
- Support new project type → edit monolith
- Can't compose with other workflows

**After:**

- Add new analysis → create new worker agent
- Support new project type → update `project-context-discovery` skill
- Workers reusable in other workflows:
  - `test-runner` → use for any branch testing
  - `pr-analyzer` → use for manual PR reviews
  - Skills → portable to other agents/platforms

### Security

**Before:**

- All phases have full permissions
- No isolation between phases
- Permission sprawl risk

**After:**

- Each worker has minimal permissions
- Orchestrator controls access
- Workers can't interfere with each other
- Clear permission boundaries

## Success Metrics

### Functional Parity

- [ ] Discovers same PRs as monolith
- [ ] Makes same merge decisions (safe vs risky)
- [ ] Handles same error cases
- [ ] Produces equivalent final report
- [ ] Respects --dry-run, --timeout, PR selection

### Performance Improvements

- [ ] Reduce cost per PR by >50% (Haiku orchestrator)
- [ ] Reduce latency by >30% (lighter models)
- [ ] Enable parallel PR analysis (architecture supports it)

### Code Quality

- [ ] Each component <250 lines
- [ ] Each component single responsibility
- [ ] All skills reusable outside this workflow
- [ ] Clear interfaces between components
- [ ] Comprehensive error handling per component

### Extensibility Goals

- [ ] New analysis type requires only new worker agent
- [ ] Workers usable in other workflows
- [ ] Skills portable to other platforms (GitHub Copilot, etc.)

## Risk Mitigation

### Rollback Plan

Keep old monolithic agent as `.deprecated` until validation complete:

- If issues found: revert command to old agent
- Validation period: 2 weeks or 20 successful runs
- Then: safe to delete old agent

### Testing Strategy

**Unit Testing (Per Component):**

- Each worker agent: test with mock inputs
- Each skill: test pattern matching
- Orchestrator: test with mock worker responses

**Integration Testing:**

- Full workflow on test PRs
- Compare results to monolith
- Verify all error paths
- Test dry-run mode

**Validation:**

- Run both architectures on same PRs
- Compare decisions, timing, costs
- User acceptance: same experience or better

## Timeline Estimate

**Phase 1 (Skills):** 2-3 hours (parallel development)
**Phase 2 (Workers):** 4-5 hours (parallel development)
**Phase 3 (Orchestrator):** 2-3 hours (sequential)
**Phase 4 (Command Update):** 30 minutes
**Phase 5 (Deprecation):** After validation period

**Total Active Development:** 8-11 hours
**Total with Validation:** 2-3 weeks

## Next Steps

1. Review this plan with stakeholders
2. Decide: Implement all phases or POC first?
3. If POC: Start with Phase 1 + 2 (skills + one worker agent)
4. If full implementation: Create implementation plan from this design

---

**References:**

- [Anthropic's Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system)
- [Building Agents with Claude Agent SDK](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk)
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Skills Explained](https://claude.com/blog/skills-explained)
- [Agent Skills Deep Dive](https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/)
- [When to Use Skills vs Commands vs Agents](https://danielmiessler.com/blog/when-to-use-skills-vs-commands-vs-agents)
- [Orchestrator Pattern](https://responseawareness.substack.com/p/claude-code-subagents-the-orchestrators)
- [Multi-Agent Orchestration](https://dev.to/bredmond1019/multi-agent-orchestration-running-10-claude-instances-in-parallel-part-3-29da)
