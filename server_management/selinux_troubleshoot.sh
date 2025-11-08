#!/usr/bin/env bash
set -euo pipefail

#################################################
#                                               #
#     SELinux Troubleshooting Tool              #
#     Diagnose and manage SELinux issues        #
#                                               #
#################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Setup
trap cleanup_on_exit EXIT
require_root

# Configuration
ACTION="${1:-status}"
MODE="${MODE:-temporary}"  # temporary or permanent
BACKUP_CONFIG="${BACKUP_CONFIG:-yes}"

print_header "SELinux Troubleshooting Tool"

# Detect OS
OS=$(detect_os)

# Check if SELinux is available
check_selinux_available() {
    if ! command_exists getenforce; then
        error_exit "SELinux is not available on this system.

This tool requires SELinux-enabled systems (RHEL, CentOS, Fedora, Rocky, AlmaLinux)"
    fi
}

# Get current SELinux status
get_selinux_status() {
    getenforce 2>/dev/null || echo "Unknown"
}

# Show SELinux status
show_status() {
    print_header "SELinux Status"

    local current_status=$(get_selinux_status)

    echo "Current Mode: $current_status"
    echo
    sestatus
    echo

    # Check config file
    if [ -f /etc/selinux/config ]; then
        print_info "Configuration (/etc/selinux/config):"
        grep "^SELINUX=" /etc/selinux/config || echo "  No SELINUX setting found"
        grep "^SELINUXTYPE=" /etc/selinux/config || echo "  No SELINUXTYPE setting found"
    fi
}

# Show recent SELinux denials
show_denials() {
    print_header "Recent SELinux Denials"

    if ! command_exists ausearch; then
        print_warning "ausearch not found. Install policycoreutils-python-utils or audit package"
        return 1
    fi

    print_info "Checking for recent SELinux denials (last hour)..."
    echo

    if ausearch -m AVC,USER_AVC -ts recent 2>/dev/null | grep -q "type=AVC"; then
        ausearch -m AVC,USER_AVC -ts recent 2>/dev/null | grep "type=AVC" | head -20
        echo
        print_info "Use 'ausearch -m AVC -ts recent' for full audit log"
    else
        print_success "No recent SELinux denials found"
    fi
}

# Suggest fixes for SELinux denials
suggest_fixes() {
    print_header "SELinux Denial Analysis"

    if ! command_exists audit2why; then
        print_warning "audit2why not found. Install policycoreutils-python-utils package"
        print_info "To install:"
        print_info "  RHEL/Rocky/AlmaLinux: dnf install policycoreutils-python-utils"
        return 1
    fi

    print_info "Analyzing recent denials and suggesting fixes..."
    echo

    if ausearch -m AVC,USER_AVC -ts recent 2>/dev/null > /tmp/selinux_denials.log; then
        if [ -s /tmp/selinux_denials.log ]; then
            audit2why -i /tmp/selinux_denials.log
            echo
            print_info "To generate a custom policy module:"
            print_info "  audit2allow -a -M my_policy"
            print_info "  semodule -i my_policy.pp"
        else
            print_success "No denials to analyze"
        fi
        rm -f /tmp/selinux_denials.log
    else
        print_warning "Could not read audit log. Check audit daemon is running."
    fi
}

# Set SELinux to permissive (with warnings)
set_permissive() {
    print_header "Setting SELinux to Permissive Mode"

    local current_status=$(get_selinux_status)

    if [ "$current_status" = "Permissive" ]; then
        print_warning "SELinux is already in Permissive mode"
        return 0
    fi

    if [ "$current_status" = "Disabled" ]; then
        print_warning "SELinux is Disabled. Cannot set to Permissive without reboot."
        print_info "To enable SELinux:"
        print_info "  1. Edit /etc/selinux/config and set SELINUX=permissive"
        print_info "  2. Reboot the system"
        return 1
    fi

    # Display strong warnings
    echo
    print_warning "╔════════════════════════════════════════════════════════════════╗"
    print_warning "║                    SECURITY WARNING                            ║"
    print_warning "╚════════════════════════════════════════════════════════════════╝"
    echo
    print_warning "Setting SELinux to Permissive mode DISABLES mandatory access controls!"
    echo
    print_warning "Risks:"
    print_warning "  - Reduced system security"
    print_warning "  - Policy violations are logged but NOT enforced"
    print_warning "  - Compliance violations (PCI-DSS, HIPAA, etc.)"
    print_warning "  - Not recommended for production systems"
    echo
    print_info "This should ONLY be used for:"
    print_info "  - Troubleshooting SELinux issues"
    print_info "  - Identifying which policies need to be adjusted"
    print_info "  - Development and testing environments"
    echo
    print_info "Better alternatives:"
    print_info "  1. Use this tool's 'denials' command to see what's blocked"
    print_info "  2. Use 'suggest' command to get policy recommendations"
    print_info "  3. Create custom SELinux policies instead of disabling"
    print_info "  4. Use SELinux booleans: getsebool -a | grep <service>"
    print_info "  5. Fix file contexts: restorecon -Rv /path"
    echo

    # Require confirmation
    read -p "Are you sure you want to continue? (Type 'yes' to confirm): " confirm

    if [ "$confirm" != "yes" ]; then
        print_info "Aborted. No changes made."
        return 0
    fi

    # Determine mode
    if [ "$MODE" = "temporary" ]; then
        print_info "Setting SELinux to Permissive mode (temporary - reverts on reboot)..."
        setenforce 0
        print_success "SELinux set to Permissive mode (temporary)"
        print_info "This change will revert to Enforcing on next reboot"
    else
        print_info "Setting SELinux to Permissive mode (permanent)..."

        # Backup config
        if [ "$BACKUP_CONFIG" = "yes" ]; then
            local backup_file="/etc/selinux/config.backup-$(date +%Y%m%d_%H%M%S)"
            cp /etc/selinux/config "$backup_file"
            print_info "Config backed up to: $backup_file"
        fi

        # Update config file
        sed -i 's/^SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
        sed -i 's/^SELINUX=disabled/SELINUX=permissive/g' /etc/selinux/config

        # Set current mode
        setenforce 0

        print_success "SELinux set to Permissive mode (permanent)"
        print_warning "Change is persistent across reboots"
    fi

    echo
    print_info "Current status:"
    sestatus | grep "Current mode"
    echo

    print_info "To re-enable SELinux:"
    if [ "$MODE" = "temporary" ]; then
        print_info "  setenforce 1"
    else
        print_info "  1. Edit /etc/selinux/config and set SELINUX=enforcing"
        print_info "  2. Run: setenforce 1"
        print_info "  3. Or reboot"
    fi

    log_success "SELinux set to Permissive mode (MODE=$MODE)"
}

# Set SELinux to enforcing
set_enforcing() {
    print_header "Setting SELinux to Enforcing Mode"

    local current_status=$(get_selinux_status)

    if [ "$current_status" = "Enforcing" ]; then
        print_success "SELinux is already in Enforcing mode"
        return 0
    fi

    if [ "$current_status" = "Disabled" ]; then
        print_warning "SELinux is Disabled. Cannot set to Enforcing without reboot."
        print_info "To enable SELinux:"
        print_info "  1. Edit /etc/selinux/config and set SELINUX=enforcing"
        print_info "  2. Reboot the system"
        print_info "  3. System will relabel filesystem on first boot (may take time)"
        return 1
    fi

    print_info "Setting SELinux to Enforcing mode..."

    # Backup config
    if [ "$BACKUP_CONFIG" = "yes" ]; then
        local backup_file="/etc/selinux/config.backup-$(date +%Y%m%d_%H%M%S)"
        cp /etc/selinux/config "$backup_file"
        print_info "Config backed up to: $backup_file"
    fi

    # Update config file
    sed -i 's/^SELINUX=permissive/SELINUX=enforcing/g' /etc/selinux/config
    sed -i 's/^SELINUX=disabled/SELINUX=enforcing/g' /etc/selinux/config

    # Set current mode
    setenforce 1

    print_success "SELinux set to Enforcing mode"
    echo
    sestatus | grep "Current mode"

    log_success "SELinux set to Enforcing mode"
}

# Show help
show_help() {
    cat <<EOF
SELinux Troubleshooting Tool

Usage: $0 <command> [options]

Commands:
  status      Show current SELinux status (default)
  denials     Show recent SELinux denials from audit log
  suggest     Analyze denials and suggest policy fixes
  permissive  Set SELinux to Permissive mode (with warnings)
  enforcing   Set SELinux to Enforcing mode
  help        Show this help message

Options (environment variables):
  MODE=temporary|permanent   Mode for permissive/enforcing (default: temporary)
  BACKUP_CONFIG=yes|no       Backup config before changes (default: yes)

Examples:
  $0 status                    # Show current status
  $0 denials                   # Show recent denials
  $0 suggest                   # Get fix suggestions
  $0 permissive                # Set permissive (temporary)
  MODE=permanent $0 permissive # Set permissive (permanent)
  $0 enforcing                 # Set enforcing

Troubleshooting Workflow:
  1. Check status:        $0 status
  2. View denials:        $0 denials
  3. Get suggestions:     $0 suggest
  4. Apply fixes (don't just disable SELinux!)

Common SELinux Fixes:
  - Fix file contexts:    restorecon -Rv /path/to/files
  - Set booleans:         setsebool -P httpd_can_network_connect on
  - View booleans:        getsebool -a | grep httpd
  - Custom policy:        audit2allow -a -M mypolicy && semodule -i mypolicy.pp

Security Warning:
  Disabling or setting SELinux to Permissive reduces system security.
  Always prefer fixing SELinux policies over disabling enforcement.
EOF
}

# Main execution
main() {
    check_selinux_available

    case "$ACTION" in
        status)
            show_status
            ;;
        denials)
            show_denials
            ;;
        suggest|fixes|analyze)
            suggest_fixes
            ;;
        permissive)
            set_permissive
            ;;
        enforcing)
            set_enforcing
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error_exit "Invalid command: $ACTION

Usage: $0 <command>

Commands: status, denials, suggest, permissive, enforcing, help

Run '$0 help' for detailed usage information."
            ;;
    esac
}

# Run main
main
