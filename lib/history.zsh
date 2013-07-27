# Locate the history file
if [ -z $HISTFILE ]; then
  HISTFILE=$HOME/.zsh_history
fi
HISTSIZE=200
SAVEHIST=200

setopt APPEND_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt INC_APPEND_HISTORY
