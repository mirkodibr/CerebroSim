import 'package:meta/meta.dart';

/// Configuration parameters for the Vestibulo-Ocular Reflex (VOR) task.
///
/// Defines the physical properties of the head movement being simulated
/// and the desired target performance (gain).
@immutable
class VorConfig {
  /// The desired ratio between eye velocity and head velocity (usually 1.0).
  final double targetGain;
  /// The maximum velocity of the simulated head movement in degrees per second.
  final double amplitude;
  /// The frequency of the sinusoidal head oscillation in Hertz.
  final double frequency;

  const VorConfig({
    this.targetGain = 1.0,
    this.amplitude = 40.0,
    this.frequency = 1.0,
  });

  /// Returns a copy of the configuration with updated fields.
  VorConfig copyWith({
    double? targetGain,
    double? amplitude,
    double? frequency,
  }) {
    return VorConfig(
      targetGain: targetGain ?? this.targetGain,
      amplitude: amplitude ?? this.amplitude,
      frequency: frequency ?? this.frequency,
    );
  }
}
