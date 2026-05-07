import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/simulation_state.dart';
import '../models/neuron_model.dart';
import '../models/synapse_model.dart';
import '../models/environment.dart';
import '../models/network_config.dart';
import 'simulation_engine.dart';

/// Messages sent from Main Isolate to Simulation Isolate
sealed class IsolateCommand {}

class ResetCommand extends IsolateCommand {
  final NetworkConfig config;
  ResetCommand(this.config);
}

class TickCommand extends IsolateCommand {
  final EnvironmentStep env;
  final double dt;
  final double learningRate;
  final double gamma;
  final double dcnBaseline;
  final int ticksToRun;

  TickCommand({
    required this.env,
    required this.dt,
    required this.learningRate,
    required this.gamma,
    required this.dcnBaseline,
    this.ticksToRun = 1,
  });
}

class LoadSnapshotCommand extends IsolateCommand {
  final List<double> weights;
  LoadSnapshotCommand(this.weights);
}

/// Initial result containing the full network structure
class IsolateInitResult {
  final HotSimState hot;
  final int episodeCount;
  IsolateInitResult(this.hot, this.episodeCount);
}

/// Periodic result containing only dynamic data in compact form
class IsolateTickResult {
  final Float32List potentials;
  final Float32List traces;
  final Float32List weights;
  final double criticPrediction;
  final double tdError;
  final double climbingFiberSignal;
  final double rollingGainRatio;
  final int episodeStep;
  final int episodeCount;

  IsolateTickResult({
    required this.potentials,
    required this.traces,
    required this.weights,
    required this.criticPrediction,
    required this.tdError,
    required this.climbingFiberSignal,
    required this.rollingGainRatio,
    required this.episodeStep,
    required this.episodeCount,
  });
}

/// Manages a long-lived isolate for running the [SimulationEngine].
class SimulationIsolateController {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _commandPort;
  final StreamController<HotSimState> _stateStream = StreamController<HotSimState>.broadcast();
  final StreamController<int> _episodeStream = StreamController<int>.broadcast();

  Stream<HotSimState> get stateStream => _stateStream.stream;
  Stream<int> get episodeStream => _episodeStream.stream;

  // Cached topology to reconstruct state from compact payloads
  List<String>? _neuronIds;
  List<String>? _synapseIds;
  HotSimState? _latestHot;

  Future<void> spawn() async {
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntry, _receivePort!.sendPort);

    if (_receivePort == null) return; // Disposed during spawn

    final completer = Completer<void>();
    _receivePort!.listen((message) {
      if (_isolate == null) return; // Ignore messages after disposal

      if (message is SendPort) {
        _commandPort = message;
        completer.complete();
      } else if (message is IsolateInitResult) {
        _handleInitResult(message);
      } else if (message is IsolateTickResult) {
        _handleTickResult(message);
      } else if (message is Map<String, dynamic> && message['type'] == 'error') {
        if (!_stateStream.isClosed) {
          _stateStream.addError(message['error'], StackTrace.fromString(message['stack'] ?? ''));
        }
      }
    });

    return completer.future;
  }

  void _handleInitResult(IsolateInitResult result) {
    _neuronIds = result.hot.neurons.keys.toList();
    _synapseIds = result.hot.synapses.map((s) => s.id).toList();
    _latestHot = result.hot;
    if (!_stateStream.isClosed) _stateStream.add(result.hot);
    if (!_episodeStream.isClosed) _episodeStream.add(result.episodeCount);
  }

  void _handleTickResult(IsolateTickResult result) {
    if (_latestHot == null || _neuronIds == null || _synapseIds == null) return;

    // Reconstruct neurons
    final nextNeurons = Map<String, NeuronModel>.from(_latestHot!.neurons);
    for (int i = 0; i < _neuronIds!.length; i++) {
      final id = _neuronIds![i];
      final n = nextNeurons[id]!;
      final potential = result.potentials[i];
      nextNeurons[id] = n.copyWith(
        membranePotential: potential,
        isFiring: potential >= n.threshold,
        eligibilityTrace: result.traces[i],
      );
    }

    // Reconstruct synapses
    final nextSynapses = List<SynapseModel>.generate(_synapseIds!.length, (i) {
      return _latestHot!.synapses[i].copyWith(weight: result.weights[i]);
    });

    _latestHot = _latestHot!.copyWith(
      neurons: nextNeurons,
      synapses: nextSynapses,
      criticPrediction: result.criticPrediction,
      tdError: result.tdError,
      climbingFiberSignal: result.climbingFiberSignal,
      rollingGainRatio: result.rollingGainRatio,
      episodeStep: result.episodeStep,
    ).rebuildIndex();

    if (!_stateStream.isClosed) _stateStream.add(_latestHot!);
    if (!_episodeStream.isClosed) _episodeStream.add(result.episodeCount);
  }

  void sendTick(EnvironmentStep env, double dt, double lr, double gamma, double dcnBaseline, {int ticksToRun = 1}) {
    _commandPort?.send(TickCommand(
      env: env,
      dt: dt,
      learningRate: lr,
      gamma: gamma,
      dcnBaseline: dcnBaseline,
      ticksToRun: ticksToRun,
    ));
  }

  void sendReset(NetworkConfig config) {
    _commandPort?.send(ResetCommand(config));
  }

  void sendLoadSnapshot(List<double> weights) {
    _commandPort?.send(LoadSnapshotCommand(weights));
  }

  Future<void> dispose() async {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
    await _stateStream.close();
    await _episodeStream.close();
  }
}

/// The entry point for the simulation isolate.
void _isolateEntry(SendPort mainSendPort) {
  final commandPort = ReceivePort();
  mainSendPort.send(commandPort.sendPort);

  final engine = SimulationEngine();
  SimulationState? currentState;

  commandPort.listen((message) {
    try {
      if (message is ResetCommand) {
        currentState = engine.initialState(config: message.config);
        mainSendPort.send(IsolateInitResult(currentState!.hot, currentState!.episodeCount));
      } else if (message is TickCommand) {
        if (currentState == null) return;
        
        for (int i = 0; i < message.ticksToRun; i++) {
          currentState = engine.tick(
            currentState!,
            message.env,
            message.dt,
            learningRate: message.learningRate,
            gamma: message.gamma,
            dcnBaseline: message.dcnBaseline,
          );
        }

        // Prepare compact payload
        final neuronIds = currentState!.neurons.keys.toList();
        final potentials = Float32List(neuronIds.length);
        final traces = Float32List(neuronIds.length);
        for (int i = 0; i < neuronIds.length; i++) {
          final n = currentState!.neurons[neuronIds[i]]!;
          potentials[i] = n.membranePotential;
          traces[i] = n.eligibilityTrace;
        }

        final weights = Float32List(currentState!.synapses.length);
        for (int i = 0; i < currentState!.synapses.length; i++) {
          weights[i] = currentState!.synapses[i].weight;
        }

        mainSendPort.send(IsolateTickResult(
          potentials: potentials,
          traces: traces,
          weights: weights,
          criticPrediction: currentState!.criticPrediction,
          tdError: currentState!.tdError,
          climbingFiberSignal: currentState!.climbingFiberSignal,
          rollingGainRatio: currentState!.rollingGainRatio,
          episodeStep: currentState!.episodeStep,
          episodeCount: currentState!.episodeCount,
        ));
      } else if (message is LoadSnapshotCommand) {
        if (currentState == null) return;
        final hot = currentState!.hot;
        if (message.weights.length == hot.synapses.length) {
          final nextSynapses = List.generate(hot.synapses.length, (i) {
            return hot.synapses[i].copyWith(weight: message.weights[i]);
          });
          engine.clearBuffer();
          currentState = currentState!.copyWith(
            synapses: nextSynapses,
          ).rebuildIndex();
          mainSendPort.send(IsolateInitResult(currentState!.hot, currentState!.episodeCount));
        }
      }
    } catch (e, s) {
      mainSendPort.send({
        'type': 'error',
        'error': e.toString(),
        'stack': s.toString(),
      });
    }
  });
}
