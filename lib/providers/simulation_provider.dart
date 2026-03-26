import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simulation_state.dart';
import '../models/simulation_constants.dart';
import '../services/simulation_engine.dart';
import 'environment_provider.dart';

final simulationEngineProvider = Provider<SimulationEngine>((ref) {
  return SimulationEngine();
});

class SimulationNotifier extends Notifier<SimulationState> {
  Timer? _timer;
  final SimulationEngine _engine = SimulationEngine();

  @override
  SimulationState build() {
    ref.onDispose(() => _timer?.cancel());
    return _engine.initialState();
  }

  void startSimulation() {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true);
    
    final interval = Duration(milliseconds: (1000 / SimulationConstants.kTickRateHz).round());
    _timer = Timer.periodic(interval, (timer) {
      _tick();
    });
  }

  void stopSimulation() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void resetEpisode() {
    stopSimulation();
    state = _engine.initialState();
  }

  void loadSnapshot(List<double> weights) {
    if (weights.length != state.synapses.length) return;
    
    final nextSynapses = List.generate(state.synapses.length, (i) {
      return state.synapses[i].copyWith(weight: weights[i]);
    });
    
    state = state.copyWith(synapses: nextSynapses);
  }

  void _tick() {
    final env = ref.read(environmentProvider.notifier).step(state);
    
    final dt = 1.0 / SimulationConstants.kTickRateHz;
    state = _engine.tick(state, env, dt);
  }
}

final simulationProvider = NotifierProvider<SimulationNotifier, SimulationState>(() {
  return SimulationNotifier();
});
