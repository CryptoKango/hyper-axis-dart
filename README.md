# HyperAxis Dart

HyperAxis Rust Core 的 Dart/Flutter SDK。该仓库负责稳定的 Dart API、Native bridge 适配、
平台加载、测试和示例，不保存私钥，也不在 Dart 中重复实现签名、哈希和协议编码。

## 当前状态

仓库已完成第一阶段 Native bridge 接入：公共 API 门面、bridge 隔离接口、强类型错误、
日志模型、严格 JSON 解码、FRB 生成代码、测试和 CI。当前 ABI 已覆盖运行时版本、精度
规范化、脱敏日志，以及限价单的准备、外部签名验证和 exchange 请求生成；其余交易 API
与各平台 Native artifact 发布流水线仍在建设中，因此当前版本不用于生产环境。

## 架构

```text
App
 └─ HyperAxisClient
     └─ HyperAxisBridge
         └─ 生成的 Rust bridge adapter
             └─ hyper-axis-ffi / hyper-axis-core
```

- 调用方只导入 `package:hyper_axis/hyper_axis.dart`。
- 金额、价格、数量、费率、nonce 和时间戳在跨语言边界均使用十进制字符串。
- SDK 不接触私钥；签名由 App、硬件钱包或系统安全模块完成。
- 日志默认关闭，并且只接收 Rust Core 已脱敏的结构化记录。

## 开发

```bash
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dart test
```

Bridge 固定使用 `flutter_rust_bridge 2.13.0`。Rust 与 Dart 仓库需位于同一父目录，安装
相同版本的 `flutter_rust_bridge_codegen` 后执行：

```bash
./tool/generate_bindings.sh
```

本仓库只生成 iOS、macOS、Android、Windows 和 Linux 的 Native 绑定，不生成 Web 绑定；
Web SDK 由 `hyper-axis-ts` 通过 WASM 独立交付。开发态由脚本构建 Rust workspace 动态库，
并通过 FRB 官方加载目录变量执行真实桥接验证：

```bash
./tool/run_native_smoke.sh
```

完整工程规范见 [AGENTS.md](AGENTS.md)。Rust Core 位于
[CryptoKango/hyper-axis](https://github.com/CryptoKango/hyper-axis)。

## 版本策略

Dart SDK 使用 SemVer，并为每个版本记录兼容的 Rust Core 版本和 Native artifact SHA256。
生成器版本必须固定为 `2.13.0`；生成文件不得手工修改。

## License

MIT
