#!/bin/bash
################################################################################
#
# Update - Update all dotfiles components
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

# Logging functions
log() { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[DONE]${NC}  $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }

# Dotfiles
echo && log "Updating dotfiles source..."
(
    cd "${HOME}/dotfiles" || exit
    git refresh
)
success "Dotfiles updated"

# Homebrew and Homebrew Packages
echo && log "Updating Homebrew and Homebrew Packages..."
brewup
success "Homebrew updated"

# Vimrc
# https://github.com/amix/vimrc
if [[ -d "${HOME}/.vim_runtime" ]]; then
    echo && log "Updating Vimrc from https://github.com/amix/vimrc..."
    vimup
    success "Vimrc updated"
else
    warn "Vimrc not installed, skipping update"
fi

# Spacemacs
# https://github.com/syl20bnr/spacemacs
if [[ -d "${HOME}/.emacs.d" ]]; then
    echo && log "Updating Spacemacs from https://github.com/syl20bnr/spacemacs..."
    spacemacsup
    success "Spacemacs updated"
else
    warn "Spacemacs not installed, skipping update"
fi

# rbenv plugins
echo && "$DOTFILES_DIR/scripts/update_rbenv_plugins"

# npm packages
echo && "$DOTFILES_DIR/scripts/update_npm_packages"

echo
success "All updates completed!"