# superseded by oh-my-zsh

local DOTFILES="dotfiles"
local DOTFILES_PATH="$(dirname ~/code/bostonaholic/$DOTFILES)/$DOTFILES"

# Set custom prompt
setopt PROMPT_SUBST
autoload -U promptinit
promptinit

# Initialize completion
autoload -U compinit
compinit

# Colorize terminal
autoload -U colors
colors
alias ls='ls -G'

# Load all .zsh config files
for config_file ($DOTFILES_PATH/lib/*.zsh); do
  source $config_file
done
