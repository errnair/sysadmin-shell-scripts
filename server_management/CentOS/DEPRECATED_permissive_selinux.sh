#!/usr/bin/env bash

cat <<'EOF'
================================================================================
                           DEPRECATION NOTICE
================================================================================

This script has been DEPRECATED and replaced with a comprehensive tool.

OLD LOCATION:
  server_management/CentOS/permissive_selinux.sh

NEW LOCATION:
  server_management/selinux_troubleshoot.sh

WHAT CHANGED:
  - Renamed to reflect purpose (troubleshooting, not just disabling)
  - Multiple commands: status, denials, suggest, permissive, enforcing
  - Strong security warnings before disabling enforcement
  - SELinux denial analysis with audit2why
  - Troubleshooting workflow guidance
  - Temporary vs permanent mode options

MIGRATION:
  Old: ./server_management/CentOS/permissive_selinux.sh
  New: ./server_management/selinux_troubleshoot.sh permissive

RECOMMENDED WORKFLOW:
  1. Check status:      ./server_management/selinux_troubleshoot.sh status
  2. View denials:      ./server_management/selinux_troubleshoot.sh denials
  3. Get suggestions:   ./server_management/selinux_troubleshoot.sh suggest
  4. Set permissive:    ./server_management/selinux_troubleshoot.sh permissive

This deprecated file will be removed in a future release.
Please update your scripts to use the new location.
================================================================================
EOF

exit 1
