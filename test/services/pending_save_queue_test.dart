import 'package:flutter_test/flutter_test.dart';
import 'package:cerebrosim/services/pending_save_queue.dart';
import 'package:cerebrosim/models/experiment_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PendingSaveQueue', () {
    late PendingSaveQueue queue;
    const uid = 'user_abc';

    setUp(() {
      queue = PendingSaveQueue();
    });

    tearDown(() {
      queue.dispose();
    });

    ExperimentSnapshot _snap(String title) => ExperimentSnapshot(
          id: '',
          userId: uid,
          userEmail: 'a@b.com',
          taskName: 'vor',
          finalErrorRate: 0.3,
          synapticWeights: [0.5],
          episodeCount: 5,
          isPublic: false,
          title: title,
          createdAt: DateTime(2026, 1, 1),
        );

    test('enqueue persists items across instances', () async {
      await queue.enqueue(uid, _snap('Snap A'));
      await queue.enqueue(uid, _snap('Snap B'));

      final q2 = PendingSaveQueue();
      addTearDown(q2.dispose);
      final all = await q2.getAll(uid);
      expect(all.map((e) => e.snapshot.title), containsAll(['Snap A', 'Snap B']));
    });

    test('dequeue removes only the matching entry by localId', () async {
      final idA = await queue.enqueue(uid, _snap('Snap A'));
      await queue.enqueue(uid, _snap('Snap B'));

      await queue.dequeue(uid, idA);

      final all = await queue.getAll(uid);
      expect(all.length, 1);
      expect(all.single.snapshot.title, 'Snap B');
    });

    test('clear removes all items', () async {
      await queue.enqueue(uid, _snap('X'));
      await queue.enqueue(uid, _snap('Y'));
      await queue.clear(uid);

      expect(await queue.getAll(uid), isEmpty);
      expect(await queue.pendingCount(uid), 0);
    });

    test('pendingCountStream emits updated counts', () async {
      final counts = <int>[];
      final sub = queue.pendingCountStream.listen(counts.add);
      addTearDown(sub.cancel);

      await queue.enqueue(uid, _snap('M'));
      await queue.enqueue(uid, _snap('N'));
      await queue.clear(uid);

      await Future.delayed(Duration.zero);
      expect(counts, containsAllInOrder([1, 2, 0]));
    });
  });
}
