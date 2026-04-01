import 'package:meta/meta.dart';

/// A mathematical representation of a single neuron in the cerebellar model.
///
/// This model tracks membrane potential, firing state, and eligibility traces
/// used for temporal difference (TD) learning or other synaptic plasticity rules.
@immutable
class NeuronModel {
  /// Unique identifier for the neuron.
  final String id;
  /// The biological type of the cell (e.g., "GC", "PC", "BC").
  final String cellType;
  /// The current electrical potential of the neuron's membrane.
  final double membranePotential;
  /// The potential the membrane returns to in the absence of input.
  final double restingPotential;
  /// The potential at which the neuron triggers a spike or firing event.
  final double threshold;
  /// The rate at which the membrane potential returns to resting state.
  final double decayRate;
  /// A value used in reinforcement learning to bridge the gap between stimulus and reward/error.
  final double eligibilityTrace;
  /// Indicates if this neuron releases inhibitory neurotransmitters (e.g., GABA).
  final bool isInhibitory;
  /// Whether the neuron is currently in a firing (spiking) state.
  final bool isFiring;

  const NeuronModel({
    required this.id,
    required this.cellType,
    this.membranePotential = 0.0,
    this.restingPotential = 0.0,
    this.threshold = 1.0,
    this.decayRate = 0.1,
    this.eligibilityTrace = 0.0,
    required this.isInhibitory,
    this.isFiring = false,
  });

  /// Creates a [NeuronModel] with default parameters based on its [cellType].
  factory NeuronModel.initial({
    required String id,
    required String cellType,
  }) {
    final bool isInhibitory = cellType == 'PC' || cellType == 'BC';
    return NeuronModel(
      id: id,
      cellType: cellType,
      membranePotential: 0.0,
      restingPotential: 0.0,
      threshold: 1.0,
      decayRate: 0.1,
      eligibilityTrace: 0.0,
      isInhibitory: isInhibitory,
      isFiring: false,
    );
  }

  /// Returns a copy of this neuron with updated fields.
  NeuronModel copyWith({
    String? id,
    String? cellType,
    double? membranePotential,
    double? restingPotential,
    double? threshold,
    double? decayRate,
    double? eligibilityTrace,
    bool? isInhibitory,
    bool? isFiring,
  }) {
    return NeuronModel(
      id: id ?? this.id,
      cellType: cellType ?? this.cellType,
      membranePotential: membranePotential ?? this.membranePotential,
      restingPotential: restingPotential ?? this.restingPotential,
      threshold: threshold ?? this.threshold,
      decayRate: decayRate ?? this.decayRate,
      eligibilityTrace: eligibilityTrace ?? this.eligibilityTrace,
      isInhibitory: isInhibitory ?? this.isInhibitory,
      isFiring: isFiring ?? this.isFiring,
    );
  }
}
