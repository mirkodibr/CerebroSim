import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/widgets/signal_plotter.dart';
import 'package:cerebrosim/models/plot_point.dart';

void main() {
  group('PlotBufferNotifier', () {
    test('starts with an empty buffer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final buffer = container.read(plotBufferProvider);
      expect(buffer, isEmpty);
    });

    test('adds points and limits buffer to 200 points', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(plotBufferProvider.notifier);

      for (int i = 0; i < 250; i++) {
        notifier.addPoint(const PlotPoint(criticPrediction: 0.0, actualSignal: 0.0));
      }

      final buffer = container.read(plotBufferProvider);
      expect(buffer.length, equals(200));
    });
  });
}
