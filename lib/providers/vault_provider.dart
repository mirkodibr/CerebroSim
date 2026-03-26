import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/experiment_snapshot.dart';
import '../services/database_service.dart';
import 'auth_provider.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

class VaultNotifier extends AsyncNotifier<List<ExperimentSnapshot>> {
  StreamSubscription? _subscription;

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

final vaultProvider = AsyncNotifierProvider<VaultNotifier, List<ExperimentSnapshot>>(() {
  return VaultNotifier();
});

final publicGalleryProvider = FutureProvider<List<ExperimentSnapshot>>((ref) async {
  return await ref.read(databaseServiceProvider).fetchPublicGallery();
});
