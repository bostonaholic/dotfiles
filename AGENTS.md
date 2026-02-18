# AI Coding Assistant Guide

Personal dotfiles managed via declarative YAML configuration. All changes flow
through `dotfiles.yaml` and `install.sh`.

## Quick Reference Commands

```bash
# Preview changes (always run first)
./install.sh --dry-run

# Apply symlink changes only
./install.sh --only symlinks

# Full installation
./install.sh -fy

# Update everything
./update.sh

# Validate shell scripts
shellcheck scripts/*
```

## File Locations

| Purpose | Location |
| ------- | -------- |
| Central config | `dotfiles.yaml` |
| Homebrew packages | `Brewfile` |
| Shell config | `zsh/zshrc`, `zsh/zprofile` |
| Custom zsh plugin | `zsh/bostonaholic.plugin.zsh` |
| Git config | `git/config` |
| Claude commands | `claude/commands/*.md` |
| Claude agents | `claude/agents/*.md` |
| Claude skills | `claude/skills/*/SKILL.md` |
| Install scripts | `scripts/install_*` |

## Modification Workflow

### Adding a New Dotfile

1. Create the config file in appropriate directory
2. Add symlink entry to `dotfiles.yaml` under `symlinks:`
3. Run `./install.sh --only symlinks`
4. Commit both files

### Adding a Homebrew Package

1. Edit `Brewfile` with the package
2. Run `brew bundle`
3. Commit `Brewfile`

### Adding an npm Global Package

1. Add package name to `packages.npm.global_packages` in `dotfiles.yaml`
2. Run `./install.sh --only npm`
3. Commit `dotfiles.yaml`

### Adding a Claude Plugin

1. Add plugin to `packages.claude.plugins` in `dotfiles.yaml`
2. Run `./scripts/install_claude_plugins`
3. Commit `dotfiles.yaml`

## Anti-Patterns

| Do Not | Instead |
| ------ | ------- |
| Run `ln -s` directly | Add to `dotfiles.yaml`, run install.sh |
| Run `brew install X` | Add to `Brewfile`, run `brew bundle` |
| Run `npm install -g X` | Add to `dotfiles.yaml`, run install.sh |
| Edit files in `~/.config/` | Edit source files in repo, run install.sh |
| Create backup copies manually | install.sh handles backups automatically |

## Shell Scripts

All scripts in `scripts/` must:

- Pass shellcheck validation (pre-commit hook)
- Be executable (`chmod +x`)
- Use `set -euo pipefail`

Run before committing:

```bash
shellcheck scripts/*
```

## Quality Gates

Pre-commit hooks run automatically. Manual checks:

```bash
# Shell script validation
shellcheck scripts/*.sh

# Markdown linting
markdownlint "**/*.md"
```

## Directory Structure

```text
dotfiles/
  dotfiles.yaml     # Source of truth for all config
  install.sh        # Idempotent installer
  update.sh         # Pull updates, refresh packages
  Brewfile          # Homebrew packages
  scripts/          # Install and update scripts
  zsh/              # Shell configuration
  git/              # Git config and helpers
  claude/           # Claude Code configuration
    commands/       # Slash commands
    agents/         # Subagent definitions
    skills/         # Skill definitions
    settings.json   # Claude Code settings
  vim/              # Vim configuration
  ruby/             # Ruby gems and pry config
  node/             # Node version config
  gpg/              # GPG agent config
```

## Claude Code Integration

Changes to `claude/` are immediately effective (symlinked to `~/.claude/`).

- Commands: `claude/commands/*.md` - Slash command definitions
- Agents: `claude/agents/*.md` - Subagent system prompts
- Skills: `claude/skills/*/SKILL.md` - Skill definitions
- Settings: `claude/settings.json` - Preferences and hooks

## Commit Conventions

Follow conventional commits observed in this repo:

- `feat(scope):` - New feature
- `fix(scope):` - Bug fix
- `refactor(scope):` - Code restructuring
- `style(scope):` - Formatting changes
- `chore(scope):` - Maintenance tasks

Examples from recent history:

```text
feat(statusline): add data extraction helpers to Clojure impl
fix(settings): update enabledPlugins section for consistency
refactor(statusline): remove deprecated status line shell script
```

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:

   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```

5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**

- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
