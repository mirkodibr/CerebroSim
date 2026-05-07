import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/providers/simulation_provider.dart';
import 'package:cerebrosim/providers/plot_buffer_provider.dart';

void main() {
  test('SimulationNotifier pushes data into plotRingBuffer on tick', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Initial state — ring buffer is empty and tick counter is 0.
    expect(container.read(plotRingBufferProvider).filled, equals(0));
    expect(container.read(plotBufferProvider), equals(0));

    // Start simulation
    container.read(simulationProvider.notifier).startSimulation();

    // Wait for at least one tick (~16.6ms at 60 Hz)
    await Future.delayed(const Duration(milliseconds: 100));

    // Stop simulation to prevent further ticks
    container.read(simulationProvider.notifier).stopSimulation();

    // Ring buffer must have received data
    expect(container.read(plotRingBufferProvider).filled, greaterThan(0));
    expect(container.read(plotBufferProvider), greaterThan(0));

    final lastTick = container.read(plotBufferProvider);

    // Wait more — counter should NOT increase because simulation is stopped
    await Future.delayed(const Duration(milliseconds: 100));
    expect(container.read(plotBufferProvider), equals(lastTick));
  });
}
