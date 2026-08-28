# Anchor Learning 当前开源准备状态

本文档只记录当前事实，不把推广素材或历史提交当作当前发布证据。

## 已完成

- 核心用户、架构、开发和贡献文档已存在。
- Android、Web、隐私数据和 AI profile 测试已纳入自动化验证。
- 当前 Flutter 测试 385/385 通过；覆盖率快照为 60.84%（16274/26751），不是本轮发布门禁。
- Web 测试 17/17 通过。
- Android release 签名门禁已配置为环境变量注入，debug 不依赖 release keystore。

## 当前状态

Private Alpha 仍为 `HOLD`。当前真实 readiness 只剩一项外部证据：

1. A01-A10 正式 cohort、观察窗口和最终决策。

物理设备验收、正式 `2005` release-day 五项技术验收、participant-owned 凭据治理和数据处理负责人记录已经完成。正式 cohort 不能用模拟器、fixture、旧 APK 或 Web Demo 替代。

## 构建说明

当前代码和 Gradle 配置已通过分析、测试和正式 release 构建。最新 Arm64 release APK 位于
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`（2026-08-26，26,272,915 bytes），
SHA-256 为 `74dcfb95cd9c123b51d9b35678ffd0153d23654bf6a5597de1070880d667207b`，包名
`cc.eu.playlab.anchor`，versionName `1.0.0`，Flutter build number `2005` / Arm64 split APK
manifest `versionCode=4005`，使用 Anchor Learning release v2 签名，仅包含 `arm64-v8a` ABI。
该 APK 已完成 OnePlus PGP110 物理设备安装、冷启动、进程存活、日志验收，以及 Chat / `grok-4.6` 的正式 release-day `5/5` 技术验收。脱敏报告见 `docs/TECHNICAL_MODEL_ACCEPTANCE_2026-08-26_2005.md`；治理记录使用 opaque `CRED-PRIMARY-2005` 和 `OPS-ALPHA-2005` 引用，仍不替代 cohort 证据。

## 推广素材

Demo 视频、截图、博客和社区发布是非阻塞推广事项。它们可以提高使用和传播效果，但不改变 readiness 状态，也不能替代设备、凭据、负责人或 cohort 门禁。

## 下一步

- 按 `docs/PRIVATE_ALPHA_EXTERNAL_EVIDENCE_HANDOFF.md` 执行 A01-A10 正式 cohort；该文件只是交接清单，不是参与者证据本身。
- 在真实外部条件满足后，只更新 `build/validation/private-alpha-readiness.json` 中的匿名绑定，再运行 readiness CLI；`test/fixtures/release/private_alpha_readiness_current.json` 仅用于测试。
- 继续维护发布文档中的构建身份、APK SHA-256、支持平台和凭据处理声明；产品文档统一使用 `Anchor Learning / 锚学`，正式应用标识见 `docs/PRODUCT_NAMING.md`。

**最后更新**: 2026-08-26
