import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simulation_state.dart';
import '../models/neuron.dart';
import '../services/simulation_service.dart';
import 'signal_provider.dart';

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
    // Return an initial empty state. 
    // In a real app, this might load from a default configuration.
    ref.onDispose(() => _timer?.cancel());
    return const SimulationState(neurons: [], synapses: []);
  }

  bool get isRunning => _isRunning;

  /// Initializes the simulation with a starting state
  void initialize(SimulationState initialState) {
    state = initialState;
    ref.read(signalHistoryProvider.notifier).reset();
    ref.read(signalProvider.notifier).reset();
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
    
    // 1. Update the signal generator
    final signalNotifier = ref.read(signalProvider.notifier);
    signalNotifier.update(16);
    final currentInput = ref.read(signalProvider);

    // 2. Feed signal into the input neuron (e.g. 'n1')
    SimulationState currentState = state;
    final List<Neuron> updatedNeurons = currentState.neurons.map((n) {
      if (n.type == 'Granular') {
        // If signal is high, push potential towards threshold
        return n.copyWith(currentPotential: currentInput ? n.threshold : n.currentPotential);
      }
      return n;
    }).toList();
    currentState = currentState.copyWith(neurons: updatedNeurons);

    // 3. Process the simulation tick
    final nextState = service.calculateNextState(currentState);
    state = nextState;

    // 4. Learning logic (Actor-Critic Refactor)
    // Temporary: Mock punishment signal based on supervised error for compilability
    final purkinje = state.neurons.firstWhere(
      (n) => n.type == 'Purkinje', 
      orElse: () => state.neurons.isNotEmpty ? state.neurons.last : const Neuron(id: '', type: '', threshold: 0, currentPotential: 0)
    );
    final isSpiking = purkinje.currentPotential >= purkinje.threshold;
    final double mockPunishment = (isSpiking != currentInput) ? -1.0 : 0.0;

    applyLearningRL(mockPunishment);

    // 5. Update history
    final outputSpike = purkinje.currentPotential >= purkinje.threshold;
    ref.read(signalHistoryProvider.notifier).addPoint(
      currentInput ? 1.0 : 0.0, 
      outputSpike ? 1.0 : 0.0
    );
  }

  /// Applies RL learning rule with climbing fiber punishment
  void applyLearningRL(double climbingFiberPunishment) {
    final service = ref.read(simulationServiceProvider);
    state = service.adjustWeightsRL(state, climbingFiberPunishment: climbingFiberPunishment);
  }
}

/// Provider for the SimulationState, managed by SimulationNotifier
final simulationProvider = NotifierProvider<SimulationNotifier, SimulationState>(() {
  return SimulationNotifier();
});
