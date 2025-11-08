#!/usr/bin/env bash

cat <<'EOF'
================================================================================
                           DEPRECATION NOTICE
================================================================================

This script has been DEPRECATED and moved to a new location.

OLD LOCATION:
  server_management/CentOS/change_hostname.sh

NEW LOCATION:
  server_management/change_hostname.sh

WHAT CHANGED:
  - Multi-OS support (RHEL/Rocky/AlmaLinux/Ubuntu/Debian)
  - RFC 1123 hostname validation
  - Cloud provider detection (AWS/Azure/GCP)
  - Automatic /etc/hosts update
  - Configuration backup before changes
  - No unnecessary network restarts by default

MIGRATION:
  Old: ./server_management/CentOS/change_hostname.sh <hostname>
  New: ./server_management/change_hostname.sh <hostname>

ADDITIONAL OPTIONS:
  UPDATE_HOSTS=no ./server_management/change_hostname.sh webserver01
  RESTART_NETWORK=yes ./server_management/change_hostname.sh db-server

This deprecated file will be removed in a future release.
Please update your scripts to use the new location.
================================================================================
EOF

exit 1
