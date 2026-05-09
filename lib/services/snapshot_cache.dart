import 'package:shared_preferences/shared_preferences.dart';
import '../models/experiment_snapshot.dart';

/// Local-disk cache for [ExperimentSnapshot]s, keyed by user UID.
///
/// Snapshots are serialised to JSON and stored in SharedPreferences so the
/// Vault can display cached data immediately on cold-start or when offline.
/// Cache entries are keyed by UID so different accounts on the same device
/// never see each other's data.
class SnapshotCache {
  static String _key(String uid) => 'snapshot_cache_$uid';

  /// Returns the cached snapshot list for [uid], or an empty list on miss.
  Future<List<ExperimentSnapshot>> loadCached(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(uid));
    if (raw == null) return [];
    return raw
        .map((json) {
          try {
            return ExperimentSnapshot.fromJson(json, currentUserId: uid);
          } catch (_) {
            return null;
          }
        })
        .whereType<ExperimentSnapshot>()
        .toList();
  }

  /// Persists [snaps] to disk for [uid], replacing any previous cache.
  Future<void> saveCached(String uid, List<ExperimentSnapshot> snaps) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = snaps.map((s) => s.toJson()).toList();
    await prefs.setStringList(_key(uid), encoded);
  }

  /// Removes all cached snapshots for [uid].
  Future<void> clearCache(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(uid));
  }
}
