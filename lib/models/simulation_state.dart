import 'package:meta/meta.dart';
import 'neuron_model.dart';
import 'synapse_model.dart';

@immutable
class SimulationState {
  final List<NeuronModel> neurons;
  final List<SynapseModel> synapses;
  final double criticPrediction;
  final double tdError;
  final double climbingFiberSignal;
  final double rollingGainRatio;
  final int episodeStep;
  final int episodeCount;
  final bool isRunning;

  const SimulationState({
    required this.neurons,
    required this.synapses,
    this.criticPrediction = 0.0,
    this.tdError = 0.0,
    this.climbingFiberSignal = 0.0,
    this.rollingGainRatio = 0.0,
    this.episodeStep = 0,
    this.episodeCount = 0,
    this.isRunning = false,
  });

  factory SimulationState.initial() {
    final neurons = [
      NeuronModel.initial(id: 'GC_01', cellType: 'GC'),
      NeuronModel.initial(id: 'PC_01', cellType: 'PC'),
      NeuronModel.initial(id: 'BC_01', cellType: 'BC'),
      NeuronModel.initial(id: 'DCN_01', cellType: 'DCN'),
      NeuronModel.initial(id: 'CF_01', cellType: 'CF'),
    ];

    final synapses = [
      SynapseModel.initial(fromId: 'GC_01', toId: 'PC_01', isInhibitory: false),
      SynapseModel.initial(fromId: 'GC_01', toId: 'BC_01', isInhibitory: false),
      SynapseModel.initial(fromId: 'BC_01', toId: 'PC_01', isInhibitory: true),
      SynapseModel.initial(fromId: 'PC_01', toId: 'DCN_01', isInhibitory: true),
    ];

    return SimulationState(
      neurons: neurons,
      synapses: synapses,
      criticPrediction: 0.0,
      tdError: 0.0,
      climbingFiberSignal: 0.0,
      rollingGainRatio: 0.0,
      episodeStep: 0,
      episodeCount: 0,
      isRunning: false,
    );
  }

  SimulationState copyWith({
    List<NeuronModel>? neurons,
    List<SynapseModel>? synapses,
    double? criticPrediction,
    double? tdError,
    double? climbingFiberSignal,
    double? rollingGainRatio,
    int? episodeStep,
    int? episodeCount,
    bool? isRunning,
  }) {
    return SimulationState(
      neurons: neurons ?? this.neurons,
      synapses: synapses ?? this.synapses,
      criticPrediction: criticPrediction ?? this.criticPrediction,
      tdError: tdError ?? this.tdError,
      climbingFiberSignal: climbingFiberSignal ?? this.climbingFiberSignal,
      rollingGainRatio: rollingGainRatio ?? this.rollingGainRatio,
      episodeStep: episodeStep ?? this.episodeStep,
      episodeCount: episodeCount ?? this.episodeCount,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}
