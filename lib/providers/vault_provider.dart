import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/experiment_snapshot.dart';
import '../services/database_service.dart';
import '../services/snapshot_cache.dart';
import '../services/pending_save_queue.dart';
import 'auth_provider.dart';
import 'connectivity_provider.dart';

/// A provider that exposes an instance of [DatabaseService].
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final snapshotCacheProvider = Provider<SnapshotCache>((ref) => SnapshotCache());

final pendingSaveQueueProvider = Provider<PendingSaveQueue>((ref) {
  final q = PendingSaveQueue();
  ref.onDispose(q.dispose);
  return q;
});

/// Whether the vault is currently showing stale cached data because Firestore
/// is unreachable. Surfaced in [VaultScreen] as an offline banner.
class _VaultOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setOffline(bool v) => state = v;
}

final vaultIsOfflineProvider = NotifierProvider<_VaultOfflineNotifier, bool>(
  _VaultOfflineNotifier.new,
);

/// Number of snapshots waiting to be flushed to Firestore.
final pendingSaveCountProvider = StreamProvider.family<int, String>((ref, uid) {
  return ref.read(pendingSaveQueueProvider).pendingCountStream;
});

/// Listens for connectivity restoration and flushes the pending-save queue.
/// Uses [connectivityProvider] so tests can override it with a fake stream.
final _pendingFlushProvider = Provider.autoDispose<void>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return;

  ref.listen<AsyncValue<List<ConnectivityResult>>>(connectivityProvider, (_, next) async {
    final results = next.value ?? [];
    final isOnline = results.any((r) => r != ConnectivityResult.none);
    if (!isOnline) return;

    final queue = ref.read(pendingSaveQueueProvider);
    final db = ref.read(databaseServiceProvider);
    final pending = await queue.getAll(user.uid);
    for (final entry in pending) {
      try {
        await db.saveSnapshot(entry.snapshot);
        await queue.dequeue(user.uid, entry.localId);
      } catch (_) {
        // Leave in queue for the next connectivity event.
      }
    }
  });
});

/// A notifier that manages the "Vault" of experiment snapshots for the current user.
/// It synchronizes with Firestore to provide a real-time list of saved cerebellar network states.
/// On cold-start or when offline, it hydrates from the local [SnapshotCache] immediately.
class VaultNotifier extends AsyncNotifier<List<ExperimentSnapshot>> {
  StreamSubscription? _vaultSubscription;

  @override
  FutureOr<List<ExperimentSnapshot>> build() async {
    // Activate the pending-save flush listener.
    ref.watch(_pendingFlushProvider);

    // Synchronously clear previous subscription before any async work.
    unawaited(_vaultSubscription?.cancel());
    _vaultSubscription = null;

    final user = ref.watch(authProvider).value;
    if (user == null) return [];

    final cache = ref.read(snapshotCacheProvider);

    // Hydrate from cache immediately so the UI is never blank on cold-start.
    final cached = await cache.loadCached(user.uid);
    if (cached.isNotEmpty) {
      state = AsyncData(cached);
    }

    final db = ref.read(databaseServiceProvider);
    final stream = db.watchUserSnapshots(user.uid);

    _vaultSubscription = stream.listen((snaps) {
      ref.read(vaultIsOfflineProvider.notifier).setOffline(false);
      state = AsyncData(snaps);
      cache.saveCached(user.uid, snaps);
    }, onError: (e, s) {
      if (cached.isNotEmpty) {
        ref.read(vaultIsOfflineProvider.notifier).setOffline(true);
        state = AsyncData(cached);
      } else {
        state = AsyncError(e, s);
      }
    });

    ref.onDispose(() => _vaultSubscription?.cancel());

    try {
      final initial = await stream.first;
      ref.read(vaultIsOfflineProvider.notifier).setOffline(false);
      cache.saveCached(user.uid, initial);
      return initial;
    } catch (e) {
      ref.read(vaultIsOfflineProvider.notifier).setOffline(cached.isNotEmpty);
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  /// Saves a new [ExperimentSnapshot] to the user's vault in Firestore.
  ///
  /// On final failure, enqueues the snapshot locally so it can be flushed
  /// when connectivity is restored. Returns normally (does not rethrow) so
  /// the UI can show a "Saved offline" message instead of an error toast.
  Future<void> saveSnapshot(ExperimentSnapshot snap, {bool enqueuOnFailure = true}) async {
    final user = ref.read(authProvider).value;
    final previousState = state;
    state = const AsyncLoading();

    try {
      await ref.read(databaseServiceProvider).saveSnapshot(snap);
      HapticFeedback.lightImpact();
    } catch (e, s) {
      if (enqueuOnFailure && user != null) {
        await ref.read(pendingSaveQueueProvider).enqueue(user.uid, snap);
        // Restore previous UI state with the offline flag.
        if (previousState.hasValue) {
          state = AsyncData(previousState.value!);
        } else {
          state = previousState;
        }
        ref.read(vaultIsOfflineProvider.notifier).setOffline(true);
        // Don't rethrow: caller receives a silent "saved offline" outcome.
        return;
      }

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
final vaultProvider = AsyncNotifierProvider<VaultNotifier, List<ExperimentSnapshot>>(() {
  return VaultNotifier();
});

/// A provider that fetches a list of experiment snapshots that have been marked as public.
final publicGalleryProvider = FutureProvider.family<List<ExperimentSnapshot>, String>((ref, taskFilter) async {
  return await ref.read(databaseServiceProvider).fetchPublicGallery(
    taskFilter: taskFilter == 'all' ? null : taskFilter,
  );
});
