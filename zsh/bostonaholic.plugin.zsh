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

alias π="pi"

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

# Git worktree wrapper - intercepts subcommands that should cd
function wt() {
    # Pass --help/-h straight through without capturing output
    for arg in "$@"; do
        if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
            command wt "$@"
            return
        fi
    done

    case "$1" in
        main|new|add|cd)
            local worktree_path
            if worktree_path=$(command wt "$@") && [ -d "$worktree_path" ]; then
                builtin cd "$worktree_path" || return
            else
                return $?
            fi
            ;;
        rm)
            local root_path
            root_path=$(command wt _root 2>/dev/null)
            command wt "$@" || return
            # cd out if the worktree we were in was just removed
            if ! [[ -d "$PWD" ]]; then
                builtin cd "$root_path" 2>/dev/null || builtin cd ~ || return
            fi
            ;;
        *)
            command wt "$@"
            ;;
    esac
}

# Completion for wt command
function _wt() {
    local -a subcommands
    subcommands=(
        'main:Enter main worktree'
        'new:Create worktree for a new branch'
        'add:Create worktree for an existing branch'
        'rm:Remove a worktree'
        'ls:List all worktrees'
        'cd:Enter a worktree by name'
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
            local root
            case ${words[2]} in
                rm)
                    if root=$(command wt _root 2>/dev/null); then
                        local -a worktrees flags
                        worktrees=(${(f)"$(git -C "$root" worktree list --porcelain 2>/dev/null | awk -v prefix="$root/.worktrees/" '
                            /^worktree / {
                                path = substr($0, 10)
                                if (index(path, prefix) == 1) {
                                    print substr(path, length(prefix) + 1)
                                }
                            }
                        ')"})
                        flags=(
                            '--keep-branch:Keep the local branch'
                            '-f:Force removal even with modifications'
                            '--force:Force removal even with modifications'
                        )
                        _describe -t worktrees 'worktree' worktrees
                        _describe -t flags 'option' flags
                    fi
                    ;;
                cd|path)
                    if root=$(command wt _root 2>/dev/null); then
                        local -a worktrees
                        worktrees=(${(f)"$(git -C "$root" worktree list --porcelain 2>/dev/null | awk -v prefix="$root/.worktrees/" '
                            /^worktree / {
                                path = substr($0, 10)
                                if (index(path, prefix) == 1) {
                                    print substr(path, length(prefix) + 1)
                                }
                            }
                        ')"})
                        _describe -t worktrees 'worktree' worktrees
                    fi
                    ;;
                add)
                    if git rev-parse --git-dir &>/dev/null; then
                        local -a all_branches
                        all_branches=(${(f)"$(git branch -a --format='%(refname:short)' 2>/dev/null | sed 's|^origin/||' | sort -u)"})
                        _describe -t branches 'branch' all_branches
                    fi
                    ;;
                new)
                    # Second arg is start-point (branch/tag/ref)
                    if [[ $CURRENT -eq 4 ]] && git rev-parse --git-dir &>/dev/null; then
                        local -a all_branches
                        all_branches=(${(f)"$(git branch -a --format='%(refname:short)' 2>/dev/null | sed 's|^origin/||' | sort -u)"})
                        _describe -t branches 'start-point' all_branches
                    fi
                    ;;
                prune)
                    local -a flags
                    flags=(
                        '-n:Show what would be removed without removing'
                        '--dry-run:Show what would be removed without removing'
                        '-v:Report pruned worktree references'
                        '--verbose:Report pruned worktree references'
                        '--expire:Only prune entries older than given time'
                    )
                    _describe -t flags 'option' flags
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
