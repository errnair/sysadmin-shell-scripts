# System Administration Shell Scripts

Modern, secure, and cross-platform system administration scripts for Linux servers.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-passing-success)]()
[![Python 3.9+](https://img.shields.io/badge/python-3.9+-blue.svg)]()

## Overview

A comprehensive collection of modernized bash and Python scripts for automating system administration tasks. All scripts feature multi-OS support, security best practices, comprehensive error handling, and integration with a shared function library.

##  Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Repository Structure](#repository-structure)
- [Script Categories](#script-categories)
  - [Installation Scripts](#installation-scripts)
  - [Server Management](#server-management)
  - [Utilities](#utilities)
  - [Python Scripts](#python-scripts)
- [Common Library](#common-library)
- [OS Compatibility](#os-compatibility)
- [Configuration](#configuration)
- [Security](#security)
- [Migration Guide](#migration-guide)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Multi-OS Support**: RHEL 8/9, Rocky Linux, AlmaLinux, CentOS Stream, Ubuntu 20.04+, Debian 11+
- **Security-First**: No hardcoded credentials, secure password input, input validation
- **Modern Standards**: `set -euo pipefail`, trap cleanup, comprehensive error handling
- **Shared Library**: Reusable functions via `lib/common.sh` (548 lines)
- **Multiple Output Formats**: Text, JSON, CSV for integration with monitoring tools
- **Comprehensive Logging**: Syslog integration with colored terminal output
- **Environment Variable Configuration**: Flexible configuration without editing scripts
- **Backup and Rollback**: Automatic configuration backups before changes

## Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/sysadmin-shell-scripts.git
cd sysadmin-shell-scripts

# Example: Install Nginx with SSL support
sudo ./installation_scripts/install_nginx.sh

# Example: Check system information in JSON format
sudo OUTPUT_FORMAT=json ./server_management/system_stats.sh

# Example: Backup /etc with encryption
sudo ENCRYPT=yes ./utilities/etcbackup.sh

# Example: Generate 10 secure passwords
./utilities/passgen.sh 10 24

# Example: Check CPU information
python3 python-scripts/checkcpu.py --json
```

## Repository Structure

```
sysadmin-shell-scripts/
├── lib/
│   └── common.sh                    # Shared function library (548 lines)
├── config/
│   ├── defaults.conf                # Global defaults
│   └── README.md                    # Configuration guide
├── installation_scripts/            # Software installation (9 scripts)
│   ├── install_ansible.sh          # Ansible automation platform
│   ├── install_flask.sh            # Flask + Gunicorn + Nginx stack
│   ├── install_jenkins.sh          # Jenkins CI/CD server
│   ├── install_nagios.sh           # Nagios monitoring system
│   ├── install_nginx.sh            # Nginx web server
│   ├── install_python3.sh          # Python 3 from source
│   ├── install_salt.sh             # SaltStack master
│   ├── install_salt_minion.sh      # SaltStack minion
│   ├── install_squid.sh            # Squid proxy server
│   ├── checkssh_conn.sh            # SSH connection checker
│   ├── create_db.sh                # MySQL database creator
│   └── sync_emails.sh              # IMAP email synchronization
├── server_management/               # Server management tools
│   ├── change_hostname.sh          # Hostname management with cloud support
│   ├── system_stats.sh             # System information gatherer
│   └── selinux_troubleshoot.sh     # SELinux troubleshooting tool
├── utilities/                       # Utility scripts
│   ├── dirbackup.sh                # Directory backup with encryption
│   ├── etcbackup.sh                # /etc backup wrapper
│   ├── passgen.sh                  # Secure password generator
│   └── webpagedl.sh                # Web page downloader
└── python-scripts/                  # Python utilities
    ├── checkcpu.py                 # CPU information tool
    ├── portcheck.py                # Port connectivity checker
    └── timer.py                    # Command benchmarking tool
```

## Script Categories

### Installation Scripts

All installation scripts support RHEL/Rocky/AlmaLinux/Ubuntu/Debian and include:
- Modern repository configuration
- Version selection
- Firewall configuration (firewalld and ufw)
- SELinux configuration (where applicable)
- Service management with systemd
- Comprehensive post-installation documentation

| Script | Description | Key Features |
|--------|-------------|--------------|
| `install_ansible.sh` | Ansible automation platform | Package or pip installation, generates ansible.cfg and inventory, optional collection installation |
| `install_flask.sh` | Flask + Gunicorn + Nginx | Creates user with venv, systemd service, optional SSL, Git deployment support |
| `install_jenkins.sh` | Jenkins CI/CD server | Java 17+ validation, LTS/weekly selection, displays initial admin password |
| `install_nagios.sh` | Nagios Core + Plugins + NRPE | Builds from source, secure password input, example configs, check_nrpe command |
| `install_nginx.sh` | Nginx web server | 3 app types (static/proxy/flask), optional SSL with Let's Encrypt, SELinux config |
| `install_python3.sh` | Python 3.12.7 from source | Auto-detect system packages first, checksum verification, pip setup |
| `install_salt.sh` | SaltStack master | Modern SaltProject repos, generates example states, minion key management |
| `install_salt_minion.sh` | SaltStack minion | Master validation, custom minion ID, connection testing |
| `install_squid.sh` | Squid proxy server | 3 modes (forward/transparent/reverse), ACLs, site blocking |

**Usage Examples:**

```bash
# Install Ansible with specific version
ANSIBLE_VERSION=2.16 ./installation_scripts/install_ansible.sh

# Install Nginx with Flask application support
./installation_scripts/install_nginx.sh
# Choose "flask" when prompted for application type

# Install Jenkins with custom port
JENKINS_PORT=9090 ./installation_scripts/install_jenkins.sh

# Install Python 3 (tries system packages first, falls back to source)
./installation_scripts/install_python3.sh

# Install Salt minion with custom ID
MINION_ID=webserver01 ./installation_scripts/install_salt_minion.sh 192.168.1.100
```

### Server Management

System administration and configuration tools with multi-OS support.

| Script | Description | Key Features |
|--------|-------------|--------------|
| `system_stats.sh` | System information gatherer | Text/JSON/CSV output, virtualization detection, container runtime detection, security status |
| `change_hostname.sh` | Hostname management | RFC 1123 validation, cloud provider detection (AWS/Azure/GCP), auto /etc/hosts update, config backup |
| `selinux_troubleshoot.sh` | SELinux troubleshooting | 5 commands (status/denials/suggest/permissive/enforcing), audit2why integration, security warnings |

**Usage Examples:**

```bash
# Get system stats in JSON format
sudo OUTPUT_FORMAT=json ./server_management/system_stats.sh

# Save system stats to file
sudo SAVE_TO_FILE=yes OUTPUT_FILE=/tmp/stats.json ./server_management/system_stats.sh

# Change hostname (safe, no network restart)
sudo ./server_management/change_hostname.sh webserver01

# Change hostname with network restart
sudo RESTART_NETWORK=yes ./server_management/change_hostname.sh db-server-01

# Check SELinux status
sudo ./server_management/selinux_troubleshoot.sh status

# View recent SELinux denials
sudo ./server_management/selinux_troubleshoot.sh denials

# Get policy fix suggestions
sudo ./server_management/selinux_troubleshoot.sh suggest

# Set SELinux to permissive (temporary, with warnings)
sudo ./server_management/selinux_troubleshoot.sh permissive
```

### Utilities

General-purpose utility scripts with enhanced features.

| Script | Description | Key Features |
|--------|-------------|--------------|
| `dirbackup.sh` | Directory backup tool | Multiple compression formats, GPG encryption, SHA256 verification, retention policy, incremental backups |
| `etcbackup.sh` | /etc backup wrapper | Wrapper around dirbackup.sh, 90-day retention default, inherits all dirbackup features |
| `passgen.sh` | Password generator | 4 types (alphanumeric/special/passphrase/PIN), strength assessment, text/JSON/CSV output, clipboard integration |
| `webpagedl.sh` | Web page downloader | Multi-method (wget/curl/aria2), retry logic, mirror mode, authentication support, download verification |

**Usage Examples:**

```bash
# Backup directory with encryption
sudo ENCRYPT=yes ./utilities/dirbackup.sh /var/www

# Backup with 7-day retention
sudo RETENTION_DAYS=7 ./utilities/dirbackup.sh /home

# Incremental backup
sudo INCREMENTAL=yes ./utilities/dirbackup.sh /data

# Backup /etc (uses optimized defaults)
sudo ./utilities/etcbackup.sh

# Generate 10 strong passwords with special characters
PASSWORD_TYPE=special ./utilities/passgen.sh 10 32

# Generate memorable passphrase (5 words)
PASSWORD_TYPE=passphrase ./utilities/passgen.sh 1 5

# Generate passwords in CSV format
OUTPUT_FORMAT=csv ./utilities/passgen.sh 100 16 > passwords.csv

# Download webpage with retry logic
RETRY_COUNT=5 ./utilities/webpagedl.sh https://example.com

# Mirror entire site
MIRROR_MODE=yes ./utilities/webpagedl.sh https://example.com

# Download with authentication
AUTH_USER=admin AUTH_PASS=secret ./utilities/webpagedl.sh https://example.com/protected
```

### Python Scripts

Python 3 utilities with type hints and cross-platform support.

| Script | Description | Platforms | Key Features |
|--------|-------------|-----------|--------------|
| `checkcpu.py` | CPU information tool | Linux, macOS | Detailed CPU info, JSON output, virtual CPU detection, optional usage/temperature |
| `portcheck.py` | Port connectivity checker | All | TCP/UDP support, port range scanning, JSON output, concurrent scanning |
| `timer.py` | Command benchmarking | All | Statistics (min/max/mean/median/stdev), compare mode, JSON/CSV output, warmup runs |

**Usage Examples:**

```bash
# Display CPU information
python3 python-scripts/checkcpu.py

# Get CPU info in JSON format
python3 python-scripts/checkcpu.py --json

# Show all CPU flags/features
python3 python-scripts/checkcpu.py --verbose

# Check if port is open
python3 python-scripts/portcheck.py example.com 22

# Scan port range
python3 python-scripts/portcheck.py example.com 20-25

# Time a command
python3 python-scripts/timer.py "ls -la"

# Run 10 iterations with statistics
python3 python-scripts/timer.py -n 10 "curl https://example.com"

# Compare two commands
python3 python-scripts/timer.py --compare "grep pattern file" "rg pattern file"

# Benchmark with warmup runs
python3 python-scripts/timer.py -n 100 --warmup 5 "echo test"

# Export benchmark results to CSV
python3 python-scripts/timer.py --csv -n 50 "command" > results.csv
```

## Common Library

All bash scripts leverage `lib/common.sh` (548 lines) providing:

### Output Functions
- `print_header` - Section headers with formatting
- `print_info` - Informational messages (blue)
- `print_success` - Success messages (green)
- `print_warning` - Warning messages (yellow)
- `print_error` - Error messages (red)

### OS Detection
- `detect_os` - Detect OS family (rhel/debian)
- `detect_os_version` - Get OS version
- `get_package_manager` - Get package manager (dnf/yum/apt)

### Validation
- `validate_domain` - Validate domain names
- `validate_ip` - Validate IPv4 addresses
- `validate_port` - Validate port numbers (1-65535)
- `validate_hostname` - Validate RFC 1123 hostnames

### Utilities
- `require_root` - Ensure script runs as root
- `command_exists` - Check if command is available
- `backup_file` - Backup file with timestamp
- `cleanup_on_exit` - Cleanup function for trap
- `log_info`, `log_success`, `log_error` - Syslog logging
- `read_password` - Secure password input

**Example Usage:**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

trap cleanup_on_exit EXIT
require_root

OS=$(detect_os)
PKG_MGR=$(get_package_manager)

print_header "My Script"
print_info "Detected OS: $OS"
print_info "Package manager: $PKG_MGR"

validate_domain "example.com" || error_exit "Invalid domain"

log_success "Script completed successfully"
```

## OS Compatibility

| Operating System | Version | Status | Notes |
|-----------------|---------|--------|-------|
| RHEL | 8, 9 | Fully supported | All scripts tested |
| Rocky Linux | 8, 9 | Fully supported | All scripts tested |
| AlmaLinux | 8, 9 | Fully supported | All scripts tested |
| CentOS Stream | 8, 9 | Fully supported | All scripts tested |
| Ubuntu | 20.04, 22.04, 24.04 | Fully supported | All scripts tested |
| Debian | 11, 12 | Fully supported | All scripts tested |
| CentOS | 7 | Legacy | EOL, limited support |

**Supported Package Managers:**
- `dnf` (RHEL 8+, Rocky 8+, AlmaLinux 8+)
- `yum` (Legacy RHEL 7, CentOS 7)
- `apt` (Ubuntu, Debian)

## Configuration

Scripts support configuration via:

1. **Environment Variables** (Recommended)
   ```bash
   BACKUP_DIR=/mnt/backups RETENTION_DAYS=7 ./utilities/dirbackup.sh /data
   ```

2. **Configuration Files** (Optional)
   ```bash
   cp config/backup.conf.example config/backup.conf
   vim config/backup.conf
   ```

3. **Command-Line Arguments**
   ```bash
   ./utilities/passgen.sh 10 32
   ```

See [config/README.md](config/README.md) for detailed configuration documentation.

## Security

### Best Practices Implemented

- **No Hardcoded Credentials**: All passwords via `read -sp` or environment variables
- **Input Validation**: All user inputs validated before use
- **Principle of Least Privilege**: Root checks only where necessary
- **Secure Defaults**: SELinux enforcing, firewall enabled, strong passwords
- **Comprehensive Logging**: All operations logged to syslog
- **Automatic Backups**: Configuration files backed up before modification
- **Error Handling**: `set -euo pipefail` with trap cleanup in all scripts
- **No Password Leakage**: Passwords never in command-line arguments or logs

### Security Features by Script

- **SELinux**: Proper contexts and booleans, no `setenforce 0`
- **Firewall**: Both firewalld and ufw support
- **SSL/TLS**: Let's Encrypt integration in web server installers
- **Password Security**: Minimum 8 characters, complexity requirements where applicable
- **Backup Encryption**: GPG with AES256 in backup scripts

## Migration Guide

Scripts have been reorganized for better structure. See [MIGRATION.md](MIGRATION.md) for complete migration guide.

### Quick Migration Reference

| Old Location | New Location |
|--------------|--------------|
| `server_management/CentOS/*.sh` | `server_management/*.sh` or `installation_scripts/*.sh` |
| `server_management/Debian/*.sh` | `installation_scripts/*.sh` |
| `miscellaneous/*.sh` | `utilities/*.sh` or `installation_scripts/*.sh` |

All old locations have `DEPRECATED_*.sh` files that display the new location and migration examples.

## Examples

See [EXAMPLES.md](EXAMPLES.md) for comprehensive usage examples including:
- Complete installation workflows
- Backup and recovery procedures
- Security hardening examples
- Monitoring and troubleshooting
- Integration with configuration management tools

## Troubleshooting

### Common Issues

**Script fails with "command not found"**
```bash
# Install missing dependencies
sudo dnf install <package>  # RHEL-based
sudo apt install <package>  # Debian-based
```

**Permission denied**
```bash
# Ensure script is executable
chmod +x script.sh

# Run with sudo if root required
sudo ./script.sh
```

**SELinux denials**
```bash
# Use SELinux troubleshooting tool
sudo ./server_management/selinux_troubleshoot.sh denials
sudo ./server_management/selinux_troubleshoot.sh suggest
```

**Script exits with "must be run as root"**
```bash
# Run with sudo
sudo ./script.sh
```

For more troubleshooting, see inline script help:
```bash
./script.sh --help
./script.sh help
```

## Development

### Prerequisites

- Bash 4.0+
- Python 3.9+
- ShellCheck (for linting)

### Testing

```bash
# Syntax check all bash scripts
find . -name "*.sh" -type f -exec bash -n {} \;

# Syntax check all Python scripts
find python-scripts -name "*.py" -exec python3 -m py_compile {} \;
```

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Code style guidelines
- Testing requirements
- Pull request process
- Commit message format

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and changes.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: Report bugs via [GitHub Issues](https://github.com/yourusername/sysadmin-shell-scripts/issues)
- **Documentation**: Check script help output and inline comments
- **Migration**: See [MIGRATION.md](MIGRATION.md) for upgrade paths

---

**Note**: Always test scripts in a non-production environment first. Scripts requiring root access can make system-level changes.
