import 'package:cloud_firestore/cloud_firestore.dart';

/// A single entry in a task leaderboard.
///
/// Leaderboard data lives at `leaderboards/{taskName}/current`
/// and is populated nightly by the `recomputeLeaderboards` Cloud Function.
class LeaderboardEntry {
  final int rank;
  final String snapshotId;
  final String title;
  final String userId;
  final String userEmail;
  final double score;
  final int episodeCount;
  final int networkSize;
  final DateTime createdAt;

  const LeaderboardEntry({
    required this.rank,
    required this.snapshotId,
    required this.title,
    required this.userId,
    required this.userEmail,
    required this.score,
    required this.episodeCount,
    required this.networkSize,
    required this.createdAt,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, int rank) {
    return LeaderboardEntry(
      rank: rank,
      snapshotId: json['snapshotId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      episodeCount: (json['episodeCount'] as num?)?.toInt() ?? 0,
      networkSize: (json['networkSize'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime(2000),
    );
  }
}
