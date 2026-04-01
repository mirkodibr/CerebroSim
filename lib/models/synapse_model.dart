import 'package:meta/meta.dart';

@immutable
class SynapseModel {
  final String id;
  final String fromNeuronId;
  final String toNeuronId;
  final double weight;
  final double eligibility;
  final bool isInhibitory;

  const SynapseModel({
    required this.id,
    required this.fromNeuronId,
    required this.toNeuronId,
    required this.weight,
    this.eligibility = 0.0,
    required this.isInhibitory,
  });

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
