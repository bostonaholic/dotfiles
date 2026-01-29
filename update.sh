#!/bin/bash
################################################################################
# Dotfiles Updater v2 - Profile-Based Updates
#
# DESCRIPTION:
#   Profile-aware updater that updates components based on the detected profile.
#   Updates both shared and profile-specific Homebrew packages.
#
# USAGE:
#   ./update-v2.sh [--profile PROFILE]
#
# OPTIONS:
#   --profile PROFILE   Force a specific profile (work|personal)
#
# WHAT IT UPDATES:
#   - Dotfiles repository (git refresh)
#   - Homebrew and all Homebrew packages (shared + profile)
#   - Claude CLI plugins
#   - Vim runtime (if installed)
#   - Spacemacs (if installed)
#   - rbenv plugins (personal only)
#   - Global npm packages (personal only)
#   - uv tools (personal only)
#
################################################################################

set -euo pipefail

# Colors for output
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m' # No Color

# Configuration
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR

# Options
PROFILE=""

# Logging functions
log() { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[DONE]${NC}  $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --profile)
            PROFILE="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

echo
log "===================================="
log "  Dotfiles Updater (v2)"
log "===================================="
echo

# Detect profile
if [[ -n "$PROFILE" ]]; then
    log "Using specified profile: $PROFILE"
else
    log "Detecting profile..."
    PROFILE=$("$DOTFILES_DIR/scripts/detect_profile.sh")
fi
success "Profile: $PROFILE"

# Dotfiles
echo && log "Updating dotfiles source..."
(
    cd "${HOME}/dotfiles" || exit
    git refresh
)
success "Dotfiles updated"

# Homebrew and Homebrew Packages (shared + profile)
echo && log "Updating Homebrew..."
brew update
brew upgrade

echo && log "Installing shared Homebrew packages..."
if [[ -f "$DOTFILES_DIR/Brewfile.shared" ]]; then
    brew bundle --file="$DOTFILES_DIR/Brewfile.shared" || warn "Some shared packages may have failed"
fi

echo && log "Installing $PROFILE Homebrew packages..."
if [[ -f "$DOTFILES_DIR/Brewfile.${PROFILE}" ]]; then
    brew bundle --file="$DOTFILES_DIR/Brewfile.${PROFILE}" || warn "Some $PROFILE packages may have failed"
fi

brew cleanup
success "Homebrew updated"

# Update Claude plugins
echo && "$DOTFILES_DIR/scripts/update_claude_plugins"

# Vimrc
if [[ -d "${HOME}/.vim_runtime" ]]; then
    echo && log "Updating Vimrc..."
    if command -v vimup &> /dev/null; then
        vimup
        success "Vimrc updated"
    else
        warn "vimup command not found, skipping Vimrc update"
    fi
else
    warn "Vimrc not installed, skipping update"
fi

# Spacemacs
if [[ -d "${HOME}/.emacs.d" ]]; then
    echo && log "Updating Spacemacs..."
    if command -v spacemacsup &> /dev/null; then
        spacemacsup
        success "Spacemacs updated"
    else
        warn "spacemacsup command not found, skipping Spacemacs update"
    fi
else
    warn "Spacemacs not installed, skipping update"
fi

# Profile-specific updates
if [[ "$PROFILE" == "personal" ]]; then
    # rbenv plugins (personal only)
    echo && "$DOTFILES_DIR/scripts/update_rbenv_plugins"

    # npm packages (personal only)
    echo && "$DOTFILES_DIR/scripts/update_npm_packages"

    # uv tools (personal only)
    echo && "$DOTFILES_DIR/scripts/update_uv_tools"
fi

echo
success "All updates completed for profile: $PROFILE"
