import '../error/hyper_axis_exception.dart';
import '../generated/api/orders.dart' as native_orders;
import '../generated/api/runtime.dart' as native;
import '../generated/frb_generated.dart';
import '../logging/hyper_axis_log.dart';
import '../models/orders.dart';
import 'hyper_axis_bridge.dart';
import 'hyper_axis_bridge_codec.dart';

/// Production bridge backed by generated Flutter Rust Bridge bindings.
final class FrbHyperAxisBridge implements HyperAxisBridge {
  const FrbHyperAxisBridge._();

  /// Initializes the generated bridge exactly once at the client layer.
  static Future<FrbHyperAxisBridge> initialize() async {
    try {
      await HyperAxisRustLib.init();
      return const FrbHyperAxisBridge._();
    } on Object catch (error, stackTrace) {
      // FRB installs its entrypoint state before running Rust initializers. If
      // an initializer fails, leaving that partial state installed makes the
      // next init attempt fail immediately with "already initialized".
      if (HyperAxisRustLib.instance.initialized) {
        HyperAxisRustLib.dispose();
      }
      throw HyperAxisException(
        code: HyperAxisErrorCode.bridgeUnavailable,
        message: 'Unable to initialize the HyperAxis native bridge.',
        cause: error,
        causeStackTrace: stackTrace,
      );
    }
  }

  @override
  String get protocolVersion => _invoke(
    operation: 'protocolVersion',
    errorCode: HyperAxisErrorCode.bridgeFailure,
    invoke: native.protocolVersion,
  );

  @override
  String normalizeDecimal(String value) {
    return _invoke(
      operation: 'normalizeDecimal',
      errorCode: HyperAxisErrorCode.protocol,
      invoke: () => native.normalizeDecimal(value: value),
    );
  }

  @override
  HyperAxisPreparedOrder prepareLimitOrder(HyperAxisLimitOrderRequest request) {
    final String json = _invoke(
      operation: 'prepareLimitOrder',
      errorCode: HyperAxisErrorCode.protocol,
      invoke: () => native_orders.prepareLimitOrderJson(
        requestJson: request.toBridgeJson(),
      ),
    );
    return HyperAxisBridgeCodec.decodePreparedOrder(json);
  }

  @override
  HyperAxisFinalizedAction finalizeOrder({
    required HyperAxisPreparedOrder prepared,
    required HyperAxisSignature signature,
    required String expectedSigner,
  }) {
    final String json = _invoke(
      operation: 'finalizeOrder',
      errorCode: HyperAxisErrorCode.signing,
      invoke: () => native_orders.finalizeOrderJson(
        preparedJson: prepared.bridgeJson,
        r: signature.r,
        s: signature.s,
        v: signature.v,
        expectedSigner: expectedSigner,
      ),
    );
    return HyperAxisBridgeCodec.decodeFinalizedAction(json);
  }

  @override
  HyperAxisLoggingConfig configureLogging(HyperAxisLoggingConfig config) {
    final String json = _invoke(
      operation: 'configureLogging',
      errorCode: HyperAxisErrorCode.invalidArgument,
      invoke: () => native.configureLoggingJson(
        enabled: config.enabled,
        level: config.level.wireName,
        capacity: config.capacity,
      ),
    );
    return HyperAxisBridgeCodec.decodeLoggingConfig(json);
  }

  @override
  HyperAxisLogBatch snapshotLogs() {
    final String json = _invoke(
      operation: 'snapshotLogs',
      errorCode: HyperAxisErrorCode.bridgeFailure,
      invoke: native.snapshotLogsJson,
    );
    return HyperAxisBridgeCodec.decodeLogBatch(json);
  }

  @override
  HyperAxisLogBatch drainLogs() {
    final String json = _invoke(
      operation: 'drainLogs',
      errorCode: HyperAxisErrorCode.bridgeFailure,
      invoke: native.drainLogsJson,
    );
    return HyperAxisBridgeCodec.decodeLogBatch(json);
  }

  @override
  void clearLogs() {
    _invoke<void>(
      operation: 'clearLogs',
      errorCode: HyperAxisErrorCode.bridgeFailure,
      invoke: native.clearLogs,
    );
  }
}

T _invoke<T>({
  required String operation,
  required HyperAxisErrorCode errorCode,
  required T Function() invoke,
}) {
  try {
    return invoke();
  } on HyperAxisException {
    rethrow;
  } on Object catch (error, stackTrace) {
    throw HyperAxisException(
      code: errorCode,
      message: 'HyperAxis native operation failed: $operation',
      details: <String, Object?>{'operation': operation},
      cause: error,
      causeStackTrace: stackTrace,
    );
  }
}
