import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity.dart';
import '../repositories/activity_repository.dart';
import '../services/foreground_app_service.dart';
import 'activity_repository_provider.dart';

// Auto-tracker state model
@immutable
class AutoTrackerState {
  final bool isEnabled;
  final bool isTracking;
  final String? currentAppName;
  final DateTime? lastUpdateTime;
  final String? errorMessage;

  const AutoTrackerState({
    this.isEnabled = false,
    this.isTracking = false,
    this.currentAppName,
    this.lastUpdateTime,
    this.errorMessage,
  });

  AutoTrackerState copyWith({
    bool? isEnabled,
    bool? isTracking,
    String? currentAppName,
    DateTime? lastUpdateTime,
    String? errorMessage,
  }) {
    return AutoTrackerState(
      isEnabled: isEnabled ?? this.isEnabled,
      isTracking: isTracking ?? this.isTracking,
      currentAppName: currentAppName ?? this.currentAppName,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutoTrackerState &&
          runtimeType == other.runtimeType &&
          isEnabled == other.isEnabled &&
          isTracking == other.isTracking &&
          currentAppName == other.currentAppName &&
          lastUpdateTime == other.lastUpdateTime &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
        isEnabled,
        isTracking,
        currentAppName,
        lastUpdateTime,
        errorMessage,
      );
}

// Auto-tracker provider
class AutoTrackerNotifier extends StateNotifier<AutoTrackerState> {
  final ForegroundAppService _foregroundAppService;
  final ActivityRepository _activityRepository;
  Timer? _trackingTimer;
  String? _lastTrackedApp;
  DateTime? _lastAppStartTime;

  static const String _enabledKey = 'auto_tracker_enabled';
  static const Duration _trackingInterval = Duration(seconds: 5);

  AutoTrackerNotifier(this._foregroundAppService, this._activityRepository)
      : super(const AutoTrackerState()) {
    _loadSettings();
  }

  // Load saved settings
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool(_enabledKey) ?? false;
      
      state = state.copyWith(isEnabled: isEnabled);
      
      if (isEnabled) {
        await startTracking();
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to load settings: $e');
    }
  }

  // Save settings
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, state.isEnabled);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save settings: $e');
    }
  }

  // Toggle auto-tracking
  Future<void> toggleTracking() async {
    if (state.isEnabled) {
      await stopTracking();
    } else {
      await enableTracking();
    }
  }

  // Enable auto-tracking
  Future<void> enableTracking() async {
    state = state.copyWith(isEnabled: true, errorMessage: null);
    await _saveSettings();
    await startTracking();
  }

  // Disable auto-tracking
  Future<void> disableTracking() async {
    state = state.copyWith(isEnabled: false);
    await _saveSettings();
    await stopTracking();
  }

  // Start tracking foreground apps
  Future<void> startTracking() async {
    if (!state.isEnabled || state.isTracking) return;

    try {
      // Check if platform supports foreground app detection
      final isSupported = _foregroundAppService.isPlatformSupported();
      if (!isSupported) {
        state = state.copyWith(
          errorMessage: 'Auto-tracking not supported on this platform',
        );
        return;
      }

      state = state.copyWith(isTracking: true, errorMessage: null);

      // Start periodic tracking
      _trackingTimer = Timer.periodic(_trackingInterval, (_) async {
        await _trackForegroundApp();
      });

      // Get initial app
      await _trackForegroundApp();
    } catch (e) {
      state = state.copyWith(
        isTracking: false,
        errorMessage: 'Failed to start tracking: $e',
      );
    }
  }

  // Stop tracking
  Future<void> stopTracking() async {
    _trackingTimer?.cancel();
    _trackingTimer = null;

    // Save current activity if one is being tracked
    if (_lastTrackedApp != null && _lastAppStartTime != null) {
      await _saveCurrentActivity();
    }

    state = state.copyWith(
      isTracking: false,
      currentAppName: null,
      lastUpdateTime: null,
    );
  }

  // Track current foreground app
  Future<void> _trackForegroundApp() async {
    try {
      final appName = await _foregroundAppService.getForegroundAppName();
      final now = DateTime.now();

      // If app changed, save previous activity and start new one
      if (appName != _lastTrackedApp) {
        // Save previous activity if it exists
        if (_lastTrackedApp != null && _lastAppStartTime != null) {
          await _saveCurrentActivity();
        }

        // Start tracking new app
        _lastTrackedApp = appName;
        _lastAppStartTime = now;
      }

      state = state.copyWith(
        currentAppName: appName,
        lastUpdateTime: now,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to get foreground app: $e',
      );
    }
  }

  // Save current activity to database
  Future<void> _saveCurrentActivity() async {
    if (_lastTrackedApp == null || _lastAppStartTime == null) return;

    try {
      final endTime = DateTime.now();
      final duration = endTime.difference(_lastAppStartTime!);

      // Only save if duration is meaningful (at least 5 seconds)
      if (duration.inSeconds >= 5) {
        final activity = Activity.tracked(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _lastTrackedApp!,
          startTime: _lastAppStartTime!,
          endTime: endTime,
          category: 'Auto-tracked', // Will be categorized by ML later
        );

        await _activityRepository.saveActivity(activity);
      }
    } catch (e) {
      debugPrint('Failed to save tracked activity: $e');
    }
  }

  // Get tracking statistics
  Future<Map<String, dynamic>> getTrackingStats() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final activities = await _activityRepository.getActivitiesByDateRange(
        startOfDay,
        today,
      );

      final trackedActivities = activities.where((a) => a.isTracked).toList();
      final totalDuration = trackedActivities.fold<Duration>(
        Duration.zero,
        (sum, activity) => sum + activity.duration,
      );

      final appCounts = <String, int>{};
      for (final activity in trackedActivities) {
        appCounts[activity.name] = (appCounts[activity.name] ?? 0) + 1;
      }

      return {
        'totalActivities': trackedActivities.length,
        'totalDuration': totalDuration,
        'appCounts': appCounts,
        'mostUsedApp': appCounts.isNotEmpty 
            ? appCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : null,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }
}

// Provider instances
final foregroundAppServiceProvider = Provider<ForegroundAppService>((ref) {
  return ForegroundAppService();
});

final autoTrackerProvider = StateNotifierProvider<AutoTrackerNotifier, AutoTrackerState>((ref) {
  final foregroundAppService = ref.watch(foregroundAppServiceProvider);
  final activityRepository = ref.watch(activityRepositoryProvider);
  
  return AutoTrackerNotifier(foregroundAppService, activityRepository);
});

// Convenience providers
final isAutoTrackingEnabledProvider = Provider<bool>((ref) {
  return ref.watch(autoTrackerProvider).isEnabled;
});

final currentTrackedAppProvider = Provider<String?>((ref) {
  return ref.watch(autoTrackerProvider).currentAppName;
});

final autoTrackingErrorProvider = Provider<String?>((ref) {
  return ref.watch(autoTrackerProvider).errorMessage;
});