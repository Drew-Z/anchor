# 数据模型设计

## ER 图

```mermaid
erDiagram
    Source ||--o{ SourceChunk : contains
    SourceChunk ||--o{ KnowledgePointSource : cited_by
    KnowledgePoint ||--o{ KnowledgePointSource : has
    KnowledgePoint ||--o{ Question : generates
    SourceChunk ||--o{ Question : cited_by
    Question ||--o{ StudyRecord : answered
    KnowledgePoint ||--o{ KnowledgePointPrerequisite : requires
    
    Deck ||--o{ Question : contains
    
    LearningSession ||--o{ InterviewTurn : contains
    LearningSession ||--o{ TutorTurn : contains
    
    ProgrammingExercise ||--o{ ProgrammingExerciseAttempt : attempted
    
    Source {
        string id PK
        string type
        string title
        string metadata
        datetime created_at
    }
    
    SourceChunk {
        string id PK
        string source_id FK
        int chunk_index
        text content
        string locator
        string relative_path
        int start_line
        int end_line
        string content_hash
        datetime created_at
    }
    
    KnowledgePoint {
        string id PK
        string title
        text description
        string category
        datetime created_at
    }
    
    KnowledgePointSource {
        string id PK
        string knowledge_point_id FK
        string source_chunk_id FK
        string excerpt
        datetime created_at
    }
    
    Question {
        string id PK
        string deck_id FK
        string knowledge_point_id FK
        string type
        text content
        text options
        text answer
        text explanation
        int difficulty
        string source_status
        text citation_ids
        datetime last_reviewed_at
        datetime next_review_at
        float ease
        int lapse_count
    }
    
    StudyRecord {
        string id PK
        string question_id FK
        string user_answer
        bool is_correct
        int time_spent
        datetime created_at
    }
    
    Deck {
        string id PK
        string name
        text description
        datetime created_at
    }
```

---

## 核心表详解

### 1. Source (来源表)

存储导入的文档/项目元数据。

```dart
class Source {
  final String id;              // UUID
  final SourceType type;        // project/markdown/pdf
  final String title;           // 项目名或文档标题
  final Map<String, dynamic> metadata; // 扩展字段
  final DateTime createdAt;
}

enum SourceType {
  project,      // 代码项目
  markdown,     // Markdown 文档
  pdf,          // PDF 文档(未来支持)
  webpage,      // 网页抓取(未来支持)
}
```

**设计要点**:
- `metadata` 存储:
  - 项目: `{projectPath, language, fileCount}`
  - 文档: `{filePath, wordCount, author}`
- 一个 Source 可以包含多个文件(如整个代码项目)

---

### 2. SourceChunk (文档块表)

文档/代码的最小可引用单元。

```dart
class SourceChunk {
  final String id;              // source_id + chunk_index
  final String sourceId;        // 外键 → Source
  final int chunkIndex;         // 在 Source 内的序号
  final String content;         // 实际内容(纯文本)
  final String locator;         // 精确定位符
  final String? relativePath;   // 文件路径(项目导入用)
  final int? startLine;         // 起始行号
  final int? endLine;           // 结束行号
  final String contentHash;     // SHA256,用于检测更新
  final DateTime createdAt;
}
```

**Locator 格式示例**:
```
README.md:## 快速开始           (Markdown 标题定位)
lib/main.dart:15-42            (代码行号定位)
tutorial.pdf:第3章 异步编程      (PDF 章节定位)
```

**设计要点**:
- `locator` 是可读的人类友好定位符,显示在 UI 中
- `startLine/endLine` 用于代码高亮跳转
- `contentHash` 用于增量更新检测

---

### 3. KnowledgePoint (知识点表)

从文档中提取的知识点。

```dart
class KnowledgePoint {
  final String id;
  final String title;           // "Flutter 的 Widget 树机制"
  final String description;     // 详细描述
  final String? category;       // 分类(概念/API/最佳实践)
  final DateTime createdAt;
}
```

**示例**:
```json
{
  "id": "kp_001",
  "title": "StatefulWidget 的生命周期",
  "description": "StatefulWidget 通过 State 对象管理状态,生命周期包括 initState、build、dispose 等方法。",
  "category": "核心概念"
}
```

---

### 4. KnowledgePointSource (知识点引用表)

**关键表**: 实现知识点到源文档的可溯源链接。

```dart
class KnowledgePointSource {
  final String id;
  final String knowledgePointId;   // 外键 → KnowledgePoint
  final String sourceChunkId;      // 外键 → SourceChunk
  final String excerpt;            // 引用的具体文本片段
  final DateTime createdAt;
}
```

**示例**:
```json
{
  "id": "kps_001",
  "knowledgePointId": "kp_001",
  "sourceChunkId": "source_abc_chunk_5",
  "excerpt": "State 对象的生命周期从 initState() 开始..."
}
```

**设计要点**:
- 一个知识点可以有多个引用(从不同文档)
- `excerpt` 保存引用的具体文本,避免重新查询 chunk
- 用于生成 "查看来源" 功能

---

### 5. KnowledgePointPrerequisite (知识点依赖表)

```dart
class KnowledgePointPrerequisite {
  final String id;
  final String knowledgePointId;       // 当前知识点
  final String prerequisiteId;         // 前置知识点
  final String reason;                 // 为什么需要前置
  final DateTime createdAt;
}
```

**示例**:
```
"理解 StatefulWidget" 需要先理解 "Widget 基础"
原因: "StatefulWidget 是 Widget 的子类"
```

**用途**:
- 生成学习路径推荐
- 答题时提示 "可能需要先学习 X"

---

### 6. Question (题目表)

核心的练习题数据。

```dart
class Question {
  final String id;
  final String deckId;                 // 外键 → Deck
  final String? knowledgePointId;      // 外键 → KnowledgePoint
  final QuestionType type;             // 题型
  final String content;                // 题干
  final List<String> options;          // 选项(选择题用)
  final String answer;                 // 正确答案
  final String? explanation;           // 解析
  final int difficulty;                // 1-5
  final SourceStatus sourceStatus;     // verified/pending/no_source
  final List<String> citationIds;      // 引用的 chunk IDs
  
  // 间隔重复字段
  final DateTime? lastReviewedAt;
  final DateTime? nextReviewAt;
  final double ease;                   // 难度系数 0.5-3.0
  final int lapseCount;                // 累计错误次数
  
  // 匹配题专用
  final List<String>? matchLeft;
  final List<String>? matchRight;
}

enum QuestionType {
  singleChoice,    // 单选题
  multipleChoice,  // 多选题
  fillBlank,       // 填空题
  trueFalse,       // 判断题
  matching,        // 匹配题
  sorting,         // 排序题
}

enum SourceStatus {
  verified,        // 引用已核验
  pending,         // 待核验
  noSource,        // 无来源(用户手工创建)
}
```

**Citation 存储**:
```dart
citationIds: ["source_abc_chunk_3", "source_abc_chunk_7"]
```

**设计要点**:
- `sourceStatus` 区分 AI 生成(需核验) vs 用户创建
- `citationIds` JSON 数组,支持多个引用
- `ease` 初始值 1.0,每次正确 +0.1,错误 -0.2

---

### 7. StudyRecord (学习记录表)

```dart
class StudyRecord {
  final String id;
  final String questionId;          // 外键 → Question
  final String userAnswer;          // 用户的答案
  final bool isCorrect;             // 是否正确
  final int timeSpent;              // 答题用时(秒)
  final DateTime createdAt;
}
```

**用途**:
- 计算掌握度统计
- 生成学习曲线
- 识别常错题

---

### 8. Deck (卡组表)

```dart
class Deck {
  final String id;
  final String name;                // "Flutter 基础"
  final String? description;
  final DateTime createdAt;
}
```

**设计要点**:
- 一个 Deck 对应一个学习主题
- 导入项目时自动创建 Deck
- 用户可手动创建 Deck 并移动题目

---

## Agent 相关表

### 9. LearningSession (学习会话表)

```dart
class LearningSession {
  final String id;
  final LearningSessionType type;   // interview/tutor/knowledge_answer
  final String? knowledgePointId;   // 可选:关联的知识点
  final String? sourceId;           // 可选:关联的来源
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? completedAt;
}

enum LearningSessionType {
  interview,         // 项目代码面试
  tutor,             // 苏格拉底式辅导
  knowledgeAnswer,   // 知识问答
}
```

---

### 10. InterviewTurn / TutorTurn (对话轮次表)

```dart
class InterviewTurn {
  final String id;
  final String sessionId;           // 外键 → LearningSession
  final int turnIndex;              // 对话序号
  final String aiQuestion;          // AI 的问题
  final String? userAnswer;         // 用户的回答
  final String? aiEvaluation;       // AI 的评价
  final List<String> citedChunkIds; // 引用的 chunks
  final DateTime createdAt;
}

// TutorTurn 结构类似
class TutorTurn {
  final String id;
  final String sessionId;
  final int turnIndex;
  final String userQuestion;        // 用户的问题
  final String aiResponse;          // AI 的回答
  final List<String> citedChunkIds;
  final DateTime createdAt;
}
```

---

### 11. ProgrammingExercise (编程练习表)

```dart
class ProgrammingExercise {
  final String id;
  final String knowledgePointId;
  final String title;
  final String description;         // 题目描述
  final String starterCode;         // 起始代码
  final String expectedOutput;      // 预期输出
  final String? hint;
  final DateTime createdAt;
}
```

---

### 12. ProgrammingExerciseAttempt (编程练习尝试表)

```dart
class ProgrammingExerciseAttempt {
  final String id;
  final String exerciseId;
  final String userCode;            // 用户提交的代码
  final bool isPassed;              // 是否通过
  final String? feedback;           // AI 反馈
  final DateTime createdAt;
}
```

---

## 关键设计模式

### 1. Citation Chain (引用链)

```
用户点击题目的"查看来源"
  ↓
Question.citationIds: ["chunk_A", "chunk_B"]
  ↓
查询 SourceChunk 表
  ↓
显示:
  - chunk_A: lib/main.dart:15-42
  - chunk_B: README.md:## 快速开始
  ↓
用户点击 locator → 跳转到原文
```

### 2. Knowledge Graph (知识图谱)

```
KnowledgePoint "StatefulWidget"
  ↓ (has prerequisite)
KnowledgePoint "Widget 基础"
  ↓ (has source)
KnowledgePointSource
  ↓ (cites)
SourceChunk "Flutter 官方文档 chunk_5"
```

### 3. Mastery Tracking (掌握度追踪)

```sql
-- 查询某个知识点的掌握度
SELECT 
  kp.title,
  COUNT(sr.id) as total_attempts,
  SUM(CASE WHEN sr.is_correct THEN 1 ELSE 0 END) as correct_count,
  AVG(q.ease) as avg_ease
FROM knowledge_points kp
JOIN questions q ON q.knowledge_point_id = kp.id
LEFT JOIN study_records sr ON sr.question_id = q.id
WHERE kp.id = ?
GROUP BY kp.id
```

---

## 索引设计

### 高频查询索引

```sql
-- 1. 查询某个 Source 的所有 Chunks
CREATE INDEX idx_source_chunks_source_id 
ON source_chunks(source_id, chunk_index);

-- 2. 查询待复习的题目
CREATE INDEX idx_questions_next_review 
ON questions(next_review_at, deck_id);

-- 3. 查询某个知识点的题目
CREATE INDEX idx_questions_knowledge_point 
ON questions(knowledge_point_id);

-- 4. 查询某个题目的学习记录
CREATE INDEX idx_study_records_question 
ON study_records(question_id, created_at DESC);

-- 5. 查询某个会话的对话轮次
CREATE INDEX idx_interview_turns_session 
ON interview_turns(session_id, turn_index);
```

---

## 数据完整性约束

### 1. Citation 完整性

```dart
// 保存 Question 时校验 citationIds
for (final chunkId in question.citationIds) {
  final chunk = await sourceChunkRepo.getById(chunkId);
  if (chunk == null) {
    throw ValidationError('Invalid citation: $chunkId');
  }
}
```

### 2. Prerequisite 无环检测

```dart
// 添加前置依赖时检查是否形成环
bool wouldCreateCycle(String from, String to) {
  final visited = <String>{};
  return _dfs(to, from, visited);
}
```

---

## 数据迁移策略

### Version 1 → Version 2 示例

```dart
// migration_002_add_validation_fields.dart
Future<void> migrate(Database db) async {
  await db.execute('''
    ALTER TABLE questions 
    ADD COLUMN validation_confidence REAL DEFAULT 1.0
  ''');
  
  await db.execute('''
    ALTER TABLE questions 
    ADD COLUMN validation_issues TEXT
  ''');
}
```

---

## 数据备份格式

### JSON Export 结构

```json
{
  "version": "1.0.0",
  "exportedAt": "2026-07-26T10:00:00Z",
  "sources": [...],
  "sourceChunks": [...],
  "knowledgePoints": [...],
  "knowledgePointSources": [...],
  "questions": [...],
  "studyRecords": [...]
}
```

**用途**:
- 用户自行备份数据
- 跨设备迁移
- 未来云同步功能

---

## 性能优化

### 1. 分页查询

```dart
// 大量 chunks 分页加载
Future<List<SourceChunk>> getChunksBySource(
  String sourceId, {
  int offset = 0,
  int limit = 100,
}) async {
  return await db.query(
    'source_chunks',
    where: 'source_id = ?',
    whereArgs: [sourceId],
    orderBy: 'chunk_index ASC',
    limit: limit,
    offset: offset,
  );
}
```

### 2. 缓存策略

```dart
// Riverpod 自动缓存
final sourceChunksProvider = FutureProvider.family<List<SourceChunk>, String>(
  (ref, sourceId) async {
    return sourceChunkRepo.getBySourceId(sourceId);
  },
);
```

---

## 下一步阅读

- [AI Pipeline 设计](./AI_PIPELINE.md)
- [系统架构概览](./SYSTEM_OVERVIEW.md)
