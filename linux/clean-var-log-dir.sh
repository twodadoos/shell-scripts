#!/usr/bin/env bash
#

set -euo pipefail
IFS=$'\n\t'

#######################################
# Globals
#######################################
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RUN_DIR="$(pwd)"
TIMESTAMP="$(date -u +'%Y%m%dT%H%M%SZ')"

LOG_DIR="${RUN_DIR}"
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}.${TIMESTAMP}.log"

DRY_RUN=true
FORCE=false

#######################################
# Logging
#######################################
log() {
    local level="$1"
    shift
    printf '%s [%s] %s\n' \
        "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
        "$level" \
        "$*" >>"$LOG_FILE"
}

die() {
    log "ERROR" "$*"
    exit 1
}

#######################################
# Error handling
#######################################
trap 'die "Command failed at line ${LINENO}: ${BASH_COMMAND}"' ERR

#######################################
# Usage
#######################################
usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Options:
  --execute        Perform destructive actions (disables dry-run)
  --force          Skip safety confirmation checks
  -h, --help       Show this help and exit

Default behavior is DRY-RUN.
EOF
}

#######################################
# Preconditions
#######################################
require_root() {
    [[ "$(id -u)" -eq 0 ]] || die "This script must be run as root"
}

require_binary() {
    local bin="$1"
    command -v "$bin" >/dev/null 2>&1 || die "Required binary not found: $bin"
}

#######################################
# Argument parsing
#######################################
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --execute)
                DRY_RUN=false
                ;;
            --force)
                FORCE=true
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                die "Unknown argument: $1"
                ;;
        esac
        shift
    done
}

#######################################
# Safety gates
#######################################
confirm_execution() {
    if [[ "$DRY_RUN" == true ]]; then
        log "INFO" "Running in DRY-RUN mode (no changes will be made)"
        return
    fi

    if [[ "$FORCE" == true ]]; then
        log "WARN" "Force flag set; skipping confirmation checks"
        return
    fi

    die "Refusing to execute destructive actions without --force"
}

#######################################
# Safe execution helper
#######################################
run() {
    if [[ "$DRY_RUN" == true ]]; then
        log "INFO" "[DRY-RUN] $*"
    else
        log "INFO" "Executing: $*"
        "$@" >>"$LOG_FILE" 2>&1
    fi
}

#######################################
# Main logic
#######################################
main() {
    touch "$LOG_FILE"

    log "INFO" "Starting ${SCRIPT_NAME}"
    log "INFO" "Mode: $( [[ "$DRY_RUN" == true ]] && echo DRY-RUN || echo EXECUTE )"

    require_root
    require_binary /usr/bin/rm
    require_binary /usr/bin/find

    confirm_execution

    #
    # === DESTRUCTIVE LOGIC GOES HERE ===
    #
    /usr/bin/find /var/log -type f \( \
        -name '*.gz' -o \
        -name '*.[0-9]' \
    \) -print | while IFS= read -r logfile; do
        run /usr/bin/rm -- "$logfile"
    done

    log "INFO" "Completed successfully"
}

#######################################
# Entrypoint
#######################################
parse_args "$@"
main

