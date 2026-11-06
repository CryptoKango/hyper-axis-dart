import 'dart:convert';

import '../error/hyper_axis_exception.dart';

/// Hyperliquid environment used for routing and signature replay protection.
enum HyperAxisNetwork {
  /// Production environment.
  mainnet('mainnet'),

  /// Public test environment.
  testnet('testnet');

  const HyperAxisNetwork(this.wireName);

  /// Exact Rust wire representation.
  final String wireName;

  /// Official Hyperliquid WebSocket endpoint for this environment.
  String get websocketUrl => switch (this) {
    HyperAxisNetwork.mainnet => 'wss://api.hyperliquid.xyz/ws',
    HyperAxisNetwork.testnet => 'wss://api.hyperliquid-testnet.xyz/ws',
  };
}

/// Market family controlling price and size precision rules.
enum HyperAxisMarketKind {
  /// Regular or HIP-3 perpetual market.
  perpetual('perpetual'),

  /// Spot market.
  spot('spot');

  const HyperAxisMarketKind(this.wireName);

  /// Exact Rust wire representation.
  final String wireName;
}

/// Time-in-force behavior for a limit order.
enum HyperAxisTimeInForce {
  /// Add liquidity or cancel.
  alo('Alo'),

  /// Immediate or cancel.
  ioc('Ioc'),

  /// Good until canceled.
  gtc('Gtc');

  const HyperAxisTimeInForce(this.wireName);

  /// Exact Rust wire representation.
  final String wireName;
}

/// Grouping mode for an order action.
enum HyperAxisOrderGrouping {
  /// Independent order.
  none('na'),

  /// Normal take-profit/stop-loss grouping.
  normalTakeProfitStopLoss('normalTpsl'),

  /// Position take-profit/stop-loss grouping.
  positionTakeProfitStopLoss('positionTpsl');

  const HyperAxisOrderGrouping(this.wireName);

  /// Exact Rust wire representation.
  final String wireName;
}

/// Trigger-order classification used by Hyperliquid conditional orders.
enum HyperAxisTriggerKind {
  /// Take-profit trigger.
  takeProfit('tp'),

  /// Stop-loss trigger.
  stopLoss('sl');

  const HyperAxisTriggerKind(this.wireName);

  /// Exact Rust wire representation.
  final String wireName;
}

/// Optional builder fee attribution included in an order action.
final class HyperAxisBuilderFee {
  /// Creates exact builder attribution without using floating-point math.
  factory HyperAxisBuilderFee({required String address, required int fee}) {
    _requireUnsignedRange('builderFee', fee, 0xffffffff);
    return HyperAxisBuilderFee._(address: address, fee: fee);
  }

  const HyperAxisBuilderFee._({required this.address, required this.fee});

  /// Builder EVM address receiving the fee.
  final String address;

  /// Fee in tenths of a basis point.
  final int fee;

  /// Encodes the exact Rust request shape.
  Map<String, Object?> toBridgeJson() => <String, Object?>{
    'address': address,
    'fee': fee,
  };
}

/// One trigger order accepted by the mixed order preparation API.
final class HyperAxisTriggerOrderInput {
  /// Creates an exact trigger order without performing price calculations.
  factory HyperAxisTriggerOrderInput({
    required int asset,
    required HyperAxisMarketKind marketKind,
    required int sizeDecimals,
    required bool isBuy,
    required String limitPrice,
    required String triggerPrice,
    required String size,
    required bool reduceOnly,
    required bool isMarket,
    required HyperAxisTriggerKind triggerKind,
    String? clientOrderId,
  }) {
    _requireUnsignedRange('asset', asset, 0xffffffff);
    _requireUnsignedRange('sizeDecimals', sizeDecimals, 0xff);
    return HyperAxisTriggerOrderInput._(
      asset: asset,
      marketKind: marketKind,
      sizeDecimals: sizeDecimals,
      isBuy: isBuy,
      limitPrice: limitPrice,
      triggerPrice: triggerPrice,
      size: size,
      reduceOnly: reduceOnly,
      isMarket: isMarket,
      triggerKind: triggerKind,
      clientOrderId: clientOrderId,
    );
  }

  const HyperAxisTriggerOrderInput._({
    required this.asset,
    required this.marketKind,
    required this.sizeDecimals,
    required this.isBuy,
    required this.limitPrice,
    required this.triggerPrice,
    required this.size,
    required this.reduceOnly,
    required this.isMarket,
    required this.triggerKind,
    required this.clientOrderId,
  });

  /// Hyperliquid numeric asset identifier.
  final int asset;

  /// Market family controlling precision rules.
  final HyperAxisMarketKind marketKind;

  /// Exact size precision published by market metadata.
  final int sizeDecimals;

  /// Whether the trigger creates a buy-side order.
  final bool isBuy;

  /// Limit price submitted after the trigger fires.
  final String limitPrice;

  /// Exact price that activates the conditional order.
  final String triggerPrice;

  /// Exact order size in base-asset units.
  final String size;

  /// Whether the order may only reduce an existing position.
  final bool reduceOnly;

  /// Whether the activated order should execute as a market order.
  final bool isMarket;

  /// Take-profit or stop-loss classification.
  final HyperAxisTriggerKind triggerKind;

  /// Optional client order identifier used for idempotent tracking.
  final String? clientOrderId;

  /// Encodes the exact mixed-order input expected by Rust.
  Map<String, Object?> toBridgeJson() => <String, Object?>{
    'kind': 'trigger',
    'asset': asset,
    'marketKind': marketKind.wireName,
    'szDecimals': sizeDecimals,
    'isBuy': isBuy,
    'limitPrice': limitPrice,
    'triggerPrice': triggerPrice,
    'size': size,
    'reduceOnly': reduceOnly,
    'isMarket': isMarket,
    'triggerKind': triggerKind.wireName,
    'clientOrderId': clientOrderId,
  };
}

/// Exact input for preparing one or more trigger orders atomically.
final class HyperAxisTriggerOrdersRequest {
  /// Creates one atomic conditional-order action.
  factory HyperAxisTriggerOrdersRequest({
    required HyperAxisNetwork network,
    required List<HyperAxisTriggerOrderInput> orders,
    required HyperAxisOrderGrouping grouping,
    required String nonce,
    HyperAxisBuilderFee? builder,
    String? vaultAddress,
    String? expiresAfter,
  }) {
    if (orders.isEmpty) {
      throw HyperAxisException(
        code: HyperAxisErrorCode.invalidArgument,
        message: 'orders must not be empty.',
      );
    }
    _requireUnsignedDecimal('nonce', nonce);
    if (expiresAfter != null) {
      _requireUnsignedDecimal('expiresAfter', expiresAfter);
    }
    return HyperAxisTriggerOrdersRequest._(
      network: network,
      orders: List<HyperAxisTriggerOrderInput>.unmodifiable(orders),
      grouping: grouping,
      nonce: nonce,
      builder: builder,
      vaultAddress: vaultAddress,
      expiresAfter: expiresAfter,
    );
  }

  const HyperAxisTriggerOrdersRequest._({
    required this.network,
    required this.orders,
    required this.grouping,
    required this.nonce,
    required this.builder,
    required this.vaultAddress,
    required this.expiresAfter,
  });

  /// Environment used for signing and submission.
  final HyperAxisNetwork network;

  /// Trigger orders included in the atomic action.
  final List<HyperAxisTriggerOrderInput> orders;

  /// Hyperliquid TP/SL grouping behavior.
  final HyperAxisOrderGrouping grouping;

  /// Nonce encoded as an unsigned decimal string.
  final String nonce;

  /// Optional builder fee attribution.
  final HyperAxisBuilderFee? builder;

  /// Optional vault or subaccount address.
  final String? vaultAddress;

  /// Optional expiry timestamp encoded as an unsigned decimal string.
  final String? expiresAfter;

  /// Encodes the exact Rust request shape.
  String toBridgeJson() => jsonEncode(<String, Object?>{
    'network': network.wireName,
    'orders': orders.map((order) => order.toBridgeJson()).toList(),
    'grouping': grouping.wireName,
    'builder': builder?.toBridgeJson(),
    'nonce': nonce,
    'vaultAddress': vaultAddress,
    'expiresAfter': expiresAfter,
  });
}

/// Exact input for preparing one Hyperliquid limit order in Rust.
final class HyperAxisLimitOrderRequest {
  /// Creates a limit-order request without performing protocol calculations.
  factory HyperAxisLimitOrderRequest({
    required HyperAxisNetwork network,
    required int asset,
    required HyperAxisMarketKind marketKind,
    required int sizeDecimals,
    required bool isBuy,
    required String limitPrice,
    required String size,
    required String nonce,
    bool reduceOnly = false,
    HyperAxisTimeInForce timeInForce = HyperAxisTimeInForce.gtc,
    String? clientOrderId,
    HyperAxisOrderGrouping grouping = HyperAxisOrderGrouping.none,
    HyperAxisBuilderFee? builder,
    String? vaultAddress,
    String? expiresAfter,
  }) {
    _requireUnsignedRange('asset', asset, 0xffffffff);
    _requireUnsignedRange('sizeDecimals', sizeDecimals, 0xff);
    return HyperAxisLimitOrderRequest._(
      network: network,
      asset: asset,
      marketKind: marketKind,
      sizeDecimals: sizeDecimals,
      isBuy: isBuy,
      limitPrice: limitPrice,
      size: size,
      reduceOnly: reduceOnly,
      timeInForce: timeInForce,
      clientOrderId: clientOrderId,
      grouping: grouping,
      builder: builder,
      nonce: nonce,
      vaultAddress: vaultAddress,
      expiresAfter: expiresAfter,
    );
  }

  const HyperAxisLimitOrderRequest._({
    required this.network,
    required this.asset,
    required this.marketKind,
    required this.sizeDecimals,
    required this.isBuy,
    required this.limitPrice,
    required this.size,
    required this.reduceOnly,
    required this.timeInForce,
    required this.clientOrderId,
    required this.grouping,
    required this.builder,
    required this.nonce,
    required this.vaultAddress,
    required this.expiresAfter,
  });

  /// Target environment.
  final HyperAxisNetwork network;

  /// Hyperliquid exchange asset identifier.
  final int asset;

  /// Perpetual or spot precision family.
  final HyperAxisMarketKind marketKind;

  /// `szDecimals` obtained from current market metadata.
  final int sizeDecimals;

  /// Whether the order buys the asset.
  final bool isBuy;

  /// Exact decimal limit price.
  final String limitPrice;

  /// Exact decimal order size.
  final String size;

  /// Whether execution may only reduce a position.
  final bool reduceOnly;

  /// Limit-order time in force.
  final HyperAxisTimeInForce timeInForce;

  /// Optional 128-bit client order identifier.
  final String? clientOrderId;

  /// Batch grouping mode.
  final HyperAxisOrderGrouping grouping;

  /// Optional builder fee attribution.
  final HyperAxisBuilderFee? builder;

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
    'marketKind': marketKind.wireName,
    'szDecimals': sizeDecimals,
    'isBuy': isBuy,
    'limitPrice': limitPrice,
    'size': size,
    'reduceOnly': reduceOnly,
    'timeInForce': timeInForce.wireName,
    'clientOrderId': clientOrderId,
    'grouping': grouping.wireName,
    'builder': builder?.toBridgeJson(),
    'nonce': nonce,
    'vaultAddress': vaultAddress,
    'expiresAfter': expiresAfter,
  });
}

/// One exchange order selected for cancellation by its server-assigned OID.
final class HyperAxisCancelOrder {
  /// Creates an exact cancellation selector.
  const HyperAxisCancelOrder({required this.asset, required this.orderId});

  /// Hyperliquid exchange asset identifier.
  final int asset;

  /// Unsigned decimal OID string returned by the exchange.
  final String orderId;

  /// Encodes this selector for the Rust request schema.
  Map<String, Object?> toBridgeJson() => <String, Object?>{
    'asset': asset,
    'oid': orderId,
  };
}

/// Exact input for preparing one or more Hyperliquid cancellations.
final class HyperAxisCancelRequest {
  /// Creates a cancellation request without handling private keys.
  HyperAxisCancelRequest({
    required this.network,
    required List<HyperAxisCancelOrder> cancels,
    required this.nonce,
    this.vaultAddress,
    this.expiresAfter,
  }) : cancels = List<HyperAxisCancelOrder>.unmodifiable(cancels) {
    if (cancels.isEmpty) {
      throw HyperAxisException(
        code: HyperAxisErrorCode.invalidArgument,
        message: 'cancels must not be empty.',
      );
    }
    for (final HyperAxisCancelOrder cancel in cancels) {
      _requireUnsignedRange('asset', cancel.asset, 0xffffffff);
      _requireUnsignedDecimal('orderId', cancel.orderId);
    }
    _requireUnsignedDecimal('nonce', nonce);
    if (expiresAfter != null) {
      _requireUnsignedDecimal('expiresAfter', expiresAfter!);
    }
  }

  /// Target environment.
  final HyperAxisNetwork network;

  /// Non-empty immutable cancellation collection.
  final List<HyperAxisCancelOrder> cancels;

  /// Millisecond nonce encoded as an unsigned decimal string.
  final String nonce;

  /// Optional vault or subaccount address.
  final String? vaultAddress;

  /// Optional expiry timestamp encoded as an unsigned decimal string.
  final String? expiresAfter;

  /// Encodes the exact Rust request schema.
  String toBridgeJson() => jsonEncode(<String, Object?>{
    'network': network.wireName,
    'cancels': cancels
        .map((HyperAxisCancelOrder value) => value.toBridgeJson())
        .toList(growable: false),
    'nonce': nonce,
    'vaultAddress': vaultAddress,
    'expiresAfter': expiresAfter,
  });
}

/// Opaque Rust-validated artifacts required by the platform signer.
final class HyperAxisPreparedOrder {
  /// Creates a decoded prepared order returned by the bridge.
  const HyperAxisPreparedOrder({
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
  ///
  /// Rust revalidates every field, so modified artifacts are rejected.
  final String bridgeJson;
}

/// Recoverable secp256k1 signature returned by the platform signer.
final class HyperAxisSignature {
  /// Creates signature components for Rust validation and normalization.
  const HyperAxisSignature({required this.r, required this.s, required this.v});

  /// 32-byte `r` scalar encoded as hexadecimal.
  final String r;

  /// 32-byte low-`s` scalar encoded as hexadecimal.
  final String s;

  /// Recovery identifier accepted as 0, 1, 27, or 28.
  final int v;
}

/// Final exchange request returned after signature verification.
final class HyperAxisFinalizedAction {
  /// Creates a decoded finalized action returned by the bridge.
  const HyperAxisFinalizedAction({
    required this.endpoint,
    required this.requestJson,
    required this.recoveredSigner,
  });

  /// Official exchange endpoint for the selected network.
  final String endpoint;

  /// Canonical JSON body for `POST /exchange`.
  final String requestJson;

  /// Recovered signer address normalized by Rust.
  final String recoveredSigner;

  /// Encodes the exact finalized action accepted by Rust transport helpers.
  String toBridgeJson() => jsonEncode(<String, Object?>{
    'endpoint': endpoint,
    'requestJson': requestJson,
    'recoveredSigner': recoveredSigner,
  });
}

void _requireUnsignedRange(String field, int value, int maximum) {
  if (value < 0 || value > maximum) {
    throw HyperAxisException(
      code: HyperAxisErrorCode.invalidArgument,
      message: '$field is outside its unsigned integer range.',
      details: <String, Object?>{'field': field},
    );
  }
}

void _requireUnsignedDecimal(String field, String value) {
  if (!RegExp(r'^(0|[1-9][0-9]*)$').hasMatch(value)) {
    throw HyperAxisException(
      code: HyperAxisErrorCode.invalidArgument,
      message: '$field must be an unsigned decimal string.',
    );
  }
}
