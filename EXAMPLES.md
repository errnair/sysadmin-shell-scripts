# Usage Examples

Common workflows and practical examples.

## Installation Workflows

### Web Application Stack

```bash
# Install Flask app with Nginx in one go
sudo ./installation_scripts/install_flask.sh

# Or install Nginx separately
sudo ./installation_scripts/install_nginx.sh
```

The install_flask script creates a user, sets up virtualenv, configures systemd and nginx, and optionally handles SSL.

### CI/CD with Jenkins

```bash
sudo ./installation_scripts/install_jenkins.sh
sudo JENKINS_PORT=9090 ./installation_scripts/install_jenkins.sh  # Custom port

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Nagios Monitoring

```bash
sudo ./installation_scripts/install_nagios.sh

# Access at http://server/nagios
# Username: nagiosadmin
# Password: what you entered during setup
```

Configure hosts in `/usr/local/nagios/etc/objects/hosts.cfg` and reload with `systemctl reload nagios`.

### SaltStack Setup

```bash
# Master server
sudo ./installation_scripts/install_salt.sh

# Minion servers
sudo MINION_ID=webserver01 ./installation_scripts/install_salt_minion.sh 192.168.1.100

# On master, accept keys
sudo salt-key -A
sudo salt '*' test.ping
```

### Squid Proxy

```bash
sudo ./installation_scripts/install_squid.sh
# Choose mode when prompted: forward, transparent, or reverse

# Test
curl -x http://localhost:3128 https://example.com
```

## Backup and Recovery

### Daily /etc Backups

```bash
sudo ./utilities/etcbackup.sh
sudo ENCRYPT=yes ./utilities/etcbackup.sh
```

Cron job for daily 2 AM backup:
```
0 2 * * * BACKUP_DIR=/mnt/backups ENCRYPT=yes /path/to/utilities/etcbackup.sh
```

### Application Backups

```bash
# Full backup with encryption
sudo BACKUP_DIR=/mnt/backups ENCRYPT=yes RETENTION_DAYS=30 ./utilities/dirbackup.sh /var/www

# Incremental (faster for large directories)
sudo BACKUP_DIR=/mnt/backups INCREMENTAL=yes ./utilities/dirbackup.sh /var/www
```

### Database Backup

```bash
#!/bin/bash
# backup-mysql.sh

mysqldump --all-databases > /tmp/mysql-dump.sql
sudo BACKUP_DIR=/mnt/backups ENCRYPT=yes ./utilities/dirbackup.sh /var/lib/mysql
sudo BACKUP_DIR=/mnt/backups ENCRYPT=yes ./utilities/dirbackup.sh /tmp/mysql-dump.sql
rm /tmp/mysql-dump.sql
```

### Restore from Backup

```bash
# Decrypt
gpg -d /mnt/backups/etc_20240115_020001.tar.xz.gpg > /tmp/etc-backup.tar.xz

# Verify checksum
sha256sum -c /mnt/backups/etc_20240115_020001.tar.xz.sha256

# Extract
sudo tar -xJf /tmp/etc-backup.tar.xz -C /tmp/restore

# Copy back what you need
sudo cp -a /tmp/restore/etc/nginx/nginx.conf /etc/nginx/
```

### Remote Backup

```bash
#!/bin/bash
BACKUP_DIR=/mnt/backups
REMOTE_HOST=backup-server.example.com
REMOTE_DIR=/backups/$(hostname)

# Create backup
sudo BACKUP_DIR=$BACKUP_DIR ENCRYPT=yes ./utilities/dirbackup.sh /var/www

# Transfer
LATEST=$(ls -t $BACKUP_DIR/var_www_*.tar.*.gpg | head -1)
rsync -avz $LATEST $REMOTE_HOST:$REMOTE_DIR/
```

## Security Hardening

### SELinux Configuration

```bash
# Check status
sudo ./server_management/selinux_troubleshoot.sh status

# If you get permission denied errors
sudo ./server_management/selinux_troubleshoot.sh denials
sudo ./server_management/selinux_troubleshoot.sh suggest

# Apply fixes (example)
sudo setsebool -P httpd_can_network_connect on
sudo setsebool -P httpd_can_network_connect_db on

# Custom port for web server
sudo semanage port -a -t http_port_t -p tcp 8080
```

Don't just set SELinux to permissive - fix the policy.

### Firewall Setup

```bash
# RHEL/CentOS (firewalld)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# Ubuntu/Debian (ufw)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### SSL Certificates

```bash
# Nginx with Let's Encrypt
sudo ENABLE_SSL=yes DOMAIN_NAME=example.com ./installation_scripts/install_nginx.sh

# Manual certificate
sudo certbot certonly --nginx -d example.com -d www.example.com
sudo certbot renew --dry-run  # Test auto-renewal
```

### Password Management

```bash
# Generate strong password
PASSWORD_TYPE=special ./utilities/passgen.sh 1 32

# Batch passwords for users
PASSWORD_TYPE=special OUTPUT_FORMAT=csv ./utilities/passgen.sh 50 16 > user-passwords.csv

# Memorable passphrase
PASSWORD_TYPE=passphrase ./utilities/passgen.sh 1 5

# Encrypt password file
PASSWORD_TYPE=special OUTPUT_FORMAT=csv ./utilities/passgen.sh 100 16 | \
    gpg -c --cipher-algo AES256 > passwords.csv.gpg
```

## Monitoring and Troubleshooting

### System Stats Collection

```bash
# Text output
sudo ./server_management/system_stats.sh

# JSON for automation
sudo OUTPUT_FORMAT=json ./server_management/system_stats.sh | jq '.memory'

# CSV for spreadsheet
sudo OUTPUT_FORMAT=csv ./server_management/system_stats.sh > stats.csv
```

Collect from multiple servers:
```bash
for server in web{01..05}.example.com; do
    ssh $server "sudo OUTPUT_FORMAT=json ./system_stats.sh" > ${server}-stats.json
done
```

### CPU Monitoring

```bash
python3 python-scripts/checkcpu.py
python3 python-scripts/checkcpu.py --json | jq '.model_name'
```

### Performance Benchmarking

```bash
# Time a command
python3 python-scripts/timer.py "ls -la /usr/bin"

# Multiple runs with stats
python3 python-scripts/timer.py -n 100 "curl -s https://example.com"

# Compare two approaches
python3 python-scripts/timer.py --compare "grep -r pattern /var/log" "rg pattern /var/log"
```

### Port Testing

```bash
python3 python-scripts/portcheck.py example.com 443
python3 python-scripts/portcheck.py example.com 20-25  # Range

# Check multiple services
for port in 22 80 443 3306; do
    python3 python-scripts/portcheck.py db-server.example.com $port
done
```

## Automation with Cron

### Backup Schedule

```bash
# Edit crontab
crontab -e

# /etc backup at 2 AM daily
0 2 * * * BACKUP_DIR=/mnt/backups ENCRYPT=yes /root/scripts/utilities/etcbackup.sh

# Web app backup at 3 AM daily
0 3 * * * BACKUP_DIR=/mnt/backups ENCRYPT=yes RETENTION_DAYS=30 /root/scripts/utilities/dirbackup.sh /var/www

# Weekly full backup on Sunday at 1 AM
0 1 * * 0 BACKUP_DIR=/mnt/weekly ENCRYPT=yes RETENTION_DAYS=180 /root/scripts/utilities/dirbackup.sh /
```

### Monitoring Schedule

```bash
# System stats every 6 hours
0 */6 * * * OUTPUT_FORMAT=json SAVE_TO_FILE=yes OUTPUT_FILE=/var/log/stats-$(date +\%Y\%m\%d-\%H\%M).json /root/scripts/server_management/system_stats.sh

# Cleanup old stats (keep 30 days)
0 4 * * * find /var/log/stats-*.json -mtime +30 -delete
```

### Certificate Renewal

```bash
# Daily at 3:30 AM
30 3 * * * certbot renew --quiet --post-hook "systemctl reload nginx"
```

## Configuration Management Integration

### Ansible Playbook

```yaml
---
- name: Deploy web servers
  hosts: webservers
  become: yes
  tasks:
    - name: Copy scripts
      copy:
        src: sysadmin-shell-scripts/
        dest: /opt/scripts/

    - name: Install Nginx
      command: /opt/scripts/installation_scripts/install_nginx.sh
      environment:
        APP_TYPE: flask
        DOMAIN_NAME: "{{ inventory_hostname }}"

    - name: Setup backups
      cron:
        name: "Backup /etc"
        hour: "2"
        minute: "0"
        job: "BACKUP_DIR=/mnt/backups ENCRYPT=yes /opt/scripts/utilities/etcbackup.sh"
```

### SaltStack State

```yaml
# /srv/salt/webserver.sls
install_nginx:
  cmd.run:
    - name: /opt/scripts/installation_scripts/install_nginx.sh
    - env:
        - APP_TYPE: flask
    - creates: /etc/nginx/nginx.conf

backup_etc:
  cron.present:
    - name: /opt/scripts/utilities/etcbackup.sh
    - user: root
    - hour: 2
    - minute: 0
    - env:
        - BACKUP_DIR: /mnt/backups
        - ENCRYPT: yes
```

## Multi-Server Deployment

### Parallel Installation

```bash
#!/bin/bash
SERVERS=(web01 web02 web03)

for server in "${SERVERS[@]}"; do
    (
        echo "Deploying to $server..."
        ssh root@$server "bash -s" < installation_scripts/install_nginx.sh
        echo "Done: $server"
    ) &
done
wait
```

### Centralized Backup Collection

```bash
#!/bin/bash
SERVERS=(web01 web02 db01)
BACKUP_ROOT="/mnt/backups"

for server in "${SERVERS[@]}"; do
    ssh root@$server "BACKUP_DIR=/tmp/backups ENCRYPT=yes ./utilities/etcbackup.sh"
    LATEST=$(ssh root@$server "ls -t /tmp/backups/etc_*.tar.*.gpg | head -1")
    scp root@$server:$LATEST $BACKUP_ROOT/$server/
    ssh root@$server "rm $LATEST ${LATEST}.sha256"
done
```

### Health Check Dashboard

```bash
#!/bin/bash
SERVERS=(web01 web02 db01)

echo "Server Health - $(date)"
echo "====================================="

for server in "${SERVERS[@]}"; do
    echo ""
    echo "Server: $server"
    STATS=$(ssh root@$server "OUTPUT_FORMAT=json ./server_management/system_stats.sh")
    echo "  OS: $(echo $STATS | jq -r '.os_name')"
    echo "  Load: $(echo $STATS | jq -r '.load_average')"
    echo "  Memory: $(echo $STATS | jq -r '.memory.used')G / $(echo $STATS | jq -r '.memory.total')G"
done
```

## Tips

### Script Organization

```bash
# System-wide
sudo mkdir -p /opt/sysadmin-scripts
sudo git clone https://github.com/user/sysadmin-shell-scripts.git /opt/sysadmin-scripts

# Add to PATH
echo 'export PATH="/opt/sysadmin-scripts/utilities:$PATH"' >> ~/.bashrc
```

### Logging

All scripts log to syslog. View with:
```bash
sudo journalctl -t dirbackup.sh
sudo journalctl -t system_stats.sh -f  # Follow
```

### Error Handling

Scripts use `set -euo pipefail` so they exit on errors. Check exit codes:
```bash
./utilities/dirbackup.sh /data
if [ $? -eq 0 ]; then
    echo "Success"
fi
```

### Security

Never hardcode credentials:
```bash
# Bad
mysql -u root -pMyPassword

# Good - prompt
./installation_scripts/create_db.sh

# Good - environment variable
MYSQL_PASSWORD=$(read -sp "Password: "; echo $REPLY)
mysql -u root -p$MYSQL_PASSWORD
```
