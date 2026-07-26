# MVP Implementation Roadmap

## 开发目标

第一版目标不是做完整知识库平台，而是跑通一个强闭环：

```text
导入可信来源
-> 拆知识点
-> 生成带引用的题目
-> 人工核验
-> 面试官模式追问
-> 保存薄弱点
-> 安排复习
```

## Phase 0：稳定当前项目

目标：先让现有项目适合继续扩展。

### 任务

- 安装或配置 Flutter 环境。
- 跑通 `flutter pub get`。
- 跑通 `flutter analyze`。
- 跑通现有测试。
- 给数据库增加 `onUpgrade` 基础结构。
- 修复匹配题预览可能错配的问题。
- 把 `OpenAIService` 移到 `services/ai/` 或保持现名但抽象接口。

### 主要文件

```text
lib/data/database/database_helper.dart
lib/data/models/question.dart
lib/services/openai_service.dart
lib/features/ingestion/deck_preview_screen.dart
```

### 验收标准

- 项目能正常运行。
- 现有导入和答题流程不退化。
- 数据库具备版本迁移入口。
- 匹配题预览显示正确匹配关系。

## Phase 1：来源化数据模型

目标：从“题包题目”升级为“来源知识库”。

### 任务

- 新增模型：
  - `Source`
  - `SourceChunk`
  - `KnowledgePoint`
  - `KnowledgePointSource`
- 扩展 `Question`：
  - `knowledgePointId`
  - `difficulty`
  - `sourceStatus`
  - `citationIds`
  - `lastReviewedAt`
  - `nextReviewAt`
  - `ease`
  - `lapseCount`
- 新增数据库表：
  - `sources`
  - `source_chunks`
  - `knowledge_points`
  - `knowledge_point_sources`
- 新增 repository 层：
  - `SourceRepository`
  - `KnowledgePointRepository`
  - `QuestionRepository`

### 主要文件

```text
lib/data/models/source.dart
lib/data/models/source_chunk.dart
lib/data/models/knowledge_point.dart
lib/data/models/knowledge_point_source.dart
lib/data/database/database_helper.dart
lib/data/repositories/source_repository.dart
lib/data/repositories/knowledge_point_repository.dart
lib/data/repositories/question_repository.dart
```

### 验收标准

- 可以保存一个来源。
- 可以保存来源片段。
- 可以保存知识点并关联来源片段。
- 可以保存题目并关联知识点和引用。
- 旧题包数据不被破坏。

## Phase 2：结构化 AI 任务

目标：替代当前“prompt + 文本解析”的方式。

### 任务

- 新增 AI 任务目录。
- 实现 `KnowledgeExtractionTask`。
- 实现 `QuestionGenerationTask`。
- 实现 `CitationVerificationTask`。
- 定义统一 `AiTaskResult<T>`。
- 解析失败时显示明确错误。

### 主要文件

```text
lib/services/ai/ai_service.dart
lib/services/ai/ai_task_result.dart
lib/services/ai/tasks/knowledge_extraction_task.dart
lib/services/ai/tasks/question_generation_task.dart
lib/services/ai/tasks/citation_verification_task.dart
lib/services/content_analyzer.dart
```

### 验收标准

- 输入一段来源文本后，AI 返回知识点。
- 题目生成结果包含 citation ids。
- 没有来源的题目不能被标成 verified。
- 解析失败不会静默跳过题目。

## Phase 3：知识核验预览页

目标：替换当前简单题目预览页。

### 任务

- 将 `DeckPreviewScreen` 升级为 `KnowledgeReviewScreen`。
- 展示：
  - 来源摘要。
  - 知识点列表。
  - 每道题。
  - 每道题的来源片段。
  - 来源状态。
- 支持用户操作：
  - 确认为 verified。
  - 标记 pending。
  - 删除。
  - 手动编辑题干、答案、解析。

### 主要文件

```text
lib/features/ingestion/deck_preview_screen.dart
lib/features/ingestion/knowledge_review_screen.dart
lib/core/providers/providers.dart
```

### 验收标准

- AI 生成内容不会直接保存为正式学习内容。
- 用户能看见每道题的引用依据。
- 用户确认后才进入正式学习。
- pending/no_source 不进入默认学习路径。

## Phase 4：项目导入向导

目标：服务面试准备场景。

### 任务

- 新增项目导入入口。
- 表单字段：
  - 项目名称。
  - 项目目标。
  - 技术栈。
  - README / 项目说明。
  - 目录结构。
  - 关键文件片段。
  - 重点面试方向。
- 支持代码片段的文件路径和行号范围。
- 生成项目知识点。

### 主要文件

```text
lib/features/ingestion/project_import_screen.dart
lib/services/ingestion/project_source_builder.dart
lib/data/models/source.dart
lib/data/models/source_chunk.dart
```

### 验收标准

- 用户可以导入一个项目。
- 项目材料被保存为 `project` source。
- 关键代码片段被保存为 `code_file` source chunk。
- 系统能生成项目相关知识点。

## Phase 5：面试官模式 MVP

目标：让用户练习讲清楚自己的项目。

### 任务

- 新增 Agent tab。
- 新增面试官模式页面。
- 实现：
  - 选择学习单元或项目。
  - 生成面试问题。
  - 一次问一个问题。
  - 用户先回答。
  - AI 评分。
  - 展示参考答案和来源。
  - 保存 learning session 和 interview turns。

### 主要文件

```text
lib/features/agent/agent_home_screen.dart
lib/features/agent/interview_screen.dart
lib/services/agent/learning_agent_orchestrator.dart
lib/services/agent/interviewer_service.dart
lib/services/ai/tasks/interview_question_task.dart
lib/services/ai/tasks/answer_evaluation_task.dart
lib/data/models/learning_session.dart
lib/data/models/interview_turn.dart
```

### 验收标准

- 用户必须先回答才能看到参考答案。
- 每轮反馈包含四个评分维度。
- 每轮反馈能显示来源。
- 薄弱知识点会被记录。

## Phase 6：复习和 mastery

目标：把一次性训练变成长期学习。

### 任务

- 新增 mastery 计算。
- 新增今日复习队列。
- 将 quiz、interview、answer attempts 汇总到知识点掌握度。
- 首页展示今日任务。
- 我的页面展示薄弱知识点。

### 主要文件

```text
lib/services/scheduling/review_scheduler_service.dart
lib/services/scheduling/mastery_service.dart
lib/features/home/home_screen.dart
lib/features/profile/profile_screen.dart
lib/data/models/answer_attempt.dart
```

### 验收标准

- 答错或面试低分的知识点会进入复习。
- 每个知识点有 mastery。
- 今日复习队列可用。
- 用户能看到自己薄弱在哪里。

## Phase 7：知识库 tab

目标：让用户管理知识，而不是只管理题包。

### 任务

- 新增知识库 tab。
- 展示来源。
- 展示知识点。
- 展示待核验内容。
- 展示题目和引用。
- 支持筛选：
  - verified
  - pending
  - no_source
  - trust level

### 主要文件

```text
lib/features/knowledge_base/knowledge_base_screen.dart
lib/features/knowledge_base/source_list_screen.dart
lib/features/knowledge_base/knowledge_point_list_screen.dart
lib/features/knowledge_base/pending_review_screen.dart
```

### 验收标准

- 用户可以查看所有来源。
- 用户可以查看所有知识点。
- 用户可以找到待核验内容。
- 用户可以从题目跳回来源片段。

## Phase 8：后续扩展

这些不进 MVP，但架构要预留：

- GitHub URL 自动导入。
- PDF/网页导入。
- SQLite FTS5 检索。
- embeddings + vector DB。
- 云同步。
- 多设备账户。
- 更专业的间隔复习算法。

## 建议开发顺序

严格按下面顺序推进：

```text
Phase 0
-> Phase 1
-> Phase 2
-> Phase 3
-> Phase 4
-> Phase 5
-> Phase 6
-> Phase 7
```

不要先做 Agent UI。先把来源、知识点和引用打牢。

## 第一批可执行任务

下一步最适合从 Phase 0 开始：

1. 增加数据库 migration 结构。
2. 修复匹配题预览错配风险。
3. 拆出 repository 层。
4. 新增 source/knowledge point 模型。

完成这四件事后，再进入来源化题库的正式实现。

