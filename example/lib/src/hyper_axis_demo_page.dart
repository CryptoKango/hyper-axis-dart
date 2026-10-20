import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hyper_axis/hyper_axis.dart';

import 'hyper_axis_demo_controller.dart';
import 'order_demo_card.dart';
import 'websocket/market_stream_card.dart';

final class HyperAxisDemoPage extends StatefulWidget {
  const HyperAxisDemoPage({super.key});

  @override
  State<HyperAxisDemoPage> createState() => _HyperAxisDemoPageState();
}

final class _HyperAxisDemoPageState extends State<HyperAxisDemoPage>
    with WidgetsBindingObserver {
  final HyperAxisDemoController _controller = HyperAxisDemoController();
  final TextEditingController _decimalController = TextEditingController(
    text: '00123.4500',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_controller.resumeMarketStream());
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(_controller.pauseMarketStream());
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _decimalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HyperAxis 移动端示例')),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return switch (_controller.status) {
            HyperAxisDemoStatus.initializing => const Center(
              child: CircularProgressIndicator(),
            ),
            HyperAxisDemoStatus.failed => _InitializationError(
              message: _controller.errorMessage ?? '初始化失败',
              onRetry: _controller.initialize,
            ),
            HyperAxisDemoStatus.ready => _buildReadyContent(),
          };
        },
      ),
    );
  }

  Widget _buildReadyContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: <Widget>[
        const _SafetyNotice(),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'SDK 状态',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Dart SDK：$hyperAxisDartVersion'),
              Text('Rust 协议：${_controller.protocolVersion}'),
              const Text('平台：Android API 24+ / iOS 13+'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildDecimalCard(),
        const SizedBox(height: 12),
        _buildLoggingCard(),
        const SizedBox(height: 12),
        MarketStreamCard(controller: _controller),
        const SizedBox(height: 12),
        OrderDemoCard(controller: _controller),
        if (_controller.errorMessage case final String message) ...<Widget>[
          const SizedBox(height: 12),
          _ErrorBanner(message: message),
        ],
      ],
    );
  }

  Widget _buildDecimalCard() {
    return _SectionCard(
      title: '1. 精度规范化',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: _decimalController,
            decoration: const InputDecoration(labelText: '十进制字符串'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              _controller.normalizeDecimal(_decimalController.text);
            },
            child: const Text('由 Rust 规范化'),
          ),
          if (_controller.normalizedDecimal case final String value)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SelectableText('结果：$value'),
            ),
        ],
      ),
    );
  }

  Widget _buildLoggingCard() {
    final HyperAxisLogBatch? batch = _controller.logBatch;
    return _SectionCard(
      title: '2. 安全日志',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('启用 Rust 脱敏日志'),
            subtitle: const Text('默认关闭；容量固定为 100 条'),
            value: _controller.loggingEnabled,
            onChanged: (bool enabled) {
              _controller.configureLogging(
                enabled: enabled,
                level: _controller.logLevel,
              );
            },
          ),
          DropdownButtonFormField<HyperAxisLogLevel>(
            initialValue: _controller.logLevel,
            decoration: const InputDecoration(labelText: '日志级别'),
            items: HyperAxisLogLevel.values
                .map((HyperAxisLogLevel level) {
                  return DropdownMenuItem<HyperAxisLogLevel>(
                    value: level,
                    child: Text(level.name),
                  );
                })
                .toList(growable: false),
            onChanged: (HyperAxisLogLevel? level) {
              if (level != null) {
                _controller.configureLogging(
                  enabled: _controller.loggingEnabled,
                  level: level,
                );
              }
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton(
                onPressed: _controller.snapshotLogs,
                child: const Text('快照'),
              ),
              OutlinedButton(
                onPressed: _controller.drainLogs,
                child: const Text('读取并清空'),
              ),
              OutlinedButton(
                onPressed: _controller.clearLogs,
                child: const Text('清空'),
              ),
            ],
          ),
          if (batch != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '当前 ${batch.records.length} 条，已丢弃 ${batch.dropped} 条',
              ),
            ),
          if (batch != null && batch.records.isNotEmpty) ...<Widget>[
            const Divider(height: 24),
            ...batch.records.reversed
                .take(10)
                .map(
                  (HyperAxisLogRecord record) => _LogRecordTile(record: record),
                ),
          ],
        ],
      ),
    );
  }
}

final class _LogRecordTile extends StatelessWidget {
  const _LogRecordTile({required this.record});

  final HyperAxisLogRecord record;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '#${record.sequence} ${record.level.wireName} '
            '${record.target} · ${record.timestampMs}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          SelectableText(record.message),
        ],
      ),
    );
  }
}

final class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          '本示例默认使用 testnet，只生成待签数据，不持有私钥、不签名、'
          '不调用交易接口。asset 与 szDecimals 应来自最新市场元数据。',
        ),
      ),
    );
  }
}

final class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

final class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
    );
  }
}

final class _InitializationError extends StatelessWidget {
  const _InitializationError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
