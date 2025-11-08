#!/usr/bin/env bash

cat <<'EOF'
================================================================================
                           DEPRECATION NOTICE
================================================================================

This script has been DEPRECATED and moved to a new location.

OLD LOCATION:
  miscellaneous/passgen.sh

NEW LOCATION:
  utilities/passgen.sh

WHAT CHANGED:
  - Multiple password types (alphanumeric, special, passphrase, PIN)
  - Password strength assessment with entropy calculation
  - Avoid ambiguous characters option
  - Multiple output formats (text, JSON, CSV)
  - Clipboard integration
  - Bulk password generation

MIGRATION:
  Old: ./miscellaneous/passgen.sh [count] [length]
  New: ./utilities/passgen.sh [count] [length]

EXAMPLES:
  ./utilities/passgen.sh 10 32
  PASSWORD_TYPE=special ./utilities/passgen.sh 5 24
  PASSWORD_TYPE=passphrase ./utilities/passgen.sh 1 5
  OUTPUT_FORMAT=csv ./utilities/passgen.sh 100 16 > passwords.csv

This deprecated file will be removed in a future release.
Please update your scripts to use the new location.
================================================================================
EOF

exit 1
