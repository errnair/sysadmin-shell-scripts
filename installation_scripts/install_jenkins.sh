#!/usr/bin/env bash
set -euo pipefail

#################################################
#                                               #
#     Install Jenkins CI/CD automation server   #
#     Multi-OS support with Java 17             #
#                                               #
#################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Setup
trap cleanup_on_exit EXIT
require_root

# Configuration
JENKINS_VERSION="${JENKINS_VERSION:-lts}"  # lts or weekly
JENKINS_PORT="${JENKINS_PORT:-8080}"
JAVA_VERSION="${JAVA_VERSION:-17}"
INSTALL_PLUGINS="${INSTALL_PLUGINS:-yes}"

print_header "Jenkins CI/CD Server Installer"

# Detect OS
OS=$(detect_os)
PKG_MGR=$(get_package_manager)

print_info "Detected OS: $OS"
print_info "Package manager: $PKG_MGR"
print_info "Jenkins version: $JENKINS_VERSION"
print_info "Java version: $JAVA_VERSION"
print_info "Jenkins port: $JENKINS_PORT"
echo

# Check Java installation
check_java() {
    if command_exists java; then
        local java_ver=$(java -version 2>&1 | head -1 | awk -F '"' '{print $2}' | cut -d'.' -f1)
        print_info "Java is installed: version $java_ver"

        if [ "$java_ver" -ge 17 ]; then
            print_success "Java version meets Jenkins requirements (>= 17)"
            return 0
        else
            print_warning "Java version $java_ver is too old (Jenkins requires >= 17)"
            return 1
        fi
    else
        print_info "Java is not installed"
        return 1
    fi
}

# Install Java
install_java() {
    print_header "Installing Java ${JAVA_VERSION}"

    case "$OS" in
        rhel)
            case "$PKG_MGR" in
                dnf)
                    # Install Java 17 (default for RHEL 9+) or Java 11
                    dnf install -y java-${JAVA_VERSION}-openjdk java-${JAVA_VERSION}-openjdk-devel
                    ;;
                yum)
                    # Install Java 17 or 11
                    yum install -y java-${JAVA_VERSION}-openjdk java-${JAVA_VERSION}-openjdk-devel
                    ;;
            esac
            ;;
        debian)
            apt-get update
            apt-get install -y openjdk-${JAVA_VERSION}-jdk
            ;;
        *)
            error_exit "Unsupported OS: $OS"
            ;;
    esac

    # Verify installation
    if command_exists java; then
        local java_version=$(java -version 2>&1 | head -1)
        print_success "Java installed: $java_version"
    else
        error_exit "Java installation failed"
    fi
}

# Install Jenkins
install_jenkins() {
    print_header "Installing Jenkins"

    case "$OS" in
        rhel)
            # Add Jenkins repository
            print_info "Adding Jenkins repository..."

            if [ "$JENKINS_VERSION" = "lts" ]; then
                # LTS repository
                cat > /etc/yum.repos.d/jenkins.repo <<'EOF'
[jenkins]
name=Jenkins-stable
baseurl=http://pkg.jenkins.io/redhat-stable
gpgcheck=1
gpgkey=https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
EOF
            else
                # Weekly repository
                cat > /etc/yum.repos.d/jenkins.repo <<'EOF'
[jenkins]
name=Jenkins
baseurl=http://pkg.jenkins.io/redhat
gpgcheck=1
gpgkey=https://pkg.jenkins.io/redhat/jenkins.io-2023.key
EOF
            fi

            # Install Jenkins
            $PKG_MGR install -y jenkins

            ;;
        debian)
            # Add Jenkins repository
            print_info "Adding Jenkins repository..."

            # Install dependencies
            apt-get install -y wget gnupg2

            # Add Jenkins key
            wget -q -O /usr/share/keyrings/jenkins-keyring.asc \
                https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

            if [ "$JENKINS_VERSION" = "lts" ]; then
                # LTS repository
                echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
                    > /etc/apt/sources.list.d/jenkins.list
            else
                # Weekly repository
                echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/" \
                    > /etc/apt/sources.list.d/jenkins.list
            fi

            # Update and install
            apt-get update
            apt-get install -y jenkins

            ;;
        *)
            error_exit "Unsupported OS: $OS"
            ;;
    esac

    print_success "Jenkins package installed"
}

# Configure Jenkins port
configure_jenkins_port() {
    if [ "$JENKINS_PORT" = "8080" ]; then
        return 0
    fi

    print_header "Configuring Jenkins port"

    # Modify Jenkins configuration
    local jenkins_config=""

    if [ -f /etc/sysconfig/jenkins ]; then
        # RHEL-based
        jenkins_config="/etc/sysconfig/jenkins"
        sed -i "s/JENKINS_PORT=\"8080\"/JENKINS_PORT=\"$JENKINS_PORT\"/" "$jenkins_config"
    elif [ -f /etc/default/jenkins ]; then
        # Debian-based
        jenkins_config="/etc/default/jenkins"
        sed -i "s/HTTP_PORT=8080/HTTP_PORT=$JENKINS_PORT/" "$jenkins_config"
    fi

    print_success "Jenkins configured to use port $JENKINS_PORT"
}

# Configure firewall
configure_firewall() {
    print_header "Configuring firewall"

    if command_exists firewall-cmd; then
        # firewalld (RHEL-based)
        firewall-cmd --permanent --add-port=${JENKINS_PORT}/tcp
        firewall-cmd --reload
        print_success "Firewall configured (firewalld) - port ${JENKINS_PORT}/tcp"
    elif command_exists ufw; then
        # ufw (Debian-based)
        ufw allow ${JENKINS_PORT}/tcp
        print_success "Firewall configured (ufw) - port ${JENKINS_PORT}/tcp"
    else
        print_warning "No supported firewall found"
        print_info "Manually open port ${JENKINS_PORT}/tcp if using a firewall"
    fi
}

# Start Jenkins service
start_jenkins() {
    print_header "Starting Jenkins service"

    systemctl daemon-reload
    systemctl enable jenkins
    systemctl start jenkins

    # Wait for Jenkins to start
    print_info "Waiting for Jenkins to start (this may take 30-60 seconds)..."

    local max_attempts=30
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if systemctl is-active --quiet jenkins; then
            if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
                print_success "Jenkins started successfully"
                return 0
            fi
        fi

        sleep 2
        attempt=$((attempt + 1))
        echo -n "."
    done

    echo
    print_warning "Jenkins may still be starting. Check status with: systemctl status jenkins"
}

# Get initial admin password
get_initial_password() {
    local password_file="/var/lib/jenkins/secrets/initialAdminPassword"

    if [ -f "$password_file" ]; then
        local password=$(cat "$password_file")
        return 0
    else
        print_warning "Initial admin password file not found yet"
        return 1
    fi
}

# Install recommended plugins (CLI method)
install_recommended_plugins() {
    if [ "$INSTALL_PLUGINS" != "yes" ]; then
        return 0
    fi

    print_header "Installing recommended plugins"

    print_info "Waiting for Jenkins to be fully ready..."
    sleep 10

    # Install Jenkins CLI
    local jenkins_url="http://localhost:${JENKINS_PORT}"
    local jenkins_cli="/var/lib/jenkins/jenkins-cli.jar"

    if [ ! -f "$jenkins_cli" ]; then
        wget -q "${jenkins_url}/jnlpJars/jenkins-cli.jar" -O "$jenkins_cli" || {
            print_warning "Could not download Jenkins CLI. Install plugins manually via web interface."
            return 0
        }
    fi

    print_info "Jenkins plugins can be installed via the web interface after initial setup"
}

# Display post-installation information
display_summary() {
    print_header "Installation Complete"

    local ip_addr=$(hostname -I | awk '{print $1}')
    local jenkins_url="http://${ip_addr}:${JENKINS_PORT}"

    print_success "Jenkins installed successfully!"
    echo

    print_info "Access Information:"
    print_info "  URL: $jenkins_url"
    print_info "  Port: $JENKINS_PORT"
    echo

    # Get initial password
    local password_file="/var/lib/jenkins/secrets/initialAdminPassword"
    if [ -f "$password_file" ]; then
        local initial_password=$(cat "$password_file")
        print_info "Initial Admin Password:"
        print_info "  $initial_password"
        echo
        print_info "Password file location:"
        print_info "  $password_file"
    else
        print_warning "Initial password not available yet"
        print_info "Check password file when Jenkins is fully started:"
        print_info "  cat $password_file"
    fi

    echo
    print_info "Service Management:"
    print_info "  systemctl status jenkins   # Check service status"
    print_info "  systemctl restart jenkins  # Restart Jenkins"
    print_info "  systemctl stop jenkins     # Stop Jenkins"
    echo

    print_info "Configuration:"
    print_info "  Home directory: /var/lib/jenkins"
    print_info "  Configuration: /etc/sysconfig/jenkins (RHEL) or /etc/default/jenkins (Debian)"
    print_info "  Logs: /var/log/jenkins/jenkins.log"
    echo

    print_info "View Logs:"
    print_info "  tail -f /var/log/jenkins/jenkins.log"
    print_info "  journalctl -u jenkins -f"
    echo

    print_info "Next Steps:"
    print_info "  1. Navigate to $jenkins_url"
    print_info "  2. Enter the initial admin password shown above"
    print_info "  3. Install suggested plugins or select plugins to install"
    print_info "  4. Create your first admin user"
    print_info "  5. Configure Jenkins instance settings"
    echo

    print_info "Useful Jenkins CLI commands:"
    print_info "  java -jar /var/lib/jenkins/jenkins-cli.jar -s $jenkins_url help"

    log_success "Jenkins installation completed"
}

# Main installation flow
main() {
    # Check and install Java if needed
    if ! check_java; then
        if confirm "Install Java ${JAVA_VERSION}?" "yes"; then
            install_java
        else
            error_exit "Jenkins requires Java 17 or higher"
        fi
    fi

    # Install Jenkins
    install_jenkins

    # Configure Jenkins
    configure_jenkins_port

    # Configure firewall
    configure_firewall

    # Start Jenkins
    start_jenkins

    # Install plugins (optional)
    install_recommended_plugins

    # Display summary
    display_summary
}

# Run main
main
