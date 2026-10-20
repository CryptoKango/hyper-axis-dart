import 'dart:convert';

import '../error/hyper_axis_exception.dart';
import '../logging/hyper_axis_log.dart';
import '../models/orders.dart';

/// Strict decoder for JSON returned by the Rust bridge.
///
/// This class is internal to the SDK and has no compatibility guarantee.
final class HyperAxisBridgeCodec {
  const HyperAxisBridgeCodec._();

  /// Decodes the applied logging configuration.
  static HyperAxisLoggingConfig decodeLoggingConfig(String json) {
    final Map<String, Object?> object = _decodeObject(json, 'logging config');
    return HyperAxisLoggingConfig(
      enabled: _readBool(object, 'enabled'),
      level: _decodeLogLevel(_readString(object, 'level')),
      capacity: _readInt(object, 'capacity'),
    );
  }

  /// Decodes a snapshot or drain response without accepting lossy coercions.
  static HyperAxisLogBatch decodeLogBatch(String json) {
    final Map<String, Object?> object = _decodeObject(json, 'log batch');
    final Object? rawRecords = object['records'];
    if (rawRecords is! List<Object?>) {
      throw _invalidBridgePayload('log batch records must be an array');
    }
    final List<HyperAxisLogRecord> records = rawRecords
        .map((Object? value) => _decodeLogRecord(value))
        .toList(growable: false);
    return HyperAxisLogBatch(
      dropped: _readString(object, 'dropped'),
      records: records,
    );
  }

  /// Decodes an opaque prepared order while exposing signer-safe fields.
  static HyperAxisPreparedOrder decodePreparedOrder(String json) {
    final Map<String, Object?> object = _decodeObject(json, 'prepared order');
    _readObject(object, 'action');
    return HyperAxisPreparedOrder(
      network: _decodeNetwork(_readString(object, 'network')),
      nonce: _readString(object, 'nonce'),
      vaultAddress: _readNullableString(object, 'vaultAddress'),
      expiresAfter: _readNullableString(object, 'expiresAfter'),
      actionJson: _readString(object, 'actionJson'),
      messagePackHex: _readString(object, 'messagePackHex'),
      actionHashHex: _readString(object, 'actionHashHex'),
      signingDigestHex: _readString(object, 'signingDigestHex'),
      bridgeJson: json,
    );
  }

  /// Decodes the final request after Rust has verified the signer.
  static HyperAxisFinalizedAction decodeFinalizedAction(String json) {
    final Map<String, Object?> object = _decodeObject(json, 'finalized action');
    return HyperAxisFinalizedAction(
      endpoint: _readString(object, 'endpoint'),
      requestJson: _readString(object, 'requestJson'),
      recoveredSigner: _readString(object, 'recoveredSigner'),
    );
  }

  static HyperAxisLogRecord _decodeLogRecord(Object? value) {
    if (value is! Map<String, Object?>) {
      throw _invalidBridgePayload('log record must be an object');
    }
    return HyperAxisLogRecord(
      sequence: _readString(value, 'sequence'),
      timestampMs: _readString(value, 'timestampMs'),
      level: _decodeLogLevel(_readString(value, 'level')),
      target: _readString(value, 'target'),
      message: _readString(value, 'message'),
    );
  }

  static Map<String, Object?> _decodeObject(String json, String context) {
    try {
      final Object? value = jsonDecode(json) as Object?;
      if (value is Map<String, Object?>) {
        return value;
      }
    } on FormatException catch (error, stackTrace) {
      throw HyperAxisException(
        code: HyperAxisErrorCode.bridgeFailure,
        message: 'Invalid JSON returned for $context.',
        details: <String, Object?>{'context': context},
        cause: error,
        causeStackTrace: stackTrace,
      );
    }
    throw _invalidBridgePayload('$context must be a JSON object');
  }

  static HyperAxisLogLevel _decodeLogLevel(String value) {
    for (final HyperAxisLogLevel level in HyperAxisLogLevel.values) {
      if (level.wireName == value) {
        return level;
      }
    }
    throw _invalidBridgePayload('unsupported log level');
  }

  static HyperAxisNetwork _decodeNetwork(String value) {
    for (final HyperAxisNetwork network in HyperAxisNetwork.values) {
      if (network.wireName == value) {
        return network;
      }
    }
    throw _invalidBridgePayload('unsupported network');
  }

  static String _readString(Map<String, Object?> object, String field) {
    final Object? value = object[field];
    if (value is String) {
      return value;
    }
    throw _invalidBridgePayload('$field must be a string');
  }

  static String? _readNullableString(
    Map<String, Object?> object,
    String field,
  ) {
    final Object? value = object[field];
    if (value == null || value is String) {
      return value as String?;
    }
    throw _invalidBridgePayload('$field must be a string or null');
  }

  static Map<String, Object?> _readObject(
    Map<String, Object?> object,
    String field,
  ) {
    final Object? value = object[field];
    if (value is Map<String, Object?>) {
      return value;
    }
    throw _invalidBridgePayload('$field must be an object');
  }

  static bool _readBool(Map<String, Object?> object, String field) {
    final Object? value = object[field];
    if (value is bool) {
      return value;
    }
    throw _invalidBridgePayload('$field must be a boolean');
  }

  static int _readInt(Map<String, Object?> object, String field) {
    final Object? value = object[field];
    if (value is int) {
      return value;
    }
    throw _invalidBridgePayload('$field must be an integer');
  }

  static HyperAxisException _invalidBridgePayload(String reason) {
    return HyperAxisException(
      code: HyperAxisErrorCode.bridgeFailure,
      message: 'Invalid payload returned by the HyperAxis native bridge.',
      details: <String, Object?>{'reason': reason},
    );
  }
}
