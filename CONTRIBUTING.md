# 贡献指南

开始修改前请阅读 [AGENTS.md](AGENTS.md)。公共 API、协议字段或 Bridge ABI 变更需要同时说明
对应的 Rust Core 版本和跨语言测试影响。

提交前执行：

```bash
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dart test
cd example
flutter build apk --debug
flutter build ios --simulator --no-codesign
cd ..
```

移动端构建需要 `rustup`。Android 还需要 Flutter 可发现的 Android NDK；iOS 构建只能在
安装 Xcode 的 macOS 上执行。Rust Core 由构建 hook 按兼容矩阵下载和校验，不要配置本地
相对路径或把 Rust 源码复制到本仓库。

提交信息使用 Conventional Commits，例如 `feat: add nonce session api`、
`fix: preserve unsigned nonce string`。
