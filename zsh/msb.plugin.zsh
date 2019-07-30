export PATH=:~/code/bostonaholic/dotfiles/bin:~/code/circleci/ops-tools/bin:~/code/circleci/scripts/bin:$PATH

EDITOR=vi

### ALIASES ###

# --quit-if-one-screen causes it to quit if the content is less than one screen
# however after doing so the screen is reset and you end up not seeing the content
# --no-init does away with that behavior
export LESS="--quit-if-one-screen --no-init $LESS"

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
alias de="emacs --debug-init $*"

# Ruby
alias bu="bundle update $*"
alias bundle_close="bundle exec gem pristine $*"
alias fs="foreman start $*"
alias ms="middleman server $*"
alias mb="middleman build $*"

# Clojure
alias clj="lein repl $*"
alias cljs="planck $*"

function show_env_var() { echo "$1=`printenv $1`" }

function set_env_var() {
    export $1=$2
    show_env_var $1
}
