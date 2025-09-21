import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/activity.dart';

class ActivityService {
  static const String _boxName = 'activities';
  Box<Activity>? _box;

  // Initialize the box
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<Activity>(_boxName);
    }
  }

  // Save a new activity
  Future<void> saveActivity(Activity activity) async {
    await init();
    await _box!.put(activity.id, activity);
  }

  // Get all activities
  Future<List<Activity>> getAllActivities() async {
    await init();
    return _box!.values.toList();
  }

  // Get activities for a specific date
  Future<List<Activity>> getActivitiesForDate(DateTime date) async {
    await init();
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return _box!.values
        .where((activity) => 
            activity.timestamp.isAfter(startOfDay) && 
            activity.timestamp.isBefore(endOfDay))
        .toList();
  }

  // Get activities by category
  Future<List<Activity>> getActivitiesByCategory(String category) async {
    await init();
    return _box!.values
        .where((activity) => activity.category == category)
        .toList();
  }

  // Get activities in date range
  Future<List<Activity>> getActivitiesInDateRange(
    DateTime startDate, 
    DateTime endDate,
  ) async {
    await init();
    return _box!.values
        .where((activity) => 
            activity.timestamp.isAfter(startDate) && 
            activity.timestamp.isBefore(endDate))
        .toList();
  }

  // Delete an activity
  Future<void> deleteActivity(String id) async {
    await init();
    await _box!.delete(id);
  }

  // Update an activity
  Future<void> updateActivity(Activity activity) async {
    await init();
    await _box!.put(activity.id, activity);
  }

  // Get total time for a category
  Future<int> getTotalTimeForCategory(String category) async {
    await init();
    final activities = await getActivitiesByCategory(category);
    return activities.fold<int>(0, (total, activity) => total + activity.durationSeconds);
  }

  // Get total time for a date
  Future<int> getTotalTimeForDate(DateTime date) async {
    await init();
    final activities = await getActivitiesForDate(date);
    return activities.fold<int>(0, (total, activity) => total + activity.durationSeconds);
  }

  // Clear all activities (for testing/reset)
  Future<void> clearAllActivities() async {
    await init();
    await _box!.clear();
  }

  // Get activity count
  Future<int> getActivityCount() async {
    await init();
    return _box!.length;
  }

  // Close the box
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}

// Riverpod providers
final activityServiceProvider = Provider<ActivityService>((ref) {
  return ActivityService();
});

// Provider for getting all activities
final allActivitiesProvider = FutureProvider<List<Activity>>((ref) async {
  final service = ref.read(activityServiceProvider);
  return service.getAllActivities();
});

// Provider for getting today's activities
final todaysActivitiesProvider = FutureProvider<List<Activity>>((ref) async {
  final service = ref.read(activityServiceProvider);
  return service.getActivitiesForDate(DateTime.now());
});

// Provider for useful activities today
final usefulActivitiesTodayProvider = FutureProvider<List<Activity>>((ref) async {
  final service = ref.read(activityServiceProvider);
  final today = DateTime.now();
  final activities = await service.getActivitiesForDate(today);
  return activities.where((activity) => activity.category == 'useful').toList();
});

// Provider for wasted activities today
final wastedActivitiesTodayProvider = FutureProvider<List<Activity>>((ref) async {
  final service = ref.read(activityServiceProvider);
  final today = DateTime.now();
  final activities = await service.getActivitiesForDate(today);
  return activities.where((activity) => activity.category == 'wasted').toList();
});

// Provider for total useful time today
final totalUsefulTimeTodayProvider = FutureProvider<int>((ref) async {
  final activities = await ref.read(usefulActivitiesTodayProvider.future);
  return activities.fold<int>(0, (total, activity) => total + activity.durationSeconds);
});

// Provider for total wasted time today
final totalWastedTimeTodayProvider = FutureProvider<int>((ref) async {
  final activities = await ref.read(wastedActivitiesTodayProvider.future);
  return activities.fold<int>(0, (total, activity) => total + activity.durationSeconds);
});