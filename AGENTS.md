# Dotfiles Repository Guide

This repository manages personal dotfiles using a declarative YAML configuration with an installation script.

## Core Workflow

### Installation and Updates

- Use `./install.sh` for full setup (interactive by default)
- Use `./install.sh --dry-run` to preview changes before applying
- Use `./install.sh --only <component>` to install specific components (symlinks, homebrew, npm)
- After modifying `dotfiles.yaml`, run `./install.sh --only symlinks` to update just symlinks
- Use `./update.sh` to pull latest changes and update packages

**Configuration is Declarative**
All installations are managed through `dotfiles.yaml`. Never manually create symlinks or install packages outside this system update the YAML file instead, then run install.sh.

## Repository Structure

- `dotfiles.yaml`: Central configuration defining directories, symlinks, packages, and scripts
- `install.sh`: Idempotent installation script that reads dotfiles.yaml
- `update.sh`: Updates repository, Homebrew packages, and Claude plugins
- Individual config directories (zsh/, git/, ruby/, etc.) contain actual config files
- `scripts/`: Helper scripts called during installation (oh-my-zsh, rbenv plugins, etc.)

## Adding New Dotfiles

1. Add your config file to the appropriate directory in the repo (create new dir if needed)
2. Edit `dotfiles.yaml` and add an entry to the `symlinks` section
3. Run `./install.sh --only symlinks` to create the symlink
4. Never use `ln` directly always go through dotfiles.yaml

## Tools and Languages

### Primary Development Stack

- Ruby: rbenv for version management, default gems in `ruby/default-gems`
- Node.js: nodenv for version management
- Clojure: Leiningen and clj-kondo for linting
- Python: pyenv for versions, uv for fast package installation (used for MCP servers)

### Shell Environment

- zsh with oh-my-zsh: Custom plugin at `zsh/bostonaholic.plugin.zsh`
- Custom theme: `zsh/bostonaholic.zsh-theme`
- For shell config changes, edit files in zsh/ then run install.sh

### Git Configuration

- Main config at `git/config`, links to `~/.config/git/config`
- For work computers: Create `~/.config/git/config.work` with work email/signing key
- Git helpers scripts in `git/helpers/`
- Global ignore patterns in `git/ignore`

### Security and GPG

- GPG agent configured via `gpg/gpg-agent.conf`
- If GPG signing fails: `gpgconf --kill gpg-agent` or `brew link --overwrite gnupg`
- pinentry-mac handles password prompts

## Common Operations

### Package Management

- Homebrew packages: Edit `Brewfile`, then `brew bundle`
- NPM globals: Edit `packages.npm.global_packages` in dotfiles.yaml, then install
- Ruby gems: Edit `ruby/default-gems`, they install automatically with new Ruby versions

### Troubleshooting

- For ssh-agent errors, add `zstyle :omz:plugins:ssh-agent agent-forwarding on`
- For zsh compaudit warnings, run `compaudit` to find insecure dirs, then `sudo chmod -R g-w <directory>`
- Vim plugin errors needing requests: `pip3 install requests`

## Claude Code Integration

This repository includes Claude Code configuration:

- Commands in `claude/commands/`: Custom slash commands for workflows
- Agents in `claude/agents/`: Role-specific agent configurations
- Settings in `claude/settings.json`: Claude Code preferences

When modifying Claude configs, changes are immediately available (symlinked from repo to ~/.claude).

## Principles to Follow

Never manually symlink files use dotfiles.yaml and install.sh. This keeps the repository as the single source of truth.

When adding new tools, consider:

1. Is it widely used (>30% of the time)? Add to Brewfile
2. Does it need configuration? Add config file to appropriate directory and update dotfiles.yaml
3. Does it need post-install setup? Add to `scripts.post_install` in dotfiles.yaml

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
