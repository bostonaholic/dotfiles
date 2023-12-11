#!/bin/bash

export PATH=$HOME/code/dotfiles/bin:$PATH

export EDITOR=vi

### ALIASES ###

# --quit-if-one-screen causes it to quit if the content is less than one screen
#   however after doing so the screen is reset and you end up not seeing the content
# --no-init does away with that behavior
export LESS="--quit-if-one-screen --no-init $LESS"

# Do not store commands in the bash history that start with a space
export HISTCONTROL=ignorespace

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
function bundle_close() {
    bundle exec gem pristine "$*"
}

# Clojure
function cljs() {
    planck "$*"
}
