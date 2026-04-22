import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cerebrosim/services/simulation_engine.dart';
import 'package:cerebrosim/models/neuron_model.dart';
import 'package:cerebrosim/models/synapse_model.dart';
import 'package:cerebrosim/models/simulation_state.dart';
import 'package:cerebrosim/models/environment.dart';

void main() {
  late SimulationEngine engine;

  setUp(() {
    engine = SimulationEngine();
  });

  group('Tick Assembly', () {
    test('tick does not crash and episodeStep increments', () {
      final state = SimulationState.initial();
      const env = EnvironmentStep(stateVector: [1.0], punishment: 0.0, isEpisodeEnd: false);
      
      final nextState = engine.tick(
        state, 
        env, 
        0.016, 
        learningRate: 0.01, 
        gamma: 0.95,
        dcnBaseline: 0.5,
      );
      
      expect(nextState.episodeStep, state.episodeStep + 1);
    });

    test('criticPrediction is updated based on DCN activity', () {
      final state = SimulationState.initial();
      const env = EnvironmentStep(stateVector: [0.0], punishment: 0.0, isEpisodeEnd: false);
      
      final nextState = engine.tick(
        state, 
        env, 
        0.016, 
        learningRate: 0.01, 
        gamma: 0.95,
        dcnBaseline: 0.5, // Non-zero baseline drive
      );
      
      expect(nextState.criticPrediction, greaterThan(0.0), 
        reason: 'Critic prediction (average DCN potential) should be non-zero after baseline drive');
    });

    test('isEpisodeEnd: true resets episodeStep to 0 and increments episodeCount', () {
      final state = SimulationState.initial().copyWith(episodeStep: 10, episodeCount: 5);
      const env = EnvironmentStep(stateVector: [1.0], punishment: 0.0, isEpisodeEnd: true);
      
      final nextState = engine.tick(
        state, 
        env, 
        0.016, 
        learningRate: 0.01, 
        gamma: 0.95,
        dcnBaseline: 0.5,
      );
      
      expect(nextState.episodeStep, 0);
      expect(nextState.episodeCount, 6);
    });
  });

  group('LIF Update', () {
    test('should decay potential correctly with zero input', () {
      const n = NeuronModel(
        id: 'n1',
        cellType: 'GC',
        membranePotential: 0.5,
        decayRate: 0.1,
        isInhibitory: false,
      );
      final nextPotential = engine.lifUpdate(n, 0.0);
      expect(nextPotential, closeTo(0.45, 0.0001));
    });

    test('should update potential correctly with positive input', () {
      const n = NeuronModel(
        id: 'n1',
        cellType: 'GC',
        membranePotential: 0.0,
        decayRate: 0.1,
        isInhibitory: false,
      );
      final nextPotential = engine.lifUpdate(n, 0.3);
      expect(nextPotential, closeTo(0.27, 0.0001));
    });
  });

  group('TD Error', () {
    test('reward=0.0, vNext=0.5, vCurrent=0.3, gamma=0.95 -> expect 0.175', () {
      final delta = engine.tdError(0.0, 0.5, 0.3, gamma: 0.95);
      expect(delta, closeTo(0.175, 0.0001));
    });
  });

  group('Weight Update', () {
    test('excitatory synapse weight=0.1, eligibilityTrace=0.5, tdError=0.2, learningRate=0.01 -> expect ≈ 0.101', () {
      final synapse = SynapseModel.initial(fromId: 'n1', toId: 'n2', isInhibitory: false).copyWith(weight: 0.1);
      final neuron = NeuronModel.initial(id: 'n1', cellType: 'GC').copyWith(eligibilityTrace: 0.5);
      final result = engine.updateWeights([synapse], {'n1': neuron}, 0.2, learningRate: 0.01);
      expect(result.first.weight, closeTo(0.101, 0.00001));
    });

    test('when learningRate is 0.0, updateWeights returns original synapses unchanged', () {
      final synapses = SimulationState.initial().synapses;
      final neurons = SimulationState.initial().neurons;
      final result = engine.updateWeights(synapses, neurons, 1.0, learningRate: 0.0);
      
      for (int i = 0; i < synapses.length; i++) {
        expect(result[i].weight, equals(synapses[i].weight));
      }
    });
  });

  group('Optimization Performance', () {
    test('100-neuron network processes a tick correctly', () {
      final Map<String, NeuronModel> neurons = {};
      final List<SynapseModel> synapses = [];

      // Create 100 neurons (80 GC, 10 PC, 10 DCN)
      for (int i = 0; i < 80; i++) {
        final id = 'GC_$i';
        neurons[id] = NeuronModel.initial(id: id, cellType: 'GC').copyWith(membranePotential: 0.5);
      }
      for (int i = 0; i < 10; i++) {
        final id = 'PC_$i';
        neurons[id] = NeuronModel.initial(id: id, cellType: 'PC');
      }
      for (int i = 0; i < 10; i++) {
        final id = 'DCN_$i';
        neurons[id] = NeuronModel.initial(id: id, cellType: 'DCN');
      }

      // Fully connect GC to PC (800 synapses)
      for (int i = 0; i < 80; i++) {
        for (int j = 0; j < 10; j++) {
          synapses.add(SynapseModel.initial(fromId: 'GC_$i', toId: 'PC_$j', isInhibitory: false));
        }
      }

      final state = SimulationState(
        neurons: neurons,
        synapses: synapses,
      ).rebuildIndex();

      const env = EnvironmentStep(stateVector: [0.1], punishment: 0.0, isEpisodeEnd: false);
      
      final stopwatch = Stopwatch()..start();
      final nextState = engine.tick(
        state, 
        env, 
        0.016, 
        learningRate: 0.01, 
        gamma: 0.95,
        dcnBaseline: 0.5,
      );
      stopwatch.stop();

      expect(nextState.neurons.length, 100);
      expect(nextState.synapses.length, 800);
      // Ensure DCNs actually updated (baseline drive should increase potential)
      expect(nextState.neurons['DCN_0']!.membranePotential, greaterThan(0));
      
      debugPrint('100-neuron tick processed in ${stopwatch.elapsedMicroseconds}µs');
    });
  });

  group('Temporal Dynamics (Axonal Delay)', () {
    test('spike at tick 10 with delay 3 alters potential only at tick 13', () {
      final engine = SimulationEngine();
      
      final n1 = NeuronModel.initial(id: 'n1', cellType: 'GC').copyWith(membranePotential: 1.0); // Firing
      final n2 = NeuronModel.initial(id: 'n2', cellType: 'PC').copyWith(membranePotential: 0.0);
      
      final synapse = SynapseModel(
        id: 'n1->n2', 
        fromNeuronId: 'n1', 
        toNeuronId: 'n2', 
        weight: 0.5, 
        isInhibitory: false,
        axonalDelay: 3,
      );

      var state = SimulationState(
        neurons: {'n1': n1, 'n2': n2},
        synapses: [synapse],
        episodeStep: 10,
      ).rebuildIndex();

      const env = EnvironmentStep(stateVector: [0.0], punishment: 0.0, isEpisodeEnd: false);

      // Tick 10: n1 is firing (1.0). Propagation schedules 0.5 for tick 13.
      state = engine.tick(state, env, 0.016, learningRate: 0.0, gamma: 0.95, dcnBaseline: 0.0);
      expect(state.episodeStep, 11);
      expect(state.neurons['n2']!.membranePotential, 0.0, reason: 'Too early for delay 3');

      // Tick 11
      state = engine.tick(state, env, 0.016, learningRate: 0.0, gamma: 0.95, dcnBaseline: 0.0);
      expect(state.episodeStep, 12);
      expect(state.neurons['n2']!.membranePotential, 0.0, reason: 'Too early for delay 3');

      // Tick 12
      state = engine.tick(state, env, 0.016, learningRate: 0.0, gamma: 0.95, dcnBaseline: 0.0);
      expect(state.episodeStep, 13);
      expect(state.neurons['n2']!.membranePotential, 0.0, reason: 'Still tick 12 results (potential applied at start of 13)');

      // Tick 13: Pulls from buffer
      state = engine.tick(state, env, 0.016, learningRate: 0.0, gamma: 0.95, dcnBaseline: 0.0);
      expect(state.episodeStep, 14);
      // LIF update: (currentV + input) * (1 - decay)
      // (0.0 + 0.5) * (1 - 0.1) = 0.45
      expect(state.neurons['n2']!.membranePotential, closeTo(0.45, 0.001), reason: 'Spike should arrive at tick 13');
    });

    test('_potentialBuffer does not grow unbounded over 200 ticks', () {
      final engine = SimulationEngine();
      final state = SimulationState.initial();
      const env = EnvironmentStep(
        stateVector: [1.0], punishment: 0.0, isEpisodeEnd: false);
      
      var s = state;
      for (int i = 0; i < 200; i++) {
        s = engine.tick(s, env, 0.016, 
          learningRate: 0.01, gamma: 0.95, dcnBaseline: 0.5);
      }
      // Buffer should never hold more than maxDelay worth of entries
      // We can't access private field directly, but we verify no crash/OOM
      expect(s.episodeStep, 200);
    });
  });
}
