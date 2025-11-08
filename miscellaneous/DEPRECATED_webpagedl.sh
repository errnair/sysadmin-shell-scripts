#!/usr/bin/env bash

cat <<'EOF'
================================================================================
                           DEPRECATION NOTICE
================================================================================

This script has been DEPRECATED and moved to a new location.

OLD LOCATION:
  miscellaneous/webpagedl.sh

NEW LOCATION:
  utilities/webpagedl.sh

WHAT CHANGED:
  - Multi-method support (wget, curl, aria2c)
  - Retry logic with configurable attempts
  - Rate limiting and timeout support
  - Recursive and mirror modes
  - HTTP authentication support
  - Resume capability
  - Download verification
  - Progress indication

MIGRATION:
  Old: ./miscellaneous/webpagedl.sh <url>
  New: ./utilities/webpagedl.sh <url>

EXAMPLES:
  ./utilities/webpagedl.sh https://example.com
  METHOD=curl ./utilities/webpagedl.sh https://example.com
  RECURSIVE=yes RECURSIVE_DEPTH=2 ./utilities/webpagedl.sh https://example.com
  MIRROR_MODE=yes ./utilities/webpagedl.sh https://example.com

This deprecated file will be removed in a future release.
Please update your scripts to use the new location.
================================================================================
EOF

exit 1
