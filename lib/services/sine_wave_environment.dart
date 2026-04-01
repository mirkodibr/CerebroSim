import 'dart:math' as math;
import '../models/environment.dart';
import '../models/simulation_state.dart';

/// An environment for tracking a continuous sine wave signal.
/// 
/// This task requires the cerebellar network to learn the timing and 
/// direction of a rhythmic signal. The network receives the target 
/// value and direction as input and is punished for incorrect DCN output.
class SineWaveEnvironment implements CerebellarEnvironment {
  double _currentTime = 0.0;
  final double _frequency = 1.0;
  final double _amplitude = 1.0;

  @override
  String get taskName => 'Sine Wave Tracking';

  /// Decay rate for eligibility trace (100ms).
  /// 
  /// A shorter trace is used here because the target signal changes 
  /// continuously, requiring faster adaptation to the current phase.
  @override
  double get traceDecayMs => 100.0;

  /// Updates the sine wave state and evaluates the network's performance.
  /// 
  /// - **Target:** The current value of the sine wave.
  /// - **Direction:** Whether the wave is currently moving up or down.
  /// - **DCN Logic:** Compares the potential of `dcn_open` and `dcn_close`.
  /// - **Punishment:** Occurs if the DCN output direction does not match 
  ///   the wave's movement direction.
  @override
  EnvironmentStep step(SimulationState state, double dt) {
    _currentTime += dt;

    final double target = _amplitude * math.sin(2 * math.pi * _frequency * _currentTime);
    final bool isWaveMovingUp = math.cos(2 * math.pi * _frequency * _currentTime) > 0;

    // Determine DCN output direction from the competitive DCN pair.
    final dcnOpen = state.neurons.firstWhere((n) => n.id == 'dcn_open', orElse: () => state.neurons.first);
    final dcnClose = state.neurons.firstWhere((n) => n.id == 'dcn_close', orElse: () => state.neurons.first);
    
    final bool outputMovingUp = dcnOpen.membranePotential > dcnClose.membranePotential;
    
    double punishment = 0.0;
    // Punishment if moving in wrong direction and there's significant DCN activity.
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

  /// Resets the internal timer for a new sine wave cycle.
  @override
  void reset() {
    _currentTime = 0.0;
  }
}
