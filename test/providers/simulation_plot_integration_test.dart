import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/providers/simulation_provider.dart';
import 'package:cerebrosim/providers/plot_buffer_provider.dart';

void main() {
  testWidgets('SimulationController appends points to PlotRingBuffer on tick', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Initial state check
    expect(container.read(plotBufferProvider), 0);
    expect(container.read(plotRingBufferProvider).filled, 0);

    // Start simulation
    container.read(simulationControllerProvider).startSimulation();

    // Pump a few frames
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    // The buffer should no longer be empty
    final tick = container.read(plotBufferProvider);
    expect(tick, greaterThan(0));
    expect(container.read(plotRingBufferProvider).filled, greaterThan(0));
    
    final lastCount = tick;
    
    // Stop simulation
    container.read(simulationControllerProvider).stopSimulation();

    // Wait more - should NOT increase
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(plotBufferProvider), equals(lastCount));
  });
}
