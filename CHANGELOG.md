# Changelog

All notable changes to this project.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [2.0.0] - 2024-01-15

Major modernization with multi-OS support and better security.

### Added

**Infrastructure:**
- Shared library `lib/common.sh` (548 lines) with functions for OS detection, package manager abstraction, input validation, colored output, and syslog logging
- Config directory with templates
- Documentation: README, MIGRATION, EXAMPLES, CONTRIBUTING, CHANGELOG, LICENSE
- `.gitignore` for version control

**Installation Scripts (9 scripts):**

All work on RHEL 8/9, Rocky, AlmaLinux, Ubuntu 20.04+, Debian 11+:

- `install_ansible.sh` - Ansible with package or pip installation
- `install_flask.sh` - Flask + Gunicorn + Nginx, optional SSL
- `install_jenkins.sh` - Jenkins with Java validation
- `install_nagios.sh` - Nagios Core + Plugins + NRPE from source
- `install_nginx.sh` - Three modes (static/proxy/Flask), optional SSL
- `install_python3.sh` - Python 3.12.7, tries packages first then source
- `install_salt.sh` - SaltStack master with example states
- `install_salt_minion.sh` - SaltStack minion (moved from server_management/Debian/)
- `install_squid.sh` - Squid proxy (forward/transparent/reverse modes)

**Server Management Scripts (3 scripts):**

- `system_stats.sh` - System information with text/JSON/CSV output, virtualization detection, container runtime detection
- `change_hostname.sh` - Hostname management with RFC 1123 validation, cloud detection (AWS/Azure/GCP)
- `selinux_troubleshoot.sh` - SELinux troubleshooting (renamed from permissive_selinux.sh) with 5 commands: status, denials, suggest, permissive, enforcing

**Utility Scripts (4 scripts):**

- `dirbackup.sh` - Directory backup with multiple compression formats, GPG encryption, SHA256 verification, retention policy, incremental support
- `etcbackup.sh` - /etc backup wrapper with 90-day retention
- `passgen.sh` - Password generator with 4 types (alphanumeric/special/passphrase/PIN), strength assessment, JSON/CSV output
- `webpagedl.sh` - Web page downloader with wget/curl/aria2, retry logic, mirror mode

**Python Scripts (rewritten for Python 3):**

- `checkcpu.py` - CPU info tool with type hints, cross-platform (Linux/macOS), JSON output, virtualization detection
- `timer.py` - Command benchmarking with statistics (min/max/mean/median/stdev), compare mode, warmup runs
- `portcheck.py` - Port checker (maintained)

**Scripts Moved:**
- `checkssh_conn.sh` - miscellaneous/ → installation_scripts/
- `create_db.sh` - server_management/CentOS/ → installation_scripts/
- `sync_emails.sh` - server_management/CentOS/ → installation_scripts/

### Changed

**Repository Structure:**

Scripts organized by function instead of OS:
- `installation_scripts/` - Software installers (9 scripts)
- `server_management/` - System admin tools (3 scripts)
- `utilities/` - Backup, passwords, etc. (4 scripts)
- `python-scripts/` - Python utilities (3 scripts)
- `lib/` - Shared functions
- `config/` - Config templates

**All Scripts:**
- Multi-OS support (RHEL/Rocky/AlmaLinux/Ubuntu/Debian)
- Modern bash: `set -euo pipefail`, trap cleanup, error handling
- Environment variable configuration
- Syslog logging with colored terminal output
- Input validation
- Auto backups before changes

**Security:**
- No hardcoded credentials
- Secure password input (`read -sp`)
- Input validation
- Root checks only where needed
- SELinux stays enforcing
- Firewall config in all installers
- No password leakage in logs

**Script Improvements:**

*system_stats.sh*: Works on RHEL/Ubuntu/Debian, JSON/CSV output, detects virtualization/containers, shows security status

*change_hostname.sh*: RFC 1123 validation, cloud provider detection, updates /etc/hosts

*dirbackup.sh*: Multiple compression formats, GPG encryption, SHA256 verification, retention policy, incremental backups

*passgen.sh*: 4 password types, strength assessment, multiple output formats

*webpagedl.sh*: Three download methods, retry logic, mirror mode, authentication

### Deprecated

**Old Script Locations:**

*From server_management/CentOS/:*
- `system_stats.sh` → `server_management/system_stats.sh`
- `change_hostname.sh` → `server_management/change_hostname.sh`
- `permissive_selinux.sh` → `server_management/selinux_troubleshoot.sh` (renamed)
- `create_db.sh` → `installation_scripts/create_db.sh`
- `sync_emails.sh` → `installation_scripts/sync_emails.sh`
- `nginx/newuser.sh` → `installation_scripts/install_flask.sh` (replaced)

*From server_management/Debian/:*
- `install_salt_minion.sh` → `installation_scripts/install_salt_minion.sh`

*From miscellaneous/:*
- `dirbackup.sh` → `utilities/dirbackup.sh`
- `etcbackup.sh` → `utilities/etcbackup.sh`
- `passgen.sh` → `utilities/passgen.sh`
- `webpagedl.sh` → `utilities/webpagedl.sh`
- `checkssh_conn.sh` → `installation_scripts/checkssh_conn.sh`

### Removed

- OS-specific script versions (now multi-OS)
- Hardcoded config values (now environment variables)
- Old `nginx/newuser.sh` (replaced by `install_flask.sh`)
- Old Python 2 versions of checkcpu.py and timer.py

**Deprecated directories:**
- `server_management/CentOS/` - scripts moved
- `server_management/Debian/` - scripts moved
- `miscellaneous/` - scripts moved

### Fixed

**Security:**
- No hardcoded passwords
- Input validation in all scripts
- SELinux doesn't get disabled automatically
- Proper file permissions
- No command injection vulnerabilities

**Reliability:**
- All scripts use `set -euo pipefail`
- Trap handlers for cleanup
- Better error messages and exit codes
- Prerequisite validation

**Compatibility:**
- All install scripts work on RHEL and Debian families
- Package manager abstraction (dnf/yum/apt)
- Firewall abstraction (firewalld/ufw)
- Python 3 for all Python scripts
- macOS support in checkcpu.py

### Security

**Hardening:**
- Passwords via `read -sp` or environment variables
- Input validation prevents command injection
- Root privileges only where needed
- All operations logged to syslog
- Auto backups before config changes
- SELinux enforcing mode maintained
- Firewall enabled by default

**Encryption:**
- GPG encryption for backups (AES256)
- SHA256 checksums
- Let's Encrypt SSL integration

---

## [1.0.0] - Legacy Version

Original collection of scripts with limited OS support:

- Installation scripts for Ansible, Flask, Jenkins, Nagios, Nginx, Python3, Salt, Squid
- Utilities: SSH checker, backups, password gen, webpage downloader
- Python 2 scripts: checkcpu (10 lines), timer (17 lines), portcheck
- Server management: hostname, database, SELinux, email sync, system stats

**Limitations:**
- OS-specific (separate CentOS and Debian versions)
- Limited error handling
- No shared library
- Hardcoded values
- Basic features
- Python 2

[2.0.0]: https://github.com/yourusername/sysadmin-shell-scripts/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/yourusername/sysadmin-shell-scripts/releases/tag/v1.0.0
