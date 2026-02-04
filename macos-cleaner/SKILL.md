---
name: macos-cleaner
description: Safely clean and optimize macOS system. Use when user wants to free disk space, clean caches, remove app remnants, optimize system performance, or troubleshoot macOS issues. Features dry-run mode, interactive category selection, whitelist management, protected path validation, system optimization, project artifact purge, installer cleanup, orphan app detection, and real-time system status.
---

# macOS Cleaner

A comprehensive, safety-first approach to cleaning and optimizing macOS systems. Inspired by tools like CleanMyMac, AppCleaner, and DaisyDisk, but with full transparency and user control.

## Path Convention

**SKILL_ROOT definition:**
- **Claude Code users**: `SKILL_ROOT="$HOME/.claude/skills/macos-cleaner"`
- **Other environments**: Ask user for skill path on first use, store as `SKILL_ROOT` for session

## Core Capabilities

| Feature | Command | Description |
|---------|---------|-------------|
| **System Analysis** | `analyze.sh` | Scan disk usage across all categories |
| **Cache Cleanup** | `clean.sh` | Clean user/browser/dev caches with whitelist |
| **System Optimization** | `optimize.sh` | DNS flush, cache rebuild, memory purge |
| **Dev Cache Cleanup** | `dev_caches.sh` | Clean npm/pip/cargo/go/gradle caches |
| **Project Purge** | `purge.sh` | Remove node_modules, venv, target dirs |
| **Installer Cleanup** | `installer.sh` | Find large .dmg/.pkg files |
| **App Uninstall** | `find_app_remnants.sh` | Find all files for an app |
| **Orphan Detection** | `orphan.sh` | Find data from uninstalled apps |
| **System Status** | `status.sh` | Real-time CPU/memory/disk dashboard |
| **Whitelist Manager** | `whitelist.sh` | Manage protected paths |

## Core Interaction Principles

**CRITICAL RULES:**
1. **Never delete without user confirmation** - Always show what will be deleted first
2. **Always offer dry-run option** - Let user preview before any destructive action
3. **Present choices, don't assume** - Ask user which categories to clean
4. **Respect user's whitelist** - Never touch paths user has protected
5. **Check system state** - Verify Time Machine not running, system not under high load

## Quick Start Workflows

### "I need to free up disk space"

1. Run analysis:
```bash
bash $SKILL_ROOT/scripts/analyze.sh
```

2. Show results and offer cleaning options:
```
Based on the scan, I found these cleanup opportunities:

| Category | Size | Risk | Description |
|----------|------|------|-------------|
| User Caches | 1.3G | Low | App caches, rebuild automatically |
| Browser Caches | 500M | Low | Chrome, Safari, Firefox cache |
| Developer Caches | 2.1G | Medium | npm, Cargo, pip caches |
| Project Artifacts | 5.2G | Low | node_modules, venv, target |
| Trash | 200M | Low | Files in trash bin |
| Installers | 3.1G | Low | .dmg, .pkg files |

Which would you like to clean?
1. All safe categories (User/Browser/Trash)
2. Developer caches (may slow first build)
3. Project artifacts (rebuilds on next use)
4. Let me choose specific items
```

3. Run selected cleanups with dry-run first, then confirm.

### "Clean everything possible"

```bash
# Step 1: Dry run to preview
bash $SKILL_ROOT/scripts/clean.sh --dry-run
bash $SKILL_ROOT/scripts/dev_caches.sh --dry-run
bash $SKILL_ROOT/scripts/purge.sh --dry-run
bash $SKILL_ROOT/scripts/installer.sh --dry-run

# Step 2: After user confirms, run without --dry-run
bash $SKILL_ROOT/scripts/clean.sh
bash $SKILL_ROOT/scripts/dev_caches.sh
bash $SKILL_ROOT/scripts/purge.sh
bash $SKILL_ROOT/scripts/installer.sh
```

### "Optimize system performance"

```bash
# Dry run first
bash $SKILL_ROOT/scripts/optimize.sh --dry-run

# Run optimization
bash $SKILL_ROOT/scripts/optimize.sh
```

Available optimization tasks:
- `dns` - Flush DNS cache and restart mDNSResponder
- `launch_services` - Rebuild "Open With" menu
- `quicklook` - Clear thumbnail cache
- `icon_cache` - Clear icon cache and restart Dock
- `font_cache` - Clear font caches
- `memory` - Purge inactive memory (if pressure high)
- `logs` - Clear old system logs (>7 days)
- `crash_reports` - Clear old crash reports
- `finder` - Restart Finder
- `menubar` - Restart menu bar and Control Center
- `spotlight` - Rebuild Spotlight index (long operation)
- `dyld` - Rebuild dynamic linker cache (requires reboot)

Run specific tasks:
```bash
bash $SKILL_ROOT/scripts/optimize.sh --tasks dns,memory,logs
```

### "I uninstalled an app but it left files"

```bash
# Find all remnants
bash $SKILL_ROOT/scripts/find_app_remnants.sh "App Name"

# Or with bundle ID for precision
bash $SKILL_ROOT/scripts/find_app_remnants.sh "Slack" "com.tinyspeck.slackmacgap"
```

### "Find data from uninstalled apps"

```bash
# Find orphaned app data (60 day grace period by default)
bash $SKILL_ROOT/scripts/orphan.sh

# Adjust grace period
bash $SKILL_ROOT/scripts/orphan.sh --min-age 30
```

### "Clean up project build artifacts"

```bash
# Find node_modules, venv, target, etc.
bash $SKILL_ROOT/scripts/purge.sh --dry-run

# Scan specific directories
bash $SKILL_ROOT/scripts/purge.sh --paths ~/Projects,~/Work

# Set minimum age (default 7 days)
bash $SKILL_ROOT/scripts/purge.sh --min-age 14
```

Supported artifacts:
- JavaScript: `node_modules`, `.next`, `.nuxt`, `.turbo`, `.parcel-cache`
- Python: `venv`, `.venv`, `__pycache__`, `.pytest_cache`, `.mypy_cache`
- Rust/Go/Java: `target`, `build`, `.gradle`, `vendor`
- Other: `.dart_tool`, `.zig-cache`, `.angular`, `coverage`

### "Find and remove large installers"

```bash
# Find .dmg, .pkg, .zip files > 50MB
bash $SKILL_ROOT/scripts/installer.sh

# Adjust minimum size
bash $SKILL_ROOT/scripts/installer.sh --min-size 100
```

Scans: Downloads, Desktop, Documents, Homebrew Cask, iCloud Downloads, Mail attachments

### "Clean developer tool caches"

```bash
# All dev caches
bash $SKILL_ROOT/scripts/dev_caches.sh --dry-run

# Specific tools only
bash $SKILL_ROOT/scripts/dev_caches.sh --tools js,python,rust
```

Supported tools:
- `js`: npm, pnpm, yarn, bun, tnpm
- `python`: pip, uv, poetry, pyenv, ruff, mypy, pytest
- `rust`: cargo, rustup
- `go`: go mod cache, go build cache
- `java`: gradle, maven, sbt, ivy
- `apple`: Xcode, CocoaPods, Carthage, SPM
- `brew`: Homebrew cache
- `docker`: Docker system prune

### "Check system status"

```bash
# Full status dashboard
bash $SKILL_ROOT/scripts/status.sh

# Brief output
bash $SKILL_ROOT/scripts/status.sh --brief
```

Shows:
- CPU: model, cores, load average, top processes
- Memory: used/total, pressure, swap
- Disk: used/total, purgeable space, TM snapshots
- Battery: charge, status, health, cycles (laptops)
- Network: interface, IP, SSID
- Health Score: 0-100 composite rating

## Whitelist Management

Protected paths are never cleaned. Whitelist file: `~/.config/macos-cleaner/whitelist`

```bash
# List protected paths
bash $SKILL_ROOT/scripts/whitelist.sh list

# Add path
bash $SKILL_ROOT/scripts/whitelist.sh add "~/Library/Caches/MyImportantApp"

# Remove path
bash $SKILL_ROOT/scripts/whitelist.sh remove "~/Library/Caches/MyImportantApp"

# Check if protected
bash $SKILL_ROOT/scripts/whitelist.sh check "~/.cache/huggingface"

# Interactive mode
bash $SKILL_ROOT/scripts/whitelist.sh interactive
```

### Default Protected Items

| Item | Reason |
|------|--------|
| `~/.cache/huggingface/*` | AI models, expensive to re-download |
| `~/.ollama/models/*` | Local LLM weights |
| `~/.m2/repository/*` | Maven dependencies |
| `~/.cache/torch/*` | PyTorch models |
| `~/Library/Caches/ms-playwright*` | Browser testing binaries |

## Safety Features

### Pre-flight Checks

Before any cleanup, the skill checks:
- Time Machine backup status (skip if running)
- System load (warn if high)
- Memory pressure (warn if critical)
- Disk space (warn if critical)
- AC power (recommend for optimization)

### Path Validation

All deletions go through validation:
- Blocked system paths: `/`, `/System`, `/bin`, `/sbin`, `/usr`, `/etc`
- No path traversal (`..`) allowed
- Symlinks checked to prevent system access
- Bundle ID format validation for app operations

### Protected Vendors

Orphan detection skips these vendors to prevent false positives:
- `com.apple.*` - Apple apps
- `com.adobe.*` - Adobe products
- `com.microsoft.*` - Microsoft products
- `com.google.*` - Google products
- `com.jetbrains.*` - JetBrains IDEs
- `com.anthropic.*` - Claude
- `com.openai.*` - ChatGPT

## Detailed Workflow: Interactive Cleanup

### Step 1: Initial Scan

```bash
bash $SKILL_ROOT/scripts/detailed_scan.sh
```

Shows all cleanable items with indices for selection.

### Step 2: Category Selection

Present options:
```
Select categories to clean (comma-separated, e.g., 1,3,5):

[ ] 1. User Caches (1.3G) - Safe, rebuilds automatically
[ ] 2. Browser Caches (500M) - Safe, clears browsing cache only
[ ] 3. Developer Caches (2.1G) - May need rebuild on next use
[ ] 4. System Logs (300M) - Old log files (needs sudo)
[ ] 5. Trash (200M) - Empty trash bin
[ ] 6. Crash Reports (50M) - Old crash reports
```

### Step 3: Exclusion / Whitelist

If user wants to exclude specific items:
```bash
bash $SKILL_ROOT/scripts/whitelist.sh add ~/Library/Caches/MyApp
```

### Step 4: Dry Run Preview

Always show what will happen:
```bash
bash $SKILL_ROOT/scripts/clean.sh --dry-run --categories user_caches,browser_caches,trash
```

### Step 5: Execute with Progress

After user confirms:
```bash
bash $SKILL_ROOT/scripts/clean.sh --categories user_caches,browser_caches,trash
```

## Authorization Handling

For system-level operations requiring sudo:

```bash
# Source the helper
source $SKILL_ROOT/scripts/sudo_helper.sh

# Register cleanup
register_cleanup

# Request sudo with keepalive
request_sudo "System cleanup requires admin access"

# Operations use sudo automatically
sudo find /Library/Caches -name "*.tmp" -delete
```

Inform user: "macOS will prompt for Touch ID or password. The session will be maintained during cleanup."

## Error Handling

### "Operation not permitted"

```
Some files couldn't be deleted due to permissions.

Terminal needs "Full Disk Access":
1. Open System Settings > Privacy & Security > Full Disk Access
2. Add Terminal (or iTerm)
3. Restart Terminal
```

### "Time Machine Running"

```
⚠️ Time Machine backup in progress.

Options:
1. Wait for backup to complete
2. Skip system-level operations
3. Cancel and try later
```

## Reference Files

- `references/protected-paths.md` - Complete list of protected system paths
- `references/app-locations.md` - Application data locations for uninstallation
- `references/optimization-commands.md` - System optimization and maintenance commands

## Script Reference

| Script | Purpose | Key Options |
|--------|---------|-------------|
| `analyze.sh` | Disk usage scan | `--quick`, `--full` |
| `clean.sh` | Cache cleanup | `--dry-run`, `--categories`, `--exclude` |
| `optimize.sh` | System optimization | `--dry-run`, `--tasks` |
| `dev_caches.sh` | Developer caches | `--dry-run`, `--tools` |
| `purge.sh` | Project artifacts | `--dry-run`, `--paths`, `--min-age` |
| `installer.sh` | Installer files | `--dry-run`, `--min-size` |
| `orphan.sh` | Orphaned app data | `--dry-run`, `--min-age` |
| `status.sh` | System status | `--brief` |
| `detailed_scan.sh` | Detailed item list | `--json`, `--category` |
| `find_app_remnants.sh` | App uninstall | `<app_name> [bundle_id]` |
| `whitelist.sh` | Whitelist manager | `list`, `add`, `remove`, `check` |
| `lib/safety.sh` | Safety functions | (source this file) |
