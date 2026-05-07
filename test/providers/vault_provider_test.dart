import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cerebrosim/models/experiment_snapshot.dart';
import 'package:cerebrosim/providers/auth_provider.dart';
import 'package:cerebrosim/providers/vault_provider.dart';
import 'package:cerebrosim/services/database_service.dart';

class _FakeDatabaseService extends Mock implements DatabaseService {}

class _FakeUser extends Mock implements User {
  final String _uid;
  _FakeUser(this._uid);
  @override
  String get uid => _uid;
}

/// Test-only auth notifier — skips Firebase entirely.
class _TestAuthNotifier extends AuthNotifier {
  @override
  FutureOr<User?> build() => null;

  void setUser(User? user) {
    state = AsyncData(user);
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(ExperimentSnapshot(
      id: 'test',
      userId: 'uid',
      userEmail: 'test@test.com',
      taskName: 'VOR',
      finalErrorRate: 0.0,
      synapticWeights: const [],
      episodeCount: 0,
      isPublic: false,
      title: 'Test',
      createdAt: DateTime(2024),
    ));
  });

  group('VaultNotifier subscription lifecycle (P1.5)', () {
    test('toggling auth 10x results in at most 1 active subscription', () async {
      final fakeDb = _FakeDatabaseService();
      int activeSubscriptions = 0;

      when(() => fakeDb.watchUserSnapshots(any())).thenAnswer((_) {
        return Stream.multi((controller) {
          activeSubscriptions++;
          // Emit initial snapshot so await stream.first resolves
          controller.add(const []);
          controller.onCancel = () => activeSubscriptions--;
        });
      });
      when(() => fakeDb.saveSnapshot(any())).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(fakeDb),
          authProvider.overrideWith(() => _TestAuthNotifier()),
        ],
      );
      addTearDown(container.dispose);

      final authNotifier =
          container.read(authProvider.notifier) as _TestAuthNotifier;

      // Rapid auth flips
      for (int i = 0; i < 10; i++) {
        if (i.isEven) {
          authNotifier.setUser(_FakeUser('user_$i'));
        } else {
          authNotifier.setUser(null);
        }
        // Let microtasks propagate the watch invalidation
        await Future.microtask(() {});
      }

      // Allow async builds to settle
      await Future.delayed(const Duration(milliseconds: 50));

      expect(activeSubscriptions, lessThanOrEqualTo(1));
    });
  });
}
