import 'package:meta/meta.dart';

/// Configuration parameters for the Sine Wave Tracking task.
@immutable
class SineConfig {
  /// Frequency of the sinusoidal target signal in Hertz.
  final double frequencyHz;
  /// Maximum amplitude of the target signal.
  final double amplitude;

  const SineConfig({
    this.frequencyHz = 1.0,
    this.amplitude = 1.0,
  });

  /// Returns a copy of the configuration with updated fields.
  SineConfig copyWith({
    double? frequencyHz,
    double? amplitude,
  }) {
    return SineConfig(
      frequencyHz: frequencyHz ?? this.frequencyHz,
      amplitude: amplitude ?? this.amplitude,
    );
  }
}
