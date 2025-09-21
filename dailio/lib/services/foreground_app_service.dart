import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service for detecting the current foreground application on desktop platforms
class ForegroundAppService {
  static const MethodChannel _channel = MethodChannel('dailio/foreground_app');

  /// Check if the current platform supports foreground app detection
  bool isPlatformSupported() {
    return Platform.isMacOS || Platform.isWindows || Platform.isAndroid || Platform.isLinux;
  }

  /// Get the name of the currently active/foreground application
  /// Returns null if no app is detected or if an error occurs
  Future<String?> getForegroundAppName() async {
    try {
      if (!isPlatformSupported()) {
        throw UnsupportedError('Foreground app detection not supported on ${Platform.operatingSystem}');
      }

      final String? appName = await _channel.invokeMethod('getForegroundApp');
      return appName?.trim().isNotEmpty == true ? appName : null;
    } on PlatformException catch (e) {
      debugPrint('Failed to get foreground app: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Error getting foreground app: $e');
      return null;
    }
  }

  /// Check if the required permissions are granted (mainly for macOS)
  /// Returns true if permissions are available, false otherwise
  Future<bool> checkPermissions() async {
    try {
      if (!isPlatformSupported()) {
        return false;
      }

      final bool hasPermissions = await _channel.invokeMethod('checkPermissions') ?? false;
      return hasPermissions;
    } on PlatformException catch (e) {
      debugPrint('Failed to check permissions: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      return false;
    }
  }

  /// Request permissions (opens system settings on macOS)
  /// Returns true if user should check settings, false if not applicable
  Future<bool> requestPermissions() async {
    try {
      if (!isPlatformSupported()) {
        return false;
      }

      final bool shouldOpenSettings = await _channel.invokeMethod('requestPermissions') ?? false;
      return shouldOpenSettings;
    } on PlatformException catch (e) {
      debugPrint('Failed to request permissions: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  /// Get platform-specific information about the tracking capability
  Future<Map<String, dynamic>> getPlatformInfo() async {
    try {
      if (!isPlatformSupported()) {
        return {
          'platform': Platform.operatingSystem,
          'supported': false,
          'reason': 'Platform not supported'
        };
      }

      final Map<dynamic, dynamic>? info = await _channel.invokeMethod('getPlatformInfo');
      return Map<String, dynamic>.from(info ?? {});
    } on PlatformException catch (e) {
      return {
        'platform': Platform.operatingSystem,
        'supported': false,
        'error': e.message,
      };
    } catch (e) {
      return {
        'platform': Platform.operatingSystem,
        'supported': false,
        'error': e.toString(),
      };
    }
  }

  /// Test the connection to native code
  Future<bool> testConnection() async {
    try {
      final String? result = await _channel.invokeMethod('test');
      return result == 'success';
    } catch (e) {
      debugPrint('Failed to test connection: $e');
      return false;
    }
  }
}