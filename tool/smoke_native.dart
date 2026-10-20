import 'dart:io';

import 'package:hyper_axis/hyper_axis.dart';

Future<void> main() async {
  final HyperAxisClient client = await HyperAxisClient.initialize();

  if (client.protocolVersion != hyperAxisRustProtocolVersion) {
    throw StateError(
      'Rust protocol ${client.protocolVersion} is incompatible with '
      'expected protocol $hyperAxisRustProtocolVersion.',
    );
  }
  if (client.normalizeDecimal('001.2300') != '1.23') {
    throw StateError('Rust decimal normalization returned an invalid value.');
  }

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
  if (prepared.signingDigestHex !=
      '329f08729a8f946791ed6e4046ad7d94fb9be574629f1892b48baa6578abc0bc') {
    throw StateError('Rust returned an unexpected order signing digest.');
  }
  final HyperAxisFinalizedAction finalized = client.finalizeOrder(
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

  final HyperAxisLoggingConfig applied = client.configureLogging(
    HyperAxisLoggingConfig(
      enabled: true,
      level: HyperAxisLogLevel.info,
      capacity: 32,
    ),
  );
  if (!applied.enabled || applied.capacity != 32) {
    throw StateError('Rust logging configuration was not applied.');
  }

  client.clearLogs();
  final HyperAxisLogBatch logs = client.snapshotLogs();
  if (logs.dropped != '0') {
    throw StateError('Fresh diagnostic buffer has dropped records.');
  }

  client.configureLogging(HyperAxisLoggingConfig());
  stdout.writeln('HyperAxis native bridge smoke test passed.');
}
