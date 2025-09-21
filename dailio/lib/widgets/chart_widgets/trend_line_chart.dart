import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/chart_data_providers.dart';

class TrendLineChart extends ConsumerWidget {
  const TrendLineChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartDataAsync = ref.watch(trendLineChartDataProvider);

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

  Widget _buildChart(BuildContext context, List<TrendLineData> chartData) {
    if (chartData.isEmpty) {
      return _buildEmptyState(context);
    }

    final maxHours = chartData
        .map((data) => data.wastedHours)
        .reduce((a, b) => a > b ? a : b)
        .clamp(1.0, double.infinity);

    final averageWasted = chartData
        .map((data) => data.wastedHours)
        .reduce((a, b) => a + b) / chartData.length;

    return Column(
      children: [
        // Trend insights
        _buildTrendInsights(context, chartData, averageWasted),
        const SizedBox(height: 20),
        
        // Chart
        Expanded(
          child: LineChart(
            LineChartData(
              maxY: maxHours * 1.2, // Add 20% padding
              minY: 0,
              lineBarsData: [
                _buildMainLine(chartData),
                _buildAverageLine(chartData, averageWasted),
              ],
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
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final data = chartData[spot.x.toInt()];
                      final isMainLine = spot.barIndex == 0;
                      
                      if (isMainLine) {
                        return LineTooltipItem(
                          '${_formatDate(data.date)}\n${_formatHours(data.wastedHours)} wasted',
                          TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      } else {
                        return LineTooltipItem(
                          'Average: ${_formatHours(averageWasted)}',
                          TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        
        // Legend
        const SizedBox(height: 16),
        _buildLegend(context),
      ],
    );
  }

  Widget _buildTrendInsights(
    BuildContext context,
    List<TrendLineData> chartData,
    double averageWasted,
  ) {
    final recentDays = chartData.length >= 7 ? chartData.sublist(chartData.length - 7) : chartData;
    final olderDays = chartData.length >= 14 ? chartData.sublist(0, 7) : [];
    
    double recentAverage = recentDays.isEmpty ? 0 : 
        recentDays.map((d) => d.wastedHours).reduce((a, b) => a + b) / recentDays.length;
    double olderAverage = olderDays.isEmpty ? recentAverage :
        olderDays.map((d) => d.wastedHours).reduce((a, b) => a + b) / olderDays.length;
    
    final isImproving = recentAverage < olderAverage;
    final changePercent = olderAverage > 0 ? 
        ((recentAverage - olderAverage) / olderAverage * 100).abs() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isImproving 
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isImproving ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isImproving ? Icons.trending_down : Icons.trending_up,
            color: isImproving ? Colors.green : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isImproving ? 'Improving Trend!' : 'Watch Out!',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isImproving ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isImproving
                      ? 'Wasted time reduced by ${changePercent.round()}% this week'
                      : 'Wasted time increased by ${changePercent.round()}% this week',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatHours(averageWasted),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isImproving ? Colors.green[700] : Colors.orange[700],
                ),
              ),
              Text(
                'avg/day',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          context: context,
          color: Colors.red,
          label: 'Daily Wasted Time',
          isLine: true,
        ),
        const SizedBox(width: 24),
        _buildLegendItem(
          context: context,
          color: Colors.orange,
          label: 'Average',
          isLine: true,
          isDashed: true,
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required BuildContext context,
    required Color color,
    required String label,
    required bool isLine,
    bool isDashed = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
          child: isDashed
              ? CustomPaint(
                  painter: DashedLinePainter(color: color),
                )
              : null,
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
            Icons.show_chart,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No trend data available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track activities for 2+ weeks to see trends',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildMainLine(List<TrendLineData> chartData) {
    return LineChartBarData(
      spots: chartData.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value.wastedHours);
      }).toList(),
      isCurved: true,
      curveSmoothness: 0.35,
      color: Colors.red,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: Colors.red,
            strokeWidth: 2,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            Colors.red.withValues(alpha: 0.3),
            Colors.red.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  LineChartBarData _buildAverageLine(List<TrendLineData> chartData, double average) {
    return LineChartBarData(
      spots: chartData.asMap().entries.map((entry) {
        return FlSpot(entry.key.toDouble(), average);
      }).toList(),
      isCurved: false,
      color: Colors.orange,
      barWidth: 2,
      isStrokeCapRound: true,
      dashArray: [8, 4],
      dotData: const FlDotData(show: false),
    );
  }

  FlTitlesData _buildTitlesData(BuildContext context, List<TrendLineData> chartData) {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          interval: 2,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= chartData.length) {
              return const SizedBox.shrink();
            }
            
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _formatDateShort(chartData[index].date),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  String _formatDateShort(DateTime date) {
    return '${date.day}';
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    const dashWidth = 3.0;
    const dashSpace = 2.0;
    double currentX = 0;

    while (currentX < size.width) {
      canvas.drawLine(
        Offset(currentX, size.height / 2),
        Offset((currentX + dashWidth).clamp(0, size.width), size.height / 2),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}