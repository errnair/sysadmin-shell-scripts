#!/usr/bin/env bash
set -euo pipefail

#################################################
#                                               #
#     Change system hostname                    #
#     Multi-OS support with validation          #
#                                               #
#################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Setup
trap cleanup_on_exit EXIT
require_root

# Configuration
NEW_HOSTNAME="${1:-}"
UPDATE_HOSTS="${UPDATE_HOSTS:-yes}"
RESTART_NETWORK="${RESTART_NETWORK:-no}"
BACKUP_CONFIG="${BACKUP_CONFIG:-yes}"

print_header "Hostname Change Utility"

# Detect OS
OS=$(detect_os)
PKG_MGR=$(get_package_manager)

print_info "Detected OS: $OS"
echo

# Validate hostname parameter
validate_hostname_param() {
    if [[ -z "$NEW_HOSTNAME" ]]; then
        error_exit "Usage: $0 <new-hostname> [options]

Examples:
  $0 webserver01                      # Change hostname
  UPDATE_HOSTS=no $0 db-server        # Don't update /etc/hosts
  RESTART_NETWORK=yes $0 app-server   # Restart network services

Options (environment variables):
  UPDATE_HOSTS=yes|no        # Update /etc/hosts (default: yes)
  RESTART_NETWORK=yes|no     # Restart network (default: no)
  BACKUP_CONFIG=yes|no       # Backup config files (default: yes)"
    fi

    print_info "New hostname: $NEW_HOSTNAME"
}

# Validate hostname format (RFC 1123)
validate_hostname_format() {
    print_header "Validating hostname format"

    # RFC 1123 hostname rules:
    # - 1-253 characters
    # - Labels separated by dots
    # - Each label: 1-63 characters
    # - Characters: a-z, A-Z, 0-9, hyphen (not at start/end)
    # - Case insensitive

    local hostname_regex='^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)*[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$'

    if [[ ! "$NEW_HOSTNAME" =~ $hostname_regex ]]; then
        error_exit "Invalid hostname format: $NEW_HOSTNAME

RFC 1123 hostname rules:
  - Only alphanumeric characters and hyphens
  - Cannot start or end with a hyphen
  - Maximum 253 characters
  - Labels (parts between dots) max 63 characters
  - Cannot be just numbers

Valid examples:
  - webserver01
  - web-server-01
  - app.example.com
  - db-01.internal.example.com"
    fi

    # Check length
    if [ ${#NEW_HOSTNAME} -gt 253 ]; then
        error_exit "Hostname too long: ${#NEW_HOSTNAME} characters (max: 253)"
    fi

    # Check if hostname is all numbers
    if [[ "$NEW_HOSTNAME" =~ ^[0-9]+$ ]]; then
        error_exit "Hostname cannot be only numbers"
    fi

    print_success "Hostname format is valid"
}

# Detect cloud provider
detect_cloud_provider() {
    local cloud="none"

    # AWS
    if curl -s --max-time 2 http://169.254.169.254/latest/meta-data/instance-id &>/dev/null; then
        cloud="aws"
    # Azure
    elif curl -s --max-time 2 -H "Metadata:true" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" &>/dev/null; then
        cloud="azure"
    # GCP
    elif curl -s --max-time 2 -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/id &>/dev/null; then
        cloud="gcp"
    fi

    echo "$cloud"
}

# Get current hostname
get_current_hostname() {
    if command_exists hostnamectl; then
        hostnamectl status | grep "Static hostname" | awk '{print $3}'
    else
        hostname
    fi
}

# Backup configuration files
backup_configs() {
    if [ "$BACKUP_CONFIG" != "yes" ]; then
        return 0
    fi

    print_header "Backing up configuration files"

    local backup_dir="/root/hostname_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    # Backup /etc/hostname if it exists
    if [ -f /etc/hostname ]; then
        cp /etc/hostname "$backup_dir/"
        print_info "Backed up /etc/hostname"
    fi

    # Backup /etc/hosts
    if [ -f /etc/hosts ]; then
        cp /etc/hosts "$backup_dir/"
        print_info "Backed up /etc/hosts"
    fi

    # Backup /etc/sysconfig/network if it exists (RHEL 6/7)
    if [ -f /etc/sysconfig/network ]; then
        cp /etc/sysconfig/network "$backup_dir/"
        print_info "Backed up /etc/sysconfig/network"
    fi

    print_success "Configuration files backed up to: $backup_dir"
}

# Change hostname using hostnamectl (systemd)
change_hostname_hostnamectl() {
    print_header "Changing hostname using hostnamectl"

    # Set hostname
    hostnamectl set-hostname "$NEW_HOSTNAME"

    print_success "Hostname set to: $NEW_HOSTNAME"
}

# Change hostname manually (for older systems)
change_hostname_manual() {
    print_header "Changing hostname manually"

    case "$OS" in
        rhel)
            # Update /etc/hostname
            echo "$NEW_HOSTNAME" > /etc/hostname

            # Update /etc/sysconfig/network (RHEL 6/7)
            if [ -f /etc/sysconfig/network ]; then
                if grep -q "^HOSTNAME=" /etc/sysconfig/network; then
                    sed -i "s/^HOSTNAME=.*/HOSTNAME=$NEW_HOSTNAME/" /etc/sysconfig/network
                else
                    echo "HOSTNAME=$NEW_HOSTNAME" >> /etc/sysconfig/network
                fi
            fi

            # Set hostname for current session
            hostname "$NEW_HOSTNAME"
            ;;

        debian)
            # Update /etc/hostname
            echo "$NEW_HOSTNAME" > /etc/hostname

            # Set hostname for current session
            hostname "$NEW_HOSTNAME"
            ;;

        *)
            error_exit "Unsupported OS: $OS"
            ;;
    esac

    print_success "Hostname set to: $NEW_HOSTNAME"
}

# Update /etc/hosts
update_hosts_file() {
    if [ "$UPDATE_HOSTS" != "yes" ]; then
        print_info "Skipping /etc/hosts update"
        return 0
    fi

    print_header "Updating /etc/hosts"

    local OLD_HOSTNAME="$1"
    local hosts_file="/etc/hosts"

    # Get primary IP address
    local primary_ip=$(ip -4 addr show | grep "inet" | grep -v "127.0.0.1" | head -1 | awk '{print $2}' | cut -d/ -f1)

    if [ -z "$primary_ip" ]; then
        primary_ip="127.0.1.1"
    fi

    # Remove old hostname entries (but keep localhost)
    if [ -n "$OLD_HOSTNAME" ] && [ "$OLD_HOSTNAME" != "localhost" ]; then
        sed -i "/[[:space:]]${OLD_HOSTNAME}[[:space:]]*$/d" "$hosts_file"
        sed -i "/[[:space:]]${OLD_HOSTNAME}$/d" "$hosts_file"
    fi

    # Add new hostname entry if not present
    if ! grep -q "[[:space:]]${NEW_HOSTNAME}[[:space:]]*$\|[[:space:]]${NEW_HOSTNAME}$" "$hosts_file"; then
        # Extract short hostname (without domain)
        local short_hostname=$(echo "$NEW_HOSTNAME" | cut -d. -f1)

        if [[ "$NEW_HOSTNAME" == *.* ]]; then
            # FQDN - add both FQDN and short name
            echo "$primary_ip    $NEW_HOSTNAME $short_hostname" >> "$hosts_file"
        else
            # Short name only
            echo "$primary_ip    $NEW_HOSTNAME" >> "$hosts_file"
        fi

        print_success "Updated /etc/hosts with new hostname"
    else
        print_info "/etc/hosts already contains new hostname"
    fi
}

# Restart network services
restart_network_services() {
    if [ "$RESTART_NETWORK" != "yes" ]; then
        print_info "Skipping network service restart"
        print_warning "You may need to log out and log back in to see hostname changes"
        return 0
    fi

    print_header "Restarting network services"

    case "$OS" in
        rhel)
            local rhel_major=$(rpm -E %{rhel})

            if [ "$rhel_major" -ge 8 ]; then
                # RHEL 8+ uses NetworkManager
                if systemctl is-active --quiet NetworkManager; then
                    systemctl restart NetworkManager
                    print_success "NetworkManager restarted"
                fi
            else
                # RHEL 7
                if systemctl is-active --quiet NetworkManager; then
                    systemctl restart NetworkManager
                    print_success "NetworkManager restarted"
                fi
                if systemctl is-active --quiet network; then
                    systemctl restart network
                    print_success "Network service restarted"
                fi
            fi
            ;;

        debian)
            if systemctl is-active --quiet NetworkManager; then
                systemctl restart NetworkManager
                print_success "NetworkManager restarted"
            elif systemctl is-active --quiet networking; then
                systemctl restart networking
                print_success "Networking service restarted"
            fi
            ;;
    esac

    print_warning "Network restart complete. SSH connections may have been interrupted."
}

# Cloud provider specific handling
handle_cloud_provider() {
    local cloud="$1"

    if [ "$cloud" = "none" ]; then
        return 0
    fi

    print_header "Cloud Provider: $cloud"

    case "$cloud" in
        aws)
            print_warning "Running on AWS EC2"
            print_info "Note: AWS may reset hostname on reboot unless:"
            print_info "  1. Set 'preserve_hostname: true' in /etc/cloud/cloud.cfg"
            print_info "  2. Or disable cloud-init network config"
            ;;

        azure)
            print_warning "Running on Azure VM"
            print_info "Note: Azure may reset hostname on reboot unless:"
            print_info "  1. Set 'preserve_hostname: true' in /etc/cloud/cloud.cfg"
            print_info "  2. Or use Azure VM custom script extension"
            ;;

        gcp)
            print_warning "Running on Google Cloud Platform"
            print_info "Note: GCP may reset hostname on reboot unless:"
            print_info "  1. Set 'preserve_hostname: true' in /etc/cloud/cloud.cfg"
            ;;
    esac

    # Update cloud-init config if it exists
    if [ -f /etc/cloud/cloud.cfg ]; then
        if ! grep -q "preserve_hostname: true" /etc/cloud/cloud.cfg; then
            print_info "Updating cloud-init configuration..."
            echo "" >> /etc/cloud/cloud.cfg
            echo "# Preserve hostname set by administrator" >> /etc/cloud/cloud.cfg
            echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg
            print_success "Added 'preserve_hostname: true' to /etc/cloud/cloud.cfg"
        fi
    fi
}

# Verify hostname change
verify_hostname() {
    print_header "Verifying hostname change"

    local current=$(get_current_hostname)

    if [ "$current" = "$NEW_HOSTNAME" ]; then
        print_success "Hostname successfully changed to: $NEW_HOSTNAME"
        return 0
    else
        print_warning "Hostname verification:"
        print_warning "  Expected: $NEW_HOSTNAME"
        print_warning "  Current: $current"
        print_info "You may need to log out and log back in to see the change"
    fi
}

# Display summary
display_summary() {
    print_header "Hostname Change Complete"

    local OLD_HOSTNAME="$1"
    local current=$(get_current_hostname)

    print_success "Hostname changed successfully!"
    echo

    print_info "Summary:"
    print_info "  Old hostname: $OLD_HOSTNAME"
    print_info "  New hostname: $NEW_HOSTNAME"
    print_info "  Current hostname: $current"
    echo

    print_info "Configuration files updated:"
    [ -f /etc/hostname ] && print_info "  - /etc/hostname"
    [ "$UPDATE_HOSTS" = "yes" ] && print_info "  - /etc/hosts"
    [ -f /etc/sysconfig/network ] && print_info "  - /etc/sysconfig/network"
    echo

    print_info "Next steps:"
    print_info "  1. Log out and log back in to see hostname in shell prompt"
    print_info "  2. Verify with: hostnamectl status"
    print_info "  3. Check /etc/hosts has correct entries"

    if [ "$RESTART_NETWORK" != "yes" ]; then
        print_info "  4. Consider restarting or rebooting for full effect"
    fi

    log_success "Hostname changed from $OLD_HOSTNAME to $NEW_HOSTNAME"
}

# Main execution
main() {
    validate_hostname_param
    validate_hostname_format

    # Get current hostname
    local OLD_HOSTNAME=$(get_current_hostname)
    print_info "Current hostname: $OLD_HOSTNAME"
    echo

    # Check if hostname is already set
    if [ "$OLD_HOSTNAME" = "$NEW_HOSTNAME" ]; then
        print_warning "Hostname is already set to: $NEW_HOSTNAME"
        exit 0
    fi

    # Detect cloud provider
    local cloud_provider=$(detect_cloud_provider)
    if [ "$cloud_provider" != "none" ]; then
        print_info "Cloud provider detected: $cloud_provider"
        echo
    fi

    # Backup configuration files
    backup_configs

    # Change hostname
    if command_exists hostnamectl; then
        change_hostname_hostnamectl
    else
        change_hostname_manual
    fi

    # Update /etc/hosts
    update_hosts_file "$OLD_HOSTNAME"

    # Handle cloud provider specifics
    handle_cloud_provider "$cloud_provider"

    # Restart network services if requested
    restart_network_services

    # Verify change
    verify_hostname

    # Display summary
    display_summary "$OLD_HOSTNAME"
}

# Run main
main
