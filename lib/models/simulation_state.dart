import 'package:meta/meta.dart';
import 'neuron_model.dart';
import 'synapse_model.dart';
import '../services/network_initializer.dart';

/// State that updates at high frequency (every simulation tick).
@immutable
class HotSimState {
  final Map<String, NeuronModel> neurons;
  final List<SynapseModel> synapses;
  final Map<String, List<SynapseModel>> preSynapticIndex;
  final double criticPrediction;
  final double tdError;
  final double climbingFiberSignal;
  final double rollingGainRatio;
  final int episodeStep;

  const HotSimState({
    required this.neurons,
    required this.synapses,
    this.preSynapticIndex = const {},
    this.criticPrediction = 0.0,
    this.tdError = 0.0,
    this.climbingFiberSignal = 0.0,
    this.rollingGainRatio = 0.0,
    this.episodeStep = 0,
  });

  HotSimState copyWith({
    Map<String, NeuronModel>? neurons,
    List<SynapseModel>? synapses,
    Map<String, List<SynapseModel>>? preSynapticIndex,
    double? criticPrediction,
    double? tdError,
    double? climbingFiberSignal,
    double? rollingGainRatio,
    int? episodeStep,
  }) {
    return HotSimState(
      neurons: neurons ?? this.neurons,
      synapses: synapses ?? this.synapses,
      preSynapticIndex: preSynapticIndex ?? this.preSynapticIndex,
      criticPrediction: criticPrediction ?? this.criticPrediction,
      tdError: tdError ?? this.tdError,
      climbingFiberSignal: climbingFiberSignal ?? this.climbingFiberSignal,
      rollingGainRatio: rollingGainRatio ?? this.rollingGainRatio,
      episodeStep: episodeStep ?? this.episodeStep,
    );
  }

  HotSimState rebuildIndex() {
    final Map<String, List<SynapseModel>> index = {};
    for (final s in synapses) {
      index.putIfAbsent(s.fromNeuronId, () => []).add(s);
    }
    return copyWith(preSynapticIndex: index);
  }
}

/// State that updates at low frequency (user action or episode boundary).
@immutable
class ColdSimState {
  final bool isRunning;
  final int episodeCount;
  final double speedMultiplier;
  final bool isThrottled;

  const ColdSimState({
    this.isRunning = false,
    this.episodeCount = 0,
    this.speedMultiplier = 1.0,
    this.isThrottled = false,
  });

  ColdSimState copyWith({
    bool? isRunning,
    int? episodeCount,
    double? speedMultiplier,
    bool? isThrottled,
  }) {
    return ColdSimState(
      isRunning: isRunning ?? this.isRunning,
      episodeCount: episodeCount ?? this.episodeCount,
      speedMultiplier: speedMultiplier ?? this.speedMultiplier,
      isThrottled: isThrottled ?? this.isThrottled,
    );
  }
}

/// Legacy wrapper for backward compatibility during refactor.
/// This will be removed once all consumers migrate to Hot/Cold providers.
@immutable
class SimulationState {
  final HotSimState hot;
  final ColdSimState cold;

  const SimulationState({required this.hot, required this.cold});

  Map<String, NeuronModel> get neurons => hot.neurons;
  List<SynapseModel> get synapses => hot.synapses;
  Map<String, List<SynapseModel>> get preSynapticIndex => hot.preSynapticIndex;
  double get criticPrediction => hot.criticPrediction;
  double get tdError => hot.tdError;
  double get climbingFiberSignal => hot.climbingFiberSignal;
  double get rollingGainRatio => hot.rollingGainRatio;
  int get episodeStep => hot.episodeStep;
  int get episodeCount => cold.episodeCount;
  bool get isRunning => cold.isRunning;
  double get speedMultiplier => cold.speedMultiplier;

  factory SimulationState.initial({dynamic config}) {
    final state = NetworkInitializer.createRLMockNetwork(config: config);
    return SimulationState(
      hot: HotSimState(
        neurons: state.neurons,
        synapses: state.synapses,
        preSynapticIndex: state.preSynapticIndex,
        criticPrediction: state.criticPrediction,
        tdError: state.tdError,
        climbingFiberSignal: state.climbingFiberSignal,
        rollingGainRatio: state.rollingGainRatio,
        episodeStep: state.episodeStep,
      ),
      cold: ColdSimState(
        isRunning: state.isRunning,
        episodeCount: state.episodeCount,
        speedMultiplier: state.speedMultiplier,
      ),
    );
  }

  SimulationState copyWith({
    Map<String, NeuronModel>? neurons,
    List<SynapseModel>? synapses,
    Map<String, List<SynapseModel>>? preSynapticIndex,
    double? criticPrediction,
    double? tdError,
    double? climbingFiberSignal,
    double? rollingGainRatio,
    int? episodeStep,
    int? episodeCount,
    bool? isRunning,
    double? speedMultiplier,
  }) {
    return SimulationState(
      hot: hot.copyWith(
        neurons: neurons,
        synapses: synapses,
        preSynapticIndex: preSynapticIndex,
        criticPrediction: criticPrediction,
        tdError: tdError,
        climbingFiberSignal: climbingFiberSignal,
        rollingGainRatio: rollingGainRatio,
        episodeStep: episodeStep,
      ),
      cold: cold.copyWith(
        isRunning: isRunning,
        episodeCount: episodeCount,
        speedMultiplier: speedMultiplier,
      ),
    );
  }

  SimulationState rebuildIndex() => SimulationState(hot: hot.rebuildIndex(), cold: cold);
}
