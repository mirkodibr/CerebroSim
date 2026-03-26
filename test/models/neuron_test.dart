import 'package:flutter_test/flutter_test.dart';
import 'package:cerebrosim/models/neuron_model.dart';

void main() {
  group('NeuronModel Tests', () {
    test('should be correctly initialized', () {
      const neuron = NeuronModel(
        id: 'n1',
        cellType: 'PC',
        threshold: 1.0,
        membranePotential: 0.5,
        decayRate: 0.2,
        isInhibitory: true,
      );

      expect(neuron.id, 'n1');
      expect(neuron.cellType, 'PC');
      expect(neuron.threshold, 1.0);
      expect(neuron.membranePotential, 0.5);
      expect(neuron.decayRate, 0.2);
      expect(neuron.isInhibitory, true);
      expect(neuron.isFiring, false);
    });

    test('initial factory should set correct inhibitory status', () {
      final pc = NeuronModel.initial(id: 'pc1', cellType: 'PC');
      final gc = NeuronModel.initial(id: 'gc1', cellType: 'GC');
      final bc = NeuronModel.initial(id: 'bc1', cellType: 'BC');

      expect(pc.isInhibitory, true);
      expect(gc.isInhibitory, false);
      expect(bc.isInhibitory, true);
      expect(pc.membranePotential, 0.0);
    });

    test('copyWith should return a new object with updated values', () {
      const neuron = NeuronModel(
        id: 'n1',
        cellType: 'GC',
        isInhibitory: false,
      );

      final updated = neuron.copyWith(
        membranePotential: 0.8,
        isFiring: true,
      );

      expect(updated.membranePotential, 0.8);
      expect(updated.isFiring, true);
      expect(updated.id, neuron.id);
      expect(updated.cellType, neuron.cellType);
    });
  });
}
