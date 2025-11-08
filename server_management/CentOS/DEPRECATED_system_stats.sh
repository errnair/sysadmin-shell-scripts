#!/usr/bin/env bash

cat <<'EOF'
================================================================================
                           DEPRECATION NOTICE
================================================================================

This script has been DEPRECATED and moved to a new location.

OLD LOCATION:
  server_management/CentOS/system_stats.sh

NEW LOCATION:
  server_management/system_stats.sh

WHAT CHANGED:
  - Multi-OS support (RHEL/Rocky/AlmaLinux/Ubuntu/Debian)
  - Multiple output formats (text, JSON, CSV)
  - Enhanced information (virtualization, containers, security status)
  - Save to file option
  - Improved public IP detection with multiple sources

MIGRATION:
  Old: ./server_management/CentOS/system_stats.sh
  New: ./server_management/system_stats.sh

ADDITIONAL OPTIONS:
  OUTPUT_FORMAT=json ./server_management/system_stats.sh
  SAVE_TO_FILE=yes OUTPUT_FILE=/tmp/stats.txt ./server_management/system_stats.sh

This deprecated file will be removed in a future release.
Please update your scripts to use the new location.
================================================================================
EOF

exit 1
