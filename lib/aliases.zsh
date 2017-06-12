function aliaz {
  alias $1="echo $2 && $2"
}

# CLI
alias ..="cd .."
alias la="ls -lha"

alias mci="mvn clean install $*"

alias gpg=gpg2

alias date_seconds="date +%s"

# Docker
alias dk=docker-compose

# Emacs
alias e="emacs $*"
alias ed="emacs --debug-init $*"
alias et="emacsclient --tty $*" # open a new Emacs frame on the current terminal
alias ec="emacsclient --create-frame $*" # create a new frame instead of trying to use the current Emacs frame

# Git
alias gti=git

# Ruby
alias be="bundle exec $*"
alias bi="bundle install $*"
alias bu="bundle update $*"
alias bundle_close="bundle exec gem pristine $*"
alias fs="foreman start $*"
alias ms="middleman server $*"
alias mb="middleman build $*"

# rbenv
alias ri="cat .ruby-version | rbenv install"
alias rr="rbenv rehash $*"
alias rv="ruby --version $*"

# Clojure
alias clj="lein repl $*"
alias cljs="planck $*"

# Homebrew
function brew_command {
    echo "\n==> brew $1\n" && brew $1
}

alias brewup="brew_command update &&
              brew_command upgrade &&
              brew_command doctor &&
              brew_command outdated &&
              brew_command cleanup"
