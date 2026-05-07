import 'dart:collection';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/episode_record.dart';

const int _kMaxHistory = 50;

/// A notifier that maintains a historical list of [EpisodeRecord]s.
///
/// Internally uses a [Queue] so each call to [recordEpisode] performs
/// at most one allocation (the new record itself) instead of copying
/// the entire list with a spread operator.
class EpisodeHistoryNotifier extends Notifier<List<EpisodeRecord>> {
  final Queue<EpisodeRecord> _queue = Queue();

  @override
  List<EpisodeRecord> build() => const [];

  /// Appends a new [record] and evicts the oldest when capacity is exceeded.
  void recordEpisode(EpisodeRecord record) {
    if (_queue.length >= _kMaxHistory) {
      _queue.removeFirst();
    }
    _queue.addLast(record);
    state = UnmodifiableListView(_queue.toList(growable: false));
  }

  /// Clears the entire history without reallocation.
  void clear() {
    _queue.clear();
    state = const [];
  }
}

/// A global provider for the [EpisodeHistoryNotifier].
final episodeHistoryProvider =
    NotifierProvider<EpisodeHistoryNotifier, List<EpisodeRecord>>(() {
  return EpisodeHistoryNotifier();
});
