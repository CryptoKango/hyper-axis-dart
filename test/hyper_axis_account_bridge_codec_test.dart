import 'package:hyper_axis/hyper_axis.dart';
import 'package:hyper_axis/src/bridge/hyper_axis_account_bridge_codec.dart';
import 'package:test/test.dart';

void main() {
  group('HyperAxisAccountBridgeCodec', () {
    test(
      'decodes exact perpetual values without floating-point conversion',
      () {
        final HyperAxisPerpAccountState state =
            HyperAxisAccountBridgeCodec.decodePerpAccountState('''
            {
              "assetPositions": [{
                "type": "oneWay",
                "position": {
                  "coin": "BTC",
                  "cumFunding": {
                    "allTime": "-0.00000001",
                    "sinceChange": "0",
                    "sinceOpen": "-0.00000001"
                  },
                  "entryPx": "83675.70",
                  "leverage": {"type": "cross", "value": 20, "rawUsd": null},
                  "liquidationPx": null,
                  "marginUsed": "4.183785",
                  "maxLeverage": 40,
                  "positionValue": "83.6757",
                  "returnOnEquity": "0.01234567890123456789",
                  "szi": "0.001",
                  "unrealizedPnl": "0.000000000000000001"
                }
              }],
              "crossMaintenanceMarginUsed": "1.25",
              "crossMarginSummary": {
                "accountValue": "100.000000000000000001",
                "totalMarginUsed": "4.183785",
                "totalNtlPos": "83.6757",
                "totalRawUsd": "99.999999999999999999"
              },
              "marginSummary": {
                "accountValue": "100.000000000000000001",
                "totalMarginUsed": "4.183785",
                "totalNtlPos": "83.6757",
                "totalRawUsd": "99.999999999999999999"
              },
              "time": "12345678901234567890",
              "withdrawable": "95.816215"
            }
            ''');

        expect(state.time, '12345678901234567890');
        expect(state.crossMarginSummary.accountValue, '100.000000000000000001');
        expect(
          state.assetPositions.single.position.returnOnEquity,
          '0.01234567890123456789',
        );
      },
    );

    test('decodes an immutable spot balance collection', () {
      final HyperAxisSpotAccountState state =
          HyperAxisAccountBridgeCodec.decodeSpotAccountState(
            '{"balances":[{"coin":"USDC","token":0,"hold":"1.25",'
            '"total":"10.00000001","entryNtl":"8.75"}]}',
          );

      expect(state.balances.single.total, '10.00000001');
      expect(() => state.balances.clear(), throwsUnsupportedError);
    });

    test('rejects numeric protocol decimals instead of losing precision', () {
      expect(
        () => HyperAxisAccountBridgeCodec.decodeSpotAccountState(
          '{"balances":[{"coin":"USDC","token":0,"hold":1.25,'
          '"total":"10","entryNtl":"8.75"}]}',
        ),
        throwsA(
          isA<HyperAxisException>().having(
            (HyperAxisException error) => error.code,
            'code',
            HyperAxisErrorCode.bridgeFailure,
          ),
        ),
      );
    });

    test('rejects malformed HTTP header values', () {
      expect(
        () => HyperAxisAccountBridgeCodec.decodeHttpRequest(
          '{"kind":"info","method":"POST","url":"https://example.test",'
          '"headers":{"content-type":1},"body":"{}"}',
        ),
        throwsA(isA<HyperAxisException>()),
      );
    });

    test('deeply freezes WebSocket account payloads', () {
      final HyperAxisAccountWebSocketMessage message =
          HyperAxisAccountBridgeCodec.decodeWebSocketMessage(
            '{"channel":"spotState","data":{"spotState":'
            '{"balances":[{"coin":"USDC"}]}}}',
          );
      final Map<String, Object?> data = message.data! as Map<String, Object?>;
      final Map<String, Object?> spotState =
          data['spotState']! as Map<String, Object?>;
      final List<Object?> balances = spotState['balances']! as List<Object?>;
      final Map<String, Object?> balance =
          balances.single! as Map<String, Object?>;

      expect(() => data['extra'] = true, throwsUnsupportedError);
      expect(() => balances.clear(), throwsUnsupportedError);
      expect(() => balance['coin'] = 'HYPE', throwsUnsupportedError);
    });
  });
}
