import 'dart:math' as math;
import '../models/environment.dart';
import '../models/simulation_state.dart';

class SineWaveEnvironment implements CerebellarEnvironment {
  double _currentTime = 0.0;
  final double _frequency = 1.0;
  final double _amplitude = 1.0;

  @override
  String get taskName => 'Sine Wave Tracking';

  @override
  double get traceDecayMs => 100.0;

  @override
  EnvironmentStep step(SimulationState state, double dt) {
    _currentTime += dt;

    final double target = _amplitude * math.sin(2 * math.pi * _frequency * _currentTime);
    final bool isWaveMovingUp = math.cos(2 * math.pi * _frequency * _currentTime) > 0;

    // Determine DCN output direction
    final dcnOpen = state.neurons.firstWhere((n) => n.id == 'dcn_open', orElse: () => state.neurons.first);
    final dcnClose = state.neurons.firstWhere((n) => n.id == 'dcn_close', orElse: () => state.neurons.first);
    
    final bool outputMovingUp = dcnOpen.membranePotential > dcnClose.membranePotential;
    
    double punishment = 0.0;
    // Punishment if moving in wrong direction and there's significant DCN activity
    if (outputMovingUp != isWaveMovingUp && (dcnOpen.membranePotential + dcnClose.membranePotential) > 0.1) {
      punishment = 0.5;
    }

    bool isEpisodeEnd = _currentTime >= 1.0; // 1 second episodes
    
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
