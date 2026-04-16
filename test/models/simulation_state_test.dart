import 'package:flutter_test/flutter_test.dart';
import 'package:cerebrosim/models/simulation_state.dart';

void main() {
  group('SimulationState Tests', () {
    test('initial factory should create correct structure', () {
      final state = SimulationState.initial();

      // Based on default NetworkConfig (10 GC, 5 BC, 2 PC, 1 SC, 2 DCN) + 1 CF = 21 neurons
      expect(state.neurons.length, 21);
      expect(state.synapses.length, greaterThan(10));
      expect(state.isRunning, false);
      expect(state.episodeStep, 0);
      expect(state.episodeCount, 0);
      
      final cellTypes = state.neurons.values.map((n) => n.cellType).toSet();
      expect(cellTypes.contains('GC'), true);
      expect(cellTypes.contains('PC'), true);
      expect(cellTypes.contains('BC'), true);
      expect(cellTypes.contains('SC'), true);
      expect(cellTypes.contains('DCN'), true);
      expect(cellTypes.contains('CF'), true);

      // Verify the presence of unified DCN IDs
      expect(state.neurons.containsKey('dcn_open'), true);
      expect(state.neurons.containsKey('dcn_close'), true);
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
