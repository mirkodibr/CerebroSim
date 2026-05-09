import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cerebrosim/utils/retry.dart';

void main() {
  group('retryWithBackoff', () {
    test('returns immediately on success', () async {
      int calls = 0;
      final result = await retryWithBackoff(() async {
        calls++;
        return 42;
      });
      expect(result, 42);
      expect(calls, 1);
    });

    test('retries on retryable error and eventually succeeds', () async {
      int calls = 0;
      final result = await retryWithBackoff(
        () async {
          calls++;
          if (calls < 3) {
            throw FirebaseException(plugin: 'firestore', code: 'unavailable');
          }
          return 'ok';
        },
        initialDelay: Duration.zero,
      );
      expect(result, 'ok');
      expect(calls, 3);
    });

    test('does NOT retry on non-retryable error', () async {
      int calls = 0;
      expect(
        () => retryWithBackoff(
          () async {
            calls++;
            throw FirebaseException(plugin: 'firestore', code: 'permission-denied');
          },
          initialDelay: Duration.zero,
        ),
        throwsA(isA<FirebaseException>()),
      );
      await Future.delayed(Duration.zero);
      expect(calls, 1);
    });

    test('throws after maxAttempts exhausted', () async {
      int calls = 0;
      await expectLater(
        retryWithBackoff(
          () async {
            calls++;
            throw FirebaseException(plugin: 'firestore', code: 'unavailable');
          },
          maxAttempts: 3,
          initialDelay: Duration.zero,
        ),
        throwsA(isA<FirebaseException>()),
      );
      expect(calls, 3);
    });

    test('custom shouldRetry predicate is respected', () async {
      int calls = 0;
      await expectLater(
        retryWithBackoff(
          () async {
            calls++;
            throw Exception('custom error');
          },
          maxAttempts: 3,
          initialDelay: Duration.zero,
          shouldRetry: (e) => true,
        ),
        throwsA(isA<Exception>()),
      );
      expect(calls, 3);
    });
  });
}
