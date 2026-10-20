import 'dart:collection';
import 'dart:convert';

import 'package:hyper_axis/hyper_axis.dart';

enum HyperliquidWebSocketState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  closing,
}

final class HyperliquidWebSocketConfig {
  HyperliquidWebSocketConfig({
    required this.network,
    this.heartbeatInterval = const Duration(seconds: 30),
    this.connectTimeout = const Duration(seconds: 10),
    this.initialReconnectDelay = const Duration(seconds: 1),
    this.maximumReconnectDelay = const Duration(seconds: 30),
    this.maximumReconnectAttempts,
  }) {
    if (heartbeatInterval <= Duration.zero) {
      throw ArgumentError.value(
        heartbeatInterval,
        'heartbeatInterval',
        'Must be positive.',
      );
    }
    if (connectTimeout <= Duration.zero) {
      throw ArgumentError.value(
        connectTimeout,
        'connectTimeout',
        'Must be positive.',
      );
    }
    if (initialReconnectDelay <= Duration.zero) {
      throw ArgumentError.value(
        initialReconnectDelay,
        'initialReconnectDelay',
        'Must be positive.',
      );
    }
    if (maximumReconnectDelay < initialReconnectDelay) {
      throw ArgumentError.value(
        maximumReconnectDelay,
        'maximumReconnectDelay',
        'Must be at least initialReconnectDelay.',
      );
    }
    if (maximumReconnectAttempts != null && maximumReconnectAttempts! < 0) {
      throw ArgumentError.value(
        maximumReconnectAttempts,
        'maximumReconnectAttempts',
        'Must not be negative.',
      );
    }
  }

  final HyperAxisNetwork network;
  final Duration heartbeatInterval;
  final Duration connectTimeout;
  final Duration initialReconnectDelay;
  final Duration maximumReconnectDelay;
  final int? maximumReconnectAttempts;

  Uri get endpoint => Uri.parse(switch (network) {
    HyperAxisNetwork.mainnet => 'wss://api.hyperliquid.xyz/ws',
    HyperAxisNetwork.testnet => 'wss://api.hyperliquid-testnet.xyz/ws',
  });
}

final class HyperliquidSubscription {
  HyperliquidSubscription._(Map<String, Object?> payload)
    : payload = UnmodifiableMapView<String, Object?>(payload),
      key = jsonEncode(payload);

  factory HyperliquidSubscription.allMids({String? dex}) {
    final Map<String, Object?> payload = <String, Object?>{'type': 'allMids'};
    if (dex != null) {
      payload['dex'] = _requireText('dex', dex);
    }
    return HyperliquidSubscription._(payload);
  }

  factory HyperliquidSubscription.trades({required String coin}) {
    return HyperliquidSubscription._(<String, Object?>{
      'type': 'trades',
      'coin': _requireText('coin', coin),
    });
  }

  factory HyperliquidSubscription.l2Book({
    required String coin,
    int? significantFigures,
    int? mantissa,
  }) {
    if (significantFigures != null &&
        significantFigures != 2 &&
        significantFigures != 3 &&
        significantFigures != 4 &&
        significantFigures != 5) {
      throw ArgumentError.value(
        significantFigures,
        'significantFigures',
        'Must be 2, 3, 4, or 5.',
      );
    }
    if (mantissa != null && mantissa < 1) {
      throw ArgumentError.value(mantissa, 'mantissa', 'Must be positive.');
    }
    final Map<String, Object?> payload = <String, Object?>{
      'type': 'l2Book',
      'coin': _requireText('coin', coin),
    };
    if (significantFigures != null) {
      payload['nSigFigs'] = significantFigures;
    }
    if (mantissa != null) {
      payload['mantissa'] = mantissa;
    }
    return HyperliquidSubscription._(payload);
  }

  factory HyperliquidSubscription.bbo({required String coin}) {
    return HyperliquidSubscription._(<String, Object?>{
      'type': 'bbo',
      'coin': _requireText('coin', coin),
    });
  }

  factory HyperliquidSubscription.candle({
    required String coin,
    required String interval,
  }) {
    const Set<String> intervals = <String>{
      '1m',
      '3m',
      '5m',
      '15m',
      '30m',
      '1h',
      '2h',
      '4h',
      '8h',
      '12h',
      '1d',
      '3d',
      '1w',
      '1M',
    };
    if (!intervals.contains(interval)) {
      throw ArgumentError.value(interval, 'interval', 'Unsupported interval.');
    }
    return HyperliquidSubscription._(<String, Object?>{
      'type': 'candle',
      'coin': _requireText('coin', coin),
      'interval': interval,
    });
  }

  final Map<String, Object?> payload;
  final String key;

  Map<String, Object?> request(String method) => <String, Object?>{
    'method': method,
    'subscription': payload,
  };

  static String _requireText(String name, String value) {
    final String normalized = value.trim();
    if (normalized.isEmpty || normalized.length > 128) {
      throw ArgumentError.value(value, name, 'Must contain 1-128 characters.');
    }
    for (final int codeUnit in normalized.codeUnits) {
      if (codeUnit < 0x20 || codeUnit == 0x7f) {
        throw ArgumentError.value(
          value,
          name,
          'Control characters are invalid.',
        );
      }
    }
    return normalized;
  }
}

final class HyperliquidWebSocketEvent {
  const HyperliquidWebSocketEvent({
    required this.channel,
    required this.data,
    required this.receivedAt,
  });

  final String channel;
  final Object? data;
  final DateTime receivedAt;
}

final class HyperliquidWebSocketFailure {
  const HyperliquidWebSocketFailure({
    required this.message,
    required this.reconnectAttempt,
  });

  final String message;
  final int reconnectAttempt;
}
