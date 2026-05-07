import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/providers/plot_buffer_provider.dart';

void main() {
  group('PlotBufferNotifier', () {
    test('starts with an empty buffer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final tick = container.read(plotBufferProvider);
      final ringBuffer = container.read(plotRingBufferProvider);
      expect(tick, 0);
      expect(ringBuffer.filled, 0);
    });

    test('adds points and limits buffer to 200 points', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(plotBufferProvider.notifier);
      final ringBuffer = container.read(plotRingBufferProvider);

      for (int i = 0; i < 250; i++) {
        notifier.addPoint(0.0, 0.0, 0.0);
      }

      // The state (tick counter) should be 250
      expect(container.read(plotBufferProvider), 250);
      // The ring buffer should be capped at its capacity (200)
      expect(ringBuffer.filled, equals(200));
    });
  });
}
