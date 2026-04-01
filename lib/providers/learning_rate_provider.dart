import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simulation_constants.dart';

/// A notifier that manages the learning rate for the cerebellar simulation.
/// The learning rate determines the strength of synaptic weight updates
/// during plasticity (e.g., LTD at Parallel Fiber to Purkinje Cell synapses).
class LearningRateNotifier extends Notifier<double> {
  /// Initializes the learning rate with the default value from [SimulationConstants].
  @override
  double build() => SimulationConstants.kDefaultLearningRate;

  /// Sets a new value for the learning rate, triggering updates in the simulation.
  set value(double v) => state = v;
}

/// A global provider for the [LearningRateNotifier].
final learningRateProvider = NotifierProvider<LearningRateNotifier, double>(() {
  return LearningRateNotifier();
});
