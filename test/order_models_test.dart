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
      builder: HyperAxisBuilderFee(
        address: '0x0000000000000000000000000000000000000002',
        fee: 100,
      ),
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
    expect(object['builder'], <String, Object?>{
      'address': '0x0000000000000000000000000000000000000002',
      'fee': 100,
    });
  });

  test('builder approval request encodes the exact Rust schema', () {
    const HyperAxisApproveBuilderFeeRequest request =
        HyperAxisApproveBuilderFeeRequest(
          network: HyperAxisNetwork.mainnet,
          builder: '0x0000000000000000000000000000000000000002',
          maxFeeRate: '0.1%',
          nonce: '18446744073709551615',
        );

    final Map<String, Object?> object =
        jsonDecode(request.toBridgeJson())! as Map<String, Object?>;
    expect(object, <String, Object?>{
      'network': 'mainnet',
      'builder': '0x0000000000000000000000000000000000000002',
      'maxFeeRate': '0.1%',
      'nonce': '18446744073709551615',
    });
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

  test('cancel request preserves OID and nonce as exact strings', () {
    final HyperAxisCancelRequest request = HyperAxisCancelRequest(
      network: HyperAxisNetwork.mainnet,
      cancels: const <HyperAxisCancelOrder>[
        HyperAxisCancelOrder(asset: 3, orderId: '18446744073709551615'),
      ],
      nonce: '18446744073709551615',
    );
    final Map<String, Object?> object =
        jsonDecode(request.toBridgeJson())! as Map<String, Object?>;
    final List<Object?> cancels = object['cancels']! as List<Object?>;
    final Map<String, Object?> cancel = cancels.single! as Map<String, Object?>;

    expect(cancel['oid'], '18446744073709551615');
    expect(object['nonce'], '18446744073709551615');
  });
}
