import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/providers/simulation_provider.dart';
import 'package:cerebrosim/models/cold_sim_state.dart';
import 'package:cerebrosim/models/hot_sim_state.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('SimulationNotifier', () {
    test('initial state is correct', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(simulationProvider);
      expect(state.isRunning, false);
      expect(state.neurons.isNotEmpty, true);
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

  group('coldSimulationProvider', () {
    test('reflects isRunning from simulationProvider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(coldSimulationProvider).isRunning, false);
      container.read(simulationProvider.notifier).startSimulation();
      expect(container.read(coldSimulationProvider).isRunning, true);
    });

    test('ColdSimState equality prevents spurious rebuilds', () {
      final a = ColdSimState(isRunning: false, episodeCount: 0, speedMultiplier: 1.0);
      final b = ColdSimState(isRunning: false, episodeCount: 0, speedMultiplier: 1.0);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('ColdSimState inequality detected correctly', () {
      final a = ColdSimState(isRunning: false, episodeCount: 0, speedMultiplier: 1.0);
      final b = ColdSimState(isRunning: true, episodeCount: 0, speedMultiplier: 1.0);
      expect(a, isNot(equals(b)));
    });
  });

  group('hotSimulationProvider', () {
    test('returns HotSimState with initial values', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final hot = container.read(hotSimulationProvider);
      expect(hot, isA<HotSimState>());
      expect(hot.tdError, isA<double>());
      expect(hot.neurons.isNotEmpty, true);
    });
  });

  group('SimulationController', () {
    test('facade delegates start/pause/stop correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(simulationControllerProvider);
      controller.startSimulation();
      expect(container.read(coldSimulationProvider).isRunning, true);

      controller.pauseSimulation();
      expect(container.read(coldSimulationProvider).isRunning, false);
    });

    test('setSpeed updates speedMultiplier', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(simulationControllerProvider).setSpeed(5.0);
      expect(container.read(coldSimulationProvider).speedMultiplier, 5.0);
    });
  });
}
