#!/usr/bin/env bash

cat <<'EOF'
================================================================================
                           DEPRECATION NOTICE
================================================================================

This script has been DEPRECATED and moved to a new location.

OLD LOCATION:
  server_management/CentOS/sync_emails.sh

NEW LOCATION:
  installation_scripts/sync_emails.sh

WHAT CHANGED:
  - Multi-OS support (RHEL/Rocky/AlmaLinux/Ubuntu/Debian)
  - Secure password input (no command-line passwords)
  - Email verification before sync
  - Dry-run mode for testing
  - Comprehensive logging
  - Connection timeout handling

MIGRATION:
  Old: ./server_management/CentOS/sync_emails.sh
  New: ./installation_scripts/sync_emails.sh

This deprecated file will be removed in a future release.
Please update your scripts to use the new location.
================================================================================
EOF

exit 1
