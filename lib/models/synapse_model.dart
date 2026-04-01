import 'package:meta/meta.dart';

/// A model representing a synaptic connection between two neurons.
///
/// It stores the strength (weight) of the connection and its current eligibility
/// for plasticity changes based on local firing patterns.
@immutable
class SynapseModel {
  /// Unique identifier for the synapse, typically formatted as "fromId->toId".
  final String id;
  /// The ID of the presynaptic (sending) neuron.
  final String fromNeuronId;
  /// The ID of the postsynaptic (receiving) neuron.
  final String toNeuronId;
  /// The current strength of the connection. Positive for excitatory, negative for inhibitory.
  final double weight;
  /// A value tracking the temporal correlation between pre- and post-synaptic firing.
  final double eligibility;
  /// Indicates if this synapse has an inhibitory effect on the postsynaptic neuron.
  final bool isInhibitory;

  const SynapseModel({
    required this.id,
    required this.fromNeuronId,
    required this.toNeuronId,
    required this.weight,
    this.eligibility = 0.0,
    required this.isInhibitory,
  });

  /// Creates a [SynapseModel] with an initial weight based on its inhibitory nature.
  factory SynapseModel.initial({
    required String fromId,
    required String toId,
    required bool isInhibitory,
  }) {
    return SynapseModel(
      id: '$fromId->$toId',
      fromNeuronId: fromId,
      toNeuronId: toId,
      weight: isInhibitory ? -0.1 : 0.1,
      eligibility: 0.0,
      isInhibitory: isInhibitory,
    );
  }

  /// Returns a copy of this synapse with updated fields.
  SynapseModel copyWith({
    String? id,
    String? fromNeuronId,
    String? toNeuronId,
    double? weight,
    double? eligibility,
    bool? isInhibitory,
  }) {
    return SynapseModel(
      id: id ?? this.id,
      fromNeuronId: fromNeuronId ?? this.fromNeuronId,
      toNeuronId: toNeuronId ?? this.toNeuronId,
      weight: weight ?? this.weight,
      eligibility: eligibility ?? this.eligibility,
      isInhibitory: isInhibitory ?? this.isInhibitory,
    );
  }
}
