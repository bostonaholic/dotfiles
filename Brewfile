# frozen_string_literal: true

# How to use the Brewfile
#
# $ brew tap homebrew/bundle
# $ brew bundle
#

tap 'caskroom/cask'
tap 'caskroom/versions'

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
brew "emacs", args: ["with-cocoa", "with-ctags", "with-gnutls", "with-librsvg", "with-imagemagick@6"], restart_service: :changed
brew 'git'
brew 'libyaml'
cask 'ngrok'
brew 'node'
brew 'nodenv'
cask 'paw'
brew 'postgres', restart_service: :changed
brew 'tmux'
brew 'vim'
brew 'wireshark', args: ['with-qt']
cask 'wireshark-chmodbpf'
brew 'zsh'

# docker
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
cask 'java8'
brew 'boot-clj'
brew 'planck'
brew 'leiningen'

# JavaScript
brew 'jslint4java'
brew 'phantomjs'
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
brew 'rlwrap'
brew 'the_silver_searcher'
brew 'tree'

# Other
brew 'awscli'
brew 'coreutils'
brew 'dfu-util'
brew 'graphviz'
brew 'ossp-uuid'
cask 'spotify'
brew 'watchman'
cask 'vlc'
