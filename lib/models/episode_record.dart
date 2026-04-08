import 'package:meta/meta.dart';

/// A record of a completed simulation episode, used for tracking convergence.
///
/// It stores the overall performance of the network during a specific
/// episode, allowing the UI to visualize learning trends over time.
@immutable
class EpisodeRecord {
  /// The sequential index of the episode in the current simulation session.
  final int episodeNumber;
  /// The average punishment (error signal) received across all ticks in the episode.
  final double meanPunishment;
  /// The final Temporal Difference (TD) error value at the end of the episode.
  final double finalTdError;

  const EpisodeRecord({
    required this.episodeNumber,
    required this.meanPunishment,
    required this.finalTdError,
  });

  /// Creates a copy of this record with updated fields.
  EpisodeRecord copyWith({
    int? episodeNumber,
    double? meanPunishment,
    double? finalTdError,
  }) {
    return EpisodeRecord(
      episodeNumber: episodeNumber ?? this.episodeNumber,
      meanPunishment: meanPunishment ?? this.meanPunishment,
      finalTdError: finalTdError ?? this.finalTdError,
    );
  }
}
