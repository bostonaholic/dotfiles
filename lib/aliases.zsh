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
alias e="emacs $*"
alias ed="emacs --debug-init $*"
alias et="emacsclient --tty $*" # open a new Emacs frame on the current terminal
alias ec="emacsclient --create-frame $*" # create a new frame instead of trying to use the current Emacs frame
alias gpg=gpg2

# Git
alias gti=git

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
alias lnr="lineman run $*"
alias lns="lineman spec $*"
alias lnb="lineman build $*"

# Clojure
alias clj="lein repl $*"

# Homebrew
alias brewup="echo '==> brew update\n' && brew update && echo '\n==> brew doctor\n' && brew doctor && echo '\n==> brew outdated\n' && brew outdated && echo '\n==> brew cleanup\n' && brew cleanup"
