import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/episode_record.dart';

/// A service that uses AI to interpret cerebellar simulation results.
/// 
/// Interpretation is handled securely via a Firebase Cloud Function to protect
/// API keys and offload processing from the client device.
class InterpretationService {
  final Map<String, String> _cache = {};

  /// Interprets the experiment results using the 'interpretExperiment' Cloud Function.
  Future<String> interpretExperiment({
    required String snapshotId,
    List<EpisodeRecord>? history,
    required double finalErrorRate,
    required String taskName,
    required int episodeCount,
  }) async {
    if (_cache.containsKey(snapshotId)) {
      return _cache[snapshotId]!;
    }

    final String progressStr = history != null && history.isNotEmpty
        ? history.map((e) => e.meanPunishment.toStringAsFixed(3)).join(', ')
        : "N/A";

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'interpretExperiment',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );

      final result = await callable.call({
        'taskName': taskName,
        'episodeCount': episodeCount,
        'finalErrorRate': finalErrorRate,
        'learningProgress': progressStr,
      });

      final String content = result.data as String;
      _cache[snapshotId] = content;
      return content;
    } catch (e) {
      rethrow;
    }
  }
}

final interpretationServiceProvider = InterpretationService();
