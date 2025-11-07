#!/usr/bin/env bash
set -euo pipefail

#################################################
#                                               #
#     /etc Directory Backup Wrapper             #
#     Simplified wrapper for dirbackup.sh       #
#                                               #
#################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Setup
trap cleanup_on_exit EXIT
require_root

# Configuration - optimized defaults for /etc backups
BACKUP_DIR="${BACKUP_DIR:-/backups}"
COMPRESSION="${COMPRESSION:-gz}"
VERIFY="${VERIFY:-yes}"
RETENTION_DAYS="${RETENTION_DAYS:-90}"  # Keep /etc backups longer (90 days)

print_header "/etc Directory Backup"

print_info "This is a convenience wrapper for dirbackup.sh optimized for /etc"
print_info "Backup directory: $BACKUP_DIR"
print_info "Compression: $COMPRESSION"
print_info "Retention: $RETENTION_DAYS days"
echo

# Check if dirbackup.sh exists
DIRBACKUP_SCRIPT="${SCRIPT_DIR}/dirbackup.sh"

if [ ! -f "$DIRBACKUP_SCRIPT" ]; then
    error_exit "dirbackup.sh not found at: $DIRBACKUP_SCRIPT

Please ensure dirbackup.sh is in the same directory as this script."
fi

# Make sure dirbackup.sh is executable
if [ ! -x "$DIRBACKUP_SCRIPT" ]; then
    chmod +x "$DIRBACKUP_SCRIPT"
fi

# Export environment variables for dirbackup.sh
export BACKUP_DIR
export COMPRESSION
export VERIFY
export RETENTION_DAYS

# Call dirbackup.sh with /etc as the source
print_info "Calling dirbackup.sh to backup /etc..."
echo

"$DIRBACKUP_SCRIPT" /etc

# Log completion
log_success "/etc backup completed via dirbackup.sh"
