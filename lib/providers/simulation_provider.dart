import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simulation_state.dart';
import '../services/simulation_service.dart';

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
    state = service.calculateNextState(state);
  }

  /// Applies error correction based on a target signal
  void applyLearning(String purkinjeId, bool targetSignal) {
    final service = ref.read(simulationServiceProvider);
    state = service.adjustWeights(state, purkinjeId: purkinjeId, targetSignal: targetSignal);
  }
}

/// Provider for the SimulationState, managed by SimulationNotifier
final simulationProvider = NotifierProvider<SimulationNotifier, SimulationState>(() {
  return SimulationNotifier();
});
