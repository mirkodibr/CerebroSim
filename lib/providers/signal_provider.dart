import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SignalType { sine, step, square }

class SignalNotifier extends Notifier<bool> {
  SignalType _type = SignalType.sine;
  double _frequency = 1.0; // Hz
  double _currentTime = 0.0;

  @override
  bool build() {
    return false;
  }

  void setType(SignalType type) {
    _type = type;
  }

  void setFrequency(double freq) {
    _frequency = freq;
  }

  /// Updates the signal based on the elapsed time (ms)
  void update(double deltaTimeMs) {
    _currentTime += deltaTimeMs / 1000.0;
    
    switch (_type) {
      case SignalType.sine:
        // Convert sine wave (-1 to 1) to a binary spike
        // Spike when sine is in the upper 20% of its phase
        final value = math.sin(2 * math.pi * _frequency * _currentTime);
        state = value > 0.8;
        break;
      case SignalType.step:
        // Toggle every 1 second
        state = (_currentTime % 2.0) < 1.0;
        break;
      case SignalType.square:
        // Rapid oscillation
        state = math.sin(2 * math.pi * _frequency * _currentTime) > 0;
        break;
    }
  }

  void reset() {
    _currentTime = 0.0;
    state = false;
  }
}

final signalProvider = NotifierProvider<SignalNotifier, bool>(() {
  return SignalNotifier();
});

class HistoryPoint {
  final double input;
  final double output;
  HistoryPoint(this.input, this.output);
}

class SignalHistoryNotifier extends Notifier<List<HistoryPoint>> {
  @override
  List<HistoryPoint> build() => [];

  void addPoint(double input, double output) {
    final nextHistory = List<HistoryPoint>.from(state)..add(HistoryPoint(input, output));
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
