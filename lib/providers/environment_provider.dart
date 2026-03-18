import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SignalTask { delayEyeblink, sineWave, stepFunction }

class EnvironmentState {
  final int episodeNumber;
  final double currentStep; // 0 to 1000 ms
  final SignalTask activeTask;

  const EnvironmentState({
    this.episodeNumber = 0,
    this.currentStep = 0.0,
    this.activeTask = SignalTask.delayEyeblink,
  });

  EnvironmentState copyWith({
    int? episodeNumber,
    double? currentStep,
    SignalTask? activeTask,
  }) {
    return EnvironmentState(
      episodeNumber: episodeNumber ?? this.episodeNumber,
      currentStep: currentStep ?? this.currentStep,
      activeTask: activeTask ?? this.activeTask,
    );
  }
}

class EnvironmentNotifier extends Notifier<EnvironmentState> {
  @override
  EnvironmentState build() => const EnvironmentState();

  void setTask(SignalTask task) {
    state = state.copyWith(activeTask: task, currentStep: 0.0, episodeNumber: 0);
  }

  /// Updates the environment step based on elapsed time (ms)
  void update(double deltaTimeMs) {
    double nextStep = state.currentStep + deltaTimeMs;
    
    if (nextStep >= 1000.0) {
      state = state.copyWith(
        episodeNumber: state.episodeNumber + 1,
        currentStep: 0.0,
      );
    } else {
      state = state.copyWith(currentStep: nextStep);
    }
  }

  /// Returns the state vector for Parallel Fibers (PF) based on current task and time.
  List<bool> getPFStateVector({int pfCount = 10}) {
    return List.generate(pfCount, (index) {
      switch (state.activeTask) {
        case SignalTask.delayEyeblink:
          // Eyeblink: Different temporal windows per PF
          final windowSize = 1000.0 / pfCount;
          final start = index * windowSize;
          final end = (index + 1) * windowSize;
          return state.currentStep >= start && state.currentStep < end;
        
        case SignalTask.sineWave:
          // Sine: A sweeping active index that oscillates
          // Simple sweep for sine-like representation
          final sweepIndex = ((state.currentStep / 1000.0) * pfCount).floor();
          return index == sweepIndex % pfCount;

        case SignalTask.stepFunction:
          // Step: First half PFs active in first 500ms, second half in second 500ms
          if (state.currentStep < 500) {
            return index < pfCount / 2;
          } else {
            return index >= pfCount / 2;
          }
      }
    });
  }

  /// Returns the climbing fiber signal (punishment) based on task rules.
  double getClimbingFiberSignal(String lastAction) {
    switch (state.activeTask) {
      case SignalTask.delayEyeblink:
        // Punishment if 'anticlose' (blink) is NOT active at 500ms
        if (state.currentStep >= 480 && state.currentStep <= 520) {
          return (lastAction != 'anticlose') ? -1.0 : 0.0;
        }
        break;
      
      case SignalTask.sineWave:
        // Biologically, tracking involves moving in the direction of the stimulus.
        // Slope calculation: derivative of sin(x) is cos(x)
        final bool isWaveMovingUp = math.cos((state.currentStep / 1000.0) * 2.0 * math.pi) > 0;
        final String requiredAction = isWaveMovingUp ? 'antiopen' : 'anticlose';
        
        // Return -0.5 ONLY if lastAction is not requiredAction AND lastAction != 'none'
        if (lastAction != 'none' && lastAction != requiredAction) {
          return -0.5;
        }
        break;

      case SignalTask.stepFunction:
        // Punishment if 'antiopen' is NOT active at 250ms OR 750ms
        final isTriggerTime = (state.currentStep >= 230 && state.currentStep <= 270) || 
                             (state.currentStep >= 730 && state.currentStep <= 770);
        if (isTriggerTime) {
          return (lastAction != 'antiopen') ? -1.0 : 0.0;
        }
        break;
    }
    return 0.0;
  }

  void reset() {
    state = const EnvironmentState();
  }
}

final environmentProvider = NotifierProvider<EnvironmentNotifier, EnvironmentState>(() {
  return EnvironmentNotifier();
});

/// Data point for visualization (Predicted vs Actual Punishment)
class HistoryPoint {
  final double input; // Predicted
  final double output; // Actual
  HistoryPoint(this.input, this.output);
}

class SignalHistoryNotifier extends Notifier<List<HistoryPoint>> {
  @override
  List<HistoryPoint> build() => [];

  void addPoint(double predictedPunishment, double actualPunishment) {
    final nextHistory = List<HistoryPoint>.from(state)
      ..add(HistoryPoint(predictedPunishment, actualPunishment));
    if (nextHistory.length > 200) {
      nextHistory.removeAt(0);
    }
    state = nextHistory;
  }

  void reset() {
    state = [];
  }
}

final signalHistoryProvider = NotifierProvider<SignalHistoryNotifier, List<HistoryPoint>>(() {
  return SignalHistoryNotifier();
});
