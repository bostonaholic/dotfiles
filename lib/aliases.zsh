function aliaz {
  alias $1="echo $2 && $2"
}

# CLI
aliaz .. "cd .."
aliaz la "ls -lha"
aliaz p "pygmentize $*"
aliaz reload "source ~/.zshrc"
aliaz rl "reload"

# Git
eval "$(hub alias -s)" # alias git='hub $*'
aliaz gs "git status $*"
aliaz gd "git diff $*"
aliaz gr "git remote -v $*"

# Ruby
aliaz bi "bundle install $*"
aliaz be "bundle exec $*"
aliaz fs "foreman start $*"
aliaz rr "rbenv rehash $*"

# Rails
aliaz t "script/test $*"
aliaz f "script/features $*"
aliaz z "zeus $*"
