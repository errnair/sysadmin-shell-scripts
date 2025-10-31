#!/usr/bin/env bash
set -euo pipefail

#################################################
#                                               #
#     Install Flask application with Gunicorn  #
#     Includes Nginx reverse proxy setup        #
#     Multi-OS support with systemd service     #
#                                               #
#################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Setup
trap cleanup_on_exit EXIT
require_root

# Configuration
DOMAIN="${1:-}"
PYTHON_VERSION="${PYTHON_VERSION:-3}"
FLASK_APP_REPO="${FLASK_APP_REPO:-}"
GUNICORN_WORKERS="${GUNICORN_WORKERS:-3}"
ENABLE_SSL="${ENABLE_SSL:-no}"
INSTALL_NGINX="${INSTALL_NGINX:-yes}"

print_header "Flask Application Installer"

# Detect OS
OS=$(detect_os)
PKG_MGR=$(get_package_manager)

print_info "Detected OS: $OS"
print_info "Package manager: $PKG_MGR"
echo

# Validate domain
validate_domain_input() {
    if [[ -z "$DOMAIN" ]]; then
        error_exit "Usage: $0 <domain-name.tld> [options]

Examples:
  $0 app.example.com                              # Basic Flask installation
  FLASK_APP_REPO=github.com/user/app $0 app.com  # Install from Git repo
  ENABLE_SSL=yes $0 app.example.com               # With SSL certificate
  GUNICORN_WORKERS=5 $0 api.example.com           # Custom worker count"
    fi

    if ! validate_domain "$DOMAIN"; then
        error_exit "Invalid domain format: $DOMAIN"
    fi

    USERNAME=$(echo "$DOMAIN" | cut -d. -f1)

    print_info "Domain: $DOMAIN"
    print_info "Username: $USERNAME"
    print_info "Python version: $PYTHON_VERSION"
    print_info "Gunicorn workers: $GUNICORN_WORKERS"
    print_info "Install Nginx: $INSTALL_NGINX"
    print_info "SSL: $ENABLE_SSL"
    echo
}

# Install system dependencies
install_dependencies() {
    print_header "Installing system dependencies"

    case "$OS" in
        rhel)
            case "$PKG_MGR" in
                dnf)
                    dnf install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-pip python${PYTHON_VERSION}-devel \
                        git gcc make
                    ;;
                yum)
                    yum install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-pip python${PYTHON_VERSION}-devel \
                        git gcc make
                    ;;
            esac
            ;;
        debian)
            apt-get update
            apt-get install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-pip python${PYTHON_VERSION}-venv \
                python${PYTHON_VERSION}-dev git build-essential
            ;;
        *)
            error_exit "Unsupported OS: $OS"
            ;;
    esac

    print_success "Dependencies installed"
}

# Install Nginx if requested
install_nginx() {
    if [[ "$INSTALL_NGINX" != "yes" ]]; then
        print_info "Skipping Nginx installation"
        return 0
    fi

    if command_exists nginx; then
        print_info "Nginx is already installed"
        return 0
    fi

    print_header "Installing Nginx"

    case "$OS" in
        rhel)
            local rhel_version=$(rpm -E %{rhel})

            # Add Nginx repo
            cat > /etc/yum.repos.d/nginx.repo <<EOF
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/rhel/${rhel_version}/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF

            $PKG_MGR install -y nginx
            ;;
        debian)
            apt-get install -y nginx
            ;;
    esac

    systemctl enable nginx
    systemctl start nginx

    # Configure firewall
    if command_exists firewall-cmd; then
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --reload
    elif command_exists ufw; then
        ufw allow 'Nginx Full'
    fi

    print_success "Nginx installed"
}

# Create application user
create_app_user() {
    print_header "Creating application user: $USERNAME"

    if id "$USERNAME" &>/dev/null; then
        print_warning "User $USERNAME already exists"
    else
        useradd -m -s /bin/bash "$USERNAME"
        print_success "User $USERNAME created"
    fi

    # Add user to appropriate group for Nginx
    if getent group nginx &>/dev/null; then
        usermod -a -G "$USERNAME" nginx
    elif getent group www-data &>/dev/null; then
        usermod -a -G "$USERNAME" www-data
    fi

    # Create directory structure
    local user_home="/home/$USERNAME"
    mkdir -p "$user_home"/{logs,public_html,backup}

    # Set permissions
    chmod 755 "$user_home"
    chown -R "$USERNAME:$USERNAME" "$user_home"

    # SELinux contexts (RHEL only)
    if command_exists chcon; then
        print_info "Setting SELinux contexts..."
        chcon -Rt httpd_log_t "$user_home/logs/" 2>/dev/null || true
        chcon -Rt httpd_sys_content_t "$user_home/public_html/" 2>/dev/null || true
    fi

    print_success "User and directories created"
}

# Setup Python virtual environment
setup_virtualenv() {
    print_header "Setting up Python virtual environment"

    local user_home="/home/$USERNAME"
    local venv_path="$user_home/public_html/venv"

    # Create virtual environment as the user
    sudo -u "$USERNAME" bash <<EOF
set -euo pipefail
cd "$user_home/public_html"

# Create virtual environment
python${PYTHON_VERSION} -m venv venv

# Activate and upgrade pip
source venv/bin/activate
pip install --upgrade pip setuptools wheel

# Install Flask and Gunicorn
pip install flask gunicorn

# Deactivate
deactivate
EOF

    print_success "Virtual environment created at $venv_path"
}

# Deploy Flask application
deploy_flask_app() {
    print_header "Deploying Flask application"

    local user_home="/home/$USERNAME"
    local app_dir="$user_home/public_html"

    if [[ -n "$FLASK_APP_REPO" ]]; then
        print_info "Cloning application from repository: $FLASK_APP_REPO"

        sudo -u "$USERNAME" bash <<EOF
set -euo pipefail
cd "$app_dir"

# Clone repository
git clone "$FLASK_APP_REPO" app || {
    echo "Failed to clone repository"
    exit 1
}

# Install requirements if they exist
if [ -f app/requirements.txt ]; then
    source venv/bin/activate
    pip install -r app/requirements.txt
    deactivate
fi
EOF

        print_success "Application cloned from repository"
    else
        print_info "Creating sample Flask application"

        # Create sample Flask app
        sudo -u "$USERNAME" bash <<'EOF'
set -euo pipefail
cd ~/public_html

mkdir -p app/static app/templates

# Create simple Flask app
cat > app/run.py <<'PYTHON'
from flask import Flask, render_template

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/health')
def health():
    return {'status': 'healthy'}, 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
PYTHON

# Create index template
cat > app/templates/index.html <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Flask Application</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f4f4f4; }
        .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #000; }
        .info { background: #e7f5ff; padding: 15px; border-radius: 4px; margin-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Flask Application Running</h1>
        <p>Your Flask application is successfully deployed and running with Gunicorn.</p>
        <div class="info">
            <strong>Endpoints:</strong><br>
            / - This page<br>
            /health - Health check endpoint
        </div>
    </div>
</body>
</html>
HTML

# Create requirements.txt
cat > app/requirements.txt <<'REQUIREMENTS'
Flask>=3.0.0
gunicorn>=21.2.0
REQUIREMENTS

# Install requirements
source venv/bin/activate
pip install -r app/requirements.txt
deactivate
EOF

        print_success "Sample Flask application created"
    fi
}

# Create Gunicorn systemd service
create_gunicorn_service() {
    print_header "Creating Gunicorn systemd service"

    local user_home="/home/$USERNAME"
    local service_file="/etc/systemd/system/${USERNAME}.service"

    cat > "$service_file" <<EOF
[Unit]
Description=Gunicorn instance to serve Flask app for $USERNAME
After=network.target

[Service]
Type=notify
User=$USERNAME
Group=$USERNAME
WorkingDirectory=$user_home/public_html/app
Environment="PATH=$user_home/public_html/venv/bin"
ExecStart=$user_home/public_html/venv/bin/gunicorn \\
    --workers $GUNICORN_WORKERS \\
    --bind unix:$user_home/public_html/${USERNAME}.sock \\
    --umask 007 \\
    --access-logfile $user_home/logs/gunicorn-access.log \\
    --error-logfile $user_home/logs/gunicorn-error.log \\
    --log-level info \\
    run:app
ExecReload=/bin/kill -s HUP \$MAINPID
KillMode=mixed
TimeoutStopSec=5
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd and enable service
    systemctl daemon-reload
    systemctl enable "${USERNAME}.service"
    systemctl start "${USERNAME}.service"

    # Check status
    if systemctl is-active --quiet "${USERNAME}.service"; then
        print_success "Gunicorn service created and started"
    else
        print_warning "Gunicorn service created but failed to start. Check logs with: journalctl -u ${USERNAME}.service"
    fi
}

# Configure Nginx reverse proxy
configure_nginx() {
    if [[ "$INSTALL_NGINX" != "yes" ]]; then
        return 0
    fi

    print_header "Configuring Nginx reverse proxy"

    local user_home="/home/$USERNAME"

    # Create sites directories
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled

    # Update nginx.conf if needed
    if ! grep -q "sites-enabled" /etc/nginx/nginx.conf; then
        cp /etc/nginx/nginx.conf "/etc/nginx/nginx.conf.bak-$(date +%Y%m%d)"
        sed -i '/http {/a\    include /etc/nginx/sites-enabled/*.conf;' /etc/nginx/nginx.conf
    fi

    # Create Nginx vhost
    cat > "/etc/nginx/sites-available/${DOMAIN}.conf" <<EOF
server {
    listen 80;
    listen [::]:80;

    server_name $DOMAIN www.$DOMAIN;

    access_log $user_home/logs/nginx-access.log;
    error_log $user_home/logs/nginx-error.log;

    # Flask application via Gunicorn socket
    location / {
        proxy_pass http://unix:$user_home/public_html/${USERNAME}.sock;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Static files
    location /static {
        alias $user_home/public_html/app/static;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
EOF

    # Enable site
    ln -sf "/etc/nginx/sites-available/${DOMAIN}.conf" "/etc/nginx/sites-enabled/${DOMAIN}.conf"

    # Test and reload
    if nginx -t; then
        systemctl reload nginx
        print_success "Nginx configured successfully"
    else
        error_exit "Nginx configuration test failed"
    fi
}

# Configure SELinux
configure_selinux() {
    if ! command_exists getenforce; then
        return 0
    fi

    local selinux_mode=$(getenforce)
    if [[ "$selinux_mode" == "Disabled" ]]; then
        return 0
    fi

    print_header "Configuring SELinux"

    # Allow Nginx to connect to network
    setsebool -P httpd_can_network_connect 1
    setsebool -P httpd_can_network_relay 1
    setsebool -P httpd_read_user_content 1

    print_success "SELinux configured"
}

# Setup SSL
setup_ssl() {
    if [[ "$ENABLE_SSL" != "yes" ]] || [[ "$INSTALL_NGINX" != "yes" ]]; then
        return 0
    fi

    print_header "Setting up SSL with Let's Encrypt"

    # Install certbot
    if ! command_exists certbot; then
        print_info "Installing certbot..."
        case "$PKG_MGR" in
            dnf|yum)
                $PKG_MGR install -y certbot python3-certbot-nginx
                ;;
            apt)
                apt-get install -y certbot python3-certbot-nginx
                ;;
        esac
    fi

    print_warning "SSL certificate requires domain DNS to be properly configured"

    if confirm "Proceed with SSL certificate generation?" "no"; then
        certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email

        if [ $? -eq 0 ]; then
            print_success "SSL certificate installed"
            systemctl enable certbot-renew.timer 2>/dev/null || true
        else
            print_warning "SSL certificate generation failed"
        fi
    fi
}

# Display summary
display_summary() {
    print_header "Installation Complete"

    local ip_addr=$(hostname -I | awk '{print $1}')
    local user_home="/home/$USERNAME"

    print_success "Flask application installed successfully!"
    echo
    print_info "Application Information:"
    print_info "  Domain: $DOMAIN"
    print_info "  Username: $USERNAME"
    print_info "  Application Directory: $user_home/public_html/app/"
    print_info "  Virtual Environment: $user_home/public_html/venv/"
    print_info "  Logs: $user_home/logs/"
    echo

    if [[ "$ENABLE_SSL" == "yes" ]]; then
        print_info "URL: https://$DOMAIN"
    else
        print_info "URL: http://$DOMAIN"
    fi

    echo
    print_info "Add to your local hosts file for testing:"
    print_info "  $ip_addr  $DOMAIN www.$DOMAIN"
    echo

    print_info "Service Management:"
    print_info "  systemctl status ${USERNAME}    # Check service status"
    print_info "  systemctl restart ${USERNAME}   # Restart application"
    print_info "  systemctl stop ${USERNAME}      # Stop application"
    echo

    print_info "View Logs:"
    print_info "  tail -f $user_home/logs/gunicorn-error.log"
    print_info "  journalctl -u ${USERNAME} -f"
    echo

    print_info "Deploy Updates:"
    print_info "  1. Update code in $user_home/public_html/app/"
    print_info "  2. Install any new dependencies: source venv/bin/activate && pip install -r requirements.txt"
    print_info "  3. Restart service: systemctl restart ${USERNAME}"

    log_success "Flask application installed for $DOMAIN"
}

# Main installation flow
main() {
    validate_domain_input
    install_dependencies
    install_nginx
    create_app_user
    setup_virtualenv
    deploy_flask_app
    create_gunicorn_service
    configure_nginx
    configure_selinux
    setup_ssl
    display_summary
}

# Run main
main
