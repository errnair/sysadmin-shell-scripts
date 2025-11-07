#!/usr/bin/env bash

#################################################
#                                               #
#     DEPRECATED - Use install_flask.sh         #
#                                               #
#################################################

cat <<'EOF'
╔════════════════════════════════════════════════════════════════╗
║                    DEPRECATION NOTICE                          ║
╚════════════════════════════════════════════════════════════════╝

This script (newuser.sh) has been DEPRECATED and replaced with
modernized alternatives.

REPLACEMENT:
  Use: installation_scripts/install_flask.sh

The modernized install_flask.sh script provides:
  - Multi-OS support (RHEL/Rocky/AlmaLinux/Ubuntu/Debian)
  - Automatic user creation with proper permissions
  - Python virtual environment setup
  - Gunicorn service configuration
  - Nginx integration (optional)
  - SELinux configuration
  - Firewall configuration
  - SSL support with Let's Encrypt

MIGRATION:
  Old command:
    ./newuser.sh myuser

  New command:
    ../../installation_scripts/install_flask.sh

  The new script will prompt for username and handle all setup
  including webroot, logs, permissions, SELinux contexts, and
  Python virtual environment.

DOCUMENTATION:
  See: installation_scripts/install_flask.sh --help
  Or run without arguments for interactive mode

This deprecated script will be removed in a future release.
EOF

exit 1
