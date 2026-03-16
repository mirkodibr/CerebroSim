import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/providers/signal_provider.dart';

void main() {
  group('SignalHistoryNotifier', () {
    test('starts with an empty history', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final history = container.read(signalHistoryProvider);
      expect(history, isEmpty);
    });

    test('adds points and limits history to 200 points', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(signalHistoryProvider.notifier);

      for (int i = 0; i < 250; i++) {
        notifier.addPoint(1.0, 0.0);
      }

      final history = container.read(signalHistoryProvider);
      expect(history.length, equals(200));
    });

    test('reset clears the history', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(signalHistoryProvider.notifier);
      notifier.addPoint(1.0, 1.0);
      
      notifier.reset();
      
      final history = container.read(signalHistoryProvider);
      expect(history, isEmpty);
    });
  });
}
