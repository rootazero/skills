#!/bin/bash
# Installer Files Cleanup Script
# Finds large installer files (.dmg, .pkg, .zip, etc.) across common locations
# Usage: ./installer.sh [--dry-run] [--min-size <MB>]

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
MIN_SIZE_MB=50
TOTAL_FOUND=0
TOTAL_SIZE=0
INSTALLERS=()

# Installer file extensions
INSTALLER_EXTENSIONS=(
    "dmg"
    "pkg"
    "mpkg"
    "zip"
    "tar.gz"
    "tgz"
    "tar.bz2"
    "tar.xz"
    "7z"
    "rar"
    "iso"
    "app.zip"
    "exe"  # Windows installers
    "msi"
)

# Search locations with labels
declare -A SEARCH_LOCATIONS=(
    ["$HOME/Downloads"]="Downloads"
    ["$HOME/Desktop"]="Desktop"
    ["$HOME/Documents"]="Documents"
    ["/Applications/Utilities"]="Utilities"
)

# Homebrew cask cache (if exists)
BREW_CACHE=""
if command -v brew &>/dev/null; then
    BREW_CACHE="$(brew --cache 2>/dev/null)/Cask"
fi
if [[ -n "$BREW_CACHE" && -d "$BREW_CACHE" ]]; then
    SEARCH_LOCATIONS["$BREW_CACHE"]="Homebrew Cask"
fi

# iCloud Downloads (if exists)
ICLOUD_DOWNLOADS="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Downloads"
if [[ -d "$ICLOUD_DOWNLOADS" ]]; then
    SEARCH_LOCATIONS["$ICLOUD_DOWNLOADS"]="iCloud Downloads"
fi

# Mail Downloads (if exists)
MAIL_DOWNLOADS="$HOME/Library/Containers/com.apple.mail/Data/Library/Mail Downloads"
if [[ -d "$MAIL_DOWNLOADS" ]]; then
    SEARCH_LOCATIONS["$MAIL_DOWNLOADS"]="Mail Downloads"
fi

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --min-size) MIN_SIZE_MB="$2"; shift 2 ;;
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

# Get modification date
get_mod_date() {
    local path="$1"
    if [[ -e "$path" ]]; then
        stat -f "%Sm" -t "%Y-%m-%d" "$path" 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

# Find installers in a directory
find_installers() {
    local search_path="$1"
    local label="$2"

    [[ ! -d "$search_path" ]] && return

    for ext in "${INSTALLER_EXTENSIONS[@]}"; do
        while IFS= read -r -d '' found; do
            [[ -z "$found" ]] && continue

            local size_kb=$(get_size_kb "$found")
            local min_size_kb=$((MIN_SIZE_MB * 1024))

            # Skip if too small
            if [[ $size_kb -lt $min_size_kb ]]; then
                continue
            fi

            local mod_date=$(get_mod_date "$found")
            local filename=$(basename "$found")

            INSTALLERS+=("$found|$size_kb|$mod_date|$label|$filename")
            TOTAL_FOUND=$((TOTAL_FOUND + 1))
            TOTAL_SIZE=$((TOTAL_SIZE + size_kb))

        done < <(find "$search_path" -maxdepth 3 -type f -name "*.$ext" -print0 2>/dev/null || true)
    done
}

# Display installers grouped by source
display_installers() {
    if [[ ${#INSTALLERS[@]} -eq 0 ]]; then
        echo -e "\n${GREEN}No installer files found larger than ${MIN_SIZE_MB}MB${NC}"
        return
    fi

    echo ""
    echo -e "${BLUE}═══ Found Installer Files ═══${NC}"
    echo ""

    local current_source=""
    local source_size=0
    local idx=1

    # Sort by source label
    IFS=$'\n' sorted=($(printf '%s\n' "${INSTALLERS[@]}" | sort -t'|' -k4))
    unset IFS

    for installer in "${sorted[@]}"; do
        IFS='|' read -r path size_kb mod_date label filename <<< "$installer"

        # New source header
        if [[ "$label" != "$current_source" ]]; then
            if [[ -n "$current_source" ]]; then
                echo -e "  ${GRAY}└─ Source total: $(human_size $source_size)${NC}"
                echo ""
            fi
            current_source="$label"
            source_size=0
            echo -e "${CYAN}📦 $label${NC}"
        fi

        # Truncate long filenames
        local display_name="$filename"
        if [[ ${#display_name} -gt 40 ]]; then
            display_name="${display_name:0:37}..."
        fi

        # Color by size
        local size_color="$GREEN"
        [[ $size_kb -gt 524288 ]] && size_color="$YELLOW"  # > 512MB
        [[ $size_kb -gt 1048576 ]] && size_color="$RED"    # > 1GB

        printf "  [%2d] %-42s ${size_color}%8s${NC}  %s\n" \
            "$idx" "$display_name" "$(human_size $size_kb)" "$mod_date"

        source_size=$((source_size + size_kb))
        ((idx++))
    done

    if [[ -n "$current_source" ]]; then
        echo -e "  ${GRAY}└─ Source total: $(human_size $source_size)${NC}"
    fi

    echo ""
    echo -e "${BLUE}═══ Summary ═══${NC}"
    echo -e "  Total files: ${GREEN}$TOTAL_FOUND${NC}"
    echo -e "  Total size: ${GREEN}$(human_size $TOTAL_SIZE)${NC}"
}

# Interactive selection
select_installers() {
    echo ""
    echo -e "${YELLOW}Select files to remove:${NC}"
    echo "  - Enter numbers separated by commas (e.g., 1,3,5-10)"
    echo "  - Enter 'all' to select all"
    echo "  - Enter 'none' or press Enter to cancel"
    echo ""
    read -rp "Selection: " selection

    if [[ -z "$selection" || "$selection" == "none" ]]; then
        echo -e "${GRAY}Cancelled${NC}"
        return
    fi

    local selected_indices=()

    if [[ "$selection" == "all" ]]; then
        for i in $(seq 1 ${#INSTALLERS[@]}); do
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

    # Sort installers same way as display
    IFS=$'\n' sorted=($(printf '%s\n' "${INSTALLERS[@]}" | sort -t'|' -k4))
    unset IFS

    # Confirm deletion
    local delete_size=0
    local delete_paths=()

    echo ""
    echo -e "${YELLOW}Will delete:${NC}"

    for idx in "${selected_indices[@]}"; do
        local arr_idx=$((idx - 1))
        if [[ $arr_idx -ge 0 && $arr_idx -lt ${#sorted[@]} ]]; then
            IFS='|' read -r path size_kb _ label filename <<< "${sorted[$arr_idx]}"
            echo -e "  [$label] $filename ($(human_size $size_kb))"
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
    read -rp "Move to Trash? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${GRAY}Cancelled${NC}"
        return
    fi

    # Move to Trash (safer than rm)
    echo ""
    local deleted_size=0
    for path in "${delete_paths[@]}"; do
        local size_kb=$(get_size_kb "$path")
        local filename=$(basename "$path")

        # Use AppleScript to move to Trash (preserves undo)
        if osascript -e "tell application \"Finder\" to delete POSIX file \"$path\"" &>/dev/null; then
            echo -e "  ${GREEN}✓${NC} Moved to Trash: $filename"
            deleted_size=$((deleted_size + size_kb))
        else
            # Fallback to mv
            if mv "$path" ~/.Trash/ 2>/dev/null; then
                echo -e "  ${GREEN}✓${NC} Moved to Trash: $filename"
                deleted_size=$((deleted_size + size_kb))
            else
                echo -e "  ${RED}✗${NC} Failed: $filename"
            fi
        fi
    done

    echo ""
    echo -e "${GREEN}Freed: $(human_size $deleted_size)${NC}"
    echo -e "${GRAY}Files are in Trash - empty Trash to fully reclaim space${NC}"
}

# Main
main() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${BLUE}║  Installer Cleanup (DRY RUN)           ║${NC}"
    else
        echo -e "${BLUE}║  Installer Cleanup                     ║${NC}"
    fi
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

    echo ""
    echo -e "${GRAY}Minimum file size: ${MIN_SIZE_MB}MB${NC}"
    echo -e "${GRAY}Searching in: Downloads, Desktop, Homebrew, iCloud, Mail${NC}"
    echo ""

    # Scan locations
    for location in "${!SEARCH_LOCATIONS[@]}"; do
        local label="${SEARCH_LOCATIONS[$location]}"
        echo -e "${GRAY}Scanning: $label${NC}"
        find_installers "$location" "$label"
    done

    # Display results
    display_installers

    # Interactive selection
    if [[ $TOTAL_FOUND -gt 0 ]]; then
        select_installers
    fi
}

main
