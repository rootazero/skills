# Application Data Locations

Complete reference for finding and removing application remnants on macOS.

## Application Bundle Locations

```bash
# User-installed apps
/Applications/
~/Applications/

# System apps (protected)
/System/Applications/
```

## User-Level Data Locations

### Primary Data Directories

```bash
~/Library/Application Support/$APP_NAME
~/Library/Application Support/$BUNDLE_ID
~/Library/Caches/$BUNDLE_ID
~/Library/Caches/$APP_NAME
~/Library/Logs/$APP_NAME
~/Library/Logs/$BUNDLE_ID
```

### Preferences

```bash
~/Library/Preferences/$BUNDLE_ID.plist
~/Library/Preferences/ByHost/$BUNDLE_ID.*.plist
```

### State and Containers

```bash
~/Library/Saved Application State/$BUNDLE_ID.savedState
~/Library/Containers/$BUNDLE_ID
~/Library/Group Containers/*$BUNDLE_ID*
~/Library/Application Scripts/$BUNDLE_ID
~/Library/Autosave Information/$BUNDLE_ID
```

### Web Data

```bash
~/Library/HTTPStorages/$BUNDLE_ID
~/Library/WebKit/$BUNDLE_ID
~/Library/WebKit/com.apple.WebKit.WebContent/$BUNDLE_ID
~/Library/Cookies/$BUNDLE_ID.binarycookies
```

### Crash Reports

```bash
~/Library/Application Support/CrashReporter/$APP_NAME
~/Library/Logs/DiagnosticReports/*$APP_NAME*
```

### Launch Agents

```bash
~/Library/LaunchAgents/$BUNDLE_ID.plist
~/Library/LaunchAgents/*$APP_NAME*.plist
```

### Plugins and Extensions

```bash
~/Library/Services/$APP_NAME.workflow
~/Library/QuickLook/$APP_NAME.qlgenerator
~/Library/Internet Plug-Ins/$APP_NAME.plugin
~/Library/Spotlight/$APP_NAME.mdimporter
~/Library/ColorPickers/$APP_NAME.colorPicker
~/Library/Workflows/$APP_NAME.workflow
~/Library/Contextual Menu Items/$APP_NAME.plugin
```

### Audio Plugins

```bash
~/Library/Audio/Plug-Ins/Components/$APP_NAME.component
~/Library/Audio/Plug-Ins/VST/$APP_NAME.vst
~/Library/Audio/Plug-Ins/VST3/$APP_NAME.vst3
~/Library/Audio/Plug-Ins/Digidesign/$APP_NAME.dpm
```

### System Integration

```bash
~/Library/PreferencePanes/$APP_NAME.prefPane
~/Library/Input Methods/$APP_NAME.app
~/Library/Input Methods/$BUNDLE_ID.app
~/Library/Screen Savers/$APP_NAME.saver
~/Library/Frameworks/$APP_NAME.framework
```

### Hidden Config Files

```bash
~/.config/$APP_NAME
~/.local/share/$APP_NAME
~/.$APP_NAME
~/.$APP_NAME.rc
```

## System-Level Data Locations

Require sudo to access/delete.

### Primary Directories

```bash
/Library/Application Support/$APP_NAME
/Library/Application Support/$BUNDLE_ID
/Library/Caches/$BUNDLE_ID
/Library/Caches/$APP_NAME
/Library/Logs/$APP_NAME
```

### Preferences

```bash
/Library/Preferences/$BUNDLE_ID.plist
```

### Launch Daemons and Agents

```bash
/Library/LaunchAgents/$BUNDLE_ID.plist
/Library/LaunchAgents/*$APP_NAME*.plist
/Library/LaunchDaemons/$BUNDLE_ID.plist
/Library/LaunchDaemons/*$APP_NAME*.plist
```

### Privileged Helpers

```bash
/Library/PrivilegedHelperTools/$BUNDLE_ID*
```

### Installation Receipts

```bash
/private/var/db/receipts/$BUNDLE_ID.bom
/private/var/db/receipts/$BUNDLE_ID.plist
```

### System Plugins

```bash
/Library/Frameworks/$APP_NAME.framework
/Library/Internet Plug-Ins/$APP_NAME.plugin
/Library/Input Methods/$APP_NAME.app
/Library/Audio/Plug-Ins/Components/$APP_NAME.component
/Library/Audio/Plug-Ins/VST/$APP_NAME.vst
/Library/Audio/Plug-Ins/VST3/$APP_NAME.vst3
/Library/QuickLook/$APP_NAME.qlgenerator
/Library/PreferencePanes/$APP_NAME.prefPane
/Library/Screen Savers/$APP_NAME.saver
```

## App Name Variants

Apps may use different naming conventions. Check all variants:

```bash
# Original name
"App Name"

# No spaces
"AppName"

# Underscores
"App_Name"

# Hyphens
"App-Name"

# Lowercase variants
"app name"
"appname"
"app-name"
"app_name"

# Base name without version suffix
# "App Nightly" → "App"
# "Firefox Developer Edition" → "Firefox"
```

## Development Environment Paths

### Xcode

```bash
~/Library/Developer
~/Library/Developer/Xcode/DerivedData
~/Library/Developer/Xcode/Archives
~/Library/Developer/Xcode/iOS DeviceSupport
~/.Xcode
```

### Android Studio

```bash
~/AndroidStudioProjects
~/Library/Android
~/.android
~/Library/Application Support/Google/AndroidStudio*
```

### JetBrains IDEs

```bash
~/Library/Application Support/JetBrains/$IDE_NAME*
~/Library/Caches/JetBrains/$IDE_NAME*
~/Library/Logs/JetBrains/$IDE_NAME*
```

### VS Code

```bash
~/.vscode
~/Library/Application Support/Code
~/Library/Caches/com.microsoft.VSCode*
```

### Docker

```bash
~/.docker
~/Library/Containers/com.docker.docker
~/Library/Group Containers/group.com.docker
~/Library/Application Support/Docker Desktop
```

### Unity

```bash
~/Library/Unity
```

### DevEco Studio (Huawei/HarmonyOS)

```bash
~/DevEcoStudioProjects
~/DevEco-Studio
~/Library/Application Support/Huawei
~/Library/Caches/Huawei
~/Library/Logs/Huawei
~/Library/Huawei
~/Huawei
~/HarmonyOS
~/.huawei
~/.ohos
```

## Getting Bundle ID

```bash
# From app bundle
defaults read /Applications/AppName.app/Contents/Info.plist CFBundleIdentifier

# For running app
osascript -e 'id of app "App Name"'

# Using mdls
mdls -name kMDItemCFBundleIdentifier /Applications/AppName.app

# From plist
plutil -p /Applications/AppName.app/Contents/Info.plist | grep CFBundleIdentifier
```

## Finding All App Files

```bash
# Use mdfind for quick search
mdfind "kMDItemCFBundleIdentifier == 'com.example.app'"

# Find by name pattern
find ~/Library -name "*AppName*" 2>/dev/null
sudo find /Library -name "*AppName*" 2>/dev/null

# Find by bundle ID pattern
find ~/Library -name "*com.example.app*" 2>/dev/null
```
