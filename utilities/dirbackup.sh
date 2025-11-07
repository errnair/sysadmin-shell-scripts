#!/usr/bin/env bash
set -euo pipefail

#################################################
#                                               #
#     Directory Backup Utility                  #
#     Multi-OS with encryption and retention    #
#                                               #
#################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Setup
trap cleanup_on_exit EXIT
require_root

# Configuration
SOURCE_DIR="${1:-}"
BACKUP_DIR="${BACKUP_DIR:-/backups}"
COMPRESSION="${COMPRESSION:-gz}"  # gz, bz2, xz, or none
COMPRESSION_LEVEL="${COMPRESSION_LEVEL:-6}"  # 1-9
ENCRYPT="${ENCRYPT:-no}"
ENCRYPT_PASSWORD="${ENCRYPT_PASSWORD:-}"
VERIFY="${VERIFY:-yes}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"  # Keep backups for N days
INCREMENTAL="${INCREMENTAL:-no}"
EXCLUDE_PATTERNS="${EXCLUDE_PATTERNS:-}"
EMAIL_NOTIFY="${EMAIL_NOTIFY:-}"
BACKUP_TYPE="${BACKUP_TYPE:-full}"  # full or incremental

print_header "Directory Backup Utility"

# Detect OS
OS=$(detect_os)

print_info "Detected OS: $OS"
echo

# Validate parameters
validate_params() {
    if [[ -z "$SOURCE_DIR" ]]; then
        error_exit "Usage: $0 <source-directory> [options]

Examples:
  $0 /etc                                    # Backup /etc
  BACKUP_DIR=/mnt/backups $0 /var/www       # Custom backup location
  COMPRESSION=xz $0 /home                   # Use xz compression
  ENCRYPT=yes $0 /etc                       # Encrypt backup
  RETENTION_DAYS=7 $0 /data                 # Keep backups for 7 days
  EXCLUDE_PATTERNS='*.log,*.tmp' $0 /var    # Exclude patterns

Options (environment variables):
  BACKUP_DIR=/path           # Backup destination (default: /backups)
  COMPRESSION=gz|bz2|xz|none # Compression type (default: gz)
  COMPRESSION_LEVEL=1-9      # Compression level (default: 6)
  ENCRYPT=yes|no             # Encrypt backup (default: no)
  VERIFY=yes|no              # Verify backup (default: yes)
  RETENTION_DAYS=N           # Keep backups for N days (default: 30)
  INCREMENTAL=yes|no         # Incremental backup (default: no)
  EXCLUDE_PATTERNS='*.ext'   # Comma-separated patterns to exclude
  EMAIL_NOTIFY=email@addr    # Email notification address"
    fi

    # Validate source directory exists
    if [ ! -d "$SOURCE_DIR" ]; then
        error_exit "Source directory does not exist: $SOURCE_DIR"
    fi

    # Get absolute path
    SOURCE_DIR=$(realpath "$SOURCE_DIR")

    print_info "Source directory: $SOURCE_DIR"
    print_info "Backup directory: $BACKUP_DIR"
    print_info "Compression: $COMPRESSION"
    print_info "Encryption: $ENCRYPT"
    print_info "Verification: $VERIFY"
    print_info "Retention: $RETENTION_DAYS days"
    [ "$INCREMENTAL" = "yes" ] && print_info "Backup type: incremental"
    echo
}

# Create backup directory
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        print_header "Creating backup directory"
        mkdir -p "$BACKUP_DIR"
        print_success "Created backup directory: $BACKUP_DIR"
    fi
}

# Generate backup filename
generate_backup_filename() {
    local source_basename=$(basename "$SOURCE_DIR")
    local hostname=$(hostname -s)
    local timestamp=$(date +%Y%m%d_%H%M%S)

    local extension=""
    case "$COMPRESSION" in
        gz)
            extension=".tar.gz"
            ;;
        bz2)
            extension=".tar.bz2"
            ;;
        xz)
            extension=".tar.xz"
            ;;
        none)
            extension=".tar"
            ;;
    esac

    if [ "$INCREMENTAL" = "yes" ]; then
        echo "${BACKUP_DIR}/${source_basename}-${hostname}-${timestamp}-incremental${extension}"
    else
        echo "${BACKUP_DIR}/${source_basename}-${hostname}-${timestamp}${extension}"
    fi
}

# Build tar exclude options
build_exclude_options() {
    local exclude_opts=""

    if [ -n "$EXCLUDE_PATTERNS" ]; then
        # Split by comma and build --exclude options
        IFS=',' read -ra PATTERNS <<< "$EXCLUDE_PATTERNS"
        for pattern in "${PATTERNS[@]}"; do
            exclude_opts="$exclude_opts --exclude='$pattern'"
        done
    fi

    echo "$exclude_opts"
}

# Create full backup
create_full_backup() {
    print_header "Creating full backup"

    local backup_file="$1"
    local exclude_opts=$(build_exclude_options)

    print_info "Backup file: $backup_file"
    print_info "Source: $SOURCE_DIR"

    # Build tar command based on compression
    local tar_cmd="tar"
    local tar_opts="-c"

    # Add compression flag
    case "$COMPRESSION" in
        gz)
            tar_opts="${tar_opts}z"
            ;;
        bz2)
            tar_opts="${tar_opts}j"
            ;;
        xz)
            tar_opts="${tar_opts}J"
            ;;
    esac

    # Add verbose and file options
    tar_opts="${tar_opts}f"

    # Execute backup with progress
    print_info "Creating backup archive..."
    eval "$tar_cmd $tar_opts \"$backup_file\" $exclude_opts -C \"$(dirname \"$SOURCE_DIR\")\" \"$(basename \"$SOURCE_DIR\")\"" 2>&1 | while read line; do
        echo "  $line"
    done

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        print_success "Backup created successfully"
    else
        error_exit "Backup creation failed"
    fi

    # Log to syslog
    logger "Backed up $SOURCE_DIR to $backup_file"
}

# Create incremental backup using rsync
create_incremental_backup() {
    print_header "Creating incremental backup"

    if ! command_exists rsync; then
        print_warning "rsync not found, falling back to full backup"
        create_full_backup "$1"
        return
    fi

    local backup_file="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local source_basename=$(basename "$SOURCE_DIR")
    local rsync_dir="${BACKUP_DIR}/rsync-${source_basename}"
    local snapshot_dir="${rsync_dir}/snapshot-${timestamp}"

    # Create rsync directory structure
    mkdir -p "$rsync_dir"

    # Find latest snapshot for hard linking
    local latest_snapshot=$(find "$rsync_dir" -maxdepth 1 -type d -name "snapshot-*" 2>/dev/null | sort -r | head -1)

    print_info "Creating incremental snapshot..."

    # Build exclude options for rsync
    local exclude_opts=""
    if [ -n "$EXCLUDE_PATTERNS" ]; then
        IFS=',' read -ra PATTERNS <<< "$EXCLUDE_PATTERNS"
        for pattern in "${PATTERNS[@]}"; do
            exclude_opts="$exclude_opts --exclude='$pattern'"
        done
    fi

    # Run rsync with hard links to previous snapshot
    if [ -n "$latest_snapshot" ]; then
        print_info "Linking against: $(basename \"$latest_snapshot\")"
        eval "rsync -a --delete --link-dest=\"$latest_snapshot\" $exclude_opts \"$SOURCE_DIR/\" \"$snapshot_dir/\""
    else
        print_info "Creating first snapshot"
        eval "rsync -a $exclude_opts \"$SOURCE_DIR/\" \"$snapshot_dir/\""
    fi

    # Create compressed archive of the snapshot
    print_info "Compressing snapshot..."
    create_full_backup "$backup_file"

    print_success "Incremental backup created"
}

# Encrypt backup
encrypt_backup() {
    if [ "$ENCRYPT" != "yes" ]; then
        return 0
    fi

    print_header "Encrypting backup"

    if ! command_exists gpg; then
        print_warning "gpg not found, skipping encryption"
        return 0
    fi

    local backup_file="$1"

    # Get password if not provided
    if [ -z "$ENCRYPT_PASSWORD" ]; then
        read_password "Enter encryption password" ENCRYPT_PASSWORD
    fi

    print_info "Encrypting with GPG..."

    # Encrypt file
    echo "$ENCRYPT_PASSWORD" | gpg --batch --yes --passphrase-fd 0 \
        --symmetric --cipher-algo AES256 -o "${backup_file}.gpg" "$backup_file"

    if [ $? -eq 0 ]; then
        # Remove unencrypted file
        rm -f "$backup_file"
        print_success "Backup encrypted: ${backup_file}.gpg"
        echo "${backup_file}.gpg"
    else
        error_exit "Encryption failed"
    fi
}

# Verify backup
verify_backup() {
    if [ "$VERIFY" != "yes" ]; then
        return 0
    fi

    print_header "Verifying backup"

    local backup_file="$1"

    # Check if file exists
    if [ ! -f "$backup_file" ]; then
        print_warning "Backup file not found: $backup_file"
        return 1
    fi

    # Get file size
    local file_size=$(du -h "$backup_file" | awk '{print $1}')
    print_info "Backup size: $file_size"

    # Verify tar archive (if not encrypted)
    if [[ ! "$backup_file" == *.gpg ]]; then
        print_info "Testing archive integrity..."

        case "$backup_file" in
            *.tar.gz)
                tar -tzf "$backup_file" > /dev/null 2>&1
                ;;
            *.tar.bz2)
                tar -tjf "$backup_file" > /dev/null 2>&1
                ;;
            *.tar.xz)
                tar -tJf "$backup_file" > /dev/null 2>&1
                ;;
            *.tar)
                tar -tf "$backup_file" > /dev/null 2>&1
                ;;
        esac

        if [ $? -eq 0 ]; then
            print_success "Backup verification successful"
        else
            print_warning "Backup verification failed"
            return 1
        fi
    else
        print_info "Skipping archive test for encrypted file"
        print_success "Backup file exists and has size: $file_size"
    fi

    # Calculate and display checksum
    if command_exists sha256sum; then
        local checksum=$(sha256sum "$backup_file" | awk '{print $1}')
        print_info "SHA256: $checksum"

        # Save checksum to file
        echo "$checksum  $backup_file" > "${backup_file}.sha256"
        print_info "Checksum saved to: ${backup_file}.sha256"
    fi
}

# Apply retention policy
apply_retention() {
    if [ "$RETENTION_DAYS" -eq 0 ]; then
        print_info "Retention policy disabled (RETENTION_DAYS=0)"
        return 0
    fi

    print_header "Applying retention policy"

    print_info "Removing backups older than $RETENTION_DAYS days..."

    local source_basename=$(basename "$SOURCE_DIR")
    local hostname=$(hostname -s)
    local deleted_count=0

    # Find and delete old backups
    while IFS= read -r -d '' file; do
        rm -f "$file"
        rm -f "${file}.sha256"  # Also remove checksum file
        print_info "Deleted: $(basename \"$file\")"
        ((deleted_count++))
    done < <(find "$BACKUP_DIR" -maxdepth 1 -type f \
        -name "${source_basename}-${hostname}-*.tar*" \
        -mtime +"$RETENTION_DAYS" -print0 2>/dev/null)

    if [ $deleted_count -gt 0 ]; then
        print_success "Removed $deleted_count old backup(s)"
    else
        print_info "No old backups to remove"
    fi

    # Show remaining backups
    local remaining=$(find "$BACKUP_DIR" -maxdepth 1 -type f -name "${source_basename}-${hostname}-*.tar*" 2>/dev/null | wc -l)
    print_info "Current backups: $remaining"
}

# Send email notification
send_email_notification() {
    if [ -z "$EMAIL_NOTIFY" ]; then
        return 0
    fi

    if ! command_exists mail && ! command_exists sendmail; then
        print_warning "mail/sendmail not found, skipping email notification"
        return 0
    fi

    print_header "Sending email notification"

    local backup_file="$1"
    local status="$2"
    local hostname=$(hostname -f)
    local file_size=$(du -h "$backup_file" | awk '{print $1}')

    local subject="Backup $status: $SOURCE_DIR on $hostname"
    local body="Backup Details:
Source: $SOURCE_DIR
Destination: $backup_file
Size: $file_size
Status: $status
Time: $(date)
Hostname: $hostname
Compression: $COMPRESSION
Encrypted: $ENCRYPT
"

    if command_exists mail; then
        echo "$body" | mail -s "$subject" "$EMAIL_NOTIFY"
    elif command_exists sendmail; then
        {
            echo "Subject: $subject"
            echo "To: $EMAIL_NOTIFY"
            echo ""
            echo "$body"
        } | sendmail "$EMAIL_NOTIFY"
    fi

    print_success "Email sent to: $EMAIL_NOTIFY"
}

# Display summary
display_summary() {
    print_header "Backup Complete"

    local backup_file="$1"
    local file_size=$(du -h "$backup_file" | awk '{print $1}')

    print_success "Backup completed successfully!"
    echo

    print_info "Backup Details:"
    print_info "  Source: $SOURCE_DIR"
    print_info "  Backup file: $backup_file"
    print_info "  Size: $file_size"
    print_info "  Compression: $COMPRESSION"
    print_info "  Encrypted: $ENCRYPT"
    print_info "  Retention: $RETENTION_DAYS days"
    echo

    print_info "To restore this backup:"
    if [[ "$backup_file" == *.gpg ]]; then
        print_info "  1. Decrypt: gpg -o backup.tar.gz -d \"$backup_file\""
        print_info "  2. Extract: tar -xzf backup.tar.gz -C /restore/path"
    else
        case "$backup_file" in
            *.tar.gz)
                print_info "  tar -xzf \"$backup_file\" -C /restore/path"
                ;;
            *.tar.bz2)
                print_info "  tar -xjf \"$backup_file\" -C /restore/path"
                ;;
            *.tar.xz)
                print_info "  tar -xJf \"$backup_file\" -C /restore/path"
                ;;
            *.tar)
                print_info "  tar -xf \"$backup_file\" -C /restore/path"
                ;;
        esac
    fi
    echo

    print_info "Verify backup:"
    if [ -f "${backup_file}.sha256" ]; then
        print_info "  sha256sum -c \"${backup_file}.sha256\""
    fi

    log_success "Backup completed: $SOURCE_DIR -> $backup_file"
}

# Main execution
main() {
    local start_time=$(date +%s)

    validate_params
    create_backup_dir

    # Generate backup filename
    local backup_file=$(generate_backup_filename)

    # Create backup
    if [ "$INCREMENTAL" = "yes" ]; then
        create_incremental_backup "$backup_file"
    else
        create_full_backup "$backup_file"
    fi

    # Encrypt if requested
    if [ "$ENCRYPT" = "yes" ]; then
        backup_file=$(encrypt_backup "$backup_file")
    fi

    # Verify backup
    verify_backup "$backup_file"

    # Apply retention policy
    apply_retention

    # Calculate elapsed time
    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    print_info "Elapsed time: ${elapsed}s"

    # Send notification
    send_email_notification "$backup_file" "SUCCESS"

    # Display summary
    display_summary "$backup_file"
}

# Run main
main
