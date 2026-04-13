import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simulation_state.dart';
import '../models/simulation_constants.dart';
import '../models/plot_point.dart';
import '../models/episode_record.dart';
import '../services/simulation_engine.dart';
import 'environment_provider.dart';
import 'plot_buffer_provider.dart';
import 'learning_rate_provider.dart';
import 'episode_history_provider.dart';

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
  
  double _episodePunishmentSum = 0.0;
  int _episodeTickCount = 0;
  double _speedMultiplier = SimulationConstants.kSpeedNormal;

  /// Initializes the simulation state using the [SimulationEngine]'s initial state.
  /// Ensures that any active timers are cancelled when the provider is disposed.
  @override
  SimulationState build() {
    ref.onDispose(() => _timer?.cancel());
    return _engine.initialState();
  }

  /// Starts or resumes the simulation.
  void startSimulation() {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true);
    _startTicker();
  }

  /// Pauses the simulation without resetting the current episode progress.
  void pauseSimulation() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  /// Stops the simulation and cancels the active timer.
  void stopSimulation() {
    pauseSimulation();
  }

  /// Sets the simulation speed multiplier and restarts the ticker if running.
  void setSpeed(double multiplier) {
    _speedMultiplier = multiplier;
    if (state.isRunning) {
      _timer?.cancel();
      _startTicker();
    }
  }

  /// Private helper to start the periodic timer at the adjusted speed.
  void _startTicker() {
    final intervalMs = (1000 / (SimulationConstants.kTickRateHz * _speedMultiplier)).round();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      _tick();
    });
  }

  /// Resets the simulation to its initial state and stops any running simulation.
  void resetEpisode() {
    stopSimulation();
    _episodePunishmentSum = 0.0;
    _episodeTickCount = 0;
    ref.read(episodeHistoryProvider.notifier).clear();
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
    final previousEpisodeCount = state.episodeCount;
    final env = ref.read(environmentProvider.notifier).step(state);
    final learningRate = ref.read(learningRateProvider);
    final gamma = ref.read(gammaProvider);
    final dcnBaseline = ref.read(dcnBaselineProvider);
    
    final dt = 1.0 / SimulationConstants.kTickRateHz;
    state = _engine.tick(
      state, 
      env, 
      dt, 
      learningRate: learningRate,
      gamma: gamma,
      dcnBaseline: dcnBaseline,
    );

    // Track statistics for convergence history
    _episodePunishmentSum += state.climbingFiberSignal;
    _episodeTickCount++;

    // Check if an episode just completed
    if (state.episodeCount > previousEpisodeCount) {
      final record = EpisodeRecord(
        episodeNumber: previousEpisodeCount,
        meanPunishment: _episodeTickCount > 0 ? _episodePunishmentSum / _episodeTickCount : 0.0,
        finalTdError: state.tdError,
      );
      
      ref.read(episodeHistoryProvider.notifier).recordEpisode(record);
      
      // Reset counters for next episode
      _episodePunishmentSum = 0.0;
      _episodeTickCount = 0;
    }

    // Update plot buffer with latest simulation data
    ref.read(plotBufferProvider.notifier).addPoint(
      PlotPoint(
        criticPrediction: state.criticPrediction,
        actualSignal: state.climbingFiberSignal,
        gainRatio: state.rollingGainRatio,
      ),
    );
  }
}

/// A global provider for the [SimulationNotifier].
final simulationProvider = NotifierProvider<SimulationNotifier, SimulationState>(() {
  return SimulationNotifier();
});
