# frozen_string_literal: true

# How to use the Brewfile
#
# $ brew bundle --no-lock
#

# Taps
tap 'clojure/tools'
tap 'd12frosted/emacs-plus'
tap 'borkdude/brew'
tap 'wagoodman/bashful'

# set arguments for all 'brew install --cask' commands
cask_args appdir: '~/Applications', require_sha: true

# Programming
brew 'aspell'
brew 'cloc'
brew 'ctags'
brew 'emacs-plus', # tap d12frosted/emacs-plus
     args: %w[with-spacemacs-icon],
     restart_service: :changed,
     link: true
brew 'gh'
brew 'git'
brew 'git-lfs'
brew 'libyaml'
cask 'ngrok'
brew 'vim'
brew 'zsh'
brew 'zsh-completions'

# Security
brew 'gnupg'
brew 'gnutls'
brew 'pinentry-mac'

# Clojure
brew 'clojure/tools/clojure'
brew 'planck'
brew 'leiningen'
brew 'borkdude/brew/clj-kondo'

# Java
cask 'temurin@21'

# JavaScript
brew 'jq'
brew 'jslint4java'
brew 'nodenv'

# Ruby
# ruby-build suggests using these
brew 'openssl@3' # for Ruby versions >= 3.1
brew 'rbenv' # ruby-build installed as a dependency
brew 'readline'
brew 'rust' # for building Ruby with YJIT

# Python
brew 'pyenv'

# Unix
brew 'ack'
brew 'autoenv'
brew 'bashful'
brew 'curl'
brew 'htop'
brew 'httpie'
brew 'ripgrep'
brew 'rlwrap'
brew 'shellcheck'
brew 'tree'

# Video editing
cask 'filebot'    # Renaming movies and TV shows
cask 'makemkv'    # Ripping DVDs and Blu-ray
cask 'mkvtoolnix' # Splitting .mkv files

# 3D printing
cask 'blender' # 3D modeling

# Other
brew 'adr-tools' # Architecture Decision Records tool
brew 'awscli'
brew 'coreutils' # GNU core utilities
brew 'dfu-util'  # Device Firmware Upgrade Utilities
brew 'graphviz'
brew 'markdown'
brew 'ossp-uuid' # ISO-C API and CLI for generating UUIDs
