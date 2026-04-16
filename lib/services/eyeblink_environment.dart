import '../models/environment.dart';
import '../models/simulation_state.dart';
import '../models/eyeblink_config.dart';

/// Implements a classical Delay Eyeblink conditioning environment.
class EyeblinkEnvironment implements CerebellarEnvironment {
  final EyeblinkConfig config;
  double _currentTime = 0.0;
  bool _blinkProduced = false;

  EyeblinkEnvironment({this.config = const EyeblinkConfig()});

  @override
  String get taskName => 'Delay Eyeblink';

  @override
  double get traceDecayMs => 300.0;

  @override
  EnvironmentStep step(SimulationState state, double dt) {
    _currentTime += dt;

    final double csDurationS = config.csDurationMs / 1000.0;
    final double usDurationS = config.usDurationMs / 1000.0;
    
    final bool csActive = _currentTime >= 0.0 && _currentTime <= csDurationS;
    final bool usFires = _currentTime >= csDurationS && _currentTime <= (csDurationS + usDurationS);

    if (csActive) {
      final dcnFiring = state.neurons.values.any((n) => n.cellType == 'DCN' && n.isFiring);
      if (dcnFiring) {
        _blinkProduced = true;
      }
    }

    double punishment = 0.0;
    if (usFires && !_blinkProduced) {
      punishment = 1.0;
    }

    bool isEpisodeEnd = _currentTime >= config.trialDurationS;
    
    final step = EnvironmentStep(
      stateVector: [
        csActive ? 1.0 : 0.0,
        (_currentTime / config.trialDurationS).clamp(0.0, 1.0),
        _blinkProduced ? 1.0 : 0.0,
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
    _blinkProduced = false;
  }
}
