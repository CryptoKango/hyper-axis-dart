import 'dart:convert';

import 'package:hyper_axis/hyper_axis.dart';
import 'package:test/test.dart';

void main() {
  test('isolated-margin request encodes an exact decimal delta', () {
    final request = HyperAxisUpdateIsolatedMarginRequest(
      network: HyperAxisNetwork.mainnet,
      asset: 4,
      isBuy: true,
      usdDelta: '-12.345678',
      nonce: '1234567890000',
    );

    expect(jsonDecode(request.toBridgeJson()), <String, Object?>{
      'network': 'mainnet',
      'asset': 4,
      'isBuy': true,
      'usdDelta': '-12.345678',
      'nonce': '1234567890000',
      'vaultAddress': null,
      'expiresAfter': null,
    });
  });
}
