import '../logging/hyper_axis_log.dart';
import '../models/accounts.dart';
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
