import 'package:meta/meta.dart';

@immutable
class NeuronModel {
  final String id;
  final String cellType;
  final double membranePotential;
  final double restingPotential;
  final double threshold;
  final double decayRate;
  final double eligibilityTrace;
  final bool isInhibitory;
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
