# 下一步行动计划

本文档保留早期开源准备阶段的执行草案。早期清单仅作历史参考，当前发布状态以
[OPEN_SOURCE_CHECKLIST.md](OPEN_SOURCE_CHECKLIST.md) 和
[OPEN_SOURCE_READY.md](OPEN_SOURCE_READY.md) 为准。

> 更新于 2026-08-28：仓库质量门禁已完成；Private Alpha 仍因真实外部证据不足保持 `HOLD`。
> `.env.example` 只说明配置边界，应用凭据必须在“设置 → AI 配置”中保存。

## 当前有效队列

以下事项取代本文档后面的早期时间估算和草案任务：

1. 在获得明确授权后推送 `codex/anchor-web-demo`，同步 PR #1 的验证数量和最新 CI 记录。
2. 在获得明确授权后合并 PR，并将 `web/landing` 部署到
   `https://anchor.playlab.eu.cc/`，随后执行官网和 `/app/` smoke check。
3. 临近发布窗口，用同一 `1.0.0+2005` 签名候选重新完成真机与模型五项验收。
4. 执行 A01-A10 正式 cohort 及 D0/D7/D14 观察，形成匿名外部证据并运行 readiness evaluator。
5. 只有 evaluator 返回 `GO` 后，才进入 Private Alpha 分发；Claude Code 通道在恢复
   Anthropic-compatible 网关前不作为已完成的协作开发证据。

后文的“历史待办事项”不再是当前执行队列。

---

## 🎯 本周目标(预计 12 小时)

完成开源准备的基础工作,为 2-3 周后的首次发布做准备。

---

## ✅ 已完成

### 文档体系建设(6 小时)
- [x] 创建文档目录结构 `docs/{architecture,guides,api}/`
- [x] 撰写核心架构文档
  - [x] SYSTEM_OVERVIEW.md - 四大核心流程
  - [x] DATA_MODEL.md - ER 图和表设计
  - [x] AI_PIPELINE.md - AI Tasks 详解
- [x] 撰写使用指南
  - [x] QUICK_START.md - 5 分钟上手
  - [x] IMPORT_YOUR_DOCS.md - 导入最佳实践
  - [x] CUSTOMIZE_PROMPTS.md - Prompt 定制
- [x] 开发者文档
  - [x] CONTRIBUTING.md - 贡献指南
  - [x] ROADMAP.md - 开发路线图
  - [x] CHANGELOG.md - 更新日志
- [x] 项目根文件
  - [x] README.md - 完整改写
  - [x] LICENSE - MIT 许可
  - [x] .env.example - 配置边界说明（不是应用配置入口）

### 代码改进(4 小时)
- [x] 实现 SemanticChunker 服务
- [x] 实现 QuestionValidator 服务
- [x] 集成到导入流程

---

## 📋 历史待办事项(不代表当前阻塞)

以下清单来自早期开源准备阶段。Git 提交整理、Demo 录制、截图和推广素材均不构成
Private Alpha 的技术放行条件；当前真正的阻塞项请查看发布清单。

### 高优先级 - 本周完成

#### 1. Git 提交整理(1 小时)
当前有大量未提交文件,需要分批提交:

```bash
# 第一批: 新增的核心服务
git add lib/services/ingestion/semantic_chunker.dart
git add lib/services/validation/
git commit -m "feat(validation): add semantic chunker and question validator

- SemanticChunker: 语义切分支持 Markdown/代码
- QuestionValidator: 题目质量二次验证
- 置信度评分机制"

# 第二批: 完整文档体系
git add docs/architecture/
git add docs/guides/
git add docs/README.md
git add docs/OPEN_SOURCE_PLAN.md
git commit -m "docs: add complete documentation system

- Architecture: SYSTEM_OVERVIEW, DATA_MODEL, AI_PIPELINE
- Guides: QUICK_START, IMPORT_YOUR_DOCS, CUSTOMIZE_PROMPTS
- Open source strategy and roadmap"

# 第三批: 项目元文件
git add README.md CONTRIBUTING.md ROADMAP.md CHANGELOG.md LICENSE .env.example
git commit -m "docs: prepare for open source release

- Rewrite README with feature highlights
- Add CONTRIBUTING guide
- Add ROADMAP and CHANGELOG
- MIT License
- .env.example configuration boundary, not a runtime credential entry point"

# 第四批: 集成改进
git add lib/features/ingestion/project_import_screen.dart
git add lib/services/ingestion/project_source_import_service.dart
git commit -m "feat(ingestion): integrate semantic chunker and validator

- Use SemanticChunker for all imports
- Add validation step in import flow
- Display confidence warnings in review screen"
```

#### 2. 录制 Demo 视频(1 小时)

**工具**: OBS Studio(免费)

**脚本 1: 30 秒快速体验**
```
1. 打开应用(主页空白状态)
2. 点击 "+" → "导入示例数据"
3. 等待 5 秒加载
4. 主页显示 "10 道待学习题目"
5. 点击 "开始学习" → 答一道单选题
6. 查看解析 → 点击 "查看来源" → 跳转到原文

总时长: 30 秒
输出: demo-quick.gif (用于 README)
```

**脚本 2: 2 分钟完整流程**
```
1. 导入 Markdown 文档(展示文件选择)
2. AI 分析进度条(提取知识点 → 生成题目 → 验证)
3. 进入审核界面(展示题目列表)
4. 点击一道题,查看引用链
5. 答题并查看解析
6. 进入知识库,浏览知识点卡片
7. 打开 AI 助手,问一个问题

总时长: 2 分钟
输出: demo-full.mp4
```

**录制提示**:
- 使用系统默认主题(一致性)
- 鼠标移动要流畅
- 准备好测试数据(避免等待 AI)
- 录制后用 FFmpeg 压缩

#### 3. 补充关键注释(2 小时)

**优先级文件**:

```dart
// lib/services/ingestion/semantic_chunker.dart
/// 语义切分服务,将文档切分为可引用的最小单元。
///
/// 核心设计:
/// - Markdown: 按标题层级切分,保持段落完整性
/// - 代码: 按固定行数切分,保留精确行号
/// - 每个 chunk 生成人类可读的 locator
///
/// 示例 locator:
/// - `README.md:## 快速开始`
/// - `lib/main.dart:15-42`
class SemanticChunker {
  // ... 实现
}

// lib/services/validation/question_validator.dart
/// 题目质量验证服务,防止 AI 生成事实性错误。
///
/// 验证维度:
/// 1. 事实准确性: 答案是否与源文档一致
/// 2. 引用完整性: explanation 是否真的基于 citedChunks
/// 3. 逻辑一致性: 选项设计是否合理
///
/// 返回置信度评分(0.0-1.0):
/// - >= 0.8: verified,直接通过
/// - 0.5-0.8: suspicious,标记警告
/// - < 0.5: invalid,建议删除
class QuestionValidator {
  // ... 实现
}
```

**其他需要注释的文件**:
- `lib/services/ai/tasks/*.dart` - 每个 Task 的 Prompt 设计思路
- `lib/data/repositories/*.dart` - Repository 的职责说明
- `lib/features/*/screen.dart` - 主要界面的功能说明

### 中优先级 - 下周完成

#### 4. 创建示例数据(2 小时)

**目标**: 用户克隆后立即看到效果,无需 API Key

**步骤**:

```bash
# 1. 创建示例 Markdown
mkdir -p assets/examples
cat > assets/examples/flutter_basics.md << 'EOF'
# Flutter 基础

Flutter 是 Google 推出的跨平台 UI 框架...

## Widget 树机制

Widget 是 Flutter 的核心概念...

### StatelessWidget

不可变的 Widget...

### StatefulWidget

可变状态的 Widget...
