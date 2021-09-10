# frozen_string_literal: true

# How to use the Brewfile
#
# $ brew bundle --no-lock
#

# Taps
tap 'AdoptOpenJDK/openjdk'
tap 'd12frosted/emacs-plus'
tap 'borkdude/brew'
tap 'homebrew/cask'
tap 'wagoodman/bashful'

# Programming
brew 'asdf'
brew 'aspell'
brew 'cloc'
brew 'emacs-plus', # tap d12frosted/emacs-plus
     args: %w[with-ctags with-spacemacs-icon],
     restart_service: :changed
brew 'git'
brew 'git-lfs'
brew 'libyaml'
cask 'ngrok'
brew 'tmux'
brew 'vim'
brew 'zsh'
brew 'zsh-completions'

# Security
brew 'gnupg'
brew 'gnupg2'
brew 'gnutls'
brew 'pinentry-mac'

# Clojure
cask 'adoptopenjdk11' # tap AdoptOpenJDK/openjdk
brew 'boot-clj'
brew 'planck'
brew 'leiningen'
brew 'borkdude/brew/clj-kondo'

# JavaScript
brew 'jq'
brew 'jslint4java'
brew 'yarn'

# Ruby
# ruby-build suggests using these
brew 'openssl'
brew 'readline'

# Unix
brew 'ack'
brew 'autoenv'
brew 'bashful'
brew 'curl'
brew 'htop'
brew 'httpie'
brew 'nmap'
brew 'rg'
brew 'rlwrap'
brew 'the_silver_searcher'
brew 'tree'

# Other
brew 'adr-tools' # Architecture Decision Records tool
brew 'awscli'
brew 'coreutils' # GNU core utilities
brew 'dfu-util'  # Device Firmware Upgrade Utilities
brew 'graphviz'
brew 'markdown'
brew 'ossp-uuid' # ISO-C API and CLI for generating UUIDs
