# 锚学 - 开源推广实施计划

> 基于参考项目 [aicoding-cookbook](https://github.com/lili-luo/aicoding-cookbook) 的最佳实践

## 阶段 1: 极简 MVP(当前已完成 80%)

### 1.1 核心功能打磨 ✅

**已完成**:
- ✅ 基础刷题流(卡片、选择、填空、判断、AI判题)
- ✅ Deck 管理(导入、预览、列表)
- ✅ Markdown 内容提取 + AI 生成题目
- ✅ 成就系统(经验值、连击、成长曲线)
- ✅ 知识图谱原型(知识点、前置依赖、来源关联)
- ✅ Agent 架构雏形(对话式学习、检查点、记忆)

**待优化**(本周):
- 🔨 **新用户体验改造(已启动)**
  - ✅ 自动导入 Demo 数据(Vue.js 响应式系统)
  - ⏳ 跳过 Onboarding 流程,直接进入学习界面
  - ⏳ 添加"示例数据"标签,引导用户导入自己的内容
  
- 🔨 导入流程简化
  - 当前:4步流程(粘贴 → 预览 → 审核 → 生成)
  - 目标:2步流程(粘贴 → 一键导入,后台自动处理)
  - 参考:aicoding-cookbook 的 docs-to-book skill(直接从 Markdown 生成章节)

- 🔨 UI 表达优化
  - 隐藏技术名词(Source Chunk、Knowledge Point 改为"学习材料"、"知识卡片")
  - 简化设置项(只保留 API Key、模型选择,其他默认)
  - 添加进度可视化(学习时长、掌握数、成长曲线)

### 1.2 技术债清理(本周)

- 🔧 API 配置流程
  - 当前:需要手动填 Base URL、选择协议
  - 目标:预设常用服务(OpenAI、DeepSeek、本地 Ollama),一键切换
  - 参考:aicoding-cookbook 中 Claude API 配置的简洁性

- 🔧 错误处理
  - 当前:API 报错时界面卡死,无重试机制
  - 目标:友好提示 + 自动重试 + 降级方案(离线模式)

- 🔧 性能优化
  - 当前:导入大文件时主线程阻塞
  - 目标:异步处理 + 进度条 + 取消功能

---

## 阶段 2: 开源发布准备(第 2-3 周)

### 2.1 文档体系(参考 aicoding-cookbook 结构)

#### README.md ✅ 
已完成基础版,需补充:
- 🎯 项目定位:"AI 驱动的个人学习助手,让技术文档变成可刷的知识卡片"
- 📸 功能演示 GIF(刷题、导入、知识图谱、Agent 对话)
- 🚀 快速开始(5 分钟内跑起来)
- 🏗️ 架构图(数据流、AI 流程)

#### CONTRIBUTING.md(新建)
```markdown
# 贡献指南

## 开发环境搭建
1. Flutter 3.44.8 stable（与 CI 一致；Dart 最低约束见 `pubspec.yaml`）
2. 可选:本地 AI 模型(Ollama)

## 项目结构
- `lib/features/`: 功能模块(刷题、导入、Agent)
- `lib/data/`: 数据层(SQLite、Repository)
- `lib/services/`: 业务逻辑(AI、调度、成就)

## 代码规范
- 命名:优先使用英文,注释用中文
- 提交:feat/fix/docs/refactor 前缀

## 优先级需求
- [ ] 支持更多内容格式(PDF、网页、YouTube字幕)
- [ ] 间隔重复算法优化(当前仅 SM-2)
- [ ] 移动端 UI 适配(当前仅桌面优化)
```

#### ARCHITECTURE.md(新建)
参考 aicoding-cookbook 的 skill 模块化设计,说明:
- 核心概念:Source → Chunk → KnowledgePoint → Question
- AI 任务抽象:每个 AI 功能独立成 Task(QuestionGenerationTask、AnswerEvaluationTask)
- Agent 系统:Checkpoint + Memory + Planner 三件套
- 扩展点:如何添加新题型、新 AI 能力、新导入格式

### 2.2 示例内容包

**内置 Demo 数据**(已启动):
- ✅ Vue.js 响应式系统原理(已实现)
- ⏳ React Hooks 使用指南
- ⏳ Flutter 状态管理对比

**社区贡献模板**:
```markdown
## 贡献学习包步骤
1. 在 `assets/demo/` 下创建 `your-topic.md`
2. 格式:二级标题 = 知识点,代码块 = 示例
3. 提交 PR,附带 50 字说明
```

### 2.3 部署方案

**桌面端**:
- Windows/macOS 打包(参考 README 中的 Flutter 构建命令)
- 自动更新机制(可选,初期手动下载)

**移动端**:
- Android APK 发布到 GitHub Releases
- iOS TestFlight(需开发者账号,暂缓)

**Web 端**(可选):
- 限制:无文件系统访问,需要改用云端存储
- 方案:Cloudflare Pages + Supabase(如有需求再做)

---

## 阶段 3: 社区增长策略(第 4-8 周)

### 3.1 内容营销

**技术博客系列**(每周 1 篇):
1. "我用 Flutter + AI 做了个可追溯的智能学习 APP"(产品介绍)
2. "如何让 AI 从 Markdown 生成高质量题目"(技术解析)
3. "本地 AI 模型在移动端的实践"(Ollama 集成)
4. "知识图谱 + 间隔重复算法的学习系统设计"(算法篇)

**发布渠道**:
- 掘金/CSDN(中文技术社区)
- Dev.to/Hashnode(英文社区)
- Reddit r/learnprogramming, r/FlutterDev

**视频教程**(B站/YouTube):
- 5 分钟快速上手
- 导入自己的学习笔记
- 用 Agent 对话式学习

### 3.2 开发者生态

**Skill 插件系统**(参考 aicoding-cookbook):
- 当前:所有功能硬编码在主工程
- 目标:核心功能抽象成插件接口
  - 内容导入器(Markdown/PDF/Webpage Importer)
  - 题型生成器(MCQ/FillBlank/Code Generator)
  - AI 模型适配器(OpenAI/Anthropic/Ollama Adapter)

**示例插件**(吸引贡献者):
1. **Anki 导入器**:读取 Anki 卡组,转换为锚学格式
2. **LeetCode 同步**:自动拉取已做题目,生成回顾卡片
3. **Obsidian 集成**:监听笔记变化,自动更新知识库

### 3.3 用户反馈闭环

**Issue 模板**(GitHub):
- Bug Report:环境、复现步骤、期望行为
- Feature Request:使用场景、替代方案、优先级
- Learning Pack:主题、来源、许可证

**路线图透明化**:
- GitHub Projects 看板:待做、进行中、已完成
- 每月更新日志:新功能、修复、社区贡献致谢

**社区互动**:
- Discord/微信群(达到 100 star 后建立)
- 每月线上答疑(腾讯会议/Zoom)

---

## 阶段 4: 商业化探索(3 个月后)

### 4.1 免费 vs 付费边界

**永久免费**(核心价值):
- 本地运行,无服务器成本
- 自带 AI(用户提供 API Key)
- 基础刷题、导入、成就系统

**可选付费**(增值服务):
- 云同步(跨设备同步学习进度)
- 高级 AI 功能(用官方 API,免配置)
- 精选学习包(付费课程内容转刷题包)

**不推荐**(与开源定位冲突):
- ❌ 功能限制(免费版只能导入 3 个 Deck)
- ❌ 广告(影响学习体验)
- ❌ 强制登录(违背本地优先原则)

### 4.2 可持续性方案

**赞助模式**(当前最合适):
- GitHub Sponsors / 爱发电
- 回报:提前体验新功能、专属学习包、致谢墙

**企业服务**(远期):
- 团队版:公司内部知识库刷题化
- 定制开发:特定领域的 AI 模型微调

**开源许可**:
- 建议:MIT License(最宽松,利于推广)
- 或 Apache 2.0(如需专利保护)

---

## 里程碑

### Week 1-2: MVP 打磨
- [x] 新用户体验改造(Demo 数据 + 跳过引导)
- [ ] 导入流程简化(2 步搞定)
- [ ] UI 表达优化(去技术化)
- [ ] 错误处理增强

### Week 3-4: 开源发布
- [ ] 文档补全(README/CONTRIBUTING/ARCHITECTURE)
- [ ] 示例内容包(3 个高质量 Demo)
- [ ] 桌面/移动端打包
- [ ] GitHub Private Alpha Release `v1.0.0`（须等待真实 cohort readiness `GO`）

### Week 5-8: 社区增长
- [ ] 技术博客 4 篇
- [ ] 视频教程 3 期
- [ ] 插件系统设计文档
- [ ] 第一个社区贡献的 Learning Pack

### Month 4+: 迭代优化
- [ ] 根据 Issue 反馈调整优先级
- [ ] 尝试 1-2 个付费实验
- [ ] 建立贡献者激励机制

---

## 参考资源

- **aicoding-cookbook**:https://github.com/lili-luo/aicoding-cookbook
  - 学习要点:Skill 模块化设计、文档结构、Claude API 最佳实践
  - 可复用:docs-to-book 的文档解析逻辑

- **类似开源项目**:
  - Anki(间隔重复算法鼻祖)
  - RemNote(知识图谱 + 刷题)
  - Obsidian(插件生态建设)

- **技术选型参考**:
  - Flutter(跨平台 UI,已选用)
  - SQLite(本地数据库,已选用)
  - Riverpod(状态管理,已选用)
  - Ollama(本地 AI,待集成)
