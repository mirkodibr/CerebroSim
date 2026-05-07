import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/providers/vault_provider.dart';
import 'package:cerebrosim/providers/auth_provider.dart';
import 'package:cerebrosim/services/database_service.dart';
import 'package:cerebrosim/models/experiment_snapshot.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:mocktail/mocktail.dart';

class MockUser extends Mock implements auth.User {
  @override
  String get uid => 'test_user';
}

class FakeDatabaseService extends Mock implements DatabaseService {
  int activeSubscriptions = 0;

  @override
  Stream<List<ExperimentSnapshot>> watchUserSnapshots(String? uid) {
    late StreamController<List<ExperimentSnapshot>> controller;
    controller = StreamController<List<ExperimentSnapshot>>(
      onListen: () {
        activeSubscriptions++;
        controller.add([]); // Emit initial empty list for await stream.first
      },
      onCancel: () {
        activeSubscriptions--;
      },
    );
    return controller.stream;
  }
}

void main() {
  test('VaultNotifier does not leak subscriptions on rapid auth changes', () async {
    final fakeDb = FakeDatabaseService();
    final container = ProviderContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(fakeDb),
      ],
    );
    addTearDown(container.dispose);

    // Initial state: logged out
    expect(fakeDb.activeSubscriptions, 0);

    final mockUser = MockUser();

    // Rapidly toggle auth 10 times
    for (int i = 0; i < 10; i++) {
      // ignore: invalid_use_of_visible_for_testing_member
      container.read(authProvider.notifier).state = AsyncData(i % 2 == 0 ? mockUser : null);
      
      // Trigger the vault provider to start building
      container.read(vaultProvider.future).ignore();
      
      await Future.delayed(Duration.zero);
    }

    // Wait a bit for all async work to settle
    await Future.delayed(const Duration(milliseconds: 100));

    // Ensure we end in a logged-in state to check active subscriptions
    // ignore: invalid_use_of_visible_for_testing_member
    container.read(authProvider.notifier).state = AsyncData(mockUser);
    container.read(vaultProvider.future).ignore();
    await Future.delayed(const Duration(milliseconds: 100));

    expect(fakeDb.activeSubscriptions, 1, reason: 'Should have exactly one active subscription after rapid toggling');
  });
}
