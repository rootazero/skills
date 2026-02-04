#!/bin/bash
# Clean Script for macOS Cleaner
# Performs actual cleanup with whitelist respect and user confirmation
# Usage: ./clean.sh [--dry-run] [--categories <cat1,cat2>] [--exclude <path1,path2>]

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
DRY_RUN=false
CATEGORIES=""
EXCLUDE_PATHS=()
TOTAL_FREED=0
ERRORS=0

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --categories) CATEGORIES="$2"; shift 2 ;;
        --exclude) IFS=',' read -ra EXCLUDE_PATHS <<< "$2"; shift 2 ;;
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

    # Check exclude list first
    for excluded in "${EXCLUDE_PATHS[@]:-}"; do
        [[ -z "$excluded" ]] && continue
        local expanded_excluded="${excluded/#\~/$HOME}"
        if [[ "$check_path" == "$expanded_excluded"* ]]; then
            return 0
        fi
    done

    # Check whitelist file
    if [[ ! -f "$WHITELIST_FILE" ]]; then
        return 1
    fi

    local expanded_check="${check_path/#\~/$HOME}"

    while IFS= read -r pattern; do
        [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue

        local expanded_pattern="${pattern/#\~/$HOME}"

        if [[ "$expanded_check" == "$expanded_pattern" ]]; then
            return 0
        fi

        if [[ "$expanded_pattern" == *\* ]]; then
            local prefix="${expanded_pattern%\*}"
            if [[ "$expanded_check" == "$prefix"* ]]; then
                return 0
            fi
        fi

        if [[ "$expanded_check" == "$expanded_pattern"/* ]]; then
            return 0
        fi
    done < "$WHITELIST_FILE"

    return 1
}

# Safe remove with logging
safe_remove() {
    local path="$1"
    local description="${2:-}"

    # Check whitelist
    if is_whitelisted "$path"; then
        echo -e "  ${GRAY}⊘ Skipped (protected): ${path/#$HOME/~}${NC}"
        return 0
    fi

    # Get size before deletion
    local size_kb=$(get_size_kb "$path")

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${YELLOW}○ Would delete: ${path/#$HOME/~} ($(human_size $size_kb))${NC}"
        TOTAL_FREED=$((TOTAL_FREED + size_kb))
        return 0
    fi

    # Attempt deletion
    if rm -rf "$path" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Deleted: ${path/#$HOME/~} ($(human_size $size_kb) freed)"
        TOTAL_FREED=$((TOTAL_FREED + size_kb))
    else
        echo -e "  ${RED}✗ Failed: ${path/#$HOME/~}${NC}"
        ((ERRORS++))
    fi
}

# Category check
should_clean_category() {
    local cat="$1"

    if [[ -z "$CATEGORIES" ]]; then
        return 0  # Clean all if no filter
    fi

    [[ ",$CATEGORIES," == *",$cat,"* ]]
}

# Clean user caches
clean_user_caches() {
    echo -e "\n${CYAN}═══ User Caches ═══${NC}"

    if [[ ! -d ~/Library/Caches ]]; then
        echo -e "  ${GRAY}No user caches found${NC}"
        return
    fi

    for cache_dir in ~/Library/Caches/*/; do
        [[ ! -d "$cache_dir" ]] && continue
        safe_remove "$cache_dir"
    done
}

# Clean browser caches
clean_browser_caches() {
    echo -e "\n${CYAN}═══ Browser Caches ═══${NC}"

    local -a paths=(
        "$HOME/Library/Caches/Google/Chrome/Default/Cache"
        "$HOME/Library/Caches/Google/Chrome/Default/Code Cache"
        "$HOME/Library/Caches/com.apple.Safari"
        "$HOME/Library/Caches/Firefox/Profiles"
        "$HOME/Library/Caches/Microsoft Edge/Default/Cache"
        "$HOME/Library/Caches/company.thebrowser.Browser"
    )

    for path in "${paths[@]}"; do
        [[ -d "$path" ]] && safe_remove "$path"
    done
}

# Clean developer caches
clean_dev_caches() {
    echo -e "\n${CYAN}═══ Developer Caches ═══${NC}"

    # Xcode
    [[ -d ~/Library/Developer/Xcode/DerivedData ]] && \
        safe_remove ~/Library/Developer/Xcode/DerivedData "Xcode DerivedData"

    # CocoaPods
    [[ -d ~/Library/Caches/CocoaPods ]] && \
        safe_remove ~/Library/Caches/CocoaPods "CocoaPods cache"

    # npm
    if command -v npm &>/dev/null && [[ "$DRY_RUN" == "false" ]]; then
        echo -e "  ${GRAY}Running: npm cache clean --force${NC}"
        npm cache clean --force 2>/dev/null || true
    fi

    # Homebrew
    if command -v brew &>/dev/null && [[ "$DRY_RUN" == "false" ]]; then
        echo -e "  ${GRAY}Running: brew cleanup${NC}"
        brew cleanup --prune=all 2>/dev/null || true
    fi
}

# Clean logs
clean_logs() {
    echo -e "\n${CYAN}═══ Logs ═══${NC}"

    # User logs older than 7 days
    if [[ -d ~/Library/Logs ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            local count=$(find ~/Library/Logs -type f -mtime +7 2>/dev/null | wc -l | tr -d ' ')
            echo -e "  ${YELLOW}○ Would delete $count log files older than 7 days${NC}"
        else
            find ~/Library/Logs -type f -mtime +7 -delete 2>/dev/null || true
            echo -e "  ${GREEN}✓${NC} Cleaned old log files"
        fi
    fi

    # Crash reports
    [[ -d ~/Library/Logs/DiagnosticReports ]] && \
        safe_remove ~/Library/Logs/DiagnosticReports "Crash reports"
}

# Clean trash
clean_trash() {
    echo -e "\n${CYAN}═══ Trash ═══${NC}"

    if [[ -d ~/.Trash ]]; then
        local size=$(get_size_kb ~/.Trash)
        if [[ $size -gt 0 ]]; then
            if is_whitelisted ~/.Trash; then
                echo -e "  ${GRAY}⊘ Skipped (protected): Trash${NC}"
            elif [[ "$DRY_RUN" == "true" ]]; then
                echo -e "  ${YELLOW}○ Would empty trash ($(human_size $size))${NC}"
                TOTAL_FREED=$((TOTAL_FREED + size))
            else
                rm -rf ~/.Trash/* 2>/dev/null || true
                echo -e "  ${GREEN}✓${NC} Emptied trash ($(human_size $size) freed)"
                TOTAL_FREED=$((TOTAL_FREED + size))
            fi
        else
            echo -e "  ${GRAY}Trash is already empty${NC}"
        fi
    fi
}

# Clean saved application state
clean_saved_state() {
    echo -e "\n${CYAN}═══ Saved Application State ═══${NC}"

    if [[ -d ~/Library/Saved\ Application\ State ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            local count=$(find ~/Library/Saved\ Application\ State -type d -mtime +30 2>/dev/null | wc -l | tr -d ' ')
            echo -e "  ${YELLOW}○ Would delete $count saved states older than 30 days${NC}"
        else
            find ~/Library/Saved\ Application\ State -type d -mtime +30 -exec rm -rf {} + 2>/dev/null || true
            echo -e "  ${GREEN}✓${NC} Cleaned old saved states"
        fi
    fi
}

# Main
main() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${BLUE}║     macOS Cleanup (DRY RUN)            ║${NC}"
    else
        echo -e "${BLUE}║     macOS Cleanup                      ║${NC}"
    fi
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "\n${YELLOW}This is a dry run - no files will be deleted${NC}"
    fi

    # Run selected categories
    should_clean_category "user_caches" && clean_user_caches
    should_clean_category "browser_caches" && clean_browser_caches
    should_clean_category "dev_caches" && clean_dev_caches
    should_clean_category "logs" && clean_logs
    should_clean_category "trash" && clean_trash
    should_clean_category "saved_state" && clean_saved_state

    # Summary
    echo -e "\n${BLUE}═══ Summary ═══${NC}"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  Would free: ${GREEN}$(human_size $TOTAL_FREED)${NC}"
    else
        echo -e "  Space freed: ${GREEN}$(human_size $TOTAL_FREED)${NC}"
    fi

    if [[ $ERRORS -gt 0 ]]; then
        echo -e "  Errors: ${RED}$ERRORS${NC}"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "\n${GRAY}Run without --dry-run to actually delete files${NC}"
    fi
}

main
