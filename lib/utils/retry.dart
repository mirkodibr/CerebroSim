import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Retryable Firestore error codes — transient failures that resolve on retry.
const _retryableCodes = {'unavailable', 'deadline-exceeded', 'aborted', 'internal'};

bool _defaultShouldRetry(Object error) {
  if (error is FirebaseException) {
    return _retryableCodes.contains(error.code);
  }
  return false;
}

/// Retries [operation] with exponential back-off on transient failures.
///
/// Back-off schedule: [initialDelay], [initialDelay*2], [initialDelay*4], …
/// Each delay is jittered by ±25% to prevent thundering-herd collisions.
/// After [maxAttempts] failures the last exception is rethrown.
///
/// [shouldRetry] defaults to accepting Firestore codes:
/// `unavailable`, `deadline-exceeded`, `aborted`, `internal`.
/// Deterministic errors (`permission-denied`, `not-found`, etc.) are NOT retried.
Future<T> retryWithBackoff<T>(
  Future<T> Function() operation, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(milliseconds: 500),
  bool Function(Object error)? shouldRetry,
}) async {
  final retry = shouldRetry ?? _defaultShouldRetry;
  final rng = Random();

  Object? lastError;
  StackTrace? lastStack;

  for (int attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      return await operation();
    } catch (e, s) {
      lastError = e;
      lastStack = s;

      if (!retry(e) || attempt == maxAttempts - 1) {
        rethrow;
      }

      final base = initialDelay * pow(2, attempt).toInt();
      final jitter = (base.inMilliseconds * 0.25 * (rng.nextDouble() * 2 - 1)).round();
      final delay = Duration(milliseconds: base.inMilliseconds + jitter);
      await Future.delayed(delay);
    }
  }

  // Unreachable, but satisfies the type checker.
  Error.throwWithStackTrace(lastError!, lastStack!);
}
