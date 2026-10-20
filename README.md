# HyperAxis Dart

HyperAxis Rust Core 的 Dart/Flutter SDK。该仓库负责稳定的 Dart API、Native bridge 适配、
平台加载、测试和示例，不保存私钥，也不在 Dart 中重复实现签名、哈希和协议编码。

## 当前状态

仓库已完成第一阶段 Native bridge 接入：公共 API 门面、bridge 隔离接口、强类型错误、
日志模型、严格 JSON 解码、FRB 生成代码、测试和 CI。当前 ABI 已覆盖运行时版本、精度
规范化、脱敏日志，以及限价单的准备、外部签名验证和 exchange 请求生成。Flutter 平台仅
支持 Android 与 iOS；Web 由 `hyper-axis-ts` 独立交付。

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

Bridge 固定使用 `flutter_rust_bridge 2.13.0`。开发脚本会按 `tool/core-version.sh` 中的
Git tag 和 commit 从 GitHub 拉取并校验 Rust Core，不依赖本机相邻目录。安装相同版本的
`flutter_rust_bridge_codegen` 后执行：

```bash
./tool/generate_bindings.sh
```

本仓库只交付 Android 与 iOS，不生成 Web 绑定；Web SDK 由 `hyper-axis-ts` 通过 WASM
独立交付。开发态由脚本构建已锁定的 Rust workspace 动态库，并通过 FRB 官方加载目录
变量执行真实桥接验证：

```bash
./tool/run_native_smoke.sh
```

其他 Flutter 工程应通过不可变 tag 依赖本仓库，不要依赖 `master`：

```yaml
dependencies:
  hyper_axis:
    git:
      url: https://github.com/CryptoKango/hyper-axis-dart.git
      ref: v0.1.0
```

宿主工程最低版本为 Android API 24、iOS 13。Flutter 的 Native Assets hook 会自动下载
兼容矩阵指定的 Rust Core 源码归档、校验 SHA256，并按当前 ABI 编译和打包，无需配置本地
`hyper-axis` 路径。首次构建需要网络、`rustup`，Android 还需要 Flutter 配置的 Android
NDK，iOS 需要 Xcode；后续构建复用 Native Assets 缓存。

已验证的打包结果：Android APK 包含 `arm64-v8a`、`armeabi-v7a`、`x86_64` 三套 `.so`；
iOS Simulator framework 同时包含 arm64/x64，iOS Device Release framework 为 arm64。
Native Assets 源码构建是当前可靠基线，Release 预编译产物将作为后续构建加速层，不能绕过
版本和 SHA256 校验。

完整工程规范见 [AGENTS.md](AGENTS.md)。Rust Core 位于
[CryptoKango/hyper-axis](https://github.com/CryptoKango/hyper-axis)。

## 版本策略

Dart SDK 使用 SemVer，并为每个版本记录兼容的 Rust Core 版本和 Native artifact SHA256。
生成器版本必须固定为 `2.13.0`；生成文件不得手工修改。

## License

MIT
