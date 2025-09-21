import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/activity.dart';
import '../repositories/activity_repository.dart';
import 'activity_repository_provider.dart';

/// Data model for daily bar chart
class DailyBarData {
  final DateTime date;
  final double usefulHours;
  final double wastedHours;

  const DailyBarData({
    required this.date,
    required this.usefulHours,
    required this.wastedHours,
  });

  double get totalHours => usefulHours + wastedHours;
  
  String get formattedDate {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }
}

/// Data model for weekly pie chart
class WeeklyPieData {
  final double usefulHours;
  final double wastedHours;
  final double neutralHours;

  const WeeklyPieData({
    required this.usefulHours,
    required this.wastedHours,
    this.neutralHours = 0,
  });

  double get totalHours => usefulHours + wastedHours + neutralHours;
  
  double get usefulPercentage => totalHours > 0 ? (usefulHours / totalHours) * 100 : 0;
  double get wastedPercentage => totalHours > 0 ? (wastedHours / totalHours) * 100 : 0;
  double get neutralPercentage => totalHours > 0 ? (neutralHours / totalHours) * 100 : 0;
}

/// Data model for trend line chart
class TrendLineData {
  final DateTime date;
  final double wastedHours;

  const TrendLineData({
    required this.date,
    required this.wastedHours,
  });
}

/// Data model for day summary
class DaySummary {
  final double usefulHours;
  final double wastedHours;
  final double totalHours;

  const DaySummary({
    required this.usefulHours,
    required this.wastedHours,
    required this.totalHours,
  });

  double get productivityRatio => totalHours > 0 ? usefulHours / totalHours : 0;
  
  String get formattedUsefulTime => _formatHours(usefulHours);
  String get formattedWastedTime => _formatHours(wastedHours);
  String get formattedTotalTime => _formatHours(totalHours);

  String _formatHours(double hours) {
    if (hours < 1) {
      return '${(hours * 60).round()}m';
    } else {
      final h = hours.floor();
      final m = ((hours - h) * 60).round();
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
  }
}

/// Provider for daily bar chart data (last 7 days)
final dailyBarChartDataProvider = FutureProvider<List<DailyBarData>>((ref) async {
  final repository = ref.read(activityRepositoryProvider);
  final today = DateTime.now();
  final sevenDaysAgo = today.subtract(const Duration(days: 6));
  
  final activities = await repository.getActivitiesByDateRange(sevenDaysAgo, today);
  
  // Group activities by date
  final Map<DateTime, List<Activity>> groupedByDate = {};
  for (int i = 0; i < 7; i++) {
    final date = sevenDaysAgo.add(Duration(days: i));
    final dateKey = DateTime(date.year, date.month, date.day);
    groupedByDate[dateKey] = [];
  }
  
  for (final activity in activities) {
    final dateKey = DateTime(
      activity.timestamp.year,
      activity.timestamp.month,
      activity.timestamp.day,
    );
    if (groupedByDate.containsKey(dateKey)) {
      groupedByDate[dateKey]!.add(activity);
    }
  }
  
  // Calculate daily totals
  final List<DailyBarData> chartData = [];
  for (final entry in groupedByDate.entries) {
    final date = entry.key;
    final dayActivities = entry.value;
    
    double usefulHours = 0;
    double wastedHours = 0;
    
    for (final activity in dayActivities) {
      final hours = activity.durationSeconds / 3600.0;
      if (activity.category.toLowerCase() == 'useful') {
        usefulHours += hours;
      } else if (activity.category.toLowerCase() == 'wasted') {
        wastedHours += hours;
      }
    }
    
    chartData.add(DailyBarData(
      date: date,
      usefulHours: usefulHours,
      wastedHours: wastedHours,
    ));
  }
  
  return chartData;
});

/// Provider for weekly pie chart data
final weeklyPieChartDataProvider = FutureProvider<WeeklyPieData>((ref) async {
  final repository = ref.read(activityRepositoryProvider);
  final today = DateTime.now();
  final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 6));
  
  final activities = await repository.getActivitiesByDateRange(startOfWeek, endOfWeek);
  
  double usefulHours = 0;
  double wastedHours = 0;
  double neutralHours = 0;
  
  for (final activity in activities) {
    final hours = activity.durationSeconds / 3600.0;
    switch (activity.category.toLowerCase()) {
      case 'useful':
        usefulHours += hours;
        break;
      case 'wasted':
        wastedHours += hours;
        break;
      default:
        neutralHours += hours;
        break;
    }
  }
  
  return WeeklyPieData(
    usefulHours: usefulHours,
    wastedHours: wastedHours,
    neutralHours: neutralHours,
  );
});

/// Provider for trend line chart data (last 14 days)
final trendLineChartDataProvider = FutureProvider<List<TrendLineData>>((ref) async {
  final repository = ref.read(activityRepositoryProvider);
  final today = DateTime.now();
  final fourteenDaysAgo = today.subtract(const Duration(days: 13));
  
  final activities = await repository.getActivitiesByDateRange(fourteenDaysAgo, today);
  
  // Group by date
  final Map<DateTime, List<Activity>> groupedByDate = {};
  for (int i = 0; i < 14; i++) {
    final date = fourteenDaysAgo.add(Duration(days: i));
    final dateKey = DateTime(date.year, date.month, date.day);
    groupedByDate[dateKey] = [];
  }
  
  for (final activity in activities) {
    final dateKey = DateTime(
      activity.timestamp.year,
      activity.timestamp.month,
      activity.timestamp.day,
    );
    if (groupedByDate.containsKey(dateKey)) {
      groupedByDate[dateKey]!.add(activity);
    }
  }
  
  // Calculate daily wasted hours
  final List<TrendLineData> chartData = [];
  for (final entry in groupedByDate.entries) {
    final date = entry.key;
    final dayActivities = entry.value;
    
    double wastedHours = 0;
    for (final activity in dayActivities) {
      if (activity.category.toLowerCase() == 'wasted') {
        wastedHours += activity.durationSeconds / 3600.0;
      }
    }
    
    chartData.add(TrendLineData(
      date: date,
      wastedHours: wastedHours,
    ));
  }
  
  return chartData;
});

/// Provider for today's summary stats
final todayStatsProvider = FutureProvider<DaySummary>((ref) async {
  final repository = ref.read(activityRepositoryProvider);
  final today = DateTime.now();
  
  final activities = await repository.getActivitiesForDate(today);
  
  double usefulHours = 0;
  double wastedHours = 0;
  
  for (final activity in activities) {
    final hours = activity.durationSeconds / 3600.0;
    if (activity.category.toLowerCase() == 'useful') {
      usefulHours += hours;
    } else if (activity.category.toLowerCase() == 'wasted') {
      wastedHours += hours;
    }
  }
  
  return DaySummary(
    usefulHours: usefulHours,
    wastedHours: wastedHours,
    totalHours: usefulHours + wastedHours,
  );
});

/// Provider for weekly summary stats
final weeklyStatsProvider = FutureProvider<DaySummary>((ref) async {
  final repository = ref.read(activityRepositoryProvider);
  final today = DateTime.now();
  final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 6));
  
  final activities = await repository.getActivitiesByDateRange(startOfWeek, endOfWeek);
  
  double usefulHours = 0;
  double wastedHours = 0;
  
  for (final activity in activities) {
    final hours = activity.durationSeconds / 3600.0;
    if (activity.category.toLowerCase() == 'useful') {
      usefulHours += hours;
    } else if (activity.category.toLowerCase() == 'wasted') {
      wastedHours += hours;
    }
  }
  
  return DaySummary(
    usefulHours: usefulHours,
    wastedHours: wastedHours,
    totalHours: usefulHours + wastedHours,
  );
});

/// Mock data generator for testing when repository is empty
final mockDataGeneratorProvider = Provider<MockDataGenerator>((ref) {
  return MockDataGenerator();
});

class MockDataGenerator {
  /// Generate mock activities for testing charts
  List<Activity> generateMockActivities() {
    final List<Activity> activities = [];
    final now = DateTime.now();
    
    // Generate activities for the last 14 days
    for (int day = 0; day < 14; day++) {
      final date = now.subtract(Duration(days: day));
      
      // Add 2-5 activities per day
      final activitiesPerDay = 2 + (day % 4);
      for (int i = 0; i < activitiesPerDay; i++) {
        final isUseful = (i + day) % 3 != 0; // ~66% useful activities
        final duration = 1800 + (i * 900) + (day * 300); // Varying durations
        
        activities.add(Activity(
          id: 'mock_${day}_$i',
          name: isUseful ? 'Mock Useful Activity $i' : 'Mock Wasted Activity $i',
          category: isUseful ? 'useful' : 'wasted',
          durationSeconds: duration,
          notes: 'Generated for testing charts',
          timestamp: date.subtract(Duration(hours: i * 2)),
        ));
      }
    }
    
    return activities;
  }
  
  /// Add mock data to repository for testing
  Future<void> addMockDataToRepository(ActivityRepository repository) async {
    final mockActivities = generateMockActivities();
    await repository.saveActivities(mockActivities);
  }
}