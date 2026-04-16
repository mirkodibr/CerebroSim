import 'dart:math' as math;
import '../models/environment.dart';
import '../models/simulation_state.dart';
import '../models/sine_config.dart';

/// An environment for tracking a continuous sine wave signal.
class SineWaveEnvironment implements CerebellarEnvironment {
  final SineConfig config;
  double _currentTime = 0.0;

  SineWaveEnvironment({this.config = const SineConfig()});

  @override
  String get taskName => 'Sine Wave Tracking';

  @override
  double get traceDecayMs => 100.0;

  @override
  EnvironmentStep step(SimulationState state, double dt) {
    _currentTime += dt;

    final double target = config.amplitude * math.sin(2 * math.pi * config.frequencyHz * _currentTime);
    final bool isWaveMovingUp = math.cos(2 * math.pi * config.frequencyHz * _currentTime) > 0;

    final dcnOpen = state.neurons['dcn_open'] ?? state.neurons.values.first;
    final dcnClose = state.neurons['dcn_close'] ?? state.neurons.values.first;
    
    final bool outputMovingUp = dcnOpen.membranePotential > dcnClose.membranePotential;
    
    double punishment = 0.0;
    if (outputMovingUp != isWaveMovingUp && (dcnOpen.membranePotential + dcnClose.membranePotential) > 0.1) {
      punishment = 0.5;
    }

    bool isEpisodeEnd = _currentTime >= 1.0; // Fixed 1.0s episodes for tracking tasks
    
    final step = EnvironmentStep(
      stateVector: [target, isWaveMovingUp ? 1.0 : -1.0],
      punishment: punishment,
      isEpisodeEnd: isEpisodeEnd,
    );

    if (isEpisodeEnd) {
      reset();
    }

    return step;
  }

  @override
  void reset() {
    _currentTime = 0.0;
  }
}
