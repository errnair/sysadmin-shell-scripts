#!/usr/bin/env bash
set -euo pipefail

#################################################
#                                               #
#     System and Hardware Information Gatherer #
#     Multi-OS support with JSON output         #
#                                               #
#################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Setup
trap cleanup_on_exit EXIT
require_root

# Configuration
OUTPUT_FORMAT="${OUTPUT_FORMAT:-text}"  # text, json, or csv
SAVE_TO_FILE="${SAVE_TO_FILE:-no}"
OUTPUT_FILE="${OUTPUT_FILE:-/tmp/system_stats_$(date +%Y%m%d_%H%M%S).txt}"

print_header "System and Hardware Information"

# Detect OS
OS=$(detect_os)

print_info "Detected OS: $OS"
print_info "Output format: $OUTPUT_FORMAT"
echo

# Gather system information
gather_system_info() {
    local info_array=()

    # OS Information
    case "$OS" in
        rhel)
            if [ -f /etc/redhat-release ]; then
                OS_INFO=$(cat /etc/redhat-release)
            elif [ -f /etc/os-release ]; then
                OS_INFO=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
            else
                OS_INFO="Unknown RHEL-based"
            fi
            ;;
        debian)
            if [ -f /etc/os-release ]; then
                OS_INFO=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
            else
                OS_INFO="Unknown Debian-based"
            fi
            ;;
        *)
            OS_INFO="Unknown"
            ;;
    esac

    # Kernel
    KERNEL=$(uname -r)

    # Hostname
    HOSTNAME=$(hostname -f 2>/dev/null || hostname)

    # Uptime
    UPTIME=$(uptime -p 2>/dev/null || uptime | awk -F'( |,)' '{print $3" "$4}')

    # Load Average
    LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^[[:space:]]*//')

    # Memory Information
    TOTAL_MEM=$(free -m | awk 'NR==2 {print $2 " MB"}')
    USED_MEM=$(free -m | awk 'NR==2 {print $3 " MB"}')
    FREE_MEM=$(free -m | awk 'NR==2 {print $4 " MB"}')
    AVAILABLE_MEM=$(free -m | awk 'NR==2 {print $7 " MB"}')

    # CPU Information
    CPU_MODEL=$(lscpu | grep "Model name" | cut -d: -f2 | sed 's/^[[:space:]]*//')
    CPU_COUNT=$(grep -c '^processor' /proc/cpuinfo)
    CPU_CORES=$(lscpu | grep "^Core(s) per socket" | awk '{print $NF}')
    CPU_SOCKETS=$(lscpu | grep "^Socket(s)" | awk '{print $NF}')
    CPU_THREADS=$(lscpu | grep "^Thread(s) per core" | awk '{print $NF}')
    CPU_MHZ=$(lscpu | grep "CPU MHz" | awk '{print $NF}')

    # RAM Type and Speed (if dmidecode available)
    if command_exists dmidecode; then
        RAM_TYPE=$(dmidecode --type 17 2>/dev/null | grep "Type:" | head -1 | awk '{print $2}')
        RAM_SPEED=$(dmidecode --type 17 2>/dev/null | grep "Speed:" | head -1 | awk '{print $2" "$3}')
    else
        RAM_TYPE="N/A"
        RAM_SPEED="N/A"
    fi

    # Disk Information
    DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
    DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
    DISK_AVAILABLE=$(df -h / | awk 'NR==2 {print $4}')
    DISK_PERCENT=$(df -h / | awk 'NR==2 {print $5}')

    # Network Information
    PRIVATE_IPS=$(ip -4 addr | grep inet | grep -v "127.0.0.1" | awk '{print $2}' | cut -d/ -f1 | tr '\n' ', ' | sed 's/,$//')

    # Public IP (try multiple sources)
    PUBLIC_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || \
                curl -s --max-time 5 icanhazip.com 2>/dev/null || \
                curl -s --max-time 5 api.ipify.org 2>/dev/null || \
                echo "N/A")

    # Virtualization Detection
    if command_exists systemd-detect-virt; then
        VIRT_TYPE=$(systemd-detect-virt 2>/dev/null || echo "none")
    elif command_exists virt-what; then
        VIRT_TYPE=$(virt-what 2>/dev/null || echo "none")
    else
        VIRT_TYPE="unknown"
    fi

    # SELinux/AppArmor Status
    if command_exists getenforce; then
        SELINUX_STATUS=$(getenforce 2>/dev/null || echo "N/A")
    else
        SELINUX_STATUS="N/A"
    fi

    if command_exists aa-status; then
        APPARMOR_STATUS=$(aa-status --enabled 2>/dev/null && echo "enabled" || echo "disabled")
    else
        APPARMOR_STATUS="N/A"
    fi

    # Container Runtime
    DOCKER_VERSION="N/A"
    if command_exists docker; then
        DOCKER_VERSION=$(docker --version 2>/dev/null | awk '{print $3}' | sed 's/,$//' || echo "installed")
    fi

    PODMAN_VERSION="N/A"
    if command_exists podman; then
        PODMAN_VERSION=$(podman --version 2>/dev/null | awk '{print $3}' || echo "installed")
    fi

    # Running Services Count
    if command_exists systemctl; then
        SERVICES_COUNT=$(systemctl list-units --type=service --state=running --no-pager --no-legend | wc -l)
    else
        SERVICES_COUNT="N/A"
    fi
}

# Display information in text format
display_text() {
    print_header "System and Hardware Information"
    echo

    print_info "===== SYSTEM INFORMATION ====="
    echo "1. OS Version: $OS_INFO"
    echo "2. Kernel: $KERNEL"
    echo "3. Hostname: $HOSTNAME"
    echo "4. Uptime: $UPTIME"
    echo "5. Load Average: $LOAD_AVG"
    echo "6. Virtualization: $VIRT_TYPE"
    echo

    print_info "===== SECURITY ====="
    echo "7. SELinux Status: $SELINUX_STATUS"
    echo "8. AppArmor Status: $APPARMOR_STATUS"
    echo

    print_info "===== CPU INFORMATION ====="
    echo "9. CPU Model: $CPU_MODEL"
    echo "10. CPU Count (logical): $CPU_COUNT"
    echo "11. CPU Sockets: $CPU_SOCKETS"
    echo "12. CPU Cores per Socket: $CPU_CORES"
    echo "13. Threads per Core: $CPU_THREADS"
    echo "14. CPU MHz: $CPU_MHZ"
    echo

    print_info "===== MEMORY INFORMATION ====="
    echo "15. Total Memory: $TOTAL_MEM"
    echo "16. Used Memory: $USED_MEM"
    echo "17. Free Memory: $FREE_MEM"
    echo "18. Available Memory: $AVAILABLE_MEM"
    echo "19. RAM Type: $RAM_TYPE"
    echo "20. RAM Speed: $RAM_SPEED"
    echo

    print_info "===== DISK INFORMATION ====="
    echo "21. Root Disk Total: $DISK_TOTAL"
    echo "22. Root Disk Used: $DISK_USED ($DISK_PERCENT)"
    echo "23. Root Disk Available: $DISK_AVAILABLE"
    echo

    print_info "===== DISK USAGE BY FILESYSTEM ====="
    df -h | awk 'NR>1 {printf "%-30s %8s %8s %8s %6s\n", $1, $2, $3, $4, $5}'
    echo

    print_info "===== NETWORK INFORMATION ====="
    echo "24. Private IP(s): $PRIVATE_IPS"
    echo "25. Public IP: $PUBLIC_IP"
    echo

    print_info "===== ADDITIONAL INFO ====="
    echo "26. Docker Version: $DOCKER_VERSION"
    echo "27. Podman Version: $PODMAN_VERSION"
    echo "28. Running Services: $SERVICES_COUNT"
    echo
}

# Display information in JSON format
display_json() {
    cat <<EOF
{
  "system": {
    "os": "$OS_INFO",
    "kernel": "$KERNEL",
    "hostname": "$HOSTNAME",
    "uptime": "$UPTIME",
    "load_average": "$LOAD_AVG",
    "virtualization": "$VIRT_TYPE"
  },
  "security": {
    "selinux": "$SELINUX_STATUS",
    "apparmor": "$APPARMOR_STATUS"
  },
  "cpu": {
    "model": "$CPU_MODEL",
    "logical_count": $CPU_COUNT,
    "sockets": $CPU_SOCKETS,
    "cores_per_socket": $CPU_CORES,
    "threads_per_core": $CPU_THREADS,
    "mhz": "$CPU_MHZ"
  },
  "memory": {
    "total": "$TOTAL_MEM",
    "used": "$USED_MEM",
    "free": "$FREE_MEM",
    "available": "$AVAILABLE_MEM",
    "ram_type": "$RAM_TYPE",
    "ram_speed": "$RAM_SPEED"
  },
  "disk": {
    "root_total": "$DISK_TOTAL",
    "root_used": "$DISK_USED",
    "root_available": "$DISK_AVAILABLE",
    "root_percent": "$DISK_PERCENT"
  },
  "network": {
    "private_ips": "$PRIVATE_IPS",
    "public_ip": "$PUBLIC_IP"
  },
  "containers": {
    "docker": "$DOCKER_VERSION",
    "podman": "$PODMAN_VERSION"
  },
  "services": {
    "running_count": "$SERVICES_COUNT"
  }
}
EOF
}

# Display information in CSV format
display_csv() {
    cat <<EOF
Category,Metric,Value
System,OS Version,$OS_INFO
System,Kernel,$KERNEL
System,Hostname,$HOSTNAME
System,Uptime,$UPTIME
System,Load Average,$LOAD_AVG
System,Virtualization,$VIRT_TYPE
Security,SELinux,$SELINUX_STATUS
Security,AppArmor,$APPARMOR_STATUS
CPU,Model,$CPU_MODEL
CPU,Logical Count,$CPU_COUNT
CPU,Sockets,$CPU_SOCKETS
CPU,Cores per Socket,$CPU_CORES
CPU,Threads per Core,$CPU_THREADS
CPU,MHz,$CPU_MHZ
Memory,Total,$TOTAL_MEM
Memory,Used,$USED_MEM
Memory,Free,$FREE_MEM
Memory,Available,$AVAILABLE_MEM
Memory,RAM Type,$RAM_TYPE
Memory,RAM Speed,$RAM_SPEED
Disk,Root Total,$DISK_TOTAL
Disk,Root Used,$DISK_USED
Disk,Root Available,$DISK_AVAILABLE
Disk,Root Percent,$DISK_PERCENT
Network,Private IPs,$PRIVATE_IPS
Network,Public IP,$PUBLIC_IP
Containers,Docker,$DOCKER_VERSION
Containers,Podman,$PODMAN_VERSION
Services,Running Count,$SERVICES_COUNT
EOF
}

# Main execution
main() {
    gather_system_info

    case "$OUTPUT_FORMAT" in
        json)
            OUTPUT=$(display_json)
            ;;
        csv)
            OUTPUT=$(display_csv)
            ;;
        text|*)
            OUTPUT=$(display_text)
            ;;
    esac

    # Display output
    echo "$OUTPUT"

    # Save to file if requested
    if [ "$SAVE_TO_FILE" = "yes" ]; then
        echo "$OUTPUT" > "$OUTPUT_FILE"
        echo
        print_success "Output saved to: $OUTPUT_FILE"
        log_success "System stats saved to $OUTPUT_FILE"
    fi
}

# Run main
main
