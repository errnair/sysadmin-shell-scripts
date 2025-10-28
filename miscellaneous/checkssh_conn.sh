#!/usr/bin/env bash
set -euo pipefail

#################################################
#                                               #
#     Check active SSH connections              #
#     Uses 'ss' (modern replacement for netstat)#
#                                               #
#################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

print_header "SSH Connection Monitor"

# Check if ss command exists (modern replacement for netstat)
if ! command_exists ss; then
    print_warning "'ss' command not found, trying 'netstat' (deprecated)"
    if command_exists netstat; then
        conn_check=$(netstat -tnp 2>/dev/null | grep ':22' | grep ESTABLISHED || true)
    else
        error_exit "Neither 'ss' nor 'netstat' found. Please install iproute2 package."
    fi
else
    # Use ss (modern, recommended)
    conn_check=$(ss -tnp 2>/dev/null | grep ':22' | grep ESTAB || true)
fi

# Display results
if [[ -z "$conn_check" ]]; then
    print_info "No active SSH connections found"
    exit 0
else
    print_success "Active SSH connections:"
    echo
    echo "$conn_check"
    echo

    # Count connections
    conn_count=$(echo "$conn_check" | wc -l)
    print_info "Total connections: $conn_count"

    # Show unique IPs
    print_info "Unique source IPs:"
    if command_exists ss; then
        echo "$conn_check" | awk '{print $5}' | cut -d: -f1 | sort -u | while read ip; do
            echo "  - $ip"
        done
    fi
fi
