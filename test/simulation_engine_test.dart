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
      
      final nextState = engine.tick(state, env, 0.016);
      
      expect(nextState.episodeStep, state.episodeStep + 1);
    });

    test('isEpisodeEnd: true resets episodeStep to 0 and increments episodeCount', () {
      final state = SimulationState.initial().copyWith(episodeStep: 10, episodeCount: 5);
      const env = EnvironmentStep(stateVector: [1.0], punishment: 0.0, isEpisodeEnd: true);
      
      final nextState = engine.tick(state, env, 0.016);
      
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
      final result = engine.updateWeights([synapse], [neuron], 0.2, 0.01);
      expect(result.first.weight, closeTo(0.101, 0.00001));
    });
  });
}
