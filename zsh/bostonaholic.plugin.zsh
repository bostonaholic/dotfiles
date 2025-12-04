#!/bin/bash

export PATH=$HOME/dotfiles/bin:$PATH

### ALIASES ###

# --quit-if-one-screen causes it to quit if the content is less than one screen
#   however after doing so the screen is reset and you end up not seeing the content
# --no-init does away with that behavior
export LESS="--quit-if-one-screen --no-init $LESS"

# Do not store commands in the bash history that start with a space
export HISTCONTROL=ignorespace

# CLI
alias ..="cd .."

# Claude with fallback: tries claude-swarm first, falls back to normal claude if it fails
function claude() {
    claude-swarm --vibe "$@" || command claude start --dangerously-skip-permissions "$@"
}

alias rgrep="grep --recursive"

alias date_seconds="date +%s"
alias rand="date | md5"

alias camera_restart="sudo killall VDCAssistant"

alias ip="curl https://icanhazip.com"

alias iso8601_date="date +%Y-%m-%dT%H:%M:%S%z"

alias upcase="tr '[:lower:]' '[:upper:]'"
alias downcase="tr '[:upper:]' '[:lower:]'"

# Git
alias gti=git

# Git worktree wrapper - handles 'cd' subcommand specially
function wt() {
    if [ "$1" = "cd" ]; then
        if [ -z "$2" ]; then
            command wt cd
            return $?
        fi
        local worktree_path
        worktree_path=$(command wt cd "$2")
        if [ $? -eq 0 ] && [ -d "$worktree_path" ]; then
            builtin cd "$worktree_path"
        fi
    else
        command wt "$@"
    fi
}

# Ruby
function bundle_close() {
    bundle exec gem pristine "$*"
}

# Python
alias python=python3

# Clojure
function cljs() {
    planck "$*"
}
