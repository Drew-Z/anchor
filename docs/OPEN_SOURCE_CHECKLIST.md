# Anchor Learning (锚学) 开源与 Private Alpha 清单

本文档反映当前仓库事实。开源仓库质量与 Private Alpha 外部验收是两条不同的轨道，不能用文档、fixture 或 Web Demo 代替真实设备、凭据、负责人或参与者证据。

## 已完成的仓库质量项

- README、FAQ、SECURITY、CONTRIBUTING、CHANGELOG、ROADMAP 和开发/用户指南已提交。
- Issue 模板和 PR 模板已存在于 `.github/`。
- Flutter 依赖已升级并完成 `file_picker` 新 API 迁移。
- `flutter analyze --no-fatal-infos`: 0 errors, 0 warnings（仅 info 级 lint）。
- `flutter test`: 387/387 通过。
- `flutter test --coverage`: 本轮功能测试 387/387 通过；覆盖率快照 60.69%（16089/26510）仍为历史记录，不作为 Private Alpha 单独放行条件。
- `dart format --output=none --set-exit-if-changed lib test`: 通过。
- Web 单元测试和 Playwright 测试共 17/17 通过；Web 是独立静态 Demo，不作为原生发布验收。
- Android release 签名改为环境变量注入；缺少签名时只阻止 release task，debug 构建仍可运行。
- 本地备份、恢复、导出、删除、支持包和隐私控制已有实现与测试。

## 当前未完成项

### 仓库内可继续完成

- [x] 为 Agent 启动 checkpoint 失败/重试、页面销毁后的异步返回、详情页完成/失败/恢复、首页与历史页错误恢复和深层导航补充 widget 覆盖。
- [x] 覆盖率已提升到 60.69%（16089/26510）；覆盖率不是 Private Alpha 的单独放行条件。
- [x] 已生成当前 Android Arm64 release APK：`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`（2026-08-26，26272915 bytes），SHA-256 `74DCFB95CD9C123B51D9B35678FFD0153D23654BF6A5597DE1070880D667207B`，包名 `cc.eu.playlab.anchor`，versionName `1.0.0`，Flutter build number `2005` / Arm64 split APK manifest `versionCode=4005`，Anchor Learning release v2 签名，ABI `arm64-v8a`。
- [x] 已将推广、交付、架构、研究和 Trellis 文档统一到正式产品名 `Anchor Learning / 锚学`；正式应用标识单独记录在 `docs/PRODUCT_NAMING.md`。

### 需要真实外部证据的 Private Alpha 门禁

正式 cohort 及其最终决策尚未完成，因此当前必须保持 HOLD；物理设备、正式 APK 模型、凭据治理和运营负责人门禁已完成：

- [x] Arm64 Android 物理设备安装、冷启动和日志验收（最终 release `2005` APK，OnePlus PGP110，API 35，`74dcfb95…d667207b`，日志错误匹配 0）。
- [x] participant-owned release 凭据治理已建立，包含配额、撤销、保留和数据处理声明；仓库只记录 opaque `CRED-PRIMARY-2005` 引用。
- [x] 数据处理负责人及运营角色已明确；仓库只记录 opaque `OPS-ALPHA-2005` 引用，实际记录保存在受限访问的仓库外目录。
- [x] `1.0.0+2005` 正式 release-day 模型验收（Chat / `grok-4.6`，固定五项 `5/5`，117.3 秒，8325 tokens），记录见 `docs/TECHNICAL_MODEL_ACCEPTANCE_2026-08-26_2005.md`，绑定 APK SHA-256 `74dcfb95…d667207b`。
- [ ] 正式 A01-A10 十人 cohort 及其观察窗口和最终决策。

当前本地证据命令（初始化后的匿名工作区证据）：

```powershell
& 'D:\tools\flutter\bin\dart.bat' run tool\private_alpha_readiness.dart `
  --evidence build\validation\private-alpha-readiness.json `
  --format json
```

`test/fixtures/release/private_alpha_readiness_current.json` 仅用于 evaluator
测试，不代表本次设备验收结果。

当前真实结果为 `HOLD`，唯一阻塞码为 `cohort_pending`。正式 release APK 的技术模型验收、participant-owned 凭据治理和数据处理责任已经有相互匹配的匿名证据；A01-A10 正式 cohort 仍必须按 D0/D7/D14 真实执行。

## 非阻塞推广事项

视频、截图、博客、社区发布和项目主页属于推广素材，不是当前 Private Alpha 的技术放行门禁。它们可以在发布准备度允许时单独排期，不能被写成“阻塞构建”或“阻塞代码质量”。

## 构建与验证

```powershell
flutter analyze --no-fatal-infos
flutter test --coverage
dart format --output=none --set-exit-if-changed lib test
npm test
```

Android debug 构建需要可用的 Android/Gradle 依赖缓存或网络。release 构建还需要四项 `ANCHOR_SIGNING_*` 环境变量；实际 PKCS#12 keystore 还可通过 `ANCHOR_SIGNING_STORE_TYPE=PKCS12` 显式指定。不得提交 keystore 或凭据。

## 维护规则

- 文档中的支持平台必须以当前发布清单和真实验收为准；Flutter 框架支持不等于产品发布支持。
- `.env.example` 仅用于说明环境变量命名，不是应用读取模型凭据的入口；模型凭据在应用内 secure storage 保存。
- 历史验收记录可以保留，但必须标注日期、APK 身份和是否仍对应当前提交。

**最后更新**: 2026-08-26
