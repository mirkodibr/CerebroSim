import 'package:meta/meta.dart';
import 'neuron_model.dart';
import 'synapse_model.dart';
import '../services/network_initializer.dart';

/// The complete snapshot of the simulation's current state at any given tick.
///
/// It contains the status of every neuron and synapse, as well as high-level
/// metrics like prediction error and overall progress through an experiment.
@immutable
class SimulationState {
  /// The map of all neurons in the current network architecture, keyed by their ID.
  final Map<String, NeuronModel> neurons;
  /// The list of all synaptic connections between neurons.
  final List<SynapseModel> synapses;
  /// An adjacency list for instant outbound connection lookups, keyed by the pre-synaptic neuron ID.
  final Map<String, List<SynapseModel>> preSynapticIndex;
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
    this.preSynapticIndex = const {},
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
  /// This utilizes the [NetworkInitializer] to build a standard 
  /// cerebellar architecture rather than hardcoding neuron IDs.
  factory SimulationState.initial({dynamic config}) {
    // The config parameter is typed dynamic to avoid a circular dependency 
    // with NetworkConfig in some build scenarios, though here we cast it.
    return NetworkInitializer.createRLMockNetwork(config: config);
  }

  /// Returns a copy of the simulation state with updated fields.
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
  }) {
    return SimulationState(
      neurons: neurons ?? this.neurons,
      synapses: synapses ?? this.synapses,
      preSynapticIndex: preSynapticIndex ?? this.preSynapticIndex,
      criticPrediction: criticPrediction ?? this.criticPrediction,
      tdError: tdError ?? this.tdError,
      climbingFiberSignal: climbingFiberSignal ?? this.climbingFiberSignal,
      rollingGainRatio: rollingGainRatio ?? this.rollingGainRatio,
      episodeStep: episodeStep ?? this.episodeStep,
      episodeCount: episodeCount ?? this.episodeCount,
      isRunning: isRunning ?? this.isRunning,
    );
  }

  /// Regenerates the [preSynapticIndex] from the current [synapses] list.
  ///
  /// This is an O(N) operation typically used after loading a new set
  /// of synapses (e.g., when restoring a snapshot).
  SimulationState rebuildIndex() {
    final Map<String, List<SynapseModel>> index = {};
    for (final s in synapses) {
      index.putIfAbsent(s.fromNeuronId, () => []).add(s);
    }
    return copyWith(preSynapticIndex: index);
  }
}
