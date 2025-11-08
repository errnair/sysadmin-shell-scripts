#!/usr/bin/env bash

cat <<'EOF'
================================================================================
                           DEPRECATION NOTICE
================================================================================

This script has been DEPRECATED and moved to a new location.

OLD LOCATION:
  miscellaneous/checkssh_conn.sh

NEW LOCATION:
  installation_scripts/checkssh_conn.sh

WHAT CHANGED:
  - Multi-OS support (RHEL/Rocky/AlmaLinux/Ubuntu/Debian)
  - Connection timeout configuration
  - Port specification support
  - Multiple host checking
  - Detailed connection diagnostics
  - Known hosts handling options

MIGRATION:
  Old: ./miscellaneous/checkssh_conn.sh
  New: ./installation_scripts/checkssh_conn.sh

This deprecated file will be removed in a future release.
Please update your scripts to use the new location.
================================================================================
EOF

exit 1
