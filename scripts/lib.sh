#!/bin/bash
################################################################################
# Dotfiles Shared Library
#
# DESCRIPTION:
#   Common boilerplate for dotfiles scripts: colors, logging, directory
#   resolution, and environment defaults. Sourced by scripts in scripts/
#   and by the root install.sh / update.sh.
#
# USAGE (from scripts/*):
#   # shellcheck source=lib.sh
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
#
# USAGE (from repo root):
#   # shellcheck source=scripts/lib.sh
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts/lib.sh"
#
# PROVIDED VARIABLES:
#   DOTFILES_DIR  - Absolute path to the dotfiles repository root
#   CONFIG_FILE   - Absolute path to dotfiles.yaml
#   DRY_RUN       - Preview mode (default: false, inherits from environment)
#   VERBOSE       - Verbose output (default: false, inherits from environment)
#
# PROVIDED FUNCTIONS:
#   log()         - Info message   [INFO]
#   success()     - Success message [DONE]
#   warn()        - Warning message [WARN]
#   error()       - Error message   [ERROR] (prints only, does NOT exit)
#   debug()       - Debug message   [DEBUG] (only when VERBOSE=true)
#
################################################################################

# Double-source guard
[[ -n "${_DOTFILES_LIB_LOADED:-}" ]] && return 0
_DOTFILES_LIB_LOADED=1

# Colors for output
readonly _LIB_RED='\033[0;31m'
readonly _LIB_GREEN='\033[0;32m'
readonly _LIB_YELLOW='\033[0;33m'
readonly _LIB_BLUE='\033[0;34m'
readonly _LIB_NC='\033[0m'

# Resolve DOTFILES_DIR from the caller's location.
# BASH_SOURCE[1] is the script that sourced this file.
if [[ -z "${DOTFILES_DIR:-}" ]]; then
    _caller_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    if [[ "$(basename "$_caller_dir")" == "scripts" ]]; then
        DOTFILES_DIR="$(cd "$_caller_dir/.." && pwd)"
    else
        DOTFILES_DIR="$_caller_dir"
    fi
    unset _caller_dir
fi
readonly DOTFILES_DIR

CONFIG_FILE="$DOTFILES_DIR/dotfiles.yaml"
readonly CONFIG_FILE
export CONFIG_FILE

# Options from environment or defaults
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"

# Logging functions
log()     { echo -e "${_LIB_BLUE}[INFO]${_LIB_NC}  $1"; }
success() { echo -e "${_LIB_GREEN}[DONE]${_LIB_NC}  $1"; }
warn()    { echo -e "${_LIB_YELLOW}[WARN]${_LIB_NC}  $1"; }
error()   { echo -e "${_LIB_RED}[ERROR]${_LIB_NC} $1"; }
debug() {
    if [[ $VERBOSE == true ]]; then
        echo -e "${_LIB_BLUE}[DEBUG]${_LIB_NC} $1"
    fi
}
