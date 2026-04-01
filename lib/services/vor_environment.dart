import 'dart:math' as math;
import '../models/environment.dart';
import '../models/simulation_state.dart';
import '../models/vor_config.dart';

/// Implements a Vestibulo-Ocular Reflex (VOR) adaptation task.
/// 
/// VOR is a classic cerebellar function where the eyes move in the opposite
/// direction of the head to stabilize an image on the retina.
/// The goal of the network is to minimize 'image slip' (the sum of head and 
/// eye velocity) by adjusting synaptic weights.
class VorEnvironment implements CerebellarEnvironment {
  double _currentTime = 0.0;
  final VorConfig config;

  /// Creates a VOR environment with the specified [config].
  VorEnvironment({this.config = const VorConfig()});

  @override
  String get taskName => 'VOR Adaptation';

  /// Decay rate for eligibility trace (50ms).
  /// 
  /// VOR requires very fast, precise temporal mapping because head 
  /// movements are rapid and the error signal (image slip) is immediate.
  @override
  double get traceDecayMs => 50.0;

  /// Advances the VOR simulation by [dt].
  /// 
  /// - **Head Velocity:** A sine wave based on [config.frequency] and [config.amplitude].
  /// - **Eye Velocity:** Calculated as the difference between `dcn_open` and 
  ///   `dcn_close` potentials, scaled by the movement amplitude.
  /// - **Image Slip:** The sum of head and eye velocity. In a perfect VOR, 
  ///   this should be zero.
  /// - **Punishment:** Proportional to the absolute image slip, normalized 
  ///   by the amplitude.
  @override
  EnvironmentStep step(SimulationState state, double dt) {
    _currentTime += dt;

    final double headVel = config.amplitude * math.sin(2 * math.pi * config.frequency * _currentTime);

    // Calculate eye velocity from the DCN output pair.
    final dcnOpen = state.neurons.firstWhere((n) => n.id == 'dcn_open', orElse: () => state.neurons.first);
    final dcnClose = state.neurons.firstWhere((n) => n.id == 'dcn_close', orElse: () => state.neurons.first);
    
    final double actualEyeVel = (dcnOpen.membranePotential - dcnClose.membranePotential) * config.amplitude;
    
    // The visual error signal (image slip).
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

  /// Resets the internal timer for a new head rotation cycle.
  @override
  void reset() {
    _currentTime = 0.0;
  }
}
