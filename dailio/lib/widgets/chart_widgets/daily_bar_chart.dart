import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/chart_data_providers.dart';

class DailyBarChart extends ConsumerWidget {
  const DailyBarChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartDataAsync = ref.watch(dailyBarChartDataProvider);

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

  Widget _buildChart(BuildContext context, List<DailyBarData> chartData) {
    if (chartData.isEmpty) {
      return _buildEmptyState(context);
    }

    final maxHours = chartData
        .map((data) => data.totalHours)
        .reduce((a, b) => a > b ? a : b)
        .clamp(1.0, double.infinity);

    return Column(
      children: [
        // Legend
        _buildLegend(context),
        const SizedBox(height: 20),
        
        // Chart
        Expanded(
          child: BarChart(
            BarChartData(
              maxY: maxHours * 1.1, // Add 10% padding
              barGroups: _buildBarGroups(chartData),
              titlesData: _buildTitlesData(context, chartData),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxHours / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  strokeWidth: 1,
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final data = chartData[groupIndex];
                    final isUseful = rodIndex == 0;
                    final hours = isUseful ? data.usefulHours : data.wastedHours;
                    final category = isUseful ? 'Useful' : 'Wasted';
                    
                    return BarTooltipItem(
                      '$category\n${_formatHours(hours)}',
                      TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          context: context,
          color: Colors.green,
          label: 'Useful Time',
        ),
        const SizedBox(width: 24),
        _buildLegendItem(
          context: context,
          color: Colors.red,
          label: 'Wasted Time',
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required BuildContext context,
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
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
            Icons.bar_chart_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No activity data available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking activities to see your daily progress',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(List<DailyBarData> chartData) {
    return chartData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          // Useful time bar
          BarChartRodData(
            toY: data.usefulHours,
            color: Colors.green,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          // Wasted time bar
          BarChartRodData(
            toY: data.wastedHours,
            color: Colors.red,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
        barsSpace: 4,
      );
    }).toList();
  }

  FlTitlesData _buildTitlesData(BuildContext context, List<DailyBarData> chartData) {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= chartData.length) {
              return const SizedBox.shrink();
            }
            
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                chartData[index].formattedDate,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
          reservedSize: 32,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 50,
          getTitlesWidget: (value, meta) {
            if (value == 0) return const SizedBox.shrink();
            
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                '${value.toInt()}h',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );
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
}
