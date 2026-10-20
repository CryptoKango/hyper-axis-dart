import 'package:hyper_axis/hyper_axis.dart';
import 'package:hyper_axis/src/bridge/hyper_axis_bridge_codec.dart';
import 'package:test/test.dart';

void main() {
  group('HyperAxisBridgeCodec.decodeLoggingConfig', () {
    test('decodes an exact Rust logging configuration', () {
      final HyperAxisLoggingConfig config =
          HyperAxisBridgeCodec.decodeLoggingConfig(
            '{"enabled":true,"level":"debug","capacity":256}',
          );

      expect(config.enabled, isTrue);
      expect(config.level, HyperAxisLogLevel.debug);
      expect(config.capacity, 256);
    });

    test('rejects unsupported levels and lossy numeric coercions', () {
      expect(
        () => HyperAxisBridgeCodec.decodeLoggingConfig(
          '{"enabled":true,"level":"verbose","capacity":256}',
        ),
        throwsBridgeFailure,
      );
      expect(
        () => HyperAxisBridgeCodec.decodeLoggingConfig(
          '{"enabled":true,"level":"info","capacity":"256"}',
        ),
        throwsBridgeFailure,
      );
    });
  });

  group('HyperAxisBridgeCodec.decodeLogBatch', () {
    test('preserves u64-compatible values as decimal strings', () {
      final HyperAxisLogBatch batch = HyperAxisBridgeCodec.decodeLogBatch(
        '{"dropped":"3","records":[{'
        '"sequence":"18446744073709551615",'
        '"timestampMs":"1730000000000",'
        '"level":"warn",'
        '"target":"runtime",'
        '"message":"bounded diagnostic"}]}',
      );

      expect(batch.dropped, '3');
      expect(batch.records, hasLength(1));
      expect(batch.records.single.sequence, '18446744073709551615');
      expect(batch.records.single.timestampMs, '1730000000000');
      expect(batch.records.single.level, HyperAxisLogLevel.warn);
    });

    test('rejects malformed JSON and unexpected field types', () {
      expect(
        () => HyperAxisBridgeCodec.decodeLogBatch('{'),
        throwsBridgeFailure,
      );
      expect(
        () => HyperAxisBridgeCodec.decodeLogBatch('{"dropped":0,"records":[]}'),
        throwsBridgeFailure,
      );
      expect(
        () =>
            HyperAxisBridgeCodec.decodeLogBatch('{"dropped":"0","records":{}}'),
        throwsBridgeFailure,
      );
    });
  });

  group('order bridge codec', () {
    test('decodes exact prepared and finalized order artifacts', () {
      final HyperAxisPreparedOrder prepared =
          HyperAxisBridgeCodec.decodePreparedOrder(
            '{"network":"mainnet","action":{},'
            '"nonce":"18446744073709551615","vaultAddress":null,'
            '"expiresAfter":"18446744073709551615",'
            '"actionJson":"{}","messagePackHex":"00",'
            '"actionHashHex":"aa","signingDigestHex":"bb"}',
          );
      final HyperAxisFinalizedAction finalized =
          HyperAxisBridgeCodec.decodeFinalizedAction(
            '{"endpoint":"https://api.hyperliquid.xyz/exchange",'
            '"requestJson":"{}",'
            '"recoveredSigner":"0x0000000000000000000000000000000000000001"}',
          );

      expect(prepared.network, HyperAxisNetwork.mainnet);
      expect(prepared.nonce, '18446744073709551615');
      expect(prepared.expiresAfter, '18446744073709551615');
      expect(finalized.requestJson, '{}');
    });

    test('rejects numeric prepared-order nonce', () {
      expect(
        () => HyperAxisBridgeCodec.decodePreparedOrder(
          '{"network":"mainnet","action":{},"nonce":1,'
          '"vaultAddress":null,"expiresAfter":null,'
          '"actionJson":"{}","messagePackHex":"00",'
          '"actionHashHex":"aa","signingDigestHex":"bb"}',
        ),
        throwsBridgeFailure,
      );
    });
  });
}

final Matcher throwsBridgeFailure = throwsA(
  isA<HyperAxisException>().having(
    (HyperAxisException error) => error.code,
    'code',
    HyperAxisErrorCode.bridgeFailure,
  ),
);
