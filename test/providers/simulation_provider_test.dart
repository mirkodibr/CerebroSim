import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/models/neuron.dart';
import 'package:cerebrosim/models/simulation_state.dart';
import 'package:cerebrosim/providers/simulation_provider.dart';
import 'package:cerebrosim/providers/environment_provider.dart';

void main() {
  group('SimulationNotifier Tests', () {
    test('Should initialize with given state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const initialState = SimulationState(
        neurons: [Neuron(id: 'n1', type: 'G', threshold: 10, currentPotential: 0)],
        synapses: [],
      );

      container.read(simulationProvider.notifier).initialize(initialState);
      
      expect(container.read(simulationProvider), initialState);
    });

    test('tick() should update state using SimulationService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const initialState = SimulationState(
        neurons: [Neuron(id: 'n1', type: 'Granular', threshold: 10, currentPotential: 10)],
        synapses: [],
      );

      container.read(simulationProvider.notifier).initialize(initialState);
      container.read(simulationProvider.notifier).tick();

      // After tick, potential should be reset to 0 because it was at threshold
      expect(container.read(simulationProvider).neurons.first.currentPotential, 0.0);
    });

    test('tick() should advance environment and record history', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const initialState = SimulationState(
        neurons: [
          Neuron(id: 'pf_0', type: 'Granular', threshold: 1, currentPotential: 0),
          Neuron(id: 'pc_1', type: 'Purkinje', threshold: 1, currentPotential: 0),
        ],
        synapses: [],
      );

      container.read(simulationProvider.notifier).initialize(initialState);
      
      // Initially history is empty
      expect(container.read(signalHistoryProvider), isEmpty);
      expect(container.read(environmentProvider).currentStep, 0.0);

      container.read(simulationProvider.notifier).tick();

      // After tick, history should have 1 point and environment should advance by 16ms
      expect(container.read(signalHistoryProvider).length, 1);
      expect(container.read(environmentProvider).currentStep, 16.0);
    });

    test('start() and stop() should toggle isRunning', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(simulationProvider.notifier);
      
      expect(notifier.isRunning, false);
      notifier.start();
      expect(notifier.isRunning, true);
      notifier.stop();
      expect(notifier.isRunning, false);
    });
  });
}
