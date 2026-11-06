import '../error/hyper_axis_exception.dart';
import '../generated/api/accounts.dart' as native_accounts;
import '../generated/api/orders.dart' as native_orders;
import '../generated/api/risk.dart' as native_risk;
import '../generated/api/runtime.dart' as native;
import '../generated/api/transport.dart' as native_transport;
import '../generated/api/users.dart' as native_users;
import '../generated/frb_generated.dart';
import '../logging/hyper_axis_log.dart';
import '../models/accounts.dart';
import '../models/orders.dart';
import '../models/risk.dart';
import '../models/transport.dart';
import '../models/users.dart';
import 'hyper_axis_account_bridge_codec.dart';
import 'hyper_axis_bridge.dart';
import 'hyper_axis_bridge_codec.dart';
import 'hyper_axis_transport_bridge_codec.dart';

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
  HyperAxisPreparedInfoQuery prepareInfoQuery(HyperAxisInfoQuery query) {
    final json = _invoke(
      operation: 'prepareInfoQuery',
      errorCode: HyperAxisErrorCode.protocol,
      invoke: () => native_transport.prepareInfoQueryJson(
        queryJson: query.toBridgeJson(),
      ),
    );
    return HyperAxisTransportBridgeCodec.decodePreparedInfoQuery(json);
  }

  @override
  HyperAxisHttpRequest buildTypedInfoRequest({
    required HyperAxisNetwork network,
    required HyperAxisInfoQuery query,
  }) {
    final json = _invoke(
      operation: 'buildTypedInfoRequest',
      errorCode: HyperAxisErrorCode.protocol,
      invoke: () => native_transport.buildTypedInfoRequestJson(
        network: network.wireName,
        queryJson: query.toBridgeJson(),
      ),
    );
    return HyperAxisAccountBridgeCodec.decodeHttpRequest(json);
  }

  @override
  HyperAxisParsedHttpResponse parseHttpResponse({
    required HyperAxisRequestKind requestKind,
    required int statusCode,
    required String body,
  }) {
    final json = _invoke(
      operation: 'parseHttpResponse',
      errorCode: HyperAxisErrorCode.protocol,
      invoke: () => native_transport.parseHttpResponseJson(
        requestKind: requestKind.wireName,
        statusCode: statusCode,
        body: body,
      ),
    );
    return HyperAxisTransportBridgeCodec.decodeHttpResponse(json);
  }

  @override
  Object? parsePerpDexesResponse(String body) {
    final json = _invoke(
      operation: 'parsePerpDexesResponse',
      errorCode: HyperAxisErrorCode.protocol,
      invoke: () => native_transport.parsePerpDexsResponseJson(body: body),
    );
    return HyperAxisTransportBridgeCodec.decodeJsonValue(
      json,
      'perpetual DEX response',
    );
  }

  @override
  Object? parsePerpMetaAndAssetContextsResponse(String body) {
    final json = _invoke(
      operation: 'parsePerpMetaAndAssetContextsResponse',
      errorCode: HyperAxisErrorCode.protocol,
      invoke: () => native_transport.parsePerpMetaAndAssetContextsResponseJson(
        body: body,
      ),
    );
    return HyperAxisTransportBridgeCodec.decodeJsonValue(
      json,
      'perpetual metadata response',
    );
  }

  @override
  String websocketUrl(HyperAxisNetwork network) => _invoke(
    operation: 'websocketUrl',
    errorCode: HyperAxisErrorCode.protocol,
    invoke: () => native_transport.websocketUrl(network: network.wireName),
  );

  @override
  String websocketSubscribe(HyperAxisSubscription subscription) => _invoke(
    operation: 'websocketSubscribe',
    errorCode: HyperAxisErrorCode.protocol,
    invoke: () => native_transport.websocketSubscribeJson(
      subscriptionJson: subscription.toBridgeJson(),
    ),
  );

  @override
  String websocketUnsubscribe(HyperAxisSubscription subscription) => _invoke(
    operation: 'websocketUnsubscribe',
    errorCode: HyperAxisErrorCode.protocol,
    invoke: () => native_transport.websocketUnsubscribeJson(
      subscriptionJson: subscription.toBridgeJson(),
    ),
  );

  @override
  String websocketPing() => _invoke(
    operation: 'websocketPing',
    errorCode: HyperAxisErrorCode.protocol,
    invoke: native_transport.websocketPingJson,
  );

  @override
  HyperAxisWebSocketMessage parseWebSocketMessage(String message) {
    final json = _invoke(
      operation: 'parseWebSocketMessage',
      errorCode: HyperAxisErrorCode.protocol,
      invoke: () =>
          native_transport.parseWebsocketMessageJson(message: message),
    );
    return HyperAxisTransportBridgeCodec.decodeWebSocketMessage(json);
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
  HyperAxisPreparedUserAction prepareApproveBuilderFee(
    HyperAxisApproveBuilderFeeRequest request,
  ) {
    final String json = _invoke(
      operation: 'prepareApproveBuilderFee',
      errorCode: HyperAxisErrorCode.protocol,
      invoke: () => native_users.prepareApproveBuilderFeeJson(
        requestJson: request.toBridgeJson(),
      ),
    );
    return HyperAxisAccountBridgeCodec.decodePreparedUserAction(json);
  }

  @override
  HyperAxisFinalizedAction finalizeApproveBuilderFee({
    required HyperAxisPreparedUserAction prepared,
    required HyperAxisSignature signature,
    required String expectedSigner,
  }) {
    final String json = _invoke(
      operation: 'finalizeApproveBuilderFee',
      errorCode: HyperAxisErrorCode.signing,
      invoke: () => native_users.finalizeApproveBuilderFeeJson(
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
  HyperAxisPreparedOrder prepareCancel(HyperAxisCancelRequest request) {
    final String json = _invoke(
      operation: 'prepareCancel',
      errorCode: HyperAxisErrorCode.protocol,
      invoke: () =>
          native_orders.prepareCancelJson(requestJson: request.toBridgeJson()),
    );
    return HyperAxisBridgeCodec.decodePreparedOrder(json);
  }

  @override
  HyperAxisFinalizedAction finalizeCancel({
    required HyperAxisPreparedOrder prepared,
    required HyperAxisSignature signature,
    required String expectedSigner,
  }) {
    final String json = _invoke(
      operation: 'finalizeCancel',
      errorCode: HyperAxisErrorCode.signing,
      invoke: () => native_orders.finalizeCancelJson(
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
  HyperAxisPreparedLeverageUpdate prepareUpdateLeverage(
    HyperAxisUpdateLeverageRequest request,
  ) {
    final String json = _invoke(
      operation: 'prepareUpdateLeverage',
      errorCode: HyperAxisErrorCode.protocol,
      invoke: () => native_risk.prepareUpdateLeverageJson(
        requestJson: request.toBridgeJson(),
      ),
    );
    return HyperAxisBridgeCodec.decodePreparedLeverageUpdate(json);
  }

  @override
  HyperAxisFinalizedAction finalizeUpdateLeverage({
    required HyperAxisPreparedLeverageUpdate prepared,
    required HyperAxisSignature signature,
    required String expectedSigner,
  }) {
    final String json = _invoke(
      operation: 'finalizeUpdateLeverage',
      errorCode: HyperAxisErrorCode.signing,
      invoke: () => native_risk.finalizeUpdateLeverageJson(
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
  HyperAxisPreparedUserAction prepareWithdraw(
    HyperAxisWithdrawRequest request,
  ) {
    final String json = _invoke(
      operation: 'prepareWithdraw',
      errorCode: HyperAxisErrorCode.protocol,
      invoke: () => native_accounts.prepareWithdrawJson(
        requestJson: request.toBridgeJson(),
      ),
    );
    return HyperAxisAccountBridgeCodec.decodePreparedUserAction(json);
  }

  @override
  HyperAxisFinalizedAction finalizeWithdraw({
    required HyperAxisPreparedUserAction prepared,
    required HyperAxisSignature signature,
    required String expectedSigner,
  }) {
    final String json = _invoke(
      operation: 'finalizeWithdraw',
      errorCode: HyperAxisErrorCode.signing,
      invoke: () => native_accounts.finalizeWithdrawJson(
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
