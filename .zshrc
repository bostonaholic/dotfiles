local DOTFILES="dotfiles"
local DOTFILES_PATH="$(dirname ~/code/$DOTFILES)/$DOTFILES"

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
export GREP_OPTIONS="--color"

# Add paths
export PATH=/usr/local/bin:/usr/local/sbin:$PATH # homebrew
export PATH=/usr/local/heroku/bin:$PATH # heroku toolbelt
export PATH=$HOME/bin:$PATH # user bin overrides

# Default CLI editor
export EDITOR=vim

# To enable rbenv shims and autocompletion
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

# Load all .zsh config files
for config_file ($DOTFILES_PATH/lib/*.zsh); do
  source $config_file
done

# Save PATH to go back to later
ORIGINAL_PATH=$PATH
