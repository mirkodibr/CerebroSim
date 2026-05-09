import 'package:flutter_test/flutter_test.dart';
import 'package:cerebrosim/services/snapshot_cache.dart';
import 'package:cerebrosim/models/experiment_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SnapshotCache', () {
    late SnapshotCache cache;
    const uid = 'user_123';

    setUp(() {
      cache = SnapshotCache();
    });

    ExperimentSnapshot _snap(String id) => ExperimentSnapshot(
          id: id,
          userId: uid,
          userEmail: 'test@test.com',
          taskName: 'eyeblink',
          finalErrorRate: 0.1,
          synapticWeights: [0.1, 0.2],
          episodeCount: 10,
          isPublic: false,
          title: 'Test $id',
          createdAt: DateTime(2026, 1, 1),
        );

    test('loadCached returns empty list on miss', () async {
      final result = await cache.loadCached(uid);
      expect(result, isEmpty);
    });

    test('saveCached and loadCached round-trip', () async {
      final snaps = [_snap('a'), _snap('b')];
      await cache.saveCached(uid, snaps);

      final loaded = await cache.loadCached(uid);
      expect(loaded.length, 2);
      expect(loaded.first.title, 'Test a');
      expect(loaded.last.title, 'Test b');
    });

    test('clearCache removes stored data', () async {
      await cache.saveCached(uid, [_snap('a')]);
      await cache.clearCache(uid);

      final loaded = await cache.loadCached(uid);
      expect(loaded, isEmpty);
    });

    test('different UIDs are isolated', () async {
      await cache.saveCached('alice', [_snap('alice_snap')]);
      await cache.saveCached('bob', [_snap('bob_snap')]);

      final alice = await cache.loadCached('alice');
      final bob = await cache.loadCached('bob');

      expect(alice.single.title, 'Test alice_snap');
      expect(bob.single.title, 'Test bob_snap');
    });
  });
}
