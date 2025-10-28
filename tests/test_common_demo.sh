#!/usr/bin/env bash
#################################################
#                                               #
#     Demo/Test Script for lib/common.sh       #
#                                               #
#################################################

set -euo pipefail

# Source the common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

print_header "Common Library Function Tests"

# Test 1: Color Output
print_info "Testing color output functions..."
print_success "This is a success message"
print_warning "This is a warning message"
print_error "This is an error message"
echo

# Test 2: OS Detection
print_header "OS Detection"
print_info "Detected OS family: $(detect_os)"
print_info "OS version: $(detect_os_version)"
print_info "Package manager: $(get_package_manager)"
echo

# Test 3: Command Existence
print_header "Command Existence Checks"
if command_exists bash; then
    print_success "bash command exists"
else
    print_error "bash command not found"
fi

if command_exists nonexistentcommand12345; then
    print_success "nonexistentcommand12345 exists"
else
    print_warning "nonexistentcommand12345 not found (expected)"
fi
echo

# Test 4: Input Validation
print_header "Input Validation"

# Valid inputs
if validate_ip "192.168.1.1"; then
    print_success "Valid IP: 192.168.1.1"
fi

if validate_port 8080; then
    print_success "Valid port: 8080"
fi

if validate_hostname "myserver"; then
    print_success "Valid hostname: myserver"
fi

if validate_domain "example.com"; then
    print_success "Valid domain: example.com"
fi

echo

# Invalid inputs (these will print errors)
print_info "Testing invalid inputs (errors expected):"
validate_ip "999.999.999.999" || print_info "  ✓ Correctly rejected invalid IP"
validate_port 99999 || print_info "  ✓ Correctly rejected invalid port"
validate_hostname "invalid-hostname-" || print_info "  ✓ Correctly rejected invalid hostname"
validate_domain "notadomain" || print_info "  ✓ Correctly rejected invalid domain"
echo

# Test 5: Version Comparison
print_header "Version Comparison"
if version_gt "2.0" "1.9"; then
    print_success "2.0 > 1.9 (correct)"
else
    print_error "Version comparison failed"
fi

if version_gt "1.9" "2.0"; then
    print_error "1.9 > 2.0 (incorrect!)"
else
    print_success "1.9 not > 2.0 (correct)"
fi
echo

# Test 6: Network Functions (requires internet)
print_header "Network Functions"
print_info "Attempting to get private IP..."
if private_ip=$(get_private_ip 2>/dev/null); then
    print_success "Private IP: $private_ip"
else
    print_warning "Could not detect private IP"
fi
echo

# Test 7: Dry Run Mode
print_header "Dry Run Mode"
DRY_RUN=false
if is_dry_run; then
    print_info "Dry run mode is ENABLED"
else
    print_info "Dry run mode is DISABLED"
fi

print_info "Executing command (DRY_RUN=false):"
dry_run_execute echo "This will actually execute"
echo

DRY_RUN=true
print_info "Executing command (DRY_RUN=true):"
dry_run_execute echo "This will be simulated only"
echo

# Summary
print_header "Test Summary"
print_success "All common library function tests completed!"
print_info "The library is ready to use in your scripts"
echo
print_info "Example usage in a script:"
cat <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Use functions
require_root
print_info "Starting installation..."
validate_domain "example.com" || error_exit "Invalid domain"
log_success "Installation complete"
EOF
