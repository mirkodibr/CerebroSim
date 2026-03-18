import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simulation_state.dart';
import '../models/neuron.dart';
import '../services/simulation_service.dart';
import 'environment_provider.dart';

/// Provider for the SimulationService
final simulationServiceProvider = Provider<SimulationService>((ref) {
  return SimulationService();
});

/// Notifier that manages the simulation state and timing
class SimulationNotifier extends Notifier<SimulationState> {
  Timer? _timer;
  bool _isRunning = false;

  @override
  SimulationState build() {
    ref.onDispose(() => _timer?.cancel());
    return const SimulationState(neurons: [], synapses: []);
  }

  bool get isRunning => _isRunning;

  /// Initializes the simulation with a starting state
  void initialize(SimulationState initialState) {
    state = initialState;
    ref.read(signalHistoryProvider.notifier).reset();
    ref.read(environmentProvider.notifier).reset();
  }

  /// Starts the simulation at ~60 FPS (16ms per tick)
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      tick();
    });
  }

  /// Stops the simulation
  void stop() {
    _timer?.cancel();
    _isRunning = false;
  }

  /// Processes a single step of the simulation
  void tick() {
    final service = ref.read(simulationServiceProvider);
    
    // 1. Advance environment
    final envNotifier = ref.read(environmentProvider.notifier);
    envNotifier.update(16);
    final pfState = envNotifier.getPFStateVector();

    // 2. Feed PF state into 'Granular' neurons (Parallel Fibers)
    // Assume PF neurons have IDs like 'pf_0', 'pf_1', etc.
    SimulationState currentState = state;
    final List<Neuron> updatedNeurons = currentState.neurons.map((n) {
      if (n.type == 'Granular') {
        final pfIndexString = n.id.replaceFirst('pf_', '');
        final index = int.tryParse(pfIndexString);
        if (index != null && index < pfState.length) {
          // If this PF should be active now, push it to threshold
          return n.copyWith(currentPotential: pfState[index] ? n.threshold : n.currentPotential);
        }
      }
      return n;
    }).toList();
    currentState = currentState.copyWith(neurons: updatedNeurons);

    // 3. Process the simulation step (LIF dynamics)
    state = service.calculateNextState(currentState);

    // 4. Learning logic (Actor-Critic)
    final lastAction = service.getExecutedAction(state);
    final actualPunishment = envNotifier.getClimbingFiberSignal(lastAction);
    
    // Apply weight updates
    state = service.adjustWeightsRL(state, climbingFiberPunishment: actualPunishment);

    // 5. Update history for plotting
    // predictedPunishment is the sum of SC neuron potentials (Critic)
    double predictedPunishment = 0.0;
    for (final neuron in state.neurons) {
      if (neuron.type == 'SC') {
        predictedPunishment += neuron.currentPotential;
      }
    }

    ref.read(signalHistoryProvider.notifier).addPoint(
      predictedPunishment, 
      actualPunishment
    );
  }

  /// Applies RL learning rule with climbing fiber punishment (Convenience method)
  void applyLearningRL(double climbingFiberPunishment) {
    final service = ref.read(simulationServiceProvider);
    state = service.adjustWeightsRL(state, climbingFiberPunishment: climbingFiberPunishment);
  }
}

/// Provider for the SimulationState, managed by SimulationNotifier
final simulationProvider = NotifierProvider<SimulationNotifier, SimulationState>(() {
  return SimulationNotifier();
});
