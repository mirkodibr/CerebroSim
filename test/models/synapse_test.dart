import 'package:flutter_test/flutter_test.dart';
import 'package:cerebrosim/models/synapse_model.dart';

void main() {
  group('SynapseModel Tests', () {
    test('should be correctly initialized', () {
      const synapse = SynapseModel(
        id: 's1',
        fromNeuronId: 'n1',
        toNeuronId: 'n2',
        weight: 0.5,
        eligibility: 0.1,
        isInhibitory: false,
      );

      expect(synapse.id, 's1');
      expect(synapse.fromNeuronId, 'n1');
      expect(synapse.toNeuronId, 'n2');
      expect(synapse.weight, 0.5);
      expect(synapse.eligibility, 0.1);
      expect(synapse.isInhibitory, false);
    });

    test('initial factory should set correct weight based on inhibition', () {
      final exc = SynapseModel.initial(fromId: 'n1', toId: 'n2', isInhibitory: false);
      final inh = SynapseModel.initial(fromId: 'n1', toId: 'n3', isInhibitory: true);

      expect(exc.weight, 0.1);
      expect(inh.weight, -0.1);
      expect(exc.id, 'n1->n2');
    });

    test('copyWith should return a new object with updated values', () {
      final synapse = SynapseModel.initial(fromId: 'n1', toId: 'n2', isInhibitory: false);
      final updated = synapse.copyWith(weight: 0.8, eligibility: 0.5);

      expect(updated.weight, 0.8);
      expect(updated.eligibility, 0.5);
      expect(updated.id, synapse.id);
    });
  });
}
