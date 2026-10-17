#!/bin/bash
#
# Fresh-machine bootstrap. Clones the dotfiles repo and runs install.sh.
#
#   curl init.bostonaholic.dev | bash
#   curl -fsSL https://init.bostonaholic.dev | bash -s -- --minimal
#
# Everything lives inside main() and is called on the last line, so a truncated
# download or an error page from the host can never run half of this.
set -euo pipefail

main() {
  local REPO_URL="${DOTFILES_REPO:-https://github.com/bostonaholic/dotfiles.git}"
  local REPO_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
  local BRANCH="${DOTFILES_BRANCH:-main}"

  local COMPONENTS="symlinks,homebrew,npm,pipx,uv,claude,scripts"
  local INSTALL_ARGS=()

  usage() {
    cat <<'USAGE'
Usage: curl init.bostonaholic.dev | bash -s -- [options]

  --minimal      Only clone and create symlinks (no packages, no plugins, no scripts)
  --no-apps      Skip Homebrew packages
  --no-plugins   Skip Claude Code plugins
  --dir PATH     Clone into PATH (default: ~/dotfiles)
  -n, --dry-run  Clone, then preview install.sh without making changes
  -y, --yes      Answer yes to all install.sh prompts
  -h, --help     Show this help

Environment: DOTFILES_REPO, DOTFILES_DIR, DOTFILES_BRANCH override the defaults.
USAGE
  }

  without() { # without LIST ITEM -> LIST minus ITEM
    local list=",$1,"
    list="${list//,$2,/,}"
    list="${list#,}"
    echo "${list%,}"
  }

  while [ $# -gt 0 ]; do
    case "$1" in
      --minimal)    COMPONENTS="symlinks" ;;
      --no-apps)    COMPONENTS="$(without "$COMPONENTS" homebrew)" ;;
      --no-plugins) COMPONENTS="$(without "$COMPONENTS" claude)" ;;
      --dir)        REPO_DIR="${2:?--dir needs a path}"; shift ;;
      -n|--dry-run) INSTALL_ARGS+=(--dry-run) ;;
      -y|--yes)     INSTALL_ARGS+=(--yes) ;;
      -h|--help)    usage; return 0 ;;
      *)            echo "Unknown option: $1" >&2; usage >&2; return 1 ;;
    esac
    shift
  done

  if [ "$(uname -s)" != "Darwin" ]; then
    echo "This bootstrap expects a macOS machine." >&2
    return 1
  fi

  # Piped into bash, stdin is the script itself, so install.sh and Homebrew
  # prompts would read garbage. Point stdin back at the terminal.
  if [ ! -t 0 ] && { : </dev/tty; } 2>/dev/null; then
    exec </dev/tty
  fi

  # On a fresh Mac, git is a stub until the Command Line Tools are installed.
  if ! xcode-select -p >/dev/null 2>&1; then
    echo "==> Installing Xcode Command Line Tools..."
    xcode-select --install || true
    echo "Finish the Command Line Tools installer, then re-run this command." >&2
    return 1
  fi

  if [ -d "$REPO_DIR/.git" ]; then
    echo "==> Updating $REPO_DIR..."
    git -C "$REPO_DIR" pull --ff-only
  elif [ -e "$REPO_DIR" ]; then
    echo "$REPO_DIR exists and is not a git checkout. Move it or pass --dir." >&2
    return 1
  else
    echo "==> Cloning into $REPO_DIR..."
    git clone --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
  fi

  echo ""
  # install.sh honors an inherited DOTFILES_DIR, so pin it to this checkout.
  DOTFILES_DIR="$REPO_DIR" "$REPO_DIR/install.sh" --only "$COMPONENTS" ${INSTALL_ARGS[@]+"${INSTALL_ARGS[@]}"}

  echo ""
  echo "Bootstrap complete. Repo at $REPO_DIR"
}

main "$@"
