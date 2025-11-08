#!/usr/bin/env bash
set -euo pipefail

#################################################
#                                               #
#     Web Page Downloader                       #
#     Multi-method with retry and mirroring     #
#                                               #
#################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Setup
trap cleanup_on_exit EXIT

# Configuration
URL="${1:-}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-webpages}"
METHOD="${METHOD:-auto}"  # auto, wget, curl, aria2
RETRY_COUNT="${RETRY_COUNT:-3}"
RETRY_DELAY="${RETRY_DELAY:-5}"
TIMEOUT="${TIMEOUT:-30}"
USER_AGENT="${USER_AGENT:-Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36}"
FOLLOW_REDIRECTS="${FOLLOW_REDIRECTS:-yes}"
RECURSIVE="${RECURSIVE:-no}"
RECURSIVE_DEPTH="${RECURSIVE_DEPTH:-1}"
CONVERT_LINKS="${CONVERT_LINKS:-no}"
MIRROR_MODE="${MIRROR_MODE:-no}"
AUTH_USER="${AUTH_USER:-}"
AUTH_PASS="${AUTH_PASS:-}"
RATE_LIMIT="${RATE_LIMIT:-}"  # e.g., 100k, 1m
RESUME="${RESUME:-yes}"

print_header "Web Page Downloader"

# Validate parameters
validate_params() {
    if [[ -z "$URL" ]]; then
        error_exit "Usage: $0 <url> [options]

Examples:
  $0 https://example.com                           # Download single page
  $0 https://example.com/page.html                 # Download specific page
  METHOD=curl $0 https://example.com               # Use curl instead of wget
  RECURSIVE=yes RECURSIVE_DEPTH=2 $0 https://...   # Download site (depth 2)
  MIRROR_MODE=yes $0 https://example.com           # Mirror entire site
  RATE_LIMIT=100k $0 https://example.com           # Limit download speed
  AUTH_USER=admin AUTH_PASS=secret $0 https://...  # Basic authentication

Download Methods:
  auto    - Auto-detect best available tool (default)
  wget    - Use wget
  curl    - Use curl
  aria2   - Use aria2c (if installed)

Options (environment variables):
  DOWNLOAD_DIR=path          # Download directory (default: webpages)
  METHOD=auto|wget|curl      # Download method (default: auto)
  RETRY_COUNT=N              # Retry attempts (default: 3)
  RETRY_DELAY=N              # Delay between retries in seconds (default: 5)
  TIMEOUT=N                  # Connection timeout in seconds (default: 30)
  USER_AGENT=string          # Custom user agent
  FOLLOW_REDIRECTS=yes|no    # Follow HTTP redirects (default: yes)
  RECURSIVE=yes|no           # Download recursively (default: no)
  RECURSIVE_DEPTH=N          # Recursion depth (default: 1)
  CONVERT_LINKS=yes|no       # Convert links for offline viewing (default: no)
  MIRROR_MODE=yes|no         # Mirror mode (default: no)
  AUTH_USER=username         # HTTP basic auth username
  AUTH_PASS=password         # HTTP basic auth password
  RATE_LIMIT=speed           # Rate limit (e.g., 100k, 1m)
  RESUME=yes|no              # Resume partial downloads (default: yes)"
    fi

    # Validate URL format
    if ! [[ "$URL" =~ ^https?:// ]]; then
        error_exit "Invalid URL format: $URL (must start with http:// or https://)"
    fi

    print_info "URL: $URL"
    print_info "Download directory: $DOWNLOAD_DIR"
    print_info "Method: $METHOD"
    print_info "Retry count: $RETRY_COUNT"
    echo
}

# Detect best download method
detect_method() {
    if [ "$METHOD" != "auto" ]; then
        return 0
    fi

    # Priority: wget > curl > aria2
    if command_exists wget; then
        METHOD="wget"
    elif command_exists curl; then
        METHOD="curl"
    elif command_exists aria2c; then
        METHOD="aria2"
    else
        error_exit "No download tool found. Install wget, curl, or aria2c"
    fi

    print_info "Auto-detected method: $METHOD"
}

# Create download directory
create_download_dir() {
    if [ ! -d "$DOWNLOAD_DIR" ]; then
        mkdir -p "$DOWNLOAD_DIR"
        print_success "Created download directory: $DOWNLOAD_DIR"
    fi
}

# Generate filename from URL
generate_filename() {
    local url="$1"

    # Remove trailing slashes
    url="${url%/}"

    # Extract last part of URL path
    local filename=$(echo "$url" | sed 's#.*/##')

    # If no filename or looks like a directory, use index.html
    if [ -z "$filename" ] || [[ "$filename" =~ ^[a-z]+:$ ]]; then
        filename="index.html"
    fi

    # Add .html extension if no extension present
    if [[ ! "$filename" =~ \.[a-zA-Z0-9]+$ ]]; then
        filename="${filename}.html"
    fi

    echo "$filename"
}

# Download with wget
download_wget() {
    local url="$1"
    local output_file="$2"

    local wget_opts=(
        -q                      # Quiet mode
        --show-progress         # Show progress bar
        -O "$output_file"       # Output file
        --timeout="$TIMEOUT"    # Timeout
        --tries="$RETRY_COUNT"  # Retry count
        --waitretry="$RETRY_DELAY"  # Wait between retries
        --user-agent="$USER_AGENT"  # User agent
    )

    # Follow redirects
    if [ "$FOLLOW_REDIRECTS" = "yes" ]; then
        wget_opts+=(--max-redirect=10)
    else
        wget_opts+=(--max-redirect=0)
    fi

    # Resume
    if [ "$RESUME" = "yes" ]; then
        wget_opts+=(-c)
    fi

    # Rate limit
    if [ -n "$RATE_LIMIT" ]; then
        wget_opts+=(--limit-rate="$RATE_LIMIT")
    fi

    # Authentication
    if [ -n "$AUTH_USER" ]; then
        wget_opts+=(--user="$AUTH_USER")
        if [ -n "$AUTH_PASS" ]; then
            wget_opts+=(--password="$AUTH_PASS")
        fi
    fi

    # Recursive options
    if [ "$RECURSIVE" = "yes" ] || [ "$MIRROR_MODE" = "yes" ]; then
        wget_opts=(
            -r                          # Recursive
            -l "$RECURSIVE_DEPTH"       # Depth
            -P "$DOWNLOAD_DIR"          # Directory prefix
            --timeout="$TIMEOUT"
            --tries="$RETRY_COUNT"
            --waitretry="$RETRY_DELAY"
            --user-agent="$USER_AGENT"
        )

        if [ "$MIRROR_MODE" = "yes" ]; then
            wget_opts+=(
                -m                      # Mirror mode
                -p                      # Page requisites
                -k                      # Convert links
                -E                      # Adjust extensions
                --restrict-file-names=windows  # Safe filenames
            )
        elif [ "$CONVERT_LINKS" = "yes" ]; then
            wget_opts+=(-k)             # Convert links
        fi

        if [ -n "$RATE_LIMIT" ]; then
            wget_opts+=(--limit-rate="$RATE_LIMIT")
        fi

        wget "${wget_opts[@]}" "$url"
        return $?
    fi

    # Execute wget
    wget "${wget_opts[@]}" "$url"
}

# Download with curl
download_curl() {
    local url="$1"
    local output_file="$2"

    local curl_opts=(
        -f                          # Fail on HTTP errors
        -L                          # Follow redirects
        -o "$output_file"           # Output file
        --connect-timeout "$TIMEOUT"  # Connection timeout
        --max-time $((TIMEOUT * 2))   # Max time
        --retry "$RETRY_COUNT"      # Retry count
        --retry-delay "$RETRY_DELAY"  # Retry delay
        -A "$USER_AGENT"            # User agent
        --progress-bar              # Progress bar
    )

    # Don't follow redirects if disabled
    if [ "$FOLLOW_REDIRECTS" != "yes" ]; then
        curl_opts=("${curl_opts[@]//-L/}")
    fi

    # Resume
    if [ "$RESUME" = "yes" ]; then
        curl_opts+=(-C -)
    fi

    # Rate limit
    if [ -n "$RATE_LIMIT" ]; then
        curl_opts+=(--limit-rate "$RATE_LIMIT")
    fi

    # Authentication
    if [ -n "$AUTH_USER" ]; then
        if [ -n "$AUTH_PASS" ]; then
            curl_opts+=(-u "${AUTH_USER}:${AUTH_PASS}")
        else
            curl_opts+=(-u "${AUTH_USER}")
        fi
    fi

    # Execute curl
    curl "${curl_opts[@]}" "$url"
}

# Download with aria2
download_aria2() {
    local url="$1"
    local output_file="$2"

    local aria2_opts=(
        -o "$(basename "$output_file")"  # Output filename
        -d "$(dirname "$output_file")"   # Output directory
        --timeout="$TIMEOUT"
        --max-tries="$RETRY_COUNT"
        --retry-wait="$RETRY_DELAY"
        --user-agent="$USER_AGENT"
        --allow-overwrite=true
        --auto-file-renaming=false
    )

    # Follow redirects
    if [ "$FOLLOW_REDIRECTS" = "yes" ]; then
        aria2_opts+=(--max-redirect=10)
    else
        aria2_opts+=(--max-redirect=0)
    fi

    # Resume
    if [ "$RESUME" = "yes" ]; then
        aria2_opts+=(--continue=true)
    fi

    # Rate limit
    if [ -n "$RATE_LIMIT" ]; then
        aria2_opts+=(--max-download-limit="$RATE_LIMIT")
    fi

    # Authentication
    if [ -n "$AUTH_USER" ]; then
        if [ -n "$AUTH_PASS" ]; then
            aria2_opts+=(--http-user="$AUTH_USER" --http-passwd="$AUTH_PASS")
        else
            aria2_opts+=(--http-user="$AUTH_USER")
        fi
    fi

    # Execute aria2c
    aria2c "${aria2_opts[@]}" "$url"
}

# Download file
download_file() {
    local url="$1"
    local output_file="$2"

    print_header "Downloading file"
    print_info "Method: $METHOD"
    print_info "Output: $output_file"

    local start_time=$(date +%s)

    case "$METHOD" in
        wget)
            if ! command_exists wget; then
                error_exit "wget not found. Install wget or use METHOD=curl"
            fi
            download_wget "$url" "$output_file"
            ;;
        curl)
            if ! command_exists curl; then
                error_exit "curl not found. Install curl or use METHOD=wget"
            fi
            download_curl "$url" "$output_file"
            ;;
        aria2)
            if ! command_exists aria2c; then
                error_exit "aria2c not found. Install aria2 or use METHOD=wget"
            fi
            download_aria2 "$url" "$output_file"
            ;;
        *)
            error_exit "Invalid download method: $METHOD"
            ;;
    esac

    local exit_code=$?
    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))

    if [ $exit_code -eq 0 ]; then
        print_success "Download completed in ${elapsed}s"
        return 0
    else
        print_warning "Download failed with exit code: $exit_code"
        return $exit_code
    fi
}

# Verify download
verify_download() {
    local output_file="$1"

    if [ ! -f "$output_file" ]; then
        error_exit "Downloaded file not found: $output_file"
    fi

    local file_size=$(du -h "$output_file" | awk '{print $1}')
    print_info "File size: $file_size"

    # Check if file is empty
    if [ ! -s "$output_file" ]; then
        print_warning "Downloaded file is empty"
        return 1
    fi

    # Check if it's an HTML error page
    if command_exists file; then
        local file_type=$(file -b "$output_file")
        print_info "File type: $file_type"
    fi

    print_success "Download verified"
}

# Display summary
display_summary() {
    local output_file="$1"

    print_header "Download Complete"

    print_success "File downloaded successfully!"
    echo

    print_info "Details:"
    print_info "  URL: $URL"
    print_info "  Output file: $output_file"

    if [ -f "$output_file" ]; then
        local file_size=$(du -h "$output_file" | awk '{print $1}')
        print_info "  File size: $file_size"

        if command_exists file; then
            local file_type=$(file -b "$output_file")
            print_info "  File type: $file_type"
        fi
    fi

    echo
    print_info "View file: cat $output_file"
    print_info "Open in browser: open $output_file"

    log_success "Downloaded: $URL -> $output_file"
}

# Main execution
main() {
    validate_params
    detect_method
    create_download_dir

    # Generate output filename
    local filename=$(generate_filename "$URL")
    local output_file="${DOWNLOAD_DIR}/${filename}"

    # Check for mirror mode
    if [ "$MIRROR_MODE" = "yes" ] || [ "$RECURSIVE" = "yes" ]; then
        print_info "Recursive/mirror mode enabled"
        download_file "$URL" "$output_file"
        print_success "Recursive download completed to: $DOWNLOAD_DIR"
        log_success "Mirrored: $URL -> $DOWNLOAD_DIR"
        return 0
    fi

    # Download the file
    if download_file "$URL" "$output_file"; then
        verify_download "$output_file"
        display_summary "$output_file"
    else
        error_exit "Download failed after $RETRY_COUNT attempts"
    fi
}

# Run main
main
