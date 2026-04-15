import 'dart:math' as math;
import '../models/environment.dart';
import '../models/simulation_state.dart';

/// A 2D arm reaching task.
/// 
/// The goal is to move an end-effector (arm) from its current position 
/// (armX, armY) to a target position (targetX, targetY).
/// The cerebellar network provides velocity control signals.
class ArmReachingEnvironment implements CerebellarEnvironment {
  @override
  String get taskName => 'armReaching';

  @override
  double get traceDecayMs => 150.0;

  double _armX = 0.0;
  double _armY = 0.0;
  double _targetX = 0.7;
  double _targetY = 0.5;
  
  final math.Random _random = math.Random();

  @override
  EnvironmentStep step(SimulationState state, double dt) {
    // 1. Determine velocity from DCN neurons
    // We expect 4 specific DCNs: x_pos, x_neg, y_pos, y_neg
    final dcnXPos = state.neurons['x_pos']?.membranePotential ?? 0.0;
    final dcnXNeg = state.neurons['x_neg']?.membranePotential ?? 0.0;
    final dcnYPos = state.neurons['y_pos']?.membranePotential ?? 0.0;
    final dcnYNeg = state.neurons['y_neg']?.membranePotential ?? 0.0;

    final dx = (dcnXPos - dcnXNeg) * dt * 5.0; // Scale for visible movement
    final dy = (dcnYPos - dcnYNeg) * dt * 5.0;

    // 2. Update position
    _armX = (_armX + dx).clamp(-1.0, 1.0);
    _armY = (_armY + dy).clamp(-1.0, 1.0);

    // 3. Calculate distance to target (punishment)
    final distance = math.sqrt(math.pow(_targetX - _armX, 2) + math.pow(_targetY - _armY, 2));
    
    // Normalize punishment (0.0 to 1.0, where 2.0 is max possible distance)
    final punishment = (distance / 2.0).clamp(0.0, 1.0);

    // 4. Check for episode end
    // Success condition: reached target within small threshold
    final bool reached = distance < 0.05;
    // Timeout condition: 5 seconds (assuming 60Hz, 300 steps)
    final bool timeout = state.episodeStep > 300;
    final isEpisodeEnd = reached || timeout;

    final step = EnvironmentStep(
      stateVector: [
        _armX, 
        _armY, 
        _targetX, 
        _targetY,
        reached ? 1.0 : 0.0,
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
    // Reset arm to origin
    _armX = 0.0;
    _armY = 0.0;
    // Randomize target position
    _targetX = (_random.nextDouble() * 1.6) - 0.8;
    _targetY = (_random.nextDouble() * 1.6) - 0.8;
  }
}
