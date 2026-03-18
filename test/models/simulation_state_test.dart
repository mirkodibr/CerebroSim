import 'package:flutter_test/flutter_test.dart';
import 'package:cerebrosim/models/neuron.dart';
import 'package:cerebrosim/models/synapse.dart';
import 'package:cerebrosim/models/simulation_state.dart';

void main() {
  group('SimulationState Model Tests', () {
    const neuron1 = Neuron(
      id: 'n1',
      type: 'Granular',
      threshold: 10.0,
      currentPotential: 0.0,
    );
    const synapse1 = Synapse(
      sourceId: 'n1',
      targetId: 'n2',
      weight: 0.5,
      learningRate: 0.01,
      targetType: 'test',
    );

    test('SimulationState should be correctly initialized', () {
      const state = SimulationState(
        neurons: [neuron1],
        synapses: [synapse1],
      );

      expect(state.neurons.length, 1);
      expect(state.synapses.length, 1);
      expect(state.neurons.first.id, 'n1');
      expect(state.synapses.first.sourceId, 'n1');
    });

    test('copyWith should return a new object with updated lists', () {
      const state = SimulationState(
        neurons: [neuron1],
        synapses: [synapse1],
      );

      const neuron2 = Neuron(
        id: 'n2',
        type: 'Purkinje',
        threshold: 20.0,
        currentPotential: 0.0,
      );

      final updatedState = state.copyWith(neurons: [neuron1, neuron2]);

      expect(updatedState.neurons.length, 2);
      expect(updatedState.synapses.length, 1);
    });

    test('toJson and fromJson should be consistent', () {
      const state = SimulationState(
        neurons: [neuron1],
        synapses: [synapse1],
      );

      final json = state.toJson();
      final fromJson = SimulationState.fromJson(json);

      expect(fromJson.neurons.length, state.neurons.length);
      expect(fromJson.synapses.length, state.synapses.length);
      expect(fromJson.neurons.first.id, state.neurons.first.id);
      expect(fromJson.synapses.first.sourceId, state.synapses.first.sourceId);
    });
  });
}
