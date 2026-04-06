import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/providers/simulation_provider.dart';
import 'package:cerebrosim/providers/plot_buffer_provider.dart';
import 'package:cerebrosim/models/simulation_constants.dart';

void main() {
  test('SimulationNotifier appends PlotPoint to plotBufferProvider on tick', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Initial state check
    expect(container.read(plotBufferProvider), isEmpty);

    // Start simulation
    container.read(simulationProvider.notifier).startSimulation();

    // Wait for at least one tick
    // kTickRateHz is 60, so 1 tick is ~16.6ms
    await Future.delayed(const Duration(milliseconds: 100));

    // Stop simulation to prevent further ticks
    container.read(simulationProvider.notifier).stopSimulation();

    // The buffer should no longer be empty
    final buffer = container.read(plotBufferProvider);
    expect(buffer, isNotEmpty);
    
    final lastCount = buffer.length;
    
    // Wait more - should NOT increase because simulation is stopped
    await Future.delayed(const Duration(milliseconds: 100));
    expect(container.read(plotBufferProvider).length, equals(lastCount));
  });
}
