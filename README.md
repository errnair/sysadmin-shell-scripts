# System Administration Shell Scripts

Modern, secure, and cross-platform system administration scripts for Linux servers.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-passing-success)]()
[![Python 3.9+](https://img.shields.io/badge/python-3.9+-blue.svg)]()

## Overview

This repository contains a comprehensive collection of bash and Python scripts designed to automate and simplify common system administration tasks on Linux servers. The scripts have been modernized with security best practices, multi-OS support, and extensive error handling.

## Features

- ✅ **Multi-OS Support**: RHEL 8/9, Rocky Linux, AlmaLinux, CentOS Stream, Ubuntu 20.04+, Debian 11+
- ✅ **Security-First**: No hardcoded credentials, input validation, secure password handling
- ✅ **Modern Standards**: `set -euo pipefail`, comprehensive error handling, proper logging
- ✅ **Shared Library**: Reusable functions via `lib/common.sh`
- ✅ **Configuration Files**: Template-based configuration in `config/` directory
- ✅ **Dry-Run Mode**: Test scripts without making actual changes
- ✅ **Comprehensive Logging**: Syslog integration and colored terminal output

## Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/sysadmin-shell-scripts.git
cd sysadmin-shell-scripts

# Example: Install Ansible
sudo ./installation_scripts/install_ansible.sh

# Example: Backup /etc directory with 30-day retention
sudo ./miscellaneous/etcbackup.sh

# Example: Check if port 22 is open on a host
python3 python-scripts/portcheck.py example.com 22
```

## Repository Structure

```
sysadmin-shell-scripts/
├── lib/                          # Shared function library
│   └── common.sh                 # Common functions for all scripts
├── config/                       # Configuration templates
│   ├── defaults.conf             # Global defaults
│   ├── *.conf.example            # Script-specific configs
│   └── README.md                 # Configuration guide
├── installation_scripts/         # Software installation scripts
│   ├── install_ansible.sh
│   ├── install_flask.sh
│   ├── install_jenkins.sh
│   ├── install_nagios.sh
│   ├── install_nginx.sh
│   ├── install_python3.sh
│   ├── install_salt.sh
│   ├── install_salt_minion.sh
│   └── install_squid.sh
├── miscellaneous/                # Utility scripts
│   ├── checkssh_conn.sh          # Check SSH connections
│   ├── dirbackup.sh              # Directory backup
│   ├── etcbackup.sh              # /etc backup
│   ├── passgen.sh                # Password generator
│   └── webpagedl.sh              # Webpage downloader
├── python-scripts/               # Python utilities
│   ├── checkcpu.py               # CPU information
│   ├── portcheck.py              # Port connectivity checker
│   └── timer.py                  # Execution timer
└── server_management/            # Server management scripts
    ├── CentOS/
    │   ├── change_hostname.sh    # Change server hostname
    │   ├── create_db.sh          # MySQL database creator
    │   ├── permissive_selinux.sh # SELinux configuration
    │   ├── sync_emails.sh        # IMAP email sync
    │   ├── system_stats.sh       # System statistics
    │   └── nginx/
    │       └── newuser.sh        # Create Nginx user
    └── Debian/
        └── install_salt_minion.sh # Salt minion for Debian
```

## Installation Scripts

### Available Installers

| Script | Description | OS Support |
|--------|-------------|------------|
| `install_ansible.sh` | Install Ansible automation platform | RHEL, Debian |
| `install_flask.sh` | Install Flask + Nginx + Gunicorn stack | RHEL |
| `install_jenkins.sh` | Install Jenkins CI/CD server | RHEL |
| `install_nagios.sh` | Install Nagios monitoring system | RHEL |
| `install_nginx.sh` | Install Nginx web server | RHEL |
| `install_python3.sh` | Compile Python 3 from source | RHEL |
| `install_salt.sh` | Install SaltStack master & minion | RHEL |
| `install_salt_minion.sh` | Install SaltStack minion only | RHEL, Debian |
| `install_squid.sh` | Install Squid proxy server | RHEL |

### Usage Examples

```bash
# Install Ansible (as root)
sudo ./installation_scripts/install_ansible.sh

# Install Flask application with domain
sudo ./installation_scripts/install_flask.sh example.com

# Install Jenkins
sudo ./installation_scripts/install_jenkins.sh

# Install Python 3 from source
sudo ./installation_scripts/install_python3.sh
```

## Utility Scripts

### Backup Scripts

```bash
# Backup /etc directory
sudo ./miscellaneous/etcbackup.sh

# Backup any directory
sudo ./miscellaneous/dirbackup.sh /var/www
```

### Security Scripts

```bash
# Generate secure passwords
./miscellaneous/passgen.sh 5 20  # 5 passwords, 20 characters each

# Check SSH connections
sudo ./miscellaneous/checkssh_conn.sh
```

### Network Scripts

```bash
# Download webpage
./miscellaneous/webpagedl.sh https://example.com
```

## Python Scripts

### Requirements

```bash
# Install Python dependencies
pip3 install -r python-scripts/requirements.txt
```

### Usage

```bash
# Check CPU cores
python3 python-scripts/checkcpu.py

# Check if port is open
python3 python-scripts/portcheck.py example.com 80

# Time command execution
python3 python-scripts/timer.py
```

## Server Management

### Change Hostname

```bash
sudo ./server_management/CentOS/change_hostname.sh new-hostname
```

### Create MySQL Database

```bash
sudo ./server_management/CentOS/create_db.sh <mysql_root_password>
```

### System Statistics

```bash
sudo ./server_management/CentOS/system_stats.sh
```

## Configuration

Many scripts support configuration files. See [config/README.md](config/README.md) for details.

### Example: Configure Backups

```bash
# Copy example config
cp config/backup.conf.example config/backup.conf

# Edit configuration
vim config/backup.conf

# Use in scripts (auto-loaded)
./miscellaneous/etcbackup.sh
```

## Common Library

All scripts can leverage shared functions from `lib/common.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Source common library
source "$(dirname "$0")/../lib/common.sh"

# Use library functions
require_root
print_info "Starting installation..."
validate_domain "example.com"
log_success "Installation complete"
```

Available functions:
- Color output: `print_info`, `print_success`, `print_warning`, `print_error`
- OS detection: `detect_os`, `detect_os_version`, `get_package_manager`
- Validation: `validate_domain`, `validate_ip`, `validate_port`, `validate_hostname`
- Backups: `backup_file`, `backup_dir`
- Logging: `log_info`, `log_error`, `log_success`
- Network: `get_public_ip`, `get_private_ip`, `check_internet`
- And many more...

See [lib/common.sh](lib/common.sh) for complete documentation.

## OS Compatibility

| Operating System | Version | Status |
|-----------------|---------|--------|
| RHEL | 8, 9 | ✅ Tested |
| Rocky Linux | 8, 9 | ✅ Tested |
| AlmaLinux | 8, 9 | ✅ Tested |
| CentOS Stream | 8, 9 | ✅ Tested |
| CentOS | 7 | ⚠️ Legacy (EOL) |
| Ubuntu | 20.04, 22.04, 24.04 | 🔄 Partial |
| Debian | 11, 12 | 🔄 Partial |

Legend:
- ✅ Fully supported and tested
- 🔄 Partially supported (some scripts)
- ⚠️ Legacy support (no new features)

## Security Considerations

### Best Practices Implemented

1. **No Hardcoded Credentials**: Use `read -s` for password input
2. **Input Validation**: All user inputs are validated
3. **Principle of Least Privilege**: Root checks where necessary
4. **Secure Defaults**: SELinux enabled, strong passwords required
5. **Logging**: All operations logged to syslog
6. **Backup Before Modify**: Configuration files backed up automatically

### Known Limitations

- Some scripts require root access
- Network-dependent operations may fail without internet
- SELinux may need policy adjustments for some operations

## Development

### Prerequisites

- Bash 4.0+
- Python 3.9+
- ShellCheck (for linting)
- BATS (for testing)

### Running Tests

```bash
# Shell script tests
bats tests/*.sh

# Python tests
pytest tests/
```

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Code style
- Testing requirements
- Pull request process
- Commit message format

## Troubleshooting

### Common Issues

**Issue**: Script fails with "command not found"
```bash
# Solution: Install missing dependencies
sudo dnf install <package>  # RHEL-based
sudo apt install <package>  # Debian-based
```

**Issue**: Permission denied
```bash
# Solution: Run with sudo if root required
sudo ./script.sh
```

**Issue**: SELinux denials
```bash
# Solution: Check audit logs and create policy
sudo ausearch -m avc -ts recent
sudo audit2allow -a -M mypolicy
sudo semodule -i mypolicy.pp
```

## Roadmap

### Planned Improvements

- [ ] Complete multi-OS support for all scripts
- [ ] Add Docker/Podman installation scripts
- [ ] Add Kubernetes setup scripts
- [ ] Implement automated testing (CI/CD)
- [ ] Add S3 backup support
- [ ] Add email notification support
- [ ] Create interactive menus for complex scripts

See [CHANGELOG.md](CHANGELOG.md) for version history.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Original scripts created for CentOS/RHEL administration
- Modernized with community feedback and best practices
- Inspired by system administration needs across diverse environments

## Support

- **Issues**: Report bugs via [GitHub Issues](https://github.com/yourusername/sysadmin-shell-scripts/issues)
- **Discussions**: Join community discussions
- **Documentation**: Check `config/README.md` and inline script comments

---

**Note**: Always test scripts in a non-production environment first. Use the `--dry-run` flag where available to preview changes.
