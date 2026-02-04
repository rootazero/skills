#!/bin/bash
# macOS System Status Dashboard
# Displays real-time system information and health metrics
# Usage: ./status.sh [--brief]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
WHITE='\033[1;37m'
NC='\033[0m'

# Config
BRIEF_MODE=false
[[ "${1:-}" == "--brief" ]] && BRIEF_MODE=true

# Progress bar
progress_bar() {
    local percent=$1
    local width=${2:-20}
    local filled=$((percent * width / 100))
    local empty=$((width - filled))

    local color="$GREEN"
    [[ $percent -gt 70 ]] && color="$YELLOW"
    [[ $percent -gt 90 ]] && color="$RED"

    printf "${color}"
    printf '█%.0s' $(seq 1 $filled 2>/dev/null || true)
    printf "${GRAY}"
    printf '░%.0s' $(seq 1 $empty 2>/dev/null || true)
    printf "${NC}"
}

# Section header
section() {
    echo ""
    echo -e "${CYAN}═══ $1 ═══${NC}"
}

# Get CPU info
get_cpu_info() {
    section "CPU"

    # Model
    local cpu_model=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")
    echo -e "  Model: ${WHITE}$cpu_model${NC}"

    # Core count
    local cores=$(sysctl -n hw.ncpu 2>/dev/null || echo "?")
    local pcores=$(sysctl -n hw.perflevel0.physicalcpu 2>/dev/null || echo "")
    local ecores=$(sysctl -n hw.perflevel1.physicalcpu 2>/dev/null || echo "")

    if [[ -n "$pcores" && -n "$ecores" ]]; then
        echo -e "  Cores: ${WHITE}$cores${NC} (${pcores}P + ${ecores}E)"
    else
        echo -e "  Cores: ${WHITE}$cores${NC}"
    fi

    # Load average
    local load_raw=$(uptime | sed 's/.*load averages*: *//')
    local load1=$(echo "$load_raw" | awk '{print $1}')
    local load5=$(echo "$load_raw" | awk '{print $2}')
    local load15=$(echo "$load_raw" | awk '{print $3}')
    echo -e "  Load: ${WHITE}$load1${NC} (1m) ${WHITE}$load5${NC} (5m) ${WHITE}$load15${NC} (15m)"

    # CPU usage (top 3 processes)
    if [[ "$BRIEF_MODE" == "false" ]]; then
        echo -e "  ${GRAY}Top CPU consumers:${NC}"
        ps -Aceo %cpu,comm | sort -rn | head -3 | while read cpu cmd; do
            [[ -z "$cpu" ]] && continue
            printf "    %5s%%  %s\n" "$cpu" "$cmd"
        done
    fi
}

# Get memory info
get_memory_info() {
    section "Memory"

    # Total memory
    local total_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
    local total_gb=$(echo "scale=1; $total_bytes / 1073741824" | bc)

    # Parse vm_stat
    local page_size=$(vm_stat | grep "page size" | awk '{print $8}')
    local vm_stats=$(vm_stat)

    local pages_free=$(echo "$vm_stats" | grep "Pages free" | awk '{print $3}' | tr -d '.')
    local pages_active=$(echo "$vm_stats" | grep "Pages active" | awk '{print $3}' | tr -d '.')
    local pages_inactive=$(echo "$vm_stats" | grep "Pages inactive" | awk '{print $3}' | tr -d '.')
    local pages_wired=$(echo "$vm_stats" | grep "Pages wired" | awk '{print $4}' | tr -d '.')
    local pages_compressed=$(echo "$vm_stats" | grep "Pages occupied by compressor" | awk '{print $5}' | tr -d '.')

    # Calculate used memory
    local used_pages=$((pages_active + pages_wired + pages_compressed))
    local used_bytes=$((used_pages * page_size))
    local used_gb=$(echo "scale=1; $used_bytes / 1073741824" | bc)

    local free_bytes=$((pages_free * page_size + pages_inactive * page_size))
    local free_gb=$(echo "scale=1; $free_bytes / 1073741824" | bc)

    local percent=$((used_bytes * 100 / total_bytes))

    echo -e "  Total: ${WHITE}${total_gb}GB${NC}"
    echo -ne "  Used:  ${WHITE}${used_gb}GB${NC} ($percent%) "
    progress_bar $percent
    echo ""
    echo -e "  Free:  ${WHITE}${free_gb}GB${NC}"

    # Memory pressure (based on usage percentage)
    local pressure_level="Normal"
    local pressure_color="$GREEN"
    if [[ $percent -gt 80 ]]; then
        pressure_level="High"
        pressure_color="$RED"
    elif [[ $percent -gt 60 ]]; then
        pressure_level="Moderate"
        pressure_color="$YELLOW"
    fi
    echo -e "  Pressure: ${pressure_color}$pressure_level${NC}"

    # Swap
    local swap_info=$(sysctl -n vm.swapusage 2>/dev/null || echo "")
    if [[ -n "$swap_info" ]]; then
        local swap_used=$(echo "$swap_info" | grep -oE 'used = [0-9.]+[MG]' | awk '{print $3}')
        echo -e "  Swap used: ${WHITE}$swap_used${NC}"
    fi
}

# Get disk info
get_disk_info() {
    section "Disk"

    # Main disk
    local disk_info=$(df -h / | tail -1)
    local disk_total=$(echo "$disk_info" | awk '{print $2}')
    local disk_used=$(echo "$disk_info" | awk '{print $3}')
    local disk_free=$(echo "$disk_info" | awk '{print $4}')
    local disk_percent=$(echo "$disk_info" | awk '{print $5}' | tr -d '%')

    echo -e "  Total: ${WHITE}$disk_total${NC}"
    echo -ne "  Used:  ${WHITE}$disk_used${NC} ($disk_percent%) "
    progress_bar $disk_percent
    echo ""
    echo -e "  Free:  ${WHITE}$disk_free${NC}"

    # APFS container info
    if [[ "$BRIEF_MODE" == "false" ]]; then
        local container=$(diskutil apfs list 2>/dev/null | grep "Container Reference" | head -1 | awk '{print $NF}')
        if [[ -n "$container" ]]; then
            local purgeable=$(diskutil apfs list 2>/dev/null | grep "Purgeable" | head -1 | awk '{print $NF}')
            if [[ -n "$purgeable" ]]; then
                echo -e "  ${GRAY}Purgeable: $purgeable${NC}"
            fi
        fi
    fi

    # Time Machine snapshots
    local snapshots=$(tmutil listlocalsnapshots / 2>/dev/null | grep -c "com.apple.TimeMachine" || echo "0")
    if [[ $snapshots -gt 0 ]]; then
        echo -e "  ${YELLOW}Local TM snapshots: $snapshots${NC}"
    fi
}

# Get battery info (laptops only)
get_battery_info() {
    local battery_info=$(pmset -g batt 2>/dev/null)

    # Check if battery exists
    if ! echo "$battery_info" | grep -q "InternalBattery"; then
        return
    fi

    section "Battery"

    # Charge level
    local charge=$(echo "$battery_info" | grep -oE '[0-9]+%' | head -1 | tr -d '%')
    local status=$(echo "$battery_info" | grep -oE '(charging|discharging|charged|AC attached)' | head -1)

    local status_icon=""
    local status_color="$NC"
    case "$status" in
        "charging") status_icon="⚡"; status_color="$GREEN" ;;
        "charged") status_icon="✓"; status_color="$GREEN" ;;
        "discharging") status_icon="🔋"; status_color="$YELLOW" ;;
        *) status_icon="⚡"; status_color="$NC" ;;
    esac

    echo -ne "  Charge: ${WHITE}${charge}%${NC} "
    progress_bar $charge
    echo ""
    echo -e "  Status: ${status_color}${status_icon} ${status:-Unknown}${NC}"

    # Time remaining
    local remaining=$(echo "$battery_info" | grep -oE '[0-9]+:[0-9]+ remaining' || echo "")
    if [[ -n "$remaining" ]]; then
        echo -e "  Remaining: ${WHITE}$remaining${NC}"
    fi

    # Battery health (if available)
    if [[ "$BRIEF_MODE" == "false" ]]; then
        local health=$(system_profiler SPPowerDataType 2>/dev/null | grep "Condition" | awk -F': ' '{print $2}')
        if [[ -n "$health" ]]; then
            local health_color="$GREEN"
            [[ "$health" != "Normal" ]] && health_color="$YELLOW"
            echo -e "  Health: ${health_color}$health${NC}"
        fi

        local cycles=$(system_profiler SPPowerDataType 2>/dev/null | grep "Cycle Count" | awk -F': ' '{print $2}')
        if [[ -n "$cycles" ]]; then
            echo -e "  Cycles: ${WHITE}$cycles${NC}"
        fi
    fi
}

# Get network info
get_network_info() {
    section "Network"

    # Active interface
    local active_if=$(route get default 2>/dev/null | grep interface | awk '{print $2}')

    if [[ -z "$active_if" ]]; then
        echo -e "  ${GRAY}No active network connection${NC}"
        return
    fi

    # Interface type
    local if_type="Unknown"
    case "$active_if" in
        en0) if_type="Wi-Fi" ;;
        en1|en2|en3|en4|en5) if_type="Ethernet" ;;
        bridge*) if_type="Bridge" ;;
        utun*) if_type="VPN" ;;
    esac

    echo -e "  Interface: ${WHITE}$active_if${NC} ($if_type)"

    # IP address
    local ip=$(ifconfig "$active_if" 2>/dev/null | grep "inet " | awk '{print $2}')
    if [[ -n "$ip" ]]; then
        echo -e "  IP: ${WHITE}$ip${NC}"
    fi

    # Wi-Fi info
    if [[ "$if_type" == "Wi-Fi" ]]; then
        local ssid=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null | grep " SSID" | awk -F': ' '{print $2}')
        if [[ -n "$ssid" ]]; then
            echo -e "  SSID: ${WHITE}$ssid${NC}"
        fi
    fi

    # DNS servers
    if [[ "$BRIEF_MODE" == "false" ]]; then
        local dns=$(scutil --dns 2>/dev/null | grep "nameserver\[0\]" | head -1 | awk '{print $3}')
        if [[ -n "$dns" ]]; then
            echo -e "  DNS: ${WHITE}$dns${NC}"
        fi
    fi
}

# Get system info
get_system_info() {
    section "System"

    # macOS version
    local macos=$(sw_vers -productVersion 2>/dev/null || echo "Unknown")
    local build=$(sw_vers -buildVersion 2>/dev/null || echo "")
    echo -e "  macOS: ${WHITE}$macos${NC} ($build)"

    # Machine model
    local model=$(sysctl -n hw.model 2>/dev/null || echo "Unknown")
    echo -e "  Model: ${WHITE}$model${NC}"

    # Uptime
    local uptime_secs=$(sysctl -n kern.boottime 2>/dev/null | awk -F'sec = ' '{print $2}' | awk -F',' '{print $1}')
    local now_secs=$(date +%s)
    local uptime_days=$(( (now_secs - uptime_secs) / 86400 ))
    local uptime_hours=$(( ((now_secs - uptime_secs) % 86400) / 3600 ))
    local uptime_mins=$(( ((now_secs - uptime_secs) % 3600) / 60 ))

    local uptime_str=""
    [[ $uptime_days -gt 0 ]] && uptime_str="${uptime_days}d "
    uptime_str="${uptime_str}${uptime_hours}h ${uptime_mins}m"
    echo -e "  Uptime: ${WHITE}$uptime_str${NC}"

    # User processes
    local procs=$(ps aux | wc -l | tr -d ' ')
    echo -e "  Processes: ${WHITE}$procs${NC}"
}

# Calculate health score
get_health_score() {
    section "Health Score"

    local score=100
    local issues=()

    # Check disk usage
    local disk_percent=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
    if [[ $disk_percent -gt 90 ]]; then
        score=$((score - 30))
        issues+=("Disk usage critical (${disk_percent}%)")
    elif [[ $disk_percent -gt 80 ]]; then
        score=$((score - 15))
        issues+=("Disk usage high (${disk_percent}%)")
    fi

    # Check memory usage
    local total_mem=$(sysctl -n hw.memsize 2>/dev/null || echo "1")
    local page_size=$(vm_stat 2>/dev/null | grep "page size" | awk '{print $8}')
    local pages_active=$(vm_stat 2>/dev/null | grep "Pages active" | awk '{print $3}' | tr -d '.')
    local pages_wired=$(vm_stat 2>/dev/null | grep "Pages wired" | awk '{print $4}' | tr -d '.')
    local pages_compressed=$(vm_stat 2>/dev/null | grep "Pages occupied by compressor" | awk '{print $5}' | tr -d '.')
    local used_mem=$(( (pages_active + pages_wired + pages_compressed) * page_size ))
    local mem_percent=$((used_mem * 100 / total_mem))

    if [[ $mem_percent -gt 85 ]]; then
        score=$((score - 25))
        issues+=("Memory usage critical (${mem_percent}%)")
    elif [[ $mem_percent -gt 70 ]]; then
        score=$((score - 10))
        issues+=("Memory usage elevated (${mem_percent}%)")
    fi

    # Check load average
    local load1=$(uptime | sed 's/.*load averages*: *//' | awk '{print $1}')
    local cores=$(sysctl -n hw.ncpu 2>/dev/null || echo "4")
    local load_ratio=$(echo "scale=2; $load1 / $cores" | bc 2>/dev/null || echo "0")

    if (( $(echo "$load_ratio > 2" | bc -l) )); then
        score=$((score - 20))
        issues+=("High CPU load ($load1)")
    elif (( $(echo "$load_ratio > 1" | bc -l) )); then
        score=$((score - 10))
        issues+=("Elevated CPU load ($load1)")
    fi

    # Check battery (if laptop)
    local charge=$(pmset -g batt 2>/dev/null | grep -oE '[0-9]+%' | head -1 | tr -d '%')
    if [[ -n "$charge" && $charge -lt 20 ]]; then
        score=$((score - 10))
        issues+=("Low battery (${charge}%)")
    fi

    # Ensure score is not negative
    [[ $score -lt 0 ]] && score=0

    # Display score with color
    local score_color="$GREEN"
    [[ $score -lt 90 ]] && score_color="$YELLOW"
    [[ $score -lt 70 ]] && score_color="$RED"

    echo -ne "  Score: ${score_color}${score}/100${NC} "
    progress_bar $score 25
    echo ""

    # Display issues
    if [[ ${#issues[@]} -gt 0 ]]; then
        echo -e "  ${YELLOW}Issues:${NC}"
        for issue in "${issues[@]}"; do
            echo -e "    - $issue"
        done
    else
        echo -e "  ${GREEN}No issues detected${NC}"
    fi
}

# Main
main() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     macOS System Status                ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

    get_system_info
    get_cpu_info
    get_memory_info
    get_disk_info
    get_battery_info
    get_network_info
    get_health_score

    echo ""
    echo -e "${GRAY}Run with --brief for compact output${NC}"
}

main
