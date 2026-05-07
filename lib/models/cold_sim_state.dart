import 'package:meta/meta.dart';

/// The slow-changing "cold" portion of the simulation state.
///
/// These fields only change on user action (start/pause/speed change) or at
/// episode boundaries. Widgets that watch [ColdSimState] will NOT rebuild on
/// every 60 Hz tick — only when one of these three fields actually changes.
@immutable
class ColdSimState {
  final bool isRunning;
  final int episodeCount;
  final double speedMultiplier;

  const ColdSimState({
    this.isRunning = false,
    this.episodeCount = 0,
    this.speedMultiplier = 1.0,
  });

  ColdSimState copyWith({
    bool? isRunning,
    int? episodeCount,
    double? speedMultiplier,
  }) {
    return ColdSimState(
      isRunning: isRunning ?? this.isRunning,
      episodeCount: episodeCount ?? this.episodeCount,
      speedMultiplier: speedMultiplier ?? this.speedMultiplier,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColdSimState &&
          isRunning == other.isRunning &&
          episodeCount == other.episodeCount &&
          speedMultiplier == other.speedMultiplier;

  @override
  int get hashCode =>
      Object.hash(isRunning, episodeCount, speedMultiplier);
}
