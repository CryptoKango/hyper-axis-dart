import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_axis/hyper_axis.dart';
import 'package:hyper_axis_example/src/websocket/hyperliquid_websocket_client.dart';
import 'package:hyper_axis_example/src/websocket/hyperliquid_websocket_models.dart';
import 'package:hyper_axis_example/src/websocket/hyperliquid_websocket_transport.dart';

void main() {
  group('HyperliquidWebSocketClient', () {
    test('validates reconnect configuration in release builds', () {
      expect(
        () => HyperliquidWebSocketConfig(
          network: HyperAxisNetwork.testnet,
          heartbeatInterval: Duration.zero,
        ),
        throwsArgumentError,
      );
      expect(
        () => HyperliquidWebSocketConfig(
          network: HyperAxisNetwork.testnet,
          initialReconnectDelay: const Duration(seconds: 2),
          maximumReconnectDelay: const Duration(seconds: 1),
        ),
        throwsArgumentError,
      );
    });

    test('deduplicates subscriptions and sends an exact unsubscribe', () async {
      final _FakeTransport transport = _FakeTransport();
      final HyperliquidWebSocketClient client = HyperliquidWebSocketClient(
        config: HyperliquidWebSocketConfig(
          network: HyperAxisNetwork.testnet,
          heartbeatInterval: const Duration(hours: 1),
        ),
        connector: (Uri endpoint, Duration timeout) async => transport,
      );
      final HyperliquidSubscription subscription = HyperliquidSubscription.bbo(
        coin: 'BTC',
      );

      await client.connect();
      client.subscribe(subscription);
      client.subscribe(subscription);
      client.unsubscribe(subscription);

      expect(transport.sent, <String>[
        jsonEncode(<String, Object?>{
          'method': 'subscribe',
          'subscription': <String, Object?>{'type': 'bbo', 'coin': 'BTC'},
        }),
        jsonEncode(<String, Object?>{
          'method': 'unsubscribe',
          'subscription': <String, Object?>{'type': 'bbo', 'coin': 'BTC'},
        }),
      ]);
      await client.dispose();
    });

    test('subscribes, decodes events, and sends heartbeat pings', () async {
      final _FakeTransport transport = _FakeTransport();
      Uri? connectedEndpoint;
      final HyperliquidWebSocketClient client = HyperliquidWebSocketClient(
        config: HyperliquidWebSocketConfig(
          network: HyperAxisNetwork.testnet,
          heartbeatInterval: Duration(milliseconds: 10),
          maximumReconnectAttempts: 0,
        ),
        connector: (Uri endpoint, Duration timeout) async {
          connectedEndpoint = endpoint;
          return transport;
        },
      );
      final Future<HyperliquidWebSocketEvent> nextEvent = client.events.first;

      client.subscribe(HyperliquidSubscription.allMids());
      await client.connect();
      transport.addIncoming(
        jsonEncode(<String, Object?>{
          'channel': 'allMids',
          'data': <String, Object?>{
            'mids': <String, String>{'BTC': '100.5'},
          },
        }),
      );
      final HyperliquidWebSocketEvent event = await nextEvent;
      await Future<void>.delayed(const Duration(milliseconds: 15));

      expect(
        connectedEndpoint,
        Uri.parse('wss://api.hyperliquid-testnet.xyz/ws'),
      );
      expect(event.channel, 'allMids');
      expect(
        transport.sent.map(_decode).toList(growable: false),
        containsAll(<Map<String, Object?>>[
          <String, Object?>{
            'method': 'subscribe',
            'subscription': <String, Object?>{'type': 'allMids'},
          },
          <String, Object?>{'method': 'ping'},
        ]),
      );

      await client.dispose();
    });

    test('reconnects and restores active subscriptions', () async {
      final _FakeTransport first = _FakeTransport();
      final _FakeTransport second = _FakeTransport();
      final List<_FakeTransport> transports = <_FakeTransport>[first, second];
      int connectionCount = 0;
      final HyperliquidWebSocketClient client = HyperliquidWebSocketClient(
        config: HyperliquidWebSocketConfig(
          network: HyperAxisNetwork.testnet,
          heartbeatInterval: Duration(hours: 1),
          initialReconnectDelay: Duration(milliseconds: 1),
          maximumReconnectDelay: Duration(milliseconds: 2),
          maximumReconnectAttempts: 2,
        ),
        connector: (Uri endpoint, Duration timeout) async {
          final _FakeTransport transport = transports[connectionCount];
          connectionCount += 1;
          return transport;
        },
      );
      client.subscribe(HyperliquidSubscription.trades(coin: 'BTC'));
      await client.connect();
      final Future<HyperliquidWebSocketState> reconnected = client.states
          .firstWhere(
            (HyperliquidWebSocketState state) =>
                state == HyperliquidWebSocketState.connected,
          );

      await first.closeFromServer();
      await reconnected.timeout(const Duration(seconds: 1));

      expect(connectionCount, 2);
      expect(
        second.sent,
        contains(
          jsonEncode(<String, Object?>{
            'method': 'subscribe',
            'subscription': <String, Object?>{'type': 'trades', 'coin': 'BTC'},
          }),
        ),
      );

      await client.dispose();
    });

    test('manual disconnect does not reconnect', () async {
      final _FakeTransport transport = _FakeTransport();
      int connectionCount = 0;
      final HyperliquidWebSocketClient client = HyperliquidWebSocketClient(
        config: HyperliquidWebSocketConfig(
          network: HyperAxisNetwork.testnet,
          heartbeatInterval: Duration(hours: 1),
          initialReconnectDelay: Duration(milliseconds: 1),
          maximumReconnectDelay: Duration(milliseconds: 2),
        ),
        connector: (Uri endpoint, Duration timeout) async {
          connectionCount += 1;
          return transport;
        },
      );

      await client.connect();
      await client.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(connectionCount, 1);
      expect(client.state, HyperliquidWebSocketState.disconnected);
      await client.dispose();
    });

    test('reports malformed frames without closing the stream', () async {
      final _FakeTransport transport = _FakeTransport();
      final HyperliquidWebSocketClient client = HyperliquidWebSocketClient(
        config: HyperliquidWebSocketConfig(
          network: HyperAxisNetwork.testnet,
          heartbeatInterval: Duration(hours: 1),
        ),
        connector: (Uri endpoint, Duration timeout) async => transport,
      );
      final Future<HyperliquidWebSocketFailure> failure = client.failures.first;

      await client.connect();
      transport.addIncoming('not-json');

      expect((await failure).message, contains('malformed'));
      expect(client.state, HyperliquidWebSocketState.connected);
      await client.dispose();
    });
  });
}

Map<String, Object?> _decode(String text) {
  final Object? decoded = jsonDecode(text);
  if (decoded is! Map<String, Object?>) {
    throw StateError('Expected JSON object.');
  }
  return decoded;
}

final class _FakeTransport implements HyperliquidWebSocketTransport {
  final StreamController<Object?> _controller =
      StreamController<Object?>.broadcast();
  final List<String> sent = <String>[];

  @override
  Stream<Object?> get events => _controller.stream;

  @override
  void send(String text) {
    sent.add(text);
  }

  void addIncoming(Object? frame) {
    _controller.add(frame);
  }

  Future<void> closeFromServer() => _controller.close();

  @override
  Future<void> close() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}
