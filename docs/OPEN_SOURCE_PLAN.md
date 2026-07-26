# Anchor Learning (锚学) APP 开源推广计划

## 📋 执行摘要

**定位**: 一个展示"来源可溯源的 AI 学习代理"最佳实践的开源项目  
**目标受众**: AI 应用开发者、教育技术从业者、开源贡献者  
**差异化价值**: 完整的从文档到练习题的可溯源流水线 + Agent 驱动的学习系统

---

## 🎯 核心价值主张

### 为开发者提供
1. **可溯源 AI 管线参考实现**
   - Markdown 语义切分 → 知识点提取 → 引用核验 → 题目生成
   - 完整的 citation 链路(chunk → knowledge point → question)
   - 防幻觉的质量验证机制

2. **Learning Agent 架构模板**
   - 检查点恢复的长会话设计
   - 混合搜索(BM25 + 语义)
   - 项目代码理解的面试式引导

3. **移动端 AI 产品工程实践**
   - Flutter 架构(Riverpod + Repository)
   - 隐私优先设计(本地优先 + 可选云同步)
   - OpenAI API 集成模式

### 为学习者提供
- 一个可自托管的、隐私友好的学习工具
- 从个人文档/代码生成练习题的实用案例

---

## 📦 第一阶段:核心功能完善与文档化(2-3 周)

### 1.1 代码质量提升
**目标**: 让代码可读、可维护、可扩展

- [ ] **补充核心文件的注释**
  - `semantic_chunker.dart`: 算法逻辑说明
  - `question_validator.dart`: 验证策略文档
  - `learning_agent_runtime.dart`: Agent 状态机说明
  - 每个 AI Task 的 prompt 工程注释

- [ ] **提取可配置参数**
  ```dart
  // 当前硬编码的值提取为配置
  class IngestionConfig {
    final int maxLinesPerChunk;
    final int questionsPerKnowledgePoint;
    final double citationConfidenceThreshold;
  }
  ```

- [ ] **增加单元测试覆盖**
  - `semantic_chunker_test.dart`: Markdown 标题识别
  - `question_validator_test.dart`: Mock OpenAI 的验证逻辑
  - `citation_verification_task_test.dart`: 引用匹配测试

### 1.2 文档体系建设
**目标**: 让开发者 30 分钟内理解核心原理

#### A. 架构文档(`docs/architecture/`)
- [ ] `SYSTEM_OVERVIEW.md`: 4 大核心流程图
  - 文档导入流程(semantic chunking → citation)
  - 题目生成流程(extraction → generation → validation)
  - Agent 学习流程(interview → search → checkpoint)
  - 复习调度流程(mastery tracking → spaced repetition)

- [ ] `DATA_MODEL.md`: ER 图 + 核心表说明
  ```
  Source → SourceChunk → KnowledgePoint → Question
           ↓                    ↓
      (citation)           (citation)
  ```

- [ ] `AI_PIPELINE.md`: 每个 AI Task 的
  - 输入输出 schema
  - Prompt 设计思路
  - 防幻觉策略(如 citation verification)

#### B. 快速开始指南(`docs/guides/`)
- [ ] `QUICK_START.md`: 5 分钟跑起来
  ```bash
  # 1. Clone & Install
  git clone https://github.com/yourname/duoduo
  cd duoduo && flutter pub get
  
  # 2. 配置 API Key
  cp .env.example .env
  # 编辑 .env 填入 OPENAI_API_KEY
  
  # 3. 运行
  flutter run
  ```

- [ ] `IMPORT_YOUR_DOCS.md`: 导入自己的学习资料
  - 支持的文件格式(Markdown/代码/PDF)
  - 目录结构最佳实践
  - Troubleshooting: "为什么我的文档没生成题目?"

- [ ] `CUSTOMIZE_PROMPTS.md`: 修改 AI 行为
  ```dart
  // 例子:调整题目生成策略
  class QuestionGenerationTask {
    String get systemPrompt => '''
      你是一个严格的出题专家...
      [可定制的 prompt]
    ''';
  }
  ```

#### C. 开发者文档
- [ ] `CONTRIBUTING.md`: 贡献指南
  - 代码风格(Dart conventions)
  - PR 流程
  - Issue 模板(Bug/Feature/Question)

- [ ] `ROADMAP.md`: 公开开发计划
  - 当前版本功能
  - 下个版本计划
  - 欢迎贡献的领域

### 1.3 示例内容
**目标**: 让用户克隆后立即看到效果

- [ ] **内置示例数据集**
  - `assets/examples/flutter_basics.md`: Flutter 基础教程
  - `assets/examples/dart_async.md`: Dart 异步编程
  - 预生成的题目 JSON(首次运行自动导入)

- [ ] **视频 Demo**
  - 30 秒:从 Markdown 到第一道题
  - 2 分钟:Agent 辅导代码项目的完整流程
  - 上传到 README + GitHub Release

---

## 🚀 第二阶段:开源发布与推广(1 周)

### 2.1 仓库准备
- [ ] **README.md 完善**
  ```markdown
  # Anchor Learning (锚学) - 来源可溯源的 AI 学习代理
  
  [Demo GIF]
  
  ## ✨ 特性
  - 📚 从 Markdown/代码生成可溯源练习题
  - 🤖 AI Agent 辅导项目理解
  - 🔒 隐私优先(数据本地存储)
  - 📱 跨平台(Android/iOS/macOS)
  
  ## 🎯 适合谁
  - 正在学习编程的开发者
  - 需要理解大型项目的工程师
  - 想构建教育AI产品的团队
  
  ## 🚀 快速开始
  [链接到 docs/guides/QUICK_START.md]
  
  ## 🏗️ 架构亮点
  [3 张核心流程图]
  
  ## 📖 文档
  - [系统架构](docs/architecture/)
  - [开发指南](docs/guides/)
  - [API 参考](docs/api/)
  
  ## 🤝 贡献
  [链接到 CONTRIBUTING.md]
  
  ## 📄 许可
  MIT License
  ```

- [ ] **选择开源协议**
  - 推荐: MIT License(最宽松,利于采用)
  - 或 Apache 2.0(有专利保护)

- [ ] **清理敏感信息**
  - 检查是否有硬编码的 API Key
  - 移除个人数据库文件
  - `.gitignore` 完善

### 2.2 发布渠道
**目标**: 触达 AI + 教育技术社区

#### A. GitHub 优化
- [ ] **Topics 标签**
  ```
  flutter, ai-education, openai, knowledge-graph,
  spaced-repetition, learning-agent, citation-verification
  ```

- [ ] **GitHub Release**
  - v0.1.0-alpha: "First public preview"
  - 附带:
    - APK 下载(Android 用户直接试用)
    - CHANGELOG.md
    - 已知限制说明

- [ ] **GitHub Actions CI**
  ```yaml
  # .github/workflows/ci.yml
  - name: Run tests
  - name: Build APK
  - name: Deploy docs to GitHub Pages
  ```

#### B. 社区推广
- [ ] **技术博客文章**(2-3 篇)
  1. "如何用 Flutter 构建来源可溯源的 AI 学习应用"
     - 发布到: Medium、Dev.to、掘金
  
  2. "防止 AI 幻觉:实现 Citation Verification"
     - 发布到: Towards Data Science、AI 垂直社区
  
  3. "Learning Agent 架构实践:从代码到个性化辅导"
     - 发布到: Flutter Community、AI Agent 论坛

- [ ] **Reddit 发布**
  - r/FlutterDev: "Open-sourced my AI learning app"
  - r/MachineLearning: "Preventing LLM hallucinations with citation verification"
  - r/learnprogramming: "Built a tool to turn your notes into quiz questions"

- [ ] **Twitter/X 发布**
  ```
  🚀 Open-sourcing my AI learning agent project!
  
  ✅ Converts docs → grounded quiz questions
  ✅ AI tutor with full citation trail
  ✅ Privacy-first (local-first storage)
  
  Built with @FlutterDev + @OpenAI
  
  [GitHub link] [Demo GIF]
  
  #AI #EdTech #OpenSource
  ```

- [ ] **Hacker News 发布**
  - 标题: "Show HN: AI learning agent with citation-backed question generation"
  - 最佳时间: 工作日早上(美国东部时间)

#### C. 专业社区
- [ ] **Product Hunt 发布**
  - 分类: AI Tools / Education
  - Tagline: "Turn your docs into a personalized learning app"

- [ ] **Awesome Lists PR**
  - awesome-flutter
  - awesome-ai-tools
  - awesome-educational-games

---

## 🌱 第三阶段:社区培育(持续)

### 3.1 降低贡献门槛
- [ ] **Good First Issue 标签**
  - "Add support for PDF import"
  - "Improve Markdown parsing for tables"
  - "Add i18n support for Spanish"

- [ ] **导师计划**
  - 对首次贡献者提供代码 Review 指导
  - 在 CONTRIBUTORS.md 致谢

### 3.2 用户反馈循环
- [ ] **Discord/Slack 社区**
  - #general: 使用讨论
  - #development: 开发协作
  - #showcase: 用户分享自己的学习成果

- [ ] **月度进度更新**
  - Blog post: "What's new in v0.2"
  - 数据透明: GitHub stars / downloads / contributors

### 3.3 生态扩展
- [ ] **插件系统设计**
  ```dart
  abstract class IngestionPlugin {
    List<SourceChunk> process(File file);
  }
  // 允许第三方贡献: Notion 导入、Obsidian 同步等
  ```

- [ ] **云服务可选方案**
  - 文档: "如何部署自己的同步服务器"
  - 推荐: Supabase / Firebase(用户可选)

---

## 📊 成功指标(3 个月)

### 定量指标
- GitHub Stars: 100+
- Forks: 20+
- Contributors: 5+
- Issues/PRs: 30+ (活跃度)
- 文档页面访问: 500+ UV/月

### 定性指标
- 至少 2 个用户分享"用它学会了 X"
- 至少 1 个衍生项目(如 Web 版)
- 被 1 个技术媒体/Newsletter 报道

---

## 🛠️ 资源需求

### 时间投入
- **第一阶段**(代码+文档): 40-60 小时
- **第二阶段**(发布推广): 10-15 小时
- **持续维护**: 每周 3-5 小时(回复 Issue、Review PR)

### 技术储备
- Flutter/Dart 开发经验 ✅
- OpenAI API 使用 ✅
- 技术写作能力(博客)
- 社区运营经验(可学习)

### 可选外部帮助
- **技术写作**: 如果英文写作吃力,可雇佣 Upwork 编辑润色($50-100/篇)
- **视频制作**: Fiverr 上找 demo 视频剪辑($30-50)
- **设计素材**: Figma Community 寻找开源图标/配图

---

## 🎁 与 aicoding-cookbook 的协同

参考 https://github.com/lili-luo/aicoding-cookbook 的成功经验:

### 可借鉴的点
1. **Skill 系统设计**
   - 他们的 `docs-to-book` skill 将文档转为书籍
   - 我们可以贡献 `docs-to-quiz` skill: 用 Claude Code 调用我们的开源项目

2. **互相引用**
   - 在我们的 README 添加: "Inspired by aicoding-cookbook"
   - 向他们提 PR: 在 cookbook 添加我们的项目作为 Case Study

3. **共享最佳实践**
   - 他们的 Prompt 工程技巧
   - 我们的 Citation Verification 实现
   - 可合写一篇: "Building reliable AI tools: lessons from two projects"

---

## 🚨 风险与应对

### 风险 1: 初期关注度低
**应对**:
- 不要一次性发布所有渠道,分批测试反响
- A/B 测试标题/描述(如 HN 可以重发不同角度)
- 主动在相关 Issue/讨论中提及(不 spam)

### 风险 2: 维护负担过重
**应对**:
- 设置明确的 Response Time SLA(如 48 小时回复 Issue)
- 使用 Issue 模板自动分类
- 拒绝 Scope Creep: 不是所有 Feature Request 都要做

### 风险 3: 技术债积累
**应对**:
- 每个版本留 20% 时间重构
- Code Review 强制要求测试
- 定期 Dependency 更新(Dependabot)

---

## ✅ 下一步行动(本周)

按优先级排序:

1. **创建文档骨架** (2 小时)
   ```bash
   mkdir -p docs/{architecture,guides,api}
   touch docs/architecture/{SYSTEM_OVERVIEW,DATA_MODEL,AI_PIPELINE}.md
   touch docs/guides/{QUICK_START,IMPORT_YOUR_DOCS,CUSTOMIZE_PROMPTS}.md
   touch CONTRIBUTING.md ROADMAP.md
   ```

2. **补充核心注释** (4 小时)
   - 优先: `semantic_chunker.dart`, `question_validator.dart`
   - 标准: 每个公开方法有 Dartdoc

3. **录制 30 秒 Demo** (1 小时)
   - 工具: OBS Studio(免费)
   - 内容: 导入 Markdown → 生成题目 → 答题

4. **撰写 QUICK_START.md** (2 小时)
   - 本地测试一遍流程
   - 截图每个关键步骤

5. **提取配置参数** (3 小时)
   - 创建 `lib/core/config/ingestion_config.dart`
   - 重构硬编码值

**总计: 约 12 小时(可分 3 天完成)**

---

## 📚 参考资源

- [Open Source Guide](https://opensource.guide/) - GitHub 官方开源指南
- [Flutter Favorite Packages](https://pub.dev/flutter/favorites) - 学习优秀开源项目
- [Awesome README](https://github.com/matiassingers/awesome-readme) - README 案例
- [Indie Hackers](https://www.indiehackers.com/) - 产品推广经验

---

**最后更新**: 2026-07-26  
**维护者**: [Your Name]  
**反馈**: 欢迎在 Issue 或 Discord 提出改进建议
