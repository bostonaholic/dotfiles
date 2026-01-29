# frozen_string_literal: true

# Brewfile - Organized by functional categories
#
# Usage: brew bundle
#

# Set arguments for all 'brew install --cask' commands
cask_args appdir: '~/Applications', fontdir: '/Library/Fonts'

# =============================================================================
# AI Coding Assistants
# =============================================================================

tap 'steveyegge/beads'

brew 'bd' # AI-supervised issue tracker
cask 'claude'
cask 'claude-code'
cask 'codex'
brew 'gemini-cli'

# =============================================================================
# Editors
# =============================================================================

tap 'd12frosted/emacs-plus'

brew 'emacs-plus',
     restart_service: :changed,
     link: true
brew 'gnutls' # for Emacs TLS support
brew 'vim'

# =============================================================================
# Terminals & Shell
# =============================================================================

cask 'ghostty'
brew 'zsh'
brew 'zsh-completions'

# =============================================================================
# Version Control
# =============================================================================

brew 'bfg'        # BFG Repo-Cleaner, like git-filter-branch
brew 'gh'
brew 'git'
brew 'git-lfs'
brew 'lazygit'
brew 'pre-commit'

# =============================================================================
# Modern CLI Tools
# =============================================================================
# Unix tool replacements

brew 'bat'     # cat
brew 'btop'    # top
brew 'dua-cli' # du
brew 'duf'     # df
brew 'eza'     # ls
brew 'fd'      # find
brew 'fzf'     # ctrl-r, fuzzy finder
brew 'gping'   # ping
brew 'ripgrep' # grep
brew 'tldr'    # man

# =============================================================================
# Languages: Clojure
# =============================================================================

tap 'borkdude/brew'
tap 'clojure/tools'

brew 'borkdude/brew/babashka'
brew 'borkdude/brew/clj-kondo'
brew 'clojure/tools/clojure'
brew 'leiningen'
brew 'planck'

# =============================================================================
# Languages: Java
# =============================================================================

cask 'temurin@21'

# =============================================================================
# Languages: Node
# =============================================================================

brew 'jslint4java'
brew 'nodenv'

# =============================================================================
# Languages: Ruby
# =============================================================================

brew 'libyaml'   # for Psych YAML parser
brew 'openssl@3' # for Ruby >= 3.1
brew 'rbenv'
brew 'readline' # for IRB/Pry line editing
brew 'rust'     # for YJIT

# =============================================================================
# Languages: Python
# =============================================================================

brew 'pyenv'
brew 'uv'

# =============================================================================
# Data & Serialization
# =============================================================================

brew 'jq' # JSON
brew 'yq' # YAML

# =============================================================================
# Networking
# =============================================================================

brew 'awscli'
brew 'curl'
brew 'httpie'
cask 'ngrok'

# =============================================================================
# Security
# =============================================================================

brew 'gnupg'
brew 'pinentry-mac'

# =============================================================================
# Development Tools
# =============================================================================

brew 'adr-tools'
brew 'cloc'
brew 'ctags'
cask 'docker-desktop'
brew 'markdownlint-cli'
brew 'shellcheck'

# =============================================================================
# Shell Utilities
# =============================================================================
# Traditional Unix tools (not replaced by Modern CLI tools)

brew 'ack'
brew 'autoenv'
brew 'coreutils'
brew 'direnv'
brew 'rlwrap'
brew 'tree'

# =============================================================================
# Documentation
# =============================================================================

brew 'aspell'
brew 'graphviz'
brew 'markdown'

# =============================================================================
# macOS Utilities
# =============================================================================

cask 'clipy'
brew 'dfu-util'  # for flashing keyboard firmware
brew 'ossp-uuid' # UUID generation
brew 'terminal-notifier'

# =============================================================================
# Fonts
# =============================================================================

cask 'font-source-code-pro'

# =============================================================================
# Media: Video
# =============================================================================

cask 'filebot'
cask 'makemkv'
cask 'mkvtoolnix-app'

# =============================================================================
# Media: 3D
# =============================================================================

cask 'blender'
