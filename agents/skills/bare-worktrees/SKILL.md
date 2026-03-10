---
name: bare-worktrees
description: >-
  This skill should be used when the user asks to "clone a repo", "set up
  worktrees", "create a worktree", "switch worktrees", "add a worktree",
  "remove a worktree", or mentions bare-clone layouts, the wt command, or
  git clone-bare-for-worktrees. Provides the bare-clone worktree workflow
  using the wt CLI and git cb alias.
---

# Bare-Clone Worktree Workflow

Manage git worktrees using a bare-clone layout where all worktrees are
sibling directories of `.bare/`.

## When to Use

Use this workflow for **all new clones** and any project that needs parallel
branch work. This replaces the older `.worktrees/` subdirectory pattern.

Skip for repos that already use the `.worktrees/` pattern — those continue
to work but are not the preferred layout for new projects.

## Layout

A bare-clone project looks like this:

```text
~/code/my-project/
  .bare/          # bare Git repository (all objects, refs, config)
  .git            # pointer file containing: gitdir: ./.bare
  main/           # persistent worktree for the trunk branch
  feature-x/      # temporary worktree (created via wt add)
  bugfix-y/       # another temporary worktree
```

Key properties:

- `.bare/` holds the actual git data (no working copy)
- `.git` is a **file** (not a directory) pointing to `.bare`
- Each worktree is a **sibling directory** at the project root
- The `main/` worktree is persistent and protected from deletion

## Cloning a New Project

Use `git cb` (alias for `clone-bare-for-worktrees`):

```bash
git cb https://github.com/owner/repo.git
# Creates: repo/.bare, repo/.git, repo/main/
cd repo/main
```

With a custom directory name:

```bash
git cb https://github.com/owner/repo.git my-project
cd my-project/main
```

The clone script validates the project name, sets up fetch refspecs for
bare repos, fetches all remote branches, and creates the initial `main/`
worktree.

## The wt CLI

`wt` is the primary tool for managing worktrees in bare-clone layouts.
A zsh wrapper intercepts `main`, `add`, and `cd` subcommands to auto-cd
into the resulting worktree directory.

### Commands

| Command | Effect |
|---------|--------|
| `wt` or `wt ls` | List all worktrees |
| `wt main` | cd into `main/` (creates if missing) |
| `wt new <name> [<start-point>]` | Create worktree for a new branch (fails if branch exists) |
| `wt add <name>` | Create worktree for an existing branch (fails if branch doesn't exist) |
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
wt main
```

**Clean up after merging:**

```bash
wt rm my-feature           # removes worktree + deletes local branch
```

**Keep the branch but remove the worktree:**

```bash
wt rm my-feature --keep-branch
```

## Detecting the Layout

`wt` detects bare-clone layouts by walking up from the current directory
looking for a `.bare/` directory alongside a `.git` pointer file. If not
found, it exits with an error directing the user to `git cb`.

When writing scripts or tools that interact with bare-clone repos:

```bash
# Check if inside a bare-clone layout
if [ -d ".bare" ] && [ -f ".git" ]; then
    # bare-clone root
elif [ -f ".git" ]; then
    # possibly inside a worktree — walk up to find .bare
fi
```

## Differences from .worktrees/ Pattern

| Aspect | `.worktrees/` (old) | Bare-clone (current) |
|--------|---------------------|----------------------|
| Repo type | Normal clone | Bare clone in `.bare/` |
| Worktree location | `.worktrees/<branch>` | `<root>/<branch>` |
| Needs .gitignore | Yes (`.worktrees/` entry) | No (worktrees are outside tracked tree) |
| Main branch | In repo root | In `main/` sibling directory |
| Clone command | `git clone` | `git cb` |
| Management tool | `wt` (old version) | `wt` (current version) |

## Safety

- `wt rm main` is blocked — the main worktree is persistent
- Worktree names are validated against path traversal (`..`, leading `/`)
- `git cb` validates project names (alphanumeric, dots, hyphens, underscores)
- `wt rm` deletes the local branch by default; use `--keep-branch` to preserve it

## Integration with Other Skills

When the superpowers or rpikit worktree skills offer to create a
`.worktrees/` directory, **prefer the bare-clone layout instead** if the
project was cloned with `git cb`. Check for `.bare/` at the project root
to determine which layout is in use.

For projects already using `.worktrees/`, continue with that pattern.
Do not mix layouts within a single project.
