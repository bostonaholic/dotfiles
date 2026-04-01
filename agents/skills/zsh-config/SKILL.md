---
name: zsh-config
description: Knows which zsh dotfile to place shell configuration changes into. Use when adding environment variables, aliases, PATH entries, shell options, completions, or any other zsh configuration to the user's dotfiles.
metadata:
  filePattern:
    - "zsh/*"
    - "**/zshrc"
    - "**/zprofile"
    - "**/zshenv"
    - "**/zlogin"
    - "**/zlogout"
    - "**/*.plugin.zsh"
    - "**/*.zsh-theme"
  bashPattern:
    - "source.*zsh"
    - "export\\s+(PATH|EDITOR|PAGER|SHELL)"
    - "alias\\s+"
    - "setopt|unsetopt"
---

# Zsh Configuration File Placement

This project's zsh files live in `zsh/` and are symlinked to `$HOME` via
`dotfiles.yaml`. Always edit the repo source files, never the symlink targets.

## File Map

| Repo file | Symlinked to | Sourced when |
|-----------|-------------|-------------|
| `zsh/zprofile` | `~/.zprofile` | Login shells (once, at login) |
| `zsh/zshrc` | `~/.zshrc` | Interactive shells (every new terminal) |
| `zsh/bostonaholic.plugin.zsh` | `~/.oh-my-zsh/custom/plugins/bostonaholic/bostonaholic.plugin.zsh` | Interactive shells (loaded by oh-my-zsh via `plugins=()` in zshrc) |

Note: This project does not currently have `.zshenv`, `.zlogin`, or `.zlogout`
files. Create them only if a change genuinely requires that execution context.

## Source Order

Zsh sources files in this order:

1. **`.zshenv`** -- Every shell (login, interactive, script, non-interactive). Always first.
2. **`.zprofile`** -- Login shells only, before `.zshrc`.
3. **`.zshrc`** -- Interactive shells only, after `.zprofile`.
4. **`.zlogin`** -- Login shells only, after `.zshrc`.
5. **`.zlogout`** -- Login shells only, on exit.

## Where to Put What

### `zsh/zprofile` (login shells)

Put here:
- **Exported environment variables** needed by non-interactive programs (`$PATH`, `$EDITOR`, `$PAGER`, `$XDG_*`, `$RUBY_CONFIGURE_OPTS`)
- **PATH modifications** (Homebrew, language version managers, toolchain bins)
- **Tool initialization that sets environment** (`brew shellenv`, `pyenv init --path`)
- **Variables consumed by GUI apps** or other processes spawned from the login session

Current contents: XDG dirs, Homebrew shellenv, PATH entries (PostgreSQL, pyenv, pipx, cargo, Obsidian), Ruby build config, zoxide override.

### `zsh/zshrc` (interactive shells)

Put here:
- **Oh-my-zsh configuration** (theme, plugins list, sourcing)
- **Shell options** (`setopt`, `unsetopt`, `zstyle`)
- **Completion setup** (`compinit`, `FPATH` additions)
- **Plugin loading** and framework config
- **Interactive-only variables** that non-interactive shells don't need
- **Prompt configuration** (Starship is active, ZSH_THEME is disabled)

Current contents: oh-my-zsh setup, plugin list, editor config, zsh-completions FPATH, 1Password SSH agent, dev CLI PATH.

### `zsh/bostonaholic.plugin.zsh` (custom oh-my-zsh plugin)

Put here:
- **Aliases** (CLI shortcuts, modern tool replacements, git aliases)
- **Shell functions** (wt wrapper, bundle_close, cljs)
- **Completion definitions** for custom functions (`compdef`)
- **Interactive environment variables** tied to CLI behavior (`$LESS`, `$HISTCONTROL`, `$LS_COLORS`)

Current contents: aliases (cat/bat, ls/eza, grep/rg, etc.), wt() git worktree wrapper + completions, utility functions.

### `.zshenv` (create only if needed)

Would be appropriate for:
- Variables that **must** be available in non-interactive, non-login script contexts
- `$ZDOTDIR` to relocate zsh config files
- Rarely needed -- most exported variables belong in `.zprofile`

### `.zlogin` / `.zlogout` (create only if needed)

- `.zlogin`: Commands to run at login after everything else loads (e.g., `startx`, motd)
- `.zlogout`: Cleanup on shell exit (e.g., `clear`, `reset`)

## Decision Flowchart

```
Is it an exported variable or PATH entry?
├── Yes → Is it needed by non-interactive processes or GUI apps?
│   ├── Yes → zsh/zprofile
│   └── No → Is it interactive shell behavior ($LESS, $HISTCONTROL)?
│       ├── Yes → zsh/bostonaholic.plugin.zsh
│       └── No → zsh/zprofile (default for exports)
├── No → Is it an alias or shell function?
│   └── Yes → zsh/bostonaholic.plugin.zsh
├── No → Is it oh-my-zsh config, plugins, or completion setup?
│   └── Yes → zsh/zshrc
├── No → Is it a shell option (setopt/unsetopt/zstyle)?
│   └── Yes → zsh/zshrc
└── No → Is it needed in ALL shells including scripts?
    ├── Yes → Create zsh/zshenv (rare)
    └── No → zsh/zshrc (safe default for interactive config)
```

## Important Rules

1. **Edit repo files, not symlink targets.** Change `zsh/zprofile`, not `~/.zprofile`.
2. **Add new files to `dotfiles.yaml`.** If creating `zsh/zshenv`, add a symlink entry under `symlinks:` and run `./install.sh --only symlinks`.
3. **Don't duplicate oh-my-zsh built-ins.** Check if a plugin already provides the alias or function before adding one.
4. **Keep `zshrc` focused on framework/plugin config.** User aliases and functions go in the plugin file, not zshrc.
5. **PATH in zprofile, not zshrc.** PATH entries set in zshrc won't be available to programs started outside an interactive shell.
