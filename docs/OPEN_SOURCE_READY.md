# Anchor Learning 开源与 Private Alpha 证据索引

本文档保留 2026-08-28 整理的仓库与发布证据。最新本地开发结果和任务状态见 [CURRENT_STATE.md](CURRENT_STATE.md)；下列测试数量与签名产物分别保留其原始日期，不随本地开发自动更新。

## 已完成的仓库质量项（2026-08-28 快照）

- 核心用户、架构、开发和贡献文档已存在。
- Android、Web、隐私数据和 AI profile 测试已纳入自动化验证。
- 该快照中的 Flutter 测试 386/386 通过；覆盖率快照为 60.84%（16274/26751），不单独作为发布门禁。
- Web 测试 20/20 通过（5 个 Node 单元测试、15 个 Chromium Playwright 用例）。
- Android release 签名门禁已配置为环境变量注入，debug 不依赖 release keystore。

## 当前状态

Private Alpha 技术 readiness 当前为 `GO`。正式 cohort 已从技术发布门禁中移除，保留为可选研究工作：

1. A01-A10 正式 cohort、观察窗口和最终决策不再是技术 release gate。

当前签名候选的物理设备验收、release-day 主备五项技术验收、participant-owned 凭据治理和数据处理负责人记录已写入 readiness；正式 cohort 不属于技术 release gate，仍不得用模拟器、fixture、旧 APK 或 Web Demo 冒充研究证据。

## 已记录的签名产物（2026-08-26）

以下记录保留历史签名候选快照；当前候选与技术放行状态以 [CURRENT_STATE.md](CURRENT_STATE.md) 和 readiness 文件为准。

当时记录的 Arm64 release APK 路径为
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`（2026-08-26，26,272,915 bytes），
SHA-256 为 `74dcfb95cd9c123b51d9b35678ffd0153d23654bf6a5597de1070880d667207b`，包名
`cc.eu.playlab.anchor`，versionName `1.0.0`，Flutter build number `2005` / Arm64 split APK
manifest `versionCode=4005`，使用 Anchor Learning release v2 签名，仅包含 `arm64-v8a` ABI。
该 APK 已完成 OnePlus PGP110 物理设备安装、冷启动、进程存活、日志验收，以及 Chat / `grok-4.6` 的历史 `5/5` 技术验收。当前技术放行记录见 readiness 文件；治理记录使用 opaque `CRED-PRIMARY-2005`、`CRED-FALLBACK-2005` 和 `OPS-ALPHA-2005` 引用。

## 推广素材

Demo 视频、截图、博客和社区发布是非阻塞推广事项。它们可以提高使用和传播效果，但不改变 readiness 状态，也不能替代设备、凭据、负责人或 cohort 门禁。

## 下一步

- 如需产品研究，按 `docs/PRIVATE_ALPHA_EXTERNAL_EVIDENCE_HANDOFF.md` 执行 A01-A10 正式 cohort；该文件只是交接清单，不是参与者证据本身。
- 在真实外部条件发生变化后，只更新 `build/validation/private-alpha-readiness.json` 中的匿名绑定，再运行 readiness CLI；`test/fixtures/release/private_alpha_readiness_current.json` 仅用于测试。
- 继续维护发布文档中的构建身份、APK SHA-256、支持平台和凭据处理声明；产品文档统一使用 `Anchor Learning / 锚学`，正式应用标识见 `docs/PRODUCT_NAMING.md`。

**最后更新**: 2026-09-09（澄清历史快照与当前开发指针；未重跑发布门禁）
