#!/usr/bin/env bash
#################################################
#                                               #
#     Common Functions Library                 #
#     Shared utilities for all scripts         #
#                                               #
#################################################
# Version: 1.0.0
# Last Updated: 2025-10-18

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This is a library file and should not be executed directly."
    echo "Source it in your scripts: source /path/to/lib/common.sh"
    exit 1
fi

# ============================================
# COLOR OUTPUT FUNCTIONS
# ============================================

# Check if output is to a terminal
if [ -t 1 ]; then
    # Terminal colors
    readonly COLOR_RESET='\033[0m'
    readonly COLOR_RED='\033[0;31m'
    readonly COLOR_GREEN='\033[0;32m'
    readonly COLOR_YELLOW='\033[0;33m'
    readonly COLOR_BLUE='\033[0;34m'
    readonly COLOR_MAGENTA='\033[0;35m'
    readonly COLOR_CYAN='\033[0;36m'
    readonly COLOR_BOLD='\033[1m'
else
    # No colors for non-terminal output
    readonly COLOR_RESET=''
    readonly COLOR_RED=''
    readonly COLOR_GREEN=''
    readonly COLOR_YELLOW=''
    readonly COLOR_BLUE=''
    readonly COLOR_MAGENTA=''
    readonly COLOR_CYAN=''
    readonly COLOR_BOLD=''
fi

# Print informational message (blue)
print_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"
}

# Print success message (green)
print_success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $*"
}

# Print warning message (yellow)
print_warning() {
    echo -e "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $*"
}

# Print error message (red)
print_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

# Print header message (bold)
print_header() {
    echo -e "\n${COLOR_BOLD}=== $* ===${COLOR_RESET}\n"
}

# ============================================
# OPERATING SYSTEM DETECTION
# ============================================

# Detect operating system family
# Returns: rhel, debian, arch, or unknown
detect_os() {
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        case "$ID" in
            rhel|centos|rocky|almalinux|fedora)
                echo "rhel"
                ;;
            debian|ubuntu|linuxmint)
                echo "debian"
                ;;
            arch|manjaro)
                echo "arch"
                ;;
            *)
                echo "unknown"
                ;;
        esac
    else
        echo "unknown"
    fi
}

# Detect operating system version
# Returns: version number (e.g., "9", "22.04")
detect_os_version() {
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        echo "$VERSION_ID"
    else
        echo "unknown"
    fi
}

# Get package manager command
# Returns: dnf, yum, apt, pacman, or unknown
get_package_manager() {
    if command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v apt &> /dev/null; then
        echo "apt"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

# ============================================
# PRIVILEGE AND PERMISSION CHECKS
# ============================================

# Check if script is running as root, exit if not
require_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (or with sudo)"
        exit 1
    fi
}

# Check if script is NOT running as root, exit if it is
require_non_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should NOT be run as root"
        exit 1
    fi
}

# ============================================
# COMMAND EXISTENCE CHECKS
# ============================================

# Check if a command exists
# Usage: command_exists <command>
# Returns: 0 if exists, 1 if not
command_exists() {
    command -v "$1" &> /dev/null
}

# Require a command to exist, exit if not found
# Usage: require_command <command> [package_name]
require_command() {
    local cmd="$1"
    local pkg="${2:-$1}"

    if ! command_exists "$cmd"; then
        print_error "Required command '$cmd' not found"
        print_info "Install it with: $(get_package_manager) install $pkg"
        exit 1
    fi
}

# ============================================
# INPUT VALIDATION
# ============================================

# Validate domain name format
# Usage: validate_domain <domain>
# Returns: 0 if valid, 1 if not
validate_domain() {
    local domain="$1"
    local regex='^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$'

    if [[ "$domain" =~ $regex ]]; then
        return 0
    else
        print_error "Invalid domain name: $domain"
        return 1
    fi
}

# Validate IP address (IPv4)
# Usage: validate_ip <ip_address>
# Returns: 0 if valid, 1 if not
validate_ip() {
    local ip="$1"
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'

    if [[ "$ip" =~ $regex ]]; then
        # Check each octet is <= 255
        local IFS='.'
        local -a octets=($ip)
        for octet in "${octets[@]}"; do
            if (( octet > 255 )); then
                print_error "Invalid IP address: $ip"
                return 1
            fi
        done
        return 0
    else
        print_error "Invalid IP address format: $ip"
        return 1
    fi
}

# Validate port number
# Usage: validate_port <port>
# Returns: 0 if valid, 1 if not
validate_port() {
    local port="$1"

    if [[ "$port" =~ ^[0-9]+$ ]] && (( port >= 1 && port <= 65535 )); then
        return 0
    else
        print_error "Invalid port number: $port (must be 1-65535)"
        return 1
    fi
}

# Validate hostname per RFC 1123
# Usage: validate_hostname <hostname>
# Returns: 0 if valid, 1 if not
validate_hostname() {
    local hostname="$1"
    local regex='^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$'

    if [[ "$hostname" =~ $regex ]] && [[ ${#hostname} -le 63 ]]; then
        return 0
    else
        print_error "Invalid hostname: $hostname"
        print_info "Hostname must be 1-63 characters, alphanumeric and hyphens only"
        print_info "Cannot start or end with hyphen"
        return 1
    fi
}

# ============================================
# BACKUP FUNCTIONS
# ============================================

# Create timestamped backup of a file
# Usage: backup_file <file_path> [backup_dir]
backup_file() {
    local file="$1"
    local backup_dir="${2:-.}"
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    local backup_path="${backup_dir}/$(basename "$file").backup-${timestamp}"

    if [ ! -f "$file" ]; then
        print_error "File not found: $file"
        return 1
    fi

    cp -p "$file" "$backup_path"
    print_success "Backed up: $file -> $backup_path"
    echo "$backup_path"
}

# Create timestamped backup of a directory
# Usage: backup_dir <dir_path> [backup_dir]
backup_dir() {
    local dir="$1"
    local backup_dir="${2:-.}"
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    local backup_path="${backup_dir}/$(basename "$dir").backup-${timestamp}"

    if [ ! -d "$dir" ]; then
        print_error "Directory not found: $dir"
        return 1
    fi

    cp -rp "$dir" "$backup_path"
    print_success "Backed up: $dir -> $backup_path"
    echo "$backup_path"
}

# ============================================
# LOGGING FUNCTIONS
# ============================================

# Log informational message to syslog and stdout
# Usage: log_info <message>
log_info() {
    local msg="$*"
    print_info "$msg"
    logger -t "$(basename "$0")" -p user.info "$msg"
}

# Log error message to syslog and stderr
# Usage: log_error <message>
log_error() {
    local msg="$*"
    print_error "$msg"
    logger -t "$(basename "$0")" -p user.err "$msg"
}

# Log success message to syslog and stdout
# Usage: log_success <message>
log_success() {
    local msg="$*"
    print_success "$msg"
    logger -t "$(basename "$0")" -p user.notice "$msg"
}

# ============================================
# SERVICE MANAGEMENT
# ============================================

# Start and enable a systemd service
# Usage: start_and_enable <service_name>
start_and_enable() {
    local service="$1"

    print_info "Starting and enabling service: $service"

    if systemctl start "$service"; then
        print_success "Started $service"
    else
        print_error "Failed to start $service"
        return 1
    fi

    if systemctl enable "$service"; then
        print_success "Enabled $service"
    else
        print_warning "Failed to enable $service"
    fi

    return 0
}

# Restart a systemd service with error handling
# Usage: restart_service <service_name>
restart_service() {
    local service="$1"

    print_info "Restarting service: $service"

    if systemctl restart "$service"; then
        print_success "Restarted $service"
        return 0
    else
        print_error "Failed to restart $service"
        systemctl status "$service" --no-pager
        return 1
    fi
}

# ============================================
# FIREWALL MANAGEMENT
# ============================================

# Open a firewall port (works with firewalld or ufw)
# Usage: open_firewall_port <port> [protocol] [zone]
open_firewall_port() {
    local port="$1"
    local protocol="${2:-tcp}"
    local zone="${3:-public}"

    validate_port "$port" || return 1

    if command_exists firewall-cmd; then
        print_info "Opening port $port/$protocol in firewalld (zone: $zone)"
        firewall-cmd --zone="$zone" --add-port="$port/$protocol" --permanent
        firewall-cmd --reload
        print_success "Port $port/$protocol opened"
    elif command_exists ufw; then
        print_info "Opening port $port/$protocol in ufw"
        ufw allow "$port/$protocol"
        print_success "Port $port/$protocol opened"
    else
        print_warning "No supported firewall found (firewalld or ufw)"
        return 1
    fi
}

# ============================================
# ERROR HANDLING
# ============================================

# Print error and exit with specified code
# Usage: error_exit <message> [exit_code]
error_exit() {
    local msg="$1"
    local code="${2:-1}"

    log_error "$msg"
    exit "$code"
}

# Cleanup function to be called on exit
# Usage: Set trap: trap cleanup_on_exit EXIT
cleanup_on_exit() {
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        log_success "Script completed successfully"
    else
        log_error "Script failed with exit code: $exit_code"
    fi

    # Add custom cleanup logic here if needed
    return $exit_code
}

# ============================================
# DRY RUN SUPPORT
# ============================================

# Global variable for dry-run mode (set in main script)
DRY_RUN=${DRY_RUN:-false}

# Check if in dry-run mode
# Returns: 0 if dry-run, 1 if not
is_dry_run() {
    [[ "$DRY_RUN" == "true" ]]
}

# Execute command or simulate if in dry-run mode
# Usage: dry_run_execute <command>
dry_run_execute() {
    if is_dry_run; then
        print_info "[DRY RUN] Would execute: $*"
        return 0
    else
        "$@"
    fi
}

# ============================================
# VERSION COMPARISON
# ============================================

# Compare version strings
# Usage: version_gt <version1> <version2>
# Returns: 0 if version1 > version2, 1 otherwise
version_gt() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

# ============================================
# NETWORK UTILITIES
# ============================================

# Get public IP address (multiple fallback methods)
# Usage: get_public_ip
get_public_ip() {
    local ip=""

    # Try multiple services
    ip=$(curl -s --max-time 3 https://ifconfig.me) || \
    ip=$(curl -s --max-time 3 https://icanhazip.com) || \
    ip=$(curl -s --max-time 3 https://api.ipify.org) || \
    ip=$(dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null)

    if [ -n "$ip" ]; then
        echo "$ip"
        return 0
    else
        print_error "Failed to detect public IP address"
        return 1
    fi
}

# Get primary private IP address
# Usage: get_private_ip
get_private_ip() {
    local ip=""

    # Try to get IP from default route interface
    ip=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $7; exit}')

    if [ -n "$ip" ]; then
        echo "$ip"
        return 0
    else
        # Fallback: get first non-loopback IP
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
        if [ -n "$ip" ]; then
            echo "$ip"
            return 0
        fi
    fi

    print_error "Failed to detect private IP address"
    return 1
}

# Check internet connectivity
# Usage: check_internet
# Returns: 0 if connected, 1 if not
check_internet() {
    print_info "Checking internet connectivity..."

    if ping -c 1 -W 3 8.8.8.8 &> /dev/null; then
        print_success "Internet connection available"
        return 0
    else
        print_error "No internet connection"
        return 1
    fi
}

# ============================================
# FILE INTEGRITY
# ============================================

# Verify SHA256 checksum of a file
# Usage: verify_checksum <file> <expected_checksum>
# Returns: 0 if valid, 1 if not
verify_checksum() {
    local file="$1"
    local expected="$2"

    if [ ! -f "$file" ]; then
        print_error "File not found: $file"
        return 1
    fi

    print_info "Verifying checksum for: $(basename "$file")"

    local actual=$(sha256sum "$file" | awk '{print $1}')

    if [ "$actual" = "$expected" ]; then
        print_success "Checksum verified"
        return 0
    else
        print_error "Checksum mismatch!"
        print_error "Expected: $expected"
        print_error "Actual:   $actual"
        return 1
    fi
}

# Download file and verify checksum
# Usage: download_with_verify <url> <checksum> [output_file]
download_with_verify() {
    local url="$1"
    local checksum="$2"
    local output="${3:-$(basename "$url")}"

    print_info "Downloading: $url"

    if command_exists curl; then
        curl -fsSL -o "$output" "$url" || return 1
    elif command_exists wget; then
        wget -q -O "$output" "$url" || return 1
    else
        print_error "Neither curl nor wget found"
        return 1
    fi

    print_success "Downloaded: $output"

    if [ -n "$checksum" ]; then
        verify_checksum "$output" "$checksum" || return 1
    fi

    return 0
}

# ============================================
# USER INTERACTION
# ============================================

# Prompt user for yes/no confirmation
# Usage: confirm "Question?" [default_yes]
# Returns: 0 for yes, 1 for no
confirm() {
    local prompt="$1"
    local default="${2:-no}"
    local answer

    if [ "$default" = "yes" ]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi

    read -p "$prompt" answer

    answer="${answer:-$default}"

    case "${answer,,}" in
        y|yes)
            return 0
            ;;
        n|no)
            return 1
            ;;
        *)
            print_error "Invalid response. Please answer yes or no."
            confirm "$1" "$default"
            ;;
    esac
}

# Read password securely (no echo)
# Usage: read_password "Prompt" <variable_name>
read_password() {
    local prompt="$1"
    local var_name="$2"
    local password

    read -sp "$prompt: " password
    echo

    if [ -z "$password" ]; then
        print_error "Password cannot be empty"
        return 1
    fi

    eval "$var_name='$password'"
    return 0
}

# ============================================
# LIBRARY INITIALIZATION
# ============================================

print_info "Common functions library loaded (v1.0.0)"
