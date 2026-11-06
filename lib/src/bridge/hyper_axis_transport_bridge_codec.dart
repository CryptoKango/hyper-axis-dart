import 'dart:convert';

import '../error/hyper_axis_exception.dart';
import '../models/transport.dart';

/// Strict decoders for transport JSON validated by Rust Core.
final class HyperAxisTransportBridgeCodec {
  const HyperAxisTransportBridgeCodec._();

  /// Decodes a canonical Info query.
  static HyperAxisPreparedInfoQuery decodePreparedInfoQuery(String json) {
    final object = _decodeObject(json, 'prepared Info query');
    return HyperAxisPreparedInfoQuery(
      queryType: _readString(object, 'queryType'),
      body: _readString(object, 'body'),
    );
  }

  /// Decodes a classified HTTP response.
  static HyperAxisParsedHttpResponse decodeHttpResponse(String json) {
    final object = _decodeObject(json, 'HTTP response');
    return HyperAxisParsedHttpResponse(
      requestKind: _readString(object, 'requestKind'),
      statusCode: _readInt(object, 'statusCode'),
      kind: _readString(object, 'kind'),
      retry: _readString(object, 'retry'),
      payload: object['payload'],
      message: _readNullableString(object, 'message'),
    );
  }

  /// Decodes a canonical WebSocket message.
  static HyperAxisWebSocketMessage decodeWebSocketMessage(String json) {
    final object = _decodeObject(json, 'WebSocket message');
    return HyperAxisWebSocketMessage(
      channel: _readString(object, 'channel'),
      data: object['data'],
      canonicalJson: json,
    );
  }

  /// Decodes an arbitrary JSON value validated by Rust Core.
  static Object? decodeJsonValue(String json, String context) {
    try {
      return jsonDecode(json);
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

  static Map<String, Object?> _decodeObject(String json, String context) {
    final value = decodeJsonValue(json, context);
    if (value is Map<String, Object?>) return value;
    throw _invalidPayload('$context must be an object');
  }

  static String _readString(Map<String, Object?> object, String field) {
    final value = object[field];
    if (value is String) return value;
    throw _invalidPayload('$field must be a string');
  }

  static String? _readNullableString(
    Map<String, Object?> object,
    String field,
  ) {
    final value = object[field];
    if (value == null || value is String) return value as String?;
    throw _invalidPayload('$field must be a string or null');
  }

  static int _readInt(Map<String, Object?> object, String field) {
    final value = object[field];
    if (value is int) return value;
    throw _invalidPayload('$field must be an integer');
  }

  static HyperAxisException _invalidPayload(String reason) =>
      HyperAxisException(
        code: HyperAxisErrorCode.bridgeFailure,
        message: 'Invalid transport payload returned by the native bridge.',
        details: <String, Object?>{'reason': reason},
      );
}
