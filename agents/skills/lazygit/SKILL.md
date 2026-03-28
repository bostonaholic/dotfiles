---
name: lazygit
description: 'This skill should be used when the user asks to "open lazygit", "use lg", "interactively stage changes", "do an interactive rebase", "resolve merge conflicts visually", "browse git log", or any task that benefits from the lazygit terminal UI. Also use when the user says "lg" (their alias for lazygit). Note: lazygit is an interactive TUI — AI agents cannot operate it directly. Use this skill to guide users on when and how to invoke it, and to handle any programmatic git operations via the git CLI instead.'
---

# lazygit Skill

## What lazygit Is

lazygit is an interactive terminal UI for git, installed at
`/opt/homebrew/bin/lazygit`. The user's alias `lg` maps to `lazygit`.

**Critical for AI agents:** lazygit is a full-screen interactive TUI. AI
agents cannot invoke it, read its output, or automate it. For any programmatic
git operation, use `git` CLI directly. This skill exists to:

1. Know when to suggest lazygit to the user instead of CLI commands
2. Provide the correct invocation flags to pass to the user
3. Handle surrounding non-interactive work (reading config, running git CLI)

---

## When to Suggest lazygit vs. git CLI

Suggest lazygit to the user for tasks where visual interaction wins:

| Task | Suggest lazygit | Use git CLI directly |
|------|-----------------|----------------------|
| Interactive rebase (reorder, fixup, squash) | Yes | No |
| Selectively stage hunks within a file | Yes | No |
| Resolve merge/rebase conflicts with diff view | Yes | No |
| Browse git log with filtering | Yes | No |
| Cherry-pick commits across branches | Yes | No |
| Stash management (create, pop, apply, drop) | Yes | No |
| Simple staging and commit of all changes | No | Yes |
| Scripted/automated git operations | No | Yes |
| Reading git state for AI reasoning | No | Yes |

---

## Invocation Reference

### Basic Usage

```bash
# Open in current repo
lazygit
lg  # user's alias

# Open focused on a specific panel
lazygit status    # Files panel
lazygit branch    # Branches panel
lazygit log       # Commits panel
lazygit stash     # Stash panel
```

### Key Flags

```bash
# Open lazygit for a repo at a specific path
lazygit -p /path/to/repo
# or equivalently:
lazygit --work-tree /path/to/repo --git-dir /path/to/repo/.git

# Filter git log to a specific file or directory
lazygit -f path/to/file
# This activates filter mode: commits, reflog, and stash are filtered
# to those touching the given path. Some operations are restricted in
# filter mode.

# Separate work-tree and git-dir (bare repos, worktrees)
lazygit -w /path/to/worktree -g /path/to/.git

# Use a custom config file
lazygit --use-config-file /path/to/config.yml

# Print default config (useful for building a custom config)
lazygit --config
lazygit -c

# Print the config directory
lazygit --print-config-dir
# → /Users/matthew/.config/lazygit

# Initial screen mode
lazygit --screen-mode full    # full-screen focused panel
lazygit --screen-mode half    # half-screen focused panel
lazygit --screen-mode normal  # default split view
```

---

## Configuration

Config directory: `/Users/matthew/.config/lazygit/`
Primary config file: `/Users/matthew/.config/lazygit/config.yml`

To generate the full default config as a starting point:

```bash
lazygit -c > ~/.config/lazygit/config.yml
```

Key config sections (from `lazygit -c`):

- `gui.sidePanelWidth` — fraction of screen for side panels (default `0.3333`)
- `gui.theme` — colors for active borders, selections, unstaged changes
- `gui.showFileTree` — tree vs. flat file listing in staging view
- `gui.nerdFontsVersion` — set to `"3"` if using Nerd Fonts for icons
- `git.paging.colorArg` — `always` to force color in diff pager
- `keybinding` — rebind any key in any context

To inspect current effective config or find a specific setting:

```bash
lazygit -c | grep -A5 "keybinding"
```

---

## Panel Navigation (for instructing the user)

Inside lazygit, default keybindings for panel navigation:

| Key | Action |
|-----|--------|
| `[` / `]` | Previous / next panel |
| `1`–`5` | Jump to panel by number |
| `p` | Pull |
| `P` | Push |
| `z` | Undo last git action |
| `e` | Edit file in `$EDITOR` |
| `space` | Stage / unstage |
| `v` | Toggle staging mode (line/hunk) |
| `enter` | Drill into selected item |
| `q` | Quit |
| `?` | Show keybinding help for current panel |

---

## Common Scenarios

### Interactive Rebase

Tell the user:

```bash
lg log   # or: lazygit log
# Navigate to the target commit, press 'e' to start interactive rebase
# Use 'd' to drop, 's' to squash, 'r' to reword inline
```

### Selective Hunk Staging

Tell the user:

```bash
lg status   # or: lazygit status
# Select a file, press enter to open staging view
# Use arrow keys to select hunks, space to stage
# Press 'v' to toggle line-level staging
```

### Resolving Merge Conflicts

Tell the user:

```bash
lg   # conflicts appear in the Files panel
# Select the conflicted file, press enter
# Use arrow keys to pick ours/theirs for each conflict
# Press space to stage after resolving
```

### Filter Log to a File

```bash
lazygit -f path/to/interesting/file
```

### Open Repo from Anywhere

```bash
lazygit -p ~/projects/myrepo
```

---

## What AI Agents Do Instead

For any operation an agent needs to perform programmatically:

```bash
# Stage files
git add -p                    # interactive (still requires user input)
git add path/to/file

# Commit
git commit -m "message"

# Rebase (non-interactive scripted form)
git rebase --onto main feature~3 feature

# Cherry-pick
git cherry-pick <sha>

# Stash
git stash push -m "description"
git stash pop

# Read log
git log --oneline --graph --decorate -20

# Check status
git status --short
```

Never attempt to invoke `lazygit` as part of an automated sequence — it will
block waiting for terminal input and cannot be driven programmatically.
