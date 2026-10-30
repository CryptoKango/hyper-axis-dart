import 'dart:io';

import 'package:hyper_axis/hyper_axis.dart';
import 'package:hyper_axis/src/bridge/frb_hyper_axis_bridge.dart';

Future<void> main() async {
  final HyperAxisBridge bridge = await FrbHyperAxisBridge.initialize();
  final bool usesDevelopmentCore =
      Platform.environment['HYPER_AXIS_CORE_DEV_ROOT']?.isNotEmpty ?? false;

  if (!usesDevelopmentCore &&
      bridge.protocolVersion != hyperAxisRustProtocolVersion) {
    throw StateError(
      'Rust protocol ${bridge.protocolVersion} is incompatible with '
      'expected protocol $hyperAxisRustProtocolVersion.',
    );
  }
  if (usesDevelopmentCore && bridge.protocolVersion.isEmpty) {
    throw StateError('Development Rust protocol version is empty.');
  }
  if (bridge.normalizeDecimal('001.2300') != '1.23') {
    throw StateError('Rust decimal normalization returned an invalid value.');
  }

  final HyperAxisPreparedOrder prepared = bridge.prepareLimitOrder(
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
  if (prepared.signingDigestHex !=
      '329f08729a8f946791ed6e4046ad7d94fb9be574629f1892b48baa6578abc0bc') {
    throw StateError('Rust returned an unexpected order signing digest.');
  }
  final HyperAxisFinalizedAction finalized = bridge.finalizeOrder(
    prepared: prepared,
    signature: const HyperAxisSignature(
      r: '0xc466abc93e91e15884da406ef9f37e72e924995f0661a286519e0a9e5c7ff919',
      s: '0x7cd5cef5728c82b9edcc45cf243f701b464d4b292f5c5d15605028902a1a3b20',
      v: 27,
    ),
    expectedSigner: '0x7e5f4552091a69125d5dfcb7b8c2659029395bdf',
  );
  if (finalized.recoveredSigner !=
      '0x7e5f4552091a69125d5dfcb7b8c2659029395bdf') {
    throw StateError('Rust recovered an unexpected order signer.');
  }

  final HyperAxisHttpRequest perpRequest = bridge.buildPerpAccountRequest(
    network: HyperAxisNetwork.mainnet,
    user: '0x000000000000000000000000000000000000beef',
    dex: '',
  );
  if (!perpRequest.body.contains('clearinghouseState')) {
    throw StateError('Rust returned an invalid perpetual account request.');
  }
  final HyperAxisPerpAccountState perpState = bridge.parsePerpAccountState(
    '{"assetPositions":[],"crossMaintenanceMarginUsed":"0.0",'
    '"crossMarginSummary":{"accountValue":"1","totalMarginUsed":"0",'
    '"totalNtlPos":"0","totalRawUsd":"1"},"marginSummary":'
    '{"accountValue":"1","totalMarginUsed":"0","totalNtlPos":"0",'
    '"totalRawUsd":"1"},"time":1,"withdrawable":"1"}',
  );
  if (perpState.time != '1' || perpState.withdrawable != '1') {
    throw StateError('Rust returned an invalid perpetual account state.');
  }
  final String subscription = bridge.subscribePerpAccount(
    user: '0x000000000000000000000000000000000000beef',
    dex: '',
  );
  if (!subscription.contains('clearinghouseState')) {
    throw StateError('Rust returned an invalid account subscription.');
  }

  final HyperAxisPreparedUserAction transfer = bridge.prepareUsdClassTransfer(
    const HyperAxisUsdClassTransferRequest(
      network: HyperAxisNetwork.mainnet,
      amount: '1.25',
      toPerp: true,
      nonce: '1234567890000',
    ),
  );
  if (transfer.signingDigestHex.isEmpty) {
    throw StateError('Rust returned an empty transfer signing digest.');
  }

  final HyperAxisLoggingConfig applied = bridge.configureLogging(
    HyperAxisLoggingConfig(
      enabled: true,
      level: HyperAxisLogLevel.info,
      capacity: 32,
    ),
  );
  if (!applied.enabled || applied.capacity != 32) {
    throw StateError('Rust logging configuration was not applied.');
  }

  bridge.clearLogs();
  final HyperAxisLogBatch logs = bridge.snapshotLogs();
  if (logs.dropped != '0') {
    throw StateError('Fresh diagnostic buffer has dropped records.');
  }

  bridge.configureLogging(HyperAxisLoggingConfig());
  stdout.writeln(
    'HyperAxis native bridge smoke test passed '
    '(Rust ${bridge.protocolVersion}).',
  );
}
