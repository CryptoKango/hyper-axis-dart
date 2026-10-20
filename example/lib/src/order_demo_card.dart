import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hyper_axis/hyper_axis.dart';

import 'hyper_axis_demo_controller.dart';

final class OrderDemoCard extends StatefulWidget {
  const OrderDemoCard({required this.controller, super.key});

  final HyperAxisDemoController controller;

  @override
  State<OrderDemoCard> createState() => _OrderDemoCardState();
}

final class _OrderDemoCardState extends State<OrderDemoCard> {
  final TextEditingController _assetController = TextEditingController(
    text: '0',
  );
  final TextEditingController _sizeDecimalsController = TextEditingController(
    text: '5',
  );
  final TextEditingController _priceController = TextEditingController(
    text: '100.0',
  );
  final TextEditingController _sizeController = TextEditingController(
    text: '0.001',
  );
  final TextEditingController _nonceController = TextEditingController();
  final TextEditingController _clientOrderIdController =
      TextEditingController();
  final TextEditingController _vaultAddressController = TextEditingController();
  final TextEditingController _expiresAfterController = TextEditingController();
  final TextEditingController _signatureRController = TextEditingController();
  final TextEditingController _signatureSController = TextEditingController();
  final TextEditingController _signatureVController = TextEditingController(
    text: '27',
  );
  final TextEditingController _expectedSignerController =
      TextEditingController();

  HyperAxisNetwork _network = HyperAxisNetwork.testnet;
  HyperAxisMarketKind _marketKind = HyperAxisMarketKind.perpetual;
  HyperAxisTimeInForce _timeInForce = HyperAxisTimeInForce.gtc;
  HyperAxisOrderGrouping _grouping = HyperAxisOrderGrouping.none;
  bool _isBuy = true;
  bool _reduceOnly = false;

  @override
  void dispose() {
    _assetController.dispose();
    _sizeDecimalsController.dispose();
    _priceController.dispose();
    _sizeController.dispose();
    _nonceController.dispose();
    _clientOrderIdController.dispose();
    _vaultAddressController.dispose();
    _expiresAfterController.dispose();
    _signatureRController.dispose();
    _signatureSController.dispose();
    _signatureVController.dispose();
    _expectedSignerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final HyperAxisPreparedOrder? prepared = widget.controller.preparedOrder;
    final HyperAxisFinalizedAction? finalized =
        widget.controller.finalizedAction;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('4. 限价单完整流程', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('构造订单 → 外部钱包签名 → Rust 验签并生成最终请求。'),
            const SizedBox(height: 16),
            _buildBasicFields(),
            _buildAdvancedFields(),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _prepareOrder,
              icon: const Icon(Icons.lock_outline),
              label: const Text('生成待签数据'),
            ),
            if (prepared != null) ...<Widget>[
              const Divider(height: 32),
              _PreparedOrderView(order: prepared),
              const SizedBox(height: 8),
              _buildSignatureFields(),
            ],
            if (finalized != null) ...<Widget>[
              const Divider(height: 32),
              _FinalizedActionView(action: finalized),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBasicFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DropdownButtonFormField<HyperAxisNetwork>(
          initialValue: _network,
          decoration: const InputDecoration(labelText: '网络'),
          items: HyperAxisNetwork.values
              .map(
                (HyperAxisNetwork value) => DropdownMenuItem<HyperAxisNetwork>(
                  value: value,
                  child: Text(value.wireName),
                ),
              )
              .toList(growable: false),
          onChanged: (HyperAxisNetwork? value) {
            if (value != null) setState(() => _network = value);
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _assetController,
                decoration: const InputDecoration(labelText: 'asset ID'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _sizeDecimalsController,
                decoration: const InputDecoration(labelText: 'szDecimals'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<HyperAxisMarketKind>(
          initialValue: _marketKind,
          decoration: const InputDecoration(labelText: '市场类型'),
          items: HyperAxisMarketKind.values
              .map(
                (HyperAxisMarketKind value) =>
                    DropdownMenuItem<HyperAxisMarketKind>(
                      value: value,
                      child: Text(value.wireName),
                    ),
              )
              .toList(growable: false),
          onChanged: (HyperAxisMarketKind? value) {
            if (value != null) setState(() => _marketKind = value);
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: '限价'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _sizeController,
                decoration: const InputDecoration(labelText: '数量'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: const <ButtonSegment<bool>>[
            ButtonSegment<bool>(value: true, label: Text('买入')),
            ButtonSegment<bool>(value: false, label: Text('卖出')),
          ],
          selected: <bool>{_isBuy},
          onSelectionChanged: (Set<bool> value) {
            setState(() => _isBuy = value.single);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<HyperAxisTimeInForce>(
          initialValue: _timeInForce,
          decoration: const InputDecoration(labelText: 'Time in force'),
          items: HyperAxisTimeInForce.values
              .map(
                (HyperAxisTimeInForce value) =>
                    DropdownMenuItem<HyperAxisTimeInForce>(
                      value: value,
                      child: Text(value.wireName),
                    ),
              )
              .toList(growable: false),
          onChanged: (HyperAxisTimeInForce? value) {
            if (value != null) setState(() => _timeInForce = value);
          },
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('仅减仓'),
          value: _reduceOnly,
          onChanged: (bool? value) {
            setState(() => _reduceOnly = value ?? false);
          },
        ),
      ],
    );
  }

  Widget _buildAdvancedFields() {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: const Text('高级订单字段'),
      subtitle: const Text('nonce、cloid、分组、vault 与过期时间'),
      children: <Widget>[
        DropdownButtonFormField<HyperAxisOrderGrouping>(
          initialValue: _grouping,
          decoration: const InputDecoration(labelText: '订单分组'),
          items: HyperAxisOrderGrouping.values
              .map(
                (HyperAxisOrderGrouping value) =>
                    DropdownMenuItem<HyperAxisOrderGrouping>(
                      value: value,
                      child: Text(value.wireName),
                    ),
              )
              .toList(growable: false),
          onChanged: (HyperAxisOrderGrouping? value) {
            if (value != null) setState(() => _grouping = value);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nonceController,
          decoration: const InputDecoration(
            labelText: 'nonce（可选）',
            helperText: '留空时使用当前毫秒时间戳',
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _clientOrderIdController,
          decoration: const InputDecoration(labelText: 'clientOrderId / cloid'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _vaultAddressController,
          decoration: const InputDecoration(labelText: 'vaultAddress'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _expiresAfterController,
          decoration: const InputDecoration(labelText: 'expiresAfter（毫秒）'),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildSignatureFields() {
    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: const Text('回填外部签名并生成请求'),
      subtitle: const Text('示例不读取私钥；请从宿主钱包取得 r、s、v。'),
      children: <Widget>[
        TextField(
          controller: _signatureRController,
          decoration: const InputDecoration(labelText: '签名 r'),
          autocorrect: false,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _signatureSController,
          decoration: const InputDecoration(labelText: '签名 s'),
          autocorrect: false,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _signatureVController,
          decoration: const InputDecoration(labelText: '签名 v（0/1/27/28）'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _expectedSignerController,
          decoration: const InputDecoration(labelText: 'expectedSigner'),
          autocorrect: false,
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: _finalizeOrder,
          icon: const Icon(Icons.verified_user_outlined),
          label: const Text('验签并生成最终请求'),
        ),
      ],
    );
  }

  void _prepareOrder() {
    widget.controller.prepareLimitOrder(
      network: _network,
      asset: _assetController.text,
      marketKind: _marketKind,
      sizeDecimals: _sizeDecimalsController.text,
      isBuy: _isBuy,
      limitPrice: _priceController.text,
      size: _sizeController.text,
      reduceOnly: _reduceOnly,
      timeInForce: _timeInForce,
      grouping: _grouping,
      nonce: _nonceController.text,
      clientOrderId: _clientOrderIdController.text,
      vaultAddress: _vaultAddressController.text,
      expiresAfter: _expiresAfterController.text,
    );
  }

  void _finalizeOrder() {
    widget.controller.finalizeOrder(
      signatureR: _signatureRController.text,
      signatureS: _signatureSController.text,
      signatureV: _signatureVController.text,
      expectedSigner: _expectedSignerController.text,
    );
  }
}

final class _PreparedOrderView extends StatelessWidget {
  const _PreparedOrderView({required this.order});

  final HyperAxisPreparedOrder order;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('待签结果', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        _OutputField(label: 'Network', value: order.network.wireName),
        _OutputField(label: 'Nonce', value: order.nonce),
        _OutputField(
          label: 'Vault address',
          value: order.vaultAddress ?? '(null)',
        ),
        _OutputField(
          label: 'Expires after',
          value: order.expiresAfter ?? '(null)',
        ),
        _OutputField(label: 'Signing digest', value: order.signingDigestHex),
        _OutputField(label: 'Action hash', value: order.actionHashHex),
        _OutputField(label: 'Action JSON', value: order.actionJson),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          title: const Text('底层协议产物'),
          children: <Widget>[
            _OutputField(label: 'MessagePack hex', value: order.messagePackHex),
            _OutputField(label: 'Bridge JSON', value: order.bridgeJson),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => _copy(order.signingDigestHex),
            icon: const Icon(Icons.copy),
            label: const Text('复制签名摘要'),
          ),
        ),
      ],
    );
  }
}

final class _FinalizedActionView extends StatelessWidget {
  const _FinalizedActionView({required this.action});

  final HyperAxisFinalizedAction action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('最终请求', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        const Text('这里只生成请求，不会自动发送到交易接口。'),
        const SizedBox(height: 12),
        _OutputField(label: 'Endpoint', value: action.endpoint),
        _OutputField(label: 'Recovered signer', value: action.recoveredSigner),
        _OutputField(label: 'Request JSON', value: action.requestJson),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => _copy(action.requestJson),
            icon: const Icon(Icons.copy),
            label: const Text('复制最终请求'),
          ),
        ),
      ],
    );
  }
}

final class _OutputField extends StatelessWidget {
  const _OutputField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          SelectableText(value),
        ],
      ),
    );
  }
}

Future<void> _copy(String value) {
  return Clipboard.setData(ClipboardData(text: value));
}
