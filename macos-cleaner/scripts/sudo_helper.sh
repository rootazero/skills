#!/bin/bash
# Sudo Session Helper for macOS Cleaner
# Handles Touch ID detection, password auth, and session keepalive
# Usage: source sudo_helper.sh; request_sudo; ... ; cleanup_sudo

set -euo pipefail

# Global state
MACOS_CLEANER_SUDO_PID=""
MACOS_CLEANER_SUDO_ACTIVE="false"

# Colors
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
GRAY='\033[0;90m'
NC='\033[0m'

# Check if Touch ID is configured for sudo
check_touchid() {
    # Check sudo_local first (macOS Sonoma+)
    if [[ -f /etc/pam.d/sudo_local ]]; then
        grep -q "pam_tid.so" /etc/pam.d/sudo_local 2>/dev/null && return 0
    fi

    # Fallback to checking sudo directly
    if [[ -f /etc/pam.d/sudo ]]; then
        grep -q "pam_tid.so" /etc/pam.d/sudo 2>/dev/null && return 0
    fi

    return 1
}

# Detect clamshell mode (lid closed)
is_clamshell() {
    if ! command -v ioreg &>/dev/null; then
        return 1
    fi

    local state
    state=$(ioreg -r -k AppleClamshellState -d 4 2>/dev/null | grep "AppleClamshellState" | head -1 || true)

    if [[ "$state" =~ \"AppleClamshellState\"\ =\ Yes ]]; then
        return 0  # Lid closed
    fi

    return 1  # Lid open
}

# Start sudo keepalive in background
start_keepalive() {
    # Kill existing keepalive if any
    stop_keepalive

    # Start new keepalive process
    (
        # Initial delay to let sudo cache stabilize
        sleep 2

        while true; do
            if ! sudo -n -v 2>/dev/null; then
                exit 1
            fi
            sleep 30
            # Exit if parent process is gone
            kill -0 $$ 2>/dev/null || exit 0
        done
    ) >/dev/null 2>&1 &

    MACOS_CLEANER_SUDO_PID=$!
    export MACOS_CLEANER_SUDO_PID
}

# Stop sudo keepalive
stop_keepalive() {
    if [[ -n "${MACOS_CLEANER_SUDO_PID:-}" ]]; then
        kill "$MACOS_CLEANER_SUDO_PID" 2>/dev/null || true
        wait "$MACOS_CLEANER_SUDO_PID" 2>/dev/null || true
        MACOS_CLEANER_SUDO_PID=""
    fi
}

# Check if sudo session is active
has_sudo() {
    sudo -n true 2>/dev/null
}

# Request sudo access with Touch ID support
request_sudo() {
    local prompt="${1:-Admin access required}"

    # Already have sudo?
    if has_sudo; then
        MACOS_CLEANER_SUDO_ACTIVE="true"
        start_keepalive
        return 0
    fi

    # Clear any stale sudo cache
    sudo -k 2>/dev/null || true

    # Detect available auth methods
    local has_touchid=false
    local in_clamshell=false

    check_touchid && has_touchid=true
    is_clamshell && in_clamshell=true

    # Show appropriate message
    if [[ "$has_touchid" == "true" && "$in_clamshell" == "false" ]]; then
        echo -e "${PURPLE}→${NC} ${prompt} ${GRAY}(Touch ID or password)${NC}"
    else
        echo -e "${PURPLE}→${NC} ${prompt}"
    fi

    # If clamshell mode, skip Touch ID
    if [[ "$in_clamshell" == "true" ]]; then
        if sudo -v; then
            MACOS_CLEANER_SUDO_ACTIVE="true"
            start_keepalive
            return 0
        fi
        return 1
    fi

    # Try Touch ID if available
    if [[ "$has_touchid" == "true" ]]; then
        # Background sudo to allow Touch ID timeout
        sudo -v </dev/null >/dev/null 2>&1 &
        local sudo_pid=$!

        # Wait up to 5 seconds
        local elapsed=0
        while [[ $elapsed -lt 50 ]]; do
            if ! kill -0 "$sudo_pid" 2>/dev/null; then
                wait "$sudo_pid" 2>/dev/null
                if has_sudo; then
                    MACOS_CLEANER_SUDO_ACTIVE="true"
                    start_keepalive
                    return 0
                fi
                break
            fi
            sleep 0.1
            ((elapsed++))
        done

        # Kill if still running (timeout or cancelled)
        if kill -0 "$sudo_pid" 2>/dev/null; then
            kill -9 "$sudo_pid" 2>/dev/null || true
            wait "$sudo_pid" 2>/dev/null || true
        fi

        # Clear sudo state
        sudo -k 2>/dev/null || true
        sleep 0.5
    fi

    # Fallback to password
    if sudo -v; then
        MACOS_CLEANER_SUDO_ACTIVE="true"
        start_keepalive
        return 0
    fi

    return 1
}

# Cleanup sudo session
cleanup_sudo() {
    stop_keepalive
    sudo -k 2>/dev/null || true
    MACOS_CLEANER_SUDO_ACTIVE="false"
}

# Register cleanup on exit
register_cleanup() {
    trap cleanup_sudo EXIT INT TERM
}

# Check if operation needs sudo
needs_sudo() {
    local path="$1"

    # System paths that need sudo
    case "$path" in
        /Library/* | /private/* | /System/*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Print usage if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Sudo Session Helper for macOS Cleaner"
    echo ""
    echo "Usage: source sudo_helper.sh"
    echo ""
    echo "Functions:"
    echo "  check_touchid    - Check if Touch ID is enabled for sudo"
    echo "  is_clamshell     - Check if laptop lid is closed"
    echo "  has_sudo         - Check if sudo session is active"
    echo "  request_sudo     - Request sudo access (Touch ID or password)"
    echo "  cleanup_sudo     - End sudo session and cleanup"
    echo "  register_cleanup - Register automatic cleanup on exit"
    echo "  needs_sudo       - Check if a path requires sudo to modify"
    echo ""
    echo "Example:"
    echo '  source sudo_helper.sh'
    echo '  register_cleanup'
    echo '  request_sudo "Cleaning system caches"'
    echo '  sudo rm -rf /Library/Caches/*.tmp'
    echo '  # cleanup_sudo called automatically on exit'
fi
