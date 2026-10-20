/// Stable error categories exposed by the Dart SDK.
enum HyperAxisErrorCode {
  /// A caller supplied an invalid field or unsupported value.
  invalidArgument,

  /// Rust rejected a protocol invariant.
  protocol,

  /// Signature encoding, recovery, or signer verification failed.
  signing,

  /// HTTP or WebSocket request or response validation failed.
  transport,

  /// No compatible native bridge is available for the current platform.
  bridgeUnavailable,

  /// An unexpected binding or native invocation failure occurred.
  bridgeFailure,

  /// Dart and Rust versions cannot safely communicate.
  incompatibleVersion,

  /// The native side returned an unrecognized error category.
  unknown,
}

/// Typed exception returned by every public HyperAxis API.
final class HyperAxisException implements Exception {
  /// Creates a stable SDK exception.
  HyperAxisException({
    required this.code,
    required this.message,
    Map<String, Object?> details = const <String, Object?>{},
    this.cause,
    this.causeStackTrace,
  }) : details = Map<String, Object?>.unmodifiable(details);

  /// Machine-readable error category.
  final HyperAxisErrorCode code;

  /// Sanitized human-readable explanation.
  final String message;

  /// Structured, non-sensitive diagnostic context.
  final Map<String, Object?> details;

  /// Original implementation error, when one exists.
  final Object? cause;

  /// Stack trace associated with [cause].
  final StackTrace? causeStackTrace;

  @override
  String toString() => 'HyperAxisException(${code.name}): $message';
}
