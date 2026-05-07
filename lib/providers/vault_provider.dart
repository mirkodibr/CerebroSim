import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/experiment_snapshot.dart';
import '../services/database_service.dart';
import 'auth_provider.dart';

/// A provider that exposes an instance of [DatabaseService].
/// This service handles all interactions with Firestore for storing experiment snapshots.
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// A notifier that manages the "Vault" of experiment snapshots for the current user.
/// It synchronizes with Firestore to provide a real-time list of saved cerebellar network states.
class VaultNotifier extends AsyncNotifier<List<ExperimentSnapshot>> {
  StreamSubscription<List<ExperimentSnapshot>>? _vaultSubscription;

  @override
  FutureOr<List<ExperimentSnapshot>> build() async {
    // Synchronous cancel — eliminates re-entrancy window on rapid auth flips.
    _vaultSubscription?.cancel();
    _vaultSubscription = null;

    final user = ref.watch(authProvider).value;
    if (user == null) return [];

    // Defensive cleanup on provider disposal.
    ref.onDispose(() {
      _vaultSubscription?.cancel();
      _vaultSubscription = null;
    });

    final stream =
        ref.read(databaseServiceProvider).watchUserSnapshots(user.uid);

    // Await initial snapshot; stream.first self-cancels its internal subscription.
    final initial = await stream.first;

    // Subscribe for subsequent real-time updates.
    _vaultSubscription = stream.listen(
      (snaps) => state = AsyncData(snaps),
      onError: (e, s) => state = AsyncError(e, s),
    );

    return initial;
  }

  /// Saves a new [ExperimentSnapshot] to the user's vault in Firestore.
  Future<void> saveSnapshot(ExperimentSnapshot snap) async {
    final previousState = state;
    state = const AsyncLoading();

    try {
      await ref.read(databaseServiceProvider).saveSnapshot(snap);
      HapticFeedback.lightImpact();
    } catch (e, s) {
      state = AsyncError(e, s);
      if (previousState.hasValue) {
        state = AsyncData(previousState.value!);
      } else {
        state = previousState;
      }
      rethrow;
    }
  }
}

/// A global provider for the [VaultNotifier], allowing access to the user's saved experiments.
final vaultProvider =
    AsyncNotifierProvider<VaultNotifier, List<ExperimentSnapshot>>(() {
  return VaultNotifier();
});

/// A provider that fetches a list of experiment snapshots that have been marked as public.
final publicGalleryProvider =
    FutureProvider.family<List<ExperimentSnapshot>, String>(
        (ref, taskFilter) async {
  return await ref.read(databaseServiceProvider).fetchPublicGallery(
        taskFilter: taskFilter == 'all' ? null : taskFilter,
      );
});
