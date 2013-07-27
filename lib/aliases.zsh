function aliaz {
  alias $1="echo $2 && $2"
}

# CLI
aliaz .. "cd .."
aliaz la "ls -lha"
aliaz p "pygmentize $*"
aliaz reload "source ~/.zshrc"
aliaz rl "reload"
alias sudo="sudo " # allow running sudo against an alias
aliaz redo '`\history -n | tail -n1`' # run last command again
aliaz now "sudo redo" # I meant sudo on that last command
alias e="emacs $*"

# Git
if which hub > /dev/null; then eval "$(hub alias -s)"; fi # alias git='hub $*'
aliaz gs "git status $*"
aliaz gd "git diff $*"
aliaz gr "git remote -v $*"
aliaz gp "git push"

# Ruby
aliaz bi "bundle install $*"
aliaz be "bundle exec $*"
aliaz bu "bundle update $*"
aliaz fs "foreman start $*"
aliaz rr "rbenv rehash $*"
aliaz ri "cat .ruby-version | rbenv install"

# Rails
aliaz t "script/test $*"
aliaz f "script/features $*"
aliaz z "zeus $*"
