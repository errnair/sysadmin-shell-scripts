#!/usr/bin/env bash

cat <<'EOF'
================================================================================
                           DEPRECATION NOTICE
================================================================================

This script has been DEPRECATED and moved to a new location.

OLD LOCATION:
  miscellaneous/etcbackup.sh

NEW LOCATION:
  utilities/etcbackup.sh

WHAT CHANGED:
  - Now a wrapper around utilities/dirbackup.sh
  - Inherits all dirbackup.sh features (encryption, retention, etc.)
  - Optimized defaults for /etc (90-day retention)
  - All dirbackup.sh options available

MIGRATION:
  Old: ./miscellaneous/etcbackup.sh
  New: ./utilities/etcbackup.sh

EXAMPLES:
  ./utilities/etcbackup.sh
  ENCRYPT=yes ./utilities/etcbackup.sh
  RETENTION_DAYS=30 ./utilities/etcbackup.sh

This deprecated file will be removed in a future release.
Please update your scripts to use the new location.
================================================================================
EOF

exit 1
