# Deprecated - CentOS-Specific Scripts

This directory contains deprecated scripts that were CentOS-specific.

## Status

All scripts in this directory have been **deprecated** and moved to new locations with multi-OS support.

## Migration

All modernized scripts now support multiple operating systems:
- RHEL 8/9
- Rocky Linux 8/9
- AlmaLinux 8/9
- Ubuntu 20.04+
- Debian 11+

### Script Locations

| Old Location (Deprecated) | New Location |
|--------------------------|--------------|
| `system_stats.sh` | `../../server_management/system_stats.sh` |
| `change_hostname.sh` | `../../server_management/change_hostname.sh` |
| `permissive_selinux.sh` | `../../server_management/selinux_troubleshoot.sh` |
| `create_db.sh` | `../../installation_scripts/create_db.sh` |
| `sync_emails.sh` | `../../installation_scripts/sync_emails.sh` |
| `nginx/newuser.sh` | DEPRECATED - use `../../installation_scripts/install_flask.sh` |

## Running Deprecated Scripts

If you run any `DEPRECATED_*.sh` script, you'll see a message with:
- The new location of the script
- What has changed
- Migration examples

## Timeline

These deprecated scripts will be removed in a future release. Please update your automation and documentation to use the new multi-OS scripts.
