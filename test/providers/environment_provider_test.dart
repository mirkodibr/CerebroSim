import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/providers/environment_provider.dart';

void main() {
  group('EnvironmentNotifier Tests', () {
    test('currentStep should increment correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(environmentProvider.notifier);
      
      notifier.update(100.0);
      expect(container.read(environmentProvider).currentStep, 100.0);
      
      notifier.update(150.0);
      expect(container.read(environmentProvider).currentStep, 250.0);
    });

    test('episode should roll over at 1000ms', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(environmentProvider.notifier);
      
      notifier.update(900.0);
      expect(container.read(environmentProvider).episodeNumber, 0);
      expect(container.read(environmentProvider).currentStep, 900.0);
      
      notifier.update(100.0);
      expect(container.read(environmentProvider).episodeNumber, 1);
      expect(container.read(environmentProvider).currentStep, 0.0);
    });

    test('getPFStateVector should have only one active window', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(environmentProvider.notifier);
      
      // Step 50ms should be in the first window (0-100ms) for pfCount=10
      notifier.update(50.0);
      final pfs = notifier.getPFStateVector(pfCount: 10);
      
      expect(pfs[0], true);
      expect(pfs.where((b) => b).length, 1);
    });

    test('getClimbingFiberSignal should return punishment at 500ms if wrong action', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(environmentProvider.notifier);
      
      // At 0ms, no punishment
      expect(notifier.getClimbingFiberSignal('anticlose'), 0.0);
      
      // At 500ms
      notifier.update(500.0);
      
      // Correct action -> 0.0
      expect(notifier.getClimbingFiberSignal('anticlose'), 0.0);
      
      // Wrong action -> -1.0
      expect(notifier.getClimbingFiberSignal('none'), -1.0);
      expect(notifier.getClimbingFiberSignal('antiopen'), -1.0);
    });
  });
}
