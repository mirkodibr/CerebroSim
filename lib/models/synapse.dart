class Synapse {
  final String sourceId;
  final String targetId;
  final double weight;
  final double learningRate;

  const Synapse({
    required this.sourceId,
    required this.targetId,
    required this.weight,
    required this.learningRate,
  });

  Synapse copyWith({
    String? sourceId,
    String? targetId,
    double? weight,
    double? learningRate,
  }) {
    return Synapse(
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      weight: weight ?? this.weight,
      learningRate: learningRate ?? this.learningRate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sourceId': sourceId,
      'targetId': targetId,
      'weight': weight,
      'learningRate': learningRate,
    };
  }

  factory Synapse.fromJson(Map<String, dynamic> json) {
    return Synapse(
      sourceId: json['sourceId'] as String,
      targetId: json['targetId'] as String,
      weight: (json['weight'] as num).toDouble(),
      learningRate: (json['learningRate'] as num).toDouble(),
    );
  }
}