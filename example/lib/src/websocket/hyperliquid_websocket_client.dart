import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'hyperliquid_websocket_models.dart';
import 'hyperliquid_websocket_transport.dart';

final class HyperliquidWebSocketClient {
  HyperliquidWebSocketClient({
    required this.config,
    this.connector = connectHyperliquidWebSocket,
  });

  final HyperliquidWebSocketConfig config;
  final HyperliquidWebSocketConnector connector;
  final Map<String, HyperliquidSubscription> _subscriptions =
      <String, HyperliquidSubscription>{};
  final StreamController<HyperliquidWebSocketState> _stateController =
      StreamController<HyperliquidWebSocketState>.broadcast();
  final StreamController<HyperliquidWebSocketEvent> _eventController =
      StreamController<HyperliquidWebSocketEvent>.broadcast();
  final StreamController<HyperliquidWebSocketFailure> _failureController =
      StreamController<HyperliquidWebSocketFailure>.broadcast();

  HyperliquidWebSocketState _state = HyperliquidWebSocketState.disconnected;
  HyperliquidWebSocketTransport? _transport;
  StreamSubscription<Object?>? _transportSubscription;
  Future<void>? _connectOperation;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _generation = 0;
  int _reconnectAttempt = 0;
  bool _manualDisconnect = true;
  bool _disposed = false;

  HyperliquidWebSocketState get state => _state;
  Stream<HyperliquidWebSocketState> get states => _stateController.stream;
  Stream<HyperliquidWebSocketEvent> get events => _eventController.stream;
  Stream<HyperliquidWebSocketFailure> get failures => _failureController.stream;
  int get subscriptionCount => _subscriptions.length;

  Future<void> connect() {
    _ensureUsable();
    if (_state == HyperliquidWebSocketState.connected) {
      return Future<void>.value();
    }
    final Future<void>? activeOperation = _connectOperation;
    if (activeOperation != null) {
      return activeOperation;
    }

    _manualDisconnect = false;
    _reconnectTimer?.cancel();
    final Future<void> operation = _open(isReconnect: false);
    _connectOperation = operation;
    unawaited(
      operation.then<void>(
        (void value) => _clearConnectOperation(operation),
        onError: (Object error, StackTrace stackTrace) {
          _clearConnectOperation(operation);
        },
      ),
    );
    return operation;
  }

  void subscribe(HyperliquidSubscription subscription) {
    _ensureUsable();
    final bool isNew = !_subscriptions.containsKey(subscription.key);
    _subscriptions[subscription.key] = subscription;
    if (isNew && _state == HyperliquidWebSocketState.connected) {
      _send(subscription.request('subscribe'));
    }
  }

  void unsubscribe(HyperliquidSubscription subscription) {
    _ensureUsable();
    final HyperliquidSubscription? removed = _subscriptions.remove(
      subscription.key,
    );
    if (removed != null && _state == HyperliquidWebSocketState.connected) {
      _send(removed.request('unsubscribe'));
    }
  }

  void clearSubscriptions() {
    _ensureUsable();
    final List<HyperliquidSubscription> active = _subscriptions.values.toList(
      growable: false,
    );
    _subscriptions.clear();
    if (_state == HyperliquidWebSocketState.connected) {
      for (final HyperliquidSubscription subscription in active) {
        _send(subscription.request('unsubscribe'));
      }
    }
  }

  Future<void> disconnect() async {
    if (_disposed) return;
    _manualDisconnect = true;
    _generation += 1;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _heartbeatTimer = null;
    _reconnectTimer = null;
    _connectOperation = null;

    if (_state != HyperliquidWebSocketState.disconnected) {
      _setState(HyperliquidWebSocketState.closing);
    }
    final StreamSubscription<Object?>? transportSubscription =
        _transportSubscription;
    final HyperliquidWebSocketTransport? transport = _transport;
    _transportSubscription = null;
    _transport = null;
    try {
      await transportSubscription?.cancel();
      await transport?.close();
    } on Object {
      _emitFailure('WebSocket close handshake failed.');
    } finally {
      _setState(HyperliquidWebSocketState.disconnected);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    await disconnect();
    _disposed = true;
    await _stateController.close();
    await _eventController.close();
    await _failureController.close();
  }

  Future<void> _open({required bool isReconnect}) async {
    final int generation = ++_generation;
    _setState(
      isReconnect
          ? HyperliquidWebSocketState.reconnecting
          : HyperliquidWebSocketState.connecting,
    );
    try {
      final HyperliquidWebSocketTransport transport = await connector(
        config.endpoint,
        config.connectTimeout,
      );
      if (_disposed || _manualDisconnect || generation != _generation) {
        await transport.close();
        return;
      }

      _transport = transport;
      _transportSubscription = transport.events.listen(
        (Object? frame) => _handleFrame(frame, generation),
        onError: (Object error, StackTrace stackTrace) {
          _handleTransportFailure('WebSocket transport error.', generation);
        },
        onDone: () {
          _handleTransportFailure('WebSocket connection closed.', generation);
        },
        cancelOnError: true,
      );
      _reconnectAttempt = 0;
      _state = HyperliquidWebSocketState.connected;
      _startHeartbeat(generation);
      for (final HyperliquidSubscription subscription
          in _subscriptions.values) {
        _send(subscription.request('subscribe'));
      }
      if (_state == HyperliquidWebSocketState.connected &&
          !_stateController.isClosed) {
        _stateController.add(HyperliquidWebSocketState.connected);
      }
    } on Object {
      if (generation == _generation && !_manualDisconnect && !_disposed) {
        _emitFailure('Unable to connect to Hyperliquid WebSocket.');
        _setState(HyperliquidWebSocketState.disconnected);
        _scheduleReconnect();
      }
      rethrow;
    }
  }

  void _handleFrame(Object? frame, int generation) {
    if (generation != _generation || _disposed) return;
    try {
      final String text = switch (frame) {
        String value => value,
        List<int> bytes => utf8.decode(bytes),
        _ => throw const FormatException('Unsupported WebSocket frame.'),
      };
      final Object? decoded = jsonDecode(text);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Expected a JSON object.');
      }
      final Object? channelValue = decoded['channel'];
      if (channelValue is! String || channelValue.isEmpty) {
        throw const FormatException('Missing WebSocket channel.');
      }
      _eventController.add(
        HyperliquidWebSocketEvent(
          channel: channelValue,
          data: decoded['data'],
          receivedAt: DateTime.now().toUtc(),
        ),
      );
    } on FormatException {
      _emitFailure('Ignored malformed Hyperliquid WebSocket message.');
    }
  }

  void _handleTransportFailure(String message, int generation) {
    if (generation != _generation || _manualDisconnect || _disposed) return;
    _generation += 1;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _transportSubscription = null;
    _transport = null;
    _setState(HyperliquidWebSocketState.disconnected);
    _emitFailure(message);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_manualDisconnect || _disposed || _reconnectTimer != null) return;
    final int? maximumAttempts = config.maximumReconnectAttempts;
    if (maximumAttempts != null && _reconnectAttempt >= maximumAttempts) {
      _emitFailure('WebSocket reconnect attempts exhausted.');
      return;
    }

    _reconnectAttempt += 1;
    final Duration delay = _reconnectDelay(_reconnectAttempt);
    _setState(HyperliquidWebSocketState.reconnecting);
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      unawaited(
        _open(isReconnect: true).catchError((Object error) {
          // `_open` already emits a sanitized failure and schedules the next try.
        }),
      );
    });
  }

  Duration _reconnectDelay(int attempt) {
    final int exponent = min(attempt - 1, 30);
    final int multiplier = 1 << exponent;
    final int milliseconds = min(
      config.initialReconnectDelay.inMilliseconds * multiplier,
      config.maximumReconnectDelay.inMilliseconds,
    );
    return Duration(milliseconds: milliseconds);
  }

  void _startHeartbeat(int generation) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(config.heartbeatInterval, (Timer timer) {
      if (generation != _generation ||
          _state != HyperliquidWebSocketState.connected) {
        timer.cancel();
        return;
      }
      _send(const <String, Object?>{'method': 'ping'});
    });
  }

  void _send(Map<String, Object?> message) {
    final HyperliquidWebSocketTransport? transport = _transport;
    if (transport == null || _state != HyperliquidWebSocketState.connected) {
      return;
    }
    try {
      transport.send(jsonEncode(message));
    } on Object {
      _handleTransportFailure(
        'Unable to send Hyperliquid WebSocket message.',
        _generation,
      );
    }
  }

  void _setState(HyperliquidWebSocketState nextState) {
    if (_state == nextState) return;
    _state = nextState;
    if (!_stateController.isClosed) {
      _stateController.add(nextState);
    }
  }

  void _clearConnectOperation(Future<void> operation) {
    if (identical(_connectOperation, operation)) {
      _connectOperation = null;
    }
  }

  void _emitFailure(String message) {
    if (!_failureController.isClosed) {
      _failureController.add(
        HyperliquidWebSocketFailure(
          message: message,
          reconnectAttempt: _reconnectAttempt,
        ),
      );
    }
  }

  void _ensureUsable() {
    if (_disposed) {
      throw StateError('HyperliquidWebSocketClient is disposed.');
    }
  }
}
