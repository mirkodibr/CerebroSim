import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/providers/simulation_provider.dart';
import 'package:cerebrosim/providers/plot_buffer_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('SimulationNotifier appends points to PlotRingBuffer on tick', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Initial state check
    expect(container.read(plotBufferProvider), 0);
    expect(container.read(plotRingBufferProvider).filled, 0);

    // Start simulation
    container.read(simulationProvider.notifier).startSimulation();

    // Wait for at least one tick
    await Future.delayed(const Duration(milliseconds: 100));

    // Stop simulation to prevent further ticks
    container.read(simulationProvider.notifier).stopSimulation();

    // The buffer should no longer be empty
    final tick = container.read(plotBufferProvider);
    expect(tick, greaterThan(0));
    expect(container.read(plotRingBufferProvider).filled, greaterThan(0));
    
    final lastCount = tick;
    
    // Wait more - should NOT increase because simulation is stopped
    await Future.delayed(const Duration(milliseconds: 100));
    expect(container.read(plotBufferProvider), equals(lastCount));
  });
}
