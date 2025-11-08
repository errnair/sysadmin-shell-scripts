# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024-01-15

Complete modernization of all scripts with multi-OS support, enhanced security, and comprehensive documentation.

### Added

#### Infrastructure
- Shared common library (`lib/common.sh`, 548 lines) with reusable functions for:
  - OS detection (RHEL/Debian families)
  - Package manager abstraction (dnf/yum/apt)
  - Input validation (domains, IPs, ports, hostnames)
  - Colored output functions
  - Syslog logging integration
  - Secure password input
  - Automatic backup and cleanup functions
- Configuration directory (`config/`) with example templates
- Comprehensive project documentation:
  - `README.md` - Complete script catalog and usage guide
  - `MIGRATION.md` - Migration guide from old to new scripts
  - `EXAMPLES.md` - Comprehensive usage examples and workflows
  - `CONTRIBUTING.md` - Contribution guidelines
  - `CHANGELOG.md` - Version history
  - `LICENSE` - MIT License
- `.gitignore` for proper version control

#### Installation Scripts (9 scripts)
All installation scripts now support RHEL 8/9, Rocky Linux, AlmaLinux, Ubuntu 20.04+, and Debian 11+:

- `install_ansible.sh` - Ansible automation platform
  - Package or pip installation options
  - Version selection support
  - Generates ansible.cfg and inventory files
  - Optional collection installation

- `install_flask.sh` - Flask + Gunicorn + Nginx stack
  - Creates dedicated user with virtual environment
  - Systemd service configuration
  - Nginx reverse proxy setup
  - Optional SSL with Let's Encrypt
  - Git deployment support
  - Firewall and SELinux configuration

- `install_jenkins.sh` - Jenkins CI/CD server
  - Java 17+ validation
  - LTS/weekly version selection
  - Firewall configuration
  - Displays initial admin password
  - Works on RHEL and Debian families

- `install_nagios.sh` - Nagios Core monitoring system
  - Builds from source (latest version)
  - Nagios Plugins included
  - NRPE for remote monitoring
  - Apache with authentication
  - Secure password input (no hardcoding)
  - Example configurations included
  - Firewall and SELinux configuration

- `install_nginx.sh` - Nginx web server
  - Three application types: static, reverse proxy, Flask
  - Optional SSL with Let's Encrypt
  - SELinux boolean configuration
  - Firewall setup (firewalld and ufw)
  - Test page generation

- `install_python3.sh` - Python 3.12.7
  - Auto-detects system packages first
  - Falls back to source compilation
  - Checksum verification for downloads
  - pip and setuptools installation
  - Development headers included

- `install_salt.sh` - SaltStack master
  - Modern SaltProject repositories
  - Generates example state files
  - Minion key management instructions
  - Firewall configuration
  - Works on RHEL and Debian families

- `install_salt_minion.sh` - SaltStack minion
  - Master server validation
  - Custom minion ID support
  - Connection testing
  - Multi-OS support (moved from server_management/Debian/)

- `install_squid.sh` - Squid proxy server
  - Three modes: forward, transparent, reverse
  - ACL configuration
  - Site blocking support
  - Firewall configuration

#### Server Management Scripts (3 scripts)
- `system_stats.sh` - Comprehensive system information gathering
  - Multi-OS support (RHEL, Ubuntu, Debian)
  - Three output formats: text, JSON, CSV
  - Virtualization detection (KVM, VMware, Xen, etc.)
  - Container runtime detection (Docker, Podman)
  - Security status (SELinux, firewall)
  - Save to file option

- `change_hostname.sh` - Hostname management
  - RFC 1123 hostname validation
  - Cloud provider detection (AWS, Azure, GCP)
  - Automatic /etc/hosts update
  - Configuration backup before changes
  - Optional network restart
  - Multi-OS support

- `selinux_troubleshoot.sh` - SELinux troubleshooting tool (renamed from `permissive_selinux.sh`)
  - Five commands: status, denials, suggest, permissive, enforcing
  - audit2why integration for policy suggestions
  - Security warnings when disabling enforcement
  - Temporary vs persistent mode changes
  - Emphasizes troubleshooting over disabling

#### Utility Scripts (4 scripts)
- `dirbackup.sh` - Enhanced directory backup
  - Multiple compression formats (gzip, bzip2, xz)
  - GPG encryption with AES256
  - SHA256 checksum verification
  - Retention policy with auto-cleanup
  - Incremental backup support
  - Multi-OS support

- `etcbackup.sh` - /etc backup wrapper
  - Wrapper around dirbackup.sh
  - Optimized defaults for /etc backups
  - 90-day retention default
  - Inherits all dirbackup.sh features

- `passgen.sh` - Advanced password generator
  - Four password types: alphanumeric, special characters, passphrase, PIN
  - Password strength assessment with entropy calculation
  - Avoid ambiguous characters option
  - Multiple output formats (text, JSON, CSV)
  - Clipboard integration
  - Bulk password generation

- `webpagedl.sh` - Web page downloader
  - Multi-method support (wget, curl, aria2)
  - Retry logic with configurable count
  - Mirror mode for entire sites
  - Authentication support (HTTP Basic)
  - Download verification

#### Python Scripts (3 scripts, completely rewritten)
- `checkcpu.py` - CPU information tool
  - Python 3 with type hints
  - Cross-platform support (Linux, macOS)
  - Detailed CPU information (model, vendor, frequency, cache, cores)
  - JSON output support
  - Virtual CPU detection
  - Optional CPU usage and temperature
  - Verbose mode showing all CPU flags

- `timer.py` - Command benchmarking tool
  - Python 3 with type hints
  - Benchmark any shell command
  - Statistics: min, max, mean, median, standard deviation
  - Compare mode for two commands
  - Warmup runs to exclude cold start
  - Multiple output formats (text, JSON, CSV)
  - Human-readable time formatting

- `portcheck.py` - Port connectivity checker (maintained)
  - TCP/UDP support
  - Port range scanning
  - JSON output
  - Concurrent scanning

#### Scripts Moved/Reorganized
- `checkssh_conn.sh` - Moved from `miscellaneous/` to `installation_scripts/`
- `create_db.sh` - Moved from `server_management/CentOS/` to `installation_scripts/`
- `sync_emails.sh` - Moved from `server_management/CentOS/` to `installation_scripts/`

### Changed

#### Repository Structure
Scripts reorganized by function instead of OS:
- `installation_scripts/` - All software installation scripts (9 scripts)
- `server_management/` - Server administration tools (3 scripts)
- `utilities/` - General-purpose utilities (4 scripts)
- `python-scripts/` - Python utilities (3 scripts)
- `lib/` - Shared function library
- `config/` - Configuration templates

#### All Scripts Now Support
- Multi-OS compatibility (RHEL 8/9, Rocky, AlmaLinux, CentOS Stream, Ubuntu 20.04+, Debian 11+)
- Modern bash practices: `set -euo pipefail`
- Trap cleanup handlers
- Comprehensive error handling
- Environment variable configuration
- Syslog logging
- Colored terminal output
- Input validation
- Automatic configuration backups

#### Security Improvements
- No hardcoded credentials anywhere
- Secure password input using `read -sp`
- Input validation for all user inputs
- Root privilege checks only where necessary
- SELinux enforcement maintained (no `setenforce 0`)
- Firewall configuration in all installation scripts
- Automatic configuration backups before changes
- No password leakage in logs or process lists

#### Script Enhancements

**system_stats.sh**:
- Now works on RHEL, Ubuntu, and Debian
- JSON and CSV output formats added
- Detects virtualization and containerization
- Shows security status (SELinux, firewall)
- Can save output to file

**change_hostname.sh**:
- Now validates hostnames against RFC 1123
- Detects cloud providers (AWS, Azure, GCP)
- Updates /etc/hosts automatically
- Works on RHEL, Ubuntu, and Debian

**dirbackup.sh**:
- Multiple compression formats (gzip, bzip2, xz)
- GPG encryption support
- SHA256 verification
- Retention policy with auto-cleanup
- Incremental backup support

**passgen.sh**:
- Four password types instead of one
- Strength assessment with entropy
- Multiple output formats
- Bulk generation support

**webpagedl.sh**:
- Three download methods (wget, curl, aria2)
- Retry logic
- Mirror mode
- Authentication support

### Deprecated

#### Old Script Locations
All old script locations have been deprecated with clear migration paths:

**From server_management/CentOS/**:
- `system_stats.sh` → `server_management/system_stats.sh`
- `change_hostname.sh` → `server_management/change_hostname.sh`
- `permissive_selinux.sh` → `server_management/selinux_troubleshoot.sh` (renamed)
- `create_db.sh` → `installation_scripts/create_db.sh`
- `sync_emails.sh` → `installation_scripts/sync_emails.sh`
- `nginx/newuser.sh` → `installation_scripts/install_flask.sh` (replaced)

**From server_management/Debian/**:
- `install_salt_minion.sh` → `installation_scripts/install_salt_minion.sh`

**From miscellaneous/**:
- `dirbackup.sh` → `utilities/dirbackup.sh`
- `etcbackup.sh` → `utilities/etcbackup.sh`
- `passgen.sh` → `utilities/passgen.sh`
- `webpagedl.sh` → `utilities/webpagedl.sh`
- `checkssh_conn.sh` → `installation_scripts/checkssh_conn.sh`

### Removed

#### Old Script Implementations
- Removed OS-specific script versions in favor of multi-OS scripts
- Removed hardcoded configuration values in favor of environment variables
- Removed deprecated `nginx/newuser.sh` (replaced by `install_flask.sh`)
- Removed old Python 2 implementations of `checkcpu.py` and `timer.py`

#### Deprecated Directories
- `server_management/CentOS/` - Scripts moved to top-level categories
- `server_management/Debian/` - Scripts moved to `installation_scripts/`
- `miscellaneous/` - Scripts moved to `utilities/` and `installation_scripts/`

### Fixed

#### Security Vulnerabilities
- No hardcoded passwords or credentials
- Proper input validation in all scripts
- SELinux remains enforcing (no automatic disabling)
- Proper file permissions on created files
- No command injection vulnerabilities

#### Reliability Issues
- All scripts use `set -euo pipefail` for strict error handling
- Trap handlers for cleanup on exit
- Proper error messages and exit codes
- Validation of prerequisites before execution

#### Compatibility Issues
- All installation scripts detect and work with both RHEL and Debian families
- Package manager abstraction (dnf/yum/apt)
- Firewall abstraction (firewalld/ufw)
- Python 3 compatibility for all Python scripts
- macOS support in `checkcpu.py`

### Security

#### Hardening Measures
- All passwords via secure input (`read -sp`) or environment variables
- Input validation prevents command injection
- Principle of least privilege (root checks only where needed)
- Comprehensive logging to syslog for audit trail
- Automatic backup before configuration changes
- SELinux enforcing mode maintained
- Firewall enabled and configured by default

#### Encryption
- GPG encryption for backups with AES256
- SHA256 checksums for backup verification
- Let's Encrypt SSL integration in web server installers

---

## [1.0.0] - Legacy Version

### Initial Scripts
Basic collection of administration scripts with limited OS support:

- Installation scripts for Ansible, Flask, Jenkins, Nagios, Nginx, Python3, Salt, Squid
- Miscellaneous utilities: SSH checker, backup scripts, password generator, webpage downloader
- Python 2 scripts: CPU checker (10 lines), timer (17 lines), port checker
- Server management scripts: hostname changer, database creator, user creator, SELinux configurator, email syncer, system stats

### Limitations of 1.0.0
- OS-specific scripts (separate for CentOS and Debian)
- Limited error handling
- No shared library
- Hardcoded values instead of environment variables
- Basic functionality without advanced features
- Python 2 scripts (deprecated)

[2.0.0]: https://github.com/yourusername/sysadmin-shell-scripts/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/yourusername/sysadmin-shell-scripts/releases/tag/v1.0.0
