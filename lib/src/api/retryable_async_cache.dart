import 'dart:async';

/// Shares an in-flight asynchronous initialization and retains its success.
///
/// A failed attempt is removed from the cache before its error reaches callers,
/// allowing the next call to start a fresh initialization attempt.
final class RetryableAsyncCache<T> {
  Future<T>? _pending;

  /// Returns the cached attempt or starts one with [initialize].
  Future<T> getOrInitialize(Future<T> Function() initialize) {
    final Future<T>? cached = _pending;
    if (cached != null) {
      return cached;
    }

    final Future<T> pending = Future<T>.sync(initialize);
    _pending = pending;
    unawaited(
      pending.then<void>(
        (_) {},
        onError: (Object _, StackTrace _) {
          if (identical(_pending, pending)) {
            _pending = null;
          }
        },
      ),
    );
    return pending;
  }
}
