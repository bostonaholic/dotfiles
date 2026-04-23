#!/usr/bin/env bash
# Status line for Claude Code - Bash implementation
#
# Example output:
#   📁 dotfiles 🌿 (main *↑2) 🧠 [████░░░░░░ 35%] 💰 $0.1234 ⚡ Opus 4.5
#
# Usage:
#   echo '{"workspace":...}' | ./statusline.sh

set -euo pipefail

# ANSI Colors
RESET="\033[0m"
RED="\033[31m"
YELLOW="\033[33m"
CYAN="\033[36m"
MAGENTA="\033[35m"
GRAY="\033[90m"
WHITE="\033[37m"

colorize() {
  local color="$1" text="$2"
  printf '%b%s%b' "$color" "$text" "$RESET"
}

# Read JSON from stdin
INPUT=$(cat)

# JSON helpers using jq
jq_raw() { echo "$INPUT" | jq -r "$1 // empty"; }
jq_num() { echo "$INPUT" | jq "$1 // 0"; }

# Data extraction
get_model_name() { jq_raw '.model.display_name'; }
get_current_dir() { jq_raw '.workspace.current_dir'; }
get_cost() { jq_raw '.context_window.total_cost_usd'; }
get_context_window_size() { jq_num '.context_window.context_window_size'; }
get_output_style() { jq_raw '.output_style.name'; }
get_input_tokens() { jq_num '.context_window.current_usage.input_tokens'; }
get_cache_creation() { jq_num '.context_window.current_usage.cache_creation_input_tokens'; }
get_cache_read() { jq_num '.context_window.current_usage.cache_read_input_tokens'; }

# Git helpers
git_repo() {
  git -C "$1" rev-parse --git-dir >/dev/null 2>&1
}

get_git_info() {
  local cwd="$1"
  git_repo "$cwd" || return 1

  GIT_ROOT=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || echo "")
  GIT_NAME=$(basename "$GIT_ROOT")
  GIT_BRANCH=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || echo "detached")

  GIT_DIRTY=""
  if ! git -C "$cwd" diff --quiet 2>/dev/null || ! git -C "$cwd" diff --cached --quiet 2>/dev/null; then
    GIT_DIRTY="*"
  fi

  GIT_AHEAD=0
  local ahead_output
  if ahead_output=$(git -C "$cwd" rev-list "@{u}..HEAD" 2>/dev/null); then
    if [[ -n "$ahead_output" ]]; then
      GIT_AHEAD=$(echo "$ahead_output" | wc -l | tr -d ' ')
    fi
  fi
}

# Formatting functions
format_project() {
  local cwd
  cwd=$(get_current_dir)
  local dir_name

  if [[ "$cwd" == "$HOME" ]]; then
    dir_name="~"
  elif [[ -n "${GIT_NAME:-}" ]]; then
    dir_name="$GIT_NAME"
  else
    # Last two path components
    dir_name=$(echo "$cwd" | awk -F/ '{print $(NF-1)"/"$NF}')
  fi

  printf '📁 %s' "$(colorize "$CYAN" "$dir_name")"
}

format_git_info() {
  [[ -z "${GIT_BRANCH:-}" ]] && return

  local branch_info="$GIT_BRANCH ${GIT_DIRTY}"
  if [[ "$GIT_AHEAD" -gt 0 ]]; then
    branch_info="${branch_info}↑${GIT_AHEAD}"
  fi

  printf ' 🌿 %s%s%s' \
    "$(colorize "$GRAY" "(")" \
    "$(colorize "$YELLOW" "$branch_info")" \
    "$(colorize "$GRAY" ")")"
}

format_context() {
  local ctx_size
  ctx_size=$(get_context_window_size)
  [[ "$ctx_size" -le 0 ]] && return

  local input_tokens cache_creation cache_read tokens pct filled empty bar color
  input_tokens=$(get_input_tokens)
  cache_creation=$(get_cache_creation)
  cache_read=$(get_cache_read)
  tokens=$((input_tokens + cache_creation + cache_read))
  pct=$((tokens * 100 / ctx_size))
  filled=$((pct / 10))
  empty=$((10 - filled))

  bar=""
  for ((i = 0; i < filled; i++)); do bar+="█"; done
  for ((i = 0; i < empty; i++)); do bar+="░"; done

  if [[ "$pct" -gt 70 ]]; then
    color="$RED"
  elif [[ "$pct" -gt 40 ]]; then
    color="$YELLOW"
  else
    color="$WHITE"
  fi

  printf ' 🧠 %s' "$(colorize "$color" "[${bar} ${pct}%]")"
}

format_cost() {
  local cost
  cost=$(get_cost)
  [[ -z "$cost" ]] && return

  printf ' 💰 %s' "$(colorize "$YELLOW" "$(printf '$%.4f' "$cost")")"
}

format_style() {
  local style
  style=$(get_output_style)
  [[ -z "$style" || "$style" == "default" ]] && return

  printf ' 🎨 %s' "$(colorize "$CYAN" "[${style}]")"
}

format_model() {
  local model
  model=$(get_model_name)
  [[ -z "$model" ]] && model="unknown"

  printf ' ⚡ %s' "$(colorize "$MAGENTA" "$model")"
}

INSPIRATIONAL_PHRASES=(
  "Build something people want today"
  "Simplicity is the ultimate sophistication"
  "Make it work then make beautiful"
  "Code is poetry in motion"
  "Ship early ship often ship well"
  "Clarity over cleverness always wins"
  "Design for humans code for machines"
  "Progress over perfection every time"
  "Small steps lead to big wins"
  "Fail fast learn faster succeed"
  "Complexity is the enemy of execution"
  "Constraints inspire the best solutions"
  "Done is better than perfect today"
)

format_inspiration() {
  local seed idx
  if [[ -n "${SESSION_ID:-}" ]]; then
    # Hash the session ID for a stable per-session phrase
    seed=$(echo -n "$SESSION_ID" | cksum | awk '{print $1}')
  else
    seed=$(date +%s)
  fi
  idx=$((seed % ${#INSPIRATIONAL_PHRASES[@]}))
  colorize "$GRAY" "${INSPIRATIONAL_PHRASES[$idx]}"
}

# Main
main() {
  local cwd
  cwd=$(get_current_dir)

  # Collect git info into globals
  GIT_ROOT="" GIT_NAME="" GIT_BRANCH="" GIT_DIRTY="" GIT_AHEAD=0
  if [[ -n "$cwd" ]]; then
    get_git_info "$cwd" 2>/dev/null || true
  fi

  printf '%s%s%s%s%s%s • %s\n' \
    "$(format_project)" \
    "$(format_git_info)" \
    "$(format_context)" \
    "$(format_cost)" \
    "$(format_style)" \
    "$(format_model)" \
    "$(format_inspiration)"
}

main
