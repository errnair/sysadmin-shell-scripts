#!/usr/bin/env bash
set -euo pipefail

#################################################
#                                               #
#     Install Python 3 (system or from source)  #
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
PYTHON_VERSION="${1:-3.12.7}"
PYTHON_MAJOR_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f1,2)
INSTALL_METHOD="${INSTALL_METHOD:-auto}"  # auto, package, source
INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"
BUILD_DIR="/tmp/python-build-$$"

# Python download URL and checksum
PYTHON_URL="https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz"
# SHA256 for Python 3.12.7 - verify from https://www.python.org/downloads/
PYTHON_SHA256="24887b92e6dbe1f7b78e5f6f5b259ef5e938d654c5b6c3c8d8551dd6a2d8330f"

print_header "Python 3 Installer"

print_info "Target version: Python ${PYTHON_VERSION}"
print_info "Installation method: ${INSTALL_METHOD}"
print_info "Install prefix: ${INSTALL_PREFIX}"
echo

# Detect OS
OS=$(detect_os)
PKG_MGR=$(get_package_manager)

print_info "Detected OS: $OS"
print_info "Package manager: $PKG_MGR"
echo

# Check if Python 3 is already installed
check_existing_python() {
    if command_exists python3; then
        local current_version=$(python3 --version 2>&1 | awk '{print $2}')
        print_info "Python 3 is already installed: $current_version"

        if version_gt "$current_version" "$PYTHON_VERSION" || [ "$current_version" = "$PYTHON_VERSION" ]; then
            print_success "Installed version ($current_version) meets or exceeds requested version ($PYTHON_VERSION)"
            return 0
        else
            print_warning "Installed version ($current_version) is older than requested ($PYTHON_VERSION)"
            return 1
        fi
    else
        print_info "Python 3 is not installed"
        return 1
    fi
}

# Install Python from system package manager
install_from_package() {
    print_header "Installing Python ${PYTHON_MAJOR_MINOR} from system packages"

    case "$OS" in
        rhel)
            case "$PKG_MGR" in
                dnf)
                    print_info "Using dnf (modern RHEL/Rocky/AlmaLinux)"
                    dnf install -y python${PYTHON_MAJOR_MINOR} python${PYTHON_MAJOR_MINOR}-pip python${PYTHON_MAJOR_MINOR}-devel
                    ;;
                yum)
                    print_info "Using yum (older RHEL/CentOS)"
                    yum install -y python${PYTHON_MAJOR_MINOR} python${PYTHON_MAJOR_MINOR}-pip python${PYTHON_MAJOR_MINOR}-devel
                    ;;
            esac
            ;;
        debian)
            print_info "Using apt (Debian/Ubuntu)"
            apt-get update
            apt-get install -y python${PYTHON_MAJOR_MINOR} python${PYTHON_MAJOR_MINOR}-venv python${PYTHON_MAJOR_MINOR}-dev python3-pip
            ;;
        *)
            print_warning "Unsupported OS for package installation: $OS"
            return 1
            ;;
    esac

    # Create python3 symlink if needed
    if ! command_exists python3; then
        ln -sf "${INSTALL_PREFIX}/bin/python${PYTHON_MAJOR_MINOR}" /usr/bin/python3
    fi

    print_success "Python ${PYTHON_MAJOR_MINOR} installed from system packages"
}

# Install build dependencies
install_build_deps() {
    print_info "Installing build dependencies..."

    case "$OS" in
        rhel)
            case "$PKG_MGR" in
                dnf)
                    dnf groupinstall -y "Development Tools"
                    dnf install -y gcc make zlib-devel bzip2-devel readline-devel \
                        sqlite-devel openssl-devel libffi-devel xz-devel \
                        tk-devel ncurses-devel gdbm-devel libuuid-devel wget
                    ;;
                yum)
                    yum groupinstall -y "Development Tools"
                    yum install -y gcc make zlib-devel bzip2-devel readline-devel \
                        sqlite-devel openssl-devel libffi-devel xz-devel \
                        tk-devel ncurses-devel gdbm-devel libuuid-devel wget
                    ;;
            esac
            ;;
        debian)
            apt-get update
            apt-get install -y build-essential wget libssl-dev zlib1g-dev \
                libbz2-dev libreadline-dev libsqlite3-dev curl \
                libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
                libffi-dev liblzma-dev
            ;;
        *)
            error_exit "Unsupported OS: $OS"
            ;;
    esac

    print_success "Build dependencies installed"
}

# Build Python from source
install_from_source() {
    print_header "Building Python ${PYTHON_VERSION} from source"

    # Install build dependencies
    install_build_deps

    # Create build directory
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    # Download Python source
    print_info "Downloading Python ${PYTHON_VERSION}..."
    if ! download_with_verify "$PYTHON_URL" "$PYTHON_SHA256" "Python-${PYTHON_VERSION}.tar.xz"; then
        print_warning "Checksum verification failed, downloading without verification..."
        if command_exists curl; then
            curl -fsSL -o "Python-${PYTHON_VERSION}.tar.xz" "$PYTHON_URL"
        else
            wget -q -O "Python-${PYTHON_VERSION}.tar.xz" "$PYTHON_URL"
        fi
    fi

    # Extract
    print_info "Extracting source..."
    tar -xf "Python-${PYTHON_VERSION}.tar.xz"
    cd "Python-${PYTHON_VERSION}"

    # Configure
    print_info "Configuring build..."
    ./configure \
        --prefix="$INSTALL_PREFIX" \
        --enable-optimizations \
        --enable-shared \
        --with-lto \
        --with-computed-gotos \
        --with-system-expat \
        --with-system-ffi \
        --enable-loadable-sqlite-extensions \
        LDFLAGS="-Wl,-rpath=${INSTALL_PREFIX}/lib"

    # Build
    print_info "Compiling Python (this may take 10-20 minutes)..."
    make -j$(nproc)

    # Install
    print_info "Installing Python..."
    make altinstall

    # Create symlinks
    print_info "Creating symlinks..."
    ln -sf "${INSTALL_PREFIX}/bin/python${PYTHON_MAJOR_MINOR}" "${INSTALL_PREFIX}/bin/python3"
    ln -sf "${INSTALL_PREFIX}/bin/pip${PYTHON_MAJOR_MINOR}" "${INSTALL_PREFIX}/bin/pip3"

    # Add to PATH if not already there
    if ! echo "$PATH" | grep -q "${INSTALL_PREFIX}/bin"; then
        echo "export PATH=${INSTALL_PREFIX}/bin:\$PATH" >> /etc/profile.d/python3.sh
        chmod +x /etc/profile.d/python3.sh
    fi

    # Update shared library cache
    if [ -f /etc/ld.so.conf.d/python3.conf ]; then
        echo "${INSTALL_PREFIX}/lib" > /etc/ld.so.conf.d/python3.conf
        ldconfig
    fi

    # Cleanup
    cd /
    rm -rf "$BUILD_DIR"

    print_success "Python ${PYTHON_VERSION} built and installed from source"
}

# Upgrade pip and install essential packages
setup_pip() {
    print_info "Setting up pip and essential packages..."

    # Find python3 and pip3
    local python_cmd
    if command_exists python3; then
        python_cmd="python3"
    elif command_exists python${PYTHON_MAJOR_MINOR}; then
        python_cmd="python${PYTHON_MAJOR_MINOR}"
    else
        print_warning "Could not find python3 command"
        return 1
    fi

    # Ensure pip is installed
    if ! $python_cmd -m pip --version &>/dev/null; then
        print_info "Installing pip..."
        $python_cmd -m ensurepip --upgrade
    fi

    # Upgrade pip, setuptools, wheel
    print_info "Upgrading pip, setuptools, and wheel..."
    $python_cmd -m pip install --upgrade pip setuptools wheel

    print_success "Pip setup complete"
}

# Main installation logic
main() {
    # Check if already installed and satisfactory
    if check_existing_python && [ "$INSTALL_METHOD" != "source" ]; then
        if confirm "Python 3 is already installed. Continue anyway?" "no"; then
            print_info "Continuing with installation..."
        else
            print_info "Installation cancelled"
            exit 0
        fi
    fi

    # Determine installation method
    if [ "$INSTALL_METHOD" = "auto" ]; then
        # Try package first, fall back to source
        print_info "Attempting package installation first..."
        if install_from_package; then
            print_success "Installed from system packages"
        else
            print_info "Package installation not available, building from source..."
            install_from_source
        fi
    elif [ "$INSTALL_METHOD" = "package" ]; then
        install_from_package || error_exit "Package installation failed"
    elif [ "$INSTALL_METHOD" = "source" ]; then
        install_from_source
    else
        error_exit "Invalid installation method: $INSTALL_METHOD"
    fi

    # Setup pip
    setup_pip

    # Verify installation
    print_header "Verification"

    local installed_version=$(python3 --version 2>&1 | awk '{print $2}')
    print_success "Python version: $installed_version"

    local python_path=$(which python3)
    print_info "Python path: $python_path"

    local pip_version=$(python3 -m pip --version 2>&1 | awk '{print $2}')
    print_info "Pip version: $pip_version"

    echo
    print_success "Python 3 installation complete!"
    echo
    print_info "Test with: python3 --version"
    print_info "Create venv: python3 -m venv myenv"
    print_info "Install packages: python3 -m pip install <package>"

    log_success "Python ${installed_version} installed successfully"
}

# Run main
main
