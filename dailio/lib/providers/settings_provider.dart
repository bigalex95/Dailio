import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Settings state class
class SettingsState {
  final bool autoTrackingEnabled;
  final int autoTrackingInterval; // in seconds
  final bool showNotifications;
  final bool exportIncludeNotes;
  final String defaultCategory;
  final bool darkMode;
  final String exportFormat;

  const SettingsState({
    this.autoTrackingEnabled = false,
    this.autoTrackingInterval = 5,
    this.showNotifications = true,
    this.exportIncludeNotes = true,
    this.defaultCategory = 'Work',
    this.darkMode = false,
    this.exportFormat = 'CSV',
  });

  SettingsState copyWith({
    bool? autoTrackingEnabled,
    int? autoTrackingInterval,
    bool? showNotifications,
    bool? exportIncludeNotes,
    String? defaultCategory,
    bool? darkMode,
    String? exportFormat,
  }) {
    return SettingsState(
      autoTrackingEnabled: autoTrackingEnabled ?? this.autoTrackingEnabled,
      autoTrackingInterval: autoTrackingInterval ?? this.autoTrackingInterval,
      showNotifications: showNotifications ?? this.showNotifications,
      exportIncludeNotes: exportIncludeNotes ?? this.exportIncludeNotes,
      defaultCategory: defaultCategory ?? this.defaultCategory,
      darkMode: darkMode ?? this.darkMode,
      exportFormat: exportFormat ?? this.exportFormat,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoTrackingEnabled': autoTrackingEnabled,
      'autoTrackingInterval': autoTrackingInterval,
      'showNotifications': showNotifications,
      'exportIncludeNotes': exportIncludeNotes,
      'defaultCategory': defaultCategory,
      'darkMode': darkMode,
      'exportFormat': exportFormat,
    };
  }

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      autoTrackingEnabled: json['autoTrackingEnabled'] as bool? ?? false,
      autoTrackingInterval: json['autoTrackingInterval'] as int? ?? 5,
      showNotifications: json['showNotifications'] as bool? ?? true,
      exportIncludeNotes: json['exportIncludeNotes'] as bool? ?? true,
      defaultCategory: json['defaultCategory'] as String? ?? 'Work',
      darkMode: json['darkMode'] as bool? ?? false,
      exportFormat: json['exportFormat'] as String? ?? 'CSV',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SettingsState &&
        other.autoTrackingEnabled == autoTrackingEnabled &&
        other.autoTrackingInterval == autoTrackingInterval &&
        other.showNotifications == showNotifications &&
        other.exportIncludeNotes == exportIncludeNotes &&
        other.defaultCategory == defaultCategory &&
        other.darkMode == darkMode &&
        other.exportFormat == exportFormat;
  }

  @override
  int get hashCode {
    return Object.hash(
      autoTrackingEnabled,
      autoTrackingInterval,
      showNotifications,
      exportIncludeNotes,
      defaultCategory,
      darkMode,
      exportFormat,
    );
  }

  @override
  String toString() {
    return 'SettingsState(autoTrackingEnabled: $autoTrackingEnabled, autoTrackingInterval: $autoTrackingInterval, showNotifications: $showNotifications, exportIncludeNotes: $exportIncludeNotes, defaultCategory: $defaultCategory, darkMode: $darkMode, exportFormat: $exportFormat)';
  }
}

/// Settings notifier for managing application settings
class SettingsNotifier extends StateNotifier<SettingsState> {
  static const String _settingsBoxName = 'settings';
  static const String _settingsKey = 'app_settings';
  
  late Box _settingsBox;

  SettingsNotifier() : super(const SettingsState()) {
    _initializeSettings();
  }

  /// Initialize settings from storage
  Future<void> _initializeSettings() async {
    try {
      _settingsBox = await Hive.openBox(_settingsBoxName);
      await _loadSettings();
    } catch (e) {
      debugPrint('Failed to initialize settings: $e');
    }
  }

  /// Load settings from storage
  Future<void> _loadSettings() async {
    try {
      final savedSettings = _settingsBox.get(_settingsKey);
      if (savedSettings != null) {
        final settingsMap = Map<String, dynamic>.from(savedSettings);
        state = SettingsState.fromJson(settingsMap);
      }
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    }
  }

  /// Save settings to storage
  Future<void> _saveSettings() async {
    try {
      await _settingsBox.put(_settingsKey, state.toJson());
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }

  // Public methods for updating settings

  /// Toggle auto-tracking feature
  Future<void> toggleAutoTracking(bool enabled) async {
    state = state.copyWith(autoTrackingEnabled: enabled);
    await _saveSettings();
  }

  /// Update auto-tracking interval
  Future<void> updateAutoTrackingInterval(int intervalSeconds) async {
    if (intervalSeconds >= 1 && intervalSeconds <= 60) {
      state = state.copyWith(autoTrackingInterval: intervalSeconds);
      await _saveSettings();
    }
  }

  /// Toggle notifications
  Future<void> toggleNotifications(bool enabled) async {
    state = state.copyWith(showNotifications: enabled);
    await _saveSettings();
  }

  /// Toggle export notes inclusion
  Future<void> toggleExportIncludeNotes(bool include) async {
    state = state.copyWith(exportIncludeNotes: include);
    await _saveSettings();
  }

  /// Update default category
  Future<void> updateDefaultCategory(String category) async {
    if (category.isNotEmpty) {
      state = state.copyWith(defaultCategory: category);
      await _saveSettings();
    }
  }

  /// Toggle dark mode
  Future<void> toggleDarkMode(bool enabled) async {
    state = state.copyWith(darkMode: enabled);
    await _saveSettings();
  }

  /// Update export format
  Future<void> updateExportFormat(String format) async {
    final validFormats = ['CSV', 'JSON'];
    if (validFormats.contains(format)) {
      state = state.copyWith(exportFormat: format);
      await _saveSettings();
    }
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    state = const SettingsState();
    await _saveSettings();
  }

  /// Import settings from JSON
  Future<bool> importSettings(Map<String, dynamic> settingsJson) async {
    try {
      final newSettings = SettingsState.fromJson(settingsJson);
      state = newSettings;
      await _saveSettings();
      return true;
    } catch (e) {
      debugPrint('Failed to import settings: $e');
      return false;
    }
  }

  /// Export settings to JSON
  Map<String, dynamic> exportSettings() {
    return state.toJson();
  }

  /// Get available categories for default selection
  List<String> getAvailableCategories() {
    return [
      'Work',
      'Personal',
      'Study',
      'Exercise',
      'Entertainment',
      'Social',
      'Other',
    ];
  }

  /// Get available export formats
  List<String> getAvailableExportFormats() {
    return ['CSV', 'JSON'];
  }

  /// Validate auto-tracking interval
  String? validateAutoTrackingInterval(int interval) {
    if (interval < 1) {
      return 'Interval must be at least 1 second';
    }
    if (interval > 60) {
      return 'Interval cannot exceed 60 seconds';
    }
    return null;
  }

  /// Get settings validation status
  Map<String, String?> validateSettings() {
    final errors = <String, String?>{};

    final intervalError = validateAutoTrackingInterval(state.autoTrackingInterval);
    if (intervalError != null) {
      errors['autoTrackingInterval'] = intervalError;
    }

    if (state.defaultCategory.isEmpty) {
      errors['defaultCategory'] = 'Default category cannot be empty';
    }

    return errors;
  }

  @override
  void dispose() {
    _settingsBox.close();
    super.dispose();
  }
}

/// Provider for settings state
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

/// Provider for auto-tracking enabled status (convenience provider)
final autoTrackingEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).autoTrackingEnabled;
});

/// Provider for dark mode status (convenience provider)
final darkModeProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).darkMode;
});

/// Provider for default category (convenience provider)
final defaultCategoryProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).defaultCategory;
});

/// Provider for export format (convenience provider)
final exportFormatProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).exportFormat;
});