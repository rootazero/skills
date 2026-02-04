#!/bin/bash
# macOS Disk Usage Analyzer
# Provides safe analysis of disk usage without any destructive operations
# Usage: ./analyze.sh [--quick|--full]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
NC='\033[0m'

# Icons
ICON_FOLDER="📁"
ICON_FILE="📄"
ICON_CACHE="🗑️"
ICON_DEV="🛠️"
ICON_BROWSER="🌐"
ICON_TRASH="🗑️"

# Human readable size
human_size() {
    local bytes=$1
    if [[ $bytes -ge 1073741824 ]]; then
        echo "$(echo "scale=1; $bytes / 1073741824" | bc)G"
    elif [[ $bytes -ge 1048576 ]]; then
        echo "$(echo "scale=1; $bytes / 1048576" | bc)M"
    elif [[ $bytes -ge 1024 ]]; then
        echo "$(echo "scale=0; $bytes / 1024" | bc)K"
    else
        echo "${bytes}B"
    fi
}

# Get directory size in KB
get_size_kb() {
    local path="$1"
    if [[ -d "$path" ]]; then
        du -sk "$path" 2>/dev/null | awk '{print $1}' || echo "0"
    else
        echo "0"
    fi
}

# Print section header
section() {
    echo ""
    echo -e "${BLUE}═══ $1 ═══${NC}"
}

# Print item with size
print_item() {
    local icon="$1"
    local name="$2"
    local size_kb="$3"
    local size_bytes=$((size_kb * 1024))
    local size_human=$(human_size $size_bytes)

    if [[ $size_kb -gt 1048576 ]]; then  # > 1GB
        echo -e "  ${icon} ${name}: ${RED}${size_human}${NC}"
    elif [[ $size_kb -gt 102400 ]]; then  # > 100MB
        echo -e "  ${icon} ${name}: ${YELLOW}${size_human}${NC}"
    elif [[ $size_kb -gt 0 ]]; then
        echo -e "  ${icon} ${name}: ${GREEN}${size_human}${NC}"
    fi
}

# Main analysis
main() {
    local mode="${1:-quick}"

    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     macOS Disk Usage Analyzer          ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

    # Disk overview
    section "Disk Overview"
    df -h / | tail -1 | awk '{printf "  Total: %s | Used: %s (%s) | Available: %s\n", $2, $3, $5, $4}'

    # User caches
    section "User Caches ${ICON_CACHE}"
    local user_caches=$(get_size_kb ~/Library/Caches)
    print_item "$ICON_FOLDER" "~/Library/Caches" "$user_caches"

    local user_logs=$(get_size_kb ~/Library/Logs)
    print_item "$ICON_FOLDER" "~/Library/Logs" "$user_logs"

    local saved_state=$(get_size_kb ~/Library/Saved\ Application\ State)
    print_item "$ICON_FOLDER" "Saved Application State" "$saved_state"

    local crash_reports=$(get_size_kb ~/Library/Logs/DiagnosticReports)
    print_item "$ICON_FOLDER" "Crash Reports" "$crash_reports"

    # Browser caches
    section "Browser Caches ${ICON_BROWSER}"

    # Chrome
    if [[ -d ~/Library/Caches/Google/Chrome ]]; then
        local chrome=$(get_size_kb ~/Library/Caches/Google/Chrome)
        print_item "$ICON_BROWSER" "Google Chrome" "$chrome"
    fi

    # Safari
    if [[ -d ~/Library/Caches/com.apple.Safari ]]; then
        local safari=$(get_size_kb ~/Library/Caches/com.apple.Safari)
        print_item "$ICON_BROWSER" "Safari" "$safari"
    fi

    # Firefox
    if [[ -d ~/Library/Caches/Firefox ]]; then
        local firefox=$(get_size_kb ~/Library/Caches/Firefox)
        print_item "$ICON_BROWSER" "Firefox" "$firefox"
    fi

    # Edge
    if [[ -d ~/Library/Caches/Microsoft\ Edge ]]; then
        local edge=$(get_size_kb ~/Library/Caches/Microsoft\ Edge)
        print_item "$ICON_BROWSER" "Microsoft Edge" "$edge"
    fi

    # Arc
    if [[ -d ~/Library/Caches/company.thebrowser.Browser ]]; then
        local arc=$(get_size_kb ~/Library/Caches/company.thebrowser.Browser)
        print_item "$ICON_BROWSER" "Arc" "$arc"
    fi

    # Developer tools
    section "Developer Caches ${ICON_DEV}"

    # Xcode
    if [[ -d ~/Library/Developer/Xcode/DerivedData ]]; then
        local xcode_derived=$(get_size_kb ~/Library/Developer/Xcode/DerivedData)
        print_item "$ICON_DEV" "Xcode DerivedData" "$xcode_derived"
    fi

    if [[ -d ~/Library/Developer/Xcode/Archives ]]; then
        local xcode_archives=$(get_size_kb ~/Library/Developer/Xcode/Archives)
        print_item "$ICON_DEV" "Xcode Archives" "$xcode_archives"
    fi

    if [[ -d ~/Library/Developer/Xcode/iOS\ DeviceSupport ]]; then
        local xcode_device=$(get_size_kb ~/Library/Developer/Xcode/iOS\ DeviceSupport)
        print_item "$ICON_DEV" "iOS Device Support" "$xcode_device"
    fi

    # CocoaPods
    if [[ -d ~/Library/Caches/CocoaPods ]]; then
        local cocoapods=$(get_size_kb ~/Library/Caches/CocoaPods)
        print_item "$ICON_DEV" "CocoaPods" "$cocoapods"
    fi

    # npm
    if [[ -d ~/.npm ]]; then
        local npm_cache=$(get_size_kb ~/.npm)
        print_item "$ICON_DEV" "npm cache" "$npm_cache"
    fi

    # Cargo (Rust)
    if [[ -d ~/.cargo/registry ]]; then
        local cargo=$(get_size_kb ~/.cargo/registry)
        print_item "$ICON_DEV" "Cargo registry" "$cargo"
    fi

    # Gradle
    if [[ -d ~/.gradle/caches ]]; then
        local gradle=$(get_size_kb ~/.gradle/caches)
        print_item "$ICON_DEV" "Gradle caches" "$gradle"
    fi

    # Maven
    if [[ -d ~/.m2/repository ]]; then
        local maven=$(get_size_kb ~/.m2/repository)
        print_item "$ICON_DEV" "Maven repository" "$maven"
    fi

    # pip
    if [[ -d ~/Library/Caches/pip ]]; then
        local pip_cache=$(get_size_kb ~/Library/Caches/pip)
        print_item "$ICON_DEV" "pip cache" "$pip_cache"
    fi

    # Homebrew
    if [[ -d "$(brew --cache 2>/dev/null)" ]]; then
        local brew_cache=$(get_size_kb "$(brew --cache)")
        print_item "$ICON_DEV" "Homebrew cache" "$brew_cache"
    fi

    # Docker
    if [[ -d ~/Library/Containers/com.docker.docker ]]; then
        local docker=$(get_size_kb ~/Library/Containers/com.docker.docker)
        print_item "$ICON_DEV" "Docker" "$docker"
    fi

    # Trash
    section "Trash ${ICON_TRASH}"
    if [[ -d ~/.Trash ]]; then
        local trash=$(get_size_kb ~/.Trash)
        print_item "$ICON_TRASH" "User Trash" "$trash"
    fi

    # System (requires sudo)
    if [[ "$mode" == "--full" ]]; then
        section "System Caches (sudo required)"
        echo -e "  ${GRAY}Run with sudo for system cache analysis${NC}"

        if sudo -n true 2>/dev/null; then
            local sys_caches=$(sudo du -sk /Library/Caches 2>/dev/null | awk '{print $1}' || echo "0")
            print_item "$ICON_FOLDER" "/Library/Caches" "$sys_caches"

            local sys_logs=$(sudo du -sk /private/var/log 2>/dev/null | awk '{print $1}' || echo "0")
            print_item "$ICON_FOLDER" "/private/var/log" "$sys_logs"

            local sys_tmp=$(sudo du -sk /private/tmp 2>/dev/null | awk '{print $1}' || echo "0")
            print_item "$ICON_FOLDER" "/private/tmp" "$sys_tmp"
        fi
    fi

    # Time Machine snapshots
    section "Time Machine"
    if command -v tmutil &>/dev/null; then
        local snapshots=$(tmutil listlocalsnapshots / 2>/dev/null | grep -c "com.apple.TimeMachine" || echo "0")
        if [[ $snapshots -gt 0 ]]; then
            echo -e "  ${YELLOW}Local snapshots: ${snapshots}${NC}"
            echo -e "  ${GRAY}Run: tmutil listlocalsnapshots /${NC}"
        else
            echo -e "  ${GREEN}No local snapshots${NC}"
        fi
    fi

    # iOS Backups
    section "iOS Backups"
    if [[ -d ~/Library/Application\ Support/MobileSync/Backup ]]; then
        local ios_backups=$(get_size_kb ~/Library/Application\ Support/MobileSync/Backup)
        print_item "$ICON_FOLDER" "iOS Backups" "$ios_backups"
    else
        echo -e "  ${GREEN}No iOS backups${NC}"
    fi

    # Summary
    section "Summary"
    local total_cleanable=$((user_caches + user_logs + saved_state + crash_reports + trash))
    local total_bytes=$((total_cleanable * 1024))
    echo -e "  Estimated cleanable (user caches): ${YELLOW}$(human_size $total_bytes)${NC}"
    echo ""
    echo -e "  ${GRAY}This is an analysis only - no files were deleted.${NC}"
    echo -e "  ${GRAY}Review before cleaning. Some caches improve performance.${NC}"
}

main "$@"
