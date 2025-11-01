#!/usr/bin/env bash
set -euo pipefail

#################################################
#                                               #
#     Install Nagios monitoring system          #
#     Includes Nagios Core, Plugins, and NRPE   #
#     Multi-OS support with HTTPS                #
#                                               #
#################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Setup
trap cleanup_on_exit EXIT
require_root

# Configuration
NAGIOS_VERSION="${NAGIOS_VERSION:-4.5.0}"
NAGIOS_PLUGINS_VERSION="${NAGIOS_PLUGINS_VERSION:-2.4.6}"
NRPE_VERSION="${NRPE_VERSION:-4.1.0}"
NAGIOS_ADMIN_USER="${NAGIOS_ADMIN_USER:-nagiosadmin}"
NAGIOS_ADMIN_EMAIL="${NAGIOS_ADMIN_EMAIL:-admin@localhost}"
ENABLE_SSL="${ENABLE_SSL:-yes}"
BUILD_DIR="/tmp/nagios-build-$$"

print_header "Nagios Monitoring System Installer"

# Detect OS
OS=$(detect_os)
PKG_MGR=$(get_package_manager)

print_info "Detected OS: $OS"
print_info "Package manager: $PKG_MGR"
print_info "Nagios version: $NAGIOS_VERSION"
print_info "Plugins version: $NAGIOS_PLUGINS_VERSION"
print_info "NRPE version: $NRPE_VERSION"
print_info "Enable SSL: $ENABLE_SSL"
echo

# Install prerequisites
install_prerequisites() {
    print_header "Installing prerequisites"

    case "$OS" in
        rhel)
            case "$PKG_MGR" in
                dnf)
                    dnf groupinstall -y "Development Tools"
                    dnf install -y httpd mod_ssl php wget unzip \
                        gcc glibc glibc-common openssl openssl-devel \
                        perl gd gd-devel gettext net-snmp net-snmp-utils \
                        xinetd
                    ;;
                yum)
                    yum groupinstall -y "Development Tools"
                    yum install -y httpd mod_ssl php wget unzip \
                        gcc glibc glibc-common openssl openssl-devel \
                        perl gd gd-devel gettext net-snmp net-snmp-utils \
                        xinetd
                    ;;
            esac
            ;;
        debian)
            apt-get update
            apt-get install -y apache2 libapache2-mod-php php wget unzip \
                build-essential libgd-dev openssl libssl-dev \
                perl gettext snmp xinetd apache2-utils

            # Enable Apache modules
            a2enmod ssl
            a2enmod cgi
            ;;
        *)
            error_exit "Unsupported OS: $OS"
            ;;
    esac

    print_success "Prerequisites installed"
}

# Create Nagios user and group
create_nagios_user() {
    print_header "Creating Nagios user and group"

    # Create nagios user if doesn't exist
    if ! id nagios &>/dev/null; then
        useradd -m -s /bin/bash nagios
        print_success "User 'nagios' created"
    else
        print_info "User 'nagios' already exists"
    fi

    # Create nagcmd group if doesn't exist
    if ! getent group nagcmd &>/dev/null; then
        groupadd nagcmd
        print_success "Group 'nagcmd' created"
    else
        print_info "Group 'nagcmd' already exists"
    fi

    # Add nagios user to nagcmd group
    usermod -a -G nagcmd nagios

    # Add web server user to nagcmd group
    if getent passwd apache &>/dev/null; then
        usermod -a -G nagcmd apache
    elif getent passwd www-data &>/dev/null; then
        usermod -a -G nagcmd www-data
    fi

    print_success "Nagios user and group configured"
}

# Download and compile Nagios Core
install_nagios_core() {
    print_header "Installing Nagios Core ${NAGIOS_VERSION}"

    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    # Download Nagios Core
    local nagios_url="https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-${NAGIOS_VERSION}/nagios-${NAGIOS_VERSION}.tar.gz"
    print_info "Downloading Nagios Core..."

    if command_exists curl; then
        curl -L -o "nagios-${NAGIOS_VERSION}.tar.gz" "$nagios_url"
    else
        wget -O "nagios-${NAGIOS_VERSION}.tar.gz" "$nagios_url"
    fi

    # Extract
    tar -xzf "nagios-${NAGIOS_VERSION}.tar.gz"
    cd "nagios-${NAGIOS_VERSION}"

    # Configure
    print_info "Configuring Nagios Core..."
    ./configure \
        --with-command-group=nagcmd \
        --with-httpd-conf=/etc/httpd/conf.d 2>/dev/null || \
        ./configure --with-command-group=nagcmd

    # Compile
    print_info "Compiling Nagios Core (this may take a few minutes)..."
    make all

    # Install
    print_info "Installing Nagios Core..."
    make install
    make install-init
    make install-commandmode
    make install-config

    # Install web config
    if [ "$OS" = "debian" ]; then
        make install-webconf -e HTTPD_CONF=/etc/apache2/sites-available
        ln -sf /etc/apache2/sites-available/nagios.conf /etc/apache2/sites-enabled/
    else
        make install-webconf
    fi

    print_success "Nagios Core installed to /usr/local/nagios/"
}

# Download and compile Nagios Plugins
install_nagios_plugins() {
    print_header "Installing Nagios Plugins ${NAGIOS_PLUGINS_VERSION}"

    cd "$BUILD_DIR"

    # Download Nagios Plugins
    local plugins_url="https://github.com/nagios-plugins/nagios-plugins/releases/download/release-${NAGIOS_PLUGINS_VERSION}/nagios-plugins-${NAGIOS_PLUGINS_VERSION}.tar.gz"
    print_info "Downloading Nagios Plugins..."

    if command_exists curl; then
        curl -L -o "nagios-plugins-${NAGIOS_PLUGINS_VERSION}.tar.gz" "$plugins_url"
    else
        wget -O "nagios-plugins-${NAGIOS_PLUGINS_VERSION}.tar.gz" "$plugins_url"
    fi

    # Extract
    tar -xzf "nagios-plugins-${NAGIOS_PLUGINS_VERSION}.tar.gz"
    cd "nagios-plugins-${NAGIOS_PLUGINS_VERSION}"

    # Configure
    print_info "Configuring Nagios Plugins..."
    ./configure \
        --with-nagios-user=nagios \
        --with-nagios-group=nagios \
        --with-openssl

    # Compile and install
    print_info "Compiling Nagios Plugins..."
    make
    make install

    print_success "Nagios Plugins installed"
}

# Download and compile NRPE
install_nrpe() {
    print_header "Installing NRPE ${NRPE_VERSION}"

    cd "$BUILD_DIR"

    # Download NRPE
    local nrpe_url="https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-${NRPE_VERSION}/nrpe-${NRPE_VERSION}.tar.gz"
    print_info "Downloading NRPE..."

    if command_exists curl; then
        curl -L -o "nrpe-${NRPE_VERSION}.tar.gz" "$nrpe_url"
    else
        wget -O "nrpe-${NRPE_VERSION}.tar.gz" "$nrpe_url"
    fi

    # Extract
    tar -xzf "nrpe-${NRPE_VERSION}.tar.gz"
    cd "nrpe-${NRPE_VERSION}"

    # Configure
    print_info "Configuring NRPE..."
    ./configure \
        --enable-command-args \
        --with-nagios-user=nagios \
        --with-nagios-group=nagios \
        --with-ssl=/usr/bin/openssl \
        --with-ssl-lib=/usr/lib/x86_64-linux-gnu 2>/dev/null || \
        ./configure \
        --enable-command-args \
        --with-nagios-user=nagios \
        --with-nagios-group=nagios \
        --with-ssl=/usr/bin/openssl \
        --with-ssl-lib=/usr/lib64

    # Compile and install
    print_info "Compiling NRPE..."
    make all
    make install
    make install-config
    make install-init

    # Add NRPE service port
    if ! grep -q "nrpe.*5666/tcp" /etc/services; then
        echo "nrpe            5666/tcp   # Nagios NRPE" >> /etc/services
    fi

    print_success "NRPE installed"
}

# Configure Nagios
configure_nagios() {
    print_header "Configuring Nagios"

    local nagios_cfg="/usr/local/nagios/etc/nagios.cfg"
    local contacts_cfg="/usr/local/nagios/etc/objects/contacts.cfg"
    local commands_cfg="/usr/local/nagios/etc/objects/commands.cfg"

    # Create servers directory
    mkdir -p /usr/local/nagios/etc/servers

    # Enable servers directory in main config
    if ! grep -q "cfg_dir=/usr/local/nagios/etc/servers" "$nagios_cfg"; then
        echo "cfg_dir=/usr/local/nagios/etc/servers" >> "$nagios_cfg"
    fi

    # Update contact email
    sed -i "s/nagios@localhost/${NAGIOS_ADMIN_EMAIL}/g" "$contacts_cfg"

    # Add check_nrpe command
    if ! grep -q "check_nrpe" "$commands_cfg"; then
        cat >> "$commands_cfg" <<'EOF'

# NRPE command definition
define command{
    command_name check_nrpe
    command_line $USER1$/check_nrpe -H $HOSTADDRESS$ -c $ARG1$
}
EOF
    fi

    print_success "Nagios configuration updated"
}

# Configure NRPE
configure_nrpe() {
    print_header "Configuring NRPE"

    local nrpe_cfg="/usr/local/nagios/etc/nrpe.cfg"
    local server_ip=$(hostname -I | awk '{print $1}')

    # Backup original config
    cp "$nrpe_cfg" "${nrpe_cfg}.bak"

    # Allow command arguments
    sed -i 's/dont_blame_nrpe=0/dont_blame_nrpe=1/' "$nrpe_cfg"

    # Add server IP to allowed hosts
    sed -i "s/allowed_hosts=127.0.0.1,::1/allowed_hosts=127.0.0.1,::1,${server_ip}/" "$nrpe_cfg"

    # Configure check_load with arguments
    sed -i 's/command\[check_load\]=.*/command[check_load]=\/usr\/local\/nagios\/libexec\/check_load -w 15,10,5 -c 30,25,20/' "$nrpe_cfg"

    print_success "NRPE configuration updated"
}

# Create Nagios admin user
create_nagios_admin() {
    print_header "Creating Nagios admin user"

    print_info "Creating web interface admin user: $NAGIOS_ADMIN_USER"

    # Create htpasswd file
    if [ -f /usr/local/nagios/etc/htpasswd.users ]; then
        print_warning "Admin user already exists, skipping creation"
    else
        # Get password securely
        read_password "Enter password for Nagios admin user '$NAGIOS_ADMIN_USER'" ADMIN_PASSWORD || error_exit "Password required"
        read_password "Confirm password for '$NAGIOS_ADMIN_USER'" ADMIN_PASSWORD_CONFIRM || error_exit "Password confirmation required"

        if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]; then
            error_exit "Passwords do not match"
        fi

        # Create htpasswd file
        echo "$ADMIN_PASSWORD" | htpasswd -i -c /usr/local/nagios/etc/htpasswd.users "$NAGIOS_ADMIN_USER"

        print_success "Admin user '$NAGIOS_ADMIN_USER' created"
    fi
}

# Configure web server
configure_webserver() {
    print_header "Configuring web server"

    case "$OS" in
        rhel)
            # Start and enable Apache
            systemctl enable httpd
            systemctl start httpd
            ;;
        debian)
            # Start and enable Apache
            systemctl enable apache2
            systemctl start apache2
            ;;
    esac

    print_success "Web server configured"
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

    # Set SELinux contexts
    chcon -R -t httpd_sys_content_t /usr/local/nagios/share/ 2>/dev/null || true
    chcon -R -t httpd_sys_rw_content_t /usr/local/nagios/var/ 2>/dev/null || true
    chcon -R -t httpd_sys_script_exec_t /usr/local/nagios/sbin/ 2>/dev/null || true
    chcon -R -t httpd_sys_rw_content_t /usr/local/nagios/var/rw/ 2>/dev/null || true

    # Set SELinux booleans
    setsebool -P httpd_can_network_connect 1

    print_success "SELinux configured"
}

# Configure firewall
configure_firewall() {
    print_header "Configuring firewall"

    if command_exists firewall-cmd; then
        # firewalld (RHEL-based)
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --permanent --add-port=5666/tcp
        firewall-cmd --reload
        print_success "Firewall configured (firewalld)"
    elif command_exists ufw; then
        # ufw (Debian-based)
        ufw allow 'Apache Full'
        ufw allow 5666/tcp
        print_success "Firewall configured (ufw)"
    else
        print_warning "No supported firewall found"
    fi
}

# Start services
start_services() {
    print_header "Starting services"

    # Enable and start Nagios
    systemctl enable nagios
    systemctl start nagios

    # Enable and start NRPE
    systemctl enable nrpe
    systemctl start nrpe

    # Restart web server
    if [ "$OS" = "debian" ]; then
        systemctl restart apache2
    else
        systemctl restart httpd
    fi

    # Verify Nagios configuration
    print_info "Verifying Nagios configuration..."
    if /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg; then
        print_success "Nagios configuration is valid"
    else
        error_exit "Nagios configuration validation failed"
    fi

    print_success "All services started"
}

# Display summary
display_summary() {
    print_header "Installation Complete"

    local ip_addr=$(hostname -I | awk '{print $1}')
    local protocol="http"
    [ "$ENABLE_SSL" = "yes" ] && protocol="https"

    print_success "Nagios monitoring system installed successfully!"
    echo

    print_info "Access Information:"
    print_info "  Web Interface: ${protocol}://${ip_addr}/nagios"
    print_info "  Username: $NAGIOS_ADMIN_USER"
    print_info "  Password: <set during installation>"
    echo

    print_info "Installation Details:"
    print_info "  Nagios Core: $NAGIOS_VERSION"
    print_info "  Nagios Plugins: $NAGIOS_PLUGINS_VERSION"
    print_info "  NRPE: $NRPE_VERSION"
    print_info "  Home directory: /usr/local/nagios/"
    print_info "  Configuration: /usr/local/nagios/etc/nagios.cfg"
    print_info "  Plugins: /usr/local/nagios/libexec/"
    echo

    print_info "Service Management:"
    print_info "  systemctl status nagios    # Check Nagios status"
    print_info "  systemctl restart nagios   # Restart Nagios"
    print_info "  systemctl status nrpe      # Check NRPE status"
    echo

    print_info "Configuration Files:"
    print_info "  Main config: /usr/local/nagios/etc/nagios.cfg"
    print_info "  Contacts: /usr/local/nagios/etc/objects/contacts.cfg"
    print_info "  Commands: /usr/local/nagios/etc/objects/commands.cfg"
    print_info "  NRPE config: /usr/local/nagios/etc/nrpe.cfg"
    print_info "  Custom hosts: /usr/local/nagios/etc/servers/"
    echo

    print_info "Testing NRPE:"
    print_info "  /usr/local/nagios/libexec/check_nrpe -H localhost"
    print_info "  /usr/local/nagios/libexec/check_nrpe -H localhost -c check_load"
    echo

    print_info "View Logs:"
    print_info "  tail -f /usr/local/nagios/var/nagios.log"
    print_info "  journalctl -u nagios -f"
    echo

    print_info "Next Steps:"
    print_info "  1. Access the web interface and log in"
    print_info "  2. Add monitored hosts in /usr/local/nagios/etc/servers/"
    print_info "  3. Reload Nagios: systemctl reload nagios"
    print_info "  4. Configure notifications in contacts.cfg"

    log_success "Nagios installation completed"
}

# Main installation flow
main() {
    install_prerequisites
    create_nagios_user
    install_nagios_core
    install_nagios_plugins
    install_nrpe
    configure_nagios
    configure_nrpe
    create_nagios_admin
    configure_webserver
    configure_selinux
    configure_firewall
    start_services

    # Cleanup
    cd /
    rm -rf "$BUILD_DIR"

    display_summary
}

# Run main
main
