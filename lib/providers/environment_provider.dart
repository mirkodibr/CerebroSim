import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cerebellar_task.dart';
import '../models/environment.dart';
import '../models/simulation_state.dart';
import '../models/vor_config.dart';
import '../services/eyeblink_environment.dart';
import '../services/sine_wave_environment.dart';
import '../services/vor_environment.dart';
import 'simulation_provider.dart';

class VorConfigNotifier extends Notifier<VorConfig> {
  @override
  VorConfig build() => const VorConfig();

  void update(VorConfig c) => state = c;
}

final vorConfigProvider = NotifierProvider<VorConfigNotifier, VorConfig>(() {
  return VorConfigNotifier();
});

class EnvironmentNotifier extends Notifier<CerebellarTask> {
  late CerebellarEnvironment _activeEnv;

  @override
  CerebellarTask build() {
    state = CerebellarTask.eyeblink;
    _activeEnv = _buildEnv(CerebellarTask.eyeblink);
    return state;
  }

  void selectTask(CerebellarTask task) {
    if (state == task) return;
    state = task;
    _activeEnv = _buildEnv(task);
    _activeEnv.reset();
    ref.read(simulationProvider.notifier).resetEpisode();
  }

  EnvironmentStep step(SimulationState s) {
    // Tick is 1/60s
    return _activeEnv.step(s, 0.016);
  }

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

  CerebellarEnvironment get activeEnv => _activeEnv;
}

final environmentProvider = NotifierProvider<EnvironmentNotifier, CerebellarTask>(() {
  return EnvironmentNotifier();
});
