import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../repositories/activity_repository.dart';

/// Legacy service class - use ActivityRepository directly or via providers instead
@Deprecated('Use ActivityRepository and related providers instead')
class ActivityService {
  final ActivityRepository _repository;

  ActivityService(this._repository);

  Future<void> init() => _repository.init();
  Future<void> saveActivity(Activity activity) => _repository.saveActivity(activity);
  Future<List<Activity>> getAllActivities() => _repository.getAllActivities();
  Future<List<Activity>> getActivitiesForDate(DateTime date) => _repository.getActivitiesForDate(date);
  Future<List<Activity>> getActivitiesByCategory(String category) => _repository.getActivitiesByCategory(category);
  Future<void> deleteActivity(String id) => _repository.deleteActivity(id);
}

/// Legacy provider - use activityRepositoryProvider instead
@Deprecated('Use activityRepositoryProvider instead')
final activityServiceProvider = Provider<ActivityService>((ref) {
  final repository = ActivityRepository();
  return ActivityService(repository);
});

/// Legacy providers - use the new providers from activity_repository_provider.dart instead
@Deprecated('Use allActivitiesProvider from activity_repository_provider.dart instead')
final allActivitiesProvider = FutureProvider<List<Activity>>((ref) async {
  final service = ref.read(activityServiceProvider);
  return service.getAllActivities();
});

@Deprecated('Use todaysActivitiesProvider from activity_repository_provider.dart instead')
final todaysActivitiesProvider = FutureProvider<List<Activity>>((ref) async {
  final service = ref.read(activityServiceProvider);
  return service.getActivitiesForDate(DateTime.now());
});

@Deprecated('Use usefulActivitiesTodayProvider from activity_repository_provider.dart instead')
final usefulActivitiesTodayProvider = FutureProvider<List<Activity>>((ref) async {
  final service = ref.read(activityServiceProvider);
  final today = DateTime.now();
  final activities = await service.getActivitiesForDate(today);
  return activities.where((activity) => activity.category == 'useful').toList();
});

@Deprecated('Use wastedActivitiesTodayProvider from activity_repository_provider.dart instead')
final wastedActivitiesTodayProvider = FutureProvider<List<Activity>>((ref) async {
  final service = ref.read(activityServiceProvider);
  final today = DateTime.now();
  final activities = await service.getActivitiesForDate(today);
  return activities.where((activity) => activity.category == 'wasted').toList();
});

@Deprecated('Use totalUsefulDurationTodayProvider from activity_repository_provider.dart instead')
final totalUsefulTimeTodayProvider = FutureProvider<int>((ref) async {
  final activities = await ref.read(usefulActivitiesTodayProvider.future);
  return activities.fold<int>(0, (total, activity) => total + activity.durationSeconds);
});

@Deprecated('Use totalWastedDurationTodayProvider from activity_repository_provider.dart instead')
final totalWastedTimeTodayProvider = FutureProvider<int>((ref) async {
  final activities = await ref.read(wastedActivitiesTodayProvider.future);
  return activities.fold<int>(0, (total, activity) => total + activity.durationSeconds);
});