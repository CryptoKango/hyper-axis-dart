import '../logging/hyper_axis_log.dart';
import '../models/orders.dart';

/// Typed boundary implemented by the generated Rust bridge adapter.
///
/// Generated bridge classes stay behind this interface so binding generator
/// changes never leak into the public SDK surface.
abstract interface class HyperAxisBridge {
  /// Returns the semantic version reported by `hyper-axis-core`.
  String get protocolVersion;

  /// Returns the canonical wire representation of an exact decimal string.
  String normalizeDecimal(String value);

  /// Validates and prepares one limit order for platform signing.
  HyperAxisPreparedOrder prepareLimitOrder(HyperAxisLimitOrderRequest request);

  /// Verifies the signature and builds the exact exchange request.
  HyperAxisFinalizedAction finalizeOrder({
    required HyperAxisPreparedOrder prepared,
    required HyperAxisSignature signature,
    required String expectedSigner,
  });

  /// Applies the process-local, sanitized Rust diagnostic configuration.
  HyperAxisLoggingConfig configureLogging(HyperAxisLoggingConfig config);

  /// Returns retained diagnostics without removing them.
  HyperAxisLogBatch snapshotLogs();

  /// Returns and removes all retained diagnostics.
  HyperAxisLogBatch drainLogs();

  /// Removes all retained diagnostics and resets the dropped counter.
  void clearLogs();
}
