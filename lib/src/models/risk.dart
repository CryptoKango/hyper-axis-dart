import 'dart:convert';

import '../error/hyper_axis_exception.dart';
import 'orders.dart';

/// Exact input for preparing one Hyperliquid leverage update in Rust.
final class HyperAxisUpdateLeverageRequest {
  /// Creates a leverage update without performing protocol calculations.
  factory HyperAxisUpdateLeverageRequest({
    required HyperAxisNetwork network,
    required int asset,
    required bool isCross,
    required int leverage,
    required int maxLeverage,
    required String nonce,
    String? vaultAddress,
    String? expiresAfter,
  }) {
    if (asset < 0 || asset > 0xffffffff) {
      throw HyperAxisException(
        code: HyperAxisErrorCode.invalidArgument,
        message: 'asset is outside its unsigned integer range.',
        details: const <String, Object?>{'field': 'asset'},
      );
    }
    if (leverage <= 0 || maxLeverage <= 0 || leverage > maxLeverage) {
      throw HyperAxisException(
        code: HyperAxisErrorCode.invalidArgument,
        message: 'leverage must be between 1 and maxLeverage.',
        details: <String, Object?>{
          'field': 'leverage',
          'leverage': leverage,
          'maxLeverage': maxLeverage,
        },
      );
    }
    return HyperAxisUpdateLeverageRequest._(
      network: network,
      asset: asset,
      isCross: isCross,
      leverage: leverage,
      maxLeverage: maxLeverage,
      nonce: nonce,
      vaultAddress: vaultAddress,
      expiresAfter: expiresAfter,
    );
  }

  const HyperAxisUpdateLeverageRequest._({
    required this.network,
    required this.asset,
    required this.isCross,
    required this.leverage,
    required this.maxLeverage,
    required this.nonce,
    required this.vaultAddress,
    required this.expiresAfter,
  });

  /// Target environment.
  final HyperAxisNetwork network;

  /// Hyperliquid exchange asset identifier.
  final int asset;

  /// Whether the market should use cross margin.
  final bool isCross;

  /// Requested leverage multiplier.
  final int leverage;

  /// Current maximum leverage from market metadata.
  final int maxLeverage;

  /// Millisecond nonce encoded as an unsigned decimal string.
  final String nonce;

  /// Optional vault or subaccount address.
  final String? vaultAddress;

  /// Optional expiry timestamp encoded as an unsigned decimal string.
  final String? expiresAfter;

  /// Encodes the exact request schema consumed by Rust.
  String toBridgeJson() => jsonEncode(<String, Object?>{
    'network': network.wireName,
    'asset': asset,
    'isCross': isCross,
    'leverage': leverage,
    'maxLeverage': maxLeverage,
    'nonce': nonce,
    'vaultAddress': vaultAddress,
    'expiresAfter': expiresAfter,
  });
}

/// Opaque Rust-validated artifacts required to sign a leverage update.
final class HyperAxisPreparedLeverageUpdate {
  /// Creates a decoded prepared update returned by the bridge.
  const HyperAxisPreparedLeverageUpdate({
    required this.network,
    required this.nonce,
    required this.vaultAddress,
    required this.expiresAfter,
    required this.actionJson,
    required this.messagePackHex,
    required this.actionHashHex,
    required this.signingDigestHex,
    required this.bridgeJson,
  });

  /// Environment used for signing and submission.
  final HyperAxisNetwork network;

  /// Nonce encoded as an unsigned decimal string.
  final String nonce;

  /// Optional vault or subaccount address.
  final String? vaultAddress;

  /// Optional expiry timestamp encoded as an unsigned decimal string.
  final String? expiresAfter;

  /// Canonical action JSON produced by Rust.
  final String actionJson;

  /// Canonical named-map MessagePack encoded as lowercase hexadecimal.
  final String messagePackHex;

  /// Keccak action hash encoded as lowercase hexadecimal.
  final String actionHashHex;

  /// EIP-712 digest that the wallet must sign exactly once.
  final String signingDigestHex;

  /// Complete opaque artifact passed back to Rust during finalization.
  final String bridgeJson;
}

/// Exact input for adding or removing isolated position margin.
final class HyperAxisUpdateIsolatedMarginRequest {
  /// Creates an exact isolated-margin update without floating-point math.
  factory HyperAxisUpdateIsolatedMarginRequest({
    required HyperAxisNetwork network,
    required int asset,
    required bool isBuy,
    required String usdDelta,
    required String nonce,
    String? vaultAddress,
    String? expiresAfter,
  }) {
    if (asset < 0 || asset > 0xffffffff) {
      throw HyperAxisException(
        code: HyperAxisErrorCode.invalidArgument,
        message: 'asset is outside its unsigned integer range.',
      );
    }
    return HyperAxisUpdateIsolatedMarginRequest._(
      network: network,
      asset: asset,
      isBuy: isBuy,
      usdDelta: usdDelta,
      nonce: nonce,
      vaultAddress: vaultAddress,
      expiresAfter: expiresAfter,
    );
  }

  const HyperAxisUpdateIsolatedMarginRequest._({
    required this.network,
    required this.asset,
    required this.isBuy,
    required this.usdDelta,
    required this.nonce,
    required this.vaultAddress,
    required this.expiresAfter,
  });

  /// Environment used for signing and submission.
  final HyperAxisNetwork network;

  /// Hyperliquid numeric perpetual asset identifier.
  final int asset;

  /// Position side whose isolated margin is updated.
  final bool isBuy;

  /// Signed US dollar delta encoded as an exact decimal string.
  final String usdDelta;

  /// Nonce encoded as an unsigned decimal string.
  final String nonce;

  /// Optional vault or subaccount address.
  final String? vaultAddress;

  /// Optional expiry timestamp encoded as an unsigned decimal string.
  final String? expiresAfter;

  /// Encodes the exact Rust request shape.
  String toBridgeJson() => jsonEncode(<String, Object?>{
    'network': network.wireName,
    'asset': asset,
    'isBuy': isBuy,
    'usdDelta': usdDelta,
    'nonce': nonce,
    'vaultAddress': vaultAddress,
    'expiresAfter': expiresAfter,
  });
}
