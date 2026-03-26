import 'dart:math' as math;
import '../models/environment.dart';
import '../models/simulation_state.dart';
import '../models/vor_config.dart';

class VorEnvironment implements CerebellarEnvironment {
  double _currentTime = 0.0;
  final VorConfig config;

  VorEnvironment({this.config = const VorConfig()});

  @override
  String get taskName => 'VOR Adaptation';

  @override
  double get traceDecayMs => 50.0;

  @override
  EnvironmentStep step(SimulationState state, double dt) {
    _currentTime += dt;

    final double headVel = config.amplitude * math.sin(2 * math.pi * config.frequency * _currentTime);
    // targetEyeVel is -headVel * config.targetGain but unused in the simple logic here.

    final dcnOpen = state.neurons.firstWhere((n) => n.id == 'dcn_open', orElse: () => state.neurons.first);
    final dcnClose = state.neurons.firstWhere((n) => n.id == 'dcn_close', orElse: () => state.neurons.first);
    
    final double actualEyeVel = (dcnOpen.membranePotential - dcnClose.membranePotential) * config.amplitude;
    
    final double imageSlip = headVel + actualEyeVel;
    final double punishment = (imageSlip.abs() / config.amplitude).clamp(0.0, 1.0);

    bool isEpisodeEnd = _currentTime >= 1.0 / config.frequency;
    
    final step = EnvironmentStep(
      stateVector: [
        headVel / config.amplitude,
        actualEyeVel / config.amplitude,
        actualEyeVel.abs() / headVel.abs().clamp(0.001, double.infinity),
        punishment,
      ],
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
