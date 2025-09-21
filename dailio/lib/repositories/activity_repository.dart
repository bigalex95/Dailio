import 'package:hive_flutter/hive_flutter.dart';
import '../models/activity.dart';

/// Repository class for managing Activity data using Hive local database
class ActivityRepository {
  static const String _boxName = 'activities';
  Box<Activity>? _box;
  
  /// Initialize the Hive box
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<Activity>(_boxName);
    }
  }

  /// Ensure box is initialized before operations
  Future<void> _ensureInitialized() async {
    await init();
    if (_box == null) {
      throw Exception('Failed to initialize Activities box');
    }
  }

  /// Save a new activity to the database
  Future<void> saveActivity(Activity activity) async {
    await _ensureInitialized();
    await _box!.put(activity.id, activity);
  }

  /// Save multiple activities at once
  Future<void> saveActivities(List<Activity> activities) async {
    await _ensureInitialized();
    final Map<String, Activity> activitiesMap = {
      for (Activity activity in activities) activity.id: activity
    };
    await _box!.putAll(activitiesMap);
  }

  /// Get all activities from the database
  Future<List<Activity>> getAllActivities() async {
    await _ensureInitialized();
    return _box!.values.toList();
  }

  /// Get activities within a specific date range
  Future<List<Activity>> getActivitiesByDateRange(
    DateTime start, 
    DateTime end,
  ) async {
    await _ensureInitialized();
    
    // Ensure start is beginning of day and end is end of day
    final startOfDay = DateTime(start.year, start.month, start.day);
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    
    return _box!.values
        .where((activity) => 
            activity.timestamp.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) && 
            activity.timestamp.isBefore(endOfDay.add(const Duration(milliseconds: 1))))
        .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort by newest first
  }

  /// Get activities for a specific date
  Future<List<Activity>> getActivitiesForDate(DateTime date) async {
    return getActivitiesByDateRange(date, date);
  }

  /// Get activities for today
  Future<List<Activity>> getTodaysActivities() async {
    final today = DateTime.now();
    return getActivitiesForDate(today);
  }

  /// Get activities by category
  Future<List<Activity>> getActivitiesByCategory(String category) async {
    await _ensureInitialized();
    return _box!.values
        .where((activity) => activity.category.toLowerCase() == category.toLowerCase())
        .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get activities by category within date range
  Future<List<Activity>> getActivitiesByCategoryAndDateRange(
    String category,
    DateTime start,
    DateTime end,
  ) async {
    final activitiesInRange = await getActivitiesByDateRange(start, end);
    return activitiesInRange
        .where((activity) => activity.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Get a single activity by ID
  Future<Activity?> getActivityById(String id) async {
    await _ensureInitialized();
    return _box!.get(id);
  }

  /// Update an existing activity
  Future<void> updateActivity(Activity activity) async {
    await _ensureInitialized();
    await _box!.put(activity.id, activity);
  }

  /// Delete an activity by ID
  Future<void> deleteActivity(String id) async {
    await _ensureInitialized();
    await _box!.delete(id);
  }

  /// Delete multiple activities by IDs
  Future<void> deleteActivities(List<String> ids) async {
    await _ensureInitialized();
    await _box!.deleteAll(ids);
  }

  /// Clear all activities (use with caution)
  Future<void> clearAllActivities() async {
    await _ensureInitialized();
    await _box!.clear();
  }

  /// Get total count of activities
  Future<int> getActivityCount() async {
    await _ensureInitialized();
    return _box!.length;
  }

  /// Get total duration for all activities
  Future<int> getTotalDuration() async {
    final activities = await getAllActivities();
    return activities.fold<int>(0, (total, activity) => total + activity.durationSeconds);
  }

  /// Get total duration for a specific category
  Future<int> getTotalDurationByCategory(String category) async {
    final activities = await getActivitiesByCategory(category);
    return activities.fold<int>(0, (total, activity) => total + activity.durationSeconds);
  }

  /// Get total duration for a specific date
  Future<int> getTotalDurationForDate(DateTime date) async {
    final activities = await getActivitiesForDate(date);
    return activities.fold<int>(0, (total, activity) => total + activity.durationSeconds);
  }

  /// Get total duration by category for a specific date
  Future<int> getTotalDurationByCategoryForDate(String category, DateTime date) async {
    final activities = await getActivitiesForDate(date);
    final categoryActivities = activities
        .where((activity) => activity.category.toLowerCase() == category.toLowerCase())
        .toList();
    return categoryActivities.fold<int>(0, (total, activity) => total + activity.durationSeconds);
  }

  /// Get activities grouped by date
  Future<Map<DateTime, List<Activity>>> getActivitiesGroupedByDate() async {
    final activities = await getAllActivities();
    final Map<DateTime, List<Activity>> grouped = {};
    
    for (final activity in activities) {
      final dateKey = activity.dateOnly;
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(activity);
    }
    
    // Sort activities within each day
    for (final dayActivities in grouped.values) {
      dayActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    
    return grouped;
  }

  /// Get unique categories used
  Future<List<String>> getUniqueCategories() async {
    final activities = await getAllActivities();
    final categories = activities.map((activity) => activity.category).toSet().toList();
    categories.sort();
    return categories;
  }

  /// Search activities by name (case-insensitive)
  Future<List<Activity>> searchActivitiesByName(String query) async {
    await _ensureInitialized();
    if (query.trim().isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    return _box!.values
        .where((activity) => 
            activity.name.toLowerCase().contains(lowerQuery) ||
            (activity.notes?.toLowerCase().contains(lowerQuery) ?? false))
        .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get activities with minimum duration
  Future<List<Activity>> getActivitiesWithMinDuration(int minDurationSeconds) async {
    final activities = await getAllActivities();
    return activities
        .where((activity) => activity.durationSeconds >= minDurationSeconds)
        .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get summary statistics
  Future<ActivitySummary> getSummary() async {
    final activities = await getAllActivities();
    
    if (activities.isEmpty) {
      return ActivitySummary(
        totalActivities: 0,
        totalDuration: 0,
        averageDuration: 0,
        uniqueCategories: 0,
        oldestActivity: null,
        newestActivity: null,
      );
    }

    final totalDuration = activities.fold<int>(0, (sum, activity) => sum + activity.durationSeconds);
    final averageDuration = totalDuration / activities.length;
    final uniqueCategories = activities.map((a) => a.category).toSet().length;
    
    activities.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    return ActivitySummary(
      totalActivities: activities.length,
      totalDuration: totalDuration,
      averageDuration: averageDuration.round(),
      uniqueCategories: uniqueCategories,
      oldestActivity: activities.first,
      newestActivity: activities.last,
    );
  }

  /// Export activities as JSON
  Future<List<Map<String, dynamic>>> exportActivities() async {
    final activities = await getAllActivities();
    return activities.map((activity) => activity.toJson()).toList();
  }

  /// Import activities from JSON
  Future<void> importActivities(List<Map<String, dynamic>> jsonData) async {
    final activities = jsonData.map((json) => Activity.fromJson(json)).toList();
    await saveActivities(activities);
  }

  /// Close the box and free resources
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }

  /// Check if the repository is initialized
  bool get isInitialized => _box != null && _box!.isOpen;
}

/// Summary statistics for activities
class ActivitySummary {
  final int totalActivities;
  final int totalDuration;
  final int averageDuration;
  final int uniqueCategories;
  final Activity? oldestActivity;
  final Activity? newestActivity;

  const ActivitySummary({
    required this.totalActivities,
    required this.totalDuration,
    required this.averageDuration,
    required this.uniqueCategories,
    this.oldestActivity,
    this.newestActivity,
  });

  String get formattedTotalDuration {
    final hours = totalDuration ~/ 3600;
    final minutes = (totalDuration % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  String get formattedAverageDuration {
    final hours = averageDuration ~/ 3600;
    final minutes = (averageDuration % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }
}