import 'package:meta/meta.dart';
import 'neuron_model.dart';
import 'synapse_model.dart';

/// The per-tick "hot" portion of the simulation state.
///
/// These fields change every frame and are broadcast 60× per second.
/// Widgets that only care about slow-changing information (running status,
/// episode count, speed) should watch [ColdSimState] instead to avoid
/// unnecessary rebuilds.
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
}
