import 'package:meta/meta.dart';

/// Configuration parameters for the Eyeblink Conditioning task.
@immutable
class EyeblinkConfig {
  /// Duration of the Conditioned Stimulus (CS) in milliseconds.
  final double csDurationMs;
  /// Duration of the Unconditioned Stimulus (US) in milliseconds.
  final double usDurationMs;
  /// Total duration of a single trial in seconds.
  final double trialDurationS;

  const EyeblinkConfig({
    this.csDurationMs = 250.0,
    this.usDurationMs = 50.0,
    this.trialDurationS = 1.0,
  });

  /// Returns a copy of the configuration with updated fields.
  EyeblinkConfig copyWith({
    double? csDurationMs,
    double? usDurationMs,
    double? trialDurationS,
  }) {
    return EyeblinkConfig(
      csDurationMs: csDurationMs ?? this.csDurationMs,
      usDurationMs: usDurationMs ?? this.usDurationMs,
      trialDurationS: trialDurationS ?? this.trialDurationS,
    );
  }
}
