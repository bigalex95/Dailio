import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/chart_data_providers.dart';

class WeeklyPieChart extends ConsumerWidget {
  const WeeklyPieChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartDataAsync = ref.watch(weeklyPieChartDataProvider);

    return chartDataAsync.when(
      data: (chartData) => _buildChart(context, chartData),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load chart data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, WeeklyPieData chartData) {
    if (chartData.totalHours == 0) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        // Summary stats
        _buildSummaryStats(context, chartData),
        const SizedBox(height: 20),
        
        // Pie chart
        Expanded(
          child: Row(
            children: [
              // Chart
              Expanded(
                flex: 3,
                child: PieChart(
                  PieChartData(
                    sections: _buildPieSections(chartData),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    startDegreeOffset: -90,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        // Handle touch events if needed
                      },
                    ),
                  ),
                ),
              ),
              
              // Legend
              Expanded(
                flex: 2,
                child: _buildLegend(context, chartData),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStats(BuildContext context, WeeklyPieData chartData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context: context,
            label: 'Total Hours',
            value: _formatHours(chartData.totalHours),
            color: Theme.of(context).colorScheme.primary,
          ),
          _buildStatItem(
            context: context,
            label: 'Productivity',
            value: '${chartData.usefulPercentage.round()}%',
            color: chartData.usefulPercentage >= 60 ? Colors.green : Colors.orange,
          ),
          _buildStatItem(
            context: context,
            label: 'Efficiency',
            value: _getEfficiencyRating(chartData.usefulPercentage),
            color: _getEfficiencyColor(chartData.usefulPercentage),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context, WeeklyPieData chartData) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (chartData.usefulHours > 0)
          _buildLegendItem(
            context: context,
            color: Colors.green,
            label: 'Useful',
            value: _formatHours(chartData.usefulHours),
            percentage: chartData.usefulPercentage,
          ),
        const SizedBox(height: 12),
        if (chartData.wastedHours > 0)
          _buildLegendItem(
            context: context,
            color: Colors.red,
            label: 'Wasted',
            value: _formatHours(chartData.wastedHours),
            percentage: chartData.wastedPercentage,
          ),
        if (chartData.neutralHours > 0) ...[
          const SizedBox(height: 12),
          _buildLegendItem(
            context: context,
            color: Colors.grey,
            label: 'Other',
            value: _formatHours(chartData.neutralHours),
            percentage: chartData.neutralPercentage,
          ),
        ],
      ],
    );
  }

  Widget _buildLegendItem({
    required BuildContext context,
    required Color color,
    required String label,
    required String value,
    required double percentage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${percentage.round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No weekly data available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track activities this week to see your breakdown',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(WeeklyPieData chartData) {
    final List<PieChartSectionData> sections = [];

    if (chartData.usefulHours > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.green,
          value: chartData.usefulHours,
          title: '${chartData.usefulPercentage.round()}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (chartData.wastedHours > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.red,
          value: chartData.wastedHours,
          title: '${chartData.wastedPercentage.round()}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (chartData.neutralHours > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.grey,
          value: chartData.neutralHours,
          title: '${chartData.neutralPercentage.round()}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return sections;
  }

  String _formatHours(double hours) {
    if (hours < 1) {
      return '${(hours * 60).round()}m';
    } else {
      final h = hours.floor();
      final m = ((hours - h) * 60).round();
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
  }

  String _getEfficiencyRating(double percentage) {
    if (percentage >= 80) return 'Excellent';
    if (percentage >= 60) return 'Good';
    if (percentage >= 40) return 'Fair';
    return 'Poor';
  }

  Color _getEfficiencyColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.lightGreen;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }
}