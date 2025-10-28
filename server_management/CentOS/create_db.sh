#!/usr/bin/env bash
set -euo pipefail

#################################################
#                                               #
#     Create MySQL database and user           #
#     Secure password handling                  #
#                                               #
#################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

# Setup
trap cleanup_on_exit EXIT

# Configuration
DB_NAME="${1:-test_db}"
DB_USER="${2:-test_user}"
DB_CHARSET="${DB_CHARSET:-utf8mb4}"
DB_COLLATION="${DB_COLLATION:-utf8mb4_unicode_ci}"

print_header "MySQL Database Creator"

# Validate inputs
if [[ ! "$DB_NAME" =~ ^[a-zA-Z0-9_]+$ ]]; then
    error_exit "Invalid database name. Use only alphanumeric characters and underscores."
fi

if [[ ! "$DB_USER" =~ ^[a-zA-Z0-9_]+$ ]]; then
    error_exit "Invalid username. Use only alphanumeric characters and underscores."
fi

print_info "Database: $DB_NAME"
print_info "User: $DB_USER"
print_info "Charset: $DB_CHARSET"
print_info "Collation: $DB_COLLATION"
echo

# Get MySQL root password securely (no command-line argument!)
read_password "Enter MySQL root password" MYSQL_ROOT_PASS || error_exit "Password required"

# Get new user password securely
read_password "Enter password for user '$DB_USER'" DB_USER_PASS || error_exit "Password required"

# Verify password
read_password "Confirm password for user '$DB_USER'" DB_USER_PASS_CONFIRM || error_exit "Password confirmation required"

if [ "$DB_USER_PASS" != "$DB_USER_PASS_CONFIRM" ]; then
    error_exit "Passwords do not match"
fi

# Create temporary credentials file (secure method)
MYSQL_CREDS=$(mktemp)
chmod 600 "$MYSQL_CREDS"

cat > "$MYSQL_CREDS" <<EOF
[client]
user=root
password=$MYSQL_ROOT_PASS
EOF

print_info "Creating database and user..."

# Test MySQL connection
if ! mysql --defaults-extra-file="$MYSQL_CREDS" -e "SELECT 1;" &>/dev/null; then
    rm -f "$MYSQL_CREDS"
    error_exit "Failed to connect to MySQL. Check your root password."
fi

# Create database and user
mysql --defaults-extra-file="$MYSQL_CREDS" <<SQL
-- Drop database if exists
DROP DATABASE IF EXISTS \`$DB_NAME\`;

-- Create database with UTF8MB4 support
CREATE DATABASE \`$DB_NAME\`
    CHARACTER SET $DB_CHARSET
    COLLATE $DB_COLLATION;

-- Create user if not exists (MySQL 5.7+)
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_USER_PASS';

-- Grant privileges
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';

-- Flush privileges
FLUSH PRIVILEGES;

-- Show created database
SHOW DATABASES LIKE '$DB_NAME';

-- Show user grants
SHOW GRANTS FOR '$DB_USER'@'localhost';
SQL

# Check if successful
if [ $? -eq 0 ]; then
    print_success "Database '$DB_NAME' created successfully"
    print_success "User '$DB_USER'@'localhost' created with all privileges"
    echo
    print_info "Connection details:"
    print_info "  Host: localhost"
    print_info "  Database: $DB_NAME"
    print_info "  User: $DB_USER"
    print_info "  Charset: $DB_CHARSET"
    echo
    print_info "Test connection with:"
    print_info "  mysql -u $DB_USER -p $DB_NAME"
else
    rm -f "$MYSQL_CREDS"
    error_exit "Failed to create database or user"
fi

# Cleanup credentials file
rm -f "$MYSQL_CREDS"

log_success "MySQL database '$DB_NAME' and user '$DB_USER' created successfully"
