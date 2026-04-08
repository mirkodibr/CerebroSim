import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/episode_record.dart';

/// A notifier that maintains a historical list of [EpisodeRecord]s.
///
/// It provides a moving window of the last 50 episodes to visualize 
/// how the cerebellar network's learning is converging over time.
class EpisodeHistoryNotifier extends Notifier<List<EpisodeRecord>> {
  @override
  List<EpisodeRecord> build() => [];

  /// Appends a new [record] to the history and removes the oldest if the 
  /// limit is reached.
  void recordEpisode(EpisodeRecord record) {
    state = [...state.skip(state.length >= 50 ? 1 : 0), record];
  }

  /// Clears the entire history, typically called when the simulation is reset.
  void clear() {
    state = [];
  }
}

/// A global provider for the [EpisodeHistoryNotifier].
final episodeHistoryProvider = NotifierProvider<EpisodeHistoryNotifier, List<EpisodeRecord>>(() {
  return EpisodeHistoryNotifier();
});
