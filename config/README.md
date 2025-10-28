# Configuration Guide

This directory contains configuration templates for various installation and management scripts.

## Usage

1. **Copy the example file:**
   ```bash
   cp ansible.conf.example ansible.conf
   ```

2. **Edit the configuration:**
   ```bash
   vim ansible.conf
   ```

3. **Use in scripts:**
   Most scripts will automatically look for configuration files in this directory.

## Configuration Files

### `defaults.conf`
Global default settings used by all scripts. This file is loaded first and can be overridden by specific configuration files.

**Key settings:**
- Backup directories and retention
- Network timeouts
- Security defaults
- Service management preferences

### `ansible.conf.example`
Configuration for Ansible installation script.

**Customize:**
- Ansible version
- Installation method (package/pip/source)
- Collections to install
- Python version

### `flask.conf.example`
Configuration for Flask + Nginx installation.

**Customize:**
- Domain name
- SSL configuration
- Gunicorn workers
- Application repository

### `jenkins.conf.example`
Configuration for Jenkins installation.

**Customize:**
- Jenkins version (LTS/latest)
- Java version
- Memory settings
- Plugins to install

### `backup.conf.example`
Configuration for backup scripts.

**Customize:**
- Backup destinations (local/S3/rsync)
- Retention policies
- Compression and encryption
- Notifications

## Environment Variables

Configuration values can be overridden using environment variables:

```bash
# Override backup directory
BACKUP_DIR=/custom/backup/path ./backup_etc.sh

# Multiple variables
BACKUP_DIR=/backups RETENTION_DAYS=60 ./backup_etc.sh
```

## Configuration Precedence

Scripts load configuration in this order (later overrides earlier):

1. `config/defaults.conf` - Global defaults
2. `config/<script>.conf` - Script-specific config
3. Environment variables - Runtime overrides
4. Command-line arguments - Highest priority

## Security Considerations

- **Never commit files with credentials** - All example files use `.example` extension
- **Protect configuration files:**
  ```bash
  chmod 600 config/*.conf
  ```
- **Use environment variables for secrets** in production
- **Consider using vault solutions** (HashiCorp Vault, AWS Secrets Manager)

## Examples

### Example 1: Custom Ansible Installation

```bash
# Create config
cat > config/ansible.conf <<EOF
ANSIBLE_VERSION="2.15.0"
INSTALL_METHOD="pip"
INSTALL_COLLECTIONS=true
COLLECTIONS=("community.general" "ansible.posix")
EOF

# Run installation
./installation_scripts/install_ansible.sh
```

### Example 2: Flask with Custom Domain

```bash
# Create config
cat > config/flask.conf <<EOF
DOMAIN="myapp.example.com"
ADMIN_EMAIL="admin@example.com"
ENABLE_SSL=true
GUNICORN_WORKERS=5
EOF

# Run installation
./installation_scripts/install_flask.sh
```

### Example 3: Encrypted Backups to S3

```bash
# Create config
cat > config/backup.conf <<EOF
BACKUP_LOCAL_DIR="/backups"
S3_ENABLED=true
S3_BUCKET="my-backup-bucket"
S3_REGION="us-west-2"
ENCRYPT_BACKUPS=true
GPG_RECIPIENT="backup@example.com"
RETENTION_DAYS=90
EOF

# Run backup
./miscellaneous/dirbackup.sh /etc
```

## Troubleshooting

### Configuration not loading

Check that:
1. Configuration file exists and is readable
2. File has correct syntax (no spaces around `=`)
3. File path is correct

### Values not taking effect

Remember precedence order - command-line arguments override everything:
```bash
# Config says RETENTION_DAYS=30, but this overrides it:
./backup_etc.sh --retention 60
```

## Contributing

When adding new configuration options:
1. Add to appropriate `.example` file
2. Document in this README
3. Use sensible defaults
4. Add validation in scripts
