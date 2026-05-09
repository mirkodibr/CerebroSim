import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leaderboard_entry.dart';

const _taskNames = ['eyeblink', 'sineWave', 'vor', 'armReaching'];

/// All supported leaderboard task names.
List<String> get leaderboardTasks => _taskNames;

/// Fetches the current week's top-50 leaderboard entries for a given task.
///
/// Reads from `leaderboards/{taskName}/current`, a document written nightly
/// by the `recomputeLeaderboards` Cloud Function.
final leaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, String>((ref, taskName) async {
  final doc = await FirebaseFirestore.instance
      .collection('leaderboards')
      .doc(taskName)
      .collection('weeks')
      .doc('current')
      .get();

  if (!doc.exists) return [];

  final data = doc.data()!;
  final entries = data['entries'] as List<dynamic>? ?? [];
  return entries
      .asMap()
      .entries
      .map((e) => LeaderboardEntry.fromJson(e.value as Map<String, dynamic>, e.key + 1))
      .toList();
});

/// Fetches past weeks (Hall of Fame). Returns a list of week keys for a task.
final leaderboardWeeksProvider = FutureProvider.family<List<String>, String>((ref, taskName) async {
  final snap = await FirebaseFirestore.instance
      .collection('leaderboards')
      .doc(taskName)
      .collection('weeks')
      .orderBy('computedAt', descending: true)
      .limit(12)
      .get();
  return snap.docs.map((d) => d.id).where((id) => id != 'current').toList();
});
