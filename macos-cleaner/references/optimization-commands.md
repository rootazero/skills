# macOS Optimization Commands

System maintenance and optimization commands for macOS.

## Disk Management

### Check Disk Space

```bash
# Overall disk usage
df -h /

# Disk usage with APFS container details
diskutil apfs list

# Large files in home directory
du -sh ~/* 2>/dev/null | sort -hr | head -20

# Large directories in Library
du -sh ~/Library/* 2>/dev/null | sort -hr | head -20
```

### APFS Maintenance

```bash
# Verify disk
diskutil verifyVolume /

# Repair disk (Recovery Mode recommended)
diskutil repairVolume /

# Defragment (live - no reboot needed)
diskutil apfs defragment / live

# List APFS snapshots
tmutil listlocalsnapshots /

# Delete specific snapshot
sudo tmutil deletelocalsnapshots <date>

# Delete all local snapshots
sudo tmutil deletelocalsnapshots /
```

### Time Machine

```bash
# Check Time Machine status
tmutil status

# List backup destinations
tmutil destinationinfo

# List local snapshots
tmutil listlocalsnapshots /

# Thin local snapshots
sudo tmutil thinlocalsnapshots / 10000000000 4  # Free ~10GB

# Exclude path from backup
tmutil addexclusion ~/path/to/exclude
```

## Cache and Index Rebuilding

### Spotlight

```bash
# Check indexing status
mdutil -s /

# Disable indexing
sudo mdutil -i off /

# Enable indexing
sudo mdutil -i on /

# Rebuild index
sudo mdutil -E /

# Erase and rebuild all volumes
sudo mdutil -E -a
```

### Launch Services

```bash
# Rebuild Launch Services database (fixes "Open With" menu)
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user

# Reset Launch Services database completely
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -seed -r -domain local -domain system -domain user
```

### Dynamic Linker Cache

```bash
# Rebuild dyld shared cache (requires reboot to take effect)
sudo update_dyld_shared_cache -force
```

### DNS Cache

```bash
# Flush DNS cache
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# macOS Monterey and later
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder

# Verify DNS resolution
dscacheutil -q host -a name google.com
```

### Font Cache

```bash
# Clear font caches
sudo atsutil databases -remove

# Restart font services
atsutil server -shutdown
atsutil server -ping
```

## System UI Reset

### Finder

```bash
# Restart Finder
killall Finder

# Reset Finder preferences (caution: resets settings)
rm ~/Library/Preferences/com.apple.finder.plist
killall Finder
```

### Dock

```bash
# Restart Dock
killall Dock

# Reset Dock to default
defaults delete com.apple.dock
killall Dock
```

### System UI Server

```bash
# Restart menu bar and Notification Center
killall SystemUIServer
```

### Control Center (macOS Big Sur+)

```bash
# Restart Control Center
killall ControlCenter
```

## Memory Management

### Purge Inactive Memory

```bash
# Free inactive memory (requires Xcode Command Line Tools)
sudo purge
```

### Check Memory Pressure

```bash
# Memory statistics
vm_stat

# Memory pressure
memory_pressure -l
```

## Network Reset

### TCP/IP Stack

```bash
# Reset network configuration
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# Renew DHCP lease
sudo ipconfig set en0 DHCP

# Show network interfaces
networksetup -listallhardwareports

# Get current DNS servers
networksetup -getdnsservers Wi-Fi
```

### WiFi

```bash
# Turn WiFi off/on
networksetup -setairportpower en0 off
networksetup -setairportpower en0 on

# List available networks
/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s

# Show current connection
/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I
```

## Kernel Extensions

```bash
# List loaded kernel extensions
kextstat

# Rebuild kernel extension cache
sudo kextcache -i /

# Clear kernel extension staging area
sudo rm -rf /Library/StagedExtensions/*
```

## System Integrity

### SIP Status

```bash
# Check SIP status
csrutil status
```

### Gatekeeper

```bash
# Check Gatekeeper status
spctl --status

# Allow apps from anywhere (not recommended)
# sudo spctl --master-disable
```

### Verify System Files

```bash
# Verify system file permissions
diskutil verifyPermissions /

# Note: Repair permissions removed in El Capitan
# SIP now handles system file protection
```

## Performance Monitoring

### CPU

```bash
# Top processes by CPU
top -l 1 -n 10 -stats pid,command,cpu

# CPU load averages
uptime

# Per-core utilization
sysctl -n machdep.cpu.core_count
```

### Memory

```bash
# Memory usage
memory_pressure

# Detailed memory stats
vm_stat
```

### Disk I/O

```bash
# Disk activity
iostat -d 1

# Disk usage by process
sudo fs_usage -f diskio
```

### Battery (Laptops)

```bash
# Battery info
pmset -g batt

# Power management settings
pmset -g

# Battery health
system_profiler SPPowerDataType
```

## Startup Items

### Launch Agents and Daemons

```bash
# List all launch agents/daemons
launchctl list

# List user launch agents
ls ~/Library/LaunchAgents/

# List system launch agents
ls /Library/LaunchAgents/

# List system daemons
ls /Library/LaunchDaemons/

# Disable a launch agent
launchctl unload ~/Library/LaunchAgents/com.example.agent.plist

# Enable a launch agent
launchctl load ~/Library/LaunchAgents/com.example.agent.plist

# Remove from startup (prevents load on next boot)
launchctl disable user/$(id -u)/com.example.agent
```

### Login Items

```bash
# View login items via AppleScript
osascript -e 'tell application "System Events" to get the name of every login item'

# Remove login item
osascript -e 'tell application "System Events" to delete login item "ItemName"'
```

## Diagnostic Logs

### System Logs

```bash
# View system log
log show --predicate 'eventMessage contains "error"' --last 1h

# Stream live logs
log stream --predicate 'process == "kernel"'

# Export logs
log collect --output ~/Desktop/system_logs.logarchive
```

### Console

```bash
# Open Console app
open /System/Applications/Utilities/Console.app
```

## Safe Mode Boot

For troubleshooting, boot into Safe Mode:

**Intel Macs:**
1. Shut down
2. Press power, immediately hold Shift
3. Release when login window appears

**Apple Silicon:**
1. Shut down
2. Press and hold power button
3. Select startup disk, hold Shift
4. Click "Continue in Safe Mode"

Safe Mode:
- Clears system caches
- Loads only essential kernel extensions
- Disables startup items
- Runs disk repair
