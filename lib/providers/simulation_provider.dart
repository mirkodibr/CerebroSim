import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simulation_state.dart';
import '../models/simulation_constants.dart';
import '../services/simulation_engine.dart';
import 'environment_provider.dart';

/// A provider that exposes an instance of [SimulationEngine].
/// The engine contains the core logic for updating the neural network state.
final simulationEngineProvider = Provider<SimulationEngine>((ref) {
  return SimulationEngine();
});

/// A notifier that manages the state of the cerebellar simulation.
/// It orchestrates the timing of the simulation ticks, interacts with the
/// [SimulationEngine] for state updates, and communicates with the
/// [EnvironmentNotifier] for task-specific inputs and feedback.
class SimulationNotifier extends Notifier<SimulationState> {
  Timer? _timer;
  final SimulationEngine _engine = SimulationEngine();

  /// Initializes the simulation state using the [SimulationEngine]'s initial state.
  /// Ensures that any active timers are cancelled when the provider is disposed.
  @override
  SimulationState build() {
    ref.onDispose(() => _timer?.cancel());
    return _engine.initialState();
  }

  /// Starts the simulation by setting up a periodic timer that calls [_tick]
  /// at the rate specified by [SimulationConstants.kTickRateHz].
  void startSimulation() {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true);
    
    final interval = Duration(milliseconds: (1000 / SimulationConstants.kTickRateHz).round());
    _timer = Timer.periodic(interval, (timer) {
      _tick();
    });
  }

  /// Stops the simulation by cancelling the active periodic timer.
  void stopSimulation() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  /// Resets the simulation to its initial state and stops any running simulation.
  void resetEpisode() {
    stopSimulation();
    state = _engine.initialState();
  }

  /// Loads a previously saved snapshot of synaptic weights into the current simulation state.
  /// This allows restoring the network's learning state from the vault.
  void loadSnapshot(List<double> weights) {
    if (weights.length != state.synapses.length) return;
    
    final nextSynapses = List.generate(state.synapses.length, (i) {
      return state.synapses[i].copyWith(weight: weights[i]);
    });
    
    state = state.copyWith(synapses: nextSynapses);
  }

  /// Performs a single simulation step (tick).
  /// 1. Obtains the environment's state and feedback via [EnvironmentNotifier.step].
  /// 2. Updates the neural network state using [SimulationEngine.tick].
  /// 3. Updates the [state] with the new simulation data.
  void _tick() {
    final env = ref.read(environmentProvider.notifier).step(state);
    
    final dt = 1.0 / SimulationConstants.kTickRateHz;
    state = _engine.tick(state, env, dt);
  }
}

/// A global provider for the [SimulationNotifier].
final simulationProvider = NotifierProvider<SimulationNotifier, SimulationState>(() {
  return SimulationNotifier();
});
