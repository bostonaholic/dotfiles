function aliaz {
  alias $1="echo $2 && $2"
}

# CLI
alias ..="cd .."
alias la="ls -lha"
alias p="pygmentize $*"
alias reload="source ~/.zshrc"
alias rl="reload"
alias mci="mvn clean install $*"

# Git
if which hub > /dev/null; then eval "$(hub alias -s)"; fi # alias git='hub $*'
alias ga="git add "
alias gaa="git add --all "
alias gap="git add --patch "
alias gb="git branch "
alias gba="git branch --all "
alias gd="git diff "
alias gdc="git diff --cached "
alias gfa="git fetch --all "
alias gp="git push "
alias gr="git remote --verbose "
alias gs="git status "

# Ruby
alias be="bundle exec $*"
alias bi="bundle install $*"
alias bu="bundle update $*"
alias bundle_close="bundle exec gem pristine $*"
alias fs="foreman start $*"
alias ms="middleman server $*"
alias mb="middleman build $*"
alias ri="cat .ruby-version | rbenv install"
alias rr="rbenv rehash $*"
alias rv="ruby --version $*"

# Rails
alias f="script/features $*"
alias t="script/test $*"
alias z="zeus $*"

# Lineman
alias lr="lineman run $*"
alias lb="lineman build $*"

# Clojure
alias clj="lein repl $*"
