import 'package:flutter_test/flutter_test.dart';
import 'package:cerebrosim/models/neuron.dart';
import 'package:cerebrosim/models/synapse.dart';
import 'package:cerebrosim/models/simulation_state.dart';
import 'package:cerebrosim/services/simulation_service.dart';

void main() {
  late SimulationService service;

  setUp(() {
    service = SimulationService();
  });

  group('SimulationService Spiking Logic Tests (with LIF Dynamics)', () {
    test('Neuron below threshold should decay its potential', () {
      const neuron = Neuron(id: 'n1', type: 'Granular', threshold: 10.0, currentPotential: 5.0, decayRate: 0.1);
      const state = SimulationState(neurons: [neuron], synapses: []);

      final nextState = service.calculateNextState(state);

      // 5.0 * (1.0 - 0.1) = 4.5
      expect(nextState.neurons.first.currentPotential, 4.5);
    });

    test('Neuron at threshold should spike and reset potential to baseline', () {
      const neuron = Neuron(id: 'n1', type: 'Granular', threshold: 10.0, currentPotential: 10.0);
      const state = SimulationState(neurons: [neuron], synapses: []);

      final nextState = service.calculateNextState(state);

      expect(nextState.neurons.first.currentPotential, 0.0);
    });

    test('Spiking neuron should propagate potential through synapse to target', () {
      const source = Neuron(id: 'n1', type: 'Granular', threshold: 10.0, currentPotential: 10.0);
      const target = Neuron(id: 'n2', type: 'Purkinje', threshold: 20.0, currentPotential: 0.0);
      const synapse = Synapse(sourceId: 'n1', targetId: 'n2', weight: 5.0, learningRate: 0.01, targetType: 'test');
      
      const state = SimulationState(neurons: [source, target], synapses: [synapse]);

      final nextState = service.calculateNextState(state);

      final nextTarget = nextState.neurons.firstWhere((n) => n.id == 'n2');
      // target potential was 0.0, next is 5.0
      expect(nextTarget.currentPotential, 5.0);
      
      final nextSource = nextState.neurons.firstWhere((n) => n.id == 'n1');
      expect(nextSource.currentPotential, 0.0);
    });

    test('Eligibility traces should decay and be reinforced by spikes', () {
      const s1 = Neuron(id: 's1', type: 'G', threshold: 5.0, currentPotential: 5.0); // Spikes
      const s2 = Neuron(id: 's2', type: 'G', threshold: 5.0, currentPotential: 0.0); // Doesn't spike
      const target = Neuron(id: 't', type: 'P', threshold: 20.0, currentPotential: 0.0);
      
      const syn1 = Synapse(sourceId: 's1', targetId: 't', weight: 1.0, learningRate: 0.1, eligibilityTrace: 1.0, targetType: 'test');
      const syn2 = Synapse(sourceId: 's2', targetId: 't', weight: 1.0, learningRate: 0.1, eligibilityTrace: 1.0, targetType: 'test');

      const state = SimulationState(neurons: [s1, s2, target], synapses: [syn1, syn2]);

      final nextState = service.calculateNextState(state);

      final nextSyn1 = nextState.synapses.firstWhere((s) => s.sourceId == 's1');
      final nextSyn2 = nextState.synapses.firstWhere((s) => s.sourceId == 's2');

      // syn1: (1.0 * 0.95) + 1.0 = 1.95
      expect(nextSyn1.eligibilityTrace, closeTo(1.95, 0.001));
      // syn2: (1.0 * 0.95) = 0.95
      expect(nextSyn2.eligibilityTrace, closeTo(0.95, 0.001));
    });

    test('Multiple source neurons should sum their potential on target after decay', () {
      const s1 = Neuron(id: 's1', type: 'G', threshold: 5.0, currentPotential: 5.0);
      const s2 = Neuron(id: 's2', type: 'G', threshold: 5.0, currentPotential: 5.0);
      // Target doesn't spike, so it decays. 2.0 * (1 - 0.1) = 1.8
      const target = Neuron(id: 't', type: 'P', threshold: 20.0, currentPotential: 2.0, decayRate: 0.1);
      
      const syn1 = Synapse(sourceId: 's1', targetId: 't', weight: 3.0, learningRate: 0.1, targetType: 'test');
      const syn2 = Synapse(sourceId: 's2', targetId: 't', weight: 4.0, learningRate: 0.1, targetType: 'test');

      const state = SimulationState(neurons: [s1, s2, target], synapses: [syn1, syn2]);

      final nextState = service.calculateNextState(state);

      final nextTarget = nextState.neurons.firstWhere((n) => n.id == 't');
      // 1.8 (decayed) + 3.0 (from s1) + 4.0 (from s2) = 8.8
      expect(nextTarget.currentPotential, closeTo(8.8, 0.001));
    });
  });

  group('SimulationService adjustWeights (Climbing Fiber) Tests', () {
    test('Weights should decrease (LTD) when neuron spikes but target is false', () {
      const source = Neuron(id: 's', type: 'G', threshold: 5.0, currentPotential: 5.0);
      const target = Neuron(id: 'p', type: 'P', threshold: 10.0, currentPotential: 10.0);
      const synapse = Synapse(sourceId: 's', targetId: 'p', weight: 1.0, learningRate: 0.1, targetType: 'test');

      final state = SimulationState(neurons: [source, target], synapses: [synapse]);

      // Target says it SHOULD NOT spike, but it IS spiking (potential 10.0 >= threshold 10.0)
      final nextState = service.adjustWeights(state, purkinjeId: 'p', targetSignal: false);

      expect(nextState.synapses.first.weight, 0.9); // 1.0 - 0.1
    });

    test('Weights should increase when neuron does not spike but target is true', () {
      const source = Neuron(id: 's', type: 'G', threshold: 5.0, currentPotential: 5.0);
      const target = Neuron(id: 'p', type: 'P', threshold: 10.0, currentPotential: 0.0);
      const synapse = Synapse(sourceId: 's', targetId: 'p', weight: 1.0, learningRate: 0.1, targetType: 'test');

      final state = SimulationState(neurons: [source, target], synapses: [synapse]);

      // Target says it SHOULD spike, but it IS NOT spiking (potential 0.0 < threshold 10.0)
      final nextState = service.adjustWeights(state, purkinjeId: 'p', targetSignal: true);

      expect(nextState.synapses.first.weight, 1.1); // 1.0 + 0.1
    });

    test('Weights should not change when output matches target', () {
      const source = Neuron(id: 's', type: 'G', threshold: 5.0, currentPotential: 5.0);
      const target = Neuron(id: 'p', type: 'P', threshold: 10.0, currentPotential: 10.0);
      const synapse = Synapse(sourceId: 's', targetId: 'p', weight: 1.0, learningRate: 0.1, targetType: 'test');

      final state = SimulationState(neurons: [source, target], synapses: [synapse]);

      // Spiking matches target (true)
      final nextState = service.adjustWeights(state, purkinjeId: 'p', targetSignal: true);

      expect(nextState.synapses.first.weight, 1.0);
    });

    test('Weight should only change if source neuron was active', () {
      const source = Neuron(id: 's', type: 'G', threshold: 5.0, currentPotential: 0.0); // NOT ACTIVE
      const target = Neuron(id: 'p', type: 'P', threshold: 10.0, currentPotential: 10.0);
      const synapse = Synapse(sourceId: 's', targetId: 'p', weight: 1.0, learningRate: 0.1, targetType: 'test');

      final state = SimulationState(neurons: [source, target], synapses: [synapse]);

      // Spiking (true) != target (false), but source was NOT active
      final nextState = service.adjustWeights(state, purkinjeId: 'p', targetSignal: false);

      expect(nextState.synapses.first.weight, 1.0); // No change
    });
  });
}
