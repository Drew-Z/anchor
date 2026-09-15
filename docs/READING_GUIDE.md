# 阅读指南

> 根据你的目标选择最合适的阅读路径

---

## 30 分钟速览

**适合**: 想快速了解项目核心价值

1. [README.md](../README.md) - 项目简介和核心亮点
2. [快速开始](guides/QUICK_START.md) - 5 分钟运行起来
3. [系统概览](architecture/SYSTEM_OVERVIEW.md) - 防幻觉架构图

**预期收获**: 理解项目做什么,如何防止 AI 幻觉,能跑起来体验

---

## 贡献者路径

**适合**: 想参与开发或提交 PR

1. [贡献指南](../CONTRIBUTING.md) - 开发流程和代码规范
2. [数据模型](architecture/DATA_MODEL.md) - 数据库表结构
3. [AI Pipeline](architecture/AI_PIPELINE.md) - AI 任务流程
4. [自定义 Prompts](guides/CUSTOMIZE_PROMPTS.md) - 修改 AI 行为

**预期收获**: 理解代码组织,能找到要修改的文件,知道如何提 PR

---

## 研究者路径

**适合**: 研究防幻觉技术方案或构建类似产品

1. [系统概览](architecture/SYSTEM_OVERVIEW.md) - 三层防线架构
2. [AI Pipeline](architecture/AI_PIPELINE.md) - Citation Verification 实现
3. 源码阅读:
   - `lib/services/content_analyzer.dart` - 语义切分
   - `lib/services/ai/tasks/citation_verification_task.dart` - 引用核验
   - `lib/services/ai/tasks/question_validator_task.dart` - 事实验证

**预期收获**: 理解防幻觉的完整技术方案,可复现到自己项目

---

## 用户路径

**适合**: 只想用这个 APP 学习

1. [快速开始](guides/QUICK_START.md) - 安装和配置
2. [导入文档](guides/IMPORT_YOUR_DOCS.md) - 最佳实践
3. 直接使用 APP,遇到问题查文档或提 Issue

---

## 特定主题

### 我想理解间隔重复算法的实现
→ 阅读 `lib/services/review_scheduler_service.dart` + [数据模型](architecture/DATA_MODEL.md) 中的 `Question` 表字段说明

### 我想知道如何集成本地 LLM
→ 查看 [开发路线图](../ROADMAP.md) 中的"本地 LLM 支持"计划；当前支持用户配置的 OpenAI-compatible 端点，本地或自托管模型需提供兼容接口并通过应用内验收

### 我想修改题目生成风格
→ [自定义 Prompts](guides/CUSTOMIZE_PROMPTS.md)

### 我想理解 Agent 辅导的实现
→ 阅读 `lib/features/agent/` 目录 + [AI Pipeline](architecture/AI_PIPELINE.md) 的 Agent 章节

---

## 文档结构总览

```
docs/
├── READING_GUIDE.md (本文件)
├── guides/              用户指南
│   ├── QUICK_START.md
│   ├── IMPORT_YOUR_DOCS.md
│   └── CUSTOMIZE_PROMPTS.md
└── architecture/        架构文档
    ├── SYSTEM_OVERVIEW.md
    ├── DATA_MODEL.md
    └── AI_PIPELINE.md

根目录/
├── README.md           项目首页
├── CONTRIBUTING.md     贡献指南
├── ROADMAP.md          开发计划
├── CHANGELOG.md        版本历史
└── LICENSE             MIT 许可
```

---

## 推荐阅读顺序

### 第一次接触项目?
**README.md** → **快速开始** → 试用 APP

### 想深入理解技术?
**系统概览** → **AI Pipeline** → **数据模型** → 源码

### 想提交代码?
**快速开始**(先跑起来) → **贡献指南** → **数据模型** → 找到相关源码

---

## 文档维护

文档与代码不一致? 请:
1. 提 Issue 说明具体不一致的地方
2. 以**代码为准** - 代码是事实来源

文档缺失或不清楚? 欢迎:
1. 提 Issue 说明需要补充的内容
2. 直接提 PR 改进文档
