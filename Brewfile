# frozen_string_literal: true

# How to use the Brewfile
#
# $ brew tap homebrew/bundle
# $ brew bundle
#

# Taps
tap 'AdoptOpenJDK/openjdk'
tap 'd12frosted/emacs-plus'
tap 'borkdude/brew'

# Programming
brew 'aspell'
brew 'cloc'
brew 'emacs-plus', # tap d12frosted/emacs-plus
     args: ['with-ctags', 'with-spacemacs-icon'],
     restart_service: :changed
brew 'git'
brew 'libyaml'
cask 'ngrok' # tap homebrew-cask
brew 'node'
brew 'nodenv'
brew 'tmux'
brew 'vim'
brew 'zsh'

# Security
brew 'gnupg'
brew 'gnupg2'
brew 'gnutls'
cask 'keybase' # tap homebrew-cask
brew 'pinentry-mac'

# Clojure
cask 'adoptopenjdk11' # tap AdoptOpenJDK/openjdk
brew 'boot-clj'
brew 'planck'
brew 'leiningen'
cask 'clj-kondo'

# JavaScript
brew 'jslint4java'

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
brew 'htop'
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
cask 'vlc' # tap homebrew-cask
