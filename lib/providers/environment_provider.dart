import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cerebellar_task.dart';
import '../models/environment.dart';
import '../models/simulation_state.dart';
import '../models/vor_config.dart';
import '../services/eyeblink_environment.dart';
import '../services/sine_wave_environment.dart';
import '../services/vor_environment.dart';
import 'simulation_provider.dart';

/// A notifier that manages the configuration for the Vestibulo-Ocular Reflex (VOR) task.
/// It allows updating the parameters that define the VOR simulation environment.
class VorConfigNotifier extends Notifier<VorConfig> {
  /// Initializes the VOR configuration with default values.
  @override
  VorConfig build() => const VorConfig();

  /// Updates the current VOR configuration.
  void update(VorConfig c) => state = c;
}

/// A global provider for the [VorConfigNotifier].
final vorConfigProvider = NotifierProvider<VorConfigNotifier, VorConfig>(() {
  return VorConfigNotifier();
});

/// A notifier that manages the active cerebellar task and its corresponding environment.
/// It handles task selection and provides a way to step through the environment simulation.
class EnvironmentNotifier extends Notifier<CerebellarTask> {
  late CerebellarEnvironment _activeEnv;

  /// Initializes the environment by setting the default task to eyeblink conditioning.
  @override
  CerebellarTask build() {
    state = CerebellarTask.eyeblink;
    _activeEnv = _buildEnv(CerebellarTask.eyeblink);
    return state;
  }

  /// Changes the active cerebellar task, resets the environment, and resets the simulation episode.
  void selectTask(CerebellarTask task) {
    if (state == task) return;
    state = task;
    _activeEnv = _buildEnv(task);
    _activeEnv.reset();
    ref.read(simulationProvider.notifier).resetEpisode();
  }

  /// Advances the active environment by one time step (typically 1/60s).
  /// It takes the current [SimulationState] and returns the resulting [EnvironmentStep].
  EnvironmentStep step(SimulationState s) {
    // Tick is 1/60s
    return _activeEnv.step(s, 0.016);
  }

  /// Factory method that creates a [CerebellarEnvironment] based on the provided [CerebellarTask].
  CerebellarEnvironment _buildEnv(CerebellarTask t) {
    switch (t) {
      case CerebellarTask.eyeblink:
        return EyeblinkEnvironment();
      case CerebellarTask.sineWave:
        return SineWaveEnvironment();
      case CerebellarTask.vor:
        return VorEnvironment(config: ref.read(vorConfigProvider));
    }
  }

  /// Returns the currently active [CerebellarEnvironment].
  CerebellarEnvironment get activeEnv => _activeEnv;
}

/// A global provider for the [EnvironmentNotifier], used to observe and switch tasks.
final environmentProvider = NotifierProvider<EnvironmentNotifier, CerebellarTask>(() {
  return EnvironmentNotifier();
});
