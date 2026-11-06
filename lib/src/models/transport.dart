import 'dart:convert';
import 'dart:io' show ZLibDecoder;

/// Hyperliquid endpoint family used for response classification.
enum HyperAxisRequestKind {
  /// Read-only `POST /info` request.
  info('info'),

  /// Signed `POST /exchange` request.
  signedAction('signedAction');

  const HyperAxisRequestKind(this.wireName);

  /// Exact Rust wire representation.
  final String wireName;
}

/// Synchronous host commands whose wire shape is fixed by Hyperliquid.
abstract final class HyperAxisWebSocketCommands {
  /// Canonical heartbeat frame.
  static const Map<String, Object?> ping = <String, Object?>{'method': 'ping'};
}

/// Order identifier accepted by the Hyperliquid `orderStatus` Info query.
final class HyperAxisOrderStatusSelector {
  HyperAxisOrderStatusSelector._(Map<String, Object?> value)
    : _value = Map<String, Object?>.unmodifiable(value);

  final Map<String, Object?> _value;

  /// Selects an order by its 128-bit client order id.
  factory HyperAxisOrderStatusSelector.cloid(String cloid) =>
      HyperAxisOrderStatusSelector._(<String, Object?>{
        'kind': 'cloid',
        'cloid': cloid,
      });

  /// Selects an order by its decimal Hyperliquid order id.
  factory HyperAxisOrderStatusSelector.oid(String oid) =>
      HyperAxisOrderStatusSelector._(<String, Object?>{
        'kind': 'oid',
        'oid': oid,
      });
}

/// Validated, typed Hyperliquid Info query.
final class HyperAxisInfoQuery {
  HyperAxisInfoQuery._(Map<String, Object?> value)
    : _value = Map<String, Object?>.unmodifiable(value);

  final Map<String, Object?> _value;

  /// Registered perpetual DEXs.
  factory HyperAxisInfoQuery.perpetualDexes() =>
      HyperAxisInfoQuery._(<String, Object?>{'type': 'perpDexs'});

  /// Perpetual metadata and aligned live asset contexts.
  factory HyperAxisInfoQuery.metaAndAssetContexts({String? dex}) {
    final value = <String, Object?>{'type': 'metaAndAssetCtxs'};
    if (dex != null) value['dex'] = dex;
    return HyperAxisInfoQuery._(value);
  }

  /// Historical candles for one market.
  factory HyperAxisInfoQuery.candleSnapshot({
    required String coin,
    required String interval,
    required int startTime,
    required int endTime,
  }) => HyperAxisInfoQuery._(<String, Object?>{
    'type': 'candleSnapshot',
    'coin': coin,
    'interval': interval,
    'startTime': startTime.toString(),
    'endTime': endTime.toString(),
  });

  /// Basic open orders for one perpetual DEX.
  factory HyperAxisInfoQuery.openOrders({
    required String user,
    String dex = '',
  }) => HyperAxisInfoQuery._(<String, Object?>{
    'type': 'openOrders',
    'user': user,
    'dex': dex,
  });

  /// Current order state selected by an order id or client order id.
  factory HyperAxisInfoQuery.orderStatus({
    required String user,
    required HyperAxisOrderStatusSelector selector,
  }) => HyperAxisInfoQuery._(<String, Object?>{
    'type': 'orderStatus',
    'user': user,
    'selector': selector._value,
  });

  /// Recent fills for one user.
  factory HyperAxisInfoQuery.userFills(String user) => HyperAxisInfoQuery._(
    <String, Object?>{'type': 'userFills', 'user': user},
  );

  /// User-specific data for one active perpetual market.
  factory HyperAxisInfoQuery.activeAssetData({
    required String user,
    required String coin,
  }) => HyperAxisInfoQuery._(<String, Object?>{
    'type': 'activeAssetData',
    'user': user,
    'coin': coin,
  });

  /// Current fee schedule and volume for one user.
  factory HyperAxisInfoQuery.userFees(String user) =>
      HyperAxisInfoQuery._(<String, Object?>{'type': 'userFees', 'user': user});

  /// Maximum Builder Fee approved by one user.
  factory HyperAxisInfoQuery.maxBuilderFee({
    required String user,
    required String builder,
  }) => HyperAxisInfoQuery._(<String, Object?>{
    'type': 'maxBuilderFee',
    'user': user,
    'builder': builder,
  });

  /// L2 order-book snapshot with optional server aggregation.
  factory HyperAxisInfoQuery.l2Book({
    required String coin,
    int? significantFigures,
    int? mantissa,
  }) {
    final value = <String, Object?>{'type': 'l2Book', 'coin': coin};
    if (significantFigures != null) {
      value['nSigFigs'] = significantFigures;
    }
    if (mantissa != null) value['mantissa'] = mantissa;
    return HyperAxisInfoQuery._(value);
  }

  /// Exact JSON consumed by Rust Core.
  String toBridgeJson() => jsonEncode(_value);
}

/// Validated Hyperliquid WebSocket subscription descriptor.
final class HyperAxisSubscription {
  HyperAxisSubscription._(Map<String, Object?> value)
    : _value = Map<String, Object?>.unmodifiable(value);

  final Map<String, Object?> _value;

  /// Compressed market-wide asset context updates.
  factory HyperAxisSubscription.fastAssetContexts() =>
      HyperAxisSubscription._(<String, Object?>{'type': 'fastAssetCtxs'});

  /// Perpetual clearinghouse state for one user on a DEX.
  ///
  /// The empty DEX selects Hyperliquid's first perpetual DEX.
  factory HyperAxisSubscription.clearinghouseState({
    required String user,
    String dex = '',
  }) => HyperAxisSubscription._(<String, Object?>{
    'type': 'clearinghouseState',
    'user': user,
    'dex': dex,
  });

  /// User order lifecycle updates.
  factory HyperAxisSubscription.orderUpdates({required String user}) =>
      HyperAxisSubscription._(<String, Object?>{
        'type': 'orderUpdates',
        'user': user,
      });

  /// User fills, optionally aggregated by time.
  factory HyperAxisSubscription.userFills({
    required String user,
    bool? aggregateByTime,
  }) {
    final value = <String, Object?>{'type': 'userFills', 'user': user};
    if (aggregateByTime != null) value['aggregateByTime'] = aggregateByTime;
    return HyperAxisSubscription._(value);
  }

  /// Candlestick updates.
  factory HyperAxisSubscription.candles({
    required String coin,
    required String interval,
  }) => HyperAxisSubscription._(<String, Object?>{
    'type': 'candle',
    'coin': coin,
    'interval': interval,
  });

  /// L2 order-book updates with optional server aggregation.
  factory HyperAxisSubscription.l2Book({
    required String coin,
    int? significantFigures,
    int? mantissa,
    bool? fast,
  }) {
    final value = <String, Object?>{'type': 'l2Book', 'coin': coin};
    if (significantFigures != null) {
      value['nSigFigs'] = significantFigures;
    }
    if (mantissa != null) value['mantissa'] = mantissa;
    if (fast != null) value['fast'] = fast;
    return HyperAxisSubscription._(value);
  }

  /// Exact JSON consumed by Rust Core.
  String toBridgeJson() => jsonEncode(_value);

  /// Synchronous host frame used by topic routers after SDK construction.
  Map<String, Object?> command(String method) => <String, Object?>{
    'method': method,
    'subscription': _value,
  };
}

/// Canonical Info body produced by Rust Core.
final class HyperAxisPreparedInfoQuery {
  /// Creates a canonical typed Info query result.
  const HyperAxisPreparedInfoQuery({
    required this.queryType,
    required this.body,
  });

  /// Hyperliquid query discriminator.
  final String queryType;

  /// Exact JSON body.
  final String body;
}

/// HTTP response classification returned by Rust Core.
final class HyperAxisParsedHttpResponse {
  /// Creates a response classification produced by Rust Core.
  const HyperAxisParsedHttpResponse({
    required this.requestKind,
    required this.statusCode,
    required this.kind,
    required this.retry,
    required this.payload,
    required this.message,
  });

  /// Source endpoint family.
  final String requestKind;

  /// HTTP response status code.
  final int statusCode;

  /// Rust response classification.
  final String kind;

  /// Retry or reconciliation advice.
  final String retry;

  /// Parsed JSON payload, when present.
  final Object? payload;

  /// Server or parser message, when present.
  final String? message;

  /// Whether the protocol accepted the response as successful.
  bool get isSuccess => kind == 'success';
}

/// Canonical WebSocket envelope returned by Rust Core.
final class HyperAxisWebSocketMessage {
  /// Creates a canonical WebSocket envelope produced by Rust Core.
  const HyperAxisWebSocketMessage({
    required this.channel,
    required this.data,
    required this.canonicalJson,
  });

  /// Decodes a host message for synchronous topic routing.
  factory HyperAxisWebSocketMessage.decodeHost(Object? raw) {
    final decoded = raw is String ? jsonDecode(raw) : raw;
    if (decoded is! Map) {
      throw const FormatException('WebSocket message must be an object');
    }
    final object = decoded.map((key, value) => MapEntry(key.toString(), value));
    final channel = object['channel'];
    if (channel is! String || channel.trim().isEmpty) {
      throw const FormatException('WebSocket channel is missing');
    }
    return HyperAxisWebSocketMessage(
      channel: channel,
      data: object['data'],
      canonicalJson: jsonEncode(object),
    );
  }

  /// Hyperliquid channel name.
  final String channel;

  /// Channel-specific payload.
  final Object? data;

  /// Canonical message JSON produced by Rust Core.
  final String canonicalJson;

  /// Stable topic key used by host WebSocket routers.
  String? get routingTopic => switch (channel) {
    'fastAssetCtxs' => 'fastAssetCtxs',
    'candle' => _candleTopic(data),
    'l2Book' => _orderBookTopic(data),
    _ => null,
  };

  /// Decodes compressed or plain `fastAssetCtxs` payloads.
  Map<String, Object?> decodeFastAssetContexts() {
    final value = data;
    if (value is Map) return _stringKeyedMap(value);
    if (value is! String) {
      throw const FormatException('fastAssetCtxs.data is invalid');
    }
    final bytes = base64Decode(value);
    final inflated = ZLibDecoder(raw: true).convert(bytes);
    final decoded = jsonDecode(utf8.decode(inflated));
    if (decoded is! Map) {
      throw const FormatException('fastAssetCtxs payload is invalid');
    }
    return _stringKeyedMap(decoded);
  }
}

String? _candleTopic(Object? data) {
  final candle = data is List && data.isNotEmpty ? data.last : data;
  if (candle is! Map) return null;
  final object = _stringKeyedMap(candle);
  final symbol = object['s']?.toString();
  final interval = object['i']?.toString();
  if (symbol == null || interval == null) return null;
  return 'candle|$symbol|$interval';
}

String? _orderBookTopic(Object? data) {
  if (data is! Map) return null;
  final symbol = _stringKeyedMap(data)['coin']?.toString();
  return symbol == null ? null : 'l2Book|$symbol';
}

Map<String, Object?> _stringKeyedMap(Map<dynamic, dynamic> value) =>
    value.map((key, item) => MapEntry(key.toString(), item));
