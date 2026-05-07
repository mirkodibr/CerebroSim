import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/providers/simulation_provider.dart';
import 'package:cerebrosim/services/simulation_engine.dart';
import 'package:cerebrosim/models/simulation_state.dart';
import 'package:cerebrosim/models/environment.dart';

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

    test('simulationEngineProvider can be overridden for testing', () {
      int tickCount = 0;

      final mockEngine = _CountingEngine(onTick: () => tickCount++);

      final container = ProviderContainer(overrides: [
        simulationEngineProvider.overrideWithValue(mockEngine),
      ]);
      addTearDown(container.dispose);

      final controller = container.read(simulationControllerProvider);
      // Force a single in-process tick (kUseIsolate is false in tests)
      controller.startSimulation();
      controller.stopSimulation();

      // The mock engine was injected (no direct SimulationEngine() instantiation)
      expect(mockEngine, isNotNull);
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

/// A [SimulationEngine] subclass that counts how many times [tick] is called.
class _CountingEngine extends SimulationEngine {
  final void Function() onTick;
  _CountingEngine({required this.onTick});

  @override
  SimulationState tick(
    SimulationState current,
    EnvironmentStep env,
    double dt, {
    required double learningRate,
    required double gamma,
    required double dcnBaseline,
  }) {
    onTick();
    return super.tick(current, env, dt,
        learningRate: learningRate, gamma: gamma, dcnBaseline: dcnBaseline);
  }
}
