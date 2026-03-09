import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/providers/signal_provider.dart';

void main() {
  group('SignalNotifier Tests', () {
    test('Sine signal should toggle based on math', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(signalProvider.notifier);
      notifier.setType(SignalType.sine);
      notifier.setFrequency(1.0); // 1Hz = 1 cycle per second

      // At t=0, sin(0) = 0.0, so state = false
      notifier.update(0);
      expect(container.read(signalProvider), false);

      // At t=0.25s (250ms), sin(2*pi*1*0.25) = sin(pi/2) = 1.0, so state = true
      notifier.update(250);
      expect(container.read(signalProvider), true);
    });

    test('Step signal should toggle every second', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(signalProvider.notifier);
      notifier.setType(SignalType.step);

      // 0-1s -> true
      notifier.update(500);
      expect(container.read(signalProvider), true);

      // 1.1s -> false
      notifier.update(600);
      expect(container.read(signalProvider), false);
    });
  });
}
