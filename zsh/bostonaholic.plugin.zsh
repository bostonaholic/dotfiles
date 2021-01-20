export PATH=$HOME/code/dotfiles/bin:$PATH

EDITOR=vi

### ALIASES ###

alias vi=vim

# --quit-if-one-screen causes it to quit if the content is less than one screen
#   however after doing so the screen is reset and you end up not seeing the content
# --no-init does away with that behavior
export LESS="--quit-if-one-screen --no-init $LESS"

# CLI
alias ..="cd .."

alias rgrep="grep --recursive"

alias date_seconds="date +%s"
alias rand="date | md5"

alias camera_restart="sudo killall VDCAssistant"

alias ip="curl https://icanhazip.com"

alias iso8601_date="date +%Y-%m-%dT%H:%M:%S%z"

# Git
alias gti=git

# Ruby
alias bundle_close="bundle exec gem pristine $*"

# Clojure
#alias clj="lein repl $*"
alias cljs="planck $*"
