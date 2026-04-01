import 'package:meta/meta.dart';
import 'neuron_model.dart';
import 'synapse_model.dart';

/// The complete snapshot of the simulation's current state at any given tick.
///
/// It contains the status of every neuron and synapse, as well as high-level
/// metrics like prediction error and overall progress through an experiment.
@immutable
class SimulationState {
  /// The list of all neurons in the current network architecture.
  final List<NeuronModel> neurons;
  /// The list of all synaptic connections between neurons.
  final List<SynapseModel> synapses;
  /// The current output of the cerebellar "critic" or prediction unit.
  final double criticPrediction;
  /// The Temporal Difference (TD) error representing the difference between prediction and reality.
  final double tdError;
  /// The current signal level being carried by the climbing fibers (the error signal).
  final double climbingFiberSignal;
  /// A moving average of the gain ratio performance metric.
  final double rollingGainRatio;
  /// The current time step index within the active episode.
  final int episodeStep;
  /// The total number of episodes that have been completed in this session.
  final int episodeCount;
  /// Whether the simulation is currently active and processing ticks.
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

  /// Creates a default initial state for a new simulation.
  ///
  /// This defines a basic cerebellar circuit with Granule, Purkinje, Basket,
  /// Deep Cerebellar Nucleus, and Climbing Fiber neurons.
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

  /// Returns a copy of the simulation state with updated fields.
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
