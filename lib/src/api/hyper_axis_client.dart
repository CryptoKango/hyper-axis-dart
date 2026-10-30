import '../bridge/frb_hyper_axis_bridge.dart';
import '../bridge/hyper_axis_bridge.dart';
import '../error/hyper_axis_exception.dart';
import '../logging/hyper_axis_log.dart';
import '../models/accounts.dart';
import '../models/orders.dart';
import '../version.dart';
import 'retryable_async_cache.dart';

/// Stable application-facing facade over the HyperAxis Rust bridge.
///
/// One instance may be shared by an application. Signer-local state such as a
/// nonce manager is exposed as an explicit session object instead of global
/// mutable state.
final class HyperAxisClient {
  static final RetryableAsyncCache<HyperAxisBridge> _nativeBridge =
      RetryableAsyncCache<HyperAxisBridge>();

  /// Initializes the generated native bridge and returns a client facade.
  ///
  /// Concurrent calls share one initialization attempt. Throws
  /// [HyperAxisException] with [HyperAxisErrorCode.bridgeUnavailable] when no
  /// compatible native artifact can be loaded.
  static Future<HyperAxisClient> initialize() async {
    final HyperAxisBridge bridge = await _nativeBridge.getOrInitialize(
      FrbHyperAxisBridge.initialize,
    );
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

  /// Builds a perpetual account `POST /info` request.
  HyperAxisHttpRequest buildPerpAccountRequest({
    required HyperAxisNetwork network,
    required String user,
    String dex = '',
  }) {
    return _guard(
      operation: 'buildPerpAccountRequest',
      invoke: () => _bridge.buildPerpAccountRequest(
        network: network,
        user: user,
        dex: dex,
      ),
    );
  }

  /// Builds a spot account `POST /info` request.
  HyperAxisHttpRequest buildSpotAccountRequest({
    required HyperAxisNetwork network,
    required String user,
  }) {
    return _guard(
      operation: 'buildSpotAccountRequest',
      invoke: () =>
          _bridge.buildSpotAccountRequest(network: network, user: user),
    );
  }

  /// Validates and decodes a perpetual account response body.
  HyperAxisPerpAccountState parsePerpAccountState(String body) {
    return _guard(
      operation: 'parsePerpAccountState',
      invoke: () => _bridge.parsePerpAccountState(body),
    );
  }

  /// Validates and decodes a spot account response body.
  HyperAxisSpotAccountState parseSpotAccountState(String body) {
    return _guard(
      operation: 'parseSpotAccountState',
      invoke: () => _bridge.parseSpotAccountState(body),
    );
  }

  /// Returns the official account WebSocket endpoint.
  String accountWebSocketUrl(HyperAxisNetwork network) {
    return _guard(
      operation: 'accountWebSocketUrl',
      invoke: () => _bridge.accountWebSocketUrl(network),
    );
  }

  /// Builds a perpetual-account WebSocket subscription command.
  String subscribePerpAccount({required String user, String dex = ''}) {
    return _guard(
      operation: 'subscribePerpAccount',
      invoke: () => _bridge.subscribePerpAccount(user: user, dex: dex),
    );
  }

  /// Builds a spot-account WebSocket subscription command.
  String subscribeSpotAccount({required String user, bool? isPortfolioMargin}) {
    return _guard(
      operation: 'subscribeSpotAccount',
      invoke: () => _bridge.subscribeSpotAccount(
        user: user,
        isPortfolioMargin: isPortfolioMargin,
      ),
    );
  }

  /// Validates one inbound account WebSocket message.
  HyperAxisAccountWebSocketMessage parseAccountWebSocketMessage(
    String message,
  ) {
    return _guard(
      operation: 'parseAccountWebSocketMessage',
      invoke: () => _bridge.parseAccountWebSocketMessage(message),
    );
  }

  /// Prepares a Spot/Perp USDC transfer for main-wallet signing.
  HyperAxisPreparedUserAction prepareUsdClassTransfer(
    HyperAxisUsdClassTransferRequest request,
  ) {
    return _guard(
      operation: 'prepareUsdClassTransfer',
      invoke: () => _bridge.prepareUsdClassTransfer(request),
    );
  }

  /// Verifies and finalizes a prepared Spot/Perp USDC transfer.
  HyperAxisFinalizedAction finalizeUsdClassTransfer({
    required HyperAxisPreparedUserAction prepared,
    required HyperAxisSignature signature,
    required String expectedSigner,
  }) {
    return _guard(
      operation: 'finalizeUsdClassTransfer',
      invoke: () => _bridge.finalizeUsdClassTransfer(
        prepared: prepared,
        signature: signature,
        expectedSigner: expectedSigner,
      ),
    );
  }

  /// Builds the canonical `POST /exchange` request for a finalized transfer.
  HyperAxisHttpRequest buildAccountExchangeRequest(
    HyperAxisFinalizedAction finalized,
  ) {
    return _guard(
      operation: 'buildAccountExchangeRequest',
      invoke: () => _bridge.buildAccountExchangeRequest(finalized),
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
