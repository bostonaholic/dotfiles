function aliaz {
  alias $1="echo $2 && $2"
}

# CLI
alias ..="cd .."
alias la="ls -lha"
alias p="pygmentize $*"
alias reload="source ~/.zshrc"
alias rl="reload"
alias v="mvim $*"
alias e="memacs $*"
alias mci="mvn clean install $*"

# Git
if which hub > /dev/null; then eval "$(hub alias -s)"; fi # alias git='hub $*'
alias ga="git add $*"
alias gd="git di $*"
alias gp="git push"
alias gr="git remote -v $*"
alias gs="git status $*"

# Ruby
alias be="bundle exec $*"
alias bi="bundle install $*"
alias bu="bundle update $*"
alias fs="foreman start $*"
alias ms="middleman server $*"
alias mb="middleman build $*"
alias ri="cat .ruby-version | rbenv install"
alias rr="rbenv rehash $*"

# Rails
alias f="script/features $*"
alias t="script/test $*"
alias z="zeus $*"
