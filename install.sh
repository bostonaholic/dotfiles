#!/usr/bin/env bash
# Dotfiles installer - Simple, idempotent dotfiles management

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
CONFIG_FILE="$DOTFILES_DIR/dotfiles.yaml"
readonly CONFIG_FILE
BACKUP_DIR="${HOME}/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
readonly BACKUP_DIR

# Options
DRY_RUN=false
FORCE=false
VERBOSE=false
BACKUP=true
COMPONENTS=""
SKIP_SCRIPTS=false

# Logging functions
log() { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[DONE]${NC}  $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
debug() { 
    if [[ $VERBOSE == true ]]; then 
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

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
    brew        Install Homebrew packages
    npm         Install npm packages
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
                error "Unknown option: $1"
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
            error "$tool is required but not installed"
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
    if ! should_install "brew"; then
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

# Run installation scripts
run_scripts() {
    if [[ $SKIP_SCRIPTS == true ]] || ! should_install "scripts"; then
        return
    fi

    local script_type=$1
    log "Running $script_type scripts..."

    case $script_type in
        pre_install)
            if [[ $DRY_RUN == false ]]; then
                log "Validating sudo credentials (you may need to enter your password)..."
                sudo --validate
                success "Sudo credentials validated"
            else
                log "[DRY RUN] Would validate sudo credentials"
            fi
            ;;
        post_install)
            # Run post-install scripts based on conditions
            export DRY_RUN VERBOSE

            # oh-my-zsh
            if [[ ! -d ~/.oh-my-zsh ]] && [[ -x "$DOTFILES_DIR/scripts/install_oh-my-zsh" ]]; then
                if [[ $DRY_RUN == true ]]; then
                    log "[DRY RUN] Would install oh-my-zsh"
                else
                    "$DOTFILES_DIR/scripts/install_oh-my-zsh"
                fi
            else
                [[ -d ~/.oh-my-zsh ]] && log "oh-my-zsh already installed, skipping"
            fi

            # Spacemacs
            if [[ ! -d ~/.emacs.d ]] && [[ -x "$DOTFILES_DIR/scripts/install_spacemacs" ]]; then
                if [[ $DRY_RUN == true ]]; then
                    log "[DRY RUN] Would install spacemacs"
                else
                    "$DOTFILES_DIR/scripts/install_spacemacs"
                fi
            else
                [[ -d ~/.emacs.d ]] && log "Spacemacs already installed, skipping"
            fi

            # Vimrc
            if [[ ! -d ~/.vim_runtime ]] && [[ -x "$DOTFILES_DIR/scripts/install_vimrc" ]]; then
                if [[ $DRY_RUN == true ]]; then
                    log "[DRY RUN] Would install vimrc"
                else
                    "$DOTFILES_DIR/scripts/install_vimrc"
                fi
            else
                [[ -d ~/.vim_runtime ]] && log "Vimrc already installed, skipping"
            fi

            # Other optional scripts
            for script in "$DOTFILES_DIR"/scripts/install_*; do
                script_name=$(basename "$script")
                # Skip the main install scripts we've already handled
                case "$script_name" in
                    install_directories|install_symlinks|install_homebrew|install_npm_packages|install_oh-my-zsh|install_spacemacs|install_vimrc)
                        continue
                        ;;
                esac

                if [[ -x "$script" ]]; then
                    if [[ $DRY_RUN == true ]]; then
                        log "[DRY RUN] Would run: $script_name"
                    else
                        log "Running: $script_name"
                        "$script" || warn "Failed to run $script_name"
                    fi
                fi
            done
            ;;
    esac

    success "$script_type scripts completed"
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