# Research: Dotfiles Unification (2026-01-28)

## Problem Statement

Need to understand the current structure of personal dotfiles (this repo) and work dotfiles (`/Users/matthew/code/bostonaholic/shopify-dotfiles`) to identify which configurations are shared vs work-specific vs personal-specific, enabling the creation of three YAML files (`dotfiles.shared.yaml`, `dotfiles.work.yaml`, `dotfiles.personal.yaml`) as designed in the brainstorming phase.

## Requirements

- Complete inventory of all configurations in both repos
- Clear categorization: shared / work-only / personal-only
- Identification of any conflicts or design considerations
- Focus on accuracy to inform implementation phase

## Findings

### Repository Structure

**Personal dotfiles** (this repo):
- Location: `/Users/matthew/dotfiles`
- Structure: Comprehensive YAML-driven configuration
- Main files:
  - `dotfiles.yaml` (153 lines) - complete configuration
  - `Brewfile` (194 lines) - extensive package list
  - `install.sh` - Python-based installer
  - `update.sh` - Update script
- Directories: bin/, claude/, zsh/, git/, vim/, emacs/, ruby/, node/, gpg/, ghostty/, cursor/, javascript/, clojure/, keyboard/, signature/, etc.

**Work dotfiles**:
- Location: `/Users/matthew/code/bostonaholic/shopify-dotfiles`
- Structure: Simple bash-based approach
- Main files:
  - `install.zsh` (164 lines) - bash installation script
  - `Brewfile` (53 lines) - minimal package list
  - `update.zsh` - Update script
  - **Note:** install.zsh references `$DOTFILES_DIR="$HOME/dotfiles"` but repos are used independently
- Directories: bin/, claude/, zsh/, git/, vim/, emacs/, gpg/, ghostty/, ruby/, scripts/

**Usage Pattern:** Repositories are used independently (one or the other), not overlaid.

### Shell Configuration (zsh)

**Personal `zsh/zshrc`:**
- Theme: robbyrussell (default)
- Custom plugin: bostonaholic
- Version managers: rbenv, pyenv, nodenv
- Plugins: bostonaholic, ngrok, nodenv, direnv, docker, docker-compose, lein, postgres, brew, bundler, common-aliases, emacs, fzf, fzf-tab, gem, gh, git, gitfast, gpg-agent, node, npm, rails, ruby, ssh-agent, yarn
- Editor: vim
- Special config: 1Password SSH agent

**Work `zsh/.zshrc`:**
- Theme: robbyrussell (default)
- Shopify integrations:
  - `/opt/dev/dev.sh` and chruby
  - `spin` completion
  - cloudplatform Kubernetes config
  - Custom prompt with `worldpath` (from tec)
  - `devx claude` integration
- Version manager: chruby (not rbenv)
- Plugins: brew, bundler, chruby, common-aliases, emacs, fzf-tab, gem, gh, git, gitfast, gpg-agent, node, npm, python, rails, ruby, ssh-agent, yarn
- Editor: cursor
- Aliases:
  - `claude="devx claude --dangerously-skip-permissions"`
  - `cc="claude"`
  - `conveyor-swarm="claude-swarm start conveyor-swarm.yml $*"`
  - Plus standard modern CLI aliases (cat→bat, ls→eza, find→fd)
- Environment:
  - `KUBECONFIG` with Shopify cloudplatform
  - `BEADS_NO_DAEMON=1`
  - Loads tec, bun, direnv

**Personal `zsh/zprofile`:**
- Exists in personal repo (symlinked to `~/.zprofile`)

**Classification:**
- `zsh/zshrc` - **SEPARATE** (work-specific and personal-specific versions)
- `zsh/zprofile` - **PERSONAL-ONLY** (not in work repo)
- `zsh/bostonaholic.zsh-theme` - **PERSONAL-ONLY**
- `zsh/bostonaholic.plugin.zsh` - **PERSONAL-ONLY**

### Homebrew Packages

**Shared packages** (in both Brewfiles):
```ruby
# Core development
brew 'gh'
brew 'git'
brew 'lazygit'
brew 'vim'
brew 'zsh'
brew 'zsh-completions'

# Terminals & Editors
cask 'ghostty'
brew 'emacs-plus' # (different args: personal=restart_service:changed, work=with-spacemacs-icon)
brew 'aspell'

# Modern CLI tools
brew 'bat'
brew 'curl'
brew 'eza'
brew 'fd'
brew 'jq'
brew 'ripgrep'
brew 'shellcheck'
brew 'tree'

# Security
brew 'gnutls'
brew 'pinentry-mac'

# Ruby dependencies
brew 'readline'
brew 'rust' # for YJIT

# AI tools
tap 'steveyegge/beads'
brew 'bd'

# macOS utilities
brew 'coreutils'
brew 'ossp-uuid'
brew 'terminal-notifier'

# Fonts
cask 'font-source-code-pro'
```

**Personal-only packages** (not in work Brewfile):
```ruby
# AI assistants
cask 'claude'
cask 'claude-code'
cask 'codex'
brew 'gemini-cli'

# Languages: Clojure
tap 'borkdude/brew'
tap 'clojure/tools'
brew 'borkdude/brew/babashka'
brew 'borkdude/brew/clj-kondo'
brew 'clojure/tools/clojure'
brew 'leiningen'
brew 'planck'

# Languages: Java
cask 'temurin@21'

# Languages: Node/Ruby/Python
brew 'jslint4java'
brew 'nodenv'
brew 'libyaml'
brew 'openssl@3' # vs 'openssl' in work
brew 'rbenv'
brew 'pyenv'
brew 'uv'

# Modern CLI tools
brew 'btop'
brew 'dua-cli'
brew 'duf'
brew 'fzf'
brew 'gping'
brew 'tldr'

# Version control
brew 'git-lfs'
brew 'pre-commit'

# Development tools
brew 'adr-tools'
brew 'cloc'
brew 'ctags'
cask 'docker-desktop'
brew 'markdownlint-cli'

# Shell utilities
brew 'ack'
brew 'autoenv'
brew 'direnv'
brew 'rlwrap'

# Data & serialization
brew 'yq'

# Networking
brew 'awscli'
brew 'httpie'
cask 'ngrok'

# Security
brew 'gnupg'

# Documentation
brew 'graphviz'
brew 'markdown'

# macOS utilities
cask 'clipy'
brew 'dfu-util'

# Media: Video
cask 'filebot'
cask 'makemkv'
cask 'mkvtoolnix-app'

# Media: 3D
cask 'blender'
```

**Work-only packages** (not in personal Brewfile):
```ruby
brew 'jnsahaj/lumen/lumen'
brew 'watchman'
brew 'python' # as brew package (personal uses pyenv)
brew 'node'   # as brew package (personal uses nodenv)
brew 'openssl' # vs 'openssl@3' in personal
```

**Recommendation:** Most packages (70%+) should go in `Brewfile.shared`, with work having minimal additions and personal having extensive development tooling.

### Claude Configuration

**Personal Claude config:**
- Files symlinked:
  - `claude/agents` → `~/.claude/agents`
  - `claude/commands` → `~/.claude/commands`
  - `claude/CLAUDE.md` → `~/.claude/CLAUDE.md`
  - `claude/settings.json` → `~/.claude/settings.json`
  - `claude/skills` → `~/.claude/skills`
  - `claude/statusline.clj` → `~/.claude/statusline.clj`

**Personal `claude/settings.json`:**
```json
{
  "apiKeyHelper": null,
  "statusLine": {
    "type": "command",
    "command": "bb ~/.claude/statusline.clj"
  },
  "enabledPlugins": {
    "beads@beads-marketplace": true,
    "code-simplifier@claude-plugins-official": true,
    "playwright@claude-plugins-official": true,
    "plugin-dev@claude-plugins-official": true,
    "ralph-loop@claude-plugins-official": true,
    "rpikit@rpikit": true,
    "superpowers@superpowers-marketplace": true,
    "typescript-lsp@claude-plugins-official": true
  }
}
```

**Work Claude config:**
- Files symlinked:
  - `claude/settings.json` → `~/.claude/settings.json`
  - `claude/settings.local.json` → `~/.claude/settings.local.json`
  - `claude/commands` → `~/.claude/commands`
  - `claude/agents` → `~/.claude/agents`
  - `claude/statusline.sh` → `~/.claude/statusline.sh`

**Work `claude/settings.json`:**
```json
{
  "apiKeyHelper": "/opt/dev/bin/user/devx llm-gateway print-token --key",
  "env": {
    "ANTHROPIC_BASE_URL": "https://proxy.shopify.ai/vendors/anthropic-claude-code",
    "MAX_THINKING_TOKENS": "31999"
  },
  "model": "opus",
  "permissions": {
    "allow": [
      "Bash(cat:*)",
      "Bash(DEV_NO_AUTO_UPDATE=1 /opt/dev/bin/dev:*)",
      "Bash(DEV_NO_AUTO_UPDATE=1 /opt/dev/bin/devx:*)",
      ...
    ]
  },
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh"
  },
  "enabledPlugins": {
    "superpowers@superpowers-marketplace": true,
    "rpikit@rpikit": true,
    "ralph-loop@claude-plugins-official": true,
    "plugin-dev@claude-plugins-official": true
  },
  "hooks": {
    "Notification": [...] // alerter notifications
  },
  "alwaysThinkingEnabled": true
}
```

**Classification:**
- `claude/settings.json` - **WORK-SPECIFIC** and **PERSONAL-SPECIFIC** (different API configs, plugins, permissions)
- `claude/settings.local.json` - **WORK-ONLY**
- `claude/agents/` - **SHARED** (same structure)
- `claude/commands/` - **SHARED** (same structure)
- `claude/CLAUDE.md` - **SHARED** (global AI instructions)
- `claude/skills/` - **PERSONAL-ONLY** (doesn't exist in work repo)
- `claude/statusline.clj` - **PERSONAL**
- `claude/statusline.sh` - **WORK**

### Git Configuration

**Personal git config:**
- `git/config` → `~/.config/git/config`
- `git/helpers` → `~/.config/git/helpers`
- `git/ignore` → `~/.config/git/ignore`
- `git/allowed_signers` → `~/.config/git/allowed_signers`

**Work git config:**
- `git/.gitconfig` → `~/.config/git/config`
- `git/.gitignore` → `~/.config/git/ignore`
- `git/helpers` → `~/.config/git/helpers`

**Note:** Need to diff actual file contents to determine if they're identical or have work-specific customizations.

**Classification (tentative, pending diff):**
- Likely **SHARED** unless diff reveals work-specific config

### Other Configuration Files

**Vim:**
- Personal: `vim/my_configs.vim` → `~/.vim_runtime/my_configs.vim`
- Work: `vim/.my_configs.vim` → `~/.vim_runtime/my_configs.vim`
- Classification: Likely **SHARED** (pending diff)

**Emacs:**
- Personal: `emacs/spacemacs` → `~/.spacemacs`
- Work: `emacs/.spacemacs` → `~/.spacemacs`
- Classification: Likely **SHARED** (pending diff)

**Ghostty:**
- Personal: `ghostty/config` → `~/.config/ghostty/config`
- Work: `ghostty/config` → `~/.config/ghostty/config`
- Classification: Likely **SHARED** (pending diff)

**GPG:**
- Personal: `gpg/gpg-agent.conf` → `~/.gnupg/gpg-agent.conf`
- Work: `gpg/gpg-agent.conf` → `~/.gnupg/gpg-agent.conf`
- Classification: Likely **SHARED** (pending diff)

**Ruby:**
- Personal: `ruby/pryrc` → `~/.pryrc`, `ruby/rspec` → `~/.rspec`, `ruby/default-gems` → `~/.rbenv/default-gems`
- Work: `ruby/.pryrc` → `~/.pryrc`
- Classification: **PERSONAL** has more files; need to diff `.pryrc`

**Cursor:**
- Personal: `cursor/rules` → `~/.cursor/rules`
- Work: None
- Classification: **PERSONAL-ONLY**

**VSCode:**
- Personal: `vscode/keybindings.json`, `vscode/settings.json`
- Work: None
- Classification: **PERSONAL-ONLY**

**Other personal-only configs:**
- `home/colors` → `~/.colors`
- `ignore/ignore` → `~/.ignore`
- `ignore/rgignore` → `~/.rgignore`
- `javascript/jsbeautifyrc` → `~/.jsbeautifyrc`
- `javascript/jshintrc` → `~/.jshintrc`
- `clojure/profiles.clj` → `~/.lein/profiles.clj`
- `keyboard/qwerty.txt` → `~/qwerty.txt`
- `signature/signature` → `~/.signature`
- `node/node-version` → `~/.node-version`

### Scripts (bin/)

**Personal bin/** (40 scripts):
```
alerter               git-age              git-ai-commit
git-ai-commit-msg     git-authors          git-batch
git-churn             git-conflicts        git-deletealltags
git-deletemerged      git-numbers          git-stats
git-undo              brew-orphans         brewup
cleanup               docker-cleanup       dwi
gemfresh              grep-routes          http-server
icons                 macchanger           monday
pairing               pass                 ports
rcopy                 replace              rmove
run-command-on-git-revisions  sayit        setup-scripts
spacemacsup           timezsh              todos
vimup                 wt
```

**Work bin/** (6 scripts):
```
alerter               git-ai-commit        git-ai-commit-msg
icons                 monday               reflect.ts
```

**Shared scripts:**
- alerter
- icons
- git-ai-commit
- git-ai-commit-msg
- monday

**Classification:**
- **SHARED**: alerter, icons, git-ai-commit, git-ai-commit-msg, monday
- **PERSONAL**: All other personal scripts (35 scripts)
- **WORK**: reflect.ts

### NPM Global Packages

**Personal:**
```yaml
npm:
  global_packages:
    - prettier
    - prettier-eslint
    - prettier-eslint-cli
    - tern
    - ulid
```

**Work:**
- None specified in config (installed via npm directly in install.zsh)

**Classification:** **PERSONAL** (work doesn't manage npm packages via config)

### UV Tool Packages

**Personal:**
```yaml
uv:
  tool_packages:
    - name: specify-cli
      source: "git+https://github.com/github/spec-kit.git"
```

**Work:**
- None

**Classification:** **PERSONAL-ONLY**

### Install Scripts & Hooks

**Personal post_install scripts:**
- Install oh-my-zsh
- Install Spacemacs
- Install vimrc
- Install rbenv plugins
- Install nodenv
- Install pre-commit hooks
- Install Powerline fonts
- Apply macOS settings

**Work install.zsh:**
- Install oh-my-zsh
- Install Spacemacs (with batch init)
- Install vimrc
- Link Emacs to Applications
- Install Claude Code via npm
- Install Claude plugins from settings.json (with marketplace mapping)
- Accept Xcode license
- Switch xcode-select to /Applications/Xcode.app

**Classification:**
- oh-my-zsh, Spacemacs, vimrc install - **SHARED** concept
- Claude plugin installation - **WORK** has more sophisticated approach
- Xcode setup - **WORK-ONLY**
- rbenv plugins, nodenv, pre-commit, Powerline fonts, macOS settings - **PERSONAL**

## Categorization Summary

### SHARED Configs (goes in dotfiles.shared.yaml + Brewfile.shared)

**Symlinks:**
- `git/config` → `~/.config/git/config` (pending diff)
- `git/helpers` → `~/.config/git/helpers`
- `git/ignore` → `~/.config/git/ignore`
- `vim/my_configs.vim` → `~/.vim_runtime/my_configs.vim` (pending diff)
- `emacs/spacemacs` → `~/.spacemacs` (pending diff)
- `ghostty/config` → `~/.config/ghostty/config` (pending diff)
- `gpg/gpg-agent.conf` → `~/.gnupg/gpg-agent.conf` (pending diff)
- `ruby/pryrc` → `~/.pryrc` (pending diff)
- `claude/agents` → `~/.claude/agents`
- `claude/commands` → `~/.claude/commands`
- `claude/CLAUDE.md` → `~/.claude/CLAUDE.md`

**Scripts (bin/):**
- `bin/alerter` → `~/bin/alerter`
- `bin/icons` → `~/bin/icons`
- `bin/git-ai-commit` → `~/bin/git-ai-commit`
- `bin/git-ai-commit-msg` → `~/bin/git-ai-commit-msg`
- `bin/monday` → `~/bin/monday`

**Packages (Brewfile.shared):**
- See "Shared packages" section above

**Post-install scripts:**
- Install oh-my-zsh
- Install Spacemacs
- Install vimrc

### WORK-SPECIFIC Configs (goes in dotfiles.work.yaml + Brewfile.work)

**Symlinks:**
- `zsh/.zshrc` → `~/.zshrc` (work version)
- `claude/settings.json` → `~/.claude/settings.json` (work version)
- `claude/settings.local.json` → `~/.claude/settings.local.json`
- `claude/statusline.sh` → `~/.claude/statusline.sh`

**Scripts (bin/):**
- `bin/reflect.ts` → `~/bin/reflect.ts`

**Packages (Brewfile.work):**
```ruby
brew 'jnsahaj/lumen/lumen'
brew 'watchman'
brew 'python'
brew 'node'
```

**Post-install scripts:**
- Link Emacs to ~/Applications
- Install Claude Code via npm
- Install Claude plugins with marketplace mapping
- Accept Xcode license
- Switch xcode-select to /Applications/Xcode.app

### PERSONAL-SPECIFIC Configs (goes in dotfiles.personal.yaml + Brewfile.personal)

**Symlinks:**
- `zsh/zshrc` → `~/.zshrc` (personal version)
- `zsh/zprofile` → `~/.zprofile`
- `zsh/bostonaholic.zsh-theme` → `~/.oh-my-zsh/custom/themes/bostonaholic.zsh-theme`
- `zsh/bostonaholic.plugin.zsh` → `~/.oh-my-zsh/custom/plugins/bostonaholic/bostonaholic.plugin.zsh`
- `claude/settings.json` → `~/.claude/settings.json` (personal version)
- `claude/skills` → `~/.claude/skills`
- `claude/statusline.clj` → `~/.claude/statusline.clj`
- `cursor/rules` → `~/.cursor/rules`
- `vscode/keybindings.json` → `~/Library/Application Support/Code/User/keybindings.json`
- `vscode/settings.json` → `~/Library/Application Support/Code/User/settings.json`
- `ruby/rspec` → `~/.rspec`
- `ruby/default-gems` → `~/.rbenv/default-gems`
- `node/node-version` → `~/.node-version`
- `home/colors` → `~/.colors`
- `ignore/ignore` → `~/.ignore`
- `ignore/rgignore` → `~/.rgignore`
- `javascript/jsbeautifyrc` → `~/.jsbeautifyrc`
- `javascript/jshintrc` → `~/.jshintrc`
- `clojure/profiles.clj` → `~/.lein/profiles.clj`
- `keyboard/qwerty.txt` → `~/qwerty.txt`
- `signature/signature` → `~/.signature`
- `git/allowed_signers` → `~/.config/git/allowed_signers`
- `emacs/templates/*` → `~/.emacs.d/private/templates/*` (symlink_contents)

**Scripts (bin/):**
All personal scripts except the 5 shared ones (35 scripts total)

**Packages (Brewfile.personal):**
All personal-only packages listed above

**NPM packages:**
```yaml
npm:
  global_packages:
    - prettier
    - prettier-eslint
    - prettier-eslint-cli
    - tern
    - ulid
```

**UV packages:**
```yaml
uv:
  tool_packages:
    - name: specify-cli
      source: "git+https://github.com/github/spec-kit.git"
```

**Post-install scripts:**
- Install rbenv plugins
- Install nodenv
- Install pre-commit hooks
- Install Powerline fonts
- Apply macOS settings

### Directories

**Shared:**
```yaml
directories:
  - ~/bin
  - ~/.claude
  - ~/.config/ghostty
  - ~/.config/git
  - ~/.gnupg
  - ~/.oh-my-zsh/custom/plugins/bostonaholic
  - ~/.oh-my-zsh/custom/themes
```

**Personal-only:**
```yaml
directories:
  - ~/.cursor
  - ~/.lein
  - ~/.rbenv
  - ~/Library/Application Support/Code/User
  - ~/.emacs.d/private/templates
```

## Open Questions

### 1. Config File Diffs Needed

The following files exist in both repos but need content comparison to determine if they're truly identical or have environment-specific differences:

- `git/config` vs `git/.gitconfig`
- `git/ignore` vs `git/.gitignore`
- `vim/my_configs.vim` vs `vim/.my_configs.vim`
- `emacs/spacemacs` vs `emacs/.spacemacs`
- `ghostty/config` vs `ghostty/config`
- `gpg/gpg-agent.conf` vs `gpg/gpg-agent.conf`
- `ruby/pryrc` vs `ruby/.pryrc`

**Action:** Diff these files during implementation to verify they can be shared or need work/personal variants.

### 2. Emacs-plus Arguments

Personal: `brew 'emacs-plus', restart_service: :changed, link: true`
Work: `brew 'emacs-plus', args: ['with-spacemacs-icon'], restart_service: :changed`

**Question:** Should these be merged into a single entry with both options, or kept separate?

**Recommendation:** Merge into shared with combined options: `brew 'emacs-plus', args: ['with-spacemacs-icon'], restart_service: :changed, link: true`

### 3. OpenSSL Version Conflict

Personal uses `openssl@3`, work uses `openssl`.

**Impact:** May need both, or one could be removed depending on actual usage.

**Action:** Test if both are needed or if we can standardize on `openssl@3`.

### 4. Python/Node Package Managers

Personal uses version managers (pyenv, nodenv), work installs via Homebrew (`brew 'python'`, `brew 'node'`).

**Question:** Should work switch to version managers to match personal?

**Recommendation:** Keep work's approach - Shopify likely has specific Python/Node versions managed via their tooling.

## Recommendations

### Implementation Priority

1. **Start with Brewfiles** - Easiest to split and most clear-cut
   - Create `Brewfile.shared` with ~30 shared packages
   - Create `Brewfile.personal` with ~100+ personal packages
   - Create `Brewfile.work` with ~4 work packages

2. **Split shell configs** - Already know these are separate
   - Create `zsh/.zshrc.personal` and `zsh/.zshrc.work`
   - Keep personal zprofile, theme, plugin

3. **Split Claude configs** - Clear differences
   - Create `claude/settings.json.personal` and `claude/settings.json.work`
   - Keep shared: agents, commands, CLAUDE.md
   - Handle statusline variants

4. **Diff shared configs** - Verify assumptions
   - Compare git, vim, emacs, ghostty, gpg configs
   - Move to shared if identical, create variants if different

5. **Create YAML files** - Build the three configs
   - `dotfiles.shared.yaml` - ~20 symlinks, shared directories
   - `dotfiles.personal.yaml` - ~30 symlinks, personal packages, scripts
   - `dotfiles.work.yaml` - ~5 symlinks, work packages, scripts

### Migration Strategy

1. Keep work repo as-is (backup, don't modify)
2. Create new structure in personal repo
3. Test v2 scripts on personal machine first
4. Test v2 scripts on work machine
5. Validate both environments before removing old scripts

## Next Steps

- [ ] Create implementation plan with detailed tasks
- [ ] Diff shared config files to verify they can be merged
- [ ] Build initial versions of three YAML files
- [ ] Build initial versions of three Brewfiles
- [ ] Create scripts/detect_profile.sh
- [ ] Create scripts/merge_yaml.py
- [ ] Create install-v2.sh and update-v2.sh
- [ ] Test on personal machine
- [ ] Test on work machine
