import 'package:flutter_test/flutter_test.dart';
import 'package:cerebrosim/models/episode_record.dart';

void main() {
  group('EpisodeRecord Serialization', () {
    test('round-trip serialization preserves all fields', () {
      const original = EpisodeRecord(
        episodeNumber: 42,
        meanPunishment: 0.1234,
        finalTdError: -0.5678,
      );

      final json = original.toJson();
      final recovered = EpisodeRecord.fromJson(json);

      expect(recovered.episodeNumber, equals(original.episodeNumber));
      expect(recovered.meanPunishment, equals(original.meanPunishment));
      expect(recovered.finalTdError, equals(original.finalTdError));
    });

    test('fromJson handles null values with defaults', () {
      final recovered = EpisodeRecord.fromJson({});

      expect(recovered.episodeNumber, equals(0));
      expect(recovered.meanPunishment, equals(0.0));
      expect(recovered.finalTdError, equals(0.0));
    });

    test('fromJson handles num to double conversion', () {
      final json = {
        'episodeNumber': 10,
        'meanPunishment': 1, // int in JSON
        'finalTdError': 0.5,
      };
      final recovered = EpisodeRecord.fromJson(json);

      expect(recovered.meanPunishment, equals(1.0));
      expect(recovered.meanPunishment, isA<double>());
    });
  });
}
