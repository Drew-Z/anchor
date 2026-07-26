# AI Pipeline 设计

## 概述

本文档详细说明多多学习中所有 AI Tasks 的设计,包括:
- 输入输出 Schema
- Prompt 工程策略
- 防幻觉机制
- 错误处理

---

## AI Task 架构

### 通用模式

所有 AI Task 遵循统一接口:

```dart
abstract class AITask<TInput, TOutput> {
  final OpenAIService openaiService;
  
  AITask(this.openaiService);
  
  // 子类实现
  String get systemPrompt;
  String buildUserPrompt(TInput input);
  TOutput parseResponse(String response);
  
  // 统一执行逻辑
  Future<TaskResult<TOutput>> run(TInput input) async {
    try {
      final userPrompt = buildUserPrompt(input);
      final response = await openaiService.complete(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
      );
      final output = parseResponse(response);
      return TaskResult.success(output);
    } catch (e) {
      return TaskResult.failure(e.toString());
    }
  }
}
```

**设计优势**:
- 统一错误处理
- 易于测试(Mock OpenAIService)
- 可观测性(日志/监控)

---

## 1. KnowledgeExtractionTask

**功能**: 从文档块中提取结构化知识点。

### 输入 Schema

```dart
class KnowledgeExtractionInput {
  final List<SourceChunk> chunks;
  final int maxKnowledgePoints;  // 限制数量,避免过度提取
}
```

### 输出 Schema

```dart
class KnowledgeExtractionOutput {
  final List<KnowledgePointDraft> knowledgePoints;
}

class KnowledgePointDraft {
  final String title;              // "StatefulWidget 的生命周期"
  final String description;        // 详细描述
  final String category;           // "核心概念"/"API"/"最佳实践"
  final List<String> citedChunkIds; // 引用的 chunk IDs
}
```

### System Prompt

```
你是一个专业的技术内容分析专家。你的任务是从给定的文档块中提取关键知识点。

要求:
1. 每个知识点必须是独立的、可学习的概念
2. 标题简洁明确,描述详细准确
3. 必须引用具体的文档块 ID(格式: chunk_xxx)
4. 分类到: 核心概念/API 用法/最佳实践/常见陷阱 之一
5. 避免重复和过于细碎的知识点

输出 JSON 格式:
{
  "knowledgePoints": [
    {
      "title": "...",
      "description": "...",
      "category": "...",
      "citedChunkIds": ["chunk_xxx", "chunk_yyy"]
    }
  ]
}
```

### User Prompt 构建

```dart
String buildUserPrompt(KnowledgeExtractionInput input) {
  final chunksText = input.chunks
      .map((c) => 'ID: ${c.id}\nLocator: ${c.locator}\nContent:\n${c.content}\n')
      .join('\n---\n');
  
  return '''
请从以下文档块中提取最多 ${input.maxKnowledgePoints} 个关键知识点:

$chunksText

要求:
- 优先提取核心概念和重要 API
- 每个知识点必须引用至少一个 chunk ID
- 如果某个概念在多个 chunks 中出现,引用所有相关 chunks
''';
}
```

### 防幻觉策略

1. **强制引用**: Prompt 中明确要求引用 chunk ID
2. **引用验证**: 解析后检查 citedChunkIds 是否有效
   ```dart
   TOutput parseResponse(String response) {
     final json = jsonDecode(response);
     final drafts = (json['knowledgePoints'] as List)
         .map((e) => KnowledgePointDraft.fromJson(e))
         .toList();
     
     // 验证引用
     for (final draft in drafts) {
       for (final chunkId in draft.citedChunkIds) {
         if (!input.chunks.any((c) => c.id == chunkId)) {
           throw ValidationError('Invalid chunk ID: $chunkId');
         }
       }
     }
     
     return KnowledgeExtractionOutput(knowledgePoints: drafts);
   }
   ```

---

## 2. ConceptPrerequisiteTask

**功能**: 推理知识点之间的前置依赖关系。

### 输入 Schema

```dart
class ConceptPrerequisiteInput {
  final List<KnowledgePoint> knowledgePoints;
}
```

### 输出 Schema

```dart
class ConceptPrerequisiteOutput {
  final List<PrerequisitePair> prerequisites;
}

class PrerequisitePair {
  final String knowledgePointId;    // 当前知识点
  final String prerequisiteId;      // 前置知识点
  final String reason;              // 原因说明
}
```

### System Prompt

```
你是一个教学设计专家。给定一组知识点,分析它们之间的学习顺序依赖。

判断标准:
- A 依赖 B: 理解 A 需要先理解 B
- 例如: "async/await" 依赖 "Future 基础"
- 例如: "Provider 状态管理" 依赖 "InheritedWidget"

要求:
1. 只标记直接依赖(不需要传递闭包)
2. 避免循环依赖
3. 给出简短的原因说明

输出 JSON:
{
  "prerequisites": [
    {
      "knowledgePointId": "kp_A",
      "prerequisiteId": "kp_B",
      "reason": "..."
    }
  ]
}
```

### 循环依赖检测

```dart
TOutput parseResponse(String response) {
  final json = jsonDecode(response);
  final pairs = (json['prerequisites'] as List)
      .map((e) => PrerequisitePair.fromJson(e))
      .toList();
  
  // 检查循环依赖
  final graph = <String, Set<String>>{};
  for (final pair in pairs) {
    graph.putIfAbsent(pair.knowledgePointId, () => {})
        .add(pair.prerequisiteId);
  }
  
  if (_hasCycle(graph)) {
    throw ValidationError('Circular dependency detected');
  }
  
  return ConceptPrerequisiteOutput(prerequisites: pairs);
}

bool _hasCycle(Map<String, Set<String>> graph) {
  final visited = <String>{};
  final recStack = <String>{};
  
  for (final node in graph.keys) {
    if (_dfs(node, graph, visited, recStack)) {
      return true;
    }
  }
  return false;
}
```

---

## 3. QuestionGenerationTask

**功能**: 从知识点生成多样化练习题。

### 输入 Schema

```dart
class QuestionGenerationInput {
  final List<KnowledgePoint> knowledgePoints;
  final List<SourceChunk> sourceChunks;
  final int questionCount;
  final List<QuestionType> allowedTypes; // 允许的题型
}
```

### 输出 Schema

```dart
class QuestionGenerationOutput {
  final List<QuestionDraft> questions;
}

class QuestionDraft {
  final String knowledgePointId;
  final QuestionType type;
  final String content;            // 题干
  final List<String> options;      // 选择题选项
  final String answer;             // 正确答案
  final String explanation;        // 解析
  final int difficulty;            // 1-5
  final List<String> citedChunkIds; // 引用的 chunks
  
  // 匹配题专用
  final List<String>? matchLeft;
  final List<String>? matchRight;
}
```

### System Prompt

```
你是一个专业出题专家。根据知识点和源文档生成高质量练习题。

题型要求:
- singleChoice: 单选题,4个选项,只有1个正确
- multipleChoice: 多选题,4-5个选项,2-3个正确
- fillBlank: 填空题,答案简短明确
- trueFalse: 判断题,陈述清晰
- matching: 匹配题,左右各3-5项

质量要求:
1. 题干清晰无歧义
2. 选项设计有干扰性(不能一眼看出答案)
3. 解析必须引用源文档,格式: [chunk_xxx]
4. 难度分级:
   - 1-2: 记忆类(定义、概念)
   - 3: 理解类(原理、区别)
   - 4-5: 应用类(代码分析、场景选择)

输出 JSON:
{
  "questions": [
    {
      "knowledgePointId": "...",
      "type": "singleChoice",
      "content": "...",
      "options": ["A. ...", "B. ...", "C. ...", "D. ..."],
      "answer": "A",
      "explanation": "...[chunk_xxx]...",
      "difficulty": 3,
      "citedChunkIds": ["chunk_xxx"]
    }
  ]
}
```

### Few-shot Examples

```dart
String buildUserPrompt(QuestionGenerationInput input) {
  return '''
知识点列表:
${input.knowledgePoints.map((kp) => '- ID: ${kp.id}, Title: ${kp.title}').join('\n')}

源文档:
${input.sourceChunks.map((c) => 'ID: ${c.id}\n${c.content}').join('\n---\n')}

请生成 ${input.questionCount} 道练习题,要求:
- 题型分布: 50% 单选, 30% 多选, 20% 填空/判断
- 难度分布: 30% 简单, 50% 中等, 20% 困难
- 每道题的 explanation 必须引用具体 chunk ID

参考示例:
{
  "knowledgePointId": "kp_001",
  "type": "singleChoice",
  "content": "以下关于 StatefulWidget 生命周期的说法,正确的是?",
  "options": [
    "A. initState() 可以多次调用",
    "B. dispose() 在 Widget 销毁时调用",
    "C. build() 只调用一次",
    "D. setState() 可以在 dispose() 后调用"
  ],
  "answer": "B",
  "explanation": "根据官方文档 [chunk_flutter_lifecycle_5],dispose() 方法在 State 对象被永久移除时调用,用于释放资源。",
  "difficulty": 2,
  "citedChunkIds": ["chunk_flutter_lifecycle_5"]
}
''';
}
```

### 防幻觉策略

1. **引用强制**: explanation 必须包含 `[chunk_xxx]` 格式
2. **引用提取**: 正则提取所有 chunk ID
   ```dart
   List<String> _extractChunkIds(String explanation) {
     final pattern = RegExp(r'\[chunk_([^\]]+)\]');
     return pattern.allMatches(explanation)
         .map((m) => 'chunk_${m.group(1)}')
         .toList();
   }
   ```
3. **选项合理性检查**: 
   - 单选题必须恰好4个选项
   - 答案必须在选项中

---

## 4. CitationVerificationTask

**功能**: 验证题目的引用是否支持其结论。

### 输入 Schema

```dart
class CitationVerificationInput {
  final Question question;
  final List<SourceChunk> citedChunks;
}
```

### 输出 Schema

```dart
class CitationVerificationOutput {
  final bool isVerified;
  final double confidence;         // 0.0-1.0
  final List<String> issues;       // 发现的问题
}
```

### System Prompt

```
你是一个严格的事实核查专家。判断题目的引用是否充分支持其答案和解析。

核查清单:
1. 引用的文档中是否包含题目所述的信息?
2. 答案是否与引用内容一致?
3. 解析的推理是否基于引用,还是引入了外部知识?

判断标准:
- verified (confidence >= 0.8): 引用充分,事实准确
- suspicious (0.5 <= confidence < 0.8): 引用部分支持,但有疑点
- invalid (confidence < 0.5): 引用不支持或答案错误

输出 JSON:
{
  "isVerified": true,
  "confidence": 0.9,
  "issues": []
}

或

{
  "isVerified": false,
  "confidence": 0.4,
  "issues": [
    "引用的 chunk_5 中未提到 'dispose 方法',但题目声称来自该文档",
    "答案 'A' 与 chunk_3 中的描述矛盾"
  ]
}
```

### User Prompt 构建

```dart
String buildUserPrompt(CitationVerificationInput input) {
  final q = input.question;
  final chunksText = input.citedChunks
      .map((c) => 'ID: ${c.id}\nContent:\n${c.content}')
      .join('\n---\n');
  
  return '''
题目:
类型: ${q.type}
题干: ${q.content}
选项: ${q.options.join(', ')}
答案: ${q.answer}
解析: ${q.explanation}

引用的文档:
$chunksText

请核查:
1. 这些文档是否支持题目的答案?
2. 解析中的推理是否基于引用的文档?
3. 是否存在事实性错误?
''';
}
```

---

## 5. QuestionValidator (新增)

**功能**: 二次核验生成的题目事实准确性。

### 与 CitationVerificationTask 的区别

| 维度 | CitationVerificationTask | QuestionValidator |
|------|--------------------------|-------------------|
| 时机 | 题目生成后 | Citation 验证后 |
| 目标 | 验证"有引用" | 验证"引用正确" |
| 检查内容 | chunk 是否存在 | 答案是否与 chunk 一致 |

### 输入 Schema

```dart
class QuestionValidationInput {
  final Question question;
  final List<SourceChunk> sourceChunks; // 所有可用 chunks
}
```

### 输出 Schema

```dart
class QuestionValidationResult {
  final String questionId;
  final bool isValid;
  final double confidence;
  final List<String> issues;
}
```

### System Prompt

```
你是一个事实核查专家。对比题目和源文档,判断题目是否存在事实性错误。

核查重点:
1. 答案的事实性: 题目声称的答案是否与文档描述一致?
2. 选项的合理性: 错误选项是否真的错误?(不能有模棱两可的选项)
3. 数字/名词的准确性: 如果涉及数量、名称,是否与文档完全一致?

示例问题:
- 题目说"有3个核心组件",但文档只提到2个 → 事实错误
- 题目引用 chunk_A,但答案来自 chunk_B 的内容 → 引用错误
- 选项 C 说"从不使用",但文档说"很少使用" → 表述过于绝对

置信度评分:
- 1.0: 完全准确,无问题
- 0.8-0.9: 基本准确,有微小瑕疵
- 0.5-0.7: 有明显问题,但不严重
- < 0.5: 严重错误,不应进入题库

输出 JSON:
{
  "isValid": false,
  "confidence": 0.6,
  "issues": [
    "答案中的数量'3个'与文档'2个核心组件'不符",
    "选项B表述过于绝对"
  ]
}
```

---

## 6. ProjectUnderstandingTask

**功能**: 生成项目代码的理解大纲。

### 输入 Schema

```dart
class ProjectUnderstandingInput {
  final List<SourceChunk> codeChunks;
  final String projectName;
}
```

### 输出 Schema

```dart
class ProjectUnderstandingOutput {
  final List<UnderstandingUnit> units;
}

class UnderstandingUnit {
  final String title;              // "项目架构"
  final String summary;            // 概要描述
  final List<String> keyPoints;    // 关键点列表
  final List<String> citedChunkIds;
}
```

### System Prompt

```
你是一个代码架构分析专家。分析项目代码,生成学习大纲。

输出维度:
1. 项目架构: 整体结构、技术栈、设计模式
2. 核心模块: 每个主要模块的职责
3. 数据流: 数据如何在模块间流动
4. 关键实现: 值得学习的代码技巧

每个维度:
- title: 简短标题
- summary: 1-2 句话概括
- keyPoints: 3-5 个要点
- citedChunkIds: 相关代码块

输出 JSON:
{
  "units": [
    {
      "title": "项目架构",
      "summary": "采用 MVVM 架构...",
      "keyPoints": [
        "使用 Riverpod 管理状态",
        "Repository 层封装数据访问"
      ],
      "citedChunkIds": ["chunk_main", "chunk_providers"]
    }
  ]
}
```

---

## 7. AnswerEvaluationTask

**功能**: 评估用户对面试问题的回答。

### 输入 Schema

```dart
class AnswerEvaluationInput {
  final String aiQuestion;
  final String userAnswer;
  final List<SourceChunk> relevantChunks;
}
```

### 输出 Schema

```dart
class AnswerEvaluationOutput {
  final bool isCorrect;
  final String feedback;           // 评价和建议
  final List<String> missingPoints; // 遗漏的要点
  final String? nextQuestion;      // 后续问题(苏格拉底式)
}
```

### System Prompt

```
你是一个苏格拉底式导师。评估学生的回答,但不直接给出答案。

评估步骤:
1. 判断回答是否触及核心要点
2. 指出遗漏的关键信息
3. 通过追问引导学生自己发现答案

反馈风格:
- 肯定正确的部分
- 指出不足,但不直接纠正
- 提出启发式问题,而不是直接讲解

输出 JSON:
{
  "isCorrect": false,
  "feedback": "你提到了状态管理,这是对的。但你有没有想过,为什么 Riverpod 比 Provider 更好?",
  "missingPoints": ["Provider 的局限性", "Riverpod 的编译时安全"],
  "nextQuestion": "试着对比一下 Provider 和 Riverpod 在依赖注入上的区别?"
}
```

---

## 8. KnowledgeAnswerTask

**功能**: 基于知识库回答用户问题。

### 输入 Schema

```dart
class KnowledgeAnswerInput {
  final String userQuestion;
  final List<SourceChunk> searchResults; // 检索到的相关 chunks
}
```

### 输出 Schema

```dart
class KnowledgeAnswerOutput {
  final String answer;
  final List<String> citedChunkIds;
}
```

### System Prompt

```
你是一个知识库助手。基于给定的文档回答用户问题。

要求:
1. 答案必须基于提供的文档,不要引入外部知识
2. 引用具体的文档块,格式: [chunk_xxx]
3. 如果文档中没有相关信息,明确说"文档中未提及"
4. 语言简洁友好,避免照搬原文

输出 JSON:
{
  "answer": "根据文档 [chunk_5],StatefulWidget 通过 State 对象管理状态...",
  "citedChunkIds": ["chunk_5", "chunk_7"]
}
```

---

## AI Pipeline 最佳实践

### 1. Prompt 设计原则

- **明确输出格式**: 要求 JSON,给出 schema
- **Few-shot Examples**: 复杂任务提供2-3个示例
- **约束条件**: 明确"不要做什么"
- **评分标准**: 需要判断时给出具体标准

### 2. 错误处理

```dart
Future<TaskResult<T>> run(Input input) async {
  try {
    final response = await openaiService.complete(...);
    
    // JSON 解析失败重试
    try {
      return TaskResult.success(parseResponse(response));
    } catch (e) {
      if (retryCount < 2) {
        return run(input); // 重试一次
      }
      return TaskResult.failure('JSON parsing failed: $e');
    }
  } on TimeoutException {
    return TaskResult.failure('AI request timeout');
  } on OpenAIException catch (e) {
    return TaskResult.failure('OpenAI error: ${e.message}');
  }
}
```

### 3. 成本优化

- **模型选择**:
  - GPT-4: 复杂推理(ConceptPrerequisite, ProjectUnderstanding)
  - GPT-3.5-turbo: 简单任务(QuestionGeneration, CitationVerification)
  
- **批量处理**: 一次生成10道题,而不是调用10次

- **缓存**: 相同输入缓存结果
  ```dart
  final _cache = <String, TaskResult>{};
  
  Future<TaskResult<T>> run(Input input) async {
    final key = input.hashCode.toString();
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }
    final result = await _runInternal(input);
    _cache[key] = result;
    return result;
  }
  ```

### 4. 可观测性

```dart
Future<TaskResult<T>> run(Input input) async {
  final stopwatch = Stopwatch()..start();
  
  try {
    final result = await _runInternal(input);
    
    // 记录指标
    analyticsService.logAITask(
      taskName: runtimeType.toString(),
      duration: stopwatch.elapsedMilliseconds,
      success: result.isSuccess,
      tokenCount: result.tokenCount,
    );
    
    return result;
  } finally {
    stopwatch.stop();
  }
}
```

---

## 下一步阅读

- [系统架构概览](./SYSTEM_OVERVIEW.md)
- [数据模型设计](./DATA_MODEL.md)
- [自定义 Prompt 指南](../guides/CUSTOMIZE_PROMPTS.md)
