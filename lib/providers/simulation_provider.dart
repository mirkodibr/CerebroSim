import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/simulation_state.dart';
import '../models/simulation_constants.dart';
import '../models/episode_record.dart';
import '../models/network_config.dart';
import '../models/experiment_snapshot.dart';
import '../services/simulation_engine.dart';
import '../services/simulation_isolate.dart';
import 'environment_provider.dart';
import 'plot_buffer_provider.dart';
import 'learning_rate_provider.dart';
import 'episode_history_provider.dart';
import 'gamma_provider.dart';
import 'dcn_baseline_provider.dart';
import 'network_config_provider.dart';

bool kUseIsolate = !kIsWeb && !bool.fromEnvironment('dart.library.ui');

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
  late final Ticker _ticker;
  final SimulationEngine _engine = SimulationEngine();
  SimulationIsolateController? _isolateController;
  
  final StreamController<int> _convergenceController = StreamController<int>.broadcast();
  Stream<int> get convergenceEventStream => _convergenceController.stream;

  double _episodePunishmentSum = 0.0;
  int _episodeTickCount = 0;
  bool _wasRunningBeforePause = false;

  // Performance governor state
  int _cleanFrameCount = 0;
  bool _isOverloaded = false;
  static const int _kRecoveryThresholdFrames = 120; // ~2s at 60Hz

  SimulationController(this._ref) {
    _ticker = Ticker(_onFrame);
    WidgetsBinding.instance.addObserver(this);
    
    if (kUseIsolate) {
      _isolateController = SimulationIsolateController();
      _isolateController!.spawn().then((_) {
        if (_isolateController == null) return; // Disposed while spawning
        _isolateController!.sendReset(_ref.read(networkConfigProvider));
        _isolateController!.stateStream.listen((hot) {
          _ref.read(hotSimulationProvider.notifier).setState(hot);
          _ref.read(plotBufferProvider.notifier).addPoint(
            hot.criticPrediction,
            hot.climbingFiberSignal,
            hot.rollingGainRatio,
          );
        }, onError: (e, s) {
          FirebaseCrashlytics.instance.recordError(e, s, fatal: false);
          stopSimulation();
        });

        _isolateController!.episodeStream.listen((count) {
          final cold = _ref.read(coldSimulationProvider);
          if (count > cold.episodeCount) {
            _handleEpisodeEnd(count, _ref.read(hotSimulationProvider));
          }
        });
      });
    }

    _ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _ticker.dispose();
      _isolateController?.dispose();
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
    _ticker.start();
  }

  void pauseSimulation() {
    if (_ticker.isActive) _ticker.stop();
    final cold = _ref.read(coldSimulationProvider);
    _ref.read(coldSimulationProvider.notifier).setState(cold.copyWith(isRunning: false));
  }

  void stopSimulation() => pauseSimulation();

  void setSpeed(double multiplier) {
    final cold = _ref.read(coldSimulationProvider);
    _ref.read(coldSimulationProvider.notifier).setState(cold.copyWith(speedMultiplier: multiplier));
  }

  void _onFrame(Duration elapsed) {
    final cold = _ref.read(coldSimulationProvider);
    final int ticksToRun = cold.speedMultiplier.round();
    final stopwatch = Stopwatch()..start();

    if (kUseIsolate && _isolateController != null) {
      // In Isolate mode, we delegate the batch to the isolate
      final hot = _ref.read(hotSimulationProvider);
      final currentState = SimulationState(hot: hot, cold: cold);
      final env = _ref.read(environmentProvider.notifier).step(currentState);
      
      _isolateController!.sendTick(
        env,
        1.0 / SimulationConstants.kTickRateHz,
        _ref.read(learningRateProvider),
        _ref.read(gammaProvider),
        _ref.read(dcnBaselineProvider),
        ticksToRun: ticksToRun,
      );
    } else {
      // In-process fallback
      for (int i = 0; i < ticksToRun; i++) {
        _tick();
      }
    }

    stopwatch.stop();
    final elapsedMs = stopwatch.elapsedMilliseconds;

    // Governor logic (still applies in both modes)
    if (elapsedMs > 12) {
      if (kDebugMode) {
        print('âš ï¸ Simulation Overload: Frame took ${elapsedMs}ms. Throttling speed.');
      }
      _isOverloaded = true;
      _cleanFrameCount = 0;
      
      final newSpeed = (cold.speedMultiplier / 2).clamp(1.0, 10.0);
      if (newSpeed != cold.speedMultiplier) {
        _ref.read(coldSimulationProvider.notifier).setState(cold.copyWith(speedMultiplier: newSpeed));
      }
    } else {
      if (_isOverloaded) {
        _cleanFrameCount++;
        if (_cleanFrameCount >= _kRecoveryThresholdFrames) {
          _isOverloaded = false;
          _cleanFrameCount = 0;
        }
      }
    }
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

    if (kUseIsolate) {
      _isolateController?.sendReset(config ?? _ref.read(networkConfigProvider));
    }
  }

  void loadSnapshot(ExperimentSnapshot snapshot) {
    if (snapshot.networkConfig != null) {
      _ref.read(networkConfigProvider.notifier).update(snapshot.networkConfig!);
      final newState = SimulationState.initial(config: snapshot.networkConfig!);
      _ref.read(hotSimulationProvider.notifier).setState(newState.hot);
      if (kUseIsolate) {
        _isolateController?.sendReset(snapshot.networkConfig!);
      }
    }

    final hot = _ref.read(hotSimulationProvider);
    final weights = snapshot.synapticWeights;
    if (weights.length != hot.synapses.length) return;
    
    if (kUseIsolate) {
      _isolateController?.sendLoadSnapshot(weights);
    } else {
      final nextSynapses = List.generate(hot.synapses.length, (i) {
        return hot.synapses[i].copyWith(weight: weights[i]);
      });
      
      _engine.clearBuffer();
      _ref.read(hotSimulationProvider.notifier).setState(
        hot.copyWith(synapses: nextSynapses).rebuildIndex()
      );
    }
  }

  void _handleEpisodeEnd(int nextEpisodeCount, HotSimState nextHot) {
    final cold = _ref.read(coldSimulationProvider);
    
    // Note: meanPunishment tracking in Isolate mode might be slightly different
    // if we don't send back every single tick's CF signal.
    // For now we use the latest CF signal as a proxy or keep it as is.
    final record = EpisodeRecord(
      episodeNumber: cold.episodeCount,
      meanPunishment: nextHot.climbingFiberSignal, // Simplified for Isolate mode
      finalTdError: nextHot.tdError,
    );
    
    if (record.meanPunishment < 0.2) {
      _convergenceController.add(nextEpisodeCount);
    }

    _ref.read(episodeHistoryProvider.notifier).recordEpisode(record);
    _ref.read(coldSimulationProvider.notifier).setState(cold.copyWith(episodeCount: nextEpisodeCount));
  }

  void _tick() {
    try {
      final hot = _ref.read(hotSimulationProvider);
      final cold = _ref.read(coldSimulationProvider);
      
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

      _ref.read(hotSimulationProvider.notifier).setState(nextState.hot);

      _episodePunishmentSum += nextState.climbingFiberSignal;
      _episodeTickCount++;

      if (nextState.episodeCount > cold.episodeCount) {
        _handleEpisodeEnd(nextState.episodeCount, nextState.hot);
        _episodePunishmentSum = 0.0;
        _episodeTickCount = 0;
      }

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

  @visibleForTesting
  bool get isTickerActive => _ticker.isActive;
}

final simulationControllerProvider = Provider<SimulationController>((ref) {
  return SimulationController(ref);
});

final simulationProvider = Provider<SimulationState>((ref) {
  final hot = ref.watch(hotSimulationProvider);
  final cold = ref.watch(coldSimulationProvider);
  return SimulationState(hot: hot, cold: cold);
});
