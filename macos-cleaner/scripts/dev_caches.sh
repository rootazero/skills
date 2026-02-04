#!/bin/bash
# Developer Caches Cleanup Script
# Comprehensive cleanup of development tool caches
# Usage: ./dev_caches.sh [--dry-run] [--tools <tool1,tool2>]

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
TOOLS_FILTER=""
TOTAL_FREED=0
ERRORS=0

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --tools) TOOLS_FILTER="$2"; shift 2 ;;
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

# Section header
section() {
    echo ""
    echo -e "${CYAN}═══ $1 ═══${NC}"
}

# Check tool filter
should_clean_tool() {
    local tool="$1"
    if [[ -z "$TOOLS_FILTER" ]]; then
        return 0
    fi
    [[ ",$TOOLS_FILTER," == *",$tool,"* ]]
}

# Clean directory with logging
clean_dir() {
    local path="$1"
    local description="$2"
    local tool="$3"

    [[ ! -d "$path" ]] && return

    local size_kb=$(get_size_kb "$path")
    [[ $size_kb -eq 0 ]] && return

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${YELLOW}○ Would clean: $description ($(human_size $size_kb))${NC}"
        TOTAL_FREED=$((TOTAL_FREED + size_kb))
    else
        if rm -rf "$path"/* 2>/dev/null || rm -rf "$path" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} Cleaned: $description ($(human_size $size_kb) freed)"
            TOTAL_FREED=$((TOTAL_FREED + size_kb))
        else
            echo -e "  ${RED}✗${NC} Failed: $description"
            ((ERRORS++))
        fi
    fi
}

# Run command with logging
run_cmd() {
    local cmd="$1"
    local description="$2"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${YELLOW}○ Would run: $cmd${NC}"
    else
        echo -e "  ${GRAY}Running: $cmd${NC}"
        if eval "$cmd" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $description"
        else
            echo -e "  ${YELLOW}!${NC} $description (may have issues)"
        fi
    fi
}

# JavaScript/Node.js tools
clean_javascript() {
    should_clean_tool "js" || return
    section "JavaScript/Node.js"

    # npm
    if command -v npm &>/dev/null; then
        clean_dir "$HOME/.npm/_cacache" "npm cache" "js"
        clean_dir "$HOME/.npm/_logs" "npm logs" "js"
        if [[ "$DRY_RUN" == "false" ]]; then
            run_cmd "npm cache clean --force" "npm cache cleanup"
        fi
    fi

    # pnpm
    if command -v pnpm &>/dev/null; then
        local pnpm_store=$(pnpm store path 2>/dev/null || echo "$HOME/.local/share/pnpm/store")
        clean_dir "$pnpm_store" "pnpm store" "js"
    fi

    # yarn
    if command -v yarn &>/dev/null; then
        local yarn_cache=$(yarn cache dir 2>/dev/null || echo "$HOME/.yarn/cache")
        clean_dir "$yarn_cache" "yarn cache" "js"
    fi

    # bun
    clean_dir "$HOME/.bun/install/cache" "bun cache" "js"

    # tnpm (taobao npm)
    clean_dir "$HOME/.tnpm" "tnpm cache" "js"
}

# Python tools
clean_python() {
    should_clean_tool "python" || return
    section "Python"

    # pip
    clean_dir "$HOME/Library/Caches/pip" "pip cache" "python"
    clean_dir "$HOME/.cache/pip" "pip cache (Linux style)" "python"

    # uv (fast pip alternative)
    clean_dir "$HOME/.cache/uv" "uv cache" "python"

    # poetry
    clean_dir "$HOME/Library/Caches/pypoetry" "poetry cache" "python"
    clean_dir "$HOME/.cache/pypoetry" "poetry cache (Linux style)" "python"

    # pyenv
    clean_dir "$HOME/.pyenv/cache" "pyenv cache" "python"

    # ruff (linter)
    clean_dir "$HOME/.cache/ruff" "ruff cache" "python"

    # mypy
    clean_dir "$HOME/.cache/mypy" "mypy cache" "python"
    clean_dir "$HOME/.mypy_cache" "mypy cache (local)" "python"

    # pytest
    clean_dir "$HOME/.cache/pytest" "pytest cache" "python"

    # huggingface
    echo -e "  ${GRAY}⊘ Skipped: HuggingFace models (protected by default)${NC}"

    # pip compile cache
    if command -v pip &>/dev/null && [[ "$DRY_RUN" == "false" ]]; then
        run_cmd "pip cache purge 2>/dev/null || true" "pip cache purge"
    fi
}

# Rust tools
clean_rust() {
    should_clean_tool "rust" || return
    section "Rust"

    # Cargo registry cache
    clean_dir "$HOME/.cargo/registry/cache" "cargo registry cache" "rust"

    # Cargo git cache
    clean_dir "$HOME/.cargo/git/db" "cargo git cache" "rust"

    # Rustup downloads
    clean_dir "$HOME/.rustup/downloads" "rustup downloads" "rust"

    # Rustup tmp
    clean_dir "$HOME/.rustup/tmp" "rustup temp" "rust"

    # Cargo clean (run in background for all target dirs)
    if command -v cargo &>/dev/null && [[ "$DRY_RUN" == "false" ]]; then
        run_cmd "cargo cache -a 2>/dev/null || true" "cargo cache cleanup"
    fi
}

# Go tools
clean_go() {
    should_clean_tool "go" || return
    section "Go"

    # Go build cache
    clean_dir "$HOME/.cache/go-build" "go build cache" "go"
    clean_dir "$HOME/Library/Caches/go-build" "go build cache (macOS)" "go"

    # Go mod cache
    if command -v go &>/dev/null; then
        local gomodcache=$(go env GOMODCACHE 2>/dev/null || echo "$HOME/go/pkg/mod")
        if [[ -d "$gomodcache" ]]; then
            local size_kb=$(get_size_kb "$gomodcache")
            if [[ $size_kb -gt 0 ]]; then
                if [[ "$DRY_RUN" == "true" ]]; then
                    echo -e "  ${YELLOW}○ Would clean: go mod cache ($(human_size $size_kb))${NC}"
                    TOTAL_FREED=$((TOTAL_FREED + size_kb))
                else
                    run_cmd "go clean -modcache" "go mod cache cleanup"
                    TOTAL_FREED=$((TOTAL_FREED + size_kb))
                fi
            fi
        fi
    fi
}

# Java/JVM tools
clean_java() {
    should_clean_tool "java" || return
    section "Java/JVM"

    # Gradle
    clean_dir "$HOME/.gradle/caches" "gradle caches" "java"
    clean_dir "$HOME/.gradle/daemon" "gradle daemon logs" "java"
    clean_dir "$HOME/.gradle/wrapper/dists" "gradle wrapper downloads" "java"

    # Maven (careful: repository is dependencies)
    clean_dir "$HOME/.m2/repository/.cache" "maven cache" "java"

    # sbt (Scala)
    clean_dir "$HOME/.sbt/boot" "sbt boot" "java"
    clean_dir "$HOME/.ivy2/cache" "ivy cache" "java"
}

# Apple development
clean_apple() {
    should_clean_tool "apple" || return
    section "Apple Development (Xcode)"

    # Xcode DerivedData
    clean_dir "$HOME/Library/Developer/Xcode/DerivedData" "Xcode DerivedData" "apple"

    # Xcode Archives (careful: these are app builds)
    local archives="$HOME/Library/Developer/Xcode/Archives"
    if [[ -d "$archives" ]]; then
        local size_kb=$(get_size_kb "$archives")
        if [[ $size_kb -gt 0 ]]; then
            echo -e "  ${YELLOW}!${NC} Xcode Archives: $(human_size $size_kb) (manual cleanup recommended)"
            echo -e "  ${GRAY}    Path: $archives${NC}"
        fi
    fi

    # iOS Device Support (old versions)
    local device_support="$HOME/Library/Developer/Xcode/iOS DeviceSupport"
    if [[ -d "$device_support" ]]; then
        local size_kb=$(get_size_kb "$device_support")
        if [[ $size_kb -gt 0 ]]; then
            echo -e "  ${YELLOW}!${NC} iOS Device Support: $(human_size $size_kb) (old versions can be removed)"
            echo -e "  ${GRAY}    Path: $device_support${NC}"
        fi
    fi

    # watchOS Device Support
    clean_dir "$HOME/Library/Developer/Xcode/watchOS DeviceSupport" "watchOS Device Support" "apple"

    # CoreSimulator caches
    clean_dir "$HOME/Library/Developer/CoreSimulator/Caches" "Simulator caches" "apple"

    # Simulator logs
    clean_dir "$HOME/Library/Logs/CoreSimulator" "Simulator logs" "apple"

    # CocoaPods
    clean_dir "$HOME/Library/Caches/CocoaPods" "CocoaPods cache" "apple"

    # Carthage
    clean_dir "$HOME/Library/Caches/org.carthage.CarthageKit" "Carthage cache" "apple"

    # Swift Package Manager
    clean_dir "$HOME/Library/Caches/org.swift.swiftpm" "SPM cache" "apple"

    # Swift build cache
    clean_dir "$HOME/Library/Developer/Xcode/UserData/IB Support" "Interface Builder cache" "apple"
}

# Homebrew
clean_homebrew() {
    should_clean_tool "brew" || return
    section "Homebrew"

    if ! command -v brew &>/dev/null; then
        echo -e "  ${GRAY}Homebrew not installed${NC}"
        return
    fi

    local brew_cache=$(brew --cache 2>/dev/null)
    if [[ -d "$brew_cache" ]]; then
        local size_kb=$(get_size_kb "$brew_cache")
        if [[ $size_kb -gt 0 ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                echo -e "  ${YELLOW}○ Would clean: brew cache ($(human_size $size_kb))${NC}"
                TOTAL_FREED=$((TOTAL_FREED + size_kb))
            else
                run_cmd "brew cleanup --prune=all" "brew cleanup"
                TOTAL_FREED=$((TOTAL_FREED + size_kb))
            fi
        fi
    fi
}

# Docker
clean_docker() {
    should_clean_tool "docker" || return
    section "Docker"

    if ! command -v docker &>/dev/null; then
        echo -e "  ${GRAY}Docker not installed${NC}"
        return
    fi

    # Check if Docker is running
    if ! docker info &>/dev/null; then
        echo -e "  ${YELLOW}Docker is not running${NC}"
        return
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${YELLOW}○ Would run: docker system prune${NC}"
        # Show estimate
        local docker_size=$(docker system df 2>/dev/null | tail -n +2 | awk '{sum += $4} END {print sum}' || echo "0")
        echo -e "  ${GRAY}Reclaimable space: ~${docker_size}${NC}"
    else
        echo -e "  ${YELLOW}!${NC} Clean Docker unused data? (containers, images, volumes)"
        echo -e "  ${GRAY}This will remove stopped containers and unused images${NC}"
        read -p "  Continue? (y/N): " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            run_cmd "docker system prune -f" "docker prune"
        fi
    fi
}

# Main
main() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${BLUE}║  Developer Caches Cleanup (DRY RUN)    ║${NC}"
    else
        echo -e "${BLUE}║  Developer Caches Cleanup              ║${NC}"
    fi
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "\n${YELLOW}This is a dry run - no files will be deleted${NC}"
    fi

    # Run cleanups
    clean_javascript
    clean_python
    clean_rust
    clean_go
    clean_java
    clean_apple
    clean_homebrew
    clean_docker

    # Summary
    section "Summary"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  Would free: ${GREEN}$(human_size $TOTAL_FREED)${NC}"
    else
        echo -e "  Space freed: ${GREEN}$(human_size $TOTAL_FREED)${NC}"
    fi

    if [[ $ERRORS -gt 0 ]]; then
        echo -e "  Errors: ${RED}$ERRORS${NC}"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "\n${GRAY}Run without --dry-run to apply changes${NC}"
    fi

    echo ""
    echo -e "${GRAY}Tip: Use --tools to clean specific tools only:${NC}"
    echo -e "${GRAY}  ./dev_caches.sh --tools js,python,rust${NC}"
}

main
