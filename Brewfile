# frozen_string_literal: true

# How to use the Brewfile
#
# $ brew tap homebrew/bundle
# $ brew bundle
#

# Taps
tap 'caskroom/cask'
tap 'caskroom/versions'
tap 'AdoptOpenJDK/openjdk'
tap 'd12frosted/emacs-plus'

# Browsers
cask 'firefox'

# Programming
brew 'aspell'
brew 'cloc'
brew 'emacs-plus',
     args: ['with-ctags'],
     restart_service: :changed
brew 'git'
brew 'libyaml'
cask 'ngrok'
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
cask 'keybase'
brew 'pinentry-mac'

# Clojure
cask 'grenchman'
cask 'adoptopenjdk8'
brew 'boot-clj'
brew 'planck'
brew 'leiningen'
brew 'borkdude/brew/clj-kondo'

# JavaScript
brew 'jslint4java'
cask 'phantomjs'
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
cask 'macdown'
cask 'spotify'
cask 'vlc'
