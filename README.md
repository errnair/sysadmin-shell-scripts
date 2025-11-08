# System Administration Shell Scripts

Bash and Python scripts for common Linux system administration tasks.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-passing-success)]()
[![Python 3.9+](https://img.shields.io/badge/python-3.9+-blue.svg)]()

## Overview

Collection of scripts for automating sysadmin work on RHEL/CentOS, Ubuntu, and Debian systems. Scripts use a shared library (lib/common.sh) for common functions and support environment variable configuration.

## Features

- Works on RHEL 8/9, Rocky Linux, AlmaLinux, Ubuntu 20.04+, Debian 11+
- No hardcoded passwords or credentials
- Scripts fail loudly with `set -euo pipefail`
- Output in text, JSON, or CSV formats
- Logs to syslog
- Backs up config files before modifying them

## Quick Start

```bash
git clone https://github.com/yourusername/sysadmin-shell-scripts.git
cd sysadmin-shell-scripts

# Install Nginx
sudo ./installation_scripts/install_nginx.sh

# Get system stats as JSON
sudo OUTPUT_FORMAT=json ./server_management/system_stats.sh

# Backup /etc with encryption
sudo ENCRYPT=yes ./utilities/etcbackup.sh
```

## Repository Structure

```
sysadmin-shell-scripts/
├── lib/common.sh              # Shared functions
├── config/                    # Config templates
├── installation_scripts/      # Software installers
├── server_management/         # System management
├── utilities/                 # Backup, password gen, etc.
└── python-scripts/            # Python utilities
```

## Installation Scripts

Scripts for installing common server software.

**install_ansible.sh** - Install Ansible
- Package manager or pip installation
- Can specify version: `ANSIBLE_VERSION=2.16`

**install_flask.sh** - Flask + Gunicorn + Nginx stack
- Creates user with virtualenv
- Sets up systemd service
- Optional SSL with Let's Encrypt

**install_jenkins.sh** - Jenkins CI/CD server
- Checks for Java 17+
- Choose LTS or weekly: `JENKINS_VERSION=lts`
- Shows initial admin password

**install_nagios.sh** - Nagios monitoring
- Builds from source
- Includes Nagios Plugins and NRPE
- Prompts for web UI password

**install_nginx.sh** - Nginx web server
- Three modes: static, reverse proxy, Flask
- Optional SSL: `ENABLE_SSL=yes DOMAIN_NAME=example.com`

**install_python3.sh** - Python 3.12.7
- Tries system packages first
- Falls back to source build
- Verifies checksums

**install_salt.sh** - SaltStack master
- Sets up master server
- Generates example state files

**install_salt_minion.sh** - SaltStack minion
- Configure with: `MINION_ID=webserver01`

**install_squid.sh** - Squid proxy server
- Forward, transparent, or reverse modes
- ACL configuration

## Server Management

**system_stats.sh** - Collect system information
```bash
sudo ./server_management/system_stats.sh           # Text output
sudo OUTPUT_FORMAT=json ./server_management/system_stats.sh
sudo OUTPUT_FORMAT=csv ./server_management/system_stats.sh
```
Detects virtualization (KVM, VMware, etc.), container runtimes (Docker, Podman), and security status.

**change_hostname.sh** - Change system hostname
```bash
sudo ./server_management/change_hostname.sh webserver01
sudo RESTART_NETWORK=yes ./server_management/change_hostname.sh db-server-01
```
Validates hostname format (RFC 1123), detects cloud platforms (AWS, Azure, GCP), updates /etc/hosts.

**selinux_troubleshoot.sh** - SELinux troubleshooting
```bash
sudo ./server_management/selinux_troubleshoot.sh status     # Check status
sudo ./server_management/selinux_troubleshoot.sh denials   # View denials
sudo ./server_management/selinux_troubleshoot.sh suggest   # Get fix suggestions
```
Don't just disable SELinux - figure out what's wrong and fix the policy.

## Utilities

**dirbackup.sh** - Backup directories
```bash
sudo ./utilities/dirbackup.sh /var/www
sudo ENCRYPT=yes RETENTION_DAYS=30 ./utilities/dirbackup.sh /var/www
```
Supports gzip/bzip2/xz compression, GPG encryption, SHA256 verification, retention policy, and incremental backups.

**etcbackup.sh** - Backup /etc
```bash
sudo ./utilities/etcbackup.sh
```
Wrapper around dirbackup.sh with 90-day retention.

**passgen.sh** - Generate passwords
```bash
./utilities/passgen.sh 10 32                    # 10 passwords, 32 chars
PASSWORD_TYPE=special ./utilities/passgen.sh 5  # With special chars
PASSWORD_TYPE=passphrase ./utilities/passgen.sh # Word-based passphrase
OUTPUT_FORMAT=csv ./utilities/passgen.sh 100 > passwords.csv
```
Types: alphanumeric, special, passphrase, PIN. Outputs text, JSON, or CSV.

**webpagedl.sh** - Download web pages
```bash
./utilities/webpagedl.sh https://example.com
RETRY_COUNT=5 ./utilities/webpagedl.sh https://example.com
MIRROR_MODE=yes ./utilities/webpagedl.sh https://example.com
```
Uses wget, curl, or aria2. Has retry logic and authentication support.

## Python Scripts

**checkcpu.py** - CPU information
```bash
python3 python-scripts/checkcpu.py
python3 python-scripts/checkcpu.py --json
python3 python-scripts/checkcpu.py --verbose     # Show all CPU flags
```
Works on Linux and macOS. Shows CPU model, cores, frequency, cache, virtualization.

**timer.py** - Benchmark commands
```bash
python3 python-scripts/timer.py "ls -la"
python3 python-scripts/timer.py -n 100 "curl https://example.com"
python3 python-scripts/timer.py --compare "grep pattern file" "rg pattern file"
```
Shows min, max, mean, median, standard deviation. Supports warmup runs and CSV output.

**portcheck.py** - Check port connectivity
```bash
python3 python-scripts/portcheck.py example.com 443
python3 python-scripts/portcheck.py example.com 20-25  # Port range
```
Tests TCP/UDP ports with configurable timeout.

## Common Library

All bash scripts use `lib/common.sh` which provides:

**Output functions:** print_header, print_info, print_success, print_warning, print_error

**OS detection:** detect_os, detect_os_version, get_package_manager

**Validation:** validate_domain, validate_ip, validate_port, validate_hostname

**Utilities:** require_root, command_exists, backup_file, log_info, read_password

Example:
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

trap cleanup_on_exit EXIT
require_root

OS=$(detect_os)
PKG_MGR=$(get_package_manager)
```

## OS Compatibility

| OS | Version | Status |
|----|---------|--------|
| RHEL/Rocky/AlmaLinux | 8, 9 | Supported |
| CentOS Stream | 8, 9 | Supported |
| Ubuntu | 20.04, 22.04, 24.04 | Supported |
| Debian | 11, 12 | Supported |
| CentOS | 7 | Legacy (EOL) |

Package managers: dnf (RHEL 8+), yum (RHEL 7), apt (Ubuntu/Debian)

## Configuration

Configure scripts via environment variables:

```bash
# Output formatting
OUTPUT_FORMAT=json                  # text, json, or csv
SAVE_TO_FILE=yes
OUTPUT_FILE=/path/to/file

# Installation options
JENKINS_PORT=9090
ANSIBLE_VERSION=2.16
ENABLE_SSL=yes
DOMAIN_NAME=example.com

# Backup options
BACKUP_DIR=/mnt/backups
RETENTION_DAYS=30
ENCRYPT=yes
COMPRESSION=xz                      # gzip, bzip2, or xz

# Password generation
PASSWORD_TYPE=special               # alphanumeric, special, passphrase, pin
OUTPUT_FORMAT=csv
```

See individual script help for all options: `./script.sh --help`

## Security

Scripts follow security practices:

- No hardcoded passwords - prompts with `read -sp` or uses environment variables
- Input validation prevents command injection
- Root checks only where needed
- All operations logged to syslog
- Config files backed up before modification
- SELinux stays enforcing
- Firewall enabled by default

Backups use GPG encryption (AES256) and SHA256 checksums. Web servers can use Let's Encrypt SSL.

## Migration Guide

Old scripts in `server_management/CentOS/`, `server_management/Debian/`, and `miscellaneous/` have been moved:

| Old Location | New Location |
|--------------|--------------|
| `server_management/CentOS/system_stats.sh` | `server_management/system_stats.sh` |
| `server_management/CentOS/change_hostname.sh` | `server_management/change_hostname.sh` |
| `miscellaneous/dirbackup.sh` | `utilities/dirbackup.sh` |
| `miscellaneous/passgen.sh` | `utilities/passgen.sh` |

See [MIGRATION.md](MIGRATION.md) for complete details.

## Examples

See [EXAMPLES.md](EXAMPLES.md) for:
- Installation workflows
- Backup and recovery
- Security hardening
- Monitoring and troubleshooting
- Automation with cron
- Ansible/Salt integration

## Development

```bash
# Syntax check all scripts
find . -name "*.sh" -type f -exec bash -n {} \;

# Check Python scripts
find python-scripts -name "*.py" -exec python3 -m py_compile {} \;
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

## License

MIT License - see [LICENSE](LICENSE) file.

## Support

- Report issues: https://github.com/yourusername/sysadmin-shell-scripts/issues
- Script help: `./script.sh --help`

---

**Note:** Test scripts in non-production first. Scripts requiring root can make system-level changes.
