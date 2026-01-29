#!/usr/bin/env bash
################################################################################
# Dotfiles Installer v2 - Profile-Based Installation
#
# DESCRIPTION:
#   Wrapper around install.sh that adds profile detection and YAML merging.
#   Detects work/personal profile, merges shared + profile YAML configs,
#   then runs the main installer with the merged configuration.
#
# USAGE:
#   ./install.sh [OPTIONS]
#
# OPTIONS:
#   All options are passed through to install.sh
#   -h, --help          Show help message
#   -n, --dry-run       Preview changes without making them
#   -f, --force         Force overwrite existing files without prompting
#   -v, --verbose       Enable verbose output
#   -y, --yes           Answer yes to all prompts
#   --profile PROFILE   Force a specific profile (work|personal)
#
# PROFILES:
#   work      - Shopify development environment
#   personal  - Personal machine setup
#
################################################################################

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR
MERGED_CONFIG="/tmp/dotfiles.merged.$$.yaml"

# Options
PROFILE=""
PASSTHROUGH_ARGS=()
DRY_RUN=false

# Logging functions
log() { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[DONE]${NC}  $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --profile)
                PROFILE="$2"
                shift 2
                ;;
            -n|--dry-run)
                DRY_RUN=true
                PASSTHROUGH_ARGS+=("$1")
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                PASSTHROUGH_ARGS+=("$1")
                shift
                ;;
        esac
    done
}

# Help text
usage() {
    cat << EOF
Dotfiles Installer v2 - Profile-Based Installation

Usage: $0 [OPTIONS]

This wrapper adds profile detection (work/personal) to the dotfiles installer.
On first run, you'll be prompted to select your profile. The selection is saved
to ~/.dotfiles_profile for subsequent runs.

OPTIONS:
    -h, --help          Show this help message
    --profile PROFILE   Force a specific profile (work|personal)

    All other options are passed through to install.sh:
    -n, --dry-run       Show what would be done without making changes
    -f, --force         Force overwrite existing files
    -v, --verbose       Enable verbose output
    -y, --yes           Answer yes to all prompts
    --only COMPONENTS   Install only specified components
    --skip-scripts      Skip pre/post installation scripts

PROFILES:
    work      Install work-specific configs (Shopify environment)
    personal  Install personal-specific configs

EXAMPLES:
    $0                      # Interactive profile detection
    $0 --dry-run           # Preview changes
    $0 --profile personal  # Force personal profile
    $0 -fy                 # Force install, answer yes to all

EOF
}

# Cleanup function
cleanup() {
    if [[ -f "$MERGED_CONFIG" ]]; then
        rm -f "$MERGED_CONFIG"
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Main installation
main() {
    parse_args "$@"

    echo
    log "===================================="
    log "  Dotfiles Installation (v2)"
    log "===================================="
    echo

    # Step 1: Detect or get profile
    if [[ -n "$PROFILE" ]]; then
        log "Using specified profile: $PROFILE"
    else
        log "Detecting profile..."
        PROFILE=$("$DOTFILES_DIR/scripts/detect_profile.sh")
    fi

    if [[ "$PROFILE" != "work" && "$PROFILE" != "personal" ]]; then
        error "Invalid profile: $PROFILE. Must be 'work' or 'personal'"
    fi

    success "Profile: $PROFILE"
    echo

    # Step 2: Merge YAML files
    log "Merging configuration files..."
    local shared_yaml="$DOTFILES_DIR/dotfiles.shared.yaml"
    local profile_yaml="$DOTFILES_DIR/dotfiles.${PROFILE}.yaml"

    if [[ ! -f "$shared_yaml" ]]; then
        error "Shared config not found: $shared_yaml"
    fi
    if [[ ! -f "$profile_yaml" ]]; then
        error "Profile config not found: $profile_yaml"
    fi

    if [[ $DRY_RUN == true ]]; then
        log "[DRY RUN] Would merge: $shared_yaml + $profile_yaml"
    fi

    "$DOTFILES_DIR/scripts/merge_yaml.sh" "$shared_yaml" "$profile_yaml" "$MERGED_CONFIG"
    success "Configuration merged to: $MERGED_CONFIG"
    echo

    # Step 3: Run main installer with merged config
    log "Running installer with merged configuration..."
    echo
    "$DOTFILES_DIR/install.v1.sh" --config "$MERGED_CONFIG" "${PASSTHROUGH_ARGS[@]}"
    echo

    # Step 4: Install Homebrew packages (shared + profile)
    log "Installing Homebrew packages..."

    local shared_brewfile="$DOTFILES_DIR/Brewfile.shared"
    local profile_brewfile="$DOTFILES_DIR/Brewfile.${PROFILE}"

    if [[ -f "$shared_brewfile" ]]; then
        if [[ $DRY_RUN == true ]]; then
            log "[DRY RUN] Would run: brew bundle --file=$shared_brewfile"
        else
            log "Installing shared packages from $shared_brewfile"
            brew bundle --file="$shared_brewfile" || warn "Some shared packages may have failed"
        fi
    fi

    if [[ -f "$profile_brewfile" ]]; then
        if [[ $DRY_RUN == true ]]; then
            log "[DRY RUN] Would run: brew bundle --file=$profile_brewfile"
        else
            log "Installing $PROFILE packages from $profile_brewfile"
            brew bundle --file="$profile_brewfile" || warn "Some $PROFILE packages may have failed"
        fi
    fi

    success "Homebrew packages installed"
    echo

    # Cleanup is handled by trap
    log "===================================="
    success "Installation complete for profile: $PROFILE"
    log "===================================="
    echo
}

# Run main function
main "$@"
