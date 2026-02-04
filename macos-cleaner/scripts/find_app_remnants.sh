#!/bin/bash
# Find Application Remnants
# Searches for all files related to an application by name or bundle ID
# Usage: ./find_app_remnants.sh "App Name" [bundle.id]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
NC='\033[0m'

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

# Main
main() {
    local app_name="${1:-}"
    local bundle_id="${2:-}"

    if [[ -z "$app_name" ]]; then
        echo "Usage: $0 \"App Name\" [bundle.id]"
        echo ""
        echo "Examples:"
        echo "  $0 \"Slack\""
        echo "  $0 \"Visual Studio Code\" \"com.microsoft.VSCode\""
        exit 1
    fi

    # Generate naming variants
    local nospace_name="${app_name// /}"
    local hyphen_name="${app_name// /-}"
    local underscore_name="${app_name// /_}"
    local lowercase_name=$(echo "$app_name" | tr '[:upper:]' '[:lower:]')
    local lowercase_nospace=$(echo "$nospace_name" | tr '[:upper:]' '[:lower:]')
    local lowercase_hyphen=$(echo "$hyphen_name" | tr '[:upper:]' '[:lower:]')

    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     Application Remnant Finder         ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "App Name: ${GREEN}$app_name${NC}"
    [[ -n "$bundle_id" ]] && echo -e "Bundle ID: ${GREEN}$bundle_id${NC}"
    echo ""

    # Try to find bundle ID from app if not provided
    if [[ -z "$bundle_id" ]]; then
        for app_path in "/Applications/${app_name}.app" "$HOME/Applications/${app_name}.app"; do
            if [[ -d "$app_path" ]]; then
                bundle_id=$(defaults read "$app_path/Contents/Info.plist" CFBundleIdentifier 2>/dev/null || true)
                if [[ -n "$bundle_id" ]]; then
                    echo -e "Found Bundle ID: ${GREEN}$bundle_id${NC}"
                    break
                fi
            fi
        done
    fi

    local total_size=0
    local found_paths=()

    echo ""
    echo -e "${BLUE}═══ Application Bundles ═══${NC}"

    for app_path in "/Applications/${app_name}.app" "$HOME/Applications/${app_name}.app"; do
        if [[ -d "$app_path" ]]; then
            local size=$(get_size_kb "$app_path")
            echo -e "  ${GREEN}✓${NC} $app_path ($(human_size $size))"
            found_paths+=("$app_path")
            total_size=$((total_size + size))
        fi
    done

    echo ""
    echo -e "${BLUE}═══ User Library ═══${NC}"

    # Patterns to search
    local -a patterns=("$app_name" "$nospace_name" "$hyphen_name" "$underscore_name")
    [[ -n "$bundle_id" ]] && patterns+=("$bundle_id")

    local -a user_dirs=(
        "Application Support"
        "Caches"
        "Logs"
        "Preferences"
        "Preferences/ByHost"
        "Saved Application State"
        "Containers"
        "Group Containers"
        "HTTPStorages"
        "WebKit"
        "Cookies"
        "LaunchAgents"
        "Application Scripts"
        "Services"
        "QuickLook"
        "Internet Plug-Ins"
    )

    for dir in "${user_dirs[@]}"; do
        local base_path="$HOME/Library/$dir"
        [[ ! -d "$base_path" ]] && continue

        for pattern in "${patterns[@]}"; do
            [[ -z "$pattern" ]] && continue

            while IFS= read -r -d '' found; do
                [[ -z "$found" ]] && continue

                # Skip already found
                local already_found=false
                for existing in "${found_paths[@]}"; do
                    if [[ "$found" == "$existing" ]]; then
                        already_found=true
                        break
                    fi
                done
                [[ "$already_found" == "true" ]] && continue

                local size=$(get_size_kb "$found")
                local relative_path="${found#$HOME/}"
                echo -e "  ${GREEN}✓${NC} ~/$relative_path ($(human_size $size))"
                found_paths+=("$found")
                total_size=$((total_size + size))
            done < <(find "$base_path" -maxdepth 2 -name "*${pattern}*" -print0 2>/dev/null || true)
        done
    done

    # Hidden config files
    echo ""
    echo -e "${BLUE}═══ Hidden Config Files ═══${NC}"

    for pattern in "$lowercase_name" "$lowercase_nospace" "$lowercase_hyphen"; do
        for config in "$HOME/.$pattern" "$HOME/.${pattern}rc" "$HOME/.config/$pattern" "$HOME/.local/share/$pattern"; do
            if [[ -e "$config" ]]; then
                local size=$(get_size_kb "$config")
                local relative_path="${config#$HOME/}"
                echo -e "  ${GREEN}✓${NC} ~/$relative_path ($(human_size $size))"
                found_paths+=("$config")
                total_size=$((total_size + size))
            fi
        done
    done

    # System-level (requires sudo)
    echo ""
    echo -e "${BLUE}═══ System Level (may require sudo) ═══${NC}"

    local -a system_dirs=(
        "/Library/Application Support"
        "/Library/Caches"
        "/Library/Logs"
        "/Library/Preferences"
        "/Library/LaunchAgents"
        "/Library/LaunchDaemons"
        "/Library/PrivilegedHelperTools"
    )

    for dir in "${system_dirs[@]}"; do
        [[ ! -d "$dir" ]] && continue

        for pattern in "${patterns[@]}"; do
            [[ -z "$pattern" ]] && continue

            while IFS= read -r -d '' found; do
                [[ -z "$found" ]] && continue

                local already_found=false
                for existing in "${found_paths[@]}"; do
                    if [[ "$found" == "$existing" ]]; then
                        already_found=true
                        break
                    fi
                done
                [[ "$already_found" == "true" ]] && continue

                local size=$(get_size_kb "$found" 2>/dev/null || echo "0")
                echo -e "  ${YELLOW}✓${NC} $found ($(human_size $size))"
                found_paths+=("$found")
                total_size=$((total_size + size))
            done < <(find "$dir" -maxdepth 2 -name "*${pattern}*" -print0 2>/dev/null || true)
        done
    done

    # Receipts
    if [[ -n "$bundle_id" && -d /private/var/db/receipts ]]; then
        echo ""
        echo -e "${BLUE}═══ Installation Receipts ═══${NC}"

        while IFS= read -r -d '' receipt; do
            echo -e "  ${YELLOW}✓${NC} $receipt"
            found_paths+=("$receipt")
        done < <(find /private/var/db/receipts -name "*${bundle_id}*" -print0 2>/dev/null || true)
    fi

    # Summary
    echo ""
    echo -e "${BLUE}═══ Summary ═══${NC}"
    echo -e "  Files found: ${GREEN}${#found_paths[@]}${NC}"
    echo -e "  Total size: ${GREEN}$(human_size $total_size)${NC}"
    echo ""
    echo -e "${GRAY}This is a scan only - no files were deleted.${NC}"
    echo -e "${GRAY}Review paths carefully before deletion.${NC}"

    # Output for scripting
    if [[ "${OUTPUT_PATHS:-}" == "true" ]]; then
        echo ""
        echo "# Paths found:"
        printf '%s\n' "${found_paths[@]}"
    fi
}

main "$@"
