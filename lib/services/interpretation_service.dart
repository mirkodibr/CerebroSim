import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/episode_record.dart';

/// A service that uses AI to interpret cerebellar simulation results.
class InterpretationService {
  final Map<String, String> _cache = {};
  
  // NOTE: In a real production app, this would be handled via a secure backend
  // or a Cloud Function to protect the API key.
  static const String _apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');

  /// Interprets the experiment results using the Anthropic API.
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

    if (_apiKey.isEmpty) {
      return "Interpretation unavailable: API key not configured.";
    }

    final String progressStr = history != null && history.isNotEmpty
        ? history.map((e) => e.meanPunishment.toStringAsFixed(3)).join(', ')
        : "N/A";

    final String structuredSummary = '''
Experiment Summary:
- Task: $taskName
- Total Episodes: $episodeCount
- Final Error Rate: ${(finalErrorRate * 100).toStringAsFixed(2)}%
- Learning Progress (mean punishments): $progressStr
''';

    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-haiku-20240307',
          'max_tokens': 1024,
          'system': 'You are a neuroscience educator explaining cerebellar learning results to a graduate student. Be specific, cite Marr-Albus-Ito theory, reference LTD at PF-PC synapses, climbing fiber error signals, and DCN output. Maximum 3 short paragraphs. Be encouraging.',
          'messages': [
            {'role': 'user', 'content': structuredSummary}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        _cache[snapshotId] = content;
        return content;
      } else {
        throw Exception('Failed to call Anthropic API: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}

final interpretationServiceProvider = InterpretationService();
