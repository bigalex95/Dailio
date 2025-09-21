import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/timer_providers.dart';
import '../widgets/activity_save_dialog.dart';

class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerData = ref.watch(timerProvider);
    final isRunning = ref.watch(isTimerRunningProvider);
    final canStart = ref.watch(canStartTimerProvider);
    final canStop = ref.watch(canStopTimerProvider);
    final elapsedTime = ref.watch(elapsedTimeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Timer'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Timer Display Card
            Card(
              elevation: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      'Elapsed Time',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      elapsedTime,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isRunning 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(timerData.state, context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(timerData.state, context),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getStatusText(timerData.state),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: _getStatusColor(timerData.state, context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Start Button
                if (canStart) ...[
                  _buildActionButton(
                    context: context,
                    onPressed: () => ref.read(timerProvider.notifier).startTimer(),
                    icon: Icons.play_arrow,
                    label: 'Start',
                    isPrimary: true,
                  ),
                ],
                
                // Stop Button
                if (canStop) ...[
                  _buildActionButton(
                    context: context,
                    onPressed: () => _handleStopTimer(context, ref),
                    icon: Icons.stop,
                    label: 'Stop',
                    isPrimary: true,
                  ),
                ],
                
                // Reset Button (always available when not running)
                if (!isRunning) ...[
                  _buildActionButton(
                    context: context,
                    onPressed: timerData.elapsedSeconds > 0 
                      ? () => ref.read(timerProvider.notifier).resetTimer()
                      : null,
                    icon: Icons.refresh,
                    label: 'Reset',
                    isPrimary: false,
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Instructions
            if (timerData.state == TimerState.idle)
              Text(
                'Tap Start to begin tracking your activity',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            
            if (timerData.state == TimerState.running)
              Text(
                'Timer is running... Tap Stop when you\'re done',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    if (isPrimary) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: Theme.of(context).textTheme.titleMedium,
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }
  }

  Color _getStatusColor(TimerState state, BuildContext context) {
    switch (state) {
      case TimerState.idle:
        return Theme.of(context).colorScheme.onSurfaceVariant;
      case TimerState.running:
        return Theme.of(context).colorScheme.primary;
      case TimerState.stopped:
        return Theme.of(context).colorScheme.secondary;
    }
  }

  String _getStatusText(TimerState state) {
    switch (state) {
      case TimerState.idle:
        return 'Ready';
      case TimerState.running:
        return 'Running';
      case TimerState.stopped:
        return 'Stopped';
    }
  }

  Future<void> _handleStopTimer(BuildContext context, WidgetRef ref) async {
    final timerData = ref.read(timerProvider);
    
    // Stop the timer
    ref.read(timerProvider.notifier).stopTimer();
    
    // Show save dialog
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ActivitySaveDialog(
        durationSeconds: timerData.elapsedSeconds,
      ),
    );
    
    // Reset timer after dialog is closed
    if (result == true) {
      ref.read(timerProvider.notifier).resetTimer();
    }
  }
}