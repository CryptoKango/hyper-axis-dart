import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hyper_axis/hyper_axis.dart';

import 'websocket/hyperliquid_websocket_client.dart';
import 'websocket/hyperliquid_websocket_models.dart';

enum HyperAxisDemoStatus { initializing, ready, failed }

/// 示例页状态控制器。
///
/// 它只演示协议数据准备，不持有私钥，也不执行签名或发送网络请求。
final class HyperAxisDemoController extends ChangeNotifier {
  HyperAxisDemoController() {
    _webSocketStateSubscription = _webSocket.states.listen((
      HyperliquidWebSocketState state,
    ) {
      _webSocketState = state;
      _notify();
    });
    _webSocketEventSubscription = _webSocket.events.listen(
      _handleWebSocketEvent,
    );
    _webSocketFailureSubscription = _webSocket.failures.listen((
      HyperliquidWebSocketFailure failure,
    ) {
      _webSocketError = failure.message;
      _notify();
    });
  }

  final HyperliquidWebSocketClient _webSocket = HyperliquidWebSocketClient(
    config: HyperliquidWebSocketConfig(
      network: HyperAxisNetwork.testnet,
      maximumReconnectAttempts: 8,
    ),
  );
  late final StreamSubscription<HyperliquidWebSocketState>
  _webSocketStateSubscription;
  late final StreamSubscription<HyperliquidWebSocketEvent>
  _webSocketEventSubscription;
  late final StreamSubscription<HyperliquidWebSocketFailure>
  _webSocketFailureSubscription;
  HyperAxisDemoStatus _status = HyperAxisDemoStatus.initializing;
  HyperAxisClient? _client;
  HyperAxisPreparedOrder? _preparedOrder;
  HyperAxisFinalizedAction? _finalizedAction;
  HyperAxisLogBatch? _logBatch;
  String? _normalizedDecimal;
  String? _errorMessage;
  bool _loggingEnabled = false;
  HyperAxisLogLevel _logLevel = HyperAxisLogLevel.info;
  HyperliquidWebSocketState _webSocketState =
      HyperliquidWebSocketState.disconnected;
  Map<String, String> _midPrices = const <String, String>{};
  DateTime? _lastMarketUpdate;
  String? _webSocketError;
  bool _marketStreamRequested = false;
  bool _disposed = false;

  HyperAxisDemoStatus get status => _status;
  HyperAxisPreparedOrder? get preparedOrder => _preparedOrder;
  HyperAxisFinalizedAction? get finalizedAction => _finalizedAction;
  HyperAxisLogBatch? get logBatch => _logBatch;
  String? get normalizedDecimal => _normalizedDecimal;
  String? get errorMessage => _errorMessage;
  bool get loggingEnabled => _loggingEnabled;
  HyperAxisLogLevel get logLevel => _logLevel;
  String? get protocolVersion => _client?.protocolVersion;
  HyperliquidWebSocketState get webSocketState => _webSocketState;
  Map<String, String> get midPrices => _midPrices;
  DateTime? get lastMarketUpdate => _lastMarketUpdate;
  String? get webSocketError => _webSocketError;

  Future<void> connectMarketStream() async {
    _marketStreamRequested = true;
    await _connectMarketStream();
  }

  Future<void> _connectMarketStream() async {
    _webSocketError = null;
    _webSocket.subscribe(HyperliquidSubscription.allMids());
    try {
      await _webSocket.connect();
    } on Object {
      _webSocketError = '连接失败，客户端将按退避策略自动重试。';
      _notify();
    }
  }

  Future<void> disconnectMarketStream() async {
    _marketStreamRequested = false;
    await _webSocket.disconnect();
  }

  Future<void> pauseMarketStream() async {
    if (_marketStreamRequested) {
      await _webSocket.disconnect();
    }
  }

  Future<void> resumeMarketStream() async {
    if (_marketStreamRequested) {
      await _connectMarketStream();
    }
  }

  Future<void> initialize() async {
    _status = HyperAxisDemoStatus.initializing;
    _errorMessage = null;
    _notify();

    try {
      _client = await HyperAxisClient.initialize();
      _status = HyperAxisDemoStatus.ready;
    } on HyperAxisException catch (error) {
      _status = HyperAxisDemoStatus.failed;
      _errorMessage = _describe(error);
    } on Object {
      _status = HyperAxisDemoStatus.failed;
      _errorMessage = 'Native Core 初始化失败。';
    }
    _notify();
  }

  void normalizeDecimal(String value) {
    _run(() {
      _normalizedDecimal = _requireClient().normalizeDecimal(value);
    });
  }

  void configureLogging({
    required bool enabled,
    required HyperAxisLogLevel level,
  }) {
    _run(() {
      final HyperAxisLoggingConfig applied = _requireClient().configureLogging(
        HyperAxisLoggingConfig(enabled: enabled, level: level, capacity: 100),
      );
      _loggingEnabled = applied.enabled;
      _logLevel = applied.level;
      _refreshLogs();
    });
  }

  void prepareLimitOrder({
    required HyperAxisNetwork network,
    required String asset,
    required HyperAxisMarketKind marketKind,
    required String sizeDecimals,
    required bool isBuy,
    required String limitPrice,
    required String size,
    required bool reduceOnly,
    required HyperAxisTimeInForce timeInForce,
    required HyperAxisOrderGrouping grouping,
    required String nonce,
    required String clientOrderId,
    required String vaultAddress,
    required String expiresAfter,
  }) {
    _run(() {
      final int? parsedAsset = int.tryParse(asset);
      final int? parsedSizeDecimals = int.tryParse(sizeDecimals);
      if (parsedAsset == null || parsedSizeDecimals == null) {
        throw HyperAxisException(
          code: HyperAxisErrorCode.invalidArgument,
          message: 'asset 与 sizeDecimals 必须是整数。',
        );
      }

      final String normalizedNonce = nonce.trim().isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : nonce.trim();
      _preparedOrder = _requireClient().prepareLimitOrder(
        HyperAxisLimitOrderRequest(
          network: network,
          asset: parsedAsset,
          marketKind: marketKind,
          sizeDecimals: parsedSizeDecimals,
          isBuy: isBuy,
          limitPrice: limitPrice,
          size: size,
          reduceOnly: reduceOnly,
          timeInForce: timeInForce,
          clientOrderId: _nullIfEmpty(clientOrderId),
          grouping: grouping,
          nonce: normalizedNonce,
          vaultAddress: _nullIfEmpty(vaultAddress),
          expiresAfter: _nullIfEmpty(expiresAfter),
        ),
      );
      _finalizedAction = null;
      _refreshLogs();
    });
  }

  void finalizeOrder({
    required String signatureR,
    required String signatureS,
    required String signatureV,
    required String expectedSigner,
  }) {
    _run(() {
      final HyperAxisPreparedOrder? prepared = _preparedOrder;
      if (prepared == null) {
        throw HyperAxisException(
          code: HyperAxisErrorCode.invalidArgument,
          message: '请先生成待签数据。',
        );
      }
      final int? recoveryId = int.tryParse(signatureV.trim());
      if (recoveryId == null) {
        throw HyperAxisException(
          code: HyperAxisErrorCode.invalidArgument,
          message: '签名 v 必须是整数。',
        );
      }
      if (expectedSigner.trim().isEmpty) {
        throw HyperAxisException(
          code: HyperAxisErrorCode.invalidArgument,
          message: 'expectedSigner 不能为空。',
        );
      }

      _finalizedAction = _requireClient().finalizeOrder(
        prepared: prepared,
        signature: HyperAxisSignature(
          r: signatureR.trim(),
          s: signatureS.trim(),
          v: recoveryId,
        ),
        expectedSigner: expectedSigner.trim(),
      );
      _refreshLogs();
    });
  }

  void snapshotLogs() {
    _run(_refreshLogs);
  }

  void drainLogs() {
    _run(() {
      _logBatch = _requireClient().drainLogs();
    });
  }

  void clearLogs() {
    _run(() {
      _requireClient().clearLogs();
      _refreshLogs();
    });
  }

  void _refreshLogs() {
    _logBatch = _requireClient().snapshotLogs();
  }

  HyperAxisClient _requireClient() {
    final HyperAxisClient? client = _client;
    if (client == null) {
      throw HyperAxisException(
        code: HyperAxisErrorCode.bridgeUnavailable,
        message: 'Native Core 尚未初始化。',
      );
    }
    return client;
  }

  void _run(VoidCallback operation) {
    _errorMessage = null;
    try {
      operation();
    } on HyperAxisException catch (error) {
      _errorMessage = _describe(error);
    } on Object {
      _errorMessage = '操作失败，请检查输入。';
    }
    _notify();
  }

  String _describe(HyperAxisException error) {
    return '${error.code.name}: ${error.message}';
  }

  String? _nullIfEmpty(String value) {
    final String normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  void _handleWebSocketEvent(HyperliquidWebSocketEvent event) {
    if (event.channel != 'allMids') return;
    final Object? data = event.data;
    if (data is! Map<String, Object?>) return;
    final Object? mids = data['mids'];
    if (mids is! Map<String, Object?>) return;

    final Map<String, String> prices = <String, String>{};
    for (final MapEntry<String, Object?> entry in mids.entries) {
      final Object? value = entry.value;
      if (value is String) {
        prices[entry.key] = value;
      }
    }
    _midPrices = Map<String, String>.unmodifiable(prices);
    _lastMarketUpdate = event.receivedAt;
    _webSocketError = null;
    _notify();
  }

  Future<void> _disposeWebSocket() async {
    await _webSocketStateSubscription.cancel();
    await _webSocketEventSubscription.cancel();
    await _webSocketFailureSubscription.cancel();
    await _webSocket.dispose();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_disposeWebSocket());
    super.dispose();
  }
}
