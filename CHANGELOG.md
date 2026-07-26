# 更新日志

所有值得注意的变更都会记录在本文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/),
版本遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

---

## [Unreleased]

### 新增
- 完整的项目文档体系(架构、使用指南、开发文档)
- 开源推广计划(`docs/OPEN_SOURCE_PLAN.md`)
- 贡献指南和开发路线图

---

## [0.1.0] - 2026-07-26

### 新增

#### 文档导入
- Markdown 语义切分:按标题层级智能切分
- 代码文件切分:保留行号,支持精确定位
- 项目批量导入:支持整个代码库分析
- Source 和 SourceChunk 数据模型

#### AI 内容生成
- 知识点提取(KnowledgeExtractionTask)
- 前置依赖推理(ConceptPrerequisiteTask)
- 题目生成(QuestionGenerationTask)
  - 支持题型:单选/多选/填空/判断/匹配
- 引用验证(CitationVerificationTask)
- **题目质量验证(QuestionValidator)** ⭐ 新功能
  - 事实准确性检查
  - 引用完整性验证
  - 置信度评分

#### 学习功能
- 间隔重复调度(基于 SuperMemo 算法)
- 掌握度追踪(ease, lapseCount)
- 填空题 AI 语义判题
- 来源溯源(点击题目查看原文档)
- 题目审核界面(支持编辑/删除)

#### AI Agent
- 知识问答模式(基于知识库检索)
- 项目代码面试模式(引导式提问)
- 苏格拉底式辅导模式
- 长会话检查点恢复(AgentCheckpoint)
- 混合检索(BM25 + Semantic Embedding)

#### 基础设施
- SQLite 本地存储
- Riverpod 状态管理
- OpenAI API 集成
- 跨平台支持(Android/iOS/macOS/Windows/Linux)

### 改进
- 优化语义切分算法,避免切断代码块
- 改进题目生成 Prompt,提升质量
- 增强错误处理,减少崩溃

### 已知限制
- 仅支持 Markdown 和代码文件(PDF/Notion 待支持)
- 大项目导入(1000+ 文件)可能较慢
- 需要 OpenAI API Key(本地模型支持待完善)
- 暂无云同步功能

---

## [0.0.1] - 2026-01-15

### 初始版本
- 基础的 Markdown 导入
- 简单的单选题生成
- 手动答题功能
- 本地数据存储

---

## 版本规划

### [0.2.0] - 预计 2026-08 中旬
**主题**: 开源准备

- [ ] 完善文档(架构/使用/开发)
- [ ] 补充单元测试
- [ ] 录制 Demo 视频
- [ ] 内置示例数据
- [ ] 首次发布到 GitHub

### [0.3.0] - 预计 2026-09 底
**主题**: 功能增强

- [ ] PDF 导入支持
- [ ] 学习分析可视化
- [ ] 更多题型(排序题/代码补全)
- [ ] 增量文档更新
- [ ] Prompt 模板库

### [0.4.0] - 预计 2026-11
**主题**: 生态建设

- [ ] 云同步(可选)
- [ ] 插件系统
- [ ] 社区 Deck 分享
- [ ] Anki 导出

### [1.0.0] - 预计 2027-01
**主题**: 生产就绪

- [ ] 性能优化
- [ ] 多语言支持
- [ ] 完整的 UI/UX 改进
- [ ] 高级学习分析

---

## 链接

- [开发路线图](ROADMAP.md) - 详细的功能规划
- [贡献指南](CONTRIBUTING.md) - 如何参与开发
- [GitHub Releases](https://github.com/你的用户名/duoduo/releases) - 下载历史版本

---

**格式说明**:
- `新增` - 新功能
- `改进` - 对现有功能的改进
- `修复` - Bug 修复
- `移除` - 移除的功能
- `安全` - 安全相关修复
- `已知限制` - 当前版本的已知问题
