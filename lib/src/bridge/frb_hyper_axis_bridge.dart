import '../error/hyper_axis_exception.dart';
import '../generated/api/accounts.dart' as native_accounts;
import '../generated/api/orders.dart' as native_orders;
import '../generated/api/runtime.dart' as native;
import '../generated/frb_generated.dart';
import '../logging/hyper_axis_log.dart';
import '../models/accounts.dart';
import '../models/orders.dart';
import 'hyper_axis_account_bridge_codec.dart';
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
  HyperAxisHttpRequest buildPerpAccountRequest({
    required HyperAxisNetwork network,
    required String user,
    required String dex,
  }) {
    final String json = _invoke(
      operation: 'buildPerpAccountRequest',
      errorCode: HyperAxisErrorCode.protocol,
      invoke: () => native_accounts.buildPerpAccountRequestJson(
        network: network.wireName,
        user: user,
        dex: dex,
      ),
    );
    return HyperAxisAccountBridgeCodec.decodeHttpRequest(json);
  }

  @override
  HyperAxisHttpRequest buildSpotAccountRequest({
    required HyperAxisNetwork network,
    required String user,
  }) {
    final String json = _invoke(
      operation: 'buildSpotAccountRequest',
      errorCode: HyperAxisErrorCode.protocol,
      invoke: () => native_accounts.buildSpotAccountRequestJson(
        network: network.wireName,
        user: user,
      ),
    );
    return HyperAxisAccountBridgeCodec.decodeHttpRequest(json);
  }

  @override
  HyperAxisPerpAccountState parsePerpAccountState(String body) {
    final String json = _invoke(
      operation: 'parsePerpAccountState',
      errorCode: HyperAxisErrorCode.protocol,
      invoke: () => native_accounts.parsePerpAccountStateJson(body: body),
    );
    return HyperAxisAccountBridgeCodec.decodePerpAccountState(json);
  }

  @override
  HyperAxisSpotAccountState parseSpotAccountState(String body) {
    final String json = _invoke(
      operation: 'parseSpotAccountState',
      errorCode: HyperAxisErrorCode.protocol,
      invoke: () => native_accounts.parseSpotAccountStateJson(body: body),
    );
    return HyperAxisAccountBridgeCodec.decodeSpotAccountState(json);
  }

  @override
  String accountWebSocketUrl(HyperAxisNetwork network) {
    return _invoke(
      operation: 'accountWebSocketUrl',
      errorCode: HyperAxisErrorCode.protocol,
      invoke: () =>
          native_accounts.accountWebsocketUrl(network: network.wireName),
    );
  }

  @override
  String subscribePerpAccount({required String user, required String dex}) {
    return _invoke(
      operation: 'subscribePerpAccount',
      errorCode: HyperAxisErrorCode.protocol,
      invoke: () =>
          native_accounts.subscribePerpAccountJson(user: user, dex: dex),
    );
  }

  @override
  String subscribeSpotAccount({required String user, bool? isPortfolioMargin}) {
    return _invoke(
      operation: 'subscribeSpotAccount',
      errorCode: HyperAxisErrorCode.protocol,
      invoke: () => native_accounts.subscribeSpotAccountJson(
        user: user,
        isPortfolioMargin: isPortfolioMargin,
      ),
    );
  }

  @override
  HyperAxisAccountWebSocketMessage parseAccountWebSocketMessage(
    String message,
  ) {
    final String json = _invoke(
      operation: 'parseAccountWebSocketMessage',
      errorCode: HyperAxisErrorCode.protocol,
      invoke: () =>
          native_accounts.parseAccountWebsocketMessageJson(message: message),
    );
    return HyperAxisAccountBridgeCodec.decodeWebSocketMessage(json);
  }

  @override
  HyperAxisPreparedUserAction prepareUsdClassTransfer(
    HyperAxisUsdClassTransferRequest request,
  ) {
    final String json = _invoke(
      operation: 'prepareUsdClassTransfer',
      errorCode: HyperAxisErrorCode.protocol,
      invoke: () => native_accounts.prepareUsdClassTransferJson(
        requestJson: request.toBridgeJson(),
      ),
    );
    return HyperAxisAccountBridgeCodec.decodePreparedUserAction(json);
  }

  @override
  HyperAxisFinalizedAction finalizeUsdClassTransfer({
    required HyperAxisPreparedUserAction prepared,
    required HyperAxisSignature signature,
    required String expectedSigner,
  }) {
    final String json = _invoke(
      operation: 'finalizeUsdClassTransfer',
      errorCode: HyperAxisErrorCode.signing,
      invoke: () => native_accounts.finalizeUsdClassTransferJson(
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
  HyperAxisHttpRequest buildAccountExchangeRequest(
    HyperAxisFinalizedAction finalized,
  ) {
    final String json = _invoke(
      operation: 'buildAccountExchangeRequest',
      errorCode: HyperAxisErrorCode.protocol,
      invoke: () => native_accounts.buildAccountExchangeRequestJson(
        finalizedJson: finalized.toBridgeJson(),
      ),
    );
    return HyperAxisAccountBridgeCodec.decodeHttpRequest(json);
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
