import 'package:flutter_test/flutter_test.dart';
import 'package:cerebrosim/models/simulation_state.dart';
import 'package:cerebrosim/models/neuron_model.dart';
import 'package:cerebrosim/models/synapse_model.dart';

void main() {
  group('SimulationState Tests', () {
    test('initial factory should create correct structure', () {
      final state = SimulationState.initial();

      expect(state.neurons.length, 5);
      expect(state.synapses.length, 4);
      expect(state.isRunning, false);
      expect(state.episodeStep, 0);
      expect(state.episodeCount, 0);
      
      final cellTypes = state.neurons.map((n) => n.cellType).toSet();
      expect(cellTypes.contains('GC'), true);
      expect(cellTypes.contains('PC'), true);
      expect(cellTypes.contains('BC'), true);
      expect(cellTypes.contains('DCN'), true);
      expect(cellTypes.contains('CF'), true);
    });

    test('copyWith should return updated state', () {
      final state = SimulationState.initial();
      final updated = state.copyWith(
        isRunning: true,
        episodeCount: 1,
        criticPrediction: 0.5,
      );

      expect(updated.isRunning, true);
      expect(updated.episodeCount, 1);
      expect(updated.criticPrediction, 0.5);
      expect(updated.neurons, state.neurons);
    });
  });
}
