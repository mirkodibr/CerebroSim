import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/providers/simulation_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SimulationController ticker starts and stops correctly', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(simulationControllerProvider);
    
    expect(controller.isTickerActive, isFalse);

    controller.startSimulation();
    expect(controller.isTickerActive, isTrue);

    controller.pauseSimulation();
    expect(controller.isTickerActive, isFalse);

    controller.startSimulation();
    expect(controller.isTickerActive, isTrue);

    controller.stopSimulation();
    expect(controller.isTickerActive, isFalse);
  });
}
