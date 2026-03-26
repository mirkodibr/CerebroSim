import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/providers/environment_provider.dart';
import 'package:cerebrosim/models/cerebellar_task.dart';

void main() {
  group('EnvironmentNotifier', () {
    test('starts with eyeblink task', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final task = container.read(environmentProvider);
      expect(task, CerebellarTask.eyeblink);
    });

    test('selectTask updates state and active environment', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(environmentProvider.notifier);
      notifier.selectTask(CerebellarTask.sineWave);

      expect(container.read(environmentProvider), CerebellarTask.sineWave);
      expect(notifier.activeEnv.taskName, 'Sine Wave Tracking');
    });
  });
}
