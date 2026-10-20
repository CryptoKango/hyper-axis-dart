## 0.1.0

- 初始化严格的 Dart/Flutter SDK 工程结构。
- 增加稳定客户端门面和 Rust bridge 隔离接口。
- 增加强类型错误与安全日志模型。
- 固定并接入 Flutter Rust Bridge 2.13.0，生成代码与 Rust ABI 隔离。
- 增加 Native bridge 幂等初始化与 Rust 协议版本兼容校验。
- 增加限价单准备、外部签名验证与 exchange 请求生成的强类型 API。
- 增加严格 JSON 解码、跨语言整数精度保护与真实动态库冒烟测试。
- 增加 Android/iOS Native Assets 源码构建，Rust Core 通过 tag、commit 与 SHA256 三重锁定。
- Android 支持 API 24+ 的 arm64-v8a、armeabi-v7a、x86_64；iOS 支持 13+ 的
  device arm64 与 simulator arm64/x64。
- 开发态 Rust Core 自动从 GitHub 缓存，不再依赖本机相邻仓库路径。
- 增加格式化、静态分析、测试和 CI 门禁。
