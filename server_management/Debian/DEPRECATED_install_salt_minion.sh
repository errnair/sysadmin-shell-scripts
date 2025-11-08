#!/usr/bin/env bash

cat <<'EOF'
================================================================================
                           DEPRECATION NOTICE
================================================================================

This script has been DEPRECATED and replaced with a multi-OS version.

OLD LOCATION:
  server_management/Debian/install_salt_minion.sh

NEW LOCATION:
  installation_scripts/install_salt_minion.sh

WHAT CHANGED:
  - Multi-OS support (RHEL/Rocky/AlmaLinux/Ubuntu/Debian)
  - Modern SaltProject repositories
  - Master validation (IP, hostname, FQDN)
  - Version selection support
  - Custom minion ID configuration
  - Connection testing with troubleshooting
  - Firewall configuration

MIGRATION:
  Old: ./server_management/Debian/install_salt_minion.sh <master-ip>
  New: ./installation_scripts/install_salt_minion.sh <master-ip>

EXAMPLES:
  ./installation_scripts/install_salt_minion.sh 192.168.1.100
  MINION_ID=webserver01 ./installation_scripts/install_salt_minion.sh salt.example.com

This deprecated file will be removed in a future release.
Please update your scripts to use the new location.
================================================================================
EOF

exit 1
