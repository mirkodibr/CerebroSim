import 'neuron.dart';
import 'synapse.dart';

class SimulationState {
  final List<Neuron> neurons;
  final List<Synapse> synapses;

  const SimulationState({
    required this.neurons,
    required this.synapses,
  });

  SimulationState copyWith({
    List<Neuron>? neurons,
    List<Synapse>? synapses,
  }) {
    return SimulationState(
      neurons: neurons ?? this.neurons,
      synapses: synapses ?? this.synapses,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'neurons': neurons.map((n) => n.toJson()).toList(),
      'synapses': synapses.map((s) => s.toJson()).toList(),
    };
  }

  factory SimulationState.fromJson(Map<String, dynamic> json) {
    return SimulationState(
      neurons: (json['neurons'] as List<dynamic>)
          .map((n) => Neuron.fromJson(n as Map<String, dynamic>))
          .toList(),
      synapses: (json['synapses'] as List<dynamic>)
          .map((s) => Synapse.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
