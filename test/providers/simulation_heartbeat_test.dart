import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/providers/simulation_provider.dart';
import 'package:cerebrosim/providers/episode_history_provider.dart';
import 'package:cerebrosim/providers/environment_provider.dart';
import 'package:cerebrosim/models/cerebellar_task.dart';

void main() {
  testWidgets('Simulation heartbeat records EpisodeRecord when episode completes', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Ensure we are in a task that can complete episodes
    container.read(environmentProvider.notifier).selectTask(CerebellarTask.eyeblink);
    
    // Initial state
    expect(container.read(episodeHistoryProvider), isEmpty);

    container.read(simulationControllerProvider).startSimulation();
    
    // Pump frames to advance the simulation
    for (int i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    
    final currentHistory = container.read(episodeHistoryProvider);
    final hot = container.read(hotSimulationProvider);
    final cold = container.read(coldSimulationProvider);
    print('DEBUG: episodeCount=${cold.episodeCount}, historyLen=${currentHistory.length}, step=${hot.episodeStep}');
    
    container.read(simulationControllerProvider).stopSimulation();
    
    final history = container.read(episodeHistoryProvider);
    expect(history, isNotEmpty, reason: 'Episode history should not be empty after 3s of simulation');
    expect(history.first.episodeNumber, 0);
    expect(history.first.meanPunishment, greaterThanOrEqualTo(0.0));

    // Test reset clears history
    container.read(simulationControllerProvider).resetEpisode();
    expect(container.read(episodeHistoryProvider), isEmpty, reason: 'Reset should clear history');
  });
}
