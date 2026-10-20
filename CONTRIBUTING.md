# 贡献指南

开始修改前请阅读 [AGENTS.md](AGENTS.md)。公共 API、协议字段或 Bridge ABI 变更需要同时说明
对应的 Rust Core 版本和跨语言测试影响。

提交前执行：

```bash
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dart test
```

提交信息使用 Conventional Commits，例如 `feat: add nonce session api`、
`fix: preserve unsigned nonce string`。
