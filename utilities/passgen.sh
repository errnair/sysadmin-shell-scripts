#!/usr/bin/env bash
set -euo pipefail

#################################################
#                                               #
#     Secure Password Generator                 #
#     Multi-method with strength validation     #
#                                               #
#################################################

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Setup
trap cleanup_on_exit EXIT

# Configuration
PASSWORD_COUNT="${1:-1}"
PASSWORD_LENGTH="${2:-16}"
PASSWORD_TYPE="${PASSWORD_TYPE:-alphanumeric}"  # alphanumeric, special, passphrase, pin
AVOID_AMBIGUOUS="${AVOID_AMBIGUOUS:-no}"
SHOW_STRENGTH="${SHOW_STRENGTH:-yes}"
COPY_TO_CLIPBOARD="${COPY_TO_CLIPBOARD:-no}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-text}"  # text, csv, json

print_header "Secure Password Generator"

# Validate parameters
validate_params() {
    # Validate count
    if ! [[ "$PASSWORD_COUNT" =~ ^[0-9]+$ ]] || [ "$PASSWORD_COUNT" -lt 1 ]; then
        error_exit "Invalid password count: $PASSWORD_COUNT (must be positive integer)

Usage: $0 [count] [length] [options]

Examples:
  $0                                    # Generate 1 password, 16 chars
  $0 5                                  # Generate 5 passwords, 16 chars
  $0 1 32                               # Generate 1 password, 32 chars
  PASSWORD_TYPE=special $0 10 20        # 10 passwords with special chars
  PASSWORD_TYPE=passphrase $0 5         # 5 passphrases (diceware-style)
  PASSWORD_TYPE=pin $0 1 6              # 6-digit PIN
  AVOID_AMBIGUOUS=yes $0 10             # Avoid similar characters (0/O, 1/l)
  OUTPUT_FORMAT=csv $0 10               # CSV output for import

Password Types:
  alphanumeric  - Letters and numbers only (default)
  special       - Letters, numbers, and special characters
  passphrase    - Memorable word-based passphrase
  pin           - Numeric PIN code

Options (environment variables):
  PASSWORD_TYPE=type         # Password type (see above)
  AVOID_AMBIGUOUS=yes|no     # Avoid 0/O, 1/l/I (default: no)
  SHOW_STRENGTH=yes|no       # Show password strength (default: yes)
  COPY_TO_CLIPBOARD=yes|no   # Copy to clipboard (default: no)
  OUTPUT_FORMAT=text|csv|json # Output format (default: text)"
    fi

    # Validate length
    if ! [[ "$PASSWORD_LENGTH" =~ ^[0-9]+$ ]] || [ "$PASSWORD_LENGTH" -lt 4 ]; then
        error_exit "Invalid password length: $PASSWORD_LENGTH (must be >= 4)"
    fi

    if [ "$PASSWORD_LENGTH" -gt 128 ]; then
        error_exit "Invalid password length: $PASSWORD_LENGTH (max: 128)"
    fi

    print_info "Generating $PASSWORD_COUNT password(s) of length $PASSWORD_LENGTH"
    print_info "Password type: $PASSWORD_TYPE"
    echo
}

# Generate alphanumeric password
generate_alphanumeric() {
    local length="$1"
    local charset="a-zA-Z0-9"

    if [ "$AVOID_AMBIGUOUS" = "yes" ]; then
        # Avoid 0, O, 1, l, I
        tr -dc 'a-km-zA-HJ-NP-Z2-9' < /dev/urandom | head -c "$length"
    else
        tr -dc "$charset" < /dev/urandom | head -c "$length"
    fi
}

# Generate password with special characters
generate_special() {
    local length="$1"
    local charset='A-Za-z0-9!@#$%^&*()_+-=[]{}|;:,.<>?'

    if [ "$AVOID_AMBIGUOUS" = "yes" ]; then
        # Avoid 0, O, 1, l, I and similar special chars
        charset='A-HJ-NP-Za-km-z2-9!@#$%^&*()_+-=[]{}|;:,.<>?'
    fi

    tr -dc "$charset" < /dev/urandom | head -c "$length"
}

# Generate passphrase (diceware-style)
generate_passphrase() {
    local word_count="${1:-5}"
    local words=()

    # Common word list (subset for demonstration)
    local wordlist=(
        able about above accept across action activity add address admit
        adult affect after again against age agency agent agree air
        allow almost alone along already also although always amazing
        among amount analysis analyze ancient animal answer anyone anything
        appear apply approach area argue arise arm army around arrive
        artist ask assume attack attempt attend attention author available
        avoid away baby back bad bag ball bank bar base basic
        beach bear beautiful because become before begin behind believe
        benefit best better between beyond billion bird black block
        blood blue board boat body book border born both bottom
        box boy brain break bring brother budget build building built
        burn business buy call camera campaign can cancer candidate
        capital car card care career carry case catch cause cell
        center central century certain challenge chance change character
        charge check child choice choose church citizen city civil
        claim class clear close coach cold collection college color
        come common community company compare computer concern condition
        conference congress consider consumer contain continue control
        cost could country couple course court cover create crime
        cultural culture cup current customer cut dark data daughter
        day dead deal death debate decade decide decision deep
        defense degree democrat democratic describe design despite detail
        determine develop development die difference different difficult
        dinner direction director discover discuss disease do doctor
        dog door down draw dream drive drop drug during each
        early east easy eat economic economy edge education effect
        effort eight either election else employee end energy enjoy
        enough enter entire environment environmental equal especially
        establish even evening event ever every everybody everyone
        everything evidence exactly example executive exist expect
        experience expert explain eye face fact factor fail fall
        family far fast father fear federal feel feeling few
        field fight figure fill film final finally financial find
        fine finger finish fire firm first fish five floor
        fly focus follow food foot for force foreign forget
        form former forward four free friend from front full
        fund future game garden gas general generation get girl
        give glass go goal good government great green ground
        group grow growth guess gun guy hair half hand
        hang happen happy hard have he head health hear
        heart heat heavy help her here herself high him
        himself his history hit hold home hope hospital hot
        hotel hour house how however huge human hundred husband
    )

    # Generate random words
    for ((i=0; i<word_count; i++)); do
        local idx=$((RANDOM % ${#wordlist[@]}))
        words+=("${wordlist[$idx]}")
    done

    # Join with hyphens
    local IFS='-'
    echo "${words[*]}"
}

# Generate PIN
generate_pin() {
    local length="$1"
    tr -dc '0-9' < /dev/urandom | head -c "$length"
}

# Calculate password entropy
calculate_entropy() {
    local password="$1"
    local length=${#password}
    local charset_size=0

    # Determine character set size
    if [[ "$password" =~ [a-z] ]]; then
        charset_size=$((charset_size + 26))
    fi
    if [[ "$password" =~ [A-Z] ]]; then
        charset_size=$((charset_size + 26))
    fi
    if [[ "$password" =~ [0-9] ]]; then
        charset_size=$((charset_size + 10))
    fi
    if [[ "$password" =~ [^a-zA-Z0-9] ]]; then
        charset_size=$((charset_size + 32))  # Approximate special chars
    fi

    # Entropy = log2(charset_size^length)
    # Using bc for floating point
    if command_exists bc; then
        echo "scale=2; $length * l($charset_size) / l(2)" | bc -l
    else
        # Approximate without bc
        echo "$((length * 6))"  # Rough estimate
    fi
}

# Assess password strength
assess_strength() {
    local password="$1"
    local entropy=$(calculate_entropy "$password")
    local strength=""

    # Entropy-based strength assessment
    if command_exists bc; then
        if (( $(echo "$entropy < 28" | bc -l) )); then
            strength="Very Weak"
        elif (( $(echo "$entropy < 36" | bc -l) )); then
            strength="Weak"
        elif (( $(echo "$entropy < 60" | bc -l) )); then
            strength="Fair"
        elif (( $(echo "$entropy < 128" | bc -l) )); then
            strength="Strong"
        else
            strength="Very Strong"
        fi
    else
        # Simplified without bc
        local ent_int=${entropy%.*}
        if [ "$ent_int" -lt 28 ]; then
            strength="Very Weak"
        elif [ "$ent_int" -lt 36 ]; then
            strength="Weak"
        elif [ "$ent_int" -lt 60 ]; then
            strength="Fair"
        elif [ "$ent_int" -lt 128 ]; then
            strength="Strong"
        else
            strength="Very Strong"
        fi
    fi

    echo "$strength (${entropy} bits)"
}

# Generate single password
generate_password() {
    case "$PASSWORD_TYPE" in
        alphanumeric)
            generate_alphanumeric "$PASSWORD_LENGTH"
            ;;
        special)
            generate_special "$PASSWORD_LENGTH"
            ;;
        passphrase)
            # For passphrases, length is number of words
            local word_count="$PASSWORD_LENGTH"
            [ "$word_count" -lt 3 ] && word_count=5
            [ "$word_count" -gt 10 ] && word_count=10
            generate_passphrase "$word_count"
            ;;
        pin)
            generate_pin "$PASSWORD_LENGTH"
            ;;
        *)
            error_exit "Invalid password type: $PASSWORD_TYPE"
            ;;
    esac
}

# Copy to clipboard
copy_to_clipboard() {
    local password="$1"

    if command_exists pbcopy; then
        # macOS
        echo -n "$password" | pbcopy
        print_success "Password copied to clipboard (macOS)"
    elif command_exists xclip; then
        # Linux with xclip
        echo -n "$password" | xclip -selection clipboard
        print_success "Password copied to clipboard (xclip)"
    elif command_exists xsel; then
        # Linux with xsel
        echo -n "$password" | xsel --clipboard
        print_success "Password copied to clipboard (xsel)"
    else
        print_warning "Clipboard tool not found (install pbcopy/xclip/xsel)"
    fi
}

# Output in text format
output_text() {
    local -n passwords=$1

    for i in "${!passwords[@]}"; do
        local password="${passwords[$i]}"
        local strength=$(assess_strength "$password")

        if [ "$SHOW_STRENGTH" = "yes" ]; then
            printf "%3d. %s  [%s]\n" $((i+1)) "$password" "$strength"
        else
            printf "%3d. %s\n" $((i+1)) "$password"
        fi
    done
}

# Output in CSV format
output_csv() {
    local -n passwords=$1

    echo "Number,Password,Strength,Entropy_Bits"
    for i in "${!passwords[@]}"; do
        local password="${passwords[$i]}"
        local strength_full=$(assess_strength "$password")
        local strength=$(echo "$strength_full" | cut -d'(' -f1 | xargs)
        local entropy=$(echo "$strength_full" | grep -o '[0-9.]*' | head -1)

        printf "%d,%s,%s,%s\n" $((i+1)) "$password" "$strength" "$entropy"
    done
}

# Output in JSON format
output_json() {
    local -n passwords=$1

    echo "{"
    echo '  "passwords": ['

    for i in "${!passwords[@]}"; do
        local password="${passwords[$i]}"
        local strength_full=$(assess_strength "$password")
        local strength=$(echo "$strength_full" | cut -d'(' -f1 | xargs)
        local entropy=$(echo "$strength_full" | grep -o '[0-9.]*' | head -1)

        echo "    {"
        echo "      \"number\": $((i+1)),"
        echo "      \"password\": \"$password\","
        echo "      \"strength\": \"$strength\","
        echo "      \"entropy_bits\": $entropy"
        if [ $i -lt $((${#passwords[@]} - 1)) ]; then
            echo "    },"
        else
            echo "    }"
        fi
    done

    echo "  ],"
    echo "  \"count\": ${#passwords[@]},"
    echo "  \"type\": \"$PASSWORD_TYPE\","
    echo "  \"length\": $PASSWORD_LENGTH"
    echo "}"
}

# Main execution
main() {
    validate_params

    # Generate passwords
    local passwords=()
    for ((i=0; i<PASSWORD_COUNT; i++)); do
        passwords+=("$(generate_password)")
    done

    # Output based on format
    case "$OUTPUT_FORMAT" in
        csv)
            output_csv passwords
            ;;
        json)
            output_json passwords
            ;;
        text|*)
            output_text passwords
            ;;
    esac

    # Copy first password to clipboard if requested
    if [ "$COPY_TO_CLIPBOARD" = "yes" ] && [ ${#passwords[@]} -gt 0 ]; then
        echo
        copy_to_clipboard "${passwords[0]}"
    fi

    log_success "Generated $PASSWORD_COUNT password(s)"
}

# Run main
main
