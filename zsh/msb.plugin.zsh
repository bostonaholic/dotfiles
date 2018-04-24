### ALIASES ###

# CLI
alias ..="cd .."
alias la="ls -lha"

alias date_seconds="date +%s"
alias rand="date | md5"

alias camera_restart="sudo killall VDCAssistant"

alias ip="curl https://www.icanhazip.com"

# Docker
alias dk=docker-compose

# Emacs
alias e="emacs $*"
alias ed="emacs --debug-init $*"
alias et="emacsclient --tty $*" # open a new Emacs frame on the current terminal
alias ec="emacsclient --create-frame $*" # create a new frame instead of trying to use the current Emacs frame

# Ruby
alias bu="bundle update $*"
alias bundle_close="bundle exec gem pristine $*"
alias fs="foreman start $*"
alias ms="middleman server $*"
alias mb="middleman build $*"

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

function show_env_var() { echo "$1=`printenv $1`" }

function set_env_var() {
    export $1=$2
    show_env_var $1
}
