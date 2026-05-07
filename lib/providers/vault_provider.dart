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
  StreamSubscription? _vaultSubscription;

  /// Initializes the vault by listening to the user's experiment snapshots in Firestore.
  /// Automatically re-syncs when the authenticated user changes.
  @override
  FutureOr<List<ExperimentSnapshot>> build() async {
    // Synchronously clear previous subscription before any async work.
    unawaited(_vaultSubscription?.cancel());
    _vaultSubscription = null;

    final user = ref.watch(authProvider).value;
    if (user == null) return [];

    final stream = ref.read(databaseServiceProvider).watchUserSnapshots(user.uid);
    
    // Setup the listener for real-time updates after the initial load.
    _vaultSubscription = stream.listen((snaps) {
      state = AsyncData(snaps);
    }, onError: (e, s) {
      state = AsyncError(e, s);
    });

    ref.onDispose(() => _vaultSubscription?.cancel());

    // Return the first emission as the initial state.
    return await stream.first;
  }

  /// Saves a new [ExperimentSnapshot] to the user's vault in Firestore.
  /// Snapshot includes synaptic weights, task configuration, and simulation metrics.
  Future<void> saveSnapshot(ExperimentSnapshot snap) async {
    final previousState = state;
    state = const AsyncLoading();
    
    try {
      await ref.read(databaseServiceProvider).saveSnapshot(snap);
      HapticFeedback.lightImpact();
    } catch (e, s) {
      state = AsyncError(e, s);
      // Restore previous state after an error to prevent permanent loading indicators
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
final vaultProvider = AsyncNotifierProvider<VaultNotifier, List<ExperimentSnapshot>>(() {
  return VaultNotifier();
});

/// A provider that fetches a list of experiment snapshots that have been marked as public.
/// Used to populate the community gallery of simulation results.
/// Accepts a [taskFilter] to filter results by task type at the query level.
final publicGalleryProvider = FutureProvider.family<List<ExperimentSnapshot>, String>((ref, taskFilter) async {
  return await ref.read(databaseServiceProvider).fetchPublicGallery(
    taskFilter: taskFilter == 'all' ? null : taskFilter,
  );
});
