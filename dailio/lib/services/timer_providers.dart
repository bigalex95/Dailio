import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Timer states
enum TimerState { idle, running, stopped }

// Timer data model
class TimerData {
  final TimerState state;
  final int elapsedSeconds;
  final DateTime? startTime;

  const TimerData({
    required this.state,
    required this.elapsedSeconds,
    this.startTime,
  });

  TimerData copyWith({
    TimerState? state,
    int? elapsedSeconds,
    DateTime? startTime,
  }) {
    return TimerData(
      state: state ?? this.state,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      startTime: startTime ?? this.startTime,
    );
  }

  // Helper method to format elapsed time as HH:MM:SS
  String get formattedTime {
    final hours = elapsedSeconds ~/ 3600;
    final minutes = (elapsedSeconds % 3600) ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }
}

// Timer state notifier
class TimerNotifier extends StateNotifier<TimerData> {
  TimerNotifier() : super(const TimerData(state: TimerState.idle, elapsedSeconds: 0));

  Timer? _timer;

  void startTimer() {
    if (state.state == TimerState.running) return;

    state = TimerData(
      state: TimerState.running,
      elapsedSeconds: 0,
      startTime: DateTime.now(),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(
        elapsedSeconds: state.elapsedSeconds + 1,
      );
    });
  }

  void stopTimer() {
    if (state.state != TimerState.running) return;

    _timer?.cancel();
    _timer = null;

    state = state.copyWith(state: TimerState.stopped);
  }

  void resetTimer() {
    _timer?.cancel();
    _timer = null;

    state = const TimerData(
      state: TimerState.idle,
      elapsedSeconds: 0,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// Providers
final timerProvider = StateNotifierProvider<TimerNotifier, TimerData>((ref) {
  return TimerNotifier();
});

// Helper providers for easier access
final timerStateProvider = Provider<TimerState>((ref) {
  return ref.watch(timerProvider).state;
});

final elapsedTimeProvider = Provider<String>((ref) {
  return ref.watch(timerProvider).formattedTime;
});

final isTimerRunningProvider = Provider<bool>((ref) {
  return ref.watch(timerProvider).state == TimerState.running;
});

final canStartTimerProvider = Provider<bool>((ref) {
  return ref.watch(timerProvider).state == TimerState.idle;
});

final canStopTimerProvider = Provider<bool>((ref) {
  return ref.watch(timerProvider).state == TimerState.running;
});