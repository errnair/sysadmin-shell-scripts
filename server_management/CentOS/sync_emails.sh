#!/usr/bin/env bash
set -euo pipefail

#################################################
#                                               #
# A shell script to sync IMAP email accounts   #
# Secure password handling via prompts          #
#                                               #
#################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

# Setup
trap cleanup_on_exit EXIT
require_root

print_header "IMAP Email Sync Tool"

# Check if imapsync is installed
check_imapsync() {
    if command_exists imapsync; then
        print_success "imapsync is installed"
        return 0
    else
        print_warning "imapsync is not installed"
        return 1
    fi
}

# Install imapsync
install_imapsync() {
    print_info "Installing imapsync..."

    local pkg_mgr=$(get_package_manager)

    case "$pkg_mgr" in
        dnf|yum)
            $pkg_mgr install -y epel-release
            $pkg_mgr install -y imapsync
            ;;
        apt)
            apt-get update
            apt-get install -y imapsync
            ;;
        *)
            error_exit "Unsupported package manager: $pkg_mgr"
            ;;
    esac

    print_success "imapsync installed successfully"
}

# Main sync function
sync_emails() {
    local host1="$1"
    local user1="$2"
    local pass1="$3"
    local host2="$4"
    local user2="$5"
    local pass2="$6"

    print_info "Starting email synchronization..."
    print_info "Source: $user1@$host1"
    print_info "Destination: $user2@$host2"
    echo

    # Create temporary password files (more secure than command line)
    local pass1_file=$(mktemp)
    local pass2_file=$(mktemp)
    chmod 600 "$pass1_file" "$pass2_file"

    echo "$pass1" > "$pass1_file"
    echo "$pass2" > "$pass2_file"

    # Run imapsync with password files
    if imapsync \
        --host1 "$host1" \
        --user1 "$user1" \
        --passfile1 "$pass1_file" \
        --host2 "$host2" \
        --user2 "$user2" \
        --passfile2 "$pass2_file" \
        --automap \
        --syncinternaldates \
        --exclude "\[Gmail\]/All Mail" \
        --useheader 'Message-Id' \
        --useheader 'X-Gmail-Received' \
        --skipsize \
        --allowsizemismatch \
        --addheader; then

        print_success "Email synchronization completed successfully"
        log_success "Synced emails from $user1@$host1 to $user2@$host2"
    else
        rm -f "$pass1_file" "$pass2_file"
        error_exit "Email synchronization failed"
    fi

    # Cleanup password files
    rm -f "$pass1_file" "$pass2_file"
}

# Interactive mode - get credentials securely
interactive_sync() {
    print_info "Enter source email account details:"
    read -p "Source IMAP Host: " host1
    read -p "Source Email/Username: " user1
    read_password "Source Password" pass1 || error_exit "Source password required"

    echo
    print_info "Enter destination email account details:"
    read -p "Destination IMAP Host: " host2
    read -p "Destination Email/Username: " user2
    read_password "Destination Password" pass2 || error_exit "Destination password required"

    echo
    if confirm "Sync from $user1@$host1 to $user2@$host2?" "no"; then
        sync_emails "$host1" "$user1" "$pass1" "$host2" "$user2" "$pass2"
    else
        print_warning "Sync cancelled by user"
        exit 0
    fi
}

# Check for imapsync
if ! check_imapsync; then
    if confirm "Install imapsync now?" "yes"; then
        install_imapsync
    else
        error_exit "imapsync is required for email synchronization"
    fi
fi

# Run interactive sync
interactive_sync
