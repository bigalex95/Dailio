import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../repositories/activity_repository.dart';

/// Provider for the ActivityRepository singleton
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository();
});

/// Provider for all activities
final allActivitiesProvider = FutureProvider<List<Activity>>((ref) async {
  final repository = ref.read(activityRepositoryProvider);
  return repository.getAllActivities();
});

/// Provider for today's activities
final todaysActivitiesProvider = FutureProvider<List<Activity>>((ref) async {
  final repository = ref.read(activityRepositoryProvider);
  return repository.getTodaysActivities();
});

/// Provider for activities by date range
final activitiesByDateRangeProvider = FutureProvider.family<List<Activity>, DateRange>((ref, dateRange) async {
  final repository = ref.read(activityRepositoryProvider);
  return repository.getActivitiesByDateRange(dateRange.start, dateRange.end);
});

/// Provider for activities for a specific date
final activitiesForDateProvider = FutureProvider.family<List<Activity>, DateTime>((ref, date) async {
  final repository = ref.read(activityRepositoryProvider);
  return repository.getActivitiesForDate(date);
});

/// Provider for activities by category
final activitiesByCategoryProvider = FutureProvider.family<List<Activity>, String>((ref, category) async {
  final repository = ref.read(activityRepositoryProvider);
  return repository.getActivitiesByCategory(category);
});

/// Provider for useful activities today
final usefulActivitiesTodayProvider = FutureProvider<List<Activity>>((ref) async {
  final repository = ref.read(activityRepositoryProvider);
  final today = DateTime.now();
  return repository.getActivitiesByCategoryAndDateRange('useful', today, today);
});

/// Provider for wasted activities today
final wastedActivitiesTodayProvider = FutureProvider<List<Activity>>((ref) async {
  final repository = ref.read(activityRepositoryProvider);
  final today = DateTime.now();
  return repository.getActivitiesByCategoryAndDateRange('wasted', today, today);
});

/// Provider for total duration today
final totalDurationTodayProvider = FutureProvider<int>((ref) async {
  final repository = ref.read(activityRepositoryProvider);
  final today = DateTime.now();
  return repository.getTotalDurationForDate(today);
});

/// Provider for total useful duration today
final totalUsefulDurationTodayProvider = FutureProvider<int>((ref) async {
  final repository = ref.read(activityRepositoryProvider);
  final today = DateTime.now();
  return repository.getTotalDurationByCategoryForDate('useful', today);
});

/// Provider for total wasted duration today
final totalWastedDurationTodayProvider = FutureProvider<int>((ref) async {
  final repository = ref.read(activityRepositoryProvider);
  final today = DateTime.now();
  return repository.getTotalDurationByCategoryForDate('wasted', today);
});

/// Provider for activity count
final activityCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.read(activityRepositoryProvider);
  return repository.getActivityCount();
});

/// Provider for unique categories
final uniqueCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.read(activityRepositoryProvider);
  return repository.getUniqueCategories();
});

/// Provider for activity summary statistics
final activitySummaryProvider = FutureProvider<ActivitySummary>((ref) async {
  final repository = ref.read(activityRepositoryProvider);
  return repository.getSummary();
});

/// Provider for activities grouped by date
final activitiesGroupedByDateProvider = FutureProvider<Map<DateTime, List<Activity>>>((ref) async {
  final repository = ref.read(activityRepositoryProvider);
  return repository.getActivitiesGroupedByDate();
});

/// Provider for searching activities
final searchActivitiesProvider = FutureProvider.family<List<Activity>, String>((ref, query) async {
  final repository = ref.read(activityRepositoryProvider);
  return repository.searchActivitiesByName(query);
});

/// Provider for activities with minimum duration
final activitiesWithMinDurationProvider = FutureProvider.family<List<Activity>, int>((ref, minDuration) async {
  final repository = ref.read(activityRepositoryProvider);
  return repository.getActivitiesWithMinDuration(minDuration);
});

/// StateNotifier for managing activity operations
class ActivityNotifier extends StateNotifier<AsyncValue<List<Activity>>> {
  ActivityNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadActivities();
  }

  final ActivityRepository _repository;

  Future<void> _loadActivities() async {
    try {
      final activities = await _repository.getAllActivities();
      state = AsyncValue.data(activities);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> saveActivity(Activity activity) async {
    try {
      await _repository.saveActivity(activity);
      await _loadActivities(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateActivity(Activity activity) async {
    try {
      await _repository.updateActivity(activity);
      await _loadActivities(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteActivity(String id) async {
    try {
      await _repository.deleteActivity(id);
      await _loadActivities(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteActivities(List<String> ids) async {
    try {
      await _repository.deleteActivities(ids);
      await _loadActivities(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> clearAllActivities() async {
    try {
      await _repository.clearAllActivities();
      await _loadActivities(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void refresh() {
    _loadActivities();
  }
}

/// Provider for the ActivityNotifier
final activityNotifierProvider = StateNotifierProvider<ActivityNotifier, AsyncValue<List<Activity>>>((ref) {
  final repository = ref.read(activityRepositoryProvider);
  return ActivityNotifier(repository);
});

/// Convenience provider for easy access to activity operations
final activityOperationsProvider = Provider<ActivityOperations>((ref) {
  final repository = ref.read(activityRepositoryProvider);
  final notifier = ref.read(activityNotifierProvider.notifier);
  return ActivityOperations(repository, notifier);
});

/// Helper class for common activity operations
class ActivityOperations {
  final ActivityRepository _repository;
  final ActivityNotifier _notifier;

  const ActivityOperations(this._repository, this._notifier);

  Future<void> saveActivity(Activity activity) => _notifier.saveActivity(activity);
  Future<void> updateActivity(Activity activity) => _notifier.updateActivity(activity);
  Future<void> deleteActivity(String id) => _notifier.deleteActivity(id);
  Future<void> deleteActivities(List<String> ids) => _notifier.deleteActivities(ids);
  Future<void> clearAllActivities() => _notifier.clearAllActivities();
  
  Future<Activity?> getActivityById(String id) => _repository.getActivityById(id);
  Future<List<Activity>> searchActivities(String query) => _repository.searchActivitiesByName(query);
  Future<ActivitySummary> getSummary() => _repository.getSummary();
  
  void refresh() => _notifier.refresh();
}

/// Helper class for date range queries
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange(this.start, this.end);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode;

  @override
  String toString() => 'DateRange(start: $start, end: $end)';

  /// Create a date range for today
  factory DateRange.today() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59, 999);
    return DateRange(startOfDay, endOfDay);
  }

  /// Create a date range for this week
  factory DateRange.thisWeek() {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return DateRange(
      DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59, 999),
    );
  }

  /// Create a date range for this month
  factory DateRange.thisMonth() {
    final today = DateTime.now();
    final startOfMonth = DateTime(today.year, today.month, 1);
    final endOfMonth = DateTime(today.year, today.month + 1, 0, 23, 59, 59, 999);
    return DateRange(startOfMonth, endOfMonth);
  }
}