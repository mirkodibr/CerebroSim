import 'package:flutter_riverpod/flutter_riverpod.dart';

class EnvironmentState {
  final int episodeNumber;
  final double currentStep; // 0 to 1000 ms

  const EnvironmentState({
    this.episodeNumber = 0,
    this.currentStep = 0.0,
  });

  EnvironmentState copyWith({
    int? episodeNumber,
    double? currentStep,
  }) {
    return EnvironmentState(
      episodeNumber: episodeNumber ?? this.episodeNumber,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

class EnvironmentNotifier extends Notifier<EnvironmentState> {
  @override
  EnvironmentState build() => const EnvironmentState();

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

  /// Returns the state vector for Parallel Fibers (PF) based on current time.
  /// 
  /// In this model, different PF cells are active during different temporal windows.
  List<bool> getPFStateVector({int pfCount = 10}) {
    return List.generate(pfCount, (index) {
      final windowSize = 1000.0 / pfCount;
      final start = index * windowSize;
      final end = (index + 1) * windowSize;
      return state.currentStep >= start && state.currentStep < end;
    });
  }

  /// Returns the climbing fiber signal (reward/punishment).
  /// 
  /// Negative punishment (-1.0) is triggered at step 500 if the incorrect action is selected.
  double getClimbingFiberSignal(String lastAction) {
    // Reward/Punishment window around 500ms
    if (state.currentStep >= 480 && state.currentStep <= 520) {
      // Goal: Action 'anticlose' should be triggered at 500ms
      if (lastAction != 'anticlose') {
        return -1.0;
      }
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
  final double input; // Used for predictedPunishment
  final double output; // Used for actualPunishment
  HistoryPoint(this.input, this.output);
}

class SignalHistoryNotifier extends Notifier<List<HistoryPoint>> {
  @override
  List<HistoryPoint> build() => [];

  void addPoint(double predictedPunishment, double actualPunishment) {
    final nextHistory = List<HistoryPoint>.from(state)
      ..add(HistoryPoint(predictedPunishment, actualPunishment));
    
    // Maintain a fixed window of 200 points
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
