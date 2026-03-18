import 'package:flutter_test/flutter_test.dart';
import 'package:cerebrosim/models/neuron.dart';

void main() {
  group('Neuron Model Tests', () {
    test('Neuron should be correctly initialized', () {
      const neuron = Neuron(
        id: 'n1',
        type: 'Purkinje',
        threshold: 15.0,
        currentPotential: 0.0,
        decayRate: 0.2,
        actionGroup: 'motor_x',
      );

      expect(neuron.id, 'n1');
      expect(neuron.type, 'Purkinje');
      expect(neuron.threshold, 15.0);
      expect(neuron.currentPotential, 0.0);
      expect(neuron.decayRate, 0.2);
      expect(neuron.actionGroup, 'motor_x');
    });

    test('Neuron should have default decayRate', () {
      const neuron = Neuron(
        id: 'n1',
        type: 'Purkinje',
        threshold: 15.0,
        currentPotential: 0.0,
      );
      expect(neuron.decayRate, 0.1);
      expect(neuron.actionGroup, isNull);
    });

    test('copyWith should return a new object with updated values', () {
      const neuron = Neuron(
        id: 'n1',
        type: 'Purkinje',
        threshold: 15.0,
        currentPotential: 0.0,
      );

      final updatedNeuron = neuron.copyWith(
        currentPotential: 5.0,
        decayRate: 0.3,
        actionGroup: 'motor_y',
      );

      expect(updatedNeuron.currentPotential, 5.0);
      expect(updatedNeuron.decayRate, 0.3);
      expect(updatedNeuron.actionGroup, 'motor_y');
      expect(updatedNeuron.id, neuron.id);
      expect(updatedNeuron.type, neuron.type);
      expect(updatedNeuron.threshold, neuron.threshold);
    });

    test('toJson and fromJson should be consistent', () {
      const neuron = Neuron(
        id: 'n1',
        type: 'Purkinje',
        threshold: 15.0,
        currentPotential: 0.0,
        decayRate: 0.2,
        actionGroup: 'motor_x',
      );

      final json = neuron.toJson();
      final fromJson = Neuron.fromJson(json);

      expect(fromJson.id, neuron.id);
      expect(fromJson.type, neuron.type);
      expect(fromJson.threshold, neuron.threshold);
      expect(fromJson.currentPotential, neuron.currentPotential);
      expect(fromJson.decayRate, neuron.decayRate);
      expect(fromJson.actionGroup, neuron.actionGroup);
    });
  });
}
