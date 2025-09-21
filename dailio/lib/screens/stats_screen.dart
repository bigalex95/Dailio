import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/chart_widgets/daily_bar_chart.dart';
import '../widgets/chart_widgets/weekly_pie_chart.dart';
import '../widgets/chart_widgets/trend_line_chart.dart';
import '../widgets/mock_data_helper.dart';
import '../providers/chart_data_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: () => _refreshData(ref),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      floatingActionButton: const MockDataHelper(),
      body: RefreshIndicator(
        onRefresh: () => _refreshData(ref),
        child: CustomScrollView(
          slivers: [
            // Header with summary stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildSummaryCards(context, ref),
              ),
            ),

            // Daily Bar Chart Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildChartSection(
                  context: context,
                  title: 'Daily Activity (Last 7 Days)',
                  subtitle: 'Hours of useful vs wasted time per day',
                  icon: Icons.bar_chart,
                  child: const DailyBarChart(),
                ),
              ),
            ),

            // Weekly Pie Chart Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildChartSection(
                  context: context,
                  title: 'This Week Overview',
                  subtitle: 'Percentage breakdown of time usage',
                  icon: Icons.pie_chart,
                  child: const WeeklyPieChart(),
                ),
              ),
            ),

            // Trend Line Chart Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildChartSection(
                  context: context,
                  title: 'Wasted Time Trend',
                  subtitle: 'Daily wasted hours over the last 2 weeks',
                  icon: Icons.trending_down,
                  child: const TrendLineChart(),
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, WidgetRef ref) {
    final weeklyStats = ref.watch(weeklyStatsProvider);
    final todayStats = ref.watch(todayStatsProvider);

    return Column(
      children: [
        Text(
          'Your Productivity Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context: context,
                title: 'Today',
                data: todayStats,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                context: context,
                title: 'This Week',
                data: weeklyStats,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required String title,
    required AsyncValue<DaySummary> data,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  title == 'Today' ? Icons.today : Icons.calendar_view_week,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            data.when(
              data: (summary) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatRow(
                    context,
                    'Useful',
                    summary.formattedUsefulTime,
                    Colors.green,
                  ),
                  const SizedBox(height: 4),
                  _buildStatRow(
                    context,
                    'Wasted',
                    summary.formattedWastedTime,
                    Colors.red,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: summary.productivityRatio >= 0.6
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(summary.productivityRatio * 100).round()}% Productive',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: summary.productivityRatio >= 0.6
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
              loading: () => const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (error, _) => Text(
                'Error loading data',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData(WidgetRef ref) async {
    // Invalidate all chart data providers to trigger refresh
    ref.invalidate(dailyBarChartDataProvider);
    ref.invalidate(weeklyPieChartDataProvider);
    ref.invalidate(trendLineChartDataProvider);
    ref.invalidate(weeklyStatsProvider);
    ref.invalidate(todayStatsProvider);
    
    // Wait a bit for the UI to update
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
