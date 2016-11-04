# Add paths
export PATH=/usr/local/bin:/usr/local/sbin:$PATH # homebrew
export PATH=$HOME/bin:$PATH # user bin overrides

# To enable rbenv shims and autocompletion
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

# Default CLI editor
export EDITOR=vim
