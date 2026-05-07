import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/providers/episode_history_provider.dart';
import 'package:cerebrosim/models/episode_record.dart';

void main() {
  group('EpisodeHistoryNotifier', () {
    test('initial state is empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      expect(container.read(episodeHistoryProvider), isEmpty);
    });

    test('recordEpisode appends a new record', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      const record = EpisodeRecord(episodeNumber: 1, meanPunishment: 0.5, finalTdError: 0.1);
      container.read(episodeHistoryProvider.notifier).recordEpisode(record);
      
      final state = container.read(episodeHistoryProvider);
      expect(state.length, 1);
      expect(state.first, equals(record));
    });

    test('recordEpisode caps history at 50 records', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(episodeHistoryProvider.notifier);

      for (int i = 0; i < 60; i++) {
        notifier.recordEpisode(EpisodeRecord(
          episodeNumber: i,
          meanPunishment: 0.1,
          finalTdError: 0.0,
        ));
      }

      final state = container.read(episodeHistoryProvider);
      expect(state.length, 50);
      expect(state.first.episodeNumber, 10);
      expect(state.last.episodeNumber, 59);
    });

    test('recordEpisode maintains max size of 50 even after 1000 entries', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(episodeHistoryProvider.notifier);

      for (int i = 0; i < 1000; i++) {
        notifier.recordEpisode(EpisodeRecord(
          episodeNumber: i,
          meanPunishment: i / 1000.0,
          finalTdError: 0.0,
        ));
      }

      final state = container.read(episodeHistoryProvider);
      expect(state.length, 50);
      expect(state.first.episodeNumber, 950);
      expect(state.last.episodeNumber, 999);
    });

    test('clear() resets history to empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(episodeHistoryProvider.notifier);

      notifier.recordEpisode(const EpisodeRecord(
        episodeNumber: 1,
        meanPunishment: 0.1,
        finalTdError: 0.0,
      ));
      
      expect(container.read(episodeHistoryProvider), isNotEmpty);
      
      notifier.clear();
      expect(container.read(episodeHistoryProvider), isEmpty);
    });
  });
}
