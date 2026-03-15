---
name: worktrees
description: This skill should be used when the user asks to "clone a repo", "set up worktrees", "create a worktree", "switch worktrees", "add a worktree", "remove a worktree", or mentions the .worktrees/ directory, the wt command, or git worktree workflows. Provides the worktree workflow using the wt CLI.
---

# Git Worktree Workflow

Manage git worktrees using normal clones with a `.worktrees/` subdirectory
that contains all additional worktrees.

## When to Use

Use this workflow for any project that needs parallel branch work. Clone
repos normally with `git clone`, then use the `wt` CLI to create and manage
worktrees.

## Layout

A project with worktrees looks like this:

```text
~/code/my-project/
  .git/              # normal Git directory
  .worktrees/        # container for additional worktrees (gitignored)
    feature-x/       # worktree for feature-x branch
    bugfix-y/        # worktree for bugfix-y branch
  src/               # main branch working tree files
  package.json       # ...
```

Key properties:

- `.git/` is a normal git directory (standard clone)
- The main branch lives at the repo root (no separate `main/` directory)
- `.worktrees/` holds all additional worktrees as subdirectories
- `.worktrees/` is in the global gitignore -- no per-repo config needed
- Claude Code worktrees live separately in `.claude/worktrees/` and do not
  interfere with `wt` worktrees

## Cloning a New Project

Use normal `git clone`:

```bash
git clone https://github.com/owner/repo.git
cd repo
```

No special setup script is needed. The `.worktrees/` directory is created
automatically on first `wt new` or `wt add`.

## The wt CLI

`wt` is the primary tool for managing worktrees. A zsh wrapper intercepts
`main`, `new`, `add`, and `cd` subcommands to auto-cd into the resulting
directory.

### Commands

| Command | Effect |
|---------|--------|
| `wt` or `wt ls` | List all worktrees |
| `wt main` | cd to repo root (main branch) |
| `wt new <name> [<start-point>]` | Create worktree for a new branch (default: origin/main) |
| `wt add <name>` | Create worktree for an existing branch |
| `wt rm <name> [--keep-branch]` | Remove worktree + delete local branch |
| `wt cd <name>` | cd into an existing worktree |
| `wt path <name>` | Print path without cd |
| `wt prune` | Clean up stale worktree references |
| `wt help` | Show help |

### Common Patterns

**Start work on a new feature:**

```bash
wt new my-feature          # creates branch from origin/main, cd's in
```

**Check out an existing remote branch:**

```bash
wt add fix-bug             # detects origin/fix-bug, checks it out
```

**Branch from a specific point:**

```bash
wt new experiment v2.0.0   # creates branch from tag v2.0.0
```

**Return to main after feature work:**

```bash
wt main                    # cd's to repo root
```

**Clean up after merging:**

```bash
wt rm my-feature           # removes worktree + deletes local branch
```

**Keep the branch but remove the worktree:**

```bash
wt rm my-feature --keep-branch
```

## Environment Files

When creating a new worktree, `wt` automatically copies `.env`, `.env.keys`,
and `.env.local` from the repo root into the new worktree directory. This
ensures worktrees have the same environment configuration without manual
copying.

## Coexistence with Claude Code Worktrees

Claude Code has its own worktree system that uses `.claude/worktrees/` as the
container directory. These two systems are independent:

| Aspect | `wt` worktrees | Claude Code worktrees |
|--------|---------------|----------------------|
| Location | `.worktrees/<branch>` | `.claude/worktrees/<name>` |
| Management | `wt` CLI | Claude Code internally |
| Listing | `wt ls` shows only `.worktrees/` entries | Not shown in `wt ls` |
| Purpose | Developer-managed parallel branches | AI agent isolation |

The `wt ls` command filters to only show worktrees inside `.worktrees/`,
so Claude Code worktrees never appear in the listing. Both systems can
coexist in the same repository without conflicts.

## Safety

- `wt rm` blocks removal of the main branch
- Worktree names are validated against path traversal (`..`, leading `/`)
- `wt rm` deletes the local branch by default; use `--keep-branch` to
  preserve it
- `wt rm --force` is required to remove worktrees with uncommitted changes

