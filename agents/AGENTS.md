# Global Agent Instructions

Personal instructions shared across coding agents (Codex, Antigravity,
OpenCode, Pi). Symlinked from `dotfiles/agents/AGENTS.md` to each tool's
global location via `dotfiles.yaml`.

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

## Karpathy Behavioral Guidelines

Behavioral guidelines to reduce common LLM coding mistakes. These bias toward
caution over speed — for trivial tasks, use judgment.

### 1. Think before coding

Don't assume. Don't hide confusion. Surface tradeoffs.

- State assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity first

Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.
- Ask: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical changes

Touch only what you must. Clean up only your own mess.

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.
- Test: Every changed line should trace directly to the user's request.

### 4. Goal-driven execution

Define success criteria. Loop until verified.

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"
- For multi-step tasks, state a brief plan with a verify step per item.
- Strong success criteria let you loop independently; weak criteria require
  constant clarification.

## Learned Rules

- **Keep generic tools generic.** When building framework-agnostic tools,
  use placeholder examples (e.g., `[test framework]`, `[manifest file]`)
  instead of hardcoding specific technologies like Rails or Next.js. Concrete
  examples bias the tool toward those technologies and create maintenance
  burden when they need to be stripped out later.

## Communication Style

When reporting information to me, be extremely concise and sacrifice grammar
for the sake of concision.

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

## Git Workflow

### Signed Commits (No Exceptions)

**Never create an unsigned commit.** Every commit must carry a valid
signature. There is no "just this once" — this rule has no exceptions.

- Before committing, confirm signing is enabled: `git config --get
  commit.gpgsign` must return `true`. If it does not, fix the config instead
  of committing unsigned.
- Never pass `--no-gpg-sign`, and never set `commit.gpgsign=false` (globally,
  per-repo, or inline with `-c`) to force a commit through.
- After committing, verify: `git log -1 --show-signature` must report a good
  signature. A missing or bad signature means the commit failed — amend and
  re-sign it (`git commit --amend --no-edit -S`) before doing anything else.
- Annotated tags follow the same rule (`tag.gpgsign = true`).
- **If a commit cannot be signed, STOP.** Do not commit unsigned, do not work
  around it, do not defer it to later. Report to the user:
  1. The exact command that failed, with its verbatim error output.
  2. The diagnosed cause — what specifically is broken.
  3. Recommended resolution steps, most likely fix first.

  Then wait for the user to decide how to proceed.

Signing setup on this machine: SSH-format signatures (`gpg.format = ssh`)
produced by the 1Password signing agent (`gpg.ssh.program` → `op-ssh-sign`),
key in `user.signingkey`, verified against `~/.config/git/allowed_signers`.

Diagnosing signing failures — match the error, then recommend the fix:

| Symptom | Likely cause | Recommended resolution |
| ------- | ------------ | ---------------------- |
| `error: cannot run .../op-ssh-sign: No such file or directory` | 1Password missing, or its signing binary moved | Install/reinstall 1Password, or point `gpg.ssh.program` at the current `op-ssh-sign` path |
| Signing prompt hangs, times out, or is denied | 1Password locked, or the signing request was not approved | Unlock 1Password, approve the signing prompt, retry the commit |
| `error: Load key ...: invalid format` / `no signing key available` | `user.signingkey` unset, or does not match `gpg.format` | Set `user.signingkey` to the SSH public key (or key path) matching the configured format |
| `gpg failed to sign the data` under `gpg.format = openpgp` | `gpg-agent` not running, no TTY, or expired/revoked key | Start `gpg-agent`, `export GPG_TTY=$(tty)`, or renew the expired key |
| Commit is signed locally but GitHub shows "Unverified" | Public key not registered on GitHub as a *signing* key | Add the key under GitHub → SSH and GPG keys as a **Signing** key (separate from Authentication) |
| Commits unsigned inside a worktree, container, or CI | Signing config or agent unavailable in that environment | Report the gap and ask the user — never fall back to unsigned commits |

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
