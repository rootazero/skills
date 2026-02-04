#!/bin/bash
# Whitelist Management for macOS Cleaner
# Manages protected paths that should never be cleaned
# Usage: ./whitelist.sh [add|remove|list|check <path>]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
NC='\033[0m'

# Config paths
CONFIG_DIR="$HOME/.config/macos-cleaner"
WHITELIST_FILE="$CONFIG_DIR/whitelist"

# Default whitelist patterns
DEFAULT_PATTERNS=(
    # AI/ML Models
    "~/.cache/huggingface/*"
    "~/.ollama/models/*"
    "~/.cache/torch/*"
    "~/.cache/tensorflow/*"

    # Development Dependencies
    "~/.m2/repository/*"
    "~/Library/Caches/CocoaPods/*"

    # Browser Testing
    "~/Library/Caches/ms-playwright*"

    # Proxy/VPN Config
    "~/Library/Application Support/com.nssurge.surge-mac/*"
)

# Ensure config directory exists
ensure_config() {
    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir -p "$CONFIG_DIR"
    fi
}

# Initialize whitelist with defaults if not exists
init_whitelist() {
    ensure_config

    if [[ ! -f "$WHITELIST_FILE" ]]; then
        echo "# macOS Cleaner Whitelist" > "$WHITELIST_FILE"
        echo "# Protected paths won't be deleted during cleanup" >> "$WHITELIST_FILE"
        echo "# Supports ~ expansion and glob patterns" >> "$WHITELIST_FILE"
        echo "" >> "$WHITELIST_FILE"
        echo "# AI/ML Models (large, expensive to re-download)" >> "$WHITELIST_FILE"
        for pattern in "${DEFAULT_PATTERNS[@]}"; do
            echo "$pattern" >> "$WHITELIST_FILE"
        done
        echo -e "${GREEN}Initialized whitelist with default patterns${NC}"
    fi
}

# List all whitelist entries
list_whitelist() {
    init_whitelist

    echo -e "${BLUE}═══ Protected Paths (Whitelist) ═══${NC}"
    echo ""

    local count=0
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        # Expand ~ for display
        local expanded="${line/#\~/$HOME}"

        # Check if path exists
        local status=""
        if [[ -e "$expanded" ]] || ls $expanded &>/dev/null 2>&1; then
            status="${GREEN}[exists]${NC}"
        else
            status="${GRAY}[not found]${NC}"
        fi

        echo -e "  $((++count)). $line $status"
    done < "$WHITELIST_FILE"

    if [[ $count -eq 0 ]]; then
        echo -e "  ${GRAY}(no entries)${NC}"
    fi

    echo ""
    echo -e "${GRAY}Config file: $WHITELIST_FILE${NC}"
}

# Add path to whitelist
add_to_whitelist() {
    local path="$1"

    init_whitelist

    # Validate path format
    if [[ -z "$path" ]]; then
        echo -e "${RED}Error: Path cannot be empty${NC}"
        return 1
    fi

    # Check for path traversal
    if [[ "$path" =~ \.\. ]]; then
        echo -e "${RED}Error: Path traversal (..) not allowed${NC}"
        return 1
    fi

    # Ensure absolute path or ~ prefix
    if [[ "$path" != /* && "$path" != ~* ]]; then
        echo -e "${RED}Error: Path must be absolute or start with ~${NC}"
        return 1
    fi

    # Check if already in whitelist
    local normalized="${path/#$HOME/~}"
    if grep -qxF "$normalized" "$WHITELIST_FILE" 2>/dev/null; then
        echo -e "${YELLOW}Path already in whitelist: $normalized${NC}"
        return 0
    fi

    # Add to whitelist
    echo "$normalized" >> "$WHITELIST_FILE"
    echo -e "${GREEN}Added to whitelist: $normalized${NC}"
}

# Remove path from whitelist
remove_from_whitelist() {
    local path="$1"

    if [[ ! -f "$WHITELIST_FILE" ]]; then
        echo -e "${YELLOW}No whitelist file found${NC}"
        return 1
    fi

    local normalized="${path/#$HOME/~}"

    # Check if exists
    if ! grep -qxF "$normalized" "$WHITELIST_FILE" 2>/dev/null; then
        echo -e "${YELLOW}Path not found in whitelist: $normalized${NC}"
        return 1
    fi

    # Remove using grep -v
    local temp_file=$(mktemp)
    grep -vxF "$normalized" "$WHITELIST_FILE" > "$temp_file"
    mv "$temp_file" "$WHITELIST_FILE"

    echo -e "${GREEN}Removed from whitelist: $normalized${NC}"
}

# Check if path is whitelisted
check_whitelist() {
    local check_path="$1"

    if [[ ! -f "$WHITELIST_FILE" ]]; then
        echo "false"
        return 1
    fi

    local expanded_check="${check_path/#\~/$HOME}"

    while IFS= read -r pattern; do
        [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue

        local expanded_pattern="${pattern/#\~/$HOME}"

        # Exact match
        if [[ "$expanded_check" == "$expanded_pattern" ]]; then
            echo "true"
            return 0
        fi

        # Glob match (pattern ends with *)
        if [[ "$expanded_pattern" == *\* ]]; then
            local prefix="${expanded_pattern%\*}"
            if [[ "$expanded_check" == "$prefix"* ]]; then
                echo "true"
                return 0
            fi
        fi

        # Check if check_path is under whitelisted directory
        if [[ "$expanded_check" == "$expanded_pattern"/* ]]; then
            echo "true"
            return 0
        fi
    done < "$WHITELIST_FILE"

    echo "false"
    return 1
}

# Interactive add
interactive_add() {
    echo -e "${BLUE}═══ Add to Whitelist ═══${NC}"
    echo ""
    echo "Enter path to protect (supports ~ and glob patterns):"
    echo "Examples:"
    echo "  ~/Library/Caches/MyApp"
    echo "  ~/.cargo/registry/*"
    echo "  ~/Library/Application Support/Important App"
    echo ""
    read -p "Path: " path

    if [[ -n "$path" ]]; then
        add_to_whitelist "$path"
    fi
}

# Interactive remove
interactive_remove() {
    list_whitelist
    echo ""
    echo "Enter the number or path to remove:"
    read -p "Selection: " selection

    if [[ "$selection" =~ ^[0-9]+$ ]]; then
        # Get path by number
        local count=0
        while IFS= read -r line; do
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            ((count++))
            if [[ $count -eq $selection ]]; then
                remove_from_whitelist "$line"
                return
            fi
        done < "$WHITELIST_FILE"
        echo -e "${RED}Invalid number${NC}"
    else
        remove_from_whitelist "$selection"
    fi
}

# Show usage
show_usage() {
    echo "Whitelist Management for macOS Cleaner"
    echo ""
    echo "Usage: $0 [command] [path]"
    echo ""
    echo "Commands:"
    echo "  list              List all whitelisted paths"
    echo "  add <path>        Add path to whitelist"
    echo "  remove <path>     Remove path from whitelist"
    echo "  check <path>      Check if path is whitelisted"
    echo "  interactive       Interactive mode"
    echo "  reset             Reset to default whitelist"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 add ~/.cargo/registry/*"
    echo "  $0 check ~/Library/Caches/MyApp"
}

# Reset to defaults
reset_whitelist() {
    ensure_config

    echo -e "${YELLOW}This will reset whitelist to defaults. Continue? (y/n)${NC}"
    read -p "" confirm

    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        rm -f "$WHITELIST_FILE"
        init_whitelist
        echo -e "${GREEN}Whitelist reset to defaults${NC}"
    else
        echo "Cancelled"
    fi
}

# Interactive mode
interactive_mode() {
    while true; do
        echo ""
        echo -e "${BLUE}═══ Whitelist Manager ═══${NC}"
        echo ""
        echo "1. List protected paths"
        echo "2. Add path to whitelist"
        echo "3. Remove path from whitelist"
        echo "4. Check if path is protected"
        echo "5. Reset to defaults"
        echo "6. Exit"
        echo ""
        read -p "Choice: " choice

        case "$choice" in
            1) list_whitelist ;;
            2) interactive_add ;;
            3) interactive_remove ;;
            4)
                read -p "Path to check: " path
                if [[ $(check_whitelist "$path") == "true" ]]; then
                    echo -e "${GREEN}Path is protected${NC}"
                else
                    echo -e "${YELLOW}Path is NOT protected${NC}"
                fi
                ;;
            5) reset_whitelist ;;
            6) exit 0 ;;
            *) echo -e "${RED}Invalid choice${NC}" ;;
        esac
    done
}

# Main
main() {
    case "${1:-interactive}" in
        list)
            list_whitelist
            ;;
        add)
            if [[ -z "${2:-}" ]]; then
                interactive_add
            else
                add_to_whitelist "$2"
            fi
            ;;
        remove)
            if [[ -z "${2:-}" ]]; then
                interactive_remove
            else
                remove_from_whitelist "$2"
            fi
            ;;
        check)
            if [[ -z "${2:-}" ]]; then
                echo "Usage: $0 check <path>"
                exit 1
            fi
            result=$(check_whitelist "$2")
            echo "$result"
            [[ "$result" == "true" ]] && exit 0 || exit 1
            ;;
        reset)
            reset_whitelist
            ;;
        interactive)
            interactive_mode
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
