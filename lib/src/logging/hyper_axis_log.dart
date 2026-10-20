import '../error/hyper_axis_exception.dart';

/// Severity assigned to sanitized Rust diagnostics.
enum HyperAxisLogLevel {
  /// Operation cannot continue.
  error('error'),

  /// Recoverable or suspicious condition.
  warn('warn'),

  /// High-level lifecycle event.
  info('info'),

  /// Development diagnostic.
  debug('debug'),

  /// Fine-grained protocol trace.
  trace('trace');

  const HyperAxisLogLevel(this.wireName);

  /// Lowercase wire representation accepted by Rust.
  final String wireName;
}

/// Runtime logging configuration applied to the Rust ring buffer.
final class HyperAxisLoggingConfig {
  /// Creates a validated logging configuration.
  factory HyperAxisLoggingConfig({
    bool enabled = false,
    HyperAxisLogLevel level = HyperAxisLogLevel.info,
    int capacity = 500,
  }) {
    if (capacity < 1 || capacity > maximumCapacity) {
      throw HyperAxisException(
        code: HyperAxisErrorCode.invalidArgument,
        message: 'Log capacity must be between 1 and $maximumCapacity.',
        details: <String, Object?>{'capacity': capacity},
      );
    }
    return HyperAxisLoggingConfig._(
      enabled: enabled,
      level: level,
      capacity: capacity,
    );
  }

  const HyperAxisLoggingConfig._({
    required this.enabled,
    required this.level,
    required this.capacity,
  });

  /// Hard limit mirrored from `hyper-axis-logging`.
  static const int maximumCapacity = 10000;

  /// Whether new records are captured.
  final bool enabled;

  /// Most verbose captured severity.
  final HyperAxisLogLevel level;

  /// Maximum retained record count.
  final int capacity;
}

/// One sanitized native diagnostic record.
final class HyperAxisLogRecord {
  /// Creates an immutable diagnostic record.
  const HyperAxisLogRecord({
    required this.sequence,
    required this.timestampMs,
    required this.level,
    required this.target,
    required this.message,
  });

  /// Process-local sequence encoded as a decimal string.
  final String sequence;

  /// Unix epoch milliseconds encoded as a decimal string.
  final String timestampMs;

  /// Record severity.
  final HyperAxisLogLevel level;

  /// Stable subsystem identifier.
  final String target;

  /// Sanitized diagnostic message.
  final String message;
}

/// Diagnostics returned by a snapshot or drain operation.
final class HyperAxisLogBatch {
  /// Creates an immutable log batch.
  HyperAxisLogBatch({
    required this.dropped,
    required List<HyperAxisLogRecord> records,
  }) : records = List<HyperAxisLogRecord>.unmodifiable(records);

  /// Number of evicted records encoded as a decimal string.
  final String dropped;

  /// Records in production order.
  final List<HyperAxisLogRecord> records;
}
