#!/bin/bash
# Status line for Claude Code

# Claude Code Status Line Script
# Provides git-aware status display with context window tracking

# Read JSON input once from stdin
input=$(cat)

# Helper functions for common extractions
get_model_name() { echo "$input" | jq -r '.model.display_name // "unknown"'; }
get_current_dir() { echo "$input" | jq -r '.workspace.current_dir'; }
get_project_dir() { echo "$input" | jq -r '.workspace.project_dir'; }
get_version() { echo "$input" | jq -r '.version'; }
get_cost() { echo "$input" | jq -r '.context_window.total_cost_usd // null'; }
get_duration() { echo "$input" | jq -r '.cost.total_duration_ms'; }
get_lines_added() { echo "$input" | jq -r '.cost.total_lines_added'; }
get_lines_removed() { echo "$input" | jq -r '.cost.total_lines_removed'; }
get_input_tokens() { echo "$input" | jq -r '.context_window.total_input_tokens'; }
get_output_tokens() { echo "$input" | jq -r '.context_window.total_output_tokens'; }
get_context_window_size() { echo "$input" | jq -r '.context_window.context_window_size // 0'; }
get_output_style() { echo "$input" | jq -r '.output_style.name // ""'; }
get_current_usage() { echo "$input" | jq '.context_window.current_usage // {}'; }

# Git-aware directory display
get_directory_display() {
    local cwd
    cwd=$(get_current_dir)
    local dir="$cwd"

    # Handle home directory
    if [[ "$dir" == "$HOME" ]]; then
        echo "~"
        return
    elif [[ "$dir" == "$HOME"/* ]]; then
        dir="~${dir#"$HOME"}"
    fi

    # If in a git repo, show relative to repo root
    if git -C "$cwd" -c core.fileMode=false rev-parse --git-dir >/dev/null 2>&1; then
        local git_root
        git_root=$(git -C "$cwd" -c core.fileMode=false rev-parse --show-toplevel 2>/dev/null)
        local repo_name
        repo_name=$(basename "$git_root")
        local rel_path="${cwd#"$git_root"}"

        if [[ -z "$rel_path" ]]; then
            echo "$repo_name"
        else
            echo "$repo_name$rel_path"
        fi
    else
        # Not in git repo, show last two path components
        echo "$dir" | awk -F'/' '{n=NF; if(n<=2) print $0; else print $(n-1)"/"$n}'
    fi
}

# Git status information with branch, dirty status, and ahead commits
get_git_info() {
    local cwd
    cwd=$(get_current_dir)

    if ! git -C "$cwd" -c core.fileMode=false rev-parse --git-dir >/dev/null 2>&1; then
        return
    fi

    local branch
    branch=$(git -C "$cwd" -c core.fileMode=false symbolic-ref --short HEAD 2>/dev/null || echo "detached")
    local dirty=""

    # Check for uncommitted changes
    if ! git -C "$cwd" -c core.fileMode=false diff --quiet 2>/dev/null || \
       ! git -C "$cwd" -c core.fileMode=false diff --cached --quiet 2>/dev/null; then
        dirty="*"
    fi

    # Check for unpushed commits
    local ahead
    ahead=$(git -C "$cwd" -c core.fileMode=false rev-list '@{u}..HEAD' 2>/dev/null | wc -l | tr -d ' ')
    local ahead_marker=""
    [[ "$ahead" -gt 0 ]] && ahead_marker="↑$ahead"

    printf " 🌿 \033[90m(\033[33m%s%s%s\033[90m)\033[0m" "$branch" "$dirty" "$ahead_marker"
}

# Context window usage with progress bar
get_context_display() {
    local ctx_size
    ctx_size=$(get_context_window_size)
    local usage
    usage=$(get_current_usage)

    if [[ "$usage" == "null" ]] || [[ "$usage" == "{}" ]]; then
        echo ""
        return
    fi

    local input_tokens
    input_tokens=$(echo "$usage" | jq '.input_tokens // 0')
    local cache_creation
    cache_creation=$(echo "$usage" | jq '.cache_creation_input_tokens // 0')
    local cache_read
    cache_read=$(echo "$usage" | jq '.cache_read_input_tokens // 0')
    local tokens=$((input_tokens + cache_creation + cache_read))

    if [[ $ctx_size -eq 0 ]]; then
        echo ""
        return
    fi

    local ctx=$((tokens * 100 / ctx_size))
    local filled=$((ctx / 10))
    local empty=$((10 - filled))

    # Build progress bar
    local bar=""
    for ((i=0; i<filled; i++)); do bar="${bar}█"; done
    for ((i=0; i<empty; i++)); do bar="${bar}░"; done

    # Color based on usage (auto-compact triggers at ~80%)
    local ctx_color="\033[37m"  # white (0-40%)
    [[ $ctx -gt 40 ]] && ctx_color="\033[33m"  # yellow (41-70%)
    [[ $ctx -gt 70 ]] && ctx_color="\033[31m"  # red (71%+, approaching auto-compact)

    printf " 🧠 ${ctx_color}[%s %d%%]\033[0m" "$bar" "$ctx"
}

# Cost tracking display
get_cost_display() {
    local total_cost
    total_cost=$(get_cost)

    if [[ "$total_cost" == "null" ]] || [[ -z "$total_cost" ]]; then
        echo ""
        return
    fi

    local cost_formatted
    cost_formatted=$(printf "%.4f" "$total_cost")
    printf " 💰 \033[33m\$%s\033[0m" "$cost_formatted"
}

# Output style indicator
get_style_display() {
    local style
    style=$(get_output_style)

    if [[ -n "$style" ]] && [[ "$style" != "default" ]]; then
        printf " 🎨 \033[36m[%s]\033[0m" "$style"
    fi
}

# Main status line assembly
main() {
    local model
    model=$(get_model_name)
    local dir_display
    dir_display=$(get_directory_display)
    local git_info
    git_info=$(get_git_info)
    local context
    context=$(get_context_display)
    local cost
    cost=$(get_cost_display)
    local style
    style=$(get_style_display)

    # Assemble and print status line
    printf "📁 \033[36m%s\033[0m%s%s%s%s ⚡ \033[35m%s\033[0m" \
        "$dir_display" \
        "$git_info" \
        "$context" \
        "$cost" \
        "$style" \
        "$model"
}

# Run main function
main
