#!/usr/bin/env bash
set -euo pipefail

#################################################
#                                               #
#     Install Salt Minion agent                #
#     Multi-OS support with modern repos        #
#                                               #
#################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Setup
trap cleanup_on_exit EXIT
require_root

# Configuration
SALT_MASTER="${1:-}"
SALT_VERSION="${SALT_VERSION:-latest}"  # latest, 3006, 3005, etc.
MINION_ID="${MINION_ID:-$(hostname -f)}"
INSTALL_SSH="${INSTALL_SSH:-no}"

print_header "Salt Minion Installer"

# Detect OS
OS=$(detect_os)
PKG_MGR=$(get_package_manager)

print_info "Detected OS: $OS"
print_info "Package manager: $PKG_MGR"
print_info "Salt version: $SALT_VERSION"
print_info "Install salt-ssh: $INSTALL_SSH"
echo

# Validate master parameter
validate_master() {
    if [[ -z "$SALT_MASTER" ]]; then
        error_exit "Usage: $0 <salt-master-ip-or-hostname> [options]

Examples:
  $0 192.168.1.100                      # Connect to master IP
  $0 salt.example.com                   # Connect to master hostname
  SALT_VERSION=3006 $0 192.168.1.100    # Specific Salt version
  MINION_ID=webserver01 $0 salt.master  # Custom minion ID"
    fi

    # Validate master is IP or hostname
    if ! validate_ip "$SALT_MASTER" && ! validate_domain "$SALT_MASTER"; then
        if ! validate_hostname "$SALT_MASTER"; then
            error_exit "Invalid master address: $SALT_MASTER (must be IP, hostname, or FQDN)"
        fi
    fi

    print_info "Salt Master: $SALT_MASTER"
    print_info "Minion ID: $MINION_ID"
    echo
}

# Validate hostname (simple check)
validate_hostname() {
    local hostname="$1"
    [[ "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]
}

# Add Salt repository
add_salt_repository() {
    print_header "Adding Salt repository"

    case "$OS" in
        rhel)
            local rhel_major=$(rpm -E %{rhel})

            # Add SaltProject repository
            print_info "Adding SaltProject repository for RHEL ${rhel_major}..."

            if [ "$SALT_VERSION" = "latest" ]; then
                # Latest Salt version
                cat > /etc/yum.repos.d/salt.repo <<EOF
[salt-repo]
name=Salt repo for RHEL/CentOS ${rhel_major}
baseurl=https://repo.saltproject.io/salt/py3/redhat/${rhel_major}/\$basearch/latest
enabled=1
gpgcheck=1
gpgkey=https://repo.saltproject.io/salt/py3/redhat/${rhel_major}/\$basearch/latest/SALTSTACK-GPG-KEY.pub
EOF
            else
                # Specific version
                cat > /etc/yum.repos.d/salt.repo <<EOF
[salt-repo]
name=Salt repo for RHEL/CentOS ${rhel_major} - ${SALT_VERSION}
baseurl=https://repo.saltproject.io/salt/py3/redhat/${rhel_major}/\$basearch/${SALT_VERSION}
enabled=1
gpgcheck=1
gpgkey=https://repo.saltproject.io/salt/py3/redhat/${rhel_major}/\$basearch/${SALT_VERSION}/SALTSTACK-GPG-KEY.pub
EOF
            fi
            ;;

        debian)
            print_info "Adding SaltProject repository for Debian/Ubuntu..."

            # Install dependencies
            apt-get update
            apt-get install -y wget curl gnupg lsb-release

            # Detect Debian/Ubuntu version
            local os_codename=$(lsb_release -sc)

            if [ "$SALT_VERSION" = "latest" ]; then
                # Add GPG key
                mkdir -p /usr/share/keyrings
                curl -fsSL https://repo.saltproject.io/salt/py3/ubuntu/$(lsb_release -rs)/amd64/latest/SALTSTACK-GPG-KEY.pub | \
                    gpg --dearmor -o /usr/share/keyrings/salt-archive-keyring.gpg

                # Add repository
                echo "deb [signed-by=/usr/share/keyrings/salt-archive-keyring.gpg arch=amd64] https://repo.saltproject.io/salt/py3/ubuntu/$(lsb_release -rs)/amd64/latest $os_codename main" | \
                    tee /etc/apt/sources.list.d/salt.list
            else
                # Specific version
                mkdir -p /usr/share/keyrings
                curl -fsSL https://repo.saltproject.io/salt/py3/ubuntu/$(lsb_release -rs)/amd64/${SALT_VERSION}/SALTSTACK-GPG-KEY.pub | \
                    gpg --dearmor -o /usr/share/keyrings/salt-archive-keyring.gpg

                echo "deb [signed-by=/usr/share/keyrings/salt-archive-keyring.gpg arch=amd64] https://repo.saltproject.io/salt/py3/ubuntu/$(lsb_release -rs)/amd64/${SALT_VERSION} $os_codename main" | \
                    tee /etc/apt/sources.list.d/salt.list
            fi

            apt-get update
            ;;

        *)
            error_exit "Unsupported OS: $OS"
            ;;
    esac

    print_success "Salt repository added"
}

# Install Salt Minion
install_salt_minion() {
    print_header "Installing Salt Minion"

    case "$OS" in
        rhel)
            $PKG_MGR install -y salt-minion
            ;;
        debian)
            apt-get install -y salt-minion
            ;;
    esac

    print_success "Salt Minion installed"
}

# Install Salt SSH (optional)
install_salt_ssh() {
    if [ "$INSTALL_SSH" != "yes" ]; then
        print_info "Skipping Salt SSH installation"
        return 0
    fi

    print_header "Installing Salt SSH"

    case "$OS" in
        rhel)
            $PKG_MGR install -y salt-ssh
            ;;
        debian)
            apt-get install -y salt-ssh
            ;;
    esac

    print_success "Salt SSH installed"
}

# Configure Salt Minion
configure_salt_minion() {
    print_header "Configuring Salt Minion"

    # Create minion.d directory
    mkdir -p /etc/salt/minion.d

    # Create master configuration
    cat > /etc/salt/minion.d/master.conf <<EOF
# Salt Master Configuration
master: $SALT_MASTER
EOF

    # Create minion ID configuration
    cat > /etc/salt/minion.d/minion_id.conf <<EOF
# Minion ID Configuration
id: $MINION_ID
EOF

    # Create additional basic configuration
    cat > /etc/salt/minion.d/basic.conf <<EOF
# Basic Minion Configuration

# Minion startup states
startup_states: ''

# File client
file_client: remote

# Log level
log_level: warning

# Keep minion running
loop_interval: 60
EOF

    print_info "Master: $SALT_MASTER"
    print_info "Minion ID: $MINION_ID"
    print_success "Salt Minion configured"
}

# Configure firewall
configure_firewall() {
    print_header "Configuring firewall"

    if command_exists firewall-cmd; then
        # firewalld (RHEL-based)
        # Minion only needs outbound connections, but open 4506 for potential push operations
        firewall-cmd --permanent --add-port=4506/tcp
        firewall-cmd --reload
        print_success "Firewall configured (firewalld)"
    elif command_exists ufw; then
        # ufw (Debian-based)
        ufw allow 4506/tcp
        print_success "Firewall configured (ufw)"
    else
        print_info "No firewall configuration needed (minion uses outbound connections)"
    fi
}

# Start service
start_service() {
    print_header "Starting Salt Minion service"

    # Enable and start Salt Minion
    systemctl enable salt-minion
    systemctl start salt-minion

    # Wait for service to start
    sleep 2

    if systemctl is-active --quiet salt-minion; then
        print_success "Salt Minion started successfully"
    else
        error_exit "Salt Minion failed to start"
    fi
}

# Test minion
test_minion() {
    print_header "Testing Salt Minion"

    # Check service status
    if systemctl is-active --quiet salt-minion; then
        print_success "Salt Minion is running"
    else
        print_warning "Salt Minion is not running"
        return 1
    fi

    # Display minion version
    if command_exists salt-minion; then
        local minion_version=$(salt-minion --version | head -1)
        print_info "Salt Minion version: $minion_version"
    fi

    # Check connection to master
    print_info "Checking connection to master..."
    local log_file="/var/log/salt/minion"

    if [ -f "$log_file" ]; then
        sleep 3
        if grep -q "Authentication accepted" "$log_file" 2>/dev/null; then
            print_success "Minion authenticated with master"
        else
            print_info "Waiting for master to accept minion key"
            print_info "On the master, run: salt-key -a $MINION_ID"
        fi
    fi
}

# Display summary
display_summary() {
    print_header "Installation Complete"

    print_success "Salt Minion installed successfully!"
    echo

    print_info "Configuration:"
    print_info "  Minion ID: $MINION_ID"
    print_info "  Salt Master: $SALT_MASTER"
    print_info "  Minion config: /etc/salt/minion"
    print_info "  Minion config.d: /etc/salt/minion.d/"
    print_info "  Log file: /var/log/salt/minion"
    echo

    print_info "Service Management:"
    print_info "  systemctl status salt-minion   # Check service status"
    print_info "  systemctl restart salt-minion  # Restart service"
    print_info "  systemctl stop salt-minion     # Stop service"
    echo

    print_info "View Logs:"
    print_info "  tail -f /var/log/salt/minion"
    print_info "  journalctl -u salt-minion -f"
    echo

    print_info "On Salt Master ($SALT_MASTER):"
    print_info "  salt-key -L                    # List all minion keys"
    print_info "  salt-key -a $MINION_ID         # Accept this minion's key"
    print_info "  salt-key -A                    # Accept all pending keys"
    print_info "  salt '$MINION_ID' test.ping    # Test connectivity"
    print_info "  salt '$MINION_ID' state.apply  # Apply states"
    echo

    print_info "Troubleshooting:"
    print_info "  1. Ensure master is reachable: ping $SALT_MASTER"
    print_info "  2. Check firewall allows ports 4505 and 4506"
    print_info "  3. Verify minion key on master: salt-key -L"
    print_info "  4. Check minion logs: tail -f /var/log/salt/minion"
    echo

    print_info "Next Steps:"
    print_info "  1. Accept this minion's key on the master"
    print_info "  2. Test connectivity: salt '$MINION_ID' test.ping"
    print_info "  3. Apply states from master"

    log_success "Salt Minion installation completed"
}

# Main installation flow
main() {
    validate_master
    add_salt_repository
    install_salt_minion
    install_salt_ssh
    configure_salt_minion
    configure_firewall
    start_service
    test_minion
    display_summary
}

# Run main
main
