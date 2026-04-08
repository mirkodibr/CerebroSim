import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/providers/simulation_provider.dart';
import 'package:cerebrosim/providers/episode_history_provider.dart';
import 'package:cerebrosim/providers/environment_provider.dart';
import 'package:cerebrosim/models/cerebellar_task.dart';

void main() {
  test('Simulation heartbeat records EpisodeRecord when episode completes', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Ensure we are in a task that can complete episodes
    container.read(environmentProvider.notifier).selectTask(CerebellarTask.eyeblink);
    
    // Initial state
    expect(container.read(episodeHistoryProvider), isEmpty);

    // Start simulation and wait for an episode to complete
    // Eyeblink episode is 1 second. With kTickRateHz=60, that's 60 ticks.
    // We can't wait 1s in a unit test easily without fake time, 
    // but SimulationNotifier uses a real Timer.
    // Alternatively, we can use fakeAsync if needed, but let's try a short wait first
    // or manually trigger ticks if possible (but _tick is private).
    
    // Since _tick is private and uses real timer, we'll use a small delay 
    // and hope for the best, or better, use a more controlled approach.
    // For now, let's just start and wait a bit more than 1s.
    
    container.read(simulationProvider.notifier).startSimulation();
    
    // Wait for ~1.5 seconds to ensure at least one episode completes
    await Future.delayed(const Duration(milliseconds: 1500));
    
    container.read(simulationProvider.notifier).stopSimulation();
    
    final history = container.read(episodeHistoryProvider);
    expect(history, isNotEmpty, reason: 'Episode history should not be empty after 1.5s of simulation');
    expect(history.first.episodeNumber, 0);
    expect(history.first.meanPunishment, greaterThanOrEqualTo(0.0));

    // Test reset clears history
    container.read(simulationProvider.notifier).resetEpisode();
    expect(container.read(episodeHistoryProvider), isEmpty, reason: 'Reset should clear history');
  });
}
