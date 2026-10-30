import 'dart:convert';

import 'orders.dart';

/// Runtime-neutral HTTP request produced by Rust Core.
final class HyperAxisHttpRequest {
  /// Creates an immutable request description.
  HyperAxisHttpRequest({
    required this.kind,
    required this.method,
    required this.url,
    required Map<String, String> headers,
    required this.body,
  }) : headers = Map<String, String>.unmodifiable(headers);

  /// Request family, currently `info` or `signedAction`.
  final String kind;

  /// HTTP method, currently `POST`.
  final String method;

  /// Official Hyperliquid endpoint.
  final String url;

  /// Immutable request headers.
  final Map<String, String> headers;

  /// Canonical JSON body. Send this string without decoding and re-encoding it.
  final String body;
}

/// Perpetual account margin totals.
final class HyperAxisPerpMarginSummary {
  /// Creates exact margin totals returned by HyperCore.
  const HyperAxisPerpMarginSummary({
    required this.accountValue,
    required this.totalMarginUsed,
    required this.totalNtlPos,
    required this.totalRawUsd,
  });

  /// Account equity including unrealized PnL.
  final String accountValue;

  /// Initial margin reserved by open positions.
  final String totalMarginUsed;

  /// Aggregate absolute position notional.
  final String totalNtlPos;

  /// Raw USD balance before unrealized PnL.
  final String totalRawUsd;
}

/// Funding totals for one perpetual position.
final class HyperAxisPerpCumulativeFunding {
  /// Creates exact cumulative funding totals.
  const HyperAxisPerpCumulativeFunding({
    required this.allTime,
    required this.sinceChange,
    required this.sinceOpen,
  });

  /// Lifetime funding.
  final String allTime;

  /// Funding since the latest position change.
  final String sinceChange;

  /// Funding since the position was opened.
  final String sinceOpen;
}

/// Cross or isolated leverage configuration.
final class HyperAxisPerpLeverage {
  /// Creates a leverage description returned by HyperCore.
  const HyperAxisPerpLeverage({
    required this.type,
    required this.value,
    required this.rawUsd,
  });

  /// Margin mode, currently `cross` or `isolated`.
  final String type;

  /// User-selected leverage.
  final int value;

  /// Isolated raw USD allocation, when present.
  final String? rawUsd;
}

/// One perpetual position with exact decimal strings.
final class HyperAxisPerpPosition {
  /// Creates a decoded perpetual position.
  const HyperAxisPerpPosition({
    required this.coin,
    required this.cumulativeFunding,
    required this.entryPrice,
    required this.leverage,
    required this.liquidationPrice,
    required this.marginUsed,
    required this.maxLeverage,
    required this.positionValue,
    required this.returnOnEquity,
    required this.signedSize,
    required this.unrealizedPnl,
  });

  /// Canonical market name.
  final String coin;

  /// Funding totals.
  final HyperAxisPerpCumulativeFunding cumulativeFunding;

  /// Average entry price.
  final String? entryPrice;

  /// Margin mode and leverage.
  final HyperAxisPerpLeverage leverage;

  /// Estimated liquidation price.
  final String? liquidationPrice;

  /// Initial margin currently used.
  final String marginUsed;

  /// Market maximum leverage.
  final int maxLeverage;

  /// Current position notional.
  final String positionValue;

  /// Position return on equity.
  final String returnOnEquity;

  /// Signed position size; positive is long and negative is short.
  final String signedSize;

  /// Current unrealized PnL.
  final String unrealizedPnl;
}

/// Position envelope returned by HyperCore.
final class HyperAxisPerpAssetPosition {
  /// Creates a position envelope.
  const HyperAxisPerpAssetPosition({
    required this.type,
    required this.position,
  });

  /// Position representation, currently `oneWay`.
  final String type;

  /// Position details.
  final HyperAxisPerpPosition position;
}

/// Strongly typed `clearinghouseState` response.
final class HyperAxisPerpAccountState {
  /// Creates an immutable perpetual account snapshot.
  HyperAxisPerpAccountState({
    required List<HyperAxisPerpAssetPosition> assetPositions,
    required this.crossMaintenanceMarginUsed,
    required this.crossMarginSummary,
    required this.marginSummary,
    required this.time,
    required this.withdrawable,
  }) : assetPositions = List<HyperAxisPerpAssetPosition>.unmodifiable(
         assetPositions,
       );

  /// Open positions.
  final List<HyperAxisPerpAssetPosition> assetPositions;

  /// Maintenance margin used by cross positions.
  final String crossMaintenanceMarginUsed;

  /// Cross-margin totals.
  final HyperAxisPerpMarginSummary crossMarginSummary;

  /// Totals including isolated positions.
  final HyperAxisPerpMarginSummary marginSummary;

  /// Server timestamp encoded as an exact decimal string.
  final String time;

  /// Currently withdrawable perpetual balance.
  final String withdrawable;
}

/// One token balance from `spotClearinghouseState`.
final class HyperAxisSpotBalance {
  /// Creates an exact spot balance.
  const HyperAxisSpotBalance({
    required this.coin,
    required this.token,
    required this.hold,
    required this.total,
    required this.entryNotional,
  });

  /// HyperCore token ticker.
  final String coin;

  /// HyperCore token index.
  final int token;

  /// Amount reserved by open orders.
  final String hold;

  /// Total balance including held funds.
  final String total;

  /// Frontend entry notional.
  final String entryNotional;
}

/// Strongly typed `spotClearinghouseState` response.
final class HyperAxisSpotAccountState {
  /// Creates an immutable spot account snapshot.
  HyperAxisSpotAccountState({required List<HyperAxisSpotBalance> balances})
    : balances = List<HyperAxisSpotBalance>.unmodifiable(balances);

  /// Token balances.
  final List<HyperAxisSpotBalance> balances;
}

/// Validated account WebSocket message.
final class HyperAxisAccountWebSocketMessage {
  /// Creates a decoded account message.
  HyperAxisAccountWebSocketMessage({
    required this.channel,
    required Object? data,
    required this.canonicalJson,
  }) : data = _deeplyUnmodifiableJson(data);

  /// Hyperliquid WebSocket channel.
  final String channel;

  /// Channel-specific JSON payload.
  final Object? data;

  /// Rust-canonicalized message JSON.
  final String canonicalJson;
}

/// Exact input for moving USDC between spot and perpetual balances.
final class HyperAxisUsdClassTransferRequest {
  /// Creates a class-transfer request without performing local calculations.
  const HyperAxisUsdClassTransferRequest({
    required this.network,
    required this.amount,
    required this.toPerp,
    required this.nonce,
    this.subAccount,
  });

  /// Target environment.
  final HyperAxisNetwork network;

  /// Positive exact USDC amount.
  final String amount;

  /// `true` for Spot to Perp; `false` for Perp to Spot.
  final bool toPerp;

  /// Optional source subaccount.
  final String? subAccount;

  /// Millisecond nonce encoded as an unsigned decimal string.
  final String nonce;

  /// Encodes the exact Rust request schema.
  String toBridgeJson() => jsonEncode(<String, Object?>{
    'network': network.wireName,
    'amount': amount,
    'toPerp': toPerp,
    'subAccount': subAccount,
    'nonce': nonce,
  });
}

/// Opaque Rust-validated user action awaiting a main-wallet signature.
final class HyperAxisPreparedUserAction {
  /// Creates a decoded prepared user action.
  const HyperAxisPreparedUserAction({
    required this.network,
    required this.nonce,
    required this.actionJson,
    required this.signingDigestHex,
    required this.bridgeJson,
  });

  /// Target environment.
  final HyperAxisNetwork network;

  /// Exact outer nonce.
  final String nonce;

  /// Canonical action JSON.
  final String actionJson;

  /// EIP-712 digest that the main wallet signs exactly once.
  final String signingDigestHex;

  /// Complete opaque artifact passed unchanged into finalization.
  final String bridgeJson;
}

Object? _deeplyUnmodifiableJson(Object? value) {
  if (value is Map<String, Object?>) {
    return Map<String, Object?>.unmodifiable(
      value.map(
        (String key, Object? item) =>
            MapEntry<String, Object?>(key, _deeplyUnmodifiableJson(item)),
      ),
    );
  }
  if (value is List<Object?>) {
    return List<Object?>.unmodifiable(value.map(_deeplyUnmodifiableJson));
  }
  return value;
}
