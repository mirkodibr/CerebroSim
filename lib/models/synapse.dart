class Synapse {
  final String sourceId;
  final String targetId;
  final double weight;
  final double learningRate;
  final double eligibilityTrace;
  final String targetType;

  const Synapse({
    required this.sourceId,
    required this.targetId,
    required this.weight,
    required this.learningRate,
    this.eligibilityTrace = 0.0,
    required this.targetType,
  });

  Synapse copyWith({
    String? sourceId,
    String? targetId,
    double? weight,
    double? learningRate,
    double? eligibilityTrace,
    String? targetType,
  }) {
    return Synapse(
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      weight: weight ?? this.weight,
      learningRate: learningRate ?? this.learningRate,
      eligibilityTrace: eligibilityTrace ?? this.eligibilityTrace,
      targetType: targetType ?? this.targetType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sourceId': sourceId,
      'targetId': targetId,
      'weight': weight,
      'learningRate': learningRate,
      'eligibilityTrace': eligibilityTrace,
      'targetType': targetType,
    };
  }

  factory Synapse.fromJson(Map<String, dynamic> json) {
    return Synapse(
      sourceId: json['sourceId'] as String,
      targetId: json['targetId'] as String,
      weight: (json['weight'] as num).toDouble(),
      learningRate: (json['learningRate'] as num).toDouble(),
      eligibilityTrace: (json['eligibilityTrace'] as num?)?.toDouble() ?? 0.0,
      targetType: json['targetType'] as String,
    );
  }
}
