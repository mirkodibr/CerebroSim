import 'package:meta/meta.dart';

@immutable
class VorConfig {
  final double targetGain;
  final double amplitude;
  final double frequency;

  const VorConfig({
    this.targetGain = 1.0,
    this.amplitude = 40.0,
    this.frequency = 1.0,
  });

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
