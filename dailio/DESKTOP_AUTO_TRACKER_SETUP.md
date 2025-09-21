# Cross-Platform Auto-Tracker Setup Instructions

This guide explains how to set up and use the auto-tracker module that automatically detects and tracks foreground applications across multiple platforms.

## Overview

The auto-tracker module includes:
- **Flutter Service**: `ForegroundAppService` for cross-platform app detection
- **Riverpod Provider**: `AutoTrackerProvider` for state management and database integration  
- **Native Integration**: Platform-specific code for all desktop and mobile platforms
- **UI Components**: Settings screen and status widgets

## Platform Support

| Platform | Support | Permissions Required | Native API | Status |
|----------|---------|---------------------|------------|---------|
| macOS    | ✅ Full | Accessibility Access | NSWorkspace | Production Ready |
| Windows  | ✅ Full | None | Win32 API | Production Ready |
| Android  | ✅ Full | Usage Access | UsageStatsManager | Production Ready |
| Linux    | ✅ Full | None | X11/Wayland | Production Ready |
| iOS      | ❌ Impossible | N/A | N/A (Sandboxed) | Not Possible |
| Web      | ❌ Not supported | N/A | N/A | Not Applicable |

## macOS Setup

### 1. Accessibility Permissions

The app requires accessibility permissions to detect the foreground application.

**Manual Setup:**
1. Open **System Preferences** > **Security & Privacy** > **Privacy**
2. Select **Accessibility** from the left sidebar
3. Click the lock icon and enter your password
4. Click the **+** button and add your Dailio app
5. Ensure the checkbox next to Dailio is checked

**Automatic Request:**
- The app will automatically prompt for permissions on first run
- If permissions are denied, use the "Grant Permissions" button in Settings
- The app will open System Preferences for you

### 2. App Sandbox Entitlements

The following entitlements are configured in the app:

```xml
<!-- DebugProfile.entitlements -->
<key>com.apple.security.automation.apple-events</key>
<true/>
<key>com.apple.security.temporary-exception.apple-events</key>
<array>
    <string>com.apple.systemevents</string>
</array>
```

### 3. Testing macOS Integration

```bash
# Run the app
flutter run -d macos

# Test foreground app detection
# 1. Open Settings screen
# 2. Click "Test Foreground App Detection"
# 3. Switch to another app and test again
```

## Windows Setup

### 1. No Permissions Required

Windows does not require special permissions for foreground window detection using the Win32 API.

### 2. Native Implementation

The Windows implementation uses:
- `GetForegroundWindow()` - Get the currently active window
- `GetWindowThreadProcessId()` - Get the process ID
- `QueryFullProcessImageNameW()` - Get the executable name

### 3. Testing Windows Integration

```bash
# Run the app
flutter run -d windows

# Test foreground app detection
# 1. Open Settings screen  
# 2. Click "Test Foreground App Detection"
# 3. Switch between different applications
```

## Android Setup

### 1. Usage Access Permission Required

Android requires "Usage Access" permission to detect foreground applications.

**Automatic Setup:**
1. The app will automatically prompt for usage access permission
2. You'll be redirected to Settings > Apps > Special access > Usage access
3. Find "Dailio" in the list and toggle it on
4. Return to the app - auto-tracking will now work

**Manual Setup:**
1. Open **Settings** > **Apps** > **Special access** > **Usage access**
2. Find **Dailio** in the app list
3. Toggle **"Allow usage access"** to ON
4. Return to Dailio and enable auto-tracking

### 2. Implementation Details

The Android implementation uses:
- `UsageStatsManager` - Official Android API for app usage tracking
- `PACKAGE_USAGE_STATS` permission - Required for foreground app detection
- App name resolution via `PackageManager`

### 3. Testing Android Integration

```bash
# Run the app
flutter run -d android

# Test foreground app detection
# 1. Grant usage access permission when prompted
# 2. Open Settings screen in Dailio
# 3. Click "Test Foreground App Detection"
# 4. Switch between different apps
```

## Linux Setup

### 1. No Permissions Required

Linux does not require special permissions for window detection using X11 APIs.

### 2. System Requirements

**Required packages (automatically detected):**
- X11 development libraries (`libx11-dev` on Ubuntu/Debian)
- GTK+ 3.0 development libraries
- Standard C++ compiler with C++14 support

**Supported Desktop Environments:**
- Any X11-based desktop (GNOME, KDE, XFCE, i3, etc.)
- Wayland support (planned for future release)

### 3. Implementation Details

The Linux implementation uses:
- `XGetInputFocus()` - Get currently focused window
- `XQueryTree()` - Find top-level window
- `XGetClassHint()` - Get application class name
- `XFetchName()` - Get window title as fallback

### 4. Testing Linux Integration

```bash
# Install dependencies (Ubuntu/Debian)
sudo apt install libx11-dev libgtk-3-dev

# Run the app
flutter run -d linux

# Test foreground app detection
# 1. Open Settings screen
# 2. Click "Test Foreground App Detection"  
# 3. Switch between different applications
```

## iOS Limitations

### Why iOS Auto-Tracking is Impossible

**Technical Restrictions:**
1. **App Sandboxing**: iOS apps cannot access information about other apps
2. **Apple Privacy Policy**: Strictly prohibits foreground app detection
3. **No Public APIs**: No documented APIs for cross-app detection
4. **App Store Rejection**: Apps attempting this are automatically rejected

**Alternative for iOS:**
- **Manual Categories**: Enhanced manual time tracking
- **Focus Integration**: iOS Focus mode detection (iOS 15+)
- **Screen Time Integration**: Limited personal insights only
- **Superior Manual UX**: Best-in-class manual tracking experience

## Using Auto-Tracking

### 1. Enable Auto-Tracking

1. Open the **Settings** screen from the timer screen
2. Toggle **"Enable Auto-Tracking"**
3. Grant permissions if prompted (macOS only)
4. The status widget will appear showing the current app

### 2. Auto-Tracking Behavior

- **Detection Interval**: Every 5 seconds
- **Minimum Duration**: 5 seconds to save an activity
- **Category**: Activities are marked as "Auto-tracked"
- **Storage**: Saved to Hive database with `isTracked: true`

### 3. Status Indicators

| Status | Color | Meaning |
|--------|-------|---------|
| Green dot | 🟢 | Currently tracking |
| Orange dot | 🟠 | Tracking paused/disabled |
| Red dot | 🔴 | Error occurred |

## Troubleshooting

### macOS Issues

**Problem**: "No permissions" error
**Solution**: 
1. Check System Preferences > Security & Privacy > Accessibility
2. Remove and re-add the app if present
3. Restart the app after granting permissions

**Problem**: App not detected correctly
**Solution**:
1. Ensure the app is in the foreground
2. Some system apps may not be detectable
3. Check Console.app for any error messages

### Windows Issues

**Problem**: "Could not get foreground window"
**Solution**:
1. Ensure another application window is active
2. Some system processes may not have window titles
3. Try switching to a regular application like a browser

### General Issues

**Problem**: Auto-tracking not saving activities
**Solution**:
1. Check that activities are at least 5 seconds long
2. Verify Hive database is properly initialized
3. Check the Statistics screen for auto-tracked activities

**Problem**: High CPU usage
**Solution**:
1. The 5-second interval is optimized for performance
2. Check for infinite loops in error handling
3. Disable auto-tracking if not needed

## Development

### Adding New Platforms

To add support for additional platforms:

1. **Update Platform Check**:
```dart
// In ForegroundAppService
bool isPlatformSupported() {
  return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
}
```

2. **Add Native Implementation**:
- Create platform-specific MethodChannel handler
- Implement foreground app detection using platform APIs
- Handle permissions if required

3. **Update Documentation**:
- Add platform to support table
- Document any required permissions
- Add platform-specific troubleshooting

### Testing

```bash
# Run all tests
flutter test

# Test on specific platform
flutter run -d macos
flutter run -d windows

# Test method channel
flutter run -d macos --debug
# Then use the test button in Settings
```

### Performance Monitoring

The auto-tracker includes built-in statistics:
- Total activities tracked today
- Duration breakdown by app
- Most used applications
- Error tracking

Access via Settings > "View Tracking Statistics"

## API Reference

### ForegroundAppService

```dart
// Check platform support
bool isPlatformSupported()

// Get current foreground app
Future<String?> getForegroundAppName()

// Check permissions (macOS only)
Future<bool> checkPermissions()

// Request permissions (macOS only)  
Future<bool> requestPermissions()

// Get platform information
Future<Map<String, dynamic>> getPlatformInfo()
```

### AutoTrackerProvider

```dart
// Toggle auto-tracking
Future<void> toggleTracking()

// Enable/disable tracking
Future<void> enableTracking()
Future<void> disableTracking()

// Get statistics
Future<Map<String, dynamic>> getTrackingStats()
```

## Security Considerations

### macOS
- Accessibility permissions allow reading active application names
- No access to application content or user data
- Permissions can be revoked at any time in System Preferences

### Windows  
- Uses standard Win32 APIs available to all applications
- Only reads window titles and process names
- No elevated permissions required

### Data Storage
- All tracked data stored locally in Hive database
- No data transmitted to external servers
- User controls all tracking data through the app interface