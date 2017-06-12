# How to use the Brewfile
#
# $ brew tap homebrew/bundle
# $ brew bundle
#

tap "caskroom/cask"
tap "caskroom/versions"

# Browsers
cask "google-chrome"
cask "google-chrome-canary"
cask "firefox"
# cask "firefox-beta"
cask "firefoxdeveloperedition"
cask "safari-technology-preview"

# Programming
brew "aspell"
brew "cloc"
brew "emacs", args: ["with-cocoa", "with-ctags", "with-gnutls", "with-librsvg", "with-imagemagick"], restart_service: :changed
brew "git"
brew "libyaml"
brew "nginx", restart_service: :changed
cask "ngrok"
brew "node"
brew "nvm"
cask "paw"
brew "postgres", restart_service: :changed
brew "tmux"
brew "vim"
brew "wireshark", args: ["with-qt"]
brew "zsh"

# Security
brew "gnupg"
brew "gnupg2"
brew "gnutls"
brew "pinentry-mac"

# Clojure
cask "java"
brew "boot-clj"
brew "planck"
brew "leiningen"

# JavaScript
brew "jslint4java"
brew "phantomjs"
brew "v8"

# Ruby
brew "rbenv"
brew "ruby-build"
# ruby-build suggests using these
brew "openssl"
brew "readline"

# Unix
brew "autoenv"
brew "htop"
brew "rlwrap"
brew "the_silver_searcher"
brew "tree"

# Other
brew "awscli"
brew "coreutils"
brew "dfu-util"
brew "graphviz"
