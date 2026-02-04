#!/bin/bash
# macOS System Optimization Script
# Performs safe system maintenance and optimization tasks
# Usage: ./optimize.sh [--dry-run] [--tasks <task1,task2>]

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
TASKS=""
ERRORS=0
WARNINGS=0

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --tasks) TASKS="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# Section header
section() {
    echo ""
    echo -e "${CYAN}═══ $1 ═══${NC}"
}

# Check if task should run
should_run_task() {
    local task="$1"
    if [[ -z "$TASKS" ]]; then
        return 0
    fi
    [[ ",$TASKS," == *",$task,"* ]]
}

# Check if process is running
is_process_running() {
    pgrep -x "$1" >/dev/null 2>&1
}

# Check Time Machine backup status
is_timemachine_running() {
    tmutil status 2>/dev/null | grep -q "Running = 1"
}

# Check AC power (for laptops)
is_on_ac_power() {
    local battery_info=$(pmset -g batt 2>/dev/null)
    if echo "$battery_info" | grep -q "AC Power"; then
        return 0
    fi
    # If no battery (desktop), assume AC
    if ! echo "$battery_info" | grep -q "Battery"; then
        return 0
    fi
    return 1
}

# Check memory pressure
get_memory_pressure() {
    memory_pressure -Q 2>/dev/null | grep -oE '[0-9]+%' | tr -d '%' || echo "0"
}

# DNS Cache Flush
task_flush_dns() {
    section "Flushing DNS Cache"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${YELLOW}○ Would flush DNS cache${NC}"
        return
    fi

    if sudo dscacheutil -flushcache 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Flushed DNS cache"
    else
        echo -e "  ${RED}✗${NC} Failed to flush DNS cache"
        ((ERRORS++))
        return
    fi

    if sudo killall -HUP mDNSResponder 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Restarted mDNSResponder"
    else
        echo -e "  ${YELLOW}!${NC} Could not restart mDNSResponder"
        ((WARNINGS++))
    fi
}

# Rebuild Launch Services Database
task_rebuild_launch_services() {
    section "Rebuilding Launch Services Database"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${YELLOW}○ Would rebuild Launch Services database${NC}"
        return
    fi

    local lsregister="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

    if [[ -x "$lsregister" ]]; then
        echo -e "  ${GRAY}This may take a moment...${NC}"
        if "$lsregister" -kill -r -domain local -domain system -domain user 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} Rebuilt Launch Services database"
            echo -e "  ${GRAY}Note: 'Open With' menu will be refreshed${NC}"
        else
            echo -e "  ${RED}✗${NC} Failed to rebuild Launch Services database"
            ((ERRORS++))
        fi
    else
        echo -e "  ${RED}✗${NC} lsregister not found"
        ((ERRORS++))
    fi
}

# Clear QuickLook Cache
task_clear_quicklook() {
    section "Clearing QuickLook Thumbnail Cache"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${YELLOW}○ Would clear QuickLook cache${NC}"
        return
    fi

    if qlmanage -r cache 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Cleared QuickLook cache"
    else
        echo -e "  ${YELLOW}!${NC} Could not clear QuickLook cache"
        ((WARNINGS++))
    fi

    # Also reset QuickLook generators
    if qlmanage -r 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Reset QuickLook generators"
    fi
}

# Clear Icon Services Cache
task_clear_icon_cache() {
    section "Clearing Icon Services Cache"

    local icon_cache="$HOME/Library/Caches/com.apple.iconservices.store"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${YELLOW}○ Would clear icon cache${NC}"
        return
    fi

    if [[ -d "$icon_cache" ]]; then
        if rm -rf "$icon_cache" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} Cleared icon cache"
        else
            echo -e "  ${RED}✗${NC} Failed to clear icon cache"
            ((ERRORS++))
        fi
    else
        echo -e "  ${GRAY}Icon cache not found (already clean)${NC}"
    fi

    # Restart Dock to refresh icons
    killall Dock 2>/dev/null || true
    echo -e "  ${GREEN}✓${NC} Restarted Dock"
}

# Clear Font Cache
task_clear_font_cache() {
    section "Clearing Font Cache"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${YELLOW}○ Would clear font caches${NC}"
        return
    fi

    if sudo atsutil databases -remove 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Removed font databases"
    else
        echo -e "  ${YELLOW}!${NC} Could not remove font databases"
        ((WARNINGS++))
    fi

    # Restart font server
    atsutil server -shutdown 2>/dev/null || true
    sleep 1
    atsutil server -ping 2>/dev/null || true
    echo -e "  ${GREEN}✓${NC} Restarted font server"
}

# Purge Inactive Memory
task_purge_memory() {
    section "Purging Inactive Memory"

    # Check memory pressure first
    local pressure=$(get_memory_pressure)
    if [[ $pressure -lt 50 ]]; then
        echo -e "  ${GRAY}Memory pressure is low ($pressure%), skipping purge${NC}"
        return
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${YELLOW}○ Would purge inactive memory (pressure: $pressure%)${NC}"
        return
    fi

    echo -e "  ${GRAY}Memory pressure: $pressure%${NC}"

    if sudo purge 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Purged inactive memory"

        # Show new memory state
        local new_pressure=$(get_memory_pressure)
        echo -e "  ${GRAY}New memory pressure: $new_pressure%${NC}"
    else
        echo -e "  ${RED}✗${NC} Failed to purge memory"
        ((ERRORS++))
    fi
}

# Rebuild Spotlight Index
task_rebuild_spotlight() {
    section "Rebuilding Spotlight Index"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${YELLOW}○ Would rebuild Spotlight index${NC}"
        echo -e "  ${GRAY}Warning: This can take hours for large disks${NC}"
        return
    fi

    echo -e "  ${YELLOW}!${NC} This will take significant time. Continue? (y/N)"
    read -r confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "  ${GRAY}Skipped${NC}"
        return
    fi

    if sudo mdutil -E / 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Started Spotlight reindex"
        echo -e "  ${GRAY}Progress: mdutil -s /${NC}"
    else
        echo -e "  ${RED}✗${NC} Failed to rebuild Spotlight"
        ((ERRORS++))
    fi
}

# Restart Finder
task_restart_finder() {
    section "Restarting Finder"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${YELLOW}○ Would restart Finder${NC}"
        return
    fi

    killall Finder 2>/dev/null || true
    echo -e "  ${GREEN}✓${NC} Restarted Finder"
}

# Restart SystemUIServer (menu bar)
task_restart_menubar() {
    section "Restarting Menu Bar"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${YELLOW}○ Would restart SystemUIServer${NC}"
        return
    fi

    killall SystemUIServer 2>/dev/null || true
    echo -e "  ${GREEN}✓${NC} Restarted SystemUIServer"

    # Also restart ControlCenter on Big Sur+
    killall ControlCenter 2>/dev/null || true
    echo -e "  ${GREEN}✓${NC} Restarted ControlCenter"
}

# Clear System Logs (old)
task_clear_old_logs() {
    section "Clearing Old System Logs"

    if [[ "$DRY_RUN" == "true" ]]; then
        local count=$(sudo find /private/var/log -type f -mtime +7 2>/dev/null | wc -l | tr -d ' ')
        echo -e "  ${YELLOW}○ Would delete $count log files older than 7 days${NC}"
        return
    fi

    # Clear old system logs (older than 7 days)
    local deleted=$(sudo find /private/var/log -type f -mtime +7 -delete -print 2>/dev/null | wc -l | tr -d ' ')
    echo -e "  ${GREEN}✓${NC} Deleted $deleted old log files"

    # Clear ASL logs
    if sudo rm -rf /private/var/log/asl/*.asl 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Cleared ASL logs"
    fi
}

# Clear Crash Reports
task_clear_crash_reports() {
    section "Clearing Crash Reports"

    local user_reports="$HOME/Library/Logs/DiagnosticReports"
    local system_reports="/Library/Logs/DiagnosticReports"

    if [[ "$DRY_RUN" == "true" ]]; then
        local count=0
        [[ -d "$user_reports" ]] && count=$((count + $(find "$user_reports" -type f -mtime +7 2>/dev/null | wc -l)))
        [[ -d "$system_reports" ]] && count=$((count + $(sudo find "$system_reports" -type f -mtime +7 2>/dev/null | wc -l)))
        echo -e "  ${YELLOW}○ Would delete $count crash reports older than 7 days${NC}"
        return
    fi

    # User crash reports
    if [[ -d "$user_reports" ]]; then
        find "$user_reports" -type f -mtime +7 -delete 2>/dev/null || true
        echo -e "  ${GREEN}✓${NC} Cleared old user crash reports"
    fi

    # System crash reports
    if [[ -d "$system_reports" ]]; then
        sudo find "$system_reports" -type f -mtime +7 -delete 2>/dev/null || true
        echo -e "  ${GREEN}✓${NC} Cleared old system crash reports"
    fi
}

# Rebuild dyld shared cache
task_rebuild_dyld() {
    section "Rebuilding Dynamic Linker Cache"

    # Check if already rebuilt recently (within 24h)
    local dyld_marker="/tmp/.macos_cleaner_dyld_rebuilt"
    if [[ -f "$dyld_marker" ]]; then
        local age=$(($(date +%s) - $(stat -f %m "$dyld_marker")))
        if [[ $age -lt 86400 ]]; then
            echo -e "  ${GRAY}Already rebuilt within 24 hours, skipping${NC}"
            return
        fi
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${YELLOW}○ Would rebuild dyld shared cache${NC}"
        echo -e "  ${GRAY}Warning: Takes 2-3 minutes, requires reboot${NC}"
        return
    fi

    echo -e "  ${YELLOW}!${NC} This takes 2-3 minutes and requires reboot. Continue? (y/N)"
    read -r confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "  ${GRAY}Skipped${NC}"
        return
    fi

    echo -e "  ${GRAY}Rebuilding cache (this may take a few minutes)...${NC}"
    if sudo update_dyld_shared_cache -force 2>/dev/null; then
        touch "$dyld_marker"
        echo -e "  ${GREEN}✓${NC} Rebuilt dyld cache"
        echo -e "  ${YELLOW}!${NC} Reboot required to apply changes"
    else
        echo -e "  ${RED}✗${NC} Failed to rebuild dyld cache"
        ((ERRORS++))
    fi
}

# Main
main() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${BLUE}║     macOS Optimization (DRY RUN)       ║${NC}"
    else
        echo -e "${BLUE}║     macOS Optimization                 ║${NC}"
    fi
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

    # Safety checks
    section "Pre-flight Checks"

    # Check Time Machine
    if is_timemachine_running; then
        echo -e "  ${YELLOW}!${NC} Time Machine backup in progress"
        echo -e "  ${GRAY}Some operations skipped to avoid conflicts${NC}"
        ((WARNINGS++))
    else
        echo -e "  ${GREEN}✓${NC} No Time Machine backup running"
    fi

    # Check AC power
    if ! is_on_ac_power; then
        echo -e "  ${YELLOW}!${NC} Running on battery power"
        echo -e "  ${GRAY}Connect to power for best results${NC}"
        ((WARNINGS++))
    else
        echo -e "  ${GREEN}✓${NC} AC power connected"
    fi

    # Check memory pressure
    local pressure=$(get_memory_pressure)
    if [[ $pressure -gt 80 ]]; then
        echo -e "  ${YELLOW}!${NC} High memory pressure ($pressure%)"
    else
        echo -e "  ${GREEN}✓${NC} Memory pressure normal ($pressure%)"
    fi

    # Run selected tasks
    should_run_task "dns" && task_flush_dns
    should_run_task "launch_services" && task_rebuild_launch_services
    should_run_task "quicklook" && task_clear_quicklook
    should_run_task "icon_cache" && task_clear_icon_cache
    should_run_task "font_cache" && task_clear_font_cache
    should_run_task "memory" && task_purge_memory
    should_run_task "logs" && task_clear_old_logs
    should_run_task "crash_reports" && task_clear_crash_reports
    should_run_task "finder" && task_restart_finder
    should_run_task "menubar" && task_restart_menubar

    # Optional intensive tasks (only if explicitly requested)
    if [[ -n "$TASKS" ]]; then
        should_run_task "spotlight" && task_rebuild_spotlight
        should_run_task "dyld" && task_rebuild_dyld
    fi

    # Summary
    section "Summary"
    if [[ $ERRORS -gt 0 ]]; then
        echo -e "  Errors: ${RED}$ERRORS${NC}"
    fi
    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "  Warnings: ${YELLOW}$WARNINGS${NC}"
    fi
    if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
        echo -e "  ${GREEN}All tasks completed successfully${NC}"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo ""
        echo -e "${GRAY}Run without --dry-run to apply changes${NC}"
    fi
}

main
