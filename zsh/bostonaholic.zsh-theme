local ret_status="%(?:%{$fg_bold[green]%}> :%{$fg_bold[red]%}> )"
PROMPT=' ${ret_status} %{$fg[cyan]%}%2~%{$reset_color%} $(git_prompt_info)'

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$fg[blue]%})%{$reset_color%} "

ZSH_THEME_NODE_PROMPT_PREFIX="("
ZSH_THEME_NODE_PROMPT_SUFFIX=")"