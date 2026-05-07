import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cerebellar_task.dart';
import '../models/environment.dart';
import '../models/simulation_state.dart';
import '../models/vor_config.dart';
import '../models/eyeblink_config.dart';
import '../models/sine_config.dart';
import '../models/network_config.dart';
import '../services/eyeblink_environment.dart';
import '../services/sine_wave_environment.dart';
import '../services/vor_environment.dart';
import '../services/arm_reaching_environment.dart';
import 'simulation_provider.dart';

/// A notifier that manages the configuration for the Vestibulo-Ocular Reflex (VOR) task.
class VorConfigNotifier extends Notifier<VorConfig> {
  @override
  VorConfig build() => const VorConfig();
  void update(VorConfig c) => state = c;
}

final vorConfigProvider = NotifierProvider<VorConfigNotifier, VorConfig>(() {
  return VorConfigNotifier();
});

/// A notifier that manages the configuration for the Eyeblink Conditioning task.
class EyeblinkConfigNotifier extends Notifier<EyeblinkConfig> {
  @override
  EyeblinkConfig build() => const EyeblinkConfig();
  void update(EyeblinkConfig c) => state = c;
}

final eyeblinkConfigProvider = NotifierProvider<EyeblinkConfigNotifier, EyeblinkConfig>(() {
  return EyeblinkConfigNotifier();
});

/// A notifier that manages the configuration for the Sine Wave Tracking task.
class SineConfigNotifier extends Notifier<SineConfig> {
  @override
  SineConfig build() => const SineConfig();
  void update(SineConfig c) => state = c;
}

final sineConfigProvider = NotifierProvider<SineConfigNotifier, SineConfig>(() {
  return SineConfigNotifier();
});

/// A notifier that manages the active cerebellar task and its corresponding environment.
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
    HapticFeedback.selectionClick();
    state = task;
    _activeEnv = _buildEnv(task);
    _activeEnv.reset();
    
    NetworkConfig? config;
    if (task == CerebellarTask.armReaching) {
      config = NetworkConfig.defaultConfig().copyWith(dcnCount: 4);
    }
    
    ref.read(simulationControllerProvider).resetEpisode(config: config);
  }

  EnvironmentStep step(SimulationState s) {
    return _activeEnv.step(s, 0.016);
  }

  CerebellarEnvironment _buildEnv(CerebellarTask t) {
    switch (t) {
      case CerebellarTask.eyeblink:
        return EyeblinkEnvironment(config: ref.read(eyeblinkConfigProvider));
      case CerebellarTask.sineWave:
        return SineWaveEnvironment(config: ref.read(sineConfigProvider));
      case CerebellarTask.vor:
        return VorEnvironment(config: ref.read(vorConfigProvider));
      case CerebellarTask.armReaching:
        return ArmReachingEnvironment();
    }
  }

  CerebellarEnvironment get activeEnv => _activeEnv;
}

final environmentProvider = NotifierProvider<EnvironmentNotifier, CerebellarTask>(() {
  return EnvironmentNotifier();
});
