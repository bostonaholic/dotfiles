export PATH=$HOME/dotfiles/bin:$PATH

### ALIASES ###

# --quit-if-one-screen causes it to quit if the content is less than one screen
#   however after doing so the screen is reset and you end up not seeing the content
# --no-init does away with that behavior
export LESS="--quit-if-one-screen --no-init $LESS"

# Do not store commands in the bash history that start with a space
export HISTCONTROL=ignorespace

# CLI
alias ..="cd .."

# Claude with fallback: tries claude-swarm first, falls back to normal claude if it fails
alias claude="claude --dangerously-skip-permissions"
alias cc="claude"

alias rgrep="grep --recursive"

alias date_seconds="date +%s"
alias rand="date | md5"

alias camera_restart="sudo killall VDCAssistant"

alias ip="curl https://icanhazip.com"

alias iso8601_date="date +%Y-%m-%dT%H:%M:%S%z"

alias upcase="tr '[:lower:]' '[:upper:]'"
alias downcase="tr '[:upper:]' '[:lower:]'"

# Modern CLI tools
alias cat="bat --style=plain --paging=never"
alias df="duf --sort size"
alias du="dua"
alias find="fd"
alias grep="rg"
alias lg="lazygit"
alias ls="eza --all --group-directories-first --icons --no-quotes --tree --level 1"
alias man="tldr"
alias ping="gping"
alias top="btop"

# Git
alias gti=git

# Git worktree wrapper - handles 'cd' subcommand specially
function wt() {
    if [ "$1" = "cd" ]; then
        if [ -z "$2" ]; then
            command wt cd
            return $?
        fi
        local worktree_path
        if worktree_path=$(command wt cd "$2") && [ -d "$worktree_path" ]; then
            builtin cd "$worktree_path" || return
        fi
    else
        command wt "$@"
    fi
}

# Completion for wt command (fzf-tab will automatically use fzf)
function _wt() {
    local -a subcommands
    subcommands=(
        'add:Create a new worktree'
        'ls:List all worktrees'
        'rm:Remove a worktree'
        'cd:Change to worktree directory'
        'path:Show path to a worktree'
        'prune:Clean up stale worktree references'
        'help:Show help'
    )

    _arguments -C \
        '1: :->command' \
        '*: :->args'

    case $state in
        command)
            _describe -t commands 'wt command' subcommands
            ;;
        args)
            case ${words[2]} in
                cd|rm|path)
                    # List worktree branches for completion
                    local -a branches
                    if git rev-parse --git-dir &>/dev/null; then
                        branches=(${(f)"$(git worktree list --porcelain 2>/dev/null | awk '/^branch / { br = substr($0, 8); gsub(/^refs\/heads\//, "", br); print br }')"})
                        _describe -t branches 'worktree branch' branches
                    fi
                    ;;
                add)
                    # For add, complete with all branches (local and remote)
                    local -a all_branches
                    if git rev-parse --git-dir &>/dev/null; then
                        all_branches=(${(f)"$(git branch -a --format='%(refname:short)' 2>/dev/null | sed 's|^origin/||' | sort -u)"})
                        _describe -t branches 'branch' all_branches
                    fi
                    ;;
            esac
            ;;
    esac
}

compdef _wt wt

# Ruby
function bundle_close() {
    bundle exec gem pristine "$*"
}

# Python
alias python=python3

# Clojure
function cljs() {
    planck "$*"
}
