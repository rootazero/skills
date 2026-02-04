#!/bin/bash
# Project Build Artifacts Purge Script
# Finds and removes build artifacts (node_modules, venv, target, etc.)
# Usage: ./purge.sh [--dry-run] [--paths <dir1,dir2>] [--min-age <days>]

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
MIN_AGE_DAYS=7
SCAN_PATHS=()
CONFIG_FILE="$HOME/.config/macos-cleaner/purge_paths"
TOTAL_FOUND=0
TOTAL_SIZE=0
ARTIFACTS=()

# Artifact patterns to search for
declare -A ARTIFACT_TYPES=(
    # JavaScript/TypeScript
    ["node_modules"]="npm dependencies"
    [".next"]="Next.js build"
    [".nuxt"]="Nuxt.js build"
    [".output"]="Nuxt output"
    [".turbo"]="Turborepo cache"
    [".parcel-cache"]="Parcel cache"
    [".svelte-kit"]="SvelteKit build"
    [".astro"]="Astro build"
    ["dist"]="JS build output"

    # Python
    ["venv"]="Python virtualenv"
    [".venv"]="Python virtualenv"
    ["__pycache__"]="Python cache"
    [".pytest_cache"]="Pytest cache"
    [".mypy_cache"]="Mypy cache"
    [".ruff_cache"]="Ruff cache"
    [".tox"]="Tox environments"
    [".nox"]="Nox environments"
    [".eggs"]="Python eggs"
    ["*.egg-info"]="Python egg info"

    # Rust/Go/Java
    ["target"]="Rust/Maven build"
    ["build"]="Gradle/general build"
    [".gradle"]="Gradle cache"
    ["vendor"]="Go/PHP vendor"
    ["obj"]="C#/Unity objects"

    # Other
    [".dart_tool"]="Flutter tools"
    [".zig-cache"]="Zig cache"
    ["zig-out"]="Zig output"
    [".angular"]="Angular cache"
    ["coverage"]="Code coverage"
    [".cache"]="General cache"
)

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --paths) IFS=',' read -ra SCAN_PATHS <<< "$2"; shift 2 ;;
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

# Load scan paths from config
load_scan_paths() {
    if [[ ${#SCAN_PATHS[@]} -gt 0 ]]; then
        return
    fi

    # Default paths
    SCAN_PATHS=(
        "$HOME/Projects"
        "$HOME/Developer"
        "$HOME/Code"
        "$HOME/Workspace"
        "$HOME/src"
        "$HOME/dev"
        "$HOME/git"
        "$HOME/repos"
    )

    # Add paths from config file
    if [[ -f "$CONFIG_FILE" ]]; then
        while IFS= read -r line; do
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            local expanded="${line/#\~/$HOME}"
            SCAN_PATHS+=("$expanded")
        done < "$CONFIG_FILE"
    fi

    # Filter to existing paths
    local valid_paths=()
    for path in "${SCAN_PATHS[@]}"; do
        if [[ -d "$path" ]]; then
            valid_paths+=("$path")
        fi
    done
    SCAN_PATHS=("${valid_paths[@]}")
}

# Find artifacts in a directory
find_artifacts() {
    local search_path="$1"

    echo -e "${GRAY}Scanning: $search_path${NC}"

    for artifact_name in "${!ARTIFACT_TYPES[@]}"; do
        # Skip glob patterns for now (handle separately)
        [[ "$artifact_name" == *"*"* ]] && continue

        while IFS= read -r -d '' found; do
            [[ -z "$found" ]] && continue

            local size_kb=$(get_size_kb "$found")
            local age_days=$(get_age_days "$found")
            local description="${ARTIFACT_TYPES[$artifact_name]}"

            # Skip if too recent
            if [[ $age_days -lt $MIN_AGE_DAYS ]]; then
                continue
            fi

            ARTIFACTS+=("$found|$size_kb|$age_days|$description")
            TOTAL_FOUND=$((TOTAL_FOUND + 1))
            TOTAL_SIZE=$((TOTAL_SIZE + size_kb))

        done < <(find "$search_path" -maxdepth 5 -type d -name "$artifact_name" -print0 2>/dev/null || true)
    done
}

# Display artifacts grouped by project
display_artifacts() {
    if [[ ${#ARTIFACTS[@]} -eq 0 ]]; then
        echo -e "\n${GREEN}No build artifacts found older than $MIN_AGE_DAYS days${NC}"
        return
    fi

    echo ""
    echo -e "${BLUE}═══ Found Build Artifacts ═══${NC}"
    echo ""

    local current_project=""
    local project_size=0
    local idx=1

    # Sort artifacts by path
    IFS=$'\n' sorted=($(printf '%s\n' "${ARTIFACTS[@]}" | sort))
    unset IFS

    for artifact in "${sorted[@]}"; do
        IFS='|' read -r path size_kb age_days description <<< "$artifact"

        # Extract project path (parent of artifact)
        local project=$(dirname "$path")
        project="${project/#$HOME/~}"

        # New project header
        if [[ "$project" != "$current_project" ]]; then
            if [[ -n "$current_project" ]]; then
                echo -e "  ${GRAY}└─ Project total: $(human_size $project_size)${NC}"
                echo ""
            fi
            current_project="$project"
            project_size=0
            echo -e "${CYAN}$project${NC}"
        fi

        local display_path="${path/#$HOME/~}"
        local artifact_name=$(basename "$path")

        # Color by age
        local age_color="$GREEN"
        [[ $age_days -gt 30 ]] && age_color="$YELLOW"
        [[ $age_days -gt 90 ]] && age_color="$RED"

        printf "  [%2d] %-20s %8s  ${age_color}%3d days${NC}  %s\n" \
            "$idx" "$artifact_name" "$(human_size $size_kb)" "$age_days" "$description"

        project_size=$((project_size + size_kb))
        ((idx++))
    done

    if [[ -n "$current_project" ]]; then
        echo -e "  ${GRAY}└─ Project total: $(human_size $project_size)${NC}"
    fi

    echo ""
    echo -e "${BLUE}═══ Summary ═══${NC}"
    echo -e "  Total artifacts: ${GREEN}$TOTAL_FOUND${NC}"
    echo -e "  Total size: ${GREEN}$(human_size $TOTAL_SIZE)${NC}"
}

# Interactive selection
select_artifacts() {
    echo ""
    echo -e "${YELLOW}Select artifacts to remove:${NC}"
    echo "  - Enter numbers separated by commas (e.g., 1,3,5-10)"
    echo "  - Enter 'all' to select all"
    echo "  - Enter 'old' to select only >30 days"
    echo "  - Enter 'none' or press Enter to cancel"
    echo ""
    read -rp "Selection: " selection

    if [[ -z "$selection" || "$selection" == "none" ]]; then
        echo -e "${GRAY}Cancelled${NC}"
        return
    fi

    local selected_indices=()

    if [[ "$selection" == "all" ]]; then
        for i in $(seq 1 ${#ARTIFACTS[@]}); do
            selected_indices+=("$i")
        done
    elif [[ "$selection" == "old" ]]; then
        local idx=1
        for artifact in "${ARTIFACTS[@]}"; do
            IFS='|' read -r _ _ age_days _ <<< "$artifact"
            if [[ $age_days -gt 30 ]]; then
                selected_indices+=("$idx")
            fi
            ((idx++))
        done
    else
        # Parse selection (supports ranges like 1,3,5-10)
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

    # Confirm deletion
    local delete_size=0
    local delete_paths=()

    echo ""
    echo -e "${YELLOW}Will delete:${NC}"

    for idx in "${selected_indices[@]}"; do
        local arr_idx=$((idx - 1))
        if [[ $arr_idx -ge 0 && $arr_idx -lt ${#ARTIFACTS[@]} ]]; then
            IFS='|' read -r path size_kb _ _ <<< "${ARTIFACTS[$arr_idx]}"
            echo -e "  ${path/#$HOME/~} ($(human_size $size_kb))"
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
    read -rp "Confirm deletion? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
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
        echo -e "${BLUE}║  Project Build Artifact Purge (DRY)    ║${NC}"
    else
        echo -e "${BLUE}║  Project Build Artifact Purge          ║${NC}"
    fi
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

    echo ""
    echo -e "${GRAY}Minimum age: $MIN_AGE_DAYS days${NC}"

    # Load scan paths
    load_scan_paths

    if [[ ${#SCAN_PATHS[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No project directories found to scan${NC}"
        echo ""
        echo "Configure paths in: $CONFIG_FILE"
        echo "Or use: ./purge.sh --paths ~/my/projects,~/other/path"
        exit 0
    fi

    echo -e "${GRAY}Scanning ${#SCAN_PATHS[@]} directories...${NC}"
    echo ""

    # Scan for artifacts
    for scan_path in "${SCAN_PATHS[@]}"; do
        find_artifacts "$scan_path"
    done

    # Display results
    display_artifacts

    # Interactive selection
    if [[ $TOTAL_FOUND -gt 0 ]]; then
        select_artifacts
    fi
}

main
