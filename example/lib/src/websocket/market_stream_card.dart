import 'package:flutter/material.dart';

import '../hyper_axis_demo_controller.dart';
import 'hyperliquid_websocket_models.dart';

final class MarketStreamCard extends StatelessWidget {
  const MarketStreamCard({required this.controller, super.key});

  final HyperAxisDemoController controller;

  @override
  Widget build(BuildContext context) {
    final HyperliquidWebSocketState state = controller.webSocketState;
    final bool canConnect = state == HyperliquidWebSocketState.disconnected;
    final bool canDisconnect =
        state != HyperliquidWebSocketState.disconnected &&
        state != HyperliquidWebSocketState.closing;
    final List<MapEntry<String, String>> prices =
        controller.midPrices.entries.toList(growable: false)..sort(
          (MapEntry<String, String> left, MapEntry<String, String> right) =>
              left.key.compareTo(right.key),
        );

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '3. WebSocket 实时行情',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('连接 Hyperliquid Testnet，订阅公开 allMids。异常断线后自动重连并恢复订阅。'),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                _ConnectionIndicator(state: state),
                const Spacer(),
                if (controller.lastMarketUpdate case final DateTime updatedAt)
                  Text(
                    'UTC ${updatedAt.toIso8601String().substring(11, 19)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: canConnect ? controller.connectMarketStream : null,
                  icon: const Icon(Icons.cloud_outlined),
                  label: const Text('连接并订阅'),
                ),
                OutlinedButton.icon(
                  onPressed: canDisconnect
                      ? controller.disconnectMarketStream
                      : null,
                  icon: const Icon(Icons.cloud_off_outlined),
                  label: const Text('断开'),
                ),
              ],
            ),
            if (controller.webSocketError case final String error) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (prices.isNotEmpty) ...<Widget>[
              const Divider(height: 24),
              Text(
                '中间价（展示前 12 项，共 ${prices.length} 项）',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              ...prices
                  .take(12)
                  .map(
                    (MapEntry<String, String> entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: <Widget>[
                          Expanded(child: Text(entry.key)),
                          SelectableText(entry.value),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _ConnectionIndicator extends StatelessWidget {
  const _ConnectionIndicator({required this.state});

  final HyperliquidWebSocketState state;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (state) {
      HyperliquidWebSocketState.disconnected => (
        '未连接',
        Theme.of(context).colorScheme.outline,
      ),
      HyperliquidWebSocketState.connecting => (
        '连接中',
        Theme.of(context).colorScheme.primary,
      ),
      HyperliquidWebSocketState.connected => ('已连接', Colors.green),
      HyperliquidWebSocketState.reconnecting => ('重连中', Colors.orange),
      HyperliquidWebSocketState.closing => (
        '正在断开',
        Theme.of(context).colorScheme.outline,
      ),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
