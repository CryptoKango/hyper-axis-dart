# Rust Core 兼容矩阵

| Dart SDK | Rust Core tag | Rust Core commit | FRB | Bridge ABI | 状态 |
| --- | --- | --- | --- | --- | --- |
| `0.1.0` | `v0.1.0` | `da335740afba6f4d3ed9848efddc622072e04ab6` | `2.13.0` | Runtime v0（未冻结） | Android/iOS Native Assets 构建已验证，ABI 尚未冻结 |
| `0.3.0` | `v0.3.0` | `d273ded3b69c6c3eb61fb396a2a265a16ff0dfc4` | `2.13.0` | Runtime + Orders + Accounts v0（未冻结） | Android/iOS Native Assets，账户查询、订阅与划转桥接已验证 |

## 规则

- 每次发布必须记录对应的 `hyper-axis` Git tag、commit 和 Native artifact SHA256。
- Dart patch 版本只能兼容相同的 Bridge ABI；ABI 变化至少提升 Dart minor 版本。
- Rust Core 返回的协议版本必须在客户端初始化时校验，不兼容时立即失败。
- 未进入兼容矩阵的 Native artifact 禁止由正式包自动下载或加载。
- 开发工具必须同时校验 tag 与完整 commit，禁止只跟随可移动分支。
- v0.1.0 源码归档 SHA256：`4efa2335e46f2e5cba59596244961b8fc8f7a922f599cacaa75b4c3847b51334`。
- v0.3.0 源码归档 SHA256：`031962cf60e3f7b37160742a1177cc5b259d8a2657d33a86a9f1a9f2497b162b`。
- v0.1.0 构建端曾应用 `libc 0.2.189` 兼容补丁；v0.3.0 的 Cargo.lock 已原生锁定兼容版本，
  Native Assets hook 不再修改上游锁文件。
