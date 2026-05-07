import 'dart:collection';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/episode_record.dart';

/// A notifier that maintains a historical list of [EpisodeRecord]s using an optimized queue.
///
/// It provides a moving window of the last 50 episodes to visualize 
/// how the cerebellar network's learning is converging over time.
class EpisodeHistoryNotifier extends Notifier<List<EpisodeRecord>> {
  final Queue<EpisodeRecord> _queue = Queue<EpisodeRecord>();
  static const int _maxSize = 50;

  @override
  List<EpisodeRecord> build() {
    return UnmodifiableListView(_queue);
  }

  /// Appends a new [record] to the history and removes the oldest if the 
  /// limit is reached. Performs at most one allocation (the record itself).
  void recordEpisode(EpisodeRecord record) {
    if (_queue.length >= _maxSize) {
      _queue.removeFirst();
    }
    _queue.addLast(record);
    state = UnmodifiableListView(_queue);
  }

  /// Clears the entire history without reallocation.
  void clear() {
    _queue.clear();
    state = UnmodifiableListView(_queue);
  }
}

/// A global provider for the [EpisodeHistoryNotifier].
final episodeHistoryProvider = NotifierProvider<EpisodeHistoryNotifier, List<EpisodeRecord>>(() {
  return EpisodeHistoryNotifier();
});
