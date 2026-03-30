# Claude

## First Principles

When writing planning, designing, writing, and testing code, always adhere to first-principles thinking.

- **Clarity Over Cleverness:** Code should be written for humans to read first, and for machines to execute second.
- **Strong Boundaries, Loose Coupling:** Clearly define interfaces and responsibilities; let components communicate minimally and intentionally.
- **Fail Fast, Fail Loud:** Detect errors early, surface them clearly, and avoid silently masking problems.
- **Automate the Repetitive, Measure the Critical:** Automate builds, tests, deployments, and monitoring; measure what truly reflects system health and business impact.
- **Design for Change:** Expect requirements, dependencies, and scale to evolve; build systems that can adapt without major rewrites.
- **Test at the Right Levels:** Unit tests for correctness, integration tests for contract confidence, and end-to-end tests for business outcomes—no more, no less.
- **Simplicity Wins:** Fewer moving parts means fewer bugs, easier onboarding, and faster recovery when things break.
- **Operational Excellence is a Feature:** Observability, alerting, and easy recovery are part of the design, not an afterthought.

## Programming Principles

When writing code, always adhere to these principles inspired by legendary programmers:

- Rich Hickey: Emphasize **simple, immutable data structures** and author code using **pure functions** (no side effects).
- John Carmack: **Implement features directly, avoiding unnecessary abstraction**. Always include clear strategies to **measure and reason about performance**.
- Joe Armstrong: **Isolate failures** through rigorous error handling. Ensure faults/crashes in one module do not propagate to others.
- Alan Kay: Favor a **message-passing, late-binding design** (prefer to communicate between loosely coupled components and defer binding decisions when possible).
- Donald Knuth: **Code must be readable and maintainable** above all else. Choose clarity before cleverness.
- Barbara Liskov: **Respect interface contracts**. Ensure that any implementation can be replaced by another without breaking expectations ("substitutability").
- John Ousterhout: **Fight complexity by designing deep modules with simple interfaces**. Pull complexity downward into implementations rather than exposing it to users. Strive for strategic design over tactical quick fixes.

Apply these principles in all code, explanations, and architectural recommendations.

## Learned Rules

- **Keep generic tools generic.** When building framework-agnostic tools,
  use placeholder examples (e.g., `[test framework]`, `[manifest file]`)
  instead of hardcoding specific technologies like Rails or Next.js. Concrete
  examples bias the tool toward those technologies and create maintenance
  burden when they need to be stripped out later.

## Confidence Disclosure

After any claim, share your confidence as **high**, **moderate**, or **low**
with a brief one-line reason. Match the tone and word choice of your response
to your confidence level — be assertive when confident, hedged when uncertain.

## General Guidelines

- **Minimal fixes by default.** When fixing bugs, make the smallest targeted
  change necessary. Do not refactor types, rename interfaces, or restructure
  surrounding code unless explicitly asked for a refactor.
- **Update tests, don't revert code.** When CI/tests fail after intentional code
  changes, update the test assertions to match the new behavior. Do not revert
  the code to match old tests. Ask if unsure whether a change was intentional.
- **Be efficient.** Batch operations where possible. Don't read files one by one
  when you can search or glob. Avoid excessive methodical approaches that slow
  down simple tasks.
- **Shell alias awareness:** `rm` is aliased to `rm -i`. Use `\rm` or
  `command rm` to avoid interactive prompts that block automation.
- **Check off PR test plans in-place.** When validating a PR's test plan,
  update the PR body (`gh pr edit`) to check off each item as it passes.
  Don't just report results in chat — the PR itself is the source of truth.

## Parallel Agent Work

After completing parallel agent work, always present a summary table:

| Agent | Task | Status | Issues |
| ----- | ---- | ------ | ------ |

Do not skip any agents. Include agents that failed or produced incomplete
results.

## Claude Code Integration

- Project-local slash commands go in `.claude/commands/`, NOT in plugin
  directories. Always verify the correct location before creating command files.

## Git Workflow

- **Never create merge commits.** Always keep git history linear. When
  integrating branches (including worktree branches), use `git rebase` or
  `git cherry-pick` to replay commits onto the target, then fast-forward.
  Never use `git merge --no-ff` or any merge that creates a merge commit.
- When a pre-push hook fails and the failing commit has not yet been pushed to
  the remote, squash the fix into the original commit (e.g.,
  `git commit --amend`) instead of creating a separate fix commit. This keeps
  history clean and avoids noise like "fix formatting" commits.

## Git Worktrees

When working in git worktrees:

- Husky hooks and `.env` files may not be available in worktrees
- The `wt` command handles env file copying from the repo root
- After worktree cleanup, check for and remove auto-created tracking branches
