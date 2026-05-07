import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/providers/plot_buffer_provider.dart';
import 'package:cerebrosim/models/plot_point.dart';

void main() {
  group('PlotBufferNotifier', () {
    test('starts with tick counter 0 and empty ring buffer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(plotBufferProvider), equals(0));
      expect(container.read(plotRingBufferProvider).filled, equals(0));
    });

    test('push increments tick counter and fills ring buffer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(plotBufferProvider.notifier);

      for (int i = 0; i < 250; i++) {
        notifier.push(0.0, 0.0, 0.0);
      }

      expect(container.read(plotBufferProvider), equals(250));
      expect(container.read(plotRingBufferProvider).filled, equals(200));
    });

    test('addPoint convenience wrapper works via PlotPoint', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(plotBufferProvider.notifier)
          .addPoint(const PlotPoint(criticPrediction: 0.5, actualSignal: 0.3));

      expect(container.read(plotRingBufferProvider).filled, equals(1));
      expect(container.read(plotRingBufferProvider).getCritic(0), closeTo(0.5, 0.001));
    });

    test('clear resets tick counter and ring buffer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(plotBufferProvider.notifier);
      notifier.push(1.0, 1.0, 1.0);

      notifier.clear();

      expect(container.read(plotBufferProvider), equals(0));
      expect(container.read(plotRingBufferProvider).filled, equals(0));
    });

    test('ring buffer stays at capacity after 10,000 pushes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(plotBufferProvider.notifier);

      for (int i = 0; i < 10000; i++) {
        notifier.push(0.1 * (i % 10), 0.2 * (i % 5), 0.0);
      }

      expect(container.read(plotRingBufferProvider).filled, equals(200));
    });
  });
}
