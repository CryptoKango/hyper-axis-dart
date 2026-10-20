import 'dart:convert';

import 'package:hyper_axis/hyper_axis.dart';
import 'package:test/test.dart';

void main() {
  test('limit-order request encodes the exact Rust schema', () {
    final HyperAxisLimitOrderRequest request = HyperAxisLimitOrderRequest(
      network: HyperAxisNetwork.mainnet,
      asset: 3,
      marketKind: HyperAxisMarketKind.perpetual,
      sizeDecimals: 2,
      isBuy: true,
      limitPrice: '100.00',
      size: '0.50',
      nonce: '18446744073709551615',
      expiresAfter: '18446744073709551615',
    );

    final Object? decoded = jsonDecode(request.toBridgeJson());
    expect(decoded, isA<Map<String, Object?>>());
    final Map<String, Object?> object = decoded! as Map<String, Object?>;
    expect(object['marketKind'], 'perpetual');
    expect(object['szDecimals'], 2);
    expect(object['timeInForce'], 'Gtc');
    expect(object['grouping'], 'na');
    expect(object['nonce'], '18446744073709551615');
    expect(object['expiresAfter'], '18446744073709551615');
  });

  test('limit-order request rejects values outside bridge integer ranges', () {
    expect(
      () => HyperAxisLimitOrderRequest(
        network: HyperAxisNetwork.mainnet,
        asset: -1,
        marketKind: HyperAxisMarketKind.perpetual,
        sizeDecimals: 2,
        isBuy: true,
        limitPrice: '100',
        size: '1',
        nonce: '1',
      ),
      throwsA(
        isA<HyperAxisException>().having(
          (HyperAxisException error) => error.code,
          'code',
          HyperAxisErrorCode.invalidArgument,
        ),
      ),
    );
  });
}
