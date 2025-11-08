# Usage Examples

Comprehensive examples for common system administration tasks using these scripts.

## Table of Contents

- [Installation Workflows](#installation-workflows)
- [Backup and Recovery](#backup-and-recovery)
- [Security Hardening](#security-hardening)
- [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)
- [Automation with Cron](#automation-with-cron)
- [Integration with Configuration Management](#integration-with-configuration-management)
- [Multi-Server Deployment](#multi-server-deployment)

## Installation Workflows

### Complete Web Application Stack

Deploy a Flask application with Nginx reverse proxy:

```bash
# 1. Install Python 3 (tries system packages first)
sudo ./installation_scripts/install_python3.sh

# 2. Install Nginx with Flask application support
sudo ./installation_scripts/install_nginx.sh
# When prompted, select "flask" as application type

# 3. Alternative: Install Flask with Nginx in one step
sudo ./installation_scripts/install_flask.sh
# Provide application details when prompted
```

**What happens**:
- Creates dedicated user with virtual environment
- Sets up systemd service for Gunicorn
- Configures Nginx reverse proxy
- Optional SSL with Let's Encrypt
- Configures firewall (firewalld or ufw)
- Sets SELinux booleans (RHEL-based systems)

### CI/CD Pipeline Setup

Install Jenkins with prerequisites:

```bash
# 1. Install Jenkins (includes Java validation)
sudo ./installation_scripts/install_jenkins.sh

# 2. Custom port installation
sudo JENKINS_PORT=9090 ./installation_scripts/install_jenkins.sh

# 3. Install Ansible for deployment automation
sudo ANSIBLE_VERSION=2.16 ./installation_scripts/install_ansible.sh

# 4. Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

**Post-installation**:
- Jenkins running on http://server:8080 (or custom port)
- Firewall configured
- Service enabled and started
- Initial admin password displayed

### Monitoring Infrastructure

Deploy Nagios monitoring:

```bash
# 1. Install Nagios Core with plugins
sudo ./installation_scripts/install_nagios.sh
# Enter admin password when prompted

# 2. Access Nagios web interface
# URL: http://server/nagios
# Username: nagiosadmin
# Password: (what you entered during installation)

# 3. Configure monitored hosts
sudo vim /usr/local/nagios/etc/objects/hosts.cfg

# 4. Reload Nagios
sudo systemctl reload nagios
```

**Includes**:
- Nagios Core built from source
- Nagios Plugins
- NRPE for remote monitoring
- Apache with SSL support
- Example configurations

### SaltStack Configuration Management

Deploy Salt master and minions:

```bash
# On master server:
sudo ./installation_scripts/install_salt.sh

# On minion servers:
sudo MINION_ID=webserver01 ./installation_scripts/install_salt_minion.sh 192.168.1.100

# On master, accept minion keys:
sudo salt-key -L              # List keys
sudo salt-key -A              # Accept all pending keys

# Test connectivity:
sudo salt '*' test.ping
```

**State management**:
```bash
# Apply state to all minions
sudo salt '*' state.apply

# Apply specific state
sudo salt 'webserver*' state.apply nginx

# Target by OS
sudo salt -G 'os:Ubuntu' state.apply
```

### Proxy Server Deployment

Install and configure Squid:

```bash
# 1. Install Squid proxy
sudo ./installation_scripts/install_squid.sh
# Choose mode: forward, transparent, or reverse

# 2. Configure access control
sudo vim /etc/squid/squid.conf

# 3. Restart Squid
sudo systemctl restart squid

# 4. Test proxy
curl -x http://localhost:3128 https://example.com
```

## Backup and Recovery

### Daily /etc Backups

Simple daily backup of system configuration:

```bash
# Basic backup (90-day retention default)
sudo ./utilities/etcbackup.sh

# Encrypted backup
sudo ENCRYPT=yes ./utilities/etcbackup.sh

# Custom retention and encryption
sudo BACKUP_DIR=/mnt/backups RETENTION_DAYS=180 ENCRYPT=yes ./utilities/etcbackup.sh
```

**Cron job** (runs daily at 2 AM):
```bash
0 2 * * * BACKUP_DIR=/mnt/backups ENCRYPT=yes /root/scripts/utilities/etcbackup.sh
```

### Application Data Backup

Backup web application with verification:

```bash
# Full backup with encryption
sudo BACKUP_DIR=/mnt/backups \
     ENCRYPT=yes \
     COMPRESSION=xz \
     VERIFY=yes \
     RETENTION_DAYS=30 \
     ./utilities/dirbackup.sh /var/www

# Incremental backup (faster for large directories)
sudo BACKUP_DIR=/mnt/backups \
     INCREMENTAL=yes \
     RETENTION_DAYS=7 \
     ./utilities/dirbackup.sh /var/www
```

**Output**:
```
Backup created: /mnt/backups/var_www_20240115_140523.tar.xz
Checksum: /mnt/backups/var_www_20240115_140523.tar.xz.sha256
Size: 142.3 MB
Retention: Keeping backups from last 30 days
```

### Database Backup Integration

Combine with database dumps:

```bash
#!/bin/bash
# backup-mysql.sh

# Dump all databases
mysqldump --all-databases > /tmp/mysql-dump.sql

# Backup MySQL data directory and dump
sudo BACKUP_DIR=/mnt/backups \
     ENCRYPT=yes \
     RETENTION_DAYS=14 \
     ./utilities/dirbackup.sh /var/lib/mysql

sudo BACKUP_DIR=/mnt/backups \
     ENCRYPT=yes \
     RETENTION_DAYS=14 \
     ./utilities/dirbackup.sh /tmp/mysql-dump.sql

# Cleanup temporary dump
rm /tmp/mysql-dump.sql
```

### Restore from Backup

Restore encrypted backup:

```bash
# 1. List available backups
ls -lh /mnt/backups/etc_*.tar.xz.gpg

# 2. Decrypt backup
gpg -d /mnt/backups/etc_20240115_020001.tar.xz.gpg > /tmp/etc-backup.tar.xz

# 3. Verify checksum
sha256sum -c /mnt/backups/etc_20240115_020001.tar.xz.sha256

# 4. Extract
sudo tar -xJf /tmp/etc-backup.tar.xz -C /tmp/restore

# 5. Review and restore files
sudo cp -a /tmp/restore/etc/specific-config /etc/
```

### Backup to Remote Server

Backup and transfer to remote storage:

```bash
#!/bin/bash
# backup-and-transfer.sh

BACKUP_DIR=/mnt/backups
REMOTE_HOST=backup-server.example.com
REMOTE_DIR=/backups/$(hostname)

# Create encrypted backup
sudo BACKUP_DIR=$BACKUP_DIR \
     ENCRYPT=yes \
     RETENTION_DAYS=7 \
     ./utilities/dirbackup.sh /var/www

# Find today's backup
LATEST_BACKUP=$(ls -t $BACKUP_DIR/var_www_*.tar.*.gpg | head -1)

# Transfer to remote server
rsync -avz --progress $LATEST_BACKUP $REMOTE_HOST:$REMOTE_DIR/

# Verify transfer
ssh $REMOTE_HOST "sha256sum -c $REMOTE_DIR/$(basename $LATEST_BACKUP).sha256"
```

## Security Hardening

### SELinux Configuration and Troubleshooting

Proper SELinux workflow for web server:

```bash
# 1. Check current SELinux status
sudo ./server_management/selinux_troubleshoot.sh status

# 2. Deploy application
sudo cp -r /tmp/webapp /var/www/html/

# 3. Set correct SELinux context
sudo semanage fcontext -a -t httpd_sys_content_t "/var/www/html/webapp(/.*)?"
sudo restorecon -R /var/www/html/webapp

# 4. If permission denied errors occur, check denials
sudo ./server_management/selinux_troubleshoot.sh denials

# 5. Get fix suggestions
sudo ./server_management/selinux_troubleshoot.sh suggest

# 6. Apply suggested fixes (example)
sudo setsebool -P httpd_can_network_connect on

# 7. Only use permissive mode for troubleshooting
sudo ./server_management/selinux_troubleshoot.sh permissive

# 8. After fixing issues, re-enable enforcement
sudo ./server_management/selinux_troubleshoot.sh enforcing
```

**Common web server scenarios**:

```bash
# Allow Nginx/Apache to connect to network
sudo setsebool -P httpd_can_network_connect on

# Allow Nginx/Apache to connect to database
sudo setsebool -P httpd_can_network_connect_db on

# Allow Nginx/Apache to send email
sudo setsebool -P httpd_can_sendmail on

# Custom port for web server
sudo semanage port -a -t http_port_t -p tcp 8080
```

### Firewall Configuration

Configure firewall for web server:

```bash
# RHEL-based systems (firewalld)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload

# Debian-based systems (ufw)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8080/tcp
sudo ufw reload
```

### SSL/TLS Certificate Setup

Install Nginx with Let's Encrypt SSL:

```bash
# Install Nginx with SSL support
sudo ENABLE_SSL=yes DOMAIN_NAME=example.com ./installation_scripts/install_nginx.sh

# Manual Let's Encrypt certificate
sudo certbot certonly --nginx -d example.com -d www.example.com

# Auto-renewal test
sudo certbot renew --dry-run
```

### Secure Password Management

Generate and manage passwords:

```bash
# Generate strong password for service account
PASSWORD_TYPE=special ./utilities/passgen.sh 1 32

# Generate multiple passwords for users
PASSWORD_TYPE=special OUTPUT_FORMAT=csv ./utilities/passgen.sh 50 16 > user-passwords.csv

# Generate memorable passphrase
PASSWORD_TYPE=passphrase ./utilities/passgen.sh 1 5
# Example output: correct-horse-battery-staple-lambda

# Generate PIN for 2FA backup codes
PASSWORD_TYPE=pin ./utilities/passgen.sh 10 8
```

**Secure storage**:
```bash
# Encrypt password file
PASSWORD_TYPE=special OUTPUT_FORMAT=csv ./utilities/passgen.sh 100 16 | \
    gpg -c --cipher-algo AES256 > passwords.csv.gpg

# Decrypt when needed
gpg -d passwords.csv.gpg
```

## Monitoring and Troubleshooting

### System Information Collection

Collect comprehensive system information:

```bash
# Text output for viewing
sudo ./server_management/system_stats.sh

# JSON output for automation
sudo OUTPUT_FORMAT=json ./server_management/system_stats.sh > /tmp/stats.json

# Parse JSON with jq
sudo OUTPUT_FORMAT=json ./server_management/system_stats.sh | jq '.memory'

# CSV output for spreadsheet import
sudo OUTPUT_FORMAT=csv ./server_management/system_stats.sh > system-stats.csv
```

**Automated collection**:
```bash
# Collect stats from multiple servers
for server in web{01..05}.example.com; do
    ssh $server "sudo OUTPUT_FORMAT=json ./system_stats.sh" > ${server}-stats.json
done

# Aggregate and analyze
jq -s '.' *-stats.json > all-servers-stats.json
```

### CPU Monitoring

Monitor CPU information:

```bash
# Basic CPU info
python3 python-scripts/checkcpu.py

# JSON output
python3 python-scripts/checkcpu.py --json

# Verbose with all flags
python3 python-scripts/checkcpu.py --verbose

# Parse specific fields
python3 python-scripts/checkcpu.py --json | jq '.model_name'
```

**Automated monitoring**:
```bash
#!/bin/bash
# monitor-cpu.sh

OUTPUT=$(python3 python-scripts/checkcpu.py --json)
CPU_COUNT=$(echo $OUTPUT | jq -r '.cpu_count')
CPU_MODEL=$(echo $OUTPUT | jq -r '.model_name')

echo "Server: $(hostname)"
echo "CPUs: $CPU_COUNT"
echo "Model: $CPU_MODEL"
```

### Performance Benchmarking

Benchmark commands and scripts:

```bash
# Time a single command
python3 python-scripts/timer.py "ls -la /usr/bin"

# Run 100 iterations with statistics
python3 python-scripts/timer.py -n 100 "curl -s https://example.com"

# Output:
# Command: curl -s https://example.com
# Iterations: 100
# Total time: 45.23s
# Statistics:
#   Min: 0.412s
#   Max: 0.623s
#   Mean: 0.452s
#   Median: 0.448s
#   Std Dev: 0.023s

# Compare two approaches
python3 python-scripts/timer.py --compare \
    "grep -r pattern /var/log" \
    "rg pattern /var/log"

# Warmup before benchmarking (exclude first 5 runs)
python3 python-scripts/timer.py -n 100 --warmup 5 "command"

# Export results to CSV
python3 python-scripts/timer.py --csv -n 50 "command" > benchmark-results.csv
```

### Port Connectivity Testing

Test network connectivity:

```bash
# Check single port
python3 python-scripts/portcheck.py example.com 443

# Scan port range
python3 python-scripts/portcheck.py example.com 20-25

# JSON output
python3 python-scripts/portcheck.py --json example.com 80

# Check multiple services
for port in 22 80 443 3306; do
    python3 python-scripts/portcheck.py db-server.example.com $port
done
```

### SSH Connection Monitoring

Monitor SSH connectivity to servers:

```bash
# Check SSH connection
./installation_scripts/checkssh_conn.sh user@server.example.com

# Monitor multiple servers
#!/bin/bash
SERVERS="web01 web02 db01 db02"
for server in $SERVERS; do
    ./installation_scripts/checkssh_conn.sh user@${server}.example.com
done
```

## Automation with Cron

### Daily Backup Schedule

```bash
# Edit crontab
crontab -e

# Add backup jobs:

# /etc backup at 2 AM daily
0 2 * * * BACKUP_DIR=/mnt/backups ENCRYPT=yes RETENTION_DAYS=90 /root/scripts/utilities/etcbackup.sh

# Web application backup at 3 AM daily
0 3 * * * BACKUP_DIR=/mnt/backups ENCRYPT=yes RETENTION_DAYS=30 /root/scripts/utilities/dirbackup.sh /var/www

# Database backup at 1 AM daily
0 1 * * * /root/scripts/backup-mysql.sh

# Weekly full backup on Sunday at 1 AM
0 1 * * 0 BACKUP_DIR=/mnt/weekly ENCRYPT=yes RETENTION_DAYS=180 /root/scripts/utilities/dirbackup.sh /
```

### System Monitoring Schedule

```bash
# System stats collection every 6 hours
0 */6 * * * OUTPUT_FORMAT=json SAVE_TO_FILE=yes OUTPUT_FILE=/var/log/system-stats-$(date +\%Y\%m\%d-\%H\%M).json /root/scripts/server_management/system_stats.sh

# Cleanup old stats files (keep 30 days)
0 4 * * * find /var/log/system-stats-*.json -mtime +30 -delete

# SELinux denial monitoring
*/15 * * * * /root/scripts/server_management/selinux_troubleshoot.sh denials | mail -s "SELinux Denials on $(hostname)" admin@example.com
```

### Certificate Renewal

```bash
# Attempt certificate renewal daily at 3:30 AM
30 3 * * * certbot renew --quiet --post-hook "systemctl reload nginx"
```

## Integration with Configuration Management

### Ansible Playbook Integration

Use scripts in Ansible playbooks:

```yaml
---
# playbook.yml
- name: Deploy web application stack
  hosts: webservers
  become: yes

  tasks:
    - name: Copy installation scripts
      copy:
        src: sysadmin-shell-scripts/
        dest: /opt/scripts/
        mode: '0755'

    - name: Install Nginx
      command: /opt/scripts/installation_scripts/install_nginx.sh
      environment:
        APP_TYPE: flask
        ENABLE_SSL: yes
        DOMAIN_NAME: "{{ inventory_hostname }}"

    - name: Install Flask application
      command: /opt/scripts/installation_scripts/install_flask.sh
      environment:
        APP_NAME: myapp
        APP_PORT: 8000

    - name: Setup daily backups
      cron:
        name: "Backup /etc"
        hour: "2"
        minute: "0"
        job: "BACKUP_DIR=/mnt/backups ENCRYPT=yes /opt/scripts/utilities/etcbackup.sh"

    - name: Collect system stats
      shell: OUTPUT_FORMAT=json /opt/scripts/server_management/system_stats.sh
      register: system_stats

    - name: Display CPU count
      debug:
        msg: "Server {{ inventory_hostname }} has {{ (system_stats.stdout | from_json).cpu_count }} CPUs"
```

### SaltStack State Files

Use scripts in Salt states:

```yaml
# /srv/salt/webserver.sls
install_nginx:
  cmd.run:
    - name: /opt/scripts/installation_scripts/install_nginx.sh
    - env:
        - APP_TYPE: flask
        - ENABLE_SSL: yes
    - creates: /etc/nginx/nginx.conf

configure_backups:
  cron.present:
    - name: /opt/scripts/utilities/etcbackup.sh
    - user: root
    - hour: 2
    - minute: 0
    - env:
        - BACKUP_DIR: /mnt/backups
        - ENCRYPT: yes

collect_system_info:
  cmd.run:
    - name: OUTPUT_FORMAT=json /opt/scripts/server_management/system_stats.sh > /var/log/system-stats.json
```

## Multi-Server Deployment

### Parallel Installation Across Servers

Deploy to multiple servers in parallel:

```bash
#!/bin/bash
# deploy-nginx.sh

SERVERS=(
    "web01.example.com"
    "web02.example.com"
    "web03.example.com"
)

for server in "${SERVERS[@]}"; do
    (
        echo "Deploying to $server..."
        ssh root@$server "bash -s" < installation_scripts/install_nginx.sh
        echo "Completed: $server"
    ) &
done

wait
echo "All deployments completed"
```

### Centralized Backup Collection

Collect backups from multiple servers:

```bash
#!/bin/bash
# collect-backups.sh

BACKUP_SERVER="backup.example.com"
BACKUP_ROOT="/mnt/backups"
SERVERS=(web01 web02 db01)

for server in "${SERVERS[@]}"; do
    echo "Backing up $server..."

    # Trigger backup on remote server
    ssh root@$server "BACKUP_DIR=/tmp/backups ENCRYPT=yes ./utilities/etcbackup.sh"

    # Collect backup file
    LATEST=$(ssh root@$server "ls -t /tmp/backups/etc_*.tar.*.gpg | head -1")

    # Transfer to backup server
    scp root@$server:$LATEST $BACKUP_ROOT/$server/

    # Verify checksum
    scp root@$server:${LATEST}.sha256 $BACKUP_ROOT/$server/
    sha256sum -c $BACKUP_ROOT/$server/$(basename $LATEST).sha256

    # Cleanup remote backup
    ssh root@$server "rm $LATEST ${LATEST}.sha256"
done
```

### Health Check Dashboard

Collect and display server health:

```bash
#!/bin/bash
# health-dashboard.sh

SERVERS=(web01 web02 db01 db02)

echo "Server Health Dashboard - $(date)"
echo "=========================================="

for server in "${SERVERS[@]}"; do
    echo ""
    echo "Server: $server"
    echo "---"

    # Collect system stats
    STATS=$(ssh root@$server "OUTPUT_FORMAT=json ./server_management/system_stats.sh")

    # Parse and display key metrics
    echo "  OS: $(echo $STATS | jq -r '.os_name')"
    echo "  Uptime: $(echo $STATS | jq -r '.uptime')"
    echo "  Load: $(echo $STATS | jq -r '.load_average')"
    echo "  Memory: $(echo $STATS | jq -r '.memory.used')G / $(echo $STATS | jq -r '.memory.total')G"
    echo "  Disk: $(echo $STATS | jq -r '.disk.root.used_percent')"

    # Check SELinux status
    SELINUX=$(ssh root@$server "./server_management/selinux_troubleshoot.sh status")
    echo "  SELinux: $(echo $SELINUX | grep -oP 'Current mode: \K\w+')"
done
```

### Rolling Updates

Perform rolling updates with health checks:

```bash
#!/bin/bash
# rolling-update.sh

SERVERS=(web01 web02 web03 web04)
HEALTH_CHECK_URL="http://localhost/health"

for server in "${SERVERS[@]}"; do
    echo "Updating $server..."

    # Remove from load balancer
    ssh lb.example.com "backend-remove $server"
    sleep 5

    # Perform update
    ssh root@$server "dnf update -y && systemctl restart nginx"

    # Wait for service to start
    sleep 10

    # Health check
    if ssh root@$server "curl -sf $HEALTH_CHECK_URL"; then
        echo "$server is healthy"

        # Add back to load balancer
        ssh lb.example.com "backend-add $server"

        # Wait before next server
        sleep 30
    else
        echo "ERROR: $server failed health check!"
        ssh lb.example.com "backend-add $server"  # Add back anyway
        exit 1
    fi
done

echo "Rolling update completed successfully"
```

## Best Practices

### Script Organization

Organize scripts in a standard location:

```bash
# System-wide installation
sudo mkdir -p /opt/sysadmin-scripts
sudo git clone https://github.com/yourusername/sysadmin-shell-scripts.git /opt/sysadmin-scripts
sudo chmod -R 755 /opt/sysadmin-scripts

# Add to PATH
echo 'export PATH="/opt/sysadmin-scripts/utilities:$PATH"' >> ~/.bashrc
```

### Logging Best Practices

All scripts log to syslog. View logs:

```bash
# View all script logs
sudo journalctl -t dirbackup.sh
sudo journalctl -t system_stats.sh

# Follow logs in real-time
sudo journalctl -t etcbackup.sh -f

# View logs from specific time
sudo journalctl -t install_nginx.sh --since "1 hour ago"
```

### Error Handling

Scripts use `set -euo pipefail` for strict error handling:

```bash
# Script will exit on:
# - Any command failure (set -e)
# - Undefined variable use (set -u)
# - Pipeline failures (set -o pipefail)

# Check exit codes
./utilities/dirbackup.sh /data
if [ $? -eq 0 ]; then
    echo "Backup successful"
else
    echo "Backup failed"
fi
```

### Security Considerations

Never hardcode credentials:

```bash
# Bad - credentials in script
mysql -u root -pMyPassword

# Good - prompt for password
./installation_scripts/create_db.sh  # Prompts for password

# Good - use environment variable
MYSQL_PASSWORD=$(read -sp "Password: "; echo $REPLY)
mysql -u root -p$MYSQL_PASSWORD

# Good - use .my.cnf
cat > ~/.my.cnf <<EOF
[client]
password=SecurePassword
EOF
chmod 600 ~/.my.cnf
mysql  # No password needed
```
