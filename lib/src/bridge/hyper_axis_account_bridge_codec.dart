import 'dart:convert';

import '../error/hyper_axis_exception.dart';
import '../models/accounts.dart';
import '../models/orders.dart';

/// Strict account JSON decoder for values validated by Rust Core.
final class HyperAxisAccountBridgeCodec {
  const HyperAxisAccountBridgeCodec._();

  /// Decodes a runtime-neutral HTTP request.
  static HyperAxisHttpRequest decodeHttpRequest(String json) {
    final Map<String, Object?> object = _decodeObject(json, 'HTTP request');
    final Map<String, Object?> rawHeaders = _readObject(object, 'headers');
    final Map<String, String> headers = <String, String>{};
    for (final MapEntry<String, Object?> entry in rawHeaders.entries) {
      final Object? value = entry.value;
      if (value is! String) {
        throw _invalidPayload('HTTP header values must be strings');
      }
      headers[entry.key] = value;
    }
    return HyperAxisHttpRequest(
      kind: _readString(object, 'kind'),
      method: _readString(object, 'method'),
      url: _readString(object, 'url'),
      headers: headers,
      body: _readString(object, 'body'),
    );
  }

  /// Decodes a perpetual account snapshot.
  static HyperAxisPerpAccountState decodePerpAccountState(String json) {
    final Map<String, Object?> object = _decodeObject(
      json,
      'perpetual account state',
    );
    return HyperAxisPerpAccountState(
      assetPositions: _readList(
        object,
        'assetPositions',
      ).map(_decodeAssetPosition).toList(growable: false),
      crossMaintenanceMarginUsed: _readString(
        object,
        'crossMaintenanceMarginUsed',
      ),
      crossMarginSummary: _decodeMarginSummary(
        _readObject(object, 'crossMarginSummary'),
      ),
      marginSummary: _decodeMarginSummary(_readObject(object, 'marginSummary')),
      time: _readString(object, 'time'),
      withdrawable: _readString(object, 'withdrawable'),
    );
  }

  /// Decodes a spot account snapshot.
  static HyperAxisSpotAccountState decodeSpotAccountState(String json) {
    final Map<String, Object?> object = _decodeObject(
      json,
      'spot account state',
    );
    return HyperAxisSpotAccountState(
      balances: _readList(object, 'balances')
          .map((Object? value) {
            final Map<String, Object?> balance = _requireObject(
              value,
              'spot balance',
            );
            return HyperAxisSpotBalance(
              coin: _readString(balance, 'coin'),
              token: _readInt(balance, 'token'),
              hold: _readString(balance, 'hold'),
              total: _readString(balance, 'total'),
              entryNotional: _readString(balance, 'entryNtl'),
            );
          })
          .toList(growable: false),
    );
  }

  /// Decodes a prepared user action while keeping its full JSON opaque.
  static HyperAxisPreparedUserAction decodePreparedUserAction(String json) {
    final Map<String, Object?> object = _decodeObject(
      json,
      'prepared user action',
    );
    _readObject(object, 'action');
    return HyperAxisPreparedUserAction(
      network: _decodeNetwork(_readString(object, 'network')),
      nonce: _readString(object, 'nonce'),
      actionJson: _readString(object, 'actionJson'),
      signingDigestHex: _readString(object, 'signingDigestHex'),
      bridgeJson: json,
    );
  }

  /// Decodes one validated account WebSocket message.
  static HyperAxisAccountWebSocketMessage decodeWebSocketMessage(String json) {
    final Map<String, Object?> object = _decodeObject(
      json,
      'account WebSocket message',
    );
    return HyperAxisAccountWebSocketMessage(
      channel: _readString(object, 'channel'),
      data: object['data'],
      canonicalJson: json,
    );
  }

  static HyperAxisPerpAssetPosition _decodeAssetPosition(Object? value) {
    final Map<String, Object?> envelope = _requireObject(
      value,
      'asset position',
    );
    final Map<String, Object?> position = _readObject(envelope, 'position');
    final Map<String, Object?> funding = _readObject(position, 'cumFunding');
    final Map<String, Object?> leverage = _readObject(position, 'leverage');
    return HyperAxisPerpAssetPosition(
      type: _readString(envelope, 'type'),
      position: HyperAxisPerpPosition(
        coin: _readString(position, 'coin'),
        cumulativeFunding: HyperAxisPerpCumulativeFunding(
          allTime: _readString(funding, 'allTime'),
          sinceChange: _readString(funding, 'sinceChange'),
          sinceOpen: _readString(funding, 'sinceOpen'),
        ),
        entryPrice: _readNullableString(position, 'entryPx'),
        leverage: HyperAxisPerpLeverage(
          type: _readString(leverage, 'type'),
          value: _readInt(leverage, 'value'),
          rawUsd: _readNullableString(leverage, 'rawUsd'),
        ),
        liquidationPrice: _readNullableString(position, 'liquidationPx'),
        marginUsed: _readString(position, 'marginUsed'),
        maxLeverage: _readInt(position, 'maxLeverage'),
        positionValue: _readString(position, 'positionValue'),
        returnOnEquity: _readString(position, 'returnOnEquity'),
        signedSize: _readString(position, 'szi'),
        unrealizedPnl: _readString(position, 'unrealizedPnl'),
      ),
    );
  }

  static HyperAxisPerpMarginSummary _decodeMarginSummary(
    Map<String, Object?> object,
  ) {
    return HyperAxisPerpMarginSummary(
      accountValue: _readString(object, 'accountValue'),
      totalMarginUsed: _readString(object, 'totalMarginUsed'),
      totalNtlPos: _readString(object, 'totalNtlPos'),
      totalRawUsd: _readString(object, 'totalRawUsd'),
    );
  }

  static Map<String, Object?> _decodeObject(String json, String context) {
    try {
      return _requireObject(jsonDecode(json) as Object?, context);
    } on FormatException catch (error, stackTrace) {
      throw HyperAxisException(
        code: HyperAxisErrorCode.bridgeFailure,
        message: 'Invalid JSON returned for $context.',
        details: <String, Object?>{'context': context},
        cause: error,
        causeStackTrace: stackTrace,
      );
    }
  }

  static Map<String, Object?> _requireObject(Object? value, String context) {
    if (value is Map<String, Object?>) return value;
    throw _invalidPayload('$context must be an object');
  }

  static String _readString(Map<String, Object?> object, String field) {
    final Object? value = object[field];
    if (value is String) return value;
    throw _invalidPayload('$field must be a string');
  }

  static String? _readNullableString(
    Map<String, Object?> object,
    String field,
  ) {
    final Object? value = object[field];
    if (value == null || value is String) return value as String?;
    throw _invalidPayload('$field must be a string or null');
  }

  static int _readInt(Map<String, Object?> object, String field) {
    final Object? value = object[field];
    if (value is int) return value;
    throw _invalidPayload('$field must be an integer');
  }

  static Map<String, Object?> _readObject(
    Map<String, Object?> object,
    String field,
  ) => _requireObject(object[field], field);

  static List<Object?> _readList(Map<String, Object?> object, String field) {
    final Object? value = object[field];
    if (value is List<Object?>) return value;
    throw _invalidPayload('$field must be an array');
  }

  static HyperAxisNetwork _decodeNetwork(String value) {
    for (final HyperAxisNetwork network in HyperAxisNetwork.values) {
      if (network.wireName == value) return network;
    }
    throw _invalidPayload('unsupported network');
  }

  static HyperAxisException _invalidPayload(String reason) {
    return HyperAxisException(
      code: HyperAxisErrorCode.bridgeFailure,
      message: 'Invalid account payload returned by the native bridge.',
      details: <String, Object?>{'reason': reason},
    );
  }
}
