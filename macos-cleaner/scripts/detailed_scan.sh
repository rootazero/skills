#!/bin/bash
# Detailed Scan for macOS Cleaner
# Shows all cleanable items with sizes, respects whitelist
# Usage: ./detailed_scan.sh [--category <cat>] [--json]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

# Config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WHITELIST_FILE="$HOME/.config/macos-cleaner/whitelist"
OUTPUT_FORMAT="text"
CATEGORY_FILTER=""

# Global index counter
SCAN_INDEX=1

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --json) OUTPUT_FORMAT="json"; shift ;;
        --category) CATEGORY_FILTER="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# Human readable size
human_size() {
    local kb=$1
    if [[ $kb -ge 1048576 ]]; then
        echo "$(echo "scale=1; $kb / 1048576" | bc)G"
    elif [[ $kb -ge 1024 ]]; then
        echo "$(echo "scale=1; $kb / 1024" | bc)M"
    else
        echo "${kb}K"
    fi
}

# Get size in KB
get_size_kb() {
    local path="$1"
    if [[ -e "$path" ]]; then
        du -sk "$path" 2>/dev/null | awk '{print $1}' || echo "0"
    else
        echo "0"
    fi
}

# Check if path is whitelisted
is_whitelisted() {
    local check_path="$1"

    if [[ ! -f "$WHITELIST_FILE" ]]; then
        return 1
    fi

    local expanded_check="${check_path/#\~/$HOME}"

    while IFS= read -r pattern; do
        [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue

        local expanded_pattern="${pattern/#\~/$HOME}"

        # Exact match
        if [[ "$expanded_check" == "$expanded_pattern" ]]; then
            return 0
        fi

        # Glob match
        if [[ "$expanded_pattern" == *\* ]]; then
            local prefix="${expanded_pattern%\*}"
            if [[ "$expanded_check" == "$prefix"* ]]; then
                return 0
            fi
        fi

        # Child of whitelisted directory
        if [[ "$expanded_check" == "$expanded_pattern"/* ]]; then
            return 0
        fi
    done < "$WHITELIST_FILE"

    return 1
}

# Print item (text format) - uses global SCAN_INDEX
print_item() {
    local path="$1"
    local size_kb="$2"
    local category="$3"
    local whitelisted="$4"

    local size_human=$(human_size $size_kb)
    local display_path="${path/#$HOME/~}"

    if [[ "$whitelisted" == "true" ]]; then
        echo -e "  ${GRAY}[$SCAN_INDEX] $display_path ($size_human) [PROTECTED]${NC}"
    elif [[ $size_kb -gt 1048576 ]]; then  # > 1GB
        echo -e "  ${RED}[$SCAN_INDEX] $display_path ($size_human)${NC}"
    elif [[ $size_kb -gt 102400 ]]; then  # > 100MB
        echo -e "  ${YELLOW}[$SCAN_INDEX] $display_path ($size_human)${NC}"
    else
        echo -e "  [$SCAN_INDEX] $display_path ($size_human)"
    fi

    ((SCAN_INDEX++))
}

# Print JSON item - uses global SCAN_INDEX
print_json_item() {
    local path="$1"
    local size_kb="$2"
    local category="$3"
    local whitelisted="$4"
    local name="${5:-}"

    if [[ -n "$name" ]]; then
        echo "{\"index\":$SCAN_INDEX,\"path\":\"$path\",\"size_kb\":$size_kb,\"category\":\"$category\",\"name\":\"$name\",\"whitelisted\":$whitelisted}"
    else
        echo "{\"index\":$SCAN_INDEX,\"path\":\"$path\",\"size_kb\":$size_kb,\"category\":\"$category\",\"whitelisted\":$whitelisted}"
    fi

    ((SCAN_INDEX++))
}

# Scan user caches
scan_user_caches() {
    if [[ -d ~/Library/Caches ]]; then
        for cache_dir in ~/Library/Caches/*/; do
            [[ ! -d "$cache_dir" ]] && continue

            local size=$(get_size_kb "$cache_dir")
            [[ $size -eq 0 ]] && continue

            local whitelisted="false"
            is_whitelisted "$cache_dir" && whitelisted="true"

            if [[ "$OUTPUT_FORMAT" == "text" ]]; then
                print_item "$cache_dir" "$size" "user_cache" "$whitelisted"
            else
                print_json_item "$cache_dir" "$size" "user_cache" "$whitelisted"
            fi
        done
    fi
}

# Scan browser caches
scan_browser_caches() {
    local -a browser_paths=(
        "$HOME/Library/Caches/Google/Chrome"
        "$HOME/Library/Caches/com.apple.Safari"
        "$HOME/Library/Caches/Firefox"
        "$HOME/Library/Caches/Microsoft Edge"
        "$HOME/Library/Caches/company.thebrowser.Browser"
        "$HOME/Library/Caches/com.brave.Browser"
    )

    local -a browser_names=(
        "Google Chrome"
        "Safari"
        "Firefox"
        "Microsoft Edge"
        "Arc"
        "Brave"
    )

    for i in "${!browser_paths[@]}"; do
        local path="${browser_paths[$i]}"
        local name="${browser_names[$i]}"

        [[ ! -d "$path" ]] && continue

        local size=$(get_size_kb "$path")
        [[ $size -eq 0 ]] && continue

        local whitelisted="false"
        is_whitelisted "$path" && whitelisted="true"

        if [[ "$OUTPUT_FORMAT" == "text" ]]; then
            print_item "$path" "$size" "browser_cache" "$whitelisted"
        else
            print_json_item "$path" "$size" "browser_cache" "$whitelisted" "$name"
        fi
    done
}

# Scan developer caches
scan_dev_caches() {
    local -a dev_paths=(
        "$HOME/Library/Developer/Xcode/DerivedData"
        "$HOME/Library/Developer/Xcode/Archives"
        "$HOME/Library/Developer/Xcode/iOS DeviceSupport"
        "$HOME/Library/Caches/CocoaPods"
        "$HOME/.npm"
        "$HOME/.cargo/registry"
        "$HOME/.gradle/caches"
        "$HOME/.m2/repository"
        "$HOME/Library/Caches/pip"
        "$HOME/.cache/uv"
        "$HOME/.cache/go-build"
    )

    local -a dev_names=(
        "Xcode DerivedData"
        "Xcode Archives"
        "iOS Device Support"
        "CocoaPods"
        "npm cache"
        "Cargo registry"
        "Gradle caches"
        "Maven repository"
        "pip cache"
        "uv cache"
        "Go build cache"
    )

    for i in "${!dev_paths[@]}"; do
        local path="${dev_paths[$i]}"
        local name="${dev_names[$i]}"

        [[ ! -d "$path" ]] && continue

        local size=$(get_size_kb "$path")
        [[ $size -eq 0 ]] && continue

        local whitelisted="false"
        is_whitelisted "$path" && whitelisted="true"

        if [[ "$OUTPUT_FORMAT" == "text" ]]; then
            print_item "$path" "$size" "dev_cache" "$whitelisted"
        else
            print_json_item "$path" "$size" "dev_cache" "$whitelisted" "$name"
        fi
    done
}

# Scan logs
scan_logs() {
    if [[ -d ~/Library/Logs ]]; then
        for log_dir in ~/Library/Logs/*/; do
            [[ ! -d "$log_dir" ]] && continue

            local size=$(get_size_kb "$log_dir")
            [[ $size -eq 0 ]] && continue

            local whitelisted="false"
            is_whitelisted "$log_dir" && whitelisted="true"

            if [[ "$OUTPUT_FORMAT" == "text" ]]; then
                print_item "$log_dir" "$size" "logs" "$whitelisted"
            else
                print_json_item "$log_dir" "$size" "logs" "$whitelisted"
            fi
        done
    fi
}

# Scan trash
scan_trash() {
    if [[ -d ~/.Trash ]]; then
        local size=$(get_size_kb ~/.Trash)
        if [[ $size -gt 0 ]]; then
            local whitelisted="false"
            is_whitelisted ~/.Trash && whitelisted="true"

            if [[ "$OUTPUT_FORMAT" == "text" ]]; then
                print_item "$HOME/.Trash" "$size" "trash" "$whitelisted"
            else
                print_json_item "$HOME/.Trash" "$size" "trash" "$whitelisted"
            fi
        fi
    fi
}

# Scan AI/ML caches
scan_ai_caches() {
    local -a ai_paths=(
        "$HOME/.cache/huggingface"
        "$HOME/.ollama/models"
        "$HOME/.cache/torch"
        "$HOME/.cache/tensorflow"
        "$HOME/Library/Caches/ms-playwright"
    )

    local -a ai_names=(
        "HuggingFace models"
        "Ollama models"
        "PyTorch cache"
        "TensorFlow cache"
        "Playwright browsers"
    )

    for i in "${!ai_paths[@]}"; do
        local path="${ai_paths[$i]}"
        local name="${ai_names[$i]}"

        [[ ! -d "$path" ]] && continue

        local size=$(get_size_kb "$path")
        [[ $size -eq 0 ]] && continue

        local whitelisted="false"
        is_whitelisted "$path" && whitelisted="true"

        if [[ "$OUTPUT_FORMAT" == "text" ]]; then
            print_item "$path" "$size" "ai_ml" "$whitelisted"
        else
            print_json_item "$path" "$size" "ai_ml" "$whitelisted" "$name"
        fi
    done
}

# Main scan
main() {
    if [[ "$OUTPUT_FORMAT" == "text" ]]; then
        echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║     Detailed Cleanup Scan              ║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${GRAY}Items marked [PROTECTED] are in your whitelist${NC}"
        echo -e "${RED}Red${NC} = >1GB, ${YELLOW}Yellow${NC} = >100MB"
        echo ""
    else
        echo "["
    fi

    # User Caches
    if [[ -z "$CATEGORY_FILTER" || "$CATEGORY_FILTER" == "user_cache" ]]; then
        [[ "$OUTPUT_FORMAT" == "text" ]] && echo -e "${CYAN}═══ User Caches ═══${NC}"
        scan_user_caches
    fi

    # Browser Caches
    if [[ -z "$CATEGORY_FILTER" || "$CATEGORY_FILTER" == "browser_cache" ]]; then
        [[ "$OUTPUT_FORMAT" == "text" ]] && echo -e "\n${CYAN}═══ Browser Caches ═══${NC}"
        scan_browser_caches
    fi

    # Developer Caches
    if [[ -z "$CATEGORY_FILTER" || "$CATEGORY_FILTER" == "dev_cache" ]]; then
        [[ "$OUTPUT_FORMAT" == "text" ]] && echo -e "\n${CYAN}═══ Developer Caches ═══${NC}"
        scan_dev_caches
    fi

    # AI/ML Caches
    if [[ -z "$CATEGORY_FILTER" || "$CATEGORY_FILTER" == "ai_ml" ]]; then
        [[ "$OUTPUT_FORMAT" == "text" ]] && echo -e "\n${CYAN}═══ AI/ML Caches ═══${NC}"
        scan_ai_caches
    fi

    # Logs
    if [[ -z "$CATEGORY_FILTER" || "$CATEGORY_FILTER" == "logs" ]]; then
        [[ "$OUTPUT_FORMAT" == "text" ]] && echo -e "\n${CYAN}═══ Logs ═══${NC}"
        scan_logs
    fi

    # Trash
    if [[ -z "$CATEGORY_FILTER" || "$CATEGORY_FILTER" == "trash" ]]; then
        [[ "$OUTPUT_FORMAT" == "text" ]] && echo -e "\n${CYAN}═══ Trash ═══${NC}"
        scan_trash
    fi

    if [[ "$OUTPUT_FORMAT" == "text" ]]; then
        echo ""
        echo -e "${BLUE}═══ Summary ═══${NC}"
        echo -e "  Total items found: $((SCAN_INDEX - 1))"
        echo ""
        echo -e "${GRAY}To exclude items, add them to: ~/.config/macos-cleaner/whitelist${NC}"
        echo -e "${GRAY}Or run: $SCRIPT_DIR/whitelist.sh add <path>${NC}"
    else
        echo "]"
    fi
}

main
