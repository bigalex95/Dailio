import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    setupMethodChannel()
    super.applicationDidFinishLaunching(notification)
  }
  
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
  
  private func setupMethodChannel() {
    guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
      print("ERROR: Could not find FlutterViewController")
      return
    }
    
    let channel = FlutterMethodChannel(
      name: "dailio/foreground_app",
      binaryMessenger: controller.engine.binaryMessenger
    )
    
    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      self?.handleMethodCall(call: call, result: result)
    }
  }
  
  private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getForegroundApp":
      getForegroundAppName(result: result)
    case "checkPermissions":
      checkAccessibilityPermissions(result: result)
    case "requestPermissions":
      requestAccessibilityPermissions(result: result)
    case "getPlatformInfo":
      getPlatformInfo(result: result)
    case "test":
      result("success")
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func getForegroundAppName(result: @escaping FlutterResult) {
    // Check if we have accessibility permissions
    guard AXIsProcessTrusted() else {
      result(FlutterError(
        code: "NO_PERMISSIONS",
        message: "Accessibility permissions required",
        details: "Please grant accessibility permissions in System Preferences > Security & Privacy > Privacy > Accessibility"
      ))
      return
    }
    
    let workspace = NSWorkspace.shared
    if let frontmostApp = workspace.frontmostApplication {
      result(frontmostApp.localizedName)
    } else {
      result(FlutterError(
        code: "NO_APP",
        message: "Could not get frontmost application",
        details: nil
      ))
    }
  }
  
  private func checkAccessibilityPermissions(result: @escaping FlutterResult) {
    let trusted = AXIsProcessTrusted()
    result(trusted)
  }
  
  private func requestAccessibilityPermissions(result: @escaping FlutterResult) {
    // Check current status
    let trusted = AXIsProcessTrusted()
    
    if trusted {
      result(false) // Already has permissions, no need to open settings
      return
    }
    
    // Request permissions - this will prompt the user if not already trusted
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
    let requestResult = AXIsProcessTrustedWithOptions(options)
    
    if !requestResult {
      // Open System Preferences to accessibility settings
      let prefPaneURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
      NSWorkspace.shared.open(prefPaneURL)
      result(true) // User should check settings
    } else {
      result(false) // Already trusted
    }
  }
  
  private func getPlatformInfo(result: @escaping FlutterResult) {
    let info: [String: Any] = [
      "platform": "macOS",
      "supported": true,
      "version": ProcessInfo.processInfo.operatingSystemVersionString,
      "hasPermissions": AXIsProcessTrusted(),
      "requiresPermissions": true,
      "permissionsLocation": "System Preferences > Security & Privacy > Privacy > Accessibility"
    ]
    result(info)
  }
}
