import 'dart:async';
import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/episode_record.dart';

const _kCacheTtl = Duration(days: 7);
const _kMaxCacheEntries = 100;
const _kCacheKey = 'interpretation_cache';

/// A service that uses AI to interpret cerebellar simulation results.
///
/// Interpretation is handled securely via a Firebase Cloud Function to protect
/// API keys and offload processing from the client device.
///
/// Results are persisted to SharedPreferences with a [_kCacheTtl]-day TTL
/// and an LRU eviction policy at [_kMaxCacheEntries] entries.
class InterpretationService {
  // In-memory map for fast lookups; loaded lazily from disk on first call.
  final Map<String, _CacheEntry> _cache = {};
  bool _cacheLoaded = false;

  Future<void> _ensureCacheLoaded() async {
    if (_cacheLoaded) return;
    _cacheLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCacheKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final kv in decoded.entries) {
        final entry = _CacheEntry.fromJson(kv.value as Map<String, dynamic>);
        if (!entry.isExpired) _cache[kv.key] = entry;
      }
    } catch (_) {
      // Corrupted cache — start fresh.
      await prefs.remove(_kCacheKey);
    }
  }

  Future<void> _persistCache() async {
    final prefs = await SharedPreferences.getInstance();
    // LRU eviction: keep only the most recently accessed [_kMaxCacheEntries] entries.
    final entries = _cache.entries.toList()
      ..sort((a, b) => b.value.accessedAt.compareTo(a.value.accessedAt));
    final kept = entries.take(_kMaxCacheEntries);
    final encoded = {for (final e in kept) e.key: e.value.toJson()};
    await prefs.setString(_kCacheKey, jsonEncode(encoded));
  }

  /// Interprets the experiment results using the 'interpretExperiment' Cloud Function.
  Future<String> interpretExperiment({
    required String snapshotId,
    List<EpisodeRecord>? history,
    required double finalErrorRate,
    required String taskName,
    required int episodeCount,
  }) async {
    await _ensureCacheLoaded();

    final cached = _cache[snapshotId];
    if (cached != null && !cached.isExpired) {
      cached.touch();
      return cached.content;
    }
    _cache.remove(snapshotId); // Remove expired entry if any.

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
      _cache[snapshotId] = _CacheEntry(content: content);
      await _persistCache();
      return content;
    } catch (e) {
      rethrow;
    }
  }

  /// Removes all persisted interpretation cache entries.
  Future<void> clearInterpretationCache() async {
    _cache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCacheKey);
  }
}

final interpretationServiceProvider = InterpretationService();

class _CacheEntry {
  final String content;
  final DateTime expiresAt;
  DateTime accessedAt;

  _CacheEntry({
    required this.content,
    DateTime? expiresAt,
    DateTime? accessedAt,
  })  : expiresAt = expiresAt ?? DateTime.now().add(_kCacheTtl),
        accessedAt = accessedAt ?? DateTime.now();

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  void touch() => accessedAt = DateTime.now();

  Map<String, dynamic> toJson() => {
        'content': content,
        'expiresAt': expiresAt.toIso8601String(),
        'accessedAt': accessedAt.toIso8601String(),
      };

  factory _CacheEntry.fromJson(Map<String, dynamic> json) => _CacheEntry(
        content: json['content'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        accessedAt: DateTime.parse(json['accessedAt'] as String),
      );
}
