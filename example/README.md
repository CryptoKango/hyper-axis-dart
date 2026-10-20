# HyperAxis Flutter 移动端示例

该示例展示 `hyper_axis` 在 Android 与 iOS 中的基础集成流程：

1. 初始化 Dart SDK 与 Rust Native Core，并校验协议版本；
2. 使用 Rust 规范化十进制字符串；
3. 动态开启、关闭和读取脱敏日志；
4. 连接 Hyperliquid Testnet WebSocket 并订阅公开 `allMids` 行情；
5. 在 testnet 参数下生成限价单的 action、hash 与 EIP-712 签名摘要。

示例通过 GitHub `master` 分支依赖 `hyper_axis`，不依赖当前仓库的本地相对路径。

示例不会读取或保存私钥，不实现签名，也不会向 Hyperliquid 发送订单。生产应用应把
`signingDigestHex` 交给自己的安全签名模块，再将可恢复签名传入
`HyperAxisClient.finalizeOrder`。网络提交、重试、幂等与回执校验同样由宿主应用负责。

## 运行

先在仓库根目录安装依赖：

```bash
flutter pub get
```

然后连接 Android API 24+ 或 iOS 13+ 设备/模拟器：

```bash
cd example
flutter run
```

首次构建会按仓库锁定信息获取并校验 `hyper-axis` Rust Core 源码，然后为目标平台编译
Native Assets，因此需要可访问 GitHub 与 Rust crates.io。

## 参数说明

- 示例默认选择 `testnet`，但“生成待签数据”仍不会发起网络请求。
- WebSocket 每 30 秒发送协议 ping，异常断线采用指数退避重连，并自动恢复现有订阅。
- WebSocket 示例只订阅公开行情，不传输用户地址、签名或账户数据。
- `asset ID` 与 `szDecimals` 必须从 Hyperliquid 最新市场元数据中读取，不能在生产代码中硬编码。
- 金额、价格、数量、nonce 全部使用字符串跨越 Dart/Rust 边界，禁止先转换为 `double`。
- 日志默认关闭；SDK 日志已经脱敏，但宿主应用仍不应记录签名、地址、nonce、价格、数量或完整请求体。

## Dart API 完整流程

应用只导入统一入口：

```dart
import 'package:hyper_axis/hyper_axis.dart';
```

初始化与协议版本校验：

```dart
final HyperAxisClient client = await HyperAxisClient.initialize();
final String rustProtocolVersion = client.protocolVersion;
```

精度规范化与日志控制：

```dart
final String normalized = client.normalizeDecimal('00123.4500');

client.configureLogging(
  HyperAxisLoggingConfig(
    enabled: true,
    level: HyperAxisLogLevel.info,
    capacity: 100,
  ),
);

final HyperAxisLogBatch snapshot = client.snapshotLogs();
final HyperAxisLogBatch drained = client.drainLogs();
client.clearLogs();
```

构造包含全部可选字段的限价单：

```dart
final HyperAxisLimitOrderRequest request = HyperAxisLimitOrderRequest(
  network: HyperAxisNetwork.testnet,
  asset: 0,
  marketKind: HyperAxisMarketKind.perpetual,
  sizeDecimals: 5,
  isBuy: true,
  limitPrice: '100.0',
  size: '0.001',
  reduceOnly: false,
  timeInForce: HyperAxisTimeInForce.gtc,
  clientOrderId: null,
  grouping: HyperAxisOrderGrouping.none,
  nonce: DateTime.now().millisecondsSinceEpoch.toString(),
  vaultAddress: null,
  expiresAfter: null,
);

final HyperAxisPreparedOrder prepared = client.prepareLimitOrder(request);
final String digestToSign = prepared.signingDigestHex;
```

`digestToSign` 必须交给宿主钱包安全签名。钱包返回可恢复签名后，再让 Rust 验签并生成最终请求：

```dart
final HyperAxisSignature signature = HyperAxisSignature(
  r: externalSignatureR,
  s: externalSignatureS,
  v: externalSignatureV,
);

final HyperAxisFinalizedAction finalized = client.finalizeOrder(
  prepared: prepared,
  signature: signature,
  expectedSigner: expectedSignerAddress,
);

final String endpoint = finalized.endpoint;
final String requestJson = finalized.requestJson;
final String recoveredSigner = finalized.recoveredSigner;
```

SDK 不会自动发送 `requestJson`。宿主应用应在独立网络层处理提交、超时、重试、幂等与响应校验。
错误统一通过类型化异常处理：

```dart
try {
  client.prepareLimitOrder(request);
} on HyperAxisException catch (error) {
  // error.code / error.message / error.details
}
```
