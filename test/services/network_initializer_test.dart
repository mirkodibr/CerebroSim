import 'package:flutter_test/flutter_test.dart';
import 'package:cerebrosim/services/network_initializer.dart';

void main() {
  group('NetworkInitializer Tests', () {
    test('createRLMockNetwork should create a balanced network', () {
      final state = NetworkInitializer.createRLMockNetwork();
      
      // Check neuron counts
      final pfCount = state.neurons.values.where((n) => n.cellType == 'GC').length;
      final bcCount = state.neurons.values.where((n) => n.cellType == 'BC').length;
      final pcCount = state.neurons.values.where((n) => n.cellType == 'PC').length;
      final scCount = state.neurons.values.where((n) => n.cellType == 'SC').length;
      final dcnCount = state.neurons.values.where((n) => n.cellType == 'DCN').length;
      
      expect(pfCount, 10);
      expect(bcCount, 5);
      expect(pcCount, 2);
      expect(scCount, 1);
      expect(dcnCount, 2);
      
      // Check for negative weights from inhibitory cells
      for (final synapse in state.synapses) {
        final source = state.neurons[synapse.fromNeuronId]!;
        
        if (source.cellType == 'BC' || source.cellType == 'PC') {
          expect(synapse.weight, lessThan(0), reason: 'Synapse from ${source.cellType} should be inhibitory');
        } else if (source.cellType == 'GC') {
          expect(synapse.weight, greaterThan(0), reason: 'Synapse from PF should be excitatory');
        }
      }
      
      // Check for specific synapses - more robustly
      final pcToDcnSynapses = state.synapses.where((s) {
        final from = state.neurons[s.fromNeuronId]!;
        final to = state.neurons[s.toNeuronId]!;
        return from.cellType == 'PC' && to.cellType == 'DCN';
      }).toList();
      
      expect(pcToDcnSynapses.isNotEmpty, true, reason: 'Should have at least one PC -> DCN synapse');
      for (final s in pcToDcnSynapses) {
        expect(s.isInhibitory, true, reason: 'PC -> DCN synapses must be inhibitory');
        expect(s.weight, lessThan(0));
      }

      // Check for CF neuron
      final cfCount = state.neurons.values.where((n) => n.cellType == 'CF').length;
      expect(cfCount, 1);
    });
  });
}
