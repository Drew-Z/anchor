# Anchor Learning 当前交付状态

> 更新于 2026-08-28

## 已具备

- Flutter 本地优先学习应用，覆盖来源导入、知识提取、题目生成、引用校验、答案核验、学习会话和隐私工具。
- Android Private Alpha 的发布检查、测试与运维证据；其他平台不应描述为已经正式支持。
- 公开仓库 `https://github.com/Drew-Z/anchor` 和 MIT 许可证。
- 中英文产品官网与纯前端交互 Demo。
- Demo 提供 Flutter、Git、JavaScript 三套内置数据，共 12 道单选、多选和判断题。
- 每道 Demo 题包含答案解释、稳定 locator、来源摘录和明确标注的预置导师提示。
- Cloudflare Pages 发布目录统一为 `web/landing`，官网与 `/app/` 随同一次静态部署发布。
- 当前工作区 Flutter 全量测试为 `386/386`；静态分析已通过（0 errors、0 warnings，保留既有 info lints）。
- Web Demo 当前为 `20/20` 通过（5 个 Node 单元测试、15 个 Chromium Playwright 用例）。

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
`build/app/outputs/bundle/release/app-release.aab`（63,896,933 bytes），SHA-256
`258d104c9f1c81cad4d950a997589185fe3b9706552a298c120643a32cf7e85b`；Arm64 APK
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`（26,272,915 bytes），SHA-256
`74dcfb95cd9c123b51d9b35678ffd0153d23654bf6a5597de1070880d667207b`。包名
`cc.eu.playlab.anchor`，versionName `1.0.0`，Flutter build number `2005` / Arm64 split APK
manifest `versionCode=4005`，Anchor Learning release 证书 v2 签名，已完成 OnePlus PGP110
真实设备安装、冷启动、进程存活和日志验收。

## 后续工作

- 按 `docs/PRODUCTIZATION_RELEASE_PLAN.md` 准备正式签名、分发、法律和人工验收材料。
- 当前 PR #1 尚未推送本地新增提交、合并或部署；这些外部动作需要明确授权。
- 当前发布支持范围仍限于通过验收的 Android Arm64 Private Alpha；Web 仅为独立静态 Demo。
- 在具备真实跨平台兼容证据后，再扩大 iOS、Windows、macOS 或 Linux 的支持声明。
- Private Alpha 从当前正式标识开始分发；数据迁移仅指当前 schema 升级和用户主动执行的 SQLite 备份/恢复，不承诺旧产品安装兼容。
