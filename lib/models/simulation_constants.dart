/// A collection of global constants used throughout the cerebellar simulation.
///
/// These values define default hyperparameters, physics engine parameters,
/// and biological benchmarks for different simulation tasks.
class SimulationConstants {
  /// Default rate at which synaptic weights are updated during learning.
  static const double kDefaultLearningRate = 0.01;
  /// Default rate at which neuron membrane potentials decay back to rest.
  static const double kDefaultDecayRate = 0.1;
  /// Default voltage threshold for neuron firing.
  static const double kDefaultThreshold = 1.0;
  /// The frequency (in Hertz) at which the simulation logic is updated.
  static const int kTickRateHz = 60;
  /// Default maximum head velocity for VOR tasks in degrees per second.
  static const double kDefaultHeadVelAmplitude = 40.0;
  /// Default oscillation frequency for VOR head movements.
  static const double kDefaultVorFrequencyHz = 1.0;
  /// Benchmark gain ratio for a healthy, fully adapted VOR system.
  static const double kHealthyVorGain = 1.0;
  /// Benchmark gain ratio representing an uncompensated or ataxic VOR system.
  static const double kAtaxiaVorGain = 0.4;
}
