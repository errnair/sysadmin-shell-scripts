#!/usr/bin/env bash

cat <<'EOF'
================================================================================
                           DEPRECATION NOTICE
================================================================================

This script has been DEPRECATED and moved to a new location.

OLD LOCATION:
  server_management/CentOS/create_db.sh

NEW LOCATION:
  installation_scripts/create_db.sh

WHAT CHANGED:
  - Multi-OS support (RHEL/Rocky/AlmaLinux/Ubuntu/Debian)
  - Modern MySQL/MariaDB version detection
  - Secure password input (no command-line passwords)
  - Character set and collation options
  - Database verification after creation
  - Support for MySQL 8.0+ authentication

MIGRATION:
  Old: ./server_management/CentOS/create_db.sh
  New: ./installation_scripts/create_db.sh

This deprecated file will be removed in a future release.
Please update your scripts to use the new location.
================================================================================
EOF

exit 1
