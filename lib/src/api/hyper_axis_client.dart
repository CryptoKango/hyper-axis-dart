import '../bridge/frb_hyper_axis_bridge.dart';
import '../bridge/hyper_axis_bridge.dart';
import '../error/hyper_axis_exception.dart';
import '../logging/hyper_axis_log.dart';
import '../models/orders.dart';
import '../version.dart';

/// Stable application-facing facade over the HyperAxis Rust bridge.
///
/// One instance may be shared by an application. Signer-local state such as a
/// nonce manager is exposed as an explicit session object instead of global
/// mutable state.
final class HyperAxisClient {
  static Future<HyperAxisBridge>? _nativeBridge;

  /// Initializes the generated native bridge and returns a client facade.
  ///
  /// Concurrent calls share one initialization attempt. Throws
  /// [HyperAxisException] with [HyperAxisErrorCode.bridgeUnavailable] when no
  /// compatible native artifact can be loaded.
  static Future<HyperAxisClient> initialize() async {
    final HyperAxisBridge bridge = await (_nativeBridge ??=
        FrbHyperAxisBridge.initialize());
    return HyperAxisClient.withBridge(bridge);
  }

  /// Creates a client backed by a generated or test bridge implementation.
  ///
  /// The bridge protocol is checked immediately so an incompatible native
  /// artifact cannot be used for later operations.
  HyperAxisClient.withBridge(this._bridge) {
    final String actualVersion = _guard(
      operation: 'protocolVersion',
      invoke: () => _bridge.protocolVersion,
    );
    if (actualVersion != hyperAxisRustProtocolVersion) {
      throw HyperAxisException(
        code: HyperAxisErrorCode.incompatibleVersion,
        message: 'The loaded HyperAxis Rust core is incompatible.',
        details: <String, Object?>{
          'expected': hyperAxisRustProtocolVersion,
          'actual': actualVersion,
        },
      );
    }
  }

  final HyperAxisBridge _bridge;

  /// Semantic version reported by the loaded Rust core.
  String get protocolVersion => _guard(
    operation: 'protocolVersion',
    invoke: () => _bridge.protocolVersion,
  );

  /// Canonicalizes an exact decimal without using binary floating point.
  ///
  /// Throws [HyperAxisException] when the value is not valid protocol decimal
  /// syntax or when the native bridge is unavailable.
  String normalizeDecimal(String value) {
    return _guard(
      operation: 'normalizeDecimal',
      invoke: () => _bridge.normalizeDecimal(value),
    );
  }

  /// Validates and prepares a limit order without handling private keys.
  ///
  /// Sign [HyperAxisPreparedOrder.signingDigestHex] with the expected account,
  /// then pass the recoverable signature to [finalizeOrder].
  HyperAxisPreparedOrder prepareLimitOrder(HyperAxisLimitOrderRequest request) {
    return _guard(
      operation: 'prepareLimitOrder',
      invoke: () => _bridge.prepareLimitOrder(request),
    );
  }

  /// Verifies a platform signature and builds the canonical exchange request.
  HyperAxisFinalizedAction finalizeOrder({
    required HyperAxisPreparedOrder prepared,
    required HyperAxisSignature signature,
    required String expectedSigner,
  }) {
    return _guard(
      operation: 'finalizeOrder',
      invoke: () => _bridge.finalizeOrder(
        prepared: prepared,
        signature: signature,
        expectedSigner: expectedSigner,
      ),
    );
  }

  /// Enables, disables, or reconfigures sanitized Rust diagnostics.
  HyperAxisLoggingConfig configureLogging(HyperAxisLoggingConfig config) {
    return _guard(
      operation: 'configureLogging',
      invoke: () => _bridge.configureLogging(config),
    );
  }

  /// Returns retained diagnostics without removing them.
  HyperAxisLogBatch snapshotLogs() {
    return _guard(operation: 'snapshotLogs', invoke: _bridge.snapshotLogs);
  }

  /// Returns and removes retained diagnostics.
  HyperAxisLogBatch drainLogs() {
    return _guard(operation: 'drainLogs', invoke: _bridge.drainLogs);
  }

  /// Clears retained diagnostics.
  void clearLogs() {
    _guard<void>(operation: 'clearLogs', invoke: _bridge.clearLogs);
  }

  T _guard<T>({required String operation, required T Function() invoke}) {
    try {
      return invoke();
    } on HyperAxisException {
      rethrow;
    } on Object catch (error, stackTrace) {
      throw HyperAxisException(
        code: HyperAxisErrorCode.bridgeFailure,
        message: 'HyperAxis bridge operation failed: $operation',
        details: <String, Object?>{'operation': operation},
        cause: error,
        causeStackTrace: stackTrace,
      );
    }
  }
}
