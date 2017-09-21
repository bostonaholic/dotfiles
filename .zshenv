# Save PATH to go back to later
ORIGINAL_PATH=$PATH

# user scripts
export PATH=$HOME/bin:$PATH

# homebrew
export PATH=/usr/local/bin:/usr/local/sbin:$PATH

# rbenv
eval "$(rbenv init -)"

# nodenv
eval "$(nodenv init -)"

export EDITOR=vim
export GREP_OPTIONS="--color"
export GPG_TTY=$(tty)
