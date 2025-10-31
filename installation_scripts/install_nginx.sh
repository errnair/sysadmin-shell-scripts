#!/usr/bin/env bash
set -euo pipefail

#################################################
#                                               #
#     Install and configure Nginx web server   #
#     Multi-OS support with virtual hosting     #
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
NGINX_VERSION="${NGINX_VERSION:-latest}"
ENABLE_SSL="${ENABLE_SSL:-no}"
APP_TYPE="${APP_TYPE:-static}"  # static, proxy, or flask

print_header "Nginx Web Server Installer"

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
  $0 example.com                    # Install with basic static site
  APP_TYPE=proxy $0 api.example.com # Install as reverse proxy
  APP_TYPE=flask $0 app.example.com # Install with Flask/Gunicorn
  ENABLE_SSL=yes $0 example.com     # Install with Let's Encrypt SSL"
    fi

    if ! validate_domain "$DOMAIN"; then
        error_exit "Invalid domain format: $DOMAIN"
    fi

    # Extract username from domain (first part before first dot)
    USERNAME=$(echo "$DOMAIN" | cut -d. -f1)

    print_info "Domain: $DOMAIN"
    print_info "Username: $USERNAME"
    print_info "Application type: $APP_TYPE"
    print_info "SSL: $ENABLE_SSL"
    echo
}

# Check if Nginx is already installed
check_existing_nginx() {
    if command_exists nginx; then
        local current_version=$(nginx -v 2>&1 | awk -F'/' '{print $2}')
        print_info "Nginx is already installed: $current_version"

        if confirm "Nginx is already installed. Continue with configuration?" "yes"; then
            return 0
        else
            exit 0
        fi
    fi
    return 0
}

# Install Nginx
install_nginx() {
    print_header "Installing Nginx"

    case "$OS" in
        rhel)
            # Determine RHEL version for repo URL
            local rhel_version=$(rpm -E %{rhel})

            case "$PKG_MGR" in
                dnf)
                    # Add Nginx mainline repo
                    print_info "Adding Nginx repository for RHEL $rhel_version..."
                    cat > /etc/yum.repos.d/nginx.repo <<EOF
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/rhel/${rhel_version}/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF

                    dnf install -y nginx
                    ;;
                yum)
                    # Add Nginx mainline repo
                    print_info "Adding Nginx repository for RHEL $rhel_version..."
                    cat > /etc/yum.repos.d/nginx.repo <<EOF
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/rhel/${rhel_version}/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
EOF

                    yum install -y nginx
                    ;;
            esac
            ;;
        debian)
            print_info "Installing Nginx from Ubuntu/Debian repositories..."
            apt-get update
            apt-get install -y nginx
            ;;
        *)
            error_exit "Unsupported OS: $OS"
            ;;
    esac

    # Enable and start Nginx
    systemctl enable nginx
    systemctl start nginx

    print_success "Nginx installed successfully"
}

# Configure firewall
configure_firewall() {
    print_info "Configuring firewall..."

    if command_exists firewall-cmd; then
        # firewalld (RHEL-based)
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --reload
        print_success "Firewall configured (firewalld)"
    elif command_exists ufw; then
        # ufw (Debian-based)
        ufw allow 'Nginx Full'
        print_success "Firewall configured (ufw)"
    else
        print_warning "No supported firewall found (firewalld/ufw)"
    fi
}

# Create system user for the site
create_site_user() {
    print_header "Creating site user: $USERNAME"

    if id "$USERNAME" &>/dev/null; then
        print_warning "User $USERNAME already exists"
    else
        useradd -m -s /sbin/nologin "$USERNAME"
        print_success "User $USERNAME created"
    fi

    # Create directory structure
    local user_home="/home/$USERNAME"
    mkdir -p "$user_home"/{logs,public_html,backup}

    # Set permissions
    chmod 755 "$user_home"
    chown -R "$USERNAME:$USERNAME" "$user_home"

    # SELinux contexts (RHEL-based only)
    if command_exists chcon; then
        print_info "Setting SELinux contexts..."
        chcon -Rt httpd_log_t "$user_home/logs/" || print_warning "Failed to set SELinux context for logs"
        chcon -Rt httpd_sys_content_t "$user_home/public_html/" || print_warning "Failed to set SELinux context for public_html"
    fi

    # Create test index file
    cat > "$user_home/public_html/index.html" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to $DOMAIN</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f4f4f4; }
        .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #009639; }
        .info { background: #e7f5ff; padding: 15px; border-radius: 4px; margin-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to $DOMAIN</h1>
        <p>Nginx is successfully installed and running.</p>
        <div class="info">
            <strong>Site Information:</strong><br>
            Domain: $DOMAIN<br>
            Document Root: $user_home/public_html/<br>
            Logs: $user_home/logs/
        </div>
    </div>
</body>
</html>
EOF

    chown "$USERNAME:$USERNAME" "$user_home/public_html/index.html"

    print_success "Site directories and test page created"
}

# Configure Nginx virtual host
configure_vhost() {
    print_header "Configuring Nginx virtual host"

    # Create sites-available and sites-enabled directories
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled

    # Check if nginx.conf includes sites-enabled
    if ! grep -q "sites-enabled" /etc/nginx/nginx.conf; then
        print_info "Updating nginx.conf to include sites-enabled..."

        # Backup original config
        cp /etc/nginx/nginx.conf "/etc/nginx/nginx.conf.bak-$(date +%Y%m%d)"

        # Add include directive in http block
        sed -i '/http {/a\    include /etc/nginx/sites-enabled/*.conf;' /etc/nginx/nginx.conf
    fi

    # Create virtual host configuration based on app type
    local vhost_file="/etc/nginx/sites-available/${DOMAIN}.conf"

    case "$APP_TYPE" in
        static)
            create_static_vhost "$vhost_file"
            ;;
        proxy)
            create_proxy_vhost "$vhost_file"
            ;;
        flask)
            create_flask_vhost "$vhost_file"
            ;;
        *)
            error_exit "Invalid APP_TYPE: $APP_TYPE (must be: static, proxy, or flask)"
            ;;
    esac

    # Enable site
    ln -sf "$vhost_file" "/etc/nginx/sites-enabled/${DOMAIN}.conf"

    # Test configuration
    if nginx -t; then
        print_success "Nginx configuration test passed"
        systemctl reload nginx
    else
        error_exit "Nginx configuration test failed"
    fi

    print_success "Virtual host configured: $DOMAIN"
}

# Create static site vhost
create_static_vhost() {
    local vhost_file="$1"
    local user_home="/home/$USERNAME"

    cat > "$vhost_file" <<EOF
server {
    listen 80;
    listen [::]:80;

    server_name $DOMAIN www.$DOMAIN;
    root $user_home/public_html;
    index index.html index.htm;

    access_log $user_home/logs/access.log;
    error_log $user_home/logs/error.log;

    location / {
        try_files \$uri \$uri/ =404;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
}
EOF

    print_info "Created static site configuration"
}

# Create reverse proxy vhost
create_proxy_vhost() {
    local vhost_file="$1"
    local user_home="/home/$USERNAME"
    local backend_port="${BACKEND_PORT:-8080}"

    cat > "$vhost_file" <<EOF
server {
    listen 80;
    listen [::]:80;

    server_name $DOMAIN www.$DOMAIN;

    access_log $user_home/logs/access.log;
    error_log $user_home/logs/error.log;

    location / {
        proxy_pass http://127.0.0.1:$backend_port;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
EOF

    print_info "Created reverse proxy configuration (backend: 127.0.0.1:$backend_port)"
}

# Create Flask/Gunicorn vhost
create_flask_vhost() {
    local vhost_file="$1"
    local user_home="/home/$USERNAME"

    cat > "$vhost_file" <<EOF
server {
    listen 80;
    listen [::]:80;

    server_name $DOMAIN www.$DOMAIN;

    access_log $user_home/logs/access.log;
    error_log $user_home/logs/error.log;

    location / {
        proxy_pass http://unix:$user_home/public_html/${USERNAME}.sock;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # Timeouts for Flask apps
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Static files (if any)
    location /static {
        alias $user_home/public_html/static;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
EOF

    print_info "Created Flask/Gunicorn configuration"
}

# Setup SSL with Let's Encrypt (optional)
setup_ssl() {
    if [[ "$ENABLE_SSL" != "yes" ]]; then
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

    # Obtain certificate
    print_info "Obtaining SSL certificate for $DOMAIN..."
    print_warning "This will modify your Nginx configuration and requires domain DNS to be properly configured"

    if confirm "Proceed with SSL certificate generation?" "no"; then
        certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email

        if [ $? -eq 0 ]; then
            print_success "SSL certificate installed successfully"

            # Setup automatic renewal
            systemctl enable certbot-renew.timer 2>/dev/null || crontab -l 2>/dev/null | grep -q certbot || (crontab -l 2>/dev/null; echo "0 0,12 * * * certbot renew --quiet") | crontab -
        else
            print_warning "SSL certificate generation failed. You can run certbot manually later."
        fi
    else
        print_info "Skipping SSL setup"
    fi
}

# Configure SELinux for Nginx (RHEL-based only)
configure_selinux() {
    if ! command_exists getenforce; then
        return 0
    fi

    local selinux_mode=$(getenforce)
    if [[ "$selinux_mode" == "Disabled" ]]; then
        return 0
    fi

    print_header "Configuring SELinux for Nginx"

    # Allow Nginx to connect to network
    setsebool -P httpd_can_network_connect 1

    # Allow Nginx to read user content
    setsebool -P httpd_read_user_content 1

    # For Flask/proxy apps
    if [[ "$APP_TYPE" == "flask" ]] || [[ "$APP_TYPE" == "proxy" ]]; then
        setsebool -P httpd_can_network_relay 1
    fi

    print_success "SELinux configured for Nginx"
}

# Display post-installation information
display_summary() {
    print_header "Installation Complete"

    local ip_addr=$(hostname -I | awk '{print $1}')

    print_success "Nginx installed and configured successfully!"
    echo
    print_info "Site Information:"
    print_info "  Domain: $DOMAIN"
    print_info "  Username: $USERNAME"
    print_info "  Document Root: /home/$USERNAME/public_html/"
    print_info "  Logs: /home/$USERNAME/logs/"
    print_info "  Configuration: /etc/nginx/sites-available/${DOMAIN}.conf"
    echo

    if [[ "$ENABLE_SSL" == "yes" ]]; then
        print_info "SSL: Enabled (Let's Encrypt)"
        print_info "Test URL: https://$DOMAIN"
    else
        print_info "SSL: Not enabled"
        print_info "Test URL: http://$DOMAIN"
    fi

    echo
    print_info "Add to your local hosts file for testing:"
    print_info "  $ip_addr  $DOMAIN www.$DOMAIN"
    echo

    case "$APP_TYPE" in
        flask)
            print_info "Flask Application Setup:"
            print_info "  1. Deploy your Flask app to /home/$USERNAME/public_html/"
            print_info "  2. Create a systemd service for Gunicorn"
            print_info "  3. Start your application service"
            ;;
        proxy)
            print_info "Reverse Proxy Setup:"
            print_info "  Backend: 127.0.0.1:${BACKEND_PORT:-8080}"
            print_info "  Ensure your backend application is running"
            ;;
        static)
            print_info "Static Site:"
            print_info "  Upload your files to /home/$USERNAME/public_html/"
            ;;
    esac

    echo
    print_info "Useful commands:"
    print_info "  nginx -t              # Test configuration"
    print_info "  systemctl reload nginx # Reload configuration"
    print_info "  systemctl status nginx # Check service status"

    log_success "Nginx installation completed for $DOMAIN"
}

# Main installation flow
main() {
    validate_domain_input
    check_existing_nginx
    install_nginx
    configure_firewall
    create_site_user
    configure_vhost
    configure_selinux
    setup_ssl
    display_summary
}

# Run main
main
