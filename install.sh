#!/usr/bin/env bash
################################################################################
# Dotfiles Installer
#
# DESCRIPTION:
#   Idempotent installation script that sets up dotfiles environment from
#   declarative YAML configuration. Creates symlinks, installs packages via
#   Homebrew/npm/uv, and runs installation scripts.
#
# USAGE:
#   ./install.sh [OPTIONS]
#
# OPTIONS:
#   -h, --help          Show help message
#   -n, --dry-run       Preview changes without making them
#   -f, --force         Force overwrite existing files without prompting
#   -v, --verbose       Enable verbose output
#   -y, --yes           Answer yes to all prompts
#   --no-backup         Don't backup existing files
#   --only COMPONENTS   Install only specified components (symlinks,homebrew,npm,uv,claude,scripts)
#   --skip-scripts      Skip pre/post installation scripts
#
# EXAMPLES:
#   ./install.sh                   # Interactive installation
#   ./install.sh --dry-run         # Preview changes
#   ./install.sh --only symlinks   # Only create symlinks
#   ./install.sh -fy               # Force install, answer yes to all
#
# DEPENDENCIES:
#   - git (required)
#   - yq (installed automatically if missing)
#   - homebrew (installed automatically if missing)
#
# CONFIGURATION:
#   All configuration is read from dotfiles.yaml in the same directory
#
################################################################################

set -euo pipefail

# shellcheck source=scripts/lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts/lib.sh"

BACKUP_DIR="${HOME}/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
readonly BACKUP_DIR

# Additional options
FORCE=false
BACKUP=true
COMPONENTS=""
SKIP_SCRIPTS=false

# Fatal error -- prints and exits (lib.sh error() only prints)
die() { error "$1"; exit 1; }

# Help text
usage() {
    cat << EOF
Dotfiles Installer

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -n, --dry-run       Show what would be done without making changes
    -f, --force         Force overwrite existing files without prompting
    -v, --verbose       Enable verbose output
    -y, --yes           Answer yes to all prompts
    --no-backup         Don't backup existing files
    --only COMPONENTS   Install only specified components (comma-separated)
    --skip-scripts      Skip pre/post installation scripts

COMPONENTS:
    symlinks    Create all symlinks
    homebrew    Install Homebrew packages
    npm         Install npm packages
    uv          Install uv tools
    claude      Install Claude Code plugins
    scripts     Run installation scripts

EXAMPLES:
    $0                      # Interactive installation
    $0 --dry-run           # Preview changes
    $0 --only symlinks     # Only create symlinks
    $0 -fy                 # Force install, answer yes to all

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -y|--yes)
                FORCE=true
                shift
                ;;
            --no-backup)
                BACKUP=false
                shift
                ;;
            --only)
                COMPONENTS="$2"
                shift 2
                ;;
            --skip-scripts)
                SKIP_SCRIPTS=true
                shift
                ;;
            *)
                die "Unknown option: $1"
                ;;
        esac
    done
}

# Check if component should be installed
should_install() {
    local component=$1
    if [[ -z "$COMPONENTS" ]]; then
        return 0
    fi
    [[ ",$COMPONENTS," == *",$component,"* ]]
}

# Check dependencies
check_dependencies() {
    log "Checking dependencies..."

    # Check for required tools
    local required_tools=("git")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            die "$tool is required but not installed"
        fi
    done

    # Check for yq, install if missing
    if ! command -v yq &> /dev/null; then
        warn "yq not found. Installing yq via Homebrew..."

        # Install Homebrew if not present
        if ! command -v brew &> /dev/null; then
            log "Homebrew not found. Installing Homebrew first..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

            # Add Homebrew to PATH for this session
            if [[ -x "/opt/homebrew/bin/brew" ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -x "/usr/local/bin/brew" ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        fi

        # Install yq
        if [[ $DRY_RUN == true ]]; then
            log "[DRY RUN] Would install yq via Homebrew"
        else
            brew install yq
            success "yq installed successfully"
        fi
    fi

    success "Dependencies checked"
}


# Create directories
create_directories() {
    if ! should_install "symlinks"; then
        return
    fi

    # Export options for the script
    export DRY_RUN VERBOSE
    "$DOTFILES_DIR/scripts/install_directories"
}

# Create all symlinks
create_symlinks() {
    if ! should_install "symlinks"; then
        return
    fi

    # Export options for the script
    export DRY_RUN FORCE VERBOSE BACKUP BACKUP_DIR
    "$DOTFILES_DIR/scripts/install_symlinks"
}

# Install Homebrew packages
install_brew() {
    if ! should_install "homebrew"; then
        return
    fi

    # Export options for the script
    export DRY_RUN VERBOSE
    "$DOTFILES_DIR/scripts/install_homebrew"
}

# Install npm packages
install_npm() {
    if ! should_install "npm"; then
        return
    fi

    # Export options for the script
    export DRY_RUN VERBOSE
    "$DOTFILES_DIR/scripts/install_npm_packages"
}

# Install uv tools
install_uv() {
    if ! should_install "uv"; then
        return
    fi

    # Export options for the script
    export DRY_RUN VERBOSE
    "$DOTFILES_DIR/scripts/install_uv_tools"
}

# Install Claude Code plugins
install_claude() {
    if ! should_install "claude"; then
        return
    fi

    # Export options for the script
    export DRY_RUN VERBOSE
    "$DOTFILES_DIR/scripts/install_claude_plugins"
}

# Run installation scripts from dotfiles.yaml
run_scripts() {
    if [[ $SKIP_SCRIPTS == true ]] || ! should_install "scripts"; then
        return
    fi

    local script_type=$1
    log "Running $script_type scripts..."

    export DRY_RUN VERBOSE

    local count
    count=$(yq eval ".scripts.${script_type} | length" "$CONFIG_FILE" 2>/dev/null || echo "0")

    if [[ "$count" == "0" ]]; then
        debug "No $script_type scripts configured"
        return
    fi

    local ran=0
    for ((i=0; i<count; i++)); do
        local desc cmd cond optional
        desc=$(yq eval ".scripts.${script_type}[$i].description" "$CONFIG_FILE")
        cmd=$(yq eval ".scripts.${script_type}[$i].command" "$CONFIG_FILE")
        cond=$(yq eval ".scripts.${script_type}[$i].condition // \"\"" "$CONFIG_FILE")
        optional=$(yq eval ".scripts.${script_type}[$i].optional // false" "$CONFIG_FILE")

        # Evaluate condition if present
        if [[ -n "$cond" ]]; then
            if ! eval "$cond" &>/dev/null; then
                debug "Condition not met for: $desc"
                continue
            fi
        fi

        ran=$((ran + 1))
        if [[ $DRY_RUN == true ]]; then
            log "[DRY RUN] Would run: $desc"
        else
            log "$desc..."
            if [[ "$optional" == "true" ]]; then
                "$DOTFILES_DIR/$cmd" || warn "Optional step failed: $desc"
            else
                "$DOTFILES_DIR/$cmd"
            fi
        fi
    done

    success "$script_type scripts completed ($ran executed)"
}

# Main installation
main() {
    parse_args "$@"

    echo
    log "===================================="
    log "    Dotfiles Installation Script"
    log "===================================="
    echo

    log "Starting dotfiles installation..."
    log "Configuration file: $CONFIG_FILE"
    log "Dotfiles directory: $DOTFILES_DIR"
    echo

    [[ $DRY_RUN == true ]] && warn "Running in DRY RUN mode - no changes will be made"
    [[ $FORCE == true ]] && warn "Force mode enabled - will overwrite existing files"
    [[ -n "$COMPONENTS" ]] && log "Installing only: $COMPONENTS"
    echo

    check_dependencies
    echo

    # Run pre-install scripts
    run_scripts "pre_install"
    echo

    # Create directories and symlinks
    create_directories
    echo
    create_symlinks
    echo

    # Install packages
    install_brew
    echo
    install_npm
    echo
    install_uv
    echo
    install_claude
    echo

    # Run post-install scripts
    run_scripts "post_install"
    echo

    log "===================================="
    if [[ $DRY_RUN == false ]]; then
        success "✨ Installation complete!"
        [[ $BACKUP == true ]] && [[ -d "$BACKUP_DIR" ]] && log "📁 Backups saved to: $BACKUP_DIR"
    else
        success "Dry run complete. No changes were made."
        log "Run without --dry-run to apply changes."
    fi
    log "===================================="
    echo
}

# Run main function
main "$@"