import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simulation_state.dart';
import '../models/simulation_constants.dart';
import '../models/plot_point.dart';
import '../models/episode_record.dart';
import '../models/network_config.dart';
import '../models/experiment_snapshot.dart';
import '../services/simulation_engine.dart';
import 'environment_provider.dart';
import 'plot_buffer_provider.dart';
import 'learning_rate_provider.dart';
import 'episode_history_provider.dart';
import 'gamma_provider.dart';
import 'dcn_baseline_provider.dart';
import 'network_config_provider.dart';

/// A notifier for high-frequency simulation state (neurons, synapses, etc.)
class HotSimulationNotifier extends Notifier<HotSimState> {
  @override
  HotSimState build() {
    final initialConfig = ref.read(networkConfigProvider);
    final initial = SimulationState.initial(config: initialConfig);
    return initial.hot;
  }

  void setState(HotSimState newState) => state = newState;
}

/// A notifier for low-frequency simulation state (isRunning, speed, episodeCount)
class ColdSimulationNotifier extends Notifier<ColdSimState> {
  @override
  ColdSimState build() {
    final initialConfig = ref.read(networkConfigProvider);
    final initial = SimulationState.initial(config: initialConfig);
    return initial.cold;
  }

  void setState(ColdSimState newState) => state = newState;
}

final hotSimulationProvider = NotifierProvider<HotSimulationNotifier, HotSimState>(() {
  return HotSimulationNotifier();
});

final coldSimulationProvider = NotifierProvider<ColdSimulationNotifier, ColdSimState>(() {
  return ColdSimulationNotifier();
});

/// A controller that manages the simulation lifecycle and updates Hot/Cold providers.
class SimulationController with WidgetsBindingObserver {
  final Ref _ref;
  Timer? _timer;
  final SimulationEngine _engine = SimulationEngine();
  
  final StreamController<int> _convergenceController = StreamController<int>.broadcast();
  Stream<int> get convergenceEventStream => _convergenceController.stream;

  double _episodePunishmentSum = 0.0;
  int _episodeTickCount = 0;
  bool _wasRunningBeforePause = false;

  SimulationController(this._ref) {
    WidgetsBinding.instance.addObserver(this);
    _ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _timer?.cancel();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cold = _ref.read(coldSimulationProvider);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _wasRunningBeforePause = cold.isRunning;
      pauseSimulation();
    } else if (state == AppLifecycleState.resumed) {
      if (_wasRunningBeforePause) {
        startSimulation();
      }
    }
  }

  void startSimulation() {
    final cold = _ref.read(coldSimulationProvider);
    if (cold.isRunning) return;
    HapticFeedback.mediumImpact();
    _ref.read(coldSimulationProvider.notifier).setState(cold.copyWith(isRunning: true));
    _startTicker();
  }

  void pauseSimulation() {
    _timer?.cancel();
    final cold = _ref.read(coldSimulationProvider);
    _ref.read(coldSimulationProvider.notifier).setState(cold.copyWith(isRunning: false));
  }

  void stopSimulation() => pauseSimulation();

  void setSpeed(double multiplier) {
    final cold = _ref.read(coldSimulationProvider);
    _ref.read(coldSimulationProvider.notifier).setState(cold.copyWith(speedMultiplier: multiplier));
    if (cold.isRunning) {
      _timer?.cancel();
      _startTicker();
    }
  }

  void _startTicker() {
    final cold = _ref.read(coldSimulationProvider);
    final intervalMs = (1000 / (SimulationConstants.kTickRateHz * cold.speedMultiplier)).round();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      _tick();
    });
  }

  void resetEpisode({NetworkConfig? config}) {
    stopSimulation();
    _episodePunishmentSum = 0.0;
    _episodeTickCount = 0;
    _engine.clearBuffer();
    _ref.read(plotBufferProvider.notifier).clear();
    _ref.read(episodeHistoryProvider.notifier).clear();
    
    final newState = SimulationState.initial(config: config);
    _ref.read(hotSimulationProvider.notifier).setState(newState.hot);
    _ref.read(coldSimulationProvider.notifier).setState(newState.cold.copyWith(
      speedMultiplier: SimulationConstants.kSpeedNormal,
    ));
  }

  void loadSnapshot(ExperimentSnapshot snapshot) {
    if (snapshot.networkConfig != null) {
      _ref.read(networkConfigProvider.notifier).update(snapshot.networkConfig!);
      final newState = SimulationState.initial(config: snapshot.networkConfig!);
      _ref.read(hotSimulationProvider.notifier).setState(newState.hot);
    }

    final hot = _ref.read(hotSimulationProvider);
    final weights = snapshot.synapticWeights;
    if (weights.length != hot.synapses.length) return;
    
    final nextSynapses = List.generate(hot.synapses.length, (i) {
      return hot.synapses[i].copyWith(weight: weights[i]);
    });
    
    _engine.clearBuffer();
    _ref.read(hotSimulationProvider.notifier).setState(
      hot.copyWith(synapses: nextSynapses).rebuildIndex()
    );
  }

  void _tick() {
    try {
      final hot = _ref.read(hotSimulationProvider);
      final cold = _ref.read(coldSimulationProvider);
      
      // Combine for engine (using legacy SimulationState wrapper)
      final currentState = SimulationState(hot: hot, cold: cold);

      final env = _ref.read(environmentProvider.notifier).step(currentState);
      final learningRate = _ref.read(learningRateProvider);
      final gamma = _ref.read(gammaProvider);
      final dcnBaseline = _ref.read(dcnBaselineProvider);
      
      final dt = 1.0 / SimulationConstants.kTickRateHz;
      final nextState = _engine.tick(
        currentState, 
        env, 
        dt, 
        learningRate: learningRate,
        gamma: gamma,
        dcnBaseline: dcnBaseline,
      );

      // Update Hot State
      _ref.read(hotSimulationProvider.notifier).setState(nextState.hot);

      // Track statistics
      _episodePunishmentSum += nextState.climbingFiberSignal;
      _episodeTickCount++;

      // Update Cold State if episode boundary reached
      if (nextState.episodeCount > cold.episodeCount) {
        final record = EpisodeRecord(
          episodeNumber: cold.episodeCount,
          meanPunishment: _episodeTickCount > 0 ? _episodePunishmentSum / _episodeTickCount : 0.0,
          finalTdError: nextState.tdError,
        );
        
        if (record.meanPunishment < 0.2) {
          _convergenceController.add(nextState.episodeCount);
        }

        _ref.read(episodeHistoryProvider.notifier).recordEpisode(record);
        _ref.read(coldSimulationProvider.notifier).setState(nextState.cold);
        
        _episodePunishmentSum = 0.0;
        _episodeTickCount = 0;
      }

      // Update plot buffer
      _ref.read(plotBufferProvider.notifier).addPoint(
        nextState.criticPrediction,
        nextState.climbingFiberSignal,
        nextState.rollingGainRatio,
      );
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(e, s, fatal: false);
      stopSimulation();
    }
  }
}

final simulationControllerProvider = Provider<SimulationController>((ref) {
  return SimulationController(ref);
});

/// Legacy provider for backward compatibility. 
/// It combines hot and cold states. Use hotSimulationProvider or coldSimulationProvider instead.
final simulationProvider = Provider<SimulationState>((ref) {
  final hot = ref.watch(hotSimulationProvider);
  final cold = ref.watch(coldSimulationProvider);
  return SimulationState(hot: hot, cold: cold);
});
