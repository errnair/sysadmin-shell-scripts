#!/usr/bin/env bash
set -euo pipefail

#################################################
#                                               #
#     Install Salt Master configuration mgmt   #
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
SALT_VERSION="${SALT_VERSION:-latest}"  # latest, 3006, 3005, etc.
INSTALL_MINION="${INSTALL_MINION:-yes}"
INSTALL_CLOUD="${INSTALL_CLOUD:-no}"
INSTALL_SSH="${INSTALL_SSH:-yes}"

print_header "Salt Master Installer"

# Detect OS
OS=$(detect_os)
PKG_MGR=$(get_package_manager)

print_info "Detected OS: $OS"
print_info "Package manager: $PKG_MGR"
print_info "Salt version: $SALT_VERSION"
print_info "Install minion: $INSTALL_MINION"
print_info "Install salt-cloud: $INSTALL_CLOUD"
print_info "Install salt-ssh: $INSTALL_SSH"
echo

# Add Salt repository
add_salt_repository() {
    print_header "Adding Salt repository"

    case "$OS" in
        rhel)
            local rhel_major=$(rpm -E %{rhel})

            # Add SaltProject repository
            print_info "Adding SaltProject repository for RHEL ${rhel_major}..."

            if [ "$SALT_VERSION" = "latest" ]; then
                # Latest Salt version (3006.x LTS as of 2024)
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
            apt-get install -y wget curl gnupg

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

# Install Salt Master
install_salt_master() {
    print_header "Installing Salt Master"

    case "$OS" in
        rhel)
            $PKG_MGR install -y salt-master
            ;;
        debian)
            apt-get install -y salt-master
            ;;
    esac

    print_success "Salt Master installed"
}

# Install Salt Minion (optional)
install_salt_minion() {
    if [ "$INSTALL_MINION" != "yes" ]; then
        print_info "Skipping Salt Minion installation"
        return 0
    fi

    print_header "Installing Salt Minion"

    case "$OS" in
        rhel)
            $PKG_MGR install -y salt-minion
            ;;
        debian)
            apt-get install -y salt-minion
            ;;
    esac

    # Configure minion to connect to local master
    if [ ! -f /etc/salt/minion.d/local-master.conf ]; then
        mkdir -p /etc/salt/minion.d
        cat > /etc/salt/minion.d/local-master.conf <<EOF
# Connect to local Salt Master
master: localhost
EOF
        print_info "Minion configured to connect to localhost"
    fi

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

# Install Salt Cloud (optional)
install_salt_cloud() {
    if [ "$INSTALL_CLOUD" != "yes" ]; then
        print_info "Skipping Salt Cloud installation"
        return 0
    fi

    print_header "Installing Salt Cloud"

    case "$OS" in
        rhel)
            $PKG_MGR install -y salt-cloud
            ;;
        debian)
            apt-get install -y salt-cloud
            ;;
    esac

    print_success "Salt Cloud installed"
}

# Configure Salt Master
configure_salt_master() {
    print_header "Configuring Salt Master"

    # Create necessary directories
    mkdir -p /etc/salt/master.d
    mkdir -p /srv/salt
    mkdir -p /srv/pillar

    # Create basic master configuration
    if [ ! -f /etc/salt/master.d/basic.conf ]; then
        cat > /etc/salt/master.d/basic.conf <<EOF
# Basic Salt Master Configuration

# File server backend
file_roots:
  base:
    - /srv/salt

# Pillar configuration
pillar_roots:
  base:
    - /srv/pillar

# Auto accept minion keys (disable in production!)
auto_accept: False

# Keep job cache for 24 hours
keep_jobs: 24

# Worker threads
worker_threads: 5
EOF
        print_info "Created basic master configuration"
    fi

    # Create example state
    if [ ! -f /srv/salt/top.sls ]; then
        cat > /srv/salt/top.sls <<'EOF'
# Salt State Tree (top.sls)
# This file defines which states apply to which minions

base:
  '*':
    - common

# Example targeting by OS
#  'os:RedHat':
#    - match: grain
#    - redhat_specific
#
#  'os:Debian':
#    - match: grain
#    - debian_specific
EOF
        print_info "Created example top.sls"
    fi

    # Create example common state
    if [ ! -f /srv/salt/common.sls ]; then
        cat > /srv/salt/common.sls <<'EOF'
# Common state for all minions

# Install basic packages
common_packages:
  pkg.installed:
    - pkgs:
      - vim
      - curl
      - wget
      - htop

# Ensure SSH service is running
sshd:
  service.running:
    - enable: True
EOF
        print_info "Created example common.sls state"
    fi

    print_success "Salt Master configured"
}

# Configure firewall
configure_firewall() {
    print_header "Configuring firewall"

    if command_exists firewall-cmd; then
        # firewalld (RHEL-based)
        # Salt Master ports: 4505 (publish), 4506 (request)
        firewall-cmd --permanent --add-port=4505/tcp
        firewall-cmd --permanent --add-port=4506/tcp
        firewall-cmd --reload
        print_success "Firewall configured (firewalld)"
    elif command_exists ufw; then
        # ufw (Debian-based)
        ufw allow 4505/tcp
        ufw allow 4506/tcp
        print_success "Firewall configured (ufw)"
    else
        print_warning "No supported firewall found"
        print_info "Manually open ports 4505/tcp and 4506/tcp if using a firewall"
    fi
}

# Start services
start_services() {
    print_header "Starting services"

    # Enable and start Salt Master
    systemctl enable salt-master
    systemctl start salt-master

    # Enable and start Salt Minion if installed
    if [ "$INSTALL_MINION" = "yes" ]; then
        systemctl enable salt-minion
        systemctl start salt-minion

        # Wait for minion to start
        sleep 3

        # Accept minion key
        print_info "Accepting local minion key..."
        local minion_id=$(hostname -s)
        salt-key -y -a "$minion_id" 2>/dev/null || print_warning "Could not auto-accept minion key"
    fi

    print_success "Services started"
}

# Test Salt installation
test_salt() {
    print_header "Testing Salt installation"

    # Check master status
    if systemctl is-active --quiet salt-master; then
        print_success "Salt Master is running"
    else
        print_warning "Salt Master is not running"
    fi

    # Test salt command
    if command_exists salt; then
        local salt_version=$(salt --version | head -1)
        print_info "Salt version: $salt_version"
    fi

    # Test minion connectivity if installed
    if [ "$INSTALL_MINION" = "yes" ]; then
        sleep 2
        print_info "Testing minion connectivity..."
        if salt '*' test.ping --timeout=5 2>/dev/null | grep -q "True"; then
            print_success "Minion connectivity test passed"
        else
            print_warning "Minion connectivity test failed (may need to accept key manually)"
        fi
    fi
}

# Display summary
display_summary() {
    print_header "Installation Complete"

    local ip_addr=$(hostname -I | awk '{print $1}')

    print_success "Salt Master installed successfully!"
    echo

    print_info "Installation Details:"
    print_info "  Salt Master: Installed"
    [ "$INSTALL_MINION" = "yes" ] && print_info "  Salt Minion: Installed"
    [ "$INSTALL_SSH" = "yes" ] && print_info "  Salt SSH: Installed"
    [ "$INSTALL_CLOUD" = "yes" ] && print_info "  Salt Cloud: Installed"
    print_info "  Master IP: $ip_addr"
    print_info "  Ports: 4505 (publish), 4506 (request)"
    echo

    print_info "Configuration:"
    print_info "  Master config: /etc/salt/master"
    print_info "  Master config.d: /etc/salt/master.d/"
    print_info "  Salt states: /srv/salt/"
    print_info "  Pillar data: /srv/pillar/"
    echo

    print_info "Service Management:"
    print_info "  systemctl status salt-master   # Check master status"
    print_info "  systemctl restart salt-master  # Restart master"
    if [ "$INSTALL_MINION" = "yes" ]; then
        print_info "  systemctl status salt-minion   # Check minion status"
    fi
    echo

    print_info "Common Salt Commands:"
    print_info "  salt-key -L                    # List all keys"
    print_info "  salt-key -A                    # Accept all pending keys"
    print_info "  salt-key -a <minion-id>        # Accept specific key"
    print_info "  salt '*' test.ping             # Test connectivity to all minions"
    print_info "  salt '*' cmd.run 'uptime'      # Run command on all minions"
    print_info "  salt '*' state.apply           # Apply states to all minions"
    echo

    print_info "Configuration on Minions:"
    print_info "  1. Install salt-minion on target systems"
    print_info "  2. Configure master: $ip_addr in /etc/salt/minion"
    print_info "  3. Start minion: systemctl start salt-minion"
    print_info "  4. Accept key on master: salt-key -a <minion-id>"
    echo

    print_info "Next Steps:"
    print_info "  1. Create Salt states in /srv/salt/"
    print_info "  2. Deploy minions to managed systems"
    print_info "  3. Accept minion keys: salt-key -A"
    print_info "  4. Test connectivity: salt '*' test.ping"
    print_info "  5. Apply states: salt '*' state.apply"
    echo

    print_info "Documentation:"
    print_info "  https://docs.saltproject.io/"

    log_success "Salt Master installation completed"
}

# Main installation flow
main() {
    add_salt_repository
    install_salt_master
    install_salt_minion
    install_salt_ssh
    install_salt_cloud
    configure_salt_master
    configure_firewall
    start_services
    test_salt
    display_summary
}

# Run main
main
