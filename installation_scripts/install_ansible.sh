#!/usr/bin/env bash
set -euo pipefail

#################################################
#                                               #
#     Install Ansible automation platform       #
#     Multi-OS support with version selection   #
#                                               #
#################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Setup
trap cleanup_on_exit EXIT
require_root

# Configuration
ANSIBLE_VERSION="${1:-latest}"
INSTALL_METHOD="${INSTALL_METHOD:-package}"  # package or pip
INSTALL_TYPE="${INSTALL_TYPE:-full}"  # full (ansible) or core (ansible-core)

print_header "Ansible Installer"

print_info "Ansible version: ${ANSIBLE_VERSION}"
print_info "Installation method: ${INSTALL_METHOD}"
print_info "Installation type: ${INSTALL_TYPE}"
echo

# Detect OS
OS=$(detect_os)
PKG_MGR=$(get_package_manager)

print_info "Detected OS: $OS"
print_info "Package manager: $PKG_MGR"
echo

# Check if Ansible is already installed
check_existing_ansible() {
    if command_exists ansible; then
        local current_version=$(ansible --version | head -1 | awk '{print $2}' | tr -d '[]')
        print_info "Ansible is already installed: $current_version"

        if confirm "Ansible is already installed. Continue anyway?" "no"; then
            return 1
        else
            return 0
        fi
    fi
    return 1
}

# Install Ansible from package manager
install_from_package() {
    print_header "Installing Ansible from system packages"

    case "$OS" in
        rhel)
            # Enable EPEL repository
            print_info "Enabling EPEL repository..."
            case "$PKG_MGR" in
                dnf)
                    dnf install -y epel-release
                    dnf update -y

                    if [ "$INSTALL_TYPE" = "core" ]; then
                        print_info "Installing ansible-core..."
                        dnf install -y ansible-core
                    else
                        print_info "Installing full ansible package..."
                        dnf install -y ansible
                    fi
                    ;;
                yum)
                    yum install -y epel-release
                    yum update -y

                    if [ "$INSTALL_TYPE" = "core" ]; then
                        print_info "Installing ansible-core..."
                        yum install -y ansible-core
                    else
                        print_info "Installing full ansible package..."
                        yum install -y ansible
                    fi
                    ;;
            esac
            ;;
        debian)
            print_info "Adding Ansible PPA repository..."
            apt-get update
            apt-get install -y software-properties-common
            add-apt-repository --yes --update ppa:ansible/ansible

            if [ "$INSTALL_TYPE" = "core" ]; then
                print_info "Installing ansible-core..."
                apt-get install -y ansible-core
            else
                print_info "Installing full ansible package..."
                apt-get install -y ansible
            fi
            ;;
        *)
            error_exit "Unsupported OS: $OS"
            ;;
    esac

    print_success "Ansible installed from system packages"
}

# Install Ansible via pip
install_from_pip() {
    print_header "Installing Ansible via pip"

    # Ensure Python 3 and pip are available
    if ! command_exists python3; then
        print_info "Python 3 not found, installing..."
        case "$PKG_MGR" in
            dnf|yum)
                $PKG_MGR install -y python3 python3-pip
                ;;
            apt)
                apt-get update
                apt-get install -y python3 python3-pip
                ;;
        esac
    fi

    # Upgrade pip
    python3 -m pip install --upgrade pip

    # Install Ansible
    if [ "$ANSIBLE_VERSION" = "latest" ]; then
        if [ "$INSTALL_TYPE" = "core" ]; then
            print_info "Installing latest ansible-core..."
            python3 -m pip install ansible-core
        else
            print_info "Installing latest ansible..."
            python3 -m pip install ansible
        fi
    else
        if [ "$INSTALL_TYPE" = "core" ]; then
            print_info "Installing ansible-core ${ANSIBLE_VERSION}..."
            python3 -m pip install "ansible-core==${ANSIBLE_VERSION}"
        else
            print_info "Installing ansible ${ANSIBLE_VERSION}..."
            python3 -m pip install "ansible==${ANSIBLE_VERSION}"
        fi
    fi

    print_success "Ansible installed via pip"
}

# Configure Ansible
configure_ansible() {
    print_header "Configuring Ansible"

    # Create Ansible directories
    mkdir -p /etc/ansible
    mkdir -p /etc/ansible/inventory
    mkdir -p /etc/ansible/group_vars
    mkdir -p /etc/ansible/host_vars

    # Create ansible.cfg if it doesn't exist
    if [ ! -f /etc/ansible/ansible.cfg ]; then
        print_info "Creating /etc/ansible/ansible.cfg..."
        cat > /etc/ansible/ansible.cfg <<'EOF'
[defaults]
inventory = /etc/ansible/inventory
remote_user = root
host_key_checking = False
retry_files_enabled = False
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 86400
stdout_callback = yaml
callbacks_enabled = timer, profile_tasks

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
EOF
        print_success "Created /etc/ansible/ansible.cfg"
    else
        print_info "/etc/ansible/ansible.cfg already exists"
    fi

    # Create default inventory if it doesn't exist
    if [ ! -f /etc/ansible/inventory/hosts ]; then
        print_info "Creating /etc/ansible/inventory/hosts..."
        cat > /etc/ansible/inventory/hosts <<'EOF'
# Ansible inventory file
# Add your hosts here

[local]
localhost ansible_connection=local

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
        print_success "Created /etc/ansible/inventory/hosts"
    else
        print_info "/etc/ansible/inventory/hosts already exists"
    fi

    print_success "Ansible configuration complete"
}

# Install common collections (optional)
install_collections() {
    if ! confirm "Install common Ansible collections?" "yes"; then
        return 0
    fi

    print_header "Installing Ansible Collections"

    local collections=(
        "community.general"
        "ansible.posix"
        "community.docker"
    )

    for collection in "${collections[@]}"; do
        print_info "Installing collection: $collection"
        ansible-galaxy collection install "$collection" || print_warning "Failed to install $collection"
    done

    print_success "Collections installation complete"
}

# Main installation logic
main() {
    # Check if already installed
    if check_existing_ansible; then
        print_info "Keeping existing installation"
        exit 0
    fi

    # Install Ansible
    if [ "$INSTALL_METHOD" = "pip" ]; then
        install_from_pip
    else
        install_from_package
    fi

    # Configure Ansible
    configure_ansible

    # Install collections
    install_collections

    # Verify installation
    print_header "Verification"

    local installed_version=$(ansible --version | head -1)
    print_success "$installed_version"

    local ansible_path=$(which ansible)
    print_info "Ansible path: $ansible_path"

    local python_version=$(ansible --version | grep "python version" | awk '{print $3}')
    print_info "Python version: $python_version"

    echo
    print_success "Ansible installation complete!"
    echo
    print_info "Test with: ansible --version"
    print_info "Ping localhost: ansible localhost -m ping"
    print_info "Configuration: /etc/ansible/ansible.cfg"
    print_info "Inventory: /etc/ansible/inventory/hosts"

    log_success "Ansible installed successfully"
}

# Run main
main
