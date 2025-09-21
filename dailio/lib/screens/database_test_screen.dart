import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/activity.dart';
import '../providers/activity_repository_provider.dart';

/// Test screen to verify Hive database operations
class DatabaseTestScreen extends ConsumerStatefulWidget {
  const DatabaseTestScreen({super.key});

  @override
  ConsumerState<DatabaseTestScreen> createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends ConsumerState<DatabaseTestScreen> {
  final List<String> _testResults = [];
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    final activities = ref.watch(allActivitiesProvider);
    final activityCount = ref.watch(activityCountProvider);
    final summary = ref.watch(activitySummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Test'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Database Tests',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isRunning ? null : _runAllTests,
                            child: _isRunning
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      SizedBox(width: 8),
                                      Text('Running...'),
                                    ],
                                  )
                                : const Text('Run All Tests'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _clearResults,
                          child: const Text('Clear'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _clearDatabase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Clear DB'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Database Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Database Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    activityCount.when(
                      data: (count) => Text('Total Activities: $count'),
                      loading: () => const Text('Loading count...'),
                      error: (error, _) => Text('Error: $error'),
                    ),
                    const SizedBox(height: 4),
                    summary.when(
                      data: (data) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Duration: ${data.formattedTotalDuration}'),
                          Text('Average Duration: ${data.formattedAverageDuration}'),
                          Text('Unique Categories: ${data.uniqueCategories}'),
                        ],
                      ),
                      loading: () => const Text('Loading summary...'),
                      error: (error, _) => Text('Error: $error'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Results
            Expanded(
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Test Results',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _testResults.isEmpty
                          ? const Center(
                              child: Text(
                                'No tests run yet.\nTap "Run All Tests" to start.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(8.0),
                              itemCount: _testResults.length,
                              itemBuilder: (context, index) {
                                final result = _testResults[index];
                                final isError = result.startsWith('❌');
                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 2.0),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 8.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isError
                                        ? Colors.red.withValues(alpha: 0.1)
                                        : Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    result,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      color: isError ? Colors.red : Colors.green,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Recent Activities
            if (activities.hasValue && activities.value!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Recent Activities (${activities.value!.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Divider(height: 1),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        itemCount: activities.value!.length.clamp(0, 5),
                        itemBuilder: (context, index) {
                          final activity = activities.value![index];
                          return ListTile(
                            dense: true,
                            title: Text(activity.name),
                            subtitle: Text(
                              '${activity.categoryDisplayName} • ${activity.formattedDuration}',
                            ),
                            trailing: Text(
                              '${activity.timestamp.hour.toString().padLeft(2, '0')}:'
                              '${activity.timestamp.minute.toString().padLeft(2, '0')}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _log(String message) {
    setState(() {
      _testResults.add(message);
    });
  }

  void _clearResults() {
    setState(() {
      _testResults.clear();
    });
  }

  Future<void> _clearDatabase() async {
    try {
      await ref.read(activityOperationsProvider).clearAllActivities();
      _log('✅ Database cleared successfully');
      // Refresh providers
      ref.invalidate(allActivitiesProvider);
      ref.invalidate(activityCountProvider);
      ref.invalidate(activitySummaryProvider);
    } catch (e) {
      _log('❌ Failed to clear database: $e');
    }
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isRunning = true;
      _testResults.clear();
    });

    try {
      _log('🚀 Starting database tests...');
      
      await _testBasicOperations();
      await _testDateRangeQueries();
      await _testCategoryQueries();
      await _testSearchOperations();
      await _testStatistics();
      
      _log('✅ All tests completed successfully!');
    } catch (e) {
      _log('❌ Test suite failed: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
      
      // Refresh all providers
      ref.invalidate(allActivitiesProvider);
      ref.invalidate(activityCountProvider);
      ref.invalidate(activitySummaryProvider);
    }
  }

  Future<void> _testBasicOperations() async {
    _log('📝 Testing basic CRUD operations...');
    
    final repository = ref.read(activityRepositoryProvider);
    const uuid = Uuid();

    // Test Save
    final testActivity = Activity.create(
      id: uuid.v4(),
      name: 'Test Activity',
      category: 'useful',
      durationSeconds: 1800, // 30 minutes
      notes: 'This is a test activity',
    );

    await repository.saveActivity(testActivity);
    _log('✅ Save operation successful');

    // Test Get by ID
    final retrieved = await repository.getActivityById(testActivity.id);
    if (retrieved != null && retrieved.name == testActivity.name) {
      _log('✅ Get by ID successful');
    } else {
      _log('❌ Get by ID failed');
    }

    // Test Update
    final updated = testActivity.copyWith(name: 'Updated Test Activity');
    await repository.updateActivity(updated);
    final retrievedUpdated = await repository.getActivityById(testActivity.id);
    if (retrievedUpdated?.name == 'Updated Test Activity') {
      _log('✅ Update operation successful');
    } else {
      _log('❌ Update operation failed');
    }

    // Test Delete
    await repository.deleteActivity(testActivity.id);
    final deletedCheck = await repository.getActivityById(testActivity.id);
    if (deletedCheck == null) {
      _log('✅ Delete operation successful');
    } else {
      _log('❌ Delete operation failed');
    }
  }

  Future<void> _testDateRangeQueries() async {
    _log('📅 Testing date range queries...');
    
    final repository = ref.read(activityRepositoryProvider);
    const uuid = Uuid();
    
    // Create test activities for different dates
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    final activities = [
      Activity(
        id: uuid.v4(),
        name: 'Yesterday Activity',
        category: 'useful',
        durationSeconds: 3600,
        timestamp: yesterday,
      ),
      Activity(
        id: uuid.v4(),
        name: 'Today Activity',
        category: 'wasted',
        durationSeconds: 1800,
        timestamp: today,
      ),
      Activity(
        id: uuid.v4(),
        name: 'Tomorrow Activity',
        category: 'useful',
        durationSeconds: 2400,
        timestamp: tomorrow,
      ),
    ];

    await repository.saveActivities(activities);

    // Test today's activities
    final todaysActivities = await repository.getTodaysActivities();
    final todayCount = todaysActivities.where((a) => a.name.contains('Today')).length;
    if (todayCount > 0) {
      _log('✅ Today\'s activities query successful');
    } else {
      _log('❌ Today\'s activities query failed');
    }

    // Test date range
    final rangeActivities = await repository.getActivitiesByDateRange(yesterday, tomorrow);
    if (rangeActivities.length >= 3) {
      _log('✅ Date range query successful');
    } else {
      _log('❌ Date range query failed (found ${rangeActivities.length}/3)');
    }

    // Cleanup
    await repository.deleteActivities(activities.map((a) => a.id).toList());
  }

  Future<void> _testCategoryQueries() async {
    _log('🏷️ Testing category queries...');
    
    final repository = ref.read(activityRepositoryProvider);
    const uuid = Uuid();

    // Create test activities with different categories
    final activities = [
      Activity.create(id: uuid.v4(), name: 'Useful 1', category: 'useful', durationSeconds: 1800),
      Activity.create(id: uuid.v4(), name: 'Useful 2', category: 'useful', durationSeconds: 3600),
      Activity.create(id: uuid.v4(), name: 'Wasted 1', category: 'wasted', durationSeconds: 1200),
    ];

    await repository.saveActivities(activities);

    // Test category filtering
    final usefulActivities = await repository.getActivitiesByCategory('useful');
    final wastedActivities = await repository.getActivitiesByCategory('wasted');

    if (usefulActivities.length >= 2) {
      _log('✅ Useful category query successful');
    } else {
      _log('❌ Useful category query failed');
    }

    if (wastedActivities.isNotEmpty) {
      _log('✅ Wasted category query successful');
    } else {
      _log('❌ Wasted category query failed');
    }

    // Test category duration calculation
    final usefulDuration = await repository.getTotalDurationByCategory('useful');
    if (usefulDuration >= 5400) { // 1800 + 3600
      _log('✅ Category duration calculation successful');
    } else {
      _log('❌ Category duration calculation failed');
    }

    // Cleanup
    await repository.deleteActivities(activities.map((a) => a.id).toList());
  }

  Future<void> _testSearchOperations() async {
    _log('🔍 Testing search operations...');
    
    final repository = ref.read(activityRepositoryProvider);
    const uuid = Uuid();

    // Create searchable activities
    final activities = [
      Activity.create(id: uuid.v4(), name: 'Flutter Development', category: 'useful', durationSeconds: 7200),
      Activity.create(id: uuid.v4(), name: 'Social Media', category: 'wasted', durationSeconds: 1800, notes: 'Scrolling through feeds'),
      Activity.create(id: uuid.v4(), name: 'Reading Documentation', category: 'useful', durationSeconds: 3600),
    ];

    await repository.saveActivities(activities);

    // Test name search
    final flutterResults = await repository.searchActivitiesByName('Flutter');
    if (flutterResults.isNotEmpty) {
      _log('✅ Name search successful');
    } else {
      _log('❌ Name search failed');
    }

    // Test notes search
    final notesResults = await repository.searchActivitiesByName('feeds');
    if (notesResults.isNotEmpty) {
      _log('✅ Notes search successful');
    } else {
      _log('❌ Notes search failed');
    }

    // Test minimum duration filter
    final longActivities = await repository.getActivitiesWithMinDuration(3600); // 1 hour+
    if (longActivities.length >= 2) {
      _log('✅ Minimum duration filter successful');
    } else {
      _log('❌ Minimum duration filter failed');
    }

    // Cleanup
    await repository.deleteActivities(activities.map((a) => a.id).toList());
  }

  Future<void> _testStatistics() async {
    _log('📊 Testing statistics...');
    
    final repository = ref.read(activityRepositoryProvider);
    const uuid = Uuid();

    // Create activities for statistics
    final activities = [
      Activity.create(id: uuid.v4(), name: 'Work', category: 'useful', durationSeconds: 28800), // 8 hours
      Activity.create(id: uuid.v4(), name: 'Exercise', category: 'useful', durationSeconds: 3600), // 1 hour
      Activity.create(id: uuid.v4(), name: 'TV', category: 'wasted', durationSeconds: 7200), // 2 hours
    ];

    await repository.saveActivities(activities);

    // Test summary
    final summary = await repository.getSummary();
    if (summary.totalActivities >= 3 && summary.totalDuration >= 39600) {
      _log('✅ Summary statistics successful');
    } else {
      _log('❌ Summary statistics failed');
    }

    // Test unique categories
    final categories = await repository.getUniqueCategories();
    if (categories.contains('useful') && categories.contains('wasted')) {
      _log('✅ Unique categories query successful');
    } else {
      _log('❌ Unique categories query failed');
    }

    // Test grouped by date
    final grouped = await repository.getActivitiesGroupedByDate();
    if (grouped.isNotEmpty) {
      _log('✅ Grouped by date query successful');
    } else {
      _log('❌ Grouped by date query failed');
    }

    // Cleanup
    await repository.deleteActivities(activities.map((a) => a.id).toList());
  }
}