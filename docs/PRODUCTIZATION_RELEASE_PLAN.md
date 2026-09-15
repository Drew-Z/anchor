# Anchor Learning 产品化发布候选计划

更新于 2026-09-15。本文件把 Private Alpha 技术发布前仍需完成的工作收敛在一个地方；它不是对外发布承诺，也不替代 readiness evaluator。

当前技术门禁暂不能绑定到最新候选：readiness 文件中的设备和模型证据仍绑定旧 APK `641a1a10…fafa29c54b3`，而当前重建候选是 `3371870e…cf96d475`。evaluator 当前返回 `HOLD`，阻塞码为 `android_build_bytes_mismatch` 和 `android_build_sha256_mismatch`。正式 cohort 不再是技术 release gate；研究记录仍可单独开展。

## 当前候选版本

- 产品名：`Anchor Learning` / `锚学`
- 候选版本：`1.0.0+2005`（Flutter build number `2005`；Arm64 split APK manifest `versionCode=4005`）
- 当前发布范围：通过验收的 Android Arm64 Private Alpha；Web 是独立静态 Demo
- 当前 AAB：`build/app/outputs/bundle/release/app-release.aab`；64,161,423 bytes；SHA-256 `d95e5b4209ece0251ddd7326b2508de8703c51d85ff3aa46cefa380cd60b62c7`
- 当前 Arm64 APK：`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`；26,404,187 bytes；SHA-256 `3371870ee2691f0aa3496e2e6fb1153a6c028b840bfef33c924dbea8cf96d475`
- release APK 由 Flutter 3.44.6 / Dart 3.12.2 生成，APK Signature Scheme v2 已验证，证书 DN 为 `CN=Anchor Learning, OU=Release`，证书 SHA-256 `7efa706af7e897411aac4a240c98be3cc2f672c82c90f55a515d7db30ab9fd35`
- release 产物记录：`build/validation/release-artifacts.json`；构建脚本位于工作区外受控签名目录（不进入仓库）。

## 模型验收节奏

五项模型验收不随每个 debug 或中间候选重复执行。开发阶段只运行本地协议、解析和失败恢复测试；正式验收时，将五项固定任务一次性绑定到最终 release 签名产物、精确模型 profile 和 APK/AAB 哈希，并只保留一份当前有效报告。只有最终产物哈希、模型 profile 或发布配置发生变化，才需要重新生成该报告。

## 应用标识决策

Private Alpha 使用以下正式产品标识：

- Android `applicationId` / namespace：`cc.eu.playlab.anchor`
- SQLite 文件：`anchor_learning.db`
- Android 平台通道：`cc.eu.playlab.anchor/project_directory`
- macOS bundle identifier：`cc.eu.playlab.anchor`

这些是正式产品化标识，不是服务提供商标识。发布前以干净安装、当前 schema 升级、SQLite 备份/恢复和完整性校验作为门禁；不承诺此前未发布开发构建的安装兼容。

## 正式签名与产物

release 构建会在缺少签名材料时主动失败。签名材料只通过受控环境变量注入，不进入仓库：

```powershell
$env:ANCHOR_SIGNING_STORE_FILE = '<controlled-signing-directory>\anchor-release.p12'
$env:ANCHOR_SIGNING_STORE_TYPE = 'PKCS12'
$env:ANCHOR_SIGNING_STORE_PASSWORD = '<controlled-secret>'
$env:ANCHOR_SIGNING_KEY_ALIAS = 'anchor-release'
$env:ANCHOR_SIGNING_KEY_PASSWORD = '<controlled-secret>'

& flutter.bat build appbundle --release
& flutter.bat build apk --release --split-per-abi
```

每个候选产物都记录：版本号、字节数、SHA-256、APK/AAB 签名验证结果、Flutter/Dart/Gradle/compileSdk/targetSdk、ABI、构建时间、构建机和回滚到上一个已验收产物的路径。签名密码、API key、设备数据库和 DocumentsUI 临时文件不得进入 Git 或支持包。

## 对外材料清单

在邀请真实用户前，运营负责人必须补齐并审阅：

- 隐私政策：说明本地数据库、模型请求、凭据保存、导出/备份/恢复/删除边界，以及用户联系方式。
- 用户协议：说明 Private Alpha 性质、内容责任、模型输出限制、可用性和反馈授权范围。
- 数据删除说明：以“设置 → 本地数据与隐私”为唯一操作入口，列出五种删除范围和备份后删除行为。
- 商店资料：名称 `Anchor Learning`、图标、截图、支持范围、已知限制和支持邮箱。
- Alpha 运营包：邀请、同意、D0/D7/D14 记录、问题分级、崩溃/ANR 处理、升级和回滚联系人。

法律文本在发布前由责任人按目标地区审阅；仓库内只保留经审阅的版本和变更记录，不把占位联系人当成已完成证据。

## 统一真机验收顺序

旧 `2005` release 候选已在 OnePlus PGP110（Arm64，API 35）完成设备级门禁；该验收使用 APK 哈希
`641a1a10…fafa29c54b3`。当前候选哈希已变化，现有设备和模型证据不能直接复用；凭据治理和
数据处理负责人记录仍可通过匿名引用保留，cohort 仅作为可选研究记录。

1. `adb devices -l` 和 `tool/private_alpha_device_preflight.dart` 只读预检，确认真实 Arm64、API 24-35、包名和 SHA-256。
2. 同参数加 `--execute`，完成覆盖安装、冷启动、进程存活和 PID 过滤日志检查。
3. 在 App 内完成导入/来源追溯、Agent 成功/失败/重试/恢复、备份/恢复/数据删除和反馈导出；正式 release-day 模型五项验收已绑定当前 APK，后续只有 APK、模型 profile 或发布配置变化时才重跑。
4. 清理设备临时文件，恢复安装前数据库并核对 SHA-256、schema 23、`integrity_check=ok`。
5. 将不含密钥、回答、源码和私有路径的最新报告写入受控证据位置，再运行 readiness evaluator；在最新 APK 完成设备和模型重验前，当前报告保持 `HOLD`。模型、设备配置或 APK 变化时必须重新验收。

正式 cohort、D0/D7/D14 观察窗口属于可选研究，不影响技术 readiness；不得用合成记录冒充真实参与者证据。
