import 'dart:async';
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
  StreamSubscription? _subscription;

  /// Initializes the vault by listening to the user's experiment snapshots in Firestore.
  /// Automatically re-syncs when the authenticated user changes.
  @override
  FutureOr<List<ExperimentSnapshot>> build() async {
    final user = ref.watch(authProvider).value;
    if (user == null) return [];

    final completer = Completer<List<ExperimentSnapshot>>();
    
    _subscription?.cancel();
    _subscription = ref.read(databaseServiceProvider).watchUserSnapshots(user.uid).listen((snaps) {
      if (!completer.isCompleted) {
        completer.complete(snaps);
      } else {
        state = AsyncData(snaps);
      }
    }, onError: (e, s) {
      if (!completer.isCompleted) {
        completer.completeError(e, s);
      } else {
        state = AsyncError(e, s);
      }
    });

    ref.onDispose(() => _subscription?.cancel());

    return completer.future;
  }

  /// Saves a new [ExperimentSnapshot] to the user's vault in Firestore.
  /// Snapshot includes synaptic weights, task configuration, and simulation metrics.
  Future<void> saveSnapshot(ExperimentSnapshot snap) async {
    final previousState = state;
    state = const AsyncLoading();
    
    try {
      await ref.read(databaseServiceProvider).saveSnapshot(snap);
    } catch (e, s) {
      state = AsyncError(e, s);
      await Future.delayed(const Duration(seconds: 3));
      state = previousState;
    }
  }
}

/// A global provider for the [VaultNotifier], allowing access to the user's saved experiments.
final vaultProvider = AsyncNotifierProvider<VaultNotifier, List<ExperimentSnapshot>>(() {
  return VaultNotifier();
});

/// A provider that fetches a list of experiment snapshots that have been marked as public.
/// Used to populate the community gallery of simulation results.
final publicGalleryProvider = FutureProvider<List<ExperimentSnapshot>>((ref) async {
  return await ref.read(databaseServiceProvider).fetchPublicGallery();
});
