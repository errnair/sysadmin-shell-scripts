# Migration Guide

This guide helps you migrate from old script locations to the modernized versions.

## Table of Contents

- [Overview](#overview)
- [Breaking Changes](#breaking-changes)
- [Script Location Changes](#script-location-changes)
- [Feature Changes](#feature-changes)
- [Migration Examples](#migration-examples)
- [Environment Variables](#environment-variables)
- [Testing Your Migration](#testing-your-migration)

## Overview

All scripts have been reorganized and modernized with:

- **Multi-OS support**: RHEL 8/9, Rocky Linux, AlmaLinux, CentOS Stream, Ubuntu 20.04+, Debian 11+
- **Security improvements**: No hardcoded credentials, input validation, secure password handling
- **Common library**: Shared functions in `lib/common.sh`
- **Enhanced features**: Multiple output formats, better error handling, comprehensive logging
- **Consistent structure**: Scripts organized by function, not by OS

## Breaking Changes

### 1. Directory Structure

Scripts are no longer organized by OS. Multi-OS scripts are in shared directories:

- `server_management/CentOS/` → `server_management/` or `installation_scripts/`
- `server_management/Debian/` → `installation_scripts/`
- `miscellaneous/` → `utilities/` or `installation_scripts/`

### 2. Script Names

Some scripts have been renamed to better reflect their purpose:

- `permissive_selinux.sh` → `selinux_troubleshoot.sh` (renamed to emphasize troubleshooting)
- `nginx/newuser.sh` → `install_flask.sh` (consolidated Flask installation)

### 3. Command-Line Arguments

Most scripts maintain backward compatibility, but some have enhanced syntax:

**Old (passgen.sh)**:
```bash
./miscellaneous/passgen.sh
```

**New (passgen.sh)**:
```bash
./utilities/passgen.sh [count] [length]
PASSWORD_TYPE=special ./utilities/passgen.sh 10 32
OUTPUT_FORMAT=json ./utilities/passgen.sh 5 16
```

### 4. Environment Variables

Many scripts now support environment variable configuration instead of hardcoded values:

**Installation scripts**:
- `JENKINS_PORT` - Custom Jenkins port (default: 8080)
- `ANSIBLE_VERSION` - Specific Ansible version
- `PYTHON_VERSION` - Python version to install

**Backup scripts**:
- `BACKUP_DIR` - Backup destination directory
- `RETENTION_DAYS` - Number of days to keep backups
- `ENCRYPT` - Enable GPG encryption (yes/no)
- `COMPRESSION` - Compression type (gzip/bzip2/xz)

**Output formatting**:
- `OUTPUT_FORMAT` - Output format (text/json/csv)
- `SAVE_TO_FILE` - Save output to file (yes/no)
- `OUTPUT_FILE` - File path for output

## Script Location Changes

### Server Management Scripts

| Old Location | New Location | Status |
|--------------|--------------|--------|
| `server_management/CentOS/system_stats.sh` | `server_management/system_stats.sh` | Multi-OS |
| `server_management/CentOS/change_hostname.sh` | `server_management/change_hostname.sh` | Multi-OS |
| `server_management/CentOS/permissive_selinux.sh` | `server_management/selinux_troubleshoot.sh` | Renamed |
| `server_management/CentOS/create_db.sh` | `installation_scripts/create_db.sh` | Moved |
| `server_management/CentOS/sync_emails.sh` | `installation_scripts/sync_emails.sh` | Moved |
| `server_management/CentOS/nginx/newuser.sh` | `installation_scripts/install_flask.sh` | Replaced |

### Installation Scripts

| Old Location | New Location | Status |
|--------------|--------------|--------|
| `server_management/Debian/install_salt_minion.sh` | `installation_scripts/install_salt_minion.sh` | Multi-OS |
| `miscellaneous/checkssh_conn.sh` | `installation_scripts/checkssh_conn.sh` | Moved |

### Utility Scripts

| Old Location | New Location | Status |
|--------------|--------------|--------|
| `miscellaneous/dirbackup.sh` | `utilities/dirbackup.sh` | Enhanced |
| `miscellaneous/etcbackup.sh` | `utilities/etcbackup.sh` | Enhanced |
| `miscellaneous/passgen.sh` | `utilities/passgen.sh` | Enhanced |
| `miscellaneous/webpagedl.sh` | `utilities/webpagedl.sh` | Enhanced |

### Python Scripts

Python scripts remain in `python-scripts/` but have been completely rewritten with Python 3, type hints, and cross-platform support.

| Script | Changes |
|--------|---------|
| `checkcpu.py` | Rewritten for Python 3, Linux/macOS support, JSON output |
| `timer.py` | Rewritten as benchmarking tool with statistics |
| `portcheck.py` | Maintained, Python 3 compatible |

## Feature Changes

### system_stats.sh

**Old behavior** (CentOS only):
```bash
./server_management/CentOS/system_stats.sh
# Output: Basic text output
```

**New features** (Multi-OS with enhanced output):
```bash
# Text output (default)
sudo ./server_management/system_stats.sh

# JSON output
sudo OUTPUT_FORMAT=json ./server_management/system_stats.sh

# CSV output
sudo OUTPUT_FORMAT=csv ./server_management/system_stats.sh

# Save to file
sudo OUTPUT_FORMAT=json SAVE_TO_FILE=yes OUTPUT_FILE=/tmp/stats.json ./server_management/system_stats.sh
```

**New capabilities**:
- Virtualization detection (KVM, VMware, etc.)
- Container runtime detection (Docker, Podman)
- Security status (SELinux, firewall)
- Multiple output formats

### change_hostname.sh

**Old behavior** (CentOS only):
```bash
./server_management/CentOS/change_hostname.sh webserver01
```

**New features** (Multi-OS with validation):
```bash
# Change hostname (safe, no network restart)
sudo ./server_management/change_hostname.sh webserver01

# Change hostname with network restart
sudo RESTART_NETWORK=yes ./server_management/change_hostname.sh db-server-01
```

**New capabilities**:
- RFC 1123 hostname validation
- Cloud provider detection (AWS, Azure, GCP)
- Automatic /etc/hosts update
- Configuration backup before changes
- Works on RHEL, Ubuntu, Debian

### selinux_troubleshoot.sh (formerly permissive_selinux.sh)

**Old behavior** (Set permissive mode):
```bash
./server_management/CentOS/permissive_selinux.sh
```

**New features** (Comprehensive SELinux troubleshooting):
```bash
# Check SELinux status
sudo ./server_management/selinux_troubleshoot.sh status

# View recent denials
sudo ./server_management/selinux_troubleshoot.sh denials

# Get policy fix suggestions
sudo ./server_management/selinux_troubleshoot.sh suggest

# Set permissive mode (with warnings)
sudo ./server_management/selinux_troubleshoot.sh permissive

# Re-enable enforcing mode
sudo ./server_management/selinux_troubleshoot.sh enforcing
```

**New capabilities**:
- 5 commands for different SELinux operations
- audit2why integration for fix suggestions
- Security warnings when disabling enforcement
- Temporary vs persistent mode changes

### dirbackup.sh

**Old behavior** (Basic backup):
```bash
./miscellaneous/dirbackup.sh /var/www
```

**New features** (Enhanced backup with options):
```bash
# Basic backup
sudo ./utilities/dirbackup.sh /var/www

# Encrypted backup
sudo ENCRYPT=yes ./utilities/dirbackup.sh /var/www

# Custom retention (7 days)
sudo RETENTION_DAYS=7 ./utilities/dirbackup.sh /home

# Incremental backup
sudo INCREMENTAL=yes ./utilities/dirbackup.sh /data

# Custom compression
sudo COMPRESSION=xz ./utilities/dirbackup.sh /opt

# All options combined
sudo BACKUP_DIR=/mnt/backups RETENTION_DAYS=30 ENCRYPT=yes COMPRESSION=xz ./utilities/dirbackup.sh /var/www
```

**New capabilities**:
- Multiple compression formats (gzip/bzip2/xz)
- GPG encryption with AES256
- SHA256 checksum verification
- Retention policy (auto-cleanup old backups)
- Incremental backups
- Multi-OS support

### etcbackup.sh

**Old behavior** (Basic /etc backup):
```bash
./miscellaneous/etcbackup.sh
```

**New features** (Wrapper with optimized defaults):
```bash
# Backup /etc with 90-day retention (default)
sudo ./utilities/etcbackup.sh

# With encryption
sudo ENCRYPT=yes ./utilities/etcbackup.sh

# Custom retention
sudo RETENTION_DAYS=180 ./utilities/etcbackup.sh
```

**New implementation**:
- Now a wrapper around `dirbackup.sh`
- Inherits all dirbackup features
- Optimized defaults for /etc backups
- 90-day retention default

### passgen.sh

**Old behavior** (Simple password):
```bash
./miscellaneous/passgen.sh
```

**New features** (Multiple types and formats):
```bash
# Generate 10 alphanumeric passwords (16 chars)
./utilities/passgen.sh 10 16

# Generate with special characters
PASSWORD_TYPE=special ./utilities/passgen.sh 10 32

# Generate passphrase (5 words)
PASSWORD_TYPE=passphrase ./utilities/passgen.sh 1 5

# Generate PIN
PASSWORD_TYPE=pin ./utilities/passgen.sh 5 6

# JSON output
OUTPUT_FORMAT=json ./utilities/passgen.sh 5 16

# CSV output
OUTPUT_FORMAT=csv ./utilities/passgen.sh 100 16 > passwords.csv
```

**New capabilities**:
- 4 password types (alphanumeric/special/passphrase/PIN)
- Password strength assessment with entropy calculation
- Avoid ambiguous characters option
- Multiple output formats (text/JSON/CSV)
- Clipboard integration
- Bulk password generation

### webpagedl.sh

**Old behavior** (Basic download):
```bash
./miscellaneous/webpagedl.sh https://example.com
```

**New features** (Multi-method with retry):
```bash
# Download with retry logic
RETRY_COUNT=5 ./utilities/webpagedl.sh https://example.com

# Mirror entire site
MIRROR_MODE=yes ./utilities/webpagedl.sh https://example.com

# Download with authentication
AUTH_USER=admin AUTH_PASS=secret ./utilities/webpagedl.sh https://example.com/protected

# Use specific method
DOWNLOAD_METHOD=aria2 ./utilities/webpagedl.sh https://example.com
```

**New capabilities**:
- Multi-method support (wget/curl/aria2)
- Retry logic with configurable count
- Mirror mode for entire sites
- Authentication support
- Download verification

### Python Scripts

#### checkcpu.py

**Old behavior** (Python 2, basic output):
```bash
python python-scripts/checkcpu.py
# Output: 11
```

**New features** (Python 3, comprehensive):
```bash
# Display CPU information
python3 python-scripts/checkcpu.py

# JSON output
python3 python-scripts/checkcpu.py --json

# Verbose with all CPU flags
python3 python-scripts/checkcpu.py --verbose
```

**New capabilities**:
- Python 3 with type hints
- Cross-platform (Linux, macOS)
- Detailed CPU information
- JSON output support
- Virtual CPU detection
- Optional CPU usage and temperature

#### timer.py

**Old behavior** (Python 2, simple counter):
```bash
python python-scripts/timer.py
# Output: Counts 0 to 100
```

**New features** (Python 3, benchmarking tool):
```bash
# Time a single command
python3 python-scripts/timer.py "ls -la"

# Run 10 iterations with statistics
python3 python-scripts/timer.py -n 10 "curl https://example.com"

# Compare two commands
python3 python-scripts/timer.py --compare "grep pattern file" "rg pattern file"

# Benchmark with warmup runs
python3 python-scripts/timer.py -n 100 --warmup 5 "echo test"

# CSV output
python3 python-scripts/timer.py --csv -n 50 "command" > results.csv
```

**New capabilities**:
- Command benchmarking with statistics
- min/max/mean/median/stdev calculations
- Compare mode for two commands
- Warmup runs
- JSON and CSV output
- Human-readable time formatting

## Migration Examples

### Example 1: System Statistics Automation

**Old script**:
```bash
#!/bin/bash
./server_management/CentOS/system_stats.sh > /var/log/system-stats.txt
```

**New script**:
```bash
#!/bin/bash
sudo OUTPUT_FORMAT=json SAVE_TO_FILE=yes OUTPUT_FILE=/var/log/system-stats.json \
    ./server_management/system_stats.sh
```

### Example 2: Daily Backup Cron Job

**Old crontab**:
```
0 2 * * * /root/sysadmin-shell-scripts/miscellaneous/etcbackup.sh
```

**New crontab**:
```
0 2 * * * BACKUP_DIR=/mnt/backups ENCRYPT=yes RETENTION_DAYS=90 \
    /root/sysadmin-shell-scripts/utilities/etcbackup.sh
```

### Example 3: Password Generation

**Old usage**:
```bash
./miscellaneous/passgen.sh
```

**New usage**:
```bash
# Generate strong password with special characters
PASSWORD_TYPE=special ./utilities/passgen.sh 1 32

# Generate batch of passwords for CSV import
OUTPUT_FORMAT=csv ./utilities/passgen.sh 100 16 > user-passwords.csv
```

### Example 4: Hostname Change

**Old usage**:
```bash
./server_management/CentOS/change_hostname.sh webserver01
```

**New usage** (same syntax, enhanced features):
```bash
# Works on RHEL, Ubuntu, Debian
sudo ./server_management/change_hostname.sh webserver01

# With validation and cloud detection
sudo RESTART_NETWORK=yes ./server_management/change_hostname.sh webserver01.example.com
```

### Example 5: SELinux Troubleshooting

**Old workflow** (just disable):
```bash
./server_management/CentOS/permissive_selinux.sh
```

**New workflow** (troubleshoot first):
```bash
# Check current status
sudo ./server_management/selinux_troubleshoot.sh status

# View what's being denied
sudo ./server_management/selinux_troubleshoot.sh denials

# Get suggestions for fixing the policy
sudo ./server_management/selinux_troubleshoot.sh suggest

# Only set permissive if absolutely necessary
sudo ./server_management/selinux_troubleshoot.sh permissive
```

## Environment Variables

### Common Variables (All Scripts)

```bash
# Logging
LOG_LEVEL=debug          # debug, info, warning, error
QUIET_MODE=yes           # Suppress non-essential output

# Output formatting
OUTPUT_FORMAT=json       # text, json, csv
SAVE_TO_FILE=yes         # yes, no
OUTPUT_FILE=/path/file   # Path to output file
```

### Installation Scripts

```bash
# General
SKIP_FIREWALL=yes        # Skip firewall configuration
SKIP_SELINUX=yes         # Skip SELinux configuration

# Ansible
ANSIBLE_VERSION=2.16     # Specific version
INSTALL_METHOD=pip       # pip or package

# Jenkins
JENKINS_PORT=9090        # Custom port
JENKINS_VERSION=lts      # lts or weekly

# Nginx
APP_TYPE=flask           # static, proxy, flask
ENABLE_SSL=yes           # yes or no
DOMAIN_NAME=example.com  # Domain for SSL

# Python
PYTHON_VERSION=3.12.7    # Version to install

# Salt
SALT_VERSION=3006        # Salt version
MINION_ID=server01       # Custom minion ID
```

### Backup Scripts

```bash
# Backup configuration
BACKUP_DIR=/mnt/backups  # Backup destination
RETENTION_DAYS=30        # Days to keep backups
INCREMENTAL=yes          # Incremental backup

# Compression
COMPRESSION=xz           # gzip, bzip2, xz
VERIFY=yes               # Verify with SHA256

# Encryption
ENCRYPT=yes              # GPG encryption
GPG_RECIPIENT=user@example.com
```

### Utility Scripts

```bash
# Password generation
PASSWORD_TYPE=special    # alphanumeric, special, passphrase, pin
AVOID_AMBIGUOUS=yes      # Avoid similar characters
CLIPBOARD=yes            # Copy to clipboard

# Web download
DOWNLOAD_METHOD=aria2    # wget, curl, aria2
RETRY_COUNT=5            # Number of retries
MIRROR_MODE=yes          # Mirror entire site
AUTH_USER=username       # HTTP authentication
AUTH_PASS=password
```

## Testing Your Migration

### 1. Test in Non-Production First

Always test modernized scripts in a development or staging environment:

```bash
# Clone to test environment
git clone https://github.com/yourusername/sysadmin-shell-scripts.git /tmp/test-scripts
cd /tmp/test-scripts

# Test with your existing parameters
sudo ./utilities/dirbackup.sh /tmp/test-data
```

### 2. Verify Output Format Changes

If you parse script output, test the new output formats:

```bash
# Test JSON output
sudo OUTPUT_FORMAT=json ./server_management/system_stats.sh > test.json
python3 -m json.tool test.json  # Verify valid JSON
```

### 3. Test Environment Variables

Verify environment variable configuration works:

```bash
# Test backup with encryption
sudo ENCRYPT=yes RETENTION_DAYS=7 ./utilities/dirbackup.sh /tmp/test
```

### 4. Update Automation

Update cron jobs, systemd timers, and automation scripts:

```bash
# Test cron job syntax
echo "0 2 * * * BACKUP_DIR=/mnt/backups ./utilities/etcbackup.sh" | crontab -
crontab -l  # Verify
```

### 5. Syntax Validation

All scripts pass bash syntax checking:

```bash
# Validate bash scripts
find . -name "*.sh" -type f -exec bash -n {} \;

# Validate Python scripts
find python-scripts -name "*.py" -exec python3 -m py_compile {} \;
```

## Getting Help

If you encounter issues during migration:

1. Check script help output:
   ```bash
   ./script.sh --help
   ./script.sh help
   ```

2. Review inline comments in scripts

3. Check [README.md](README.md) for detailed documentation

4. Report issues at https://github.com/yourusername/sysadmin-shell-scripts/issues

## Timeline

- **Now**: All modernized scripts available, old scripts remain for compatibility
- **Future**: Old OS-specific directories may be removed
- **Recommendation**: Migrate to new scripts as soon as possible to benefit from enhancements

## Summary Checklist

- [ ] Review script location changes table
- [ ] Identify all scripts used in your automation
- [ ] Test new scripts in non-production environment
- [ ] Update cron jobs and systemd timers
- [ ] Update automation scripts and playbooks
- [ ] Update documentation and runbooks
- [ ] Verify environment variable configuration
- [ ] Test output format changes if parsing output
- [ ] Update backup destinations if changed
- [ ] Validate all changes in production-like environment
