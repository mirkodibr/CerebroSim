import 'package:flutter_test/flutter_test.dart';
import 'package:cerebrosim/services/network_initializer.dart';

void main() {
  group('NetworkInitializer Tests', () {
    test('createRLMockNetwork should create a balanced network', () {
      final state = NetworkInitializer.createRLMockNetwork();
      
      // Check neuron counts
      final pfCount = state.neurons.where((n) => n.type == 'Granular').length;
      final bcCount = state.neurons.where((n) => n.type == 'BC').length;
      final pcCount = state.neurons.where((n) => n.type == 'Purkinje').length;
      final scCount = state.neurons.where((n) => n.type == 'SC').length;
      final dcnCount = state.neurons.where((n) => n.type == 'DCN').length;
      
      expect(pfCount, 10);
      expect(bcCount, 5);
      expect(pcCount, 2);
      expect(scCount, 1);
      expect(dcnCount, 2);
      
      // Check for negative weights from inhibitory cells
      for (final synapse in state.synapses) {
        final source = state.neurons.firstWhere((n) => n.id == synapse.sourceId);
        
        if (source.type == 'BC' || source.type == 'Purkinje') {
          expect(synapse.weight, lessThan(0), reason: 'Synapse from ${source.type} should be inhibitory');
        } else if (source.type == 'Granular') {
          expect(synapse.weight, greaterThan(0), reason: 'Synapse from PF should be excitatory');
        }
      }
      
      // Check for specific synapses
      final pc1InhibitsDcnOpen = state.synapses.any((s) => s.sourceId == 'pc_1' && s.targetId == 'dcn_open');
      final pc2InhibitsDcnClose = state.synapses.any((s) => s.sourceId == 'pc_2' && s.targetId == 'dcn_close');
      
      expect(pc1InhibitsDcnOpen, true);
      expect(pc2InhibitsDcnClose, true);
    });
  });
}
