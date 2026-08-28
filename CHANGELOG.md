# 更新日志

所有值得注意的项目变更都会记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/),
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

---

## [Unreleased]

### 修复
- 修复长耗时模型响应在客户端先超时、但中转服务已完成生成时被误报失败的问题。
- 兼容 OpenAI-compatible 中转层的嵌套响应、SSE 文本片段和 2xx 错误体，并保留可诊断的供应商错误信息。
- 将模型固定验收的默认预算调整到覆盖已观测的 2-3 分钟响应尾部。

### 新增
- 📚 完整的用户指南文档
  - 快速开始指南
  - 文档导入最佳实践
  - AI Prompt 自定义教程
- 📖 贡献指南和开发路线图
- 🌍 项目开源准备(文档/示例/CI)

---

## [0.1.0] - 2026-07-25

### 新增 ✨

#### 核心功能
- 🎯 **智能内容导入**
  - Markdown 文档语义切分
  - 项目代码扫描和分析
  - 保留源文档结构的 Locator 机制

- 🧠 **AI 驱动的内容生成**
  - 知识点自动提取
  - 多种题型生成(单选/填空/判断)
  - 基于原文的答案解析
  - AI 语义判题(填空题同义答案识别)

- 📚 **学习系统**
  - 间隔重复算法(SuperMemo-2)
  - 掌握度追踪
  - 学习进度统计
  - 答题历史记录

- 🤖 **AI Agent 辅导**
  - 知识点问答(附引用链)
  - 苏格拉底式面试引导
  - 长会话恢复
  - 基于知识库的语境感知

- 🔗 **来源溯源机制**
  - 题目追溯到源文档片段
  - 可点击的原文引用
  - Citation Verification 防幻觉
  - Question Validator 事实核验

#### 技术架构
- 💾 SQLite 本地数据库
- 🔌 OpenAI API 集成(支持兼容接口)
- 🎨 Flutter Material Design 3
- ⚡ Riverpod 状态管理
- 🔍 混合检索(BM25 + Semantic Embedding)

#### 平台支持
- ✅ Android Private Alpha 主路径
- ✅ 独立 Web 静态 Demo
- ⏳ iOS、macOS、Windows、Linux 尚未完成发布验收

### 数据模型

#### 核心表结构
```sql
-- 知识点
CREATE TABLE knowledge_points (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  kind TEXT, -- concept/architecture/implementation
  source_id TEXT,
  locator TEXT
);

-- 题目
CREATE TABLE questions (
  id TEXT PRIMARY KEY,
  knowledge_point_id TEXT,
  question_text TEXT NOT NULL,
  question_type TEXT, -- single_choice/fill_blank/true_false
  choices TEXT, -- JSON array
  correct_answer TEXT,
  explanation TEXT,
  source_chunk_id TEXT
);

-- 学习记录
CREATE TABLE study_records (
  id TEXT PRIMARY KEY,
  question_id TEXT,
  user_answer TEXT,
  is_correct INTEGER,
  answered_at INTEGER,
  next_review_at INTEGER
);
```

### 已知限制 ⚠️

- 仅支持 Markdown 和 Dart 代码文件
- PDF/Word 文档需要手动转换
- 单用户模式(无云同步)
- 需要网络连接(OpenAI API)
- 中文界面为主(英文支持有限)

---

## [0.0.1] - 2026-07-01

### 初始版本 🎉

- 基础的 Markdown 导入
- 简单的选择题生成
- 本地存储
- Android 单平台支持

---

## 版本说明

### 版本号规则

给定版本号 `MAJOR.MINOR.PATCH` (主版本号.次版本号.修订号):

- **MAJOR**: 不兼容的 API 修改
- **MINOR**: 向下兼容的功能新增
- **PATCH**: 向下兼容的 Bug 修复

### 变更类型

- **新增 (Added)**: 新功能
- **变更 (Changed)**: 现有功能的变化
- **弃用 (Deprecated)**: 即将移除的功能
- **移除 (Removed)**: 已移除的功能
- **修复 (Fixed)**: Bug 修复
- **安全 (Security)**: 安全相关的修复

---

## 升级指南

### 从 0.0.x 升级到 0.1.0

**数据迁移**: 自动执行,无需手动操作

**不兼容变更**:
- 题目数据结构调整(新增 `source_chunk_id` 字段)
- AI Service 接口重构(参数格式变化)

**推荐步骤**:
1. 备份数据: 设置 → 隐私与数据 → 导出学习数据
2. 更新应用: `flutter pub get && flutter run`
3. 验证功能: 检查现有题目是否正常显示

---

## 路线图参考

查看 [ROADMAP.md](ROADMAP.md) 了解未来计划。

---

## 链接

- [项目主页](https://github.com/Drew-Z/anchor)
- [问题追踪](https://github.com/Drew-Z/anchor/issues)
- [讨论区](https://github.com/Drew-Z/anchor/discussions)

---

**格式**: 本文档遵循 [Keep a Changelog](https://keepachangelog.com/)  
**版本**: 语义化版本 [Semantic Versioning](https://semver.org/)
