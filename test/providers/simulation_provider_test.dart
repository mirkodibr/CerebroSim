import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/providers/simulation_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Simulation Providers', () {
    test('initial hot and cold states are correct', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final hot = container.read(hotSimulationProvider);
      final cold = container.read(coldSimulationProvider);
      expect(cold.isRunning, false);
      expect(hot.neurons.length, 21);
    });

    test('startSimulation sets isRunning to true in cold state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(simulationControllerProvider);
      controller.startSimulation();

      expect(container.read(coldSimulationProvider).isRunning, true);
    });

    test('stopSimulation sets isRunning to false in cold state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(simulationControllerProvider);
      controller.startSimulation();
      controller.stopSimulation();

      expect(container.read(coldSimulationProvider).isRunning, false);
    });

    test('resetEpisode resets the states', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(simulationControllerProvider);
      controller.startSimulation();
      controller.resetEpisode();

      final hot = container.read(hotSimulationProvider);
      final cold = container.read(coldSimulationProvider);
      expect(cold.isRunning, false);
      expect(hot.episodeStep, 0);
    });
  });
}
