# Migration Guide

Guide for migrating from old script locations to new ones.

## Overview

Scripts have been reorganized:
- Works on RHEL 8/9, Rocky, AlmaLinux, Ubuntu 20.04+, Debian 11+
- No hardcoded credentials
- Shared functions in `lib/common.sh`
- Multiple output formats (text/JSON/CSV)
- Environment variable configuration

## Breaking Changes

### Directory Structure

Scripts organized by function, not OS:
- `server_management/CentOS/` → `server_management/` or `installation_scripts/`
- `server_management/Debian/` → `installation_scripts/`
- `miscellaneous/` → `utilities/` or `installation_scripts/`

### Script Names

- `permissive_selinux.sh` → `selinux_troubleshoot.sh`
- `nginx/newuser.sh` → `install_flask.sh`

### Environment Variables

Scripts now use environment variables for configuration:

```bash
# Output
OUTPUT_FORMAT=json|csv|text
SAVE_TO_FILE=yes
OUTPUT_FILE=/path/file

# Installation
JENKINS_PORT=9090
ANSIBLE_VERSION=2.16
ENABLE_SSL=yes

# Backups
BACKUP_DIR=/mnt/backups
RETENTION_DAYS=30
ENCRYPT=yes
COMPRESSION=xz
```

## Script Location Changes

| Old Location | New Location | Notes |
|--------------|--------------|-------|
| `server_management/CentOS/system_stats.sh` | `server_management/system_stats.sh` | Multi-OS |
| `server_management/CentOS/change_hostname.sh` | `server_management/change_hostname.sh` | Multi-OS |
| `server_management/CentOS/permissive_selinux.sh` | `server_management/selinux_troubleshoot.sh` | Renamed |
| `server_management/CentOS/create_db.sh` | `installation_scripts/create_db.sh` | Moved |
| `server_management/CentOS/sync_emails.sh` | `installation_scripts/sync_emails.sh` | Moved |
| `server_management/CentOS/nginx/newuser.sh` | `installation_scripts/install_flask.sh` | Replaced |
| `server_management/Debian/install_salt_minion.sh` | `installation_scripts/install_salt_minion.sh` | Multi-OS |
| `miscellaneous/dirbackup.sh` | `utilities/dirbackup.sh` | Enhanced |
| `miscellaneous/etcbackup.sh` | `utilities/etcbackup.sh` | Wrapper |
| `miscellaneous/passgen.sh` | `utilities/passgen.sh` | Enhanced |
| `miscellaneous/webpagedl.sh` | `utilities/webpagedl.sh` | Enhanced |
| `miscellaneous/checkssh_conn.sh` | `installation_scripts/checkssh_conn.sh` | Moved |

## Feature Changes

### system_stats.sh

Old (CentOS only):
```bash
./server_management/CentOS/system_stats.sh
```

New (Multi-OS with formats):
```bash
sudo ./server_management/system_stats.sh
sudo OUTPUT_FORMAT=json ./server_management/system_stats.sh
sudo OUTPUT_FORMAT=csv ./server_management/system_stats.sh
```

New features: virtualization detection, container runtimes, security status, save to file.

### change_hostname.sh

Old:
```bash
./server_management/CentOS/change_hostname.sh webserver01
```

New:
```bash
sudo ./server_management/change_hostname.sh webserver01
sudo RESTART_NETWORK=yes ./server_management/change_hostname.sh db-01
```

New features: RFC 1123 validation, cloud platform detection (AWS/Azure/GCP), updates /etc/hosts.

### selinux_troubleshoot.sh

Old (just disable):
```bash
./server_management/CentOS/permissive_selinux.sh
```

New (troubleshoot first):
```bash
sudo ./server_management/selinux_troubleshoot.sh status
sudo ./server_management/selinux_troubleshoot.sh denials
sudo ./server_management/selinux_troubleshoot.sh suggest
sudo ./server_management/selinux_troubleshoot.sh permissive  # Only if needed
```

New features: status, denials, suggest, permissive, enforcing commands. Includes audit2why integration.

### dirbackup.sh

Old:
```bash
./miscellaneous/dirbackup.sh /var/www
```

New:
```bash
sudo ./utilities/dirbackup.sh /var/www
sudo ENCRYPT=yes RETENTION_DAYS=30 ./utilities/dirbackup.sh /var/www
sudo INCREMENTAL=yes ./utilities/dirbackup.sh /data
```

New features: gzip/bzip2/xz compression, GPG encryption, SHA256 verification, retention policy, incremental backups.

### passgen.sh

Old:
```bash
./miscellaneous/passgen.sh
```

New:
```bash
./utilities/passgen.sh 10 32
PASSWORD_TYPE=special ./utilities/passgen.sh 10 32
PASSWORD_TYPE=passphrase ./utilities/passgen.sh 1 5
OUTPUT_FORMAT=csv ./utilities/passgen.sh 100 > passwords.csv
```

New features: 4 password types (alphanumeric/special/passphrase/PIN), strength assessment, JSON/CSV output.

### webpagedl.sh

Old:
```bash
./miscellaneous/webpagedl.sh https://example.com
```

New:
```bash
./utilities/webpagedl.sh https://example.com
RETRY_COUNT=5 ./utilities/webpagedl.sh https://example.com
MIRROR_MODE=yes ./utilities/webpagedl.sh https://example.com
```

New features: wget/curl/aria2 support, retry logic, mirror mode, authentication.

## Migration Examples

### System Stats Automation

Old:
```bash
./server_management/CentOS/system_stats.sh > /var/log/stats.txt
```

New:
```bash
OUTPUT_FORMAT=json SAVE_TO_FILE=yes OUTPUT_FILE=/var/log/stats.json ./server_management/system_stats.sh
```

### Daily Backup Cron

Old:
```
0 2 * * * /root/scripts/miscellaneous/etcbackup.sh
```

New:
```
0 2 * * * BACKUP_DIR=/mnt/backups ENCRYPT=yes /root/scripts/utilities/etcbackup.sh
```

### Password Generation

Old:
```bash
./miscellaneous/passgen.sh
```

New:
```bash
PASSWORD_TYPE=special ./utilities/passgen.sh 1 32
OUTPUT_FORMAT=csv ./utilities/passgen.sh 100 16 > passwords.csv
```

### Hostname Change

Old:
```bash
./server_management/CentOS/change_hostname.sh webserver01
```

New (same syntax, works on Ubuntu/Debian too):
```bash
sudo ./server_management/change_hostname.sh webserver01
```

### SELinux Workflow

Old (just disable):
```bash
./server_management/CentOS/permissive_selinux.sh
```

New (troubleshoot):
```bash
sudo ./server_management/selinux_troubleshoot.sh status
sudo ./server_management/selinux_troubleshoot.sh denials
sudo ./server_management/selinux_troubleshoot.sh suggest
# Fix the policy instead of disabling
```

## Environment Variable Reference

### Common Variables

```bash
LOG_LEVEL=debug|info|warning|error
QUIET_MODE=yes
OUTPUT_FORMAT=json|csv|text
SAVE_TO_FILE=yes
OUTPUT_FILE=/path/file
```

### Installation Scripts

```bash
SKIP_FIREWALL=yes
SKIP_SELINUX=yes
ANSIBLE_VERSION=2.16
INSTALL_METHOD=pip|package
JENKINS_PORT=9090
JENKINS_VERSION=lts|weekly
APP_TYPE=static|proxy|flask
ENABLE_SSL=yes
DOMAIN_NAME=example.com
PYTHON_VERSION=3.12.7
SALT_VERSION=3006
MINION_ID=server01
```

### Backup Scripts

```bash
BACKUP_DIR=/mnt/backups
RETENTION_DAYS=30
INCREMENTAL=yes
COMPRESSION=gzip|bzip2|xz
VERIFY=yes
ENCRYPT=yes
GPG_RECIPIENT=user@example.com
```

### Utility Scripts

```bash
PASSWORD_TYPE=alphanumeric|special|passphrase|pin
AVOID_AMBIGUOUS=yes
CLIPBOARD=yes
DOWNLOAD_METHOD=wget|curl|aria2
RETRY_COUNT=5
MIRROR_MODE=yes
AUTH_USER=username
AUTH_PASS=password
```

## Update Automation

### Cron Jobs

```bash
# Update paths
sed -i 's|miscellaneous/etcbackup.sh|utilities/etcbackup.sh|g' /etc/crontab
sed -i 's|server_management/CentOS/|server_management/|g' /etc/crontab
```

### Scripts

Find and update:
```bash
grep -r "miscellaneous/" /opt/scripts/
grep -r "server_management/CentOS/" /opt/scripts/
```

### Ansible Playbooks

```yaml
# Old
- command: /opt/scripts/miscellaneous/dirbackup.sh /data

# New
- command: /opt/scripts/utilities/dirbackup.sh /data
  environment:
    BACKUP_DIR: /mnt/backups
    ENCRYPT: yes
```

## Testing

Test in non-production first:

```bash
# Clone to test
git clone https://github.com/user/sysadmin-shell-scripts.git /tmp/test-scripts

# Test with your params
cd /tmp/test-scripts
sudo OUTPUT_FORMAT=json ./server_management/system_stats.sh
```

Verify syntax:
```bash
find . -name "*.sh" -exec bash -n {} \;
find python-scripts -name "*.py" -exec python3 -m py_compile {} \;
```

## Timeline

- **Now**: Old scripts deprecated, new scripts available
- **Future**: Old OS-specific directories may be removed
- **Action**: Migrate to new scripts ASAP

## Migration Checklist

- [ ] List all scripts used in automation
- [ ] Update cron jobs
- [ ] Update systemd timers
- [ ] Update Ansible/Salt playbooks
- [ ] Update documentation
- [ ] Test in non-production
- [ ] Update production

## Getting Help

- Script help: `./script.sh --help`
- See README.md for full documentation
- Report issues: https://github.com/user/sysadmin-shell-scripts/issues
