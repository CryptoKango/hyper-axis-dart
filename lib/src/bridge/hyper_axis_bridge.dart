import '../logging/hyper_axis_log.dart';
import '../models/accounts.dart';
import '../models/orders.dart';
import '../models/risk.dart';
import '../models/transport.dart';
import '../models/users.dart';

/// Typed boundary implemented by the generated Rust bridge adapter.
///
/// Generated bridge classes stay behind this interface so binding generator
/// changes never leak into the public SDK surface.
abstract interface class HyperAxisBridge {
  /// Returns the semantic version reported by `hyper-axis-core`.
  String get protocolVersion;

  /// Returns the canonical wire representation of an exact decimal string.
  String normalizeDecimal(String value);

  /// Validates and canonicalizes one typed Info query.
  HyperAxisPreparedInfoQuery prepareInfoQuery(HyperAxisInfoQuery query);

  /// Builds an official `POST /info` request from a typed query.
  HyperAxisHttpRequest buildTypedInfoRequest({
    required HyperAxisNetwork network,
    required HyperAxisInfoQuery query,
  });

  /// Parses and classifies one host HTTP response.
  HyperAxisParsedHttpResponse parseHttpResponse({
    required HyperAxisRequestKind requestKind,
    required int statusCode,
    required String body,
  });

  /// Validates a `perpDexs` response.
  Object? parsePerpDexesResponse(String body);

  /// Validates a `metaAndAssetCtxs` response.
  Object? parsePerpMetaAndAssetContextsResponse(String body);

  /// Returns the official WebSocket endpoint.
  String websocketUrl(HyperAxisNetwork network);

  /// Builds a validated subscribe command.
  String websocketSubscribe(HyperAxisSubscription subscription);

  /// Builds a validated unsubscribe command.
  String websocketUnsubscribe(HyperAxisSubscription subscription);

  /// Builds the canonical heartbeat command.
  String websocketPing();

  /// Parses one inbound WebSocket envelope.
  HyperAxisWebSocketMessage parseWebSocketMessage(String message);

  /// Validates and prepares one limit order for platform signing.
  HyperAxisPreparedOrder prepareLimitOrder(HyperAxisLimitOrderRequest request);

  /// Validates and prepares one or more trigger orders.
  HyperAxisPreparedOrder prepareTriggerOrders(
    HyperAxisTriggerOrdersRequest request,
  );

  /// Verifies the signature and builds the exact exchange request.
  HyperAxisFinalizedAction finalizeOrder({
    required HyperAxisPreparedOrder prepared,
    required HyperAxisSignature signature,
    required String expectedSigner,
  });

  /// Prepares a maximum Builder Fee approval for main-wallet signing.
  HyperAxisPreparedUserAction prepareApproveBuilderFee(
    HyperAxisApproveBuilderFeeRequest request,
  );

  /// Verifies and finalizes a prepared Builder Fee approval.
  HyperAxisFinalizedAction finalizeApproveBuilderFee({
    required HyperAxisPreparedUserAction prepared,
    required HyperAxisSignature signature,
    required String expectedSigner,
  });

  /// Validates and prepares one or more order cancellations.
  HyperAxisPreparedOrder prepareCancel(HyperAxisCancelRequest request);

  /// Verifies the signature and builds the exact cancel request.
  HyperAxisFinalizedAction finalizeCancel({
    required HyperAxisPreparedOrder prepared,
    required HyperAxisSignature signature,
    required String expectedSigner,
  });

  /// Validates and prepares one leverage update for platform signing.
  HyperAxisPreparedLeverageUpdate prepareUpdateLeverage(
    HyperAxisUpdateLeverageRequest request,
  );

  /// Verifies the signature and builds the leverage exchange request.
  HyperAxisFinalizedAction finalizeUpdateLeverage({
    required HyperAxisPreparedLeverageUpdate prepared,
    required HyperAxisSignature signature,
    required String expectedSigner,
  });

  /// Validates and prepares an isolated-margin delta.
  HyperAxisPreparedLeverageUpdate prepareUpdateIsolatedMargin(
    HyperAxisUpdateIsolatedMarginRequest request,
  );

  /// Verifies and finalizes an isolated-margin delta.
  HyperAxisFinalizedAction finalizeUpdateIsolatedMargin({
    required HyperAxisPreparedLeverageUpdate prepared,
    required HyperAxisSignature signature,
    required String expectedSigner,
  });

  /// Builds a perpetual account HTTP request.
  HyperAxisHttpRequest buildPerpAccountRequest({
    required HyperAxisNetwork network,
    required String user,
    required String dex,
  });

  /// Builds a spot account HTTP request.
  HyperAxisHttpRequest buildSpotAccountRequest({
    required HyperAxisNetwork network,
    required String user,
  });

  /// Validates and decodes a perpetual account response.
  HyperAxisPerpAccountState parsePerpAccountState(String body);

  /// Validates and decodes a spot account response.
  HyperAxisSpotAccountState parseSpotAccountState(String body);

  /// Returns the official account WebSocket URL.
  String accountWebSocketUrl(HyperAxisNetwork network);

  /// Builds a perpetual account subscription command.
  String subscribePerpAccount({required String user, required String dex});

  /// Builds a spot account subscription command.
  String subscribeSpotAccount({required String user, bool? isPortfolioMargin});

  /// Validates and decodes one account WebSocket message.
  HyperAxisAccountWebSocketMessage parseAccountWebSocketMessage(String message);

  /// Prepares a Spot/Perp USDC transfer.
  HyperAxisPreparedUserAction prepareUsdClassTransfer(
    HyperAxisUsdClassTransferRequest request,
  );

  /// Verifies and finalizes a Spot/Perp USDC transfer.
  HyperAxisFinalizedAction finalizeUsdClassTransfer({
    required HyperAxisPreparedUserAction prepared,
    required HyperAxisSignature signature,
    required String expectedSigner,
  });

  /// Prepares a bridge withdrawal.
  HyperAxisPreparedUserAction prepareWithdraw(HyperAxisWithdrawRequest request);

  /// Verifies and finalizes a bridge withdrawal.
  HyperAxisFinalizedAction finalizeWithdraw({
    required HyperAxisPreparedUserAction prepared,
    required HyperAxisSignature signature,
    required String expectedSigner,
  });

  /// Builds the exchange HTTP request for a finalized account action.
  HyperAxisHttpRequest buildAccountExchangeRequest(
    HyperAxisFinalizedAction finalized,
  );

  /// Applies the process-local, sanitized Rust diagnostic configuration.
  HyperAxisLoggingConfig configureLogging(HyperAxisLoggingConfig config);

  /// Returns retained diagnostics without removing them.
  HyperAxisLogBatch snapshotLogs();

  /// Returns and removes all retained diagnostics.
  HyperAxisLogBatch drainLogs();

  /// Removes all retained diagnostics and resets the dropped counter.
  void clearLogs();
}
