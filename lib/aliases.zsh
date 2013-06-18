# CLI
alias ..="cd .."
alias la="ls -lha"
alias p="pygmentize $*"
alias reload="source ~/.zshrc"
alias rl="reload"

# Git
eval "$(hub alias -s)" # alias git='hub $*'
alias gs="git status $*"
alias gd="git diff $*"
alias gr="git remote -v $*"

# Ruby
alias bi="bundle install $*"
alias be="bundle exec $*"
alias fs="foreman start $*"

# Rails
alias t="script/test $*"
alias f="script/features $*"
alias z="zeus $*"

