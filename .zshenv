# user scripts
export PATH=$HOME/bin:$PATH

# homebrew
export PATH=/usr/local/bin:/usr/local/sbin:$PATH

# rbenv
eval "$(rbenv init -)"

# nvm
export NVM_DIR="$HOME/.nvm"
. "/usr/local/opt/nvm/nvm.sh"

export EDITOR=vim
export GREP_OPTIONS="--color"
export GPG_TTY=$(tty)
