#!/usr/bin/env bash
################################################################################
# Dotfiles Updater
#
# DESCRIPTION:
#   Updates all components of the dotfiles environment including the dotfiles
#   repository itself, Homebrew packages, Claude plugins, Vim runtime,
#   Spacemacs, rbenv plugins, npm packages, and uv tools.
#
# USAGE:
#   ./update.sh
#
# WHAT IT UPDATES:
#   - Dotfiles repository (git refresh)
#   - Homebrew and all Homebrew packages
#   - Claude CLI plugins
#   - Vim runtime (if installed)
#   - Spacemacs (if installed)
#   - rbenv plugins
#   - Global npm packages
#   - uv tools
#
# DEPENDENCIES:
#   - git (required)
#   - homebrew (required)
#   - brewup script (required)
#   - Optional: claude, vimup, spacemacsup commands
#
# NOTES:
#   This script is safe to run repeatedly. It will skip components that
#   aren't installed on your system.
#
################################################################################

set -euo pipefail

# shellcheck source=scripts/lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts/lib.sh"

# Dotfiles
echo && log "Updating dotfiles source..."
(
    cd "$DOTFILES_DIR" || exit
    git refresh
)
success "Dotfiles updated"

# Homebrew and Homebrew Packages
if command -v brewup &>/dev/null; then
    echo && log "Updating Homebrew and Homebrew Packages..."
    brewup
    success "Homebrew updated"
else
    warn "brewup not found, skipping Homebrew updates"
fi

# Update Claude plugins
echo && "$DOTFILES_DIR/scripts/update_claude_plugins"

# Vimrc
# https://github.com/amix/vimrc
if [[ -d "${HOME}/.vim_runtime" ]] && command -v vimup &>/dev/null; then
    echo && log "Updating Vimrc from https://github.com/amix/vimrc..."
    vimup
    success "Vimrc updated"
else
    warn "Vimrc not installed or vimup not found, skipping update"
fi

# Spacemacs
# https://github.com/syl20bnr/spacemacs
if [[ -d "${HOME}/.emacs.d" ]] && command -v spacemacsup &>/dev/null; then
    echo && log "Updating Spacemacs from https://github.com/syl20bnr/spacemacs..."
    spacemacsup
    success "Spacemacs updated"
else
    warn "Spacemacs not installed or spacemacsup not found, skipping update"
fi

# rbenv plugins
echo && "$DOTFILES_DIR/scripts/update_rbenv_plugins"

# npm packages
echo && "$DOTFILES_DIR/scripts/update_npm_packages"

# uv tools
echo && "$DOTFILES_DIR/scripts/update_uv_tools"

echo
success "All updates completed!"