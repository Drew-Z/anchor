# Anchor Learning Agent Rebuild Plan

## 目标定位

把当前的 Duoduo 从“AI 拆题 + 游戏化刷题”升级成“有来源依据的个人知识库学习 agent”。

第一优先级不是做一个泛学习工具，而是服务两个强场景：

1. AI 应用开发面试准备：帮助用户真正讲清楚自己通过 vibe coding 做出的项目。
2. 编程知识学习：围绕官方文档、源码、课程资料生成可追溯的知识点、题目和复习计划。

核心原则：LLM 可以负责总结、提问、解释和追问，但事实依据必须来自可追溯来源。

## 可借鉴产品模式

### NotebookLM：来源驱动学习

可借鉴点：

- 从用户材料生成 flashcards、quizzes、reports、Learning Guide。
- 题目和解释应完全基于用户来源。
- 解释应能回到原始材料或引用片段。
- 适合 dense material -> active learning 的转化。

参考：

- Google Blog, "6 ways to use NotebookLM to master any subject": https://blog.google/innovation-and-ai/models-and-research/google-labs/notebooklm-student-features/
- NotebookLM Help, "Generate Flashcards or Quizzes in NotebookLM": https://support.google.com/notebooklm/answer/16958963?hl=en

对 Duoduo 的启发：

- 当前 `ContentAnalyzer` 只输出题包标题和题目。应该扩展为“来源 -> 片段 -> 知识点 -> 题目 -> 引用”的链路。
- 题目解析页必须显示“依据来自哪里”，而不是只显示 AI 解析。

### ChatGPT Study Mode：导师式引导

可借鉴点：

- 不是直接给答案，而是通过 Socratic questioning、hints、self-reflection、knowledge checks 引导理解。
- 根据用户水平调整解释层次。
- 对复杂概念使用分层解释和阶段性检查。

参考：

- OpenAI, "Introducing study mode": https://openai.com/index/chatgpt-study-mode/

对 Duoduo 的启发：

- 学习 agent 不应该只有“检查答案”。应该在用户答错时追问：“你是怎么判断的？”
- 面试准备模式应该像面试官一样一问一答，而不是一次性给用户完整讲稿。

### Anki / RemNote：长期记忆和间隔复习

可借鉴点：

- Active recall 比被动阅读更适合建立记忆。
- Spaced repetition 根据用户记忆表现安排复习。
- RemNote 的“任意来源生成卡片 + 间隔复习”适合知识库学习。

参考：

- Anki Manual, "Background": https://docs.ankiweb.net/background.html
- RemNote, "AI Flashcards": https://www.remnote.com/any_source_to_cards

对 Duoduo 的启发：

- 当前项目只有 deck mastery，不够细。应该记录到 knowledge point/question 级别。
- 复习算法可以先做简单版本：错题当天复习，困难题次日复习，熟练题延后复习。

### DeepWiki / Sourcegraph Cody：代码库理解

可借鉴点：

- DeepWiki 把 repo 自动变成架构图、文档、源码链接和问答。
- Sourcegraph Cody 用开发上下文、文件、符号和远程仓库做代码问答。

参考：

- Devin Docs, "DeepWiki": https://docs.devin.ai/work-with-devin/deepwiki
- Sourcegraph Docs, "Cody": https://docs.sourcegraph.com/cody

对 Duoduo 的启发：

- 对“vibe coding 项目复盘”来说，repo 本身就是最高价值来源。
- app 应该能从 GitHub URL 或本地代码生成：
  - 项目架构卡
  - 数据流卡
  - 面试问答卡
  - 关键文件讲解
  - 可追溯到文件路径和行号的引用

## 目标产品形态

### 一级导航

建议保留当前 Duoduo 的轻量结构，但扩展成四个主区：

1. 学习
   - 今日复习
   - 学习路径
   - 随机挑战
2. 知识库
   - 来源列表
   - 项目列表
   - 知识点图谱
3. Agent
   - 面试官模式
   - 导师模式
   - 项目讲解模式
4. 我的
   - XP、streak、掌握度、薄弱点、学习报告

### 核心学习流

1. 导入来源
   - 文本
   - URL
   - PDF/Markdown
   - GitHub repo
   - 本地项目摘要

2. 来源解析
   - 保存原文或片段
   - 拆分 chunk
   - 标注来源类型和可信等级

3. 知识点生成
   - 每个知识点绑定一个或多个 source chunk
   - 生成摘要、标签、先修关系、面试价值

4. 题目生成
   - 每道题绑定 knowledge point 和 source chunk
   - AI 输出必须包含 citation ids
   - 无 citation 的题目标记为待核验

5. 学习与追问
   - 正常答题
   - 答错后显示来源依据
   - agent 追问原因
   - 根据回答质量更新掌握度

6. 复习调度
   - question review state
   - knowledge point mastery
   - daily review queue

## 数据模型规划

第一阶段建议仍用 SQLite，但必须加 migration。

### sources

- id
- title
- type: text/url/pdf/github_repo/code_file/official_doc/user_note
- uri
- trust_level: official/source_code/course/article/user_note/unknown
- created_at
- updated_at

### source_chunks

- id
- source_id
- chunk_index
- content
- locator: url fragment, page number, file path, line range
- content_hash

### knowledge_points

- id
- title
- summary
- tags
- difficulty
- interview_relevance
- mastery_level

### knowledge_point_sources

- knowledge_point_id
- source_chunk_id
- relation: defines/explains/example/counterexample

### questions

在现有表基础上新增：

- knowledge_point_id
- difficulty
- source_status: verified/pending/no_source
- citation_ids
- last_reviewed_at
- next_review_at
- ease
- lapse_count

### learning_sessions

- id
- mode: quiz/interview/tutor/project_walkthrough
- started_at
- ended_at
- xp_gained
- summary

### answer_attempts

- id
- session_id
- question_id
- user_answer
- is_correct
- ai_feedback
- created_at

## Agent 能力规划

### Project Interview Agent

用于 AI 应用开发面试准备。

能力：

- 根据项目源码生成“我做了什么”的结构化说明。
- 追问技术细节：数据流、状态管理、数据库、AI 调用、安全、错误处理。
- 要求用户先回答，再给建议答案。
- 每个建议答案附源码引用。

最小闭环：

1. 用户导入 GitHub repo。
2. 系统生成项目知识点。
3. 用户进入面试官模式。
4. agent 一次问一个问题。
5. 用户回答后，agent 给评分、改进建议、参考答案和引用。

### Programming Tutor Agent

用于编程知识学习。

能力：

- 用官方文档或高可信材料做来源。
- 分层解释概念。
- 生成小练习。
- 识别误区并追问。

### Source Verifier

用于保证内容正规。

规则：

- 官方文档、源码、标准、论文优先。
- 用户笔记可以进入知识库，但标记为 user_note。
- AI 输出不是来源。
- 没有来源的知识点不能进入正式复习，只能进入待核验区。

## 分阶段实现

### Phase 0：稳定当前项目

- 补 Flutter 环境。
- 跑通 `flutter analyze` 和测试。
- 给 SQLite 增加 migration 基础结构。
- 修复匹配题预览可能错配的问题。

### Phase 1：来源化题库

目标：先让每道题有来源。

- 新增 `sources`、`source_chunks`、`knowledge_points`。
- 扩展 `AnalysisResult`。
- 改 `ContentAnalyzer` prompt，要求输出 knowledge points 和 citations。
- 预览页展示引用依据。
- 答题解析页展示引用依据。

### Phase 2：知识库页面

目标：用户能管理知识，而不是只管理题包。

- 新增知识库 tab。
- 展示 sources、knowledge points、待核验内容。
- 支持手动编辑知识点和来源。
- 支持把题目回溯到来源片段。

### Phase 3：面试官模式

目标：服务你的核心使用场景。

- 新增 Project 类型来源。
- 初版可以让用户粘贴项目 README、目录结构、关键代码。
- 生成项目架构卡、面试问题、参考答案。
- agent 一次问一个问题，用户回答后给反馈。

### Phase 4：复习调度

目标：从刷题变成长期掌握。

- 记录每题 review state。
- 生成今日复习队列。
- 按知识点聚合薄弱项。
- 首页从“学习路径”扩展为“今日任务 + 路径”。

### Phase 5：GitHub/文档导入和 RAG

目标：真正变成知识库学习 agent。

- 支持 GitHub URL 导入。
- 支持 Markdown/PDF/网页导入。
- 初期用 SQLite FTS5 做本地检索。
- 后续可升级到后端 + embeddings/vector DB。

## 技术建议

### 先保留 Flutter

当前 Flutter + Riverpod + SQLite 的底子适合移动端学习 app。不要一开始重写成 Web 或复杂后端。

### 先做本地 source-grounding，再做向量检索

第一版不要急着上 vector DB。先把来源、chunk、citation 数据模型做好。检索可以从 SQLite FTS5 开始。

### LLM 调用要结构化

现有 `ContentAnalyzer` 解析 JSON 的方式比较脆弱。后续应定义明确 schema：

- deck title
- source chunks used
- knowledge points
- questions
- citations
- verification notes

### 安全和可信

- API Key 不建议长期存在 SharedPreferences，正式版改安全存储。
- 所有 AI 内容都要标注生成时间、模型、来源状态。
- 用户应能看到“这条知识来自哪里”。

## 推荐的最小可行版本

MVP 不做大而全。

只做一个强闭环：

1. 用户导入一段项目说明或源码片段。
2. app 生成知识点和题目。
3. 每道题都有来源片段。
4. 用户答题或进入面试官模式。
5. agent 根据来源给反馈。
6. 答错的知识点进入今日复习。

这个版本既保留 Duoduo 的学习方法，又能证明“个人知识库学习 agent”的方向是成立的。

## Smart Search Evidence

调研命令和证据文件保存在：

`C:\tmp\smart-search-evidence\20260707-duoduo-learning-agent`

关键命令：

```powershell
smart-search search "source grounded AI study app citations NotebookLM RemNote Anki Quizlet learning agent" --validation balanced --extra-sources 3 --timeout 120 --format json
smart-search search "official NotebookLM source grounded citations study guide flashcards quizzes" --validation balanced --extra-sources 2 --timeout 120 --format json
smart-search search "OpenAI ChatGPT Study Mode official Socratic learning source" --validation balanced --extra-sources 2 --timeout 120 --format json
smart-search search "AI codebase explanation app GitHub repository wiki DeepWiki Sourcegraph Cody official" --validation balanced --extra-sources 3 --timeout 120 --format json
smart-search fetch "https://blog.google/innovation-and-ai/models-and-research/google-labs/notebooklm-student-features/" --format markdown
smart-search fetch "https://openai.com/index/chatgpt-study-mode/" --format markdown
smart-search fetch "https://docs.ankiweb.net/background.html" --format markdown
smart-search fetch "https://docs.devin.ai/work-with-devin/deepwiki" --format markdown
smart-search fetch "https://docs.sourcegraph.com/cody" --format markdown
```
