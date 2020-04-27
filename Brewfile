# frozen_string_literal: true

# How to use the Brewfile
#
# $ brew tap homebrew/bundle
# $ brew bundle
#

# Taps
tap 'AdoptOpenJDK/openjdk'
tap 'd12frosted/emacs-plus'
tap 'mongodb/brew'

# Browsers
cask 'firefox' # tap homebrew-cask

# Programming
brew 'aspell'
brew 'cloc'
brew 'emacs-plus', # tap d12frosted/emacs-plus
     args: ['with-ctags'],
     restart_service: :changed
brew 'git'
brew 'libyaml'
brew 'mongodb-community', restart_service: :changed # tap mongodb/brew
cask 'ngrok' # tap homebrew-cask
brew 'node'
brew 'nodenv'
brew 'postgres', restart_service: :changed
brew 'tmux'
brew 'vim'
brew 'zsh'

# Docker & Kubernetes
brew 'docker'
brew 'kubectl'

# Security
brew 'gnupg'
brew 'gnupg2'
brew 'gnutls'
cask 'keybase' # tap homebrew-cask
brew 'pinentry-mac'

# Clojure
cask 'adoptopenjdk8' # tap AdoptOpenJDK/openjdk
brew 'boot-clj'
brew 'planck'
brew 'leiningen'
brew 'borkdude/brew/clj-kondo'

# JavaScript
brew 'jslint4java'
cask 'phantomjs' # tap homebrew-cask
brew 'v8'

# Ruby
brew 'rbenv'
brew 'ruby-build'
# ruby-build suggests using these
brew 'openssl'
brew 'readline'

# Unix
brew 'ack'
brew 'autoenv'
brew 'curl'
brew 'httpie'
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
cask 'macdown' # tap homebrew-cask
cask 'spotify' # tap homebrew-cask
cask 'vlc' # tap homebrew-cask
