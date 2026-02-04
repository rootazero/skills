# Protected Paths Reference

Complete list of paths that must NEVER be deleted during cleanup operations.

## Critical System Directories

These paths are absolutely protected - deletion would break macOS:

```
/                           # Root filesystem
/bin                        # Essential user binaries
/sbin                       # Essential system binaries
/usr                        # Unix system resources
/usr/bin                    # Standard binaries
/usr/sbin                   # System administration binaries
/usr/lib                    # System libraries
/System                     # macOS system files (SIP protected)
/Library/Extensions         # Kernel extensions
/private/etc                # System configuration files
/private/var/db             # System databases (except safe subdirs)
```

## Safe Subdirectories Under Protected Paths

These specific paths CAN be cleaned despite parent being protected:

```
/private/tmp                                    # Temporary files
/private/var/tmp                                # More temporary files
/private/var/log/*.log                          # Log files (age-based)
/private/var/log/*.gz                           # Compressed logs
/private/var/folders                            # Per-user temp folders
/private/var/db/diagnostics                     # Diagnostic data
/private/var/db/DiagnosticPipeline              # Diagnostic pipeline
/private/var/db/powerlog                        # Power usage logs
/private/var/db/reportmemoryexception           # Memory exception reports
/private/var/db/receipts/*.bom                  # Package receipts (during uninstall only)
/private/var/db/receipts/*.plist                # Package receipts (during uninstall only)
/System/Library/Caches/com.apple.coresymbolicationd/data  # Symbol cache
```

## Protected User Data Paths

Paths containing critical user data that should never be auto-cleaned:

```
~/Library/Keychains                             # Passwords and certificates
~/Library/Preferences/com.apple.dock.plist      # Dock configuration
~/Library/Preferences/com.apple.finder.plist    # Finder configuration
~/Library/Mobile Documents                      # iCloud Drive data
~/Library/Containers/com.apple.Settings         # System Settings data
~/Library/Containers/com.apple.SystemSettings   # System Settings (Ventura+)
~/Library/Containers/com.apple.controlcenter    # Control Center data
~/Library/Preferences/ByHost/com.apple.bluetooth.*  # Bluetooth config
~/Library/Preferences/ByHost/com.apple.wifi.*   # WiFi configuration
```

## System-Critical Bundle IDs

Never clean data for these bundle ID patterns:

```
com.apple.*                 # Apple system apps (with exceptions)
loginwindow                 # Login window
dock                        # Dock
systempreferences           # System Preferences
finder                      # Finder
safari                      # Safari
backgroundtaskmanagement*   # Background task management
keychain*                   # Keychain services
security*                   # Security services
bluetooth*                  # Bluetooth services
wifi*                       # WiFi services
network*                    # Network services
tcc                         # Transparency, Consent, Control
notification*               # Notification services
accessibility*              # Accessibility services
universalaccess*            # Universal access
HIToolbox*                  # Human Interface Toolbox
textinput*                  # Text input
keyboard*                   # Keyboard services
inputsource*                # Input sources
GlobalPreferences           # Global preferences
org.pqrs.Karabiner*         # Karabiner Elements (keyboard remapping)
```

## Data-Protected Applications

Applications whose data should be protected during cleanup (but can be uninstalled if user explicitly requests):

### Password Managers
```
com.1password.*
com.agilebits.*
com.lastpass.*
com.dashlane.*
com.bitwarden.*
com.keepassx.*
org.keepassx.*
org.keepassxc.*
com.authy.*
com.yubico.*
```

### Development Tools
```
com.jetbrains.*
com.microsoft.VSCode
com.visualstudio.code.*
com.sublimetext.*
com.apple.dt.Xcode
com.docker.docker
```

### AI/LLM Tools
```
com.anthropic.claude*
Claude
com.openai.chat*
ChatGPT
com.ollama.ollama
Ollama
```

### VPN/Proxy Clients
```
com.clash.*
ClashX*
com.nssurge.*
*tailscale*
*zerotier*
*v2ray*
*surge*
```

### Cloud Storage
```
com.dropbox.*
com.microsoft.OneDrive*
com.google.GoogleDrive
com.box.desktop*
com.backblaze.*
```

### Communication
```
com.tencent.xinWeChat
com.tencent.qq
com.slack.Slack
us.zoom.xos
com.microsoft.teams*
org.telegram.desktop
```

### Input Methods
```
com.tencent.inputmethod.*
com.sogou.inputmethod.*
com.baidu.inputmethod.*
com.googlecode.rimeime.*
im.rime.*
```

## Path Validation Rules

Before deleting any path, verify:

1. **Not empty**: Path string is not empty
2. **Absolute path**: Starts with `/`
3. **No traversal**: Does not contain `/../` sequences
4. **No control chars**: Does not contain newlines or null bytes
5. **Not symlink to protected**: If symlink, target is not protected
6. **Not in protected list**: Not a critical system path
7. **Not protected app data**: Does not match protected bundle patterns
8. **User-level whitelisted**: Not in user's whitelist file

## User Whitelist

Users can protect specific paths via `~/.config/mole/whitelist`:

```
/Users/me/important-cache
~/Library/Application Support/MyApp
```

Each line is a path to protect. Supports:
- Absolute paths
- `~` expansion
- Glob patterns
