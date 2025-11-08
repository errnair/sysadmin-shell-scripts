#!/usr/bin/env bash

cat <<'EOF'
================================================================================
                           DEPRECATION NOTICE
================================================================================

This script has been DEPRECATED and moved to a new location.

OLD LOCATION:
  miscellaneous/dirbackup.sh

NEW LOCATION:
  utilities/dirbackup.sh

WHAT CHANGED:
  - Multi-OS support
  - Multiple compression formats (gz, bz2, xz)
  - GPG encryption support
  - Backup verification with SHA256
  - Retention policy (automatic cleanup)
  - Incremental backup support (rsync)
  - Exclude patterns
  - Email notifications
  - Progress indication and elapsed time

MIGRATION:
  Old: ./miscellaneous/dirbackup.sh /path
  New: ./utilities/dirbackup.sh /path

EXAMPLES:
  ./utilities/dirbackup.sh /etc
  ENCRYPT=yes ./utilities/dirbackup.sh /var/www
  RETENTION_DAYS=7 ./utilities/dirbackup.sh /home

This deprecated file will be removed in a future release.
Please update your scripts to use the new location.
================================================================================
EOF

exit 1
