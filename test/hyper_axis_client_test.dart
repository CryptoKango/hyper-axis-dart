import 'package:hyper_axis/hyper_axis.dart';
import 'package:test/test.dart';

void main() {
  group('HyperAxisClient', () {
    test('delegates stable runtime operations to the bridge', () {
      final _FakeBridge bridge = _FakeBridge();
      final HyperAxisClient client = HyperAxisClient.withBridge(bridge);

      expect(client.protocolVersion, '0.1.0');
      expect(client.normalizeDecimal('001.2300'), '1.23');

      final HyperAxisLoggingConfig applied = client.configureLogging(
        HyperAxisLoggingConfig(
          enabled: true,
          level: HyperAxisLogLevel.debug,
          capacity: 32,
        ),
      );
      expect(applied.enabled, isTrue);
      expect(applied.level, HyperAxisLogLevel.debug);
      expect(applied.capacity, 32);
    });

    test('preserves typed bridge errors', () {
      final HyperAxisClient client = HyperAxisClient.withBridge(
        _ThrowingBridge(
          HyperAxisException(
            code: HyperAxisErrorCode.protocol,
            message: 'invalid decimal',
          ),
        ),
      );

      expect(
        () => client.normalizeDecimal('invalid'),
        throwsA(
          isA<HyperAxisException>().having(
            (HyperAxisException error) => error.code,
            'code',
            HyperAxisErrorCode.protocol,
          ),
        ),
      );
    });

    test('wraps unknown implementation failures', () {
      final HyperAxisClient client = HyperAxisClient.withBridge(
        _ThrowingBridge(StateError('native failure')),
      );

      expect(
        () => client.normalizeDecimal('1'),
        throwsA(
          isA<HyperAxisException>()
              .having(
                (HyperAxisException error) => error.code,
                'code',
                HyperAxisErrorCode.bridgeFailure,
              )
              .having(
                (HyperAxisException error) => error.details['operation'],
                'operation',
                'normalizeDecimal',
              ),
        ),
      );
    });

    test('rejects an incompatible Rust protocol before use', () {
      expect(
        () => HyperAxisClient.withBridge(_FakeBridge(protocolVersion: '0.2.0')),
        throwsA(
          isA<HyperAxisException>()
              .having(
                (HyperAxisException error) => error.code,
                'code',
                HyperAxisErrorCode.incompatibleVersion,
              )
              .having(
                (HyperAxisException error) => error.details['actual'],
                'actual',
                '0.2.0',
              ),
        ),
      );
    });

    test('delegates order preparation and finalization', () {
      final HyperAxisClient client = HyperAxisClient.withBridge(_FakeBridge());
      final HyperAxisPreparedOrder prepared = client.prepareLimitOrder(
        HyperAxisLimitOrderRequest(
          network: HyperAxisNetwork.mainnet,
          asset: 3,
          marketKind: HyperAxisMarketKind.perpetual,
          sizeDecimals: 2,
          isBuy: true,
          limitPrice: '100.00',
          size: '0.50',
          nonce: '1234567890000',
        ),
      );
      final HyperAxisFinalizedAction finalized = client.finalizeOrder(
        prepared: prepared,
        signature: const HyperAxisSignature(r: '0x01', s: '0x02', v: 27),
        expectedSigner: '0x0000000000000000000000000000000000000001',
      );

      expect(prepared.signingDigestHex, 'digest');
      expect(finalized.endpoint, 'https://example.test/exchange');
    });
  });

  group('logging models', () {
    test('rejects unsafe ring-buffer capacities', () {
      expect(
        () => HyperAxisLoggingConfig(capacity: 0),
        throwsA(
          isA<HyperAxisException>().having(
            (HyperAxisException error) => error.code,
            'code',
            HyperAxisErrorCode.invalidArgument,
          ),
        ),
      );
      expect(
        () => HyperAxisLoggingConfig(capacity: 10001),
        throwsA(isA<HyperAxisException>()),
      );
    });

    test('copies the returned record collection', () {
      final List<HyperAxisLogRecord> source = <HyperAxisLogRecord>[
        const HyperAxisLogRecord(
          sequence: '1',
          timestampMs: '2',
          level: HyperAxisLogLevel.info,
          target: 'client',
          message: 'initialized',
        ),
      ];
      final HyperAxisLogBatch batch = HyperAxisLogBatch(
        dropped: '0',
        records: source,
      );

      source.clear();
      expect(batch.records, hasLength(1));
      expect(() => batch.records.clear(), throwsUnsupportedError);
    });
  });
}

final class _FakeBridge implements HyperAxisBridge {
  _FakeBridge({this.protocolVersion = '0.1.0'});

  @override
  final String protocolVersion;

  @override
  void clearLogs() {}

  @override
  HyperAxisLoggingConfig configureLogging(HyperAxisLoggingConfig config) {
    return config;
  }

  @override
  HyperAxisLogBatch drainLogs() => snapshotLogs();

  @override
  HyperAxisFinalizedAction finalizeOrder({
    required HyperAxisPreparedOrder prepared,
    required HyperAxisSignature signature,
    required String expectedSigner,
  }) {
    return HyperAxisFinalizedAction(
      endpoint: 'https://example.test/exchange',
      requestJson: '{}',
      recoveredSigner: expectedSigner,
    );
  }

  @override
  String normalizeDecimal(String value) => '1.23';

  @override
  HyperAxisPreparedOrder prepareLimitOrder(HyperAxisLimitOrderRequest request) {
    return const HyperAxisPreparedOrder(
      network: HyperAxisNetwork.mainnet,
      nonce: '1234567890000',
      vaultAddress: null,
      expiresAfter: null,
      actionJson: '{}',
      messagePackHex: '00',
      actionHashHex: 'hash',
      signingDigestHex: 'digest',
      bridgeJson: '{}',
    );
  }

  @override
  HyperAxisLogBatch snapshotLogs() {
    return HyperAxisLogBatch(dropped: '0', records: <HyperAxisLogRecord>[]);
  }
}

final class _ThrowingBridge implements HyperAxisBridge {
  _ThrowingBridge(this.error);

  final Object error;

  Never _fail() {
    final Object value = error;
    if (value is Exception) {
      throw value;
    }
    if (value is Error) {
      throw value;
    }
    throw StateError('Unsupported test error: ${value.runtimeType}');
  }

  @override
  String get protocolVersion => '0.1.0';

  @override
  void clearLogs() => _fail();

  @override
  HyperAxisLoggingConfig configureLogging(HyperAxisLoggingConfig config) {
    return _fail();
  }

  @override
  HyperAxisLogBatch drainLogs() => _fail();

  @override
  HyperAxisFinalizedAction finalizeOrder({
    required HyperAxisPreparedOrder prepared,
    required HyperAxisSignature signature,
    required String expectedSigner,
  }) => _fail();

  @override
  String normalizeDecimal(String value) => _fail();

  @override
  HyperAxisPreparedOrder prepareLimitOrder(HyperAxisLimitOrderRequest request) {
    return _fail();
  }

  @override
  HyperAxisLogBatch snapshotLogs() => _fail();
}
