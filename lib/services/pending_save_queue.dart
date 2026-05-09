import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/experiment_snapshot.dart';

/// An entry in the persistent pending-save queue.
class PendingEntry {
  final String localId;
  final ExperimentSnapshot snapshot;

  PendingEntry({required this.localId, required this.snapshot});

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'data': snapshot.toJson(),
      };

  static PendingEntry? fromJson(Map<String, dynamic> json, String uid) {
    try {
      return PendingEntry(
        localId: json['localId'] as String,
        snapshot: ExperimentSnapshot.fromJson(json['data'] as String, currentUserId: uid),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Persists [ExperimentSnapshot]s that failed to reach Firestore so they can
/// be retried automatically when connectivity is restored.
///
/// Each entry gets a stable [PendingEntry.localId] so items can be dequeued
/// reliably even though Firestore-assigned IDs are not yet available.
class PendingSaveQueue {
  static String _key(String uid) => 'pending_saves_$uid';

  final _countController = StreamController<int>.broadcast();

  /// Emits the pending-save count whenever it changes.
  Stream<int> get pendingCountStream => _countController.stream;

  Future<List<PendingEntry>> _load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(uid)) ?? [];
    return raw
        .map((s) {
          try {
            return PendingEntry.fromJson(
              jsonDecode(s) as Map<String, dynamic>,
              uid,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<PendingEntry>()
        .toList();
  }

  Future<void> _save(String uid, List<PendingEntry> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = items.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key(uid), encoded);
    _countController.add(items.length);
  }

  /// Returns the number of pending saves for [uid].
  Future<int> pendingCount(String uid) async {
    return (await _load(uid)).length;
  }

  /// Adds [snap] to the persistent queue. Returns the [localId] assigned to it.
  Future<String> enqueue(String uid, ExperimentSnapshot snap) async {
    final items = await _load(uid);
    final localId = '${DateTime.now().microsecondsSinceEpoch}_${items.length}';
    items.add(PendingEntry(localId: localId, snapshot: snap));
    await _save(uid, items);
    return localId;
  }

  /// Removes the entry with [localId] from the queue.
  Future<void> dequeue(String uid, String localId) async {
    final items = await _load(uid);
    items.removeWhere((e) => e.localId == localId);
    await _save(uid, items);
  }

  /// Returns all pending entries for [uid].
  Future<List<PendingEntry>> getAll(String uid) => _load(uid);

  /// Removes all pending saves for [uid].
  Future<void> clear(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(uid));
    _countController.add(0);
  }

  void dispose() => _countController.close();
}
