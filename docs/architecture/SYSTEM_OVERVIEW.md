# 系统架构概览

> 2026-09-09：复习调度、答题保存与共享状态刷新已按当前实现核对；题目预核验、人工审核与知识搜索的核对日期为 2026-09-08。当前开发指针见 [CURRENT_STATE.md](../CURRENT_STATE.md)。下文其他设计说明和性能估算不构成发布验收证据。

## 总体设计理念

**Anchor Learning (锚学)**是一个来源可溯源的 AI 学习代理系统,核心设计原则:

1. **可溯源性优先**: 每个知识点、每道题目都能追溯到源文档的具体位置
2. **来源核验与人工审核**: 模型引用预核验、项目导入的本地质量检查和人工审核共同提供依据；预核验分数不代表事实已被证明
3. **隐私优先**: 数据本地存储,可选云同步
4. **Agent 驱动**: 长会话学习代理,支持检查点恢复

---

## 四大核心流程

### 1. 文档导入流程 (Document Ingestion)

```mermaid
graph TD
    A[用户选择文档/项目] --> B[ProjectSourceImportService]
    B --> C{检测文件类型}
    C -->|Markdown| D[SemanticChunker.chunkMarkdown]
    C -->|代码文件| E[SemanticChunker.chunkCode]
    C -->|其他文本| F[按固定行数切分]
    D --> G[生成 SourceChunk]
    E --> G
    F --> G
    G --> H[保存到 Source 表]
    H --> I[每个 Chunk 生成精确 locator]
    
    style D fill:#e1f5e1
    style E fill:#e1f5e1
    style I fill:#ffe1e1
```

**关键设计**:
- **语义切分**: Markdown 按标题层级切分,保持段落完整性
- **Locator 生成**: 如 `README.md:## 架构设计` 或 `main.dart:45-67`
- **Content Hash**: 用于检测文档更新

**涉及文件**:
- `lib/services/ingestion/semantic_chunker.dart`
- `lib/services/ingestion/project_source_import_service.dart`
- `lib/data/models/source.dart`
- `lib/data/models/source_chunk.dart`

---

### 2. 题目生成流程 (Question Generation Pipeline)

```mermaid
graph TD
    A[SourceChunks] --> B{导入入口}
    B -->|文本| C[KnowledgeExtractionTask]
    B -->|项目| D[ProjectUnderstandingTask]
    C --> E[构建知识点草稿]
    D --> E
    E --> F[QuestionGenerationTask]
    F --> G[生成题目草稿]

    G --> H[precheckQuestions: 过滤引用 ID 并预核验]
    H --> I[保留 pending 或 noSource 草稿]
    I --> J{导入入口}
    J -->|项目| K[QuestionValidator: 本地质量检查]
    K --> L[有问题时向解析追加警告]
    J -->|文本| O[KnowledgeReviewScreen]
    L --> O
    O --> P[用户决定已核验、待核验或删除]
    P --> Q[saveReviewedContent: 按审核决策事务保存]

    style H fill:#fff3cd
    style K fill:#fff3cd
    style P fill:#e1f5e1
```

**各层的实际职责**:

1. **Layer 1: Semantic Chunker**
   - 保持源文档结构完整性
   - 不切断段落/代码块中间

2. **Layer 2: Citation Verification**
   - `precheckQuestions` 过滤不存在的引用 ID；没有可用引用时保留 `noSource` 草稿。
   - 有可用引用时，`CitationVerificationTask` 调用模型判断给定片段是否支持答案和解析，返回候选可信、证据较弱或无来源等预核验结果，并过滤模型返回的引用 ID。
   - `precheckQuestions` 按结果调整引用和草稿状态：无法获得支持的引用会被移除，有保留引用的草稿仍为 `pending`；即使模型返回 `verified_candidate` 也不自动成为 `verified`。请求失败时按已知引用是否为空保留 `pending` 或 `noSource`。
   - 该预核验函数当前不把模型的 `reason` 写回题目解析；项目导入随后追加的是本地质量检查警告。

3. **Layer 3: 本地质量检查与人工审核**
   - 项目导入调用 `QuestionValidator.validateBatch`，按题型检查关键词、数字、答案、代码片段、匹配关系和顺序等局部规则；它不调用模型，不能证明任意事实正确。
   - `confidence` 根据发现的问题数量取 1.0、0.7、0.5 或 0.3，是规则检查摘要，不是事实正确率。项目导入只向未通过检查的题目解析追加警告；文本导入当前没有这一步。
   - 两个入口都进入 `KnowledgeReviewScreen`。`saveReviewedContent` 按审核决策保存，并再次过滤引用；没有有效引用的题目只能以 `noSource` 保存。

**涉及文件**:
- `lib/services/ai/tasks/knowledge_extraction_task.dart`
- `lib/services/ai/tasks/project_understanding_task.dart`
- `lib/services/ai/tasks/question_generation_task.dart`
- `lib/services/ai/tasks/citation_verification_task.dart`
- `lib/services/validation/question_validator.dart`
- `lib/services/ingestion/source_grounded_ingestion_service.dart`
- `lib/features/ingestion/ingestion_screen.dart`
- `lib/features/ingestion/project_import_screen.dart`
- `lib/features/ingestion/knowledge_review_screen.dart`

---

### 3. Agent 学习流程 (Learning Agent Pipeline)

```mermaid
graph TD
    A[用户提问] --> B[LearningAgentRuntime]
    B --> C[LearningAgentPlanner]
    C --> D{判断用户意图}
    
    D -->|需要检索知识| E[知识库搜索与问答入口]
    D -->|需要理解项目| F[InterviewerService]
    D -->|需要练习| G[选择练习题]
    D -->|需要代码实践| H[生成 ProgrammingExercise]
    
    E --> S[词法检索及可选查询扩展与 RRF 展示]
    S --> I[从当前展示的搜索分支选择有来源的回答上下文]
    I --> J[用户触发 KnowledgeAnswerTask]
    J --> K[生成带引用的回答]
    
    F --> L[生成面试式问题]
    L --> M[用户回答]
    M --> N[AnswerEvaluationTask]
    N --> O[苏格拉底式引导]
    
    K --> P[保存到 LearningSession]
    O --> P
    
    P --> Q[AgentCheckpoint 持久化]
    Q --> R[下次可恢复长会话]
    
    style E fill:#e1f5e1
    style F fill:#e1f5e1
    style Q fill:#ffe1e1
```

**核心特性**:

- **本地检索**: `KnowledgeSearchService` 对词项覆盖、短语、标题、正文和元数据匹配计分，再结合来源可信度、题目核验状态排序；当前该实现不是 BM25 或 embedding 检索。
- **可选查询扩展**: `modelAssistedSearchEnabled` 默认关闭。启用后，`HybridKnowledgeSearchService` 对原查询及模型改写逐个执行同一个词法搜索，再用 RRF 融合；扩展提供方抛错时回退到原查询。`localSemantic` 是可选查询来源类型，不能据此认定已接入本地向量模型。
- **问答上下文**: `knowledgeAnswerGroundedContextProvider` 跟随列表当前展示的搜索分支：已完成的 `augmented` 报告使用融合排名，否则使用原查询词法结果。等待改写或回退时仍可使用本地命中；改写完成及偏好变更后上下文随 provider 更新。选择出的片段仍须通过本地来源记录、正文及引用边界检查，模型改写只提供查询文本。
- **检查点恢复**: 支持长会话中断后继续
- **多模式辅导**:
  - 知识问答: 基于知识库回答 + 引用链
  - 项目面试: 引导式提问帮助理解代码
  - 苏格拉底式: 不直接给答案,反问启发
  - 编程实践: 生成代码练习题 + 自动评测

**涉及文件**:
- `lib/services/agent/learning_agent_runtime.dart`
- `lib/services/agent/learning_agent_planner_service.dart`
- `lib/services/agent/hybrid_knowledge_search_service.dart`
- `lib/services/agent/knowledge_search_service.dart`
- `lib/services/agent/model_search_query_variant_provider.dart`
- `lib/services/agent/search_preferences.dart`
- `lib/core/providers/providers.dart`（`knowledgeHybridSearchReportProvider` 与 `knowledgeAnswerGroundedContextProvider`）
- `lib/services/agent/interviewer_service.dart`
- `lib/services/agent/learning_agent_checkpoint_store.dart`

---

### 4. 复习调度流程 (Review Scheduling)

```mermaid
graph TD
    A[QuizScreen 获得正确或错误判定] --> B[QuizOperations.saveAnswer]
    B --> C[QuizPersistenceService.saveAnswer]
    C --> D[答案事务：游戏化、复习字段、知识点掌握度、操作凭据]
    D --> E[提交成功后返回保存结果]
    E --> F[QuizOperations 刷新共享状态]
    F --> G[首页读取当前待复习队列与统计]

    H[用户完成本轮答题] --> I[QuizOperations.saveCompletion]
    I --> J[QuizPersistenceService.saveCompletion]
    J --> K[完成事务：奖励、完美计数、题包结果、操作凭据]
    K --> E

    style D fill:#e1f5e1
    style K fill:#e1f5e1
```

**保存与刷新边界**:

- `saveAnswer` 接收布尔 `isCorrect`。首次保存会在事务中重新读取题目，确认它仍为 `verified`，且题目内容、答案、来源状态等与已判定输入一致；复习元数据可以在两次读取之间更新。
- 答案事务一并提交打卡、XP/心数、累计答对、题目复习字段、知识点掌握度和操作凭据。调度与掌握度分别使用 `ReviewSchedulerService.reviewedQuestion` 和 `MasteryService.questionAttemptResult` 的纯计算结果。首次提交后的复习事件尽力记录，事件失败不会把已接受的保存改为失败。
- `saveCompletion` 使用另一个事务提交完成奖励、完美次数、恢复心数及凭据；提供 `deckId` 时同时更新该题包的掌握度和 `StudyRecord`。记录 ID 为 `<deckId>_record`，只保留该题包最近一次完成结果。随机练习的 `deckId` 为 null，不创建题包记录。
- 同一操作 ID 和相同输入重试返回已提交的结果，重复使用 ID 提交不同输入会被拒绝。凭据不保存题干、用户作答或来源正文；它可以在数据库重开后重放，当前没有自动恢复未完成答题页面的跨进程机制。schema v24 的保存、迁移和备份边界见 [数据模型当前说明](./DATA_MODEL.md)。
- `QuizOperations` 在保存成功后刷新共享 providers，答题页面退出后仍然有效；所属 provider 释放后跳过刷新，已接受的保存可以完成。当前全局统计重新从存储读取，完成页奖励明细使用本次回执的快照。统计读取失败不会撤销已保存的结果。

**题目复习字段**:

`reviewedQuestion` 设置 `lastReviewedAt = now`，再从本次更新前的题目计算 `nextReviewAt`。`ease` 默认 1.0，`lapseCount` 默认 0：

| 字段 | 答对 | 答错 |
| --- | --- | --- |
| `ease` | 原值 + 0.12，限制在 [0.6, 2.5] | 原值 - 0.2，限制在 [0.6, 2.5] |
| `lapseCount` | 保持原值 | 原值 + 1 |
| `nextReviewAt` | 按下面的间隔公式计算 | `now + Duration(days: 1)` |

`ReviewSchedulerService._nextReviewAt` 的实际计算为：

```dart
static DateTime _nextReviewAt(
  Question question,
  bool isCorrect,
  DateTime now,
) {
  if (!isCorrect) return now.add(const Duration(days: 1));

  final difficultyPenalty = (question.difficulty - 1).clamp(0, 4);
  final lapsePenalty = question.lapseCount.clamp(0, 4);
  final intervalDays =
      (1 + question.ease * 2.2 - difficultyPenalty - lapsePenalty)
          .round()
          .clamp(1, 14)
          .toInt();
  return now.add(Duration(days: intervalDays));
}
```

公式使用更新前的 `ease` 和 `lapseCount`，不依赖距上次复习的天数。默认 `ease=1.0`、`difficulty=1`、`lapseCount=0` 的题目首次答对时，间隔为 3 天，同时 ease 更新为 1.12；答错时为 1 天，ease 更新为 0.8。

**知识点掌握度**:

`MasteryService.questionAttemptResult` 将已有知识点的 `masteryLevel` 向本次目标值平滑更新，四舍五入后限制在 [0, 100]：

```dart
final target = isCorrect ? 82 : 32;
final weight = isCorrect ? 0.24 : 0.34;
final updated =
    (point.masteryLevel + (target - point.masteryLevel) * weight)
        .round()
        .clamp(0, 100)
        .toInt();
```

例如原掌握度为 40，答对后为 50，答错后为 37。题目没有关联知识点或该知识点已不存在时，保存题目复习结果而不更新知识点掌握度。

**今日队列与练习范围**:

1. 只纳入 `sourceStatus == verified` 且 `nextReviewAt` 为空或早于次日 00:00 的题目；按知识点分组，缺少知识点 ID 或无法读取知识点的题目不进入队列。逾期数只计算 `nextReviewAt` 早于当日 00:00 的题目。
2. 知识点优先级为 `100 - masteryLevel + interviewRelevance * 2 + questionCount * 6 + overdueCount * 18`，按优先级降序、同分时按标题升序排列。`getTodayReviewQueue` 默认最多返回 12 个知识点条目。
3. 题目按 `nextReviewAt` 升序排列（空值按 Unix epoch 比较），相同时间按难度降序排列。`getTodayReviewQuestions(limit: 10)` 先选最多 10 个知识点条目，再合并题目、按上述题目规则排序，最终取最多 10 题。因此首页队列中的总题数可能大于一次练习的题数。

**涉及文件**:
- [quiz_persistence_service.dart](../../lib/services/quiz_persistence_service.dart)：`saveAnswer`、`saveCompletion` 和幂等凭据。
- [providers.dart](../../lib/core/providers/providers.dart)：`QuizOperations`、统计刷新及队列 providers。
- [review_scheduler_service.dart](../../lib/services/scheduling/review_scheduler_service.dart)：复习字段、队列筛选和排序。
- [mastery_service.dart](../../lib/services/scheduling/mastery_service.dart)：`questionAttemptResult`。
- [question.dart](../../lib/data/models/question.dart)：复习字段与默认值。
- [study_record.dart](../../lib/data/models/study_record.dart)：题包最近一次完成结果。
- [quiz_screen.dart](../../lib/features/learning/quiz_screen.dart)：判定、保存重试及完成页快照。

---

## 数据流向总览

```
用户上传文档
    ↓
[Semantic Chunker] 切分保留语义
    ↓
[Source + SourceChunk] 存储
    ↓
[AI Tasks] 提取知识点 → 生成题目
    ↓
[Citation Verification] 模型预核验，草稿保持 pending / noSource
    ↓
[项目导入：Question Validator] 本地规则检查并追加警告；文本导入跳过
    ↓
[KnowledgeReviewScreen] 人工审核
    ↓
[Question 题库] 保存
    ↓
[QuizScreen + QuizOperations] 判定并提交答案
    ↓
[QuizPersistenceService.saveAnswer] 同一事务保存奖励、复习、掌握度和凭据
    ↓
[QuizOperations] 保存成功后刷新共享状态
    ↓
[主页待复习队列与统计] 读取当前已提交状态
```

完成本轮答题时，另由 `saveCompletion` 事务保存完成奖励、题包最近结果和凭据，再触发对应共享状态刷新，详见上面的复习调度流程。

---

## 技术栈

### 前端
- **Flutter 3.x**: 跨平台 UI 框架
- **Riverpod**: 状态管理
- **Shared Preferences**: 本地配置存储
- **SQLite**: 本地数据库

### AI 层
- **OpenAI-compatible API**: 通过用户配置的 Base URL、模型和协议调用模型服务商
- **Prompt Engineering**: 结构化输出 + Few-shot examples
- **Citation Verification**: 通过 `chatCompletion` 获取并解析 JSON 预核验结果

### 后端(可选)
- **当前版本**: 学习内容与产品事件默认本地存储；主动 AI 任务会向用户选择的模型服务商发送所需片段
- **未来扩展**: Supabase / Firebase 同步

---

## 核心设计决策

### 为什么选择本地优先?
- ✅ 隐私保护: 学习内容默认保存在本地，AI 发送边界由用户主动配置和触发
- ✅ 离线可用: 除 AI 调用外都可离线
- ✅ 快速响应: 无网络延迟
- ⚠️ 代价: 需要用户自行备份

### 为什么不用向量数据库?
- 当前搜索从本地来源、片段、知识点和题目构建语料，在内存中进行词法评分，无需单独部署搜索服务。
- 可选模型查询扩展复用同一词法搜索并融合排名，当前这条路径不依赖向量数据库。
- 这里描述实现边界；搜索容量、耗时和相关性仍需对应数据集的测量，不能从服务名称推导性能或 embedding 能力。

### 为什么要 Citation Verification?
- **核心问题**: LLM 生成的"知识点"可能是幻觉
- **解决方案**: 强制 AI 引用具体 chunk,然后验证引用有效性
- **效果**: 大幅降低错误知识进入题库的概率

### 为什么新增 Question Validator?
- **作用**: 在项目导入中，以可重复的本地规则补充模型引用预核验，发现缺少原文支持的数字、答案、代码或关系等候选问题。
- **边界**: 模型预核验也会判断引用是否支持答案；本地质量检查是补充规则，不能取代模型判断或人工审核。
- **处理结果**: 项目导入追加问题提示和规则置信度，不更改审核状态。题目是否保存为 `verified` 由审核决策与有效引用共同决定。

---

## 扩展点设计

### 1. 自定义 Chunking 策略
```dart
abstract class ChunkStrategy {
  List<SourceChunk> chunk(String content, String locator);
}

class CustomPDFChunker implements ChunkStrategy {
  // 用户可实现自己的 PDF 切分逻辑
}
```

### 2. 自定义 AI Provider
```dart
abstract class AIService {
  Future<String> complete(String prompt);
}

class CustomAIService implements AIService {
  // 支持替换为本地模型/其他 API
}
```

### 3. 插件系统(规划中)
```dart
abstract class IngestionPlugin {
  bool canHandle(File file);
  List<SourceChunk> process(File file);
}

// 社区可贡献:
// - NotionImporter
// - ObsidianSyncPlugin
// - AnkiExportPlugin
```

---

## 性能考量

### 当前瓶颈
- **AI 调用延迟**: 生成 10 道题 ~30-60 秒
- **大文档导入**: 1000+ 行 Markdown ~5-10 秒

### 优化方向
- [ ] 批量 AI 调用(并发请求)
- [ ] 增量更新(只处理变更的 chunks)
- [ ] 本地缓存 AI 响应

### 可扩展性
- **SQLite 性能**: 支持到 100k+ questions 无压力
- **搜索性能**: 10k chunks 内存检索 <100ms
- **超过 10k chunks**: 考虑切换到 Meilisearch / Typesense

---

## 下一步阅读

- [数据模型详解](./DATA_MODEL.md)
- [AI Pipeline 设计](./AI_PIPELINE.md)
- [快速开始指南](../guides/QUICK_START.md)
