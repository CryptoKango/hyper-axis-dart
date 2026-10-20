# Rust Core 兼容矩阵

| Dart SDK | Rust Core tag | Rust Core commit | FRB | Bridge ABI | 状态 |
| --- | --- | --- | --- | --- | --- |
| `0.1.0` | `v0.1.0` | `da335740afba6f4d3ed9848efddc622072e04ab6` | `2.13.0` | Runtime v0（未冻结） | Android/iOS Native Assets 构建已验证，ABI 尚未冻结 |

## 规则

- 每次发布必须记录对应的 `hyper-axis` Git tag、commit 和 Native artifact SHA256。
- Dart patch 版本只能兼容相同的 Bridge ABI；ABI 变化至少提升 Dart minor 版本。
- Rust Core 返回的协议版本必须在客户端初始化时校验，不兼容时立即失败。
- 未进入兼容矩阵的 Native artifact 禁止由正式包自动下载或加载。
- 开发工具必须同时校验 tag 与完整 commit，禁止只跟随可移动分支。
- v0.1.0 源码归档 SHA256：`4efa2335e46f2e5cba59596244961b8fc8f7a922f599cacaa75b4c3847b51334`。
- v0.1.0 构建端精确锁定 `libc 0.2.189`，用于规避 `libc 0.2.190` 与当前
  `backtrace` 在 iOS 目标上的上游兼容问题；升级 Rust Core 后必须删除该兼容补丁并重新验证。
