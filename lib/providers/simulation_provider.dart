import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simulation_state.dart';
import '../models/simulation_constants.dart';
import '../models/episode_record.dart';
import '../models/network_config.dart';
import '../models/experiment_snapshot.dart';
import '../models/cold_sim_state.dart';
import '../models/hot_sim_state.dart';
import '../services/simulation_engine.dart';
import 'environment_provider.dart';
import 'plot_buffer_provider.dart';
import 'learning_rate_provider.dart';
import 'episode_history_provider.dart';
import 'gamma_provider.dart';
import 'dcn_baseline_provider.dart';
import 'network_config_provider.dart';

/// A provider that exposes an instance of [SimulationEngine].
/// The engine contains the core logic for updating the neural network state.
final simulationEngineProvider = Provider<SimulationEngine>((ref) {
  return SimulationEngine();
});

/// A notifier that manages the state of the cerebellar simulation.
/// It orchestrates the timing of the simulation ticks, interacts with the
/// [SimulationEngine] for state updates, and communicates with the
/// [EnvironmentNotifier] for task-specific inputs and feedback.
class SimulationNotifier extends Notifier<SimulationState> with WidgetsBindingObserver {
  Ticker? _ticker;
  final SimulationEngine _engine = SimulationEngine();

  // Stream for convergence events
  final StreamController<int> _convergenceController = StreamController<int>.broadcast();
  Stream<int> get convergenceEventStream => _convergenceController.stream;

  double _episodePunishmentSum = 0.0;
  int _episodeTickCount = 0;
  bool _wasRunningBeforePause = false;

  // Frame budget governor state
  bool _overloaded = false;
  DateTime? _overloadedSince;

  /// Initializes the simulation state using the [SimulationEngine]'s initial state.
  /// Ensures that any active tickers are disposed when the provider is disposed.
  @override
  SimulationState build() {
    WidgetsBinding.instance.addObserver(this);

    // Listen to network config changes to invalidate correctly but not auto-reset
    ref.listen(networkConfigProvider, (prev, next) {});

    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _ticker?.dispose();
      _ticker = null;
    });

    final initialConfig = ref.read(networkConfigProvider);
    return _engine.initialState(config: initialConfig);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _wasRunningBeforePause = this.state.isRunning;
      pauseSimulation();
    } else if (state == AppLifecycleState.resumed) {
      if (_wasRunningBeforePause) {
        startSimulation();
      }
    }
  }

  /// Starts or resumes the simulation.
  void startSimulation() {
    if (state.isRunning) return;
    HapticFeedback.mediumImpact();
    state = state.copyWith(isRunning: true);
    _startTicker();
  }

  /// Pauses the simulation without resetting the current episode progress.
  void pauseSimulation() {
    _ticker?.stop();
    state = state.copyWith(isRunning: false);
  }

  /// Stops the simulation and cancels the active ticker.
  void stopSimulation() {
    pauseSimulation();
  }

  /// Sets the simulation speed multiplier.
  /// The running Ticker picks up the new value on the next frame automatically.
  void setSpeed(double multiplier) {
    state = state.copyWith(speedMultiplier: multiplier);
    _overloaded = false;
    _overloadedSince = null;
  }

  /// Creates a vsync-aligned [Ticker] that batches logical ticks per frame.
  void _startTicker() {
    _ticker?.dispose();
    _ticker = Ticker(_onFrame)..start();
  }

  /// Called once per display frame by the [Ticker].
  ///
  /// Runs [speedMultiplier.round()] logical ticks inside a single frame.
  /// If engine work exceeds 12 ms the frame-budget governor kicks in:
  /// the overload flag is set so subsequent frames run only 1 tick until
  /// 2 s of clean frames have elapsed.
  void _onFrame(Duration _elapsed) {
    final int ticksThisFrame = _overloaded ? 1 : state.speedMultiplier.round().clamp(1, 20);

    final sw = Stopwatch()..start();
    for (int i = 0; i < ticksThisFrame; i++) {
      _tick();
    }
    sw.stop();

    if (kDebugMode && sw.elapsedMilliseconds > 12) {
      debugPrint('[Sim] frame budget exceeded: ${sw.elapsedMilliseconds} ms — degrading speed');
      _overloaded = true;
      _overloadedSince = DateTime.now();
    } else if (_overloaded && _overloadedSince != null) {
      if (DateTime.now().difference(_overloadedSince!).inSeconds >= 2) {
        _overloaded = false;
        _overloadedSince = null;
      }
    }
  }

  /// Resets the simulation to its initial state and stops any running simulation.
  void resetEpisode({NetworkConfig? config}) {
    stopSimulation();
    _episodePunishmentSum = 0.0;
    _episodeTickCount = 0;
    _engine.clearBuffer();
    ref.read(plotBufferProvider.notifier).clear();
    ref.read(episodeHistoryProvider.notifier).clear();
    state = _engine.initialState(config: config).copyWith(
      speedMultiplier: SimulationConstants.kSpeedNormal,
    );
  }

  /// Loads a previously saved snapshot into the current simulation state.
  /// This allows restoring the network's learning state and topology from the vault.
  void loadSnapshot(ExperimentSnapshot snapshot) {
    // If the snapshot has a different network config, we must update our config first
    if (snapshot.networkConfig != null) {
      ref.read(networkConfigProvider.notifier).update(snapshot.networkConfig!);
      
      // Rebuild state with the new config first
      state = _engine.initialState(config: snapshot.networkConfig!);
    }

    final weights = snapshot.synapticWeights;
    if (weights.length != state.synapses.length) return;
    
    final nextSynapses = List.generate(state.synapses.length, (i) {
      return state.synapses[i].copyWith(weight: weights[i]);
    });
    
    _engine.clearBuffer();
    state = state.copyWith(synapses: nextSynapses).rebuildIndex();
  }

  /// Performs a single simulation step (tick).
  /// 1. Obtains the environment's state and feedback via [EnvironmentNotifier.step].
  /// 2. Updates the neural network state using [SimulationEngine.tick].
  /// 3. Updates the [state] with the new simulation data.
  void _tick() {
    try {
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
        assert(() {
          debugPrint("Episode completed: ${state.episodeCount}");
          return true;
        }());
        
        final record = EpisodeRecord(
          episodeNumber: previousEpisodeCount,
          meanPunishment: _episodeTickCount > 0 ? _episodePunishmentSum / _episodeTickCount : 0.0,
          finalTdError: state.tdError,
        );
        
        // Emit convergence event if mean punishment is low enough
        if (record.meanPunishment < 0.2) {
          _convergenceController.add(state.episodeCount);
        }

        ref.read(episodeHistoryProvider.notifier).recordEpisode(record);
        
        // Reset counters for next episode
        _episodePunishmentSum = 0.0;
        _episodeTickCount = 0;
      }

      // Update plot buffer with latest simulation data — no PlotPoint allocation.
      ref.read(plotBufferProvider.notifier).push(
        state.criticPrediction,
        state.climbingFiberSignal,
        state.rollingGainRatio,
      );
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s, fatal: false);
      stopSimulation();
    }
  }
}

/// A global provider for the [SimulationNotifier].
final simulationProvider = NotifierProvider<SimulationNotifier, SimulationState>(() {
  return SimulationNotifier();
});

// ---------------------------------------------------------------------------
// Hot / Cold split providers (P1.2)
// ---------------------------------------------------------------------------

/// Exposes only the hot (per-tick) fields of the simulation as a [HotSimState].
///
/// This provider is re-evaluated every tick but its reference is the same as
/// [simulationProvider] — use it in widgets that NEED per-tick updates (e.g.,
/// the 3D canvas, charts).
final hotSimulationProvider = Provider<HotSimState>((ref) {
  final s = ref.watch(simulationProvider);
  return HotSimState(
    neurons: s.neurons,
    synapses: s.synapses,
    preSynapticIndex: s.preSynapticIndex,
    criticPrediction: s.criticPrediction,
    tdError: s.tdError,
    climbingFiberSignal: s.climbingFiberSignal,
    rollingGainRatio: s.rollingGainRatio,
    episodeStep: s.episodeStep,
  );
});

/// Exposes only the cold (slow-changing) fields as a [ColdSimState].
///
/// Because [ColdSimState] implements value equality, this provider only
/// notifies listeners when [isRunning], [episodeCount], or [speedMultiplier]
/// actually change — NOT on every 60 Hz tick.
/// Widgets watching this provider will NOT rebuild during a normal tick.
final coldSimulationProvider = Provider<ColdSimState>((ref) {
  final s = ref.watch(simulationProvider);
  return ColdSimState(
    isRunning: s.isRunning,
    episodeCount: s.episodeCount,
    speedMultiplier: s.speedMultiplier,
  );
});

// ---------------------------------------------------------------------------
// SimulationController facade (P1.2)
// ---------------------------------------------------------------------------

/// Imperative API for controlling the simulation.
///
/// Prefer accessing this via [simulationControllerProvider] rather than
/// using [simulationProvider.notifier] directly, so call sites do not need
/// to depend on the concrete notifier type.
class SimulationController {
  final Ref _ref;
  SimulationController(this._ref);

  SimulationNotifier get _notifier =>
      _ref.read(simulationProvider.notifier);

  void startSimulation() => _notifier.startSimulation();
  void pauseSimulation() => _notifier.pauseSimulation();
  void stopSimulation() => _notifier.stopSimulation();
  void resetEpisode({NetworkConfig? config}) =>
      _notifier.resetEpisode(config: config);
  void setSpeed(double multiplier) => _notifier.setSpeed(multiplier);
  void loadSnapshot(ExperimentSnapshot snapshot) =>
      _notifier.loadSnapshot(snapshot);
  Stream<int> get convergenceEventStream =>
      _notifier.convergenceEventStream;
}

/// Provider for the [SimulationController] facade.
final simulationControllerProvider = Provider<SimulationController>((ref) {
  return SimulationController(ref);
});
