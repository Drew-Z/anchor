# Anchor Learning 品牌与仓库状态

## 正式产品身份

- 产品名称：`Anchor Learning`（锚学）
- 英文简称：`Anchor`
- Tagline：`Anchor your knowledge, trace every insight`
- Android applicationId：`cc.eu.playlab.anchor`
- SQLite 数据库：`anchor_learning.db`
- macOS bundle identifier：`cc.eu.playlab.anchor`

这些标识在外部用户分发前已完成产品化。项目不为此前未发布的开发构建保留旧名称、旧包名、旧数据库名或 Secure Storage 迁移兼容层。

## 公开入口

- 仓库：https://github.com/Drew-Z/anchor
- 展示页：https://anchor.playlab.eu.cc
- 浏览器 Demo：https://anchor.playlab.eu.cc/app/

GitHub 仓库描述、主页地址和 Topics 已完成配置。当前产品化变更位于 Draft PR [#1](https://github.com/Drew-Z/anchor/pull/1)；合并和生产部署仍需明确授权，且不代表 Private Alpha 已可发布。

## 当前发布边界

- 当前候选：`1.0.0+2005`
- 原生发布范围：Android Arm64 Private Alpha
- Web：独立静态演示，不调用真实模型服务，也不是 Flutter 原生应用的替代品
- readiness：`HOLD`，等待真实 A01-A10 cohort、最终发布窗口的模型复验和真机复验

发布门禁和操作顺序以 `docs/PRODUCTIZATION_RELEASE_PLAN.md`、`docs/private-alpha-release-checklist.md` 和 `docs/PRIVATE_ALPHA_EXTERNAL_EVIDENCE_HANDOFF.md` 为准。

## 品牌使用规则

- 新增产品文案、文档、导出文件和支持材料使用 `Anchor Learning`、`锚学` 或 `anchor-learning` 前缀。
- 不重新引入原工作名称、旧包名、旧数据库名或旧安全存储命名空间。
- 已完成迁移的历史技术说明使用当前产品名称描述；当前文档不把旧安装兼容性列为产品承诺。
