import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chart_data_providers.dart';
import '../providers/activity_repository_provider.dart';

/// Widget to add mock data for testing charts
class MockDataHelper extends ConsumerWidget {
  const MockDataHelper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () => _addMockData(context, ref),
      icon: const Icon(Icons.data_usage),
      label: const Text('Add Test Data'),
      backgroundColor: Theme.of(context).colorScheme.secondary,
      foregroundColor: Theme.of(context).colorScheme.onSecondary,
    );
  }

  Future<void> _addMockData(BuildContext context, WidgetRef ref) async {
    try {
      final repository = ref.read(activityRepositoryProvider);
      final mockGenerator = ref.read(mockDataGeneratorProvider);
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Adding test data...'),
            ],
          ),
        ),
      );

      await mockGenerator.addMockDataToRepository(repository);
      
      // Refresh all chart data
      ref.invalidate(dailyBarChartDataProvider);
      ref.invalidate(weeklyPieChartDataProvider);
      ref.invalidate(trendLineChartDataProvider);
      ref.invalidate(todayStatsProvider);
      ref.invalidate(weeklyStatsProvider);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test data added successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add test data: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}