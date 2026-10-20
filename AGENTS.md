# AGENTS.md

本文档是 `hyper-axis-dart` 的工程约定。所有开发者和自动化 Agent 修改代码前必须遵守。

## 1. 仓库职责

- 提供 HyperAxis 的 Dart/Flutter 公共 SDK、Rust bridge 适配、平台加载、测试和示例。
- 不复制 Rust 业务源码；Rust Core 与 Native/WASM 构建均由 `CryptoKango/hyper-axis` 维护。
- 私钥、助记词和签名实现属于宿主钱包，不进入本 SDK。

## 2. 目录和依赖方向

```text
lib/hyper_axis.dart          # 唯一公共入口
lib/src/api/                 # 稳定门面
lib/src/models/              # 不可变公共模型
lib/src/error/               # 稳定错误模型
lib/src/logging/             # 安全日志模型
lib/src/bridge/              # 生成代码隔离层
lib/src/generated/           # 自动生成，禁止手改
lib/src/platform/            # 平台加载与 Native Assets
test/                        # 单元、协议和回归测试
example/                     # 最小集成示例
```

依赖只能从 `api` 指向 `models/error/logging/bridge`，`bridge` 可以指向 `generated/platform`；
`models`、`error` 不得依赖生成代码或 Flutter UI。

## 3. 公共 API

- 使用方只导入 `package:hyper_axis/hyper_axis.dart`。
- `lib/src/**` 默认内部实现，新增公开类型必须由入口文件显式导出。
- 禁止将 FRB/FFI 生成类型暴露给调用方。
- 公开 API 必须有 DartDoc；破坏性变更必须提升主版本。

## 4. 精度和协议

- 金额、价格、数量、费率、nonce、过期时间跨语言统一使用十进制字符串。
- 禁止用 `double`、`num` 或 JavaScript `Number` 承载协议精度和 64 位整数。
- JSON 字段、大小写、空值和数组顺序必须与 Rust wire model 一致。
- 协议行为以 `hyper-axis` 的跨语言测试向量为准，Dart 不重复实现签名或哈希算法。

## 5. FFI 和生命周期

- Native 调用只能经 `HyperAxisBridge` 和 `HyperAxisClient`，业务层禁止直接打开动态库。
- 生成文件只由固定版本生成器更新，不得手工编辑。
- FRB runtime 与 codegen 固定为 `2.13.0`；升级必须同步修改 Rust crate、Dart 包、生成脚本与兼容矩阵。
- Web 不由本仓库交付，`flutter_rust_bridge.yaml` 必须保持 `web: false`。
- 平台范围仅限 Android API 24+ 与 iOS 13+；示例、CI 和发布产物不得声明其他平台支持。
- Native Assets 只能获取兼容矩阵中固定 tag/commit 的 Rust Core，下载内容必须校验仓库内
  固定的 SHA256；禁止跟随 `master`、跳过 `--locked` 或静默回退到未校验产物。
- 初始化必须幂等；Bridge 失败统一转为 `HyperAxisException`。
- NonceManager 按 master account 或 API wallet 隔离，禁止进程级全局 signer/nonce。

## 6. 安全与日志

- 禁止记录助记词、私钥、签名、地址、nonce、价格、数量和完整请求/响应体。
- 日志默认关闭，仅允许 Rust Core 已脱敏的结构化记录。
- 错误的 `details` 只能保存非敏感上下文。

## 7. 代码质量

- 使用 Dart 3 strict casts/inference/raw types，禁止 `dynamic` 扩散。
- 执行 `dart format .`，遵循 `analysis_options.yaml`，不得新增 analyzer warning。
- 文件单一职责，优先不可变对象和 `final class`。
- 不捕获后静默忽略异常；公共边界统一输出类型化错误。
- 生成代码可排除 lint，手写代码禁止通过大范围 `ignore_for_file` 规避规则。

## 8. 测试与提交

- 业务门面、协议 JSON、错误映射、版本兼容、初始化与日志配置必须测试。
- 测试不得依赖真实私钥、真实账户或线上下单。
- 提交前运行：`dart format --output=none --set-exit-if-changed .`、`dart analyze --fatal-infos`、`dart test`。
- 修改桥接 API 后必须运行 `./tool/generate_bindings.sh` 和 `./tool/run_native_smoke.sh`。
- 使用 Conventional Commits；Dart SDK 与 Rust Core 必须维护兼容矩阵和产物 SHA256。
