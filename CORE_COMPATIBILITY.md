# Rust Core 兼容矩阵

| Dart SDK | Rust Core | FRB | Bridge ABI | 状态 |
| --- | --- | --- | --- | --- |
| `0.1.0` | `0.1.0` | `2.13.0` | Runtime v0（未冻结） | Native 桥接验证阶段，不用于生产 |

## 规则

- 每次发布必须记录对应的 `hyper-axis` Git tag、commit 和 Native artifact SHA256。
- Dart patch 版本只能兼容相同的 Bridge ABI；ABI 变化至少提升 Dart minor 版本。
- Rust Core 返回的协议版本必须在客户端初始化时校验，不兼容时立即失败。
- 未进入兼容矩阵的 Native artifact 禁止由正式包自动下载或加载。
