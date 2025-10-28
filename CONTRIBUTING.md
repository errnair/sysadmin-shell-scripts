# Contributing to System Administration Shell Scripts

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)

## Code of Conduct

This project follows a Code of Conduct that all contributors are expected to adhere to:

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on what is best for the community
- Show empathy towards other community members

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the behavior
- **Expected behavior**
- **Actual behavior**
- **Environment details** (OS, version, etc.)
- **Log output** if applicable

### Suggesting Enhancements

Enhancement suggestions are welcome! Please provide:

- **Clear use case** - why is this needed?
- **Proposed solution** - how should it work?
- **Alternatives considered** - what other approaches did you think about?

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Development Setup

### Prerequisites

- Bash 4.0+ or compatible shell
- Python 3.9+ (for Python scripts)
- ShellCheck (for linting)
- BATS (for testing)

### Initial Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/sysadmin-shell-scripts.git
cd sysadmin-shell-scripts

# Install development dependencies
# For ShellCheck
sudo dnf install ShellCheck  # RHEL/CentOS/Rocky/AlmaLinux
sudo apt install shellcheck  # Debian/Ubuntu

# For BATS
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local

# For Python development
pip install -r python/requirements.txt
pip install pytest pytest-cov black flake8
```

## Coding Standards

### Shell Scripts

#### 1. Shebang and Headers

```bash
#!/usr/bin/env bash
#################################################
#                                               #
#     Script Name and Description               #
#                                               #
#################################################
# Version: 1.0.0
# Last Updated: YYYY-MM-DD
# Author: Your Name
```

#### 2. Error Handling

Always use strict error handling:

```bash
set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Set up cleanup trap
trap cleanup_on_exit EXIT
```

#### 3. Functions

- Use descriptive function names
- Add comments explaining what the function does
- Validate inputs
- Use `local` for function variables

```bash
# Install package using detected package manager
# Usage: install_package <package_name>
install_package() {
    local package="$1"
    local pkg_mgr

    if [ -z "$package" ]; then
        print_error "Package name required"
        return 1
    fi

    pkg_mgr=$(get_package_manager)

    print_info "Installing $package using $pkg_mgr"

    case "$pkg_mgr" in
        dnf|yum)
            $pkg_mgr install -y "$package"
            ;;
        apt)
            apt-get install -y "$package"
            ;;
        *)
            print_error "Unsupported package manager: $pkg_mgr"
            return 1
            ;;
    esac
}
```

#### 4. Variable Naming

- `UPPERCASE` for constants and environment variables
- `lowercase` for local variables
- Meaningful names, not abbreviations

```bash
# Good
readonly BACKUP_DIR="/backups"
local source_directory="/etc"

# Bad
readonly BD="/backups"
local sd="/etc"
```

#### 5. Quoting

Always quote variables unless you specifically need word splitting:

```bash
# Good
if [ -f "$config_file" ]; then
    source "$config_file"
fi

# Bad
if [ -f $config_file ]; then
    source $config_file
fi
```

#### 6. Use Common Library Functions

Leverage the common library instead of duplicating code:

```bash
# Good
require_root
validate_domain "$domain"
log_info "Starting installation"

# Bad
if [[ $EUID -ne 0 ]]; then
    echo "Must be root"
    exit 1
fi
```

### Python Scripts

#### 1. Style Guide

Follow PEP 8 and use type hints:

```python
#!/usr/bin/env python3
"""
Module description.
"""
import argparse
from typing import Dict, List, Optional


def process_data(input_data: List[str], options: Optional[Dict] = None) -> List[str]:
    """
    Process input data according to options.

    Args:
        input_data: List of strings to process
        options: Optional configuration dictionary

    Returns:
        Processed list of strings
    """
    if options is None:
        options = {}

    # Implementation
    return processed_data
```

#### 2. Use Modern Python

- Python 3.9+ features
- Type hints everywhere
- Dataclasses for data structures
- f-strings for formatting

#### 3. Error Handling

```python
import sys
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

try:
    result = risky_operation()
except SpecificException as e:
    logger.error(f"Operation failed: {e}")
    sys.exit(1)
```

## Testing

### Shell Script Testing with BATS

Create test files in `tests/` directory:

```bash
#!/usr/bin/env bats

# tests/test_common.sh

load test_helper

@test "detect_os returns valid os family" {
    source lib/common.sh

    result=$(detect_os)

    [[ "$result" =~ ^(rhel|debian|arch|unknown)$ ]]
}

@test "validate_ip accepts valid IP" {
    source lib/common.sh

    run validate_ip "192.168.1.1"

    [ "$status" -eq 0 ]
}

@test "validate_ip rejects invalid IP" {
    source lib/common.sh

    run validate_ip "999.999.999.999"

    [ "$status" -eq 1 ]
}
```

Run tests:

```bash
bats tests/test_common.sh
```

### Python Testing with pytest

```python
# tests/test_python.py

import pytest
from python.port_check import check_port


def test_check_port_valid():
    result = check_port("localhost", 22, timeout=1)
    assert isinstance(result, dict)
    assert "open" in result


def test_check_port_invalid_port():
    with pytest.raises(ValueError):
        check_port("localhost", 99999)
```

Run tests:

```bash
pytest tests/test_python.py -v
```

## Submitting Changes

### Commit Messages

Follow conventional commit format:

```
type(scope): subject

body

footer
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Formatting changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

Example:

```
feat(backup): add S3 support for remote backups

- Implement S3 upload functionality
- Add AWS credentials configuration
- Update backup.conf.example with S3 options

Closes #123
```

### Pull Request Process

1. **Update documentation** if adding features
2. **Add tests** for new functionality
3. **Run linters**:
   ```bash
   shellcheck installation_scripts/*.sh
   black python/*.py
   flake8 python/*.py
   ```
4. **Run tests**:
   ```bash
   bats tests/*.sh
   pytest tests/
   ```
5. **Update CHANGELOG.md** with your changes
6. **Request review** from maintainers

### Code Review

All submissions require review. Reviewers will check:

- Code quality and style
- Test coverage
- Documentation completeness
- Security implications
- Backward compatibility

## Questions?

If you have questions:

- Check existing documentation
- Search existing issues
- Create a new issue with your question
- Join our community discussions

Thank you for contributing!
