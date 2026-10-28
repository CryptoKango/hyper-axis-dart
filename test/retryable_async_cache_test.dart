import 'dart:async';

import 'package:hyper_axis/src/api/retryable_async_cache.dart';
import 'package:test/test.dart';

void main() {
  group('RetryableAsyncCache', () {
    test('shares a concurrent initialization attempt', () async {
      final RetryableAsyncCache<int> cache = RetryableAsyncCache<int>();
      final Completer<int> completer = Completer<int>();
      var attempts = 0;

      Future<int> initialize() {
        attempts += 1;
        return completer.future;
      }

      final Future<int> first = cache.getOrInitialize(initialize);
      final Future<int> second = cache.getOrInitialize(initialize);

      expect(identical(first, second), isTrue);
      expect(attempts, 1);

      completer.complete(7);
      await expectLater(first, completion(7));
      await expectLater(second, completion(7));
    });

    test('retains a successful initialization', () async {
      final RetryableAsyncCache<int> cache = RetryableAsyncCache<int>();
      var attempts = 0;

      Future<int> initialize() async {
        attempts += 1;
        return attempts;
      }

      expect(await cache.getOrInitialize(initialize), 1);
      expect(await cache.getOrInitialize(initialize), 1);
      expect(attempts, 1);
    });

    test('removes a failed attempt so the next call can retry', () async {
      final RetryableAsyncCache<int> cache = RetryableAsyncCache<int>();
      final StateError failure = StateError('first attempt failed');
      var attempts = 0;

      Future<int> initialize() async {
        attempts += 1;
        if (attempts == 1) {
          throw failure;
        }
        return 9;
      }

      await expectLater(cache.getOrInitialize(initialize), throwsA(failure));
      expect(await cache.getOrInitialize(initialize), 9);
      expect(attempts, 2);
    });

    test('also retries after a synchronous initializer failure', () async {
      final RetryableAsyncCache<int> cache = RetryableAsyncCache<int>();
      var attempts = 0;

      Future<int> initialize() {
        attempts += 1;
        if (attempts == 1) {
          throw StateError('synchronous failure');
        }
        return Future<int>.value(11);
      }

      await expectLater(
        cache.getOrInitialize(initialize),
        throwsA(isA<StateError>()),
      );
      expect(await cache.getOrInitialize(initialize), 11);
      expect(attempts, 2);
    });
  });
}
