import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/providers/simulation_provider.dart';

void main() {
  group('SimulationNotifier', () {
    test('initial state is correct', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(simulationProvider);
      expect(state.isRunning, false);
      expect(state.neurons.length, 5);
    });

    test('startSimulation sets isRunning to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(simulationProvider.notifier);
      notifier.startSimulation();

      expect(container.read(simulationProvider).isRunning, true);
    });

    test('stopSimulation sets isRunning to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(simulationProvider.notifier);
      notifier.startSimulation();
      notifier.stopSimulation();

      expect(container.read(simulationProvider).isRunning, false);
    });

    test('resetEpisode resets the state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(simulationProvider.notifier);
      notifier.startSimulation();
      notifier.resetEpisode();

      final state = container.read(simulationProvider);
      expect(state.isRunning, false);
      expect(state.episodeStep, 0);
    });
  });
}
