import 'dart:async';
import 'dart:io';

abstract interface class HyperliquidWebSocketTransport {
  Stream<Object?> get events;

  void send(String text);

  Future<void> close();
}

typedef HyperliquidWebSocketConnector =
    Future<HyperliquidWebSocketTransport> Function(
      Uri endpoint,
      Duration timeout,
    );

Future<HyperliquidWebSocketTransport> connectHyperliquidWebSocket(
  Uri endpoint,
  Duration timeout,
) async {
  final WebSocket socket = await WebSocket.connect(
    endpoint.toString(),
  ).timeout(timeout);
  return IoHyperliquidWebSocketTransport(socket);
}

final class IoHyperliquidWebSocketTransport
    implements HyperliquidWebSocketTransport {
  IoHyperliquidWebSocketTransport(this._socket);

  final WebSocket _socket;

  @override
  Stream<Object?> get events => _socket;

  @override
  void send(String text) {
    _socket.add(text);
  }

  @override
  Future<void> close() async {
    await _socket.close(WebSocketStatus.normalClosure, 'client disconnect');
  }
}
