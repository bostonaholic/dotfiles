#!/bin/bash
# shellcheck disable=SC1087,SC2016,SC2034,SC2154,SC2168

##
# Git Prompt Support
# https://github.com/git/git/blob/master/contrib/completion/git-prompt.sh
##
GIT_PS1_SHOWDIRTYSTATE=1      # display working directory state (* for modified/+ for staged)
GIT_PS1_SHOWSTASHSTATE=1      # display stashed state ($ if there are stashed files)
GIT_PS1_SHOWUNTRACKEDFILES=1  # display untracked state (% if there are untracked files)
GIT_PS1_SHOWUPSTREAM=auto     # display HEAD vs upstream state (< for behind, > for ahead, <> for diverged, = for no difference)
GIT_PS1_DESCRIBE_STYLE=branch # detached-head description

GIT_PS1_STATESEPARATOR=" "    # separator between branch name and dirty state symbols
GIT_PS1_SHOWCOLORHINTS=1      # display colored hints about the current dirty state
GIT_PS1_HIDE_IF_PWD_IGNORED=  # do nothing if pwd is ignored by git
GIT_PS1_SHOWCONFLICTSTATE=yes # show when there are unresolved conflicts

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[white]%}git:(%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$fg[white]%})%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="*"
ZSH_THEME_GIT_PROMPT_CLEAN=""

ZSH_THEME_RUBY_PROMPT_PREFIX="%{$fg[red]%}ruby:%{$reset_color%}("
ZSH_THEME_RUBY_PROMPT_SUFFIX="%{$fg[white]%})%{$reset_color%} "

ZSH_THEME_NODE_PROMPT_PREFIX="%{$fg[green]%}node:%{$reset_color%}("
ZSH_THEME_NODE_PROMPT_SUFFIX="%{$fg[white]%})%{$reset_color%} "

function git_prompt_info() {
  __git_ps1 "${ZSH_THEME_GIT_PROMPT_PREFIX//\%/%%}%s${ZSH_THEME_GIT_PROMPT_SUFFIX//\%/%%}"
}

local ret_status="%(?:%{$fg[green]%}$ :%{$fg[red]%}$ )"

PROMPT='${ret_status}%{$fg[cyan]%}%2~%{$reset_color%} $(git_prompt_info)'
