class Neuron {
  final String id;
  final String type;
  final double threshold;
  final double currentPotential;

  const Neuron({
    required this.id,
    required this.type,
    required this.threshold,
    required this.currentPotential,
  });

  Neuron copyWith({
    String? id,
    String? type,
    double? threshold,
    double? currentPotential,
  }) {
    return Neuron(
      id: id ?? this.id,
      type: type ?? this.type,
      threshold: threshold ?? this.threshold,
      currentPotential: currentPotential ?? this.currentPotential,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'threshold': threshold,
      'currentPotential': currentPotential,
    };
  }

  factory Neuron.fromJson(Map<String, dynamic> json) {
    return Neuron(
      id: json['id'] as String,
      type: json['type'] as String,
      threshold: (json['threshold'] as num).toDouble(),
      currentPotential: (json['currentPotential'] as num).toDouble(),
    );
  }
}