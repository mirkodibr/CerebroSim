import '../models/environment.dart';
import '../models/simulation_state.dart';

class EyeblinkEnvironment implements CerebellarEnvironment {
  double _currentTime = 0.0;
  final double _trialDuration = 1.0;
  bool _blinkProduced = false;

  @override
  String get taskName => 'Delay Eyeblink';

  @override
  double get traceDecayMs => 300.0;

  @override
  EnvironmentStep step(SimulationState state, double dt) {
    _currentTime += dt;

    final bool csActive = _currentTime >= 0.0 && _currentTime <= 0.250;
    final bool usFires = _currentTime >= 0.250 && _currentTime <= 0.300;

    // Check for DCN spike during CS window
    if (csActive) {
      final dcnFiring = state.neurons.any((n) => n.cellType == 'DCN' && n.isFiring);
      if (dcnFiring) {
        _blinkProduced = true;
      }
    }

    double punishment = 0.0;
    if (usFires && !_blinkProduced) {
      punishment = 1.0;
    }

    bool isEpisodeEnd = _currentTime >= _trialDuration;
    
    final step = EnvironmentStep(
      stateVector: [
        csActive ? 1.0 : 0.0,
        (_currentTime / _trialDuration).clamp(0.0, 1.0),
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
