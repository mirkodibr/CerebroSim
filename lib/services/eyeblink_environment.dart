import '../models/environment.dart';
import '../models/simulation_state.dart';

/// Implements a classical Delay Eyeblink conditioning environment.
/// 
/// This environment simulates a repetitive trial where a Conditioned Stimulus (CS)
/// precedes an Unconditioned Stimulus (US). The goal of the cerebellar network
/// is to learn to produce a blink (a DCN spike) during the CS window to 
/// anticipate the US.
class EyeblinkEnvironment implements CerebellarEnvironment {
  double _currentTime = 0.0;
  final double _trialDuration = 1.0;
  bool _blinkProduced = false;

  @override
  String get taskName => 'Delay Eyeblink';

  /// Decay rate for the eligibility trace in milliseconds.
  /// 
  /// In this task, a medium-length trace (300ms) is used to bridge the 
  /// temporal gap between the CS onset and the US onset.
  @override
  double get traceDecayMs => 300.0;

  /// Advances the trial state by [dt].
  /// 
  /// The logic defines:
  /// - **CS Active:** A signal is active from 0ms to 250ms.
  /// - **US Active:** A punishment signal (US) fires from 250ms to 300ms.
  /// - **Blink Detection:** If any DCN neuron fires during the CS window,
  ///   the agent is considered to have produced a conditioned response.
  /// - **Punishment:** If the US fires and no blink was produced, 
  ///   the environment returns a punishment value of 1.0.
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

  /// Resets the trial timer and blink status for a new episode.
  @override
  void reset() {
    _currentTime = 0.0;
    _blinkProduced = false;
  }
}
