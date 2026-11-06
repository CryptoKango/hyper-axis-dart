import 'dart:convert';

import 'orders.dart';

/// Exact input for approving a maximum Builder Fee.
final class HyperAxisApproveBuilderFeeRequest {
  /// Creates a main-wallet-signed Builder Fee authorization request.
  const HyperAxisApproveBuilderFeeRequest({
    required this.network,
    required this.builder,
    required this.maxFeeRate,
    required this.nonce,
  });

  /// Target Hyperliquid environment.
  final HyperAxisNetwork network;

  /// Builder EVM address receiving the fee.
  final String builder;

  /// Exact percentage string, for example `0.1%`.
  final String maxFeeRate;

  /// Millisecond nonce encoded as an unsigned decimal string.
  final String nonce;

  /// Encodes the exact request schema consumed by Rust.
  String toBridgeJson() => jsonEncode(<String, Object?>{
    'network': network.wireName,
    'builder': builder,
    'maxFeeRate': maxFeeRate,
    'nonce': nonce,
  });
}
