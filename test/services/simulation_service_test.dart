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

      expect(nextSyn1.eligibilityTrace, closeTo(1.95, 0.001));
      expect(nextSyn2.eligibilityTrace, closeTo(0.95, 0.001));
    });

    test('DCN neurons should receive baseline excitatory drive', () {
      const dcn = Neuron(id: 'd1', type: 'DCN', threshold: 10.0, currentPotential: 2.0, decayRate: 0.1);
      const state = SimulationState(neurons: [dcn], synapses: []);

      final nextState = service.calculateNextState(state);

      // (2.0 * 0.9) + 0.5 = 1.8 + 0.5 = 2.3
      expect(nextState.neurons.first.currentPotential, closeTo(2.3, 0.001));
    });

    test('DCN neurons should receive baseline drive even after spiking', () {
      const dcn = Neuron(id: 'd1', type: 'DCN', threshold: 5.0, currentPotential: 5.0);
      const state = SimulationState(neurons: [dcn], synapses: []);

      final nextState = service.calculateNextState(state);

      // Reset to 0.0 + 0.5 = 0.5
      expect(nextState.neurons.first.currentPotential, 0.5);
    });

    test('Inhibitory synapse (negative weight) should subtract potential from target', () {
      const source = Neuron(id: 'bc', type: 'BC', threshold: 2.0, currentPotential: 2.0);
      const target = Neuron(id: 'pc', type: 'Purkinje', threshold: 10.0, currentPotential: 5.0, decayRate: 0.0);
      const synapse = Synapse(sourceId: 'bc', targetId: 'pc', weight: -1.5, learningRate: 0.0, targetType: 'PC');
      
      final state = SimulationState(neurons: [source, target], synapses: [synapse]);

      final nextState = service.calculateNextState(state);

      final nextTarget = nextState.neurons.firstWhere((n) => n.id == 'pc');
      // 5.0 (initial) - 1.5 (inhibitory weight) = 3.5
      expect(nextTarget.currentPotential, 3.5);
    });
  });

  group('SimulationService Actor-Critic Learning (adjustWeightsRL) Tests', () {
    test('Critic (SC) weights should increase when predicted punishment is too low', () {
      // predictedPunishment = potential of all 'SC' = 0.5
      const sc = Neuron(id: 'sc', type: 'SC', threshold: 10, currentPotential: 0.5);
      // synapse to SC with active trace
      const syn = Synapse(
        sourceId: 'pf', 
        targetId: 'sc', 
        weight: 0.5, 
        learningRate: 0.1, 
        eligibilityTrace: 1.0, 
        targetType: 'SC'
      );
      
      final state = SimulationState(neurons: [sc], synapses: [syn]);
      
      // climbingFiberPunishment = 1.0 (actual)
      // tdError = 1.0 - 0.5 = 0.5
      // newWeight = 0.5 + (0.1 * 0.5 * 1.0) = 0.55
      final nextState = service.adjustWeightsRL(state, climbingFiberPunishment: 1.0);
      
      expect(nextState.synapses.first.weight, closeTo(0.55, 0.001));
    });

    test('Actor (PC) weights should decrease (LTD) when punishment occurs', () {
      // predictedPunishment = 0 (no SC)
      const pc = Neuron(id: 'pc', type: 'PC', threshold: 10, currentPotential: 0.1);
      const syn = Synapse(
        sourceId: 'pf', 
        targetId: 'pc', 
        weight: 0.5, 
        learningRate: 0.1, 
        eligibilityTrace: 1.0, 
        targetType: 'PC'
      );
      
      final state = SimulationState(neurons: [pc], synapses: [syn]);
      
      // tdError = 1.0 - 0.0 = 1.0
      // newWeight = 0.5 - (0.1 * 1.0 * 1.0) = 0.4
      final nextState = service.adjustWeightsRL(state, climbingFiberPunishment: 1.0);
      
      expect(nextState.synapses.first.weight, closeTo(0.4, 0.001));
    });

    test('Weights should not change if eligibility trace is near zero', () {
      const sc = Neuron(id: 'sc', type: 'SC', threshold: 10, currentPotential: 0.0);
      const syn = Synapse(
        sourceId: 'pf', 
        targetId: 'sc', 
        weight: 0.5, 
        learningRate: 0.1, 
        eligibilityTrace: 0.005, // < 0.01
        targetType: 'SC'
      );
      
      final state = SimulationState(neurons: [sc], synapses: [syn]);
      final nextState = service.adjustWeightsRL(state, climbingFiberPunishment: 1.0);
      
      expect(nextState.synapses.first.weight, 0.5);
    });

    test('Weights should be clamped between 0.0 and 1.0', () {
      const pc = Neuron(id: 'pc', type: 'PC', threshold: 10, currentPotential: 0.0);
      const syn = Synapse(
        sourceId: 'pf', 
        targetId: 'pc', 
        weight: 0.05, 
        learningRate: 0.1, 
        eligibilityTrace: 1.0, 
        targetType: 'PC'
      );
      
      final state = SimulationState(neurons: [pc], synapses: [syn]);
      
      // newWeight = 0.05 - (0.1 * 1.0 * 1.0) = -0.05 -> clamped to 0.0
      final nextState = service.adjustWeightsRL(state, climbingFiberPunishment: 1.0);
      
      expect(nextState.synapses.first.weight, 0.0);
    });
  });

  group('SimulationService getExecutedAction Tests', () {
    test('Should return the action group of the DCN with highest potential', () {
      const dcn1 = Neuron(id: 'd1', type: 'DCN', threshold: 1, currentPotential: 0.5, actionGroup: 'antiopen');
      const dcn2 = Neuron(id: 'd2', type: 'DCN', threshold: 1, currentPotential: 0.8, actionGroup: 'anticlose');
      const other = Neuron(id: 'o', type: 'PC', threshold: 1, currentPotential: 1.0, actionGroup: 'wrong');
      
      final state = SimulationState(neurons: [dcn1, dcn2, other], synapses: []);
      
      expect(service.getExecutedAction(state), 'anticlose');
    });

    test('Should return none if no DCN neurons exist', () {
      const other = Neuron(id: 'o', type: 'PC', threshold: 1, currentPotential: 1.0, actionGroup: 'wrong');
      final state = SimulationState(neurons: [other], synapses: []);
      
      expect(service.getExecutedAction(state), 'none');
    });

    test('Should return none if all DCN potentials are 0', () {
      const dcn1 = Neuron(id: 'd1', type: 'DCN', threshold: 1, currentPotential: 0.0, actionGroup: 'antiopen');
      final state = SimulationState(neurons: [dcn1], synapses: []);
      
      expect(service.getExecutedAction(state), 'none');
    });
  });
}
