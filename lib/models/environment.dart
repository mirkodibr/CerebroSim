import 'package:meta/meta.dart';
import 'simulation_state.dart';

@immutable
class EnvironmentStep {
  final List<double> stateVector;
  final double punishment;
  final bool isEpisodeEnd;

  const EnvironmentStep({
    required this.stateVector,
    required this.punishment,
    required this.isEpisodeEnd,
  });
}

abstract class CerebellarEnvironment {
  String get taskName;
  double get traceDecayMs;
  EnvironmentStep step(SimulationState state, double dt);
  void reset();
}
