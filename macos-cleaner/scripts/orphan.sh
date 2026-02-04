#!/bin/bash
# Orphaned App Data Detection Script
# Finds application data where the app is no longer installed
# Usage: ./orphan.sh [--dry-run] [--min-age <days>]

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
DRY_RUN=false
MIN_AGE_DAYS=60  # Grace period - only show data older than this
TOTAL_FOUND=0
TOTAL_SIZE=0
ORPHANS=()

# Protected vendors - always skip these
PROTECTED_VENDORS=(
    "com.apple."
    "com.adobe."
    "com.microsoft."
    "com.google."
    "com.jetbrains."
    "com.github."
    "com.anthropic."
    "com.openai."
)

# Minimum app name length to avoid false positives
MIN_NAME_LENGTH=3

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --min-age) MIN_AGE_DAYS="$2"; shift 2 ;;
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

# Get modification age in days
get_age_days() {
    local path="$1"
    if [[ -e "$path" ]]; then
        local mtime=$(stat -f %m "$path" 2>/dev/null || echo "0")
        local now=$(date +%s)
        echo $(( (now - mtime) / 86400 ))
    else
        echo "0"
    fi
}

# Check if app is installed
is_app_installed() {
    local app_name="$1"

    # Check /Applications
    if [[ -d "/Applications/${app_name}.app" ]]; then
        return 0
    fi

    # Check ~/Applications
    if [[ -d "$HOME/Applications/${app_name}.app" ]]; then
        return 0
    fi

    # Check /System/Applications
    if [[ -d "/System/Applications/${app_name}.app" ]]; then
        return 0
    fi

    # Check via mdfind (Spotlight)
    if mdfind "kMDItemKind == 'Application'" -name "$app_name" 2>/dev/null | grep -q ".app"; then
        return 0
    fi

    return 1
}

# Check if bundle ID belongs to protected vendor
is_protected_vendor() {
    local bundle_id="$1"

    for vendor in "${PROTECTED_VENDORS[@]}"; do
        if [[ "$bundle_id" == "$vendor"* ]]; then
            return 0
        fi
    done

    return 1
}

# Extract app name from bundle ID
extract_app_name() {
    local bundle_id="$1"

    # Get last component of bundle ID
    local name=$(echo "$bundle_id" | awk -F'.' '{print $NF}')

    # Remove common suffixes
    name="${name%-mac}"
    name="${name%-macgap}"
    name="${name%-helper}"

    # Convert to title case for display
    echo "$name"
}

# Find orphaned data in a directory
find_orphans_in_dir() {
    local search_dir="$1"
    local type="$2"

    [[ ! -d "$search_dir" ]] && return

    for item in "$search_dir"/*; do
        [[ ! -e "$item" ]] && continue

        local name=$(basename "$item")
        local age_days=$(get_age_days "$item")

        # Skip if too recent
        if [[ $age_days -lt $MIN_AGE_DAYS ]]; then
            continue
        fi

        # Extract potential app name
        local app_name=""
        local bundle_id=""

        # Check if it looks like a bundle ID (com.x.y format)
        if [[ "$name" =~ ^[a-z]+\.[a-z]+\. ]]; then
            bundle_id="$name"
            app_name=$(extract_app_name "$name")

            # Skip protected vendors
            if is_protected_vendor "$bundle_id"; then
                continue
            fi
        else
            # It's a regular app name
            app_name="$name"

            # Skip if name is too short (prevents false positives)
            if [[ ${#app_name} -lt $MIN_NAME_LENGTH ]]; then
                continue
            fi
        fi

        # Check if app is installed
        if ! is_app_installed "$app_name"; then
            local size_kb=$(get_size_kb "$item")
            if [[ $size_kb -gt 0 ]]; then
                ORPHANS+=("$item|$size_kb|$age_days|$app_name|$type")
                TOTAL_FOUND=$((TOTAL_FOUND + 1))
                TOTAL_SIZE=$((TOTAL_SIZE + size_kb))
            fi
        fi
    done
}

# Display orphans
display_orphans() {
    if [[ ${#ORPHANS[@]} -eq 0 ]]; then
        echo -e "\n${GREEN}No orphaned app data found (older than $MIN_AGE_DAYS days)${NC}"
        return
    fi

    echo ""
    echo -e "${BLUE}═══ Potential Orphaned App Data ═══${NC}"
    echo -e "${GRAY}(Apps not found in /Applications or ~/Applications)${NC}"
    echo ""

    local current_type=""
    local idx=1

    # Sort by type
    IFS=$'\n' sorted=($(printf '%s\n' "${ORPHANS[@]}" | sort -t'|' -k5))
    unset IFS

    for orphan in "${sorted[@]}"; do
        IFS='|' read -r path size_kb age_days app_name type <<< "$orphan"

        # New type header
        if [[ "$type" != "$current_type" ]]; then
            if [[ -n "$current_type" ]]; then
                echo ""
            fi
            current_type="$type"
            echo -e "${CYAN}$type${NC}"
        fi

        local display_path="${path/#$HOME/~}"

        # Color by size
        local size_color="$NC"
        [[ $size_kb -gt 102400 ]] && size_color="$YELLOW"  # > 100MB
        [[ $size_kb -gt 524288 ]] && size_color="$RED"     # > 512MB

        printf "  [%2d] %-25s ${size_color}%8s${NC}  %3d days  %s\n" \
            "$idx" "$app_name" "$(human_size $size_kb)" "$age_days" "$display_path"

        ((idx++))
    done

    echo ""
    echo -e "${BLUE}═══ Summary ═══${NC}"
    echo -e "  Total items: ${GREEN}$TOTAL_FOUND${NC}"
    echo -e "  Total size: ${GREEN}$(human_size $TOTAL_SIZE)${NC}"
}

# Interactive cleanup
select_orphans() {
    echo ""
    echo -e "${YELLOW}Select items to remove:${NC}"
    echo "  - Enter numbers separated by commas (e.g., 1,3,5-10)"
    echo "  - Enter 'all' to select all"
    echo "  - Enter 'none' or press Enter to cancel"
    echo ""
    echo -e "${RED}⚠️  WARNING: Verify these are truly orphaned before deleting!${NC}"
    echo ""
    read -rp "Selection: " selection

    if [[ -z "$selection" || "$selection" == "none" ]]; then
        echo -e "${GRAY}Cancelled${NC}"
        return
    fi

    local selected_indices=()

    if [[ "$selection" == "all" ]]; then
        for i in $(seq 1 ${#ORPHANS[@]}); do
            selected_indices+=("$i")
        done
    else
        # Parse selection
        IFS=',' read -ra parts <<< "$selection"
        for part in "${parts[@]}"; do
            if [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
                for i in $(seq "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"); do
                    selected_indices+=("$i")
                done
            elif [[ "$part" =~ ^[0-9]+$ ]]; then
                selected_indices+=("$part")
            fi
        done
    fi

    if [[ ${#selected_indices[@]} -eq 0 ]]; then
        echo -e "${GRAY}No valid selection${NC}"
        return
    fi

    # Sort orphans same way as display
    IFS=$'\n' sorted=($(printf '%s\n' "${ORPHANS[@]}" | sort -t'|' -k5))
    unset IFS

    # Confirm deletion
    local delete_size=0
    local delete_paths=()

    echo ""
    echo -e "${YELLOW}Will delete:${NC}"

    for idx in "${selected_indices[@]}"; do
        local arr_idx=$((idx - 1))
        if [[ $arr_idx -ge 0 && $arr_idx -lt ${#sorted[@]} ]]; then
            IFS='|' read -r path size_kb _ app_name _ <<< "${sorted[$arr_idx]}"
            echo -e "  $app_name: ${path/#$HOME/~} ($(human_size $size_kb))"
            delete_paths+=("$path")
            delete_size=$((delete_size + size_kb))
        fi
    done

    echo ""
    echo -e "Total to delete: ${RED}$(human_size $delete_size)${NC}"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "\n${YELLOW}DRY RUN - No files deleted${NC}"
        return
    fi

    echo ""
    read -rp "Confirm deletion? (type 'yes' to confirm): " confirm
    if [[ "$confirm" != "yes" ]]; then
        echo -e "${GRAY}Cancelled${NC}"
        return
    fi

    # Perform deletion
    echo ""
    local deleted_size=0
    for path in "${delete_paths[@]}"; do
        local size_kb=$(get_size_kb "$path")
        if rm -rf "$path" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} Deleted: ${path/#$HOME/~}"
            deleted_size=$((deleted_size + size_kb))
        else
            echo -e "  ${RED}✗${NC} Failed: ${path/#$HOME/~}"
        fi
    done

    echo ""
    echo -e "${GREEN}Freed: $(human_size $deleted_size)${NC}"
}

# Main
main() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${BLUE}║  Orphaned App Data Finder (DRY RUN)    ║${NC}"
    else
        echo -e "${BLUE}║  Orphaned App Data Finder              ║${NC}"
    fi
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

    echo ""
    echo -e "${GRAY}Looking for app data where the app is no longer installed${NC}"
    echo -e "${GRAY}Minimum age: $MIN_AGE_DAYS days (grace period for reinstalls)${NC}"
    echo ""

    echo -e "${GRAY}Scanning Application Support...${NC}"
    find_orphans_in_dir "$HOME/Library/Application Support" "Application Support"

    echo -e "${GRAY}Scanning Caches...${NC}"
    find_orphans_in_dir "$HOME/Library/Caches" "Caches"

    echo -e "${GRAY}Scanning Preferences...${NC}"
    find_orphans_in_dir "$HOME/Library/Preferences" "Preferences"

    echo -e "${GRAY}Scanning Containers...${NC}"
    find_orphans_in_dir "$HOME/Library/Containers" "Containers"

    echo -e "${GRAY}Scanning Saved Application State...${NC}"
    find_orphans_in_dir "$HOME/Library/Saved Application State" "Saved State"

    echo -e "${GRAY}Scanning Logs...${NC}"
    find_orphans_in_dir "$HOME/Library/Logs" "Logs"

    echo -e "${GRAY}Scanning HTTPStorages...${NC}"
    find_orphans_in_dir "$HOME/Library/HTTPStorages" "HTTP Storage"

    echo -e "${GRAY}Scanning WebKit data...${NC}"
    find_orphans_in_dir "$HOME/Library/WebKit" "WebKit"

    # Display results
    display_orphans

    # Interactive cleanup
    if [[ $TOTAL_FOUND -gt 0 ]]; then
        select_orphans
    fi
}

main
