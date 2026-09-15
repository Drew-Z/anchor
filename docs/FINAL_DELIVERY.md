# Anchor Learning 当前交付状态

> 更新于 2026-09-15

## 已具备

- Flutter 本地优先学习应用，覆盖来源导入、知识提取、题目生成、引用校验、答案核验、学习会话和隐私工具。
- Android Private Alpha 的发布检查、测试与运维证据；其他平台不应描述为已经正式支持。
- 公开仓库 `https://github.com/Drew-Z/anchor` 和 MIT 许可证。
- 中英文产品官网与纯前端交互 Demo。
- Demo 提供 Flutter、Git、JavaScript 三套内置数据，共 12 道单选、多选和判断题。
- 每道 Demo 题包含答案解释、稳定 locator、来源摘录和明确标注的预置导师提示。
- Cloudflare Pages 发布目录统一为 `web/landing`，官网与 `/app/` 随同一次静态部署发布。
- 当前 Flutter 全量测试为 `654/654`；静态分析与 CI 格式检查均已通过。
- Web Demo 当前为 `75` 个 Node 单元测试与 `93` 个 Chromium Playwright 用例通过。

## 交付边界

- Web Demo 是产品流程样例，不是完整 Flutter Web 版本。
- Demo 不支持上传用户文档，不调用真实 AI，不提供登录、云同步或分析服务。
- Flutter 应用已在正式产品化候选中使用最终 applicationId、数据库名和 macOS bundle ID；Secure Storage 仅使用当前 profile 命名空间。
- `.env.example` 仅说明配置边界；模型凭据必须在应用“设置 → AI 配置”中保存。
- 官网不再展示缺少可复现实验依据的幻觉率、代码量或文档字数。

## 发布前门禁

```bash
cd web
npm ci
npm test
git diff --check
```

Flutter 客户端发布仍按 `docs/private-alpha-release-checklist.md` 执行，不能用 Web Demo 验收代替原生应用测试。

当前正式 release 产物为：
`build/app/outputs/bundle/release/app-release.aab`（64,161,423 bytes），SHA-256
`d95e5b4209ece0251ddd7326b2508de8703c51d85ff3aa46cefa380cd60b62c7`；Arm64 APK
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`（26,404,187 bytes），SHA-256
`3371870ee2691f0aa3496e2e6fb1153a6c028b840bfef33c924dbea8cf96d475`。包名
`cc.eu.playlab.anchor`，versionName `1.0.0`，Flutter build number `2005` / Arm64 split APK
manifest `versionCode=4005`，Anchor Learning release 证书 v2 签名，已完成 OnePlus PGP110
真实设备安装、冷启动、进程存活和日志验收。

## 后续工作

- 按 `docs/PRODUCTIZATION_RELEASE_PLAN.md` 准备正式签名、分发、法律和人工验收材料。
- 分支 `codex/anchor-web-demo` 已推送，PR #1 已于 2026-09-15 合并到 `main`，合并提交为 `94a306a`。
- `web/landing` 已部署到 Cloudflare Pages 生产环境 `https://anchor.playlab.eu.cc/`，官网、`/app/` 与重定向 smoke check 均通过。
- 本地 Web 套件已通过 `75` 个 Node 测试与 `93` 个 Playwright 测试；生产浏览器套件允许 Cloudflare Web Analytics 性能脚本，并拒绝其他站外请求。
- APK 已作为 `v1.0.0` Private Alpha GitHub Release 公开发布；尚未邀请真实用户。
- 当前发布支持范围仍限于通过验收的 Android Arm64 Private Alpha；Web 仅为独立静态 Demo。
- 在具备真实跨平台兼容证据后，再扩大 iOS、Windows、macOS 或 Linux 的支持声明。
- Private Alpha 从当前正式标识开始分发；数据迁移仅指当前 schema 升级和用户主动执行的 SQLite 备份/恢复，不承诺旧产品安装兼容。
