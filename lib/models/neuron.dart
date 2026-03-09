class Neuron {
  final String id;
  final String type;
  final double threshold;
  final double currentPotential;
  final double x;
  final double y;

  const Neuron({
    required this.id,
    required this.type,
    required this.threshold,
    required this.currentPotential,
    this.x = 0.0,
    this.y = 0.0,
  });

  Neuron copyWith({
    String? id,
    String? type,
    double? threshold,
    double? currentPotential,
    double? x,
    double? y,
  }) {
    return Neuron(
      id: id ?? this.id,
      type: type ?? this.type,
      threshold: threshold ?? this.threshold,
      currentPotential: currentPotential ?? this.currentPotential,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'threshold': threshold,
      'currentPotential': currentPotential,
      'x': x,
      'y': y,
    };
  }

  factory Neuron.fromJson(Map<String, dynamic> json) {
    return Neuron(
      id: json['id'] as String,
      type: json['type'] as String,
      threshold: (json['threshold'] as num).toDouble(),
      currentPotential: (json['currentPotential'] as num).toDouble(),
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
    );
  }
}