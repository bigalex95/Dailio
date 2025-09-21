import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auto_tracker_provider.dart';

/// Widget that displays the current auto-tracking status and app name
class AutoTrackingStatusWidget extends ConsumerWidget {
  const AutoTrackingStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoTrackerState = ref.watch(autoTrackerProvider);

    if (!autoTrackerState.isEnabled) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: _getStatusColor(autoTrackerState, context),
          width: 2.0,
        ),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStatusColor(autoTrackerState, context),
            ),
          ),
          const SizedBox(width: 12),
          
          // Status text and app name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(autoTrackerState),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (autoTrackerState.currentAppName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    autoTrackerState.currentAppName!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (autoTrackerState.lastUpdateTime != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Updated ${_formatLastUpdate(autoTrackerState.lastUpdateTime!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Action button
          IconButton(
            onPressed: () => _handleActionPress(context, ref, autoTrackerState),
            icon: Icon(_getActionIcon(autoTrackerState)),
            tooltip: _getActionTooltip(autoTrackerState),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AutoTrackerState state, BuildContext context) {
    if (state.errorMessage != null) {
      return Colors.red;
    } else if (state.isTracking) {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }

  String _getStatusText(AutoTrackerState state) {
    if (state.errorMessage != null) {
      return 'Auto-tracking error';
    } else if (state.isTracking) {
      return 'Auto-tracking active';
    } else {
      return 'Auto-tracking paused';
    }
  }

  IconData _getActionIcon(AutoTrackerState state) {
    if (state.errorMessage != null) {
      return Icons.refresh;
    } else if (state.isTracking) {
      return Icons.pause;
    } else {
      return Icons.play_arrow;
    }
  }

  String _getActionTooltip(AutoTrackerState state) {
    if (state.errorMessage != null) {
      return 'Retry tracking';
    } else if (state.isTracking) {
      return 'Pause tracking';
    } else {
      return 'Resume tracking';
    }
  }

  void _handleActionPress(BuildContext context, WidgetRef ref, AutoTrackerState state) {
    final notifier = ref.read(autoTrackerProvider.notifier);
    
    if (state.errorMessage != null || !state.isTracking) {
      notifier.startTracking();
    } else {
      notifier.stopTracking();
    }
  }

  String _formatLastUpdate(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}

/// Compact version for app bars or smaller spaces
class CompactAutoTrackingStatus extends ConsumerWidget {
  const CompactAutoTrackingStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoTrackerState = ref.watch(autoTrackerProvider);

    if (!autoTrackerState.isEnabled) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: _getStatusColor(autoTrackerState, context).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: _getStatusColor(autoTrackerState, context),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getStatusColor(autoTrackerState, context),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            autoTrackerState.currentAppName ?? 'Auto-tracking',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AutoTrackerState state, BuildContext context) {
    if (state.errorMessage != null) {
      return Colors.red;
    } else if (state.isTracking) {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }
}

/// Error display widget for auto-tracking issues
class AutoTrackingErrorWidget extends ConsumerWidget {
  const AutoTrackingErrorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoTrackerState = ref.watch(autoTrackerProvider);

    if (autoTrackerState.errorMessage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.red),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                'Auto-tracking Error',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            autoTrackerState.errorMessage!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => ref.read(autoTrackerProvider.notifier).disableTracking(),
                child: const Text('Disable'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => ref.read(autoTrackerProvider.notifier).startTracking(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}