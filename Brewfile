# frozen_string_literal: true

# How to use the Brewfile
#
# $ brew tap homebrew/bundle
# $ brew bundle
#

tap 'caskroom/cask'
tap 'caskroom/versions'
tap 'AdoptOpenJDK/openjdk'

# Browsers
cask 'google-chrome'
cask 'google-chrome-canary'
cask 'firefox'
# cask 'firefox-beta'
cask 'firefoxdeveloperedition'
cask 'safari-technology-preview'

# Programming
brew 'aspell'
brew 'cloc'
brew 'emacs',
     args: ['with-cocoa', 'with-ctags', 'with-gnutls',
            'with-librsvg', 'with-imagemagick@6'],
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
cask 'spotify'
cask 'vlc'
