# AI Coding Assistant Guide

Unified dotfiles supporting both work and personal machines via profile-based
configuration. On first run, select your profile (work/personal) and the
installer merges shared + profile-specific configs automatically.

## Quick Reference Commands

```bash
# Preview changes (always run first)
./install.sh --dry-run

# Apply symlink changes only
./install.sh --only symlinks

# Full installation
./install.sh -f -y

# Force a specific profile
./install.sh --profile personal

# Update everything
./update.sh

# Validate shell scripts
shellcheck scripts/*
```

## Profile System

Profile selection is stored in `~/.dotfiles_profile`. On first run, the
installer prompts for selection. Subsequent runs use the saved profile.

| Profile | Purpose |
| ------- | ------- |
| `personal` | Personal machine with all tools |
| `work` | Shopify work environment |

## File Locations

### Configuration Files

| Purpose | Shared | Personal | Work |
| ------- | ------ | -------- | ---- |
| YAML config | `dotfiles.shared.yaml` | `dotfiles.personal.yaml` | `dotfiles.work.yaml` |
| Brewfile | `Brewfile.shared` | `Brewfile.personal` | `Brewfile.work` |

### Directory Structure

```text
dotfiles/
  install.sh            # Profile-aware installer (v2)
  update.sh             # Profile-aware updater (v2)
  install.v1.sh         # Legacy installer (backup)
  update.v1.sh          # Legacy updater (backup)
  dotfiles.shared.yaml  # Shared configuration
  dotfiles.personal.yaml # Personal-specific config
  dotfiles.work.yaml    # Work-specific config
  Brewfile.shared       # Shared Homebrew packages
  Brewfile.personal     # Personal Homebrew packages
  Brewfile.work         # Work Homebrew packages
  scripts/              # Install and helper scripts
  shared/               # Configs for both profiles
    bin/                # Shared scripts
    claude/             # Shared Claude components
    git/                # Shared git config
    ghostty/            # Terminal config
    gpg/                # GPG agent config
    ruby/               # Shared ruby config
  personal/             # Personal-only configs
    bin/                # Personal scripts
    claude/             # Personal Claude settings
    git/                # Git config (SSH signing)
    zsh/                # Shell config
    emacs/              # Spacemacs config
    vim/                # Vim config
    vscode/             # VS Code settings
    cursor/             # Cursor rules
    ...
  work/                 # Work-only configs
    claude/             # Work Claude settings
    git/                # Git config (GPG signing)
    zsh/                # Work shell config
    ...
```

## Modification Workflow

### Adding a New Dotfile

1. Determine if config is shared, personal-only, or work-only
2. Create the config file in the appropriate directory:
   - Shared: `shared/<category>/<file>`
   - Personal: `personal/<category>/<file>`
   - Work: `work/<category>/<file>`
3. Add symlink entry to the appropriate YAML file:
   - `dotfiles.shared.yaml` for shared configs
   - `dotfiles.personal.yaml` for personal configs
   - `dotfiles.work.yaml` for work configs
4. Run `./install.sh --only symlinks`
5. Commit the config file and YAML file

### Adding a Homebrew Package

1. Determine if package is shared, personal-only, or work-only
2. Add to appropriate Brewfile:
   - `Brewfile.shared` for both profiles
   - `Brewfile.personal` for personal only
   - `Brewfile.work` for work only
3. Run `brew bundle --file=Brewfile.<type>`
4. Commit the Brewfile

### Adding an npm Global Package

1. Add package name to `packages.npm.global_packages` in appropriate YAML
2. Run `./install.sh --only npm`
3. Commit the YAML file

### Adding a Claude Plugin

1. Add plugin to `packages.claude.plugins` in appropriate YAML
2. Run `./scripts/install_claude_plugins`
3. Commit the YAML file

## Anti-Patterns

| Do Not | Instead |
| ------ | ------- |
| Run `ln -s` directly | Add to appropriate YAML, run install.sh |
| Run `brew install X` | Add to appropriate Brewfile, run brew bundle |
| Run `npm install -g X` | Add to appropriate YAML, run install.sh |
| Edit files in `~/.config/` | Edit source files in repo, run install.sh |
| Create backup copies manually | install.sh handles backups automatically |
| Mix shared and profile-specific in wrong file | Keep configs in correct directory |

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

## Claude Code Integration

Claude configs are split between shared and profile-specific:

- **Shared** (`shared/claude/`): agents, commands, CLAUDE.md
- **Personal** (`personal/claude/`): settings.json, skills, statusline.clj
- **Work** (`work/claude/`): settings.json, statusline.sh

Changes to claude files are immediately effective (symlinked to `~/.claude/`).

## Commit Conventions

Follow conventional commits observed in this repo:

- `feat(scope):` - New feature
- `fix(scope):` - Bug fix
- `refactor(scope):` - Code restructuring
- `style(scope):` - Formatting changes
- `chore(scope):` - Maintenance tasks

Examples:

```text
feat(dotfiles): unify personal and work configs with profile-based system
fix(install): export CONFIG_FILE to symlinks script
```
