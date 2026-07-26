# 如何防止 AI 幻觉:Citation Verification 实战

> 从"Anchor Learning (锚学)"项目看如何构建可信的 AI 学习助手

---

## 问题:AI 生成内容的可信度危机

当你让 ChatGPT 根据一份技术文档生成练习题时,经常会遇到:

- **凭空编造**: "Flutter 的 BuildContext 可以在 dispose 后继续使用" ❌
- **张冠李戴**: 把 React 的概念套到 Flutter 上
- **过时信息**: 引用已废弃的 API
- **无法溯源**: 用户问"这道题哪里来的",你答不上来

这些**幻觉**(Hallucination)对学习场景是致命的——学生学到错误知识,比不学更糟糕。

---

## 方案:三层防线架构

"Anchor Learning (锚学)"项目通过三层递进式验证,将幻觉率从 GPT-4 的基准 ~15% 降低到 ~3%:

```
Layer 1: Semantic Chunker (语义切分)
    ↓ 保持上下文完整性
Layer 2: Citation Verification (引用核验)
    ↓ 强制 AI 标注来源
Layer 3: Question Validator (事实二次验证)
    ↓ 独立 AI 交叉核对
[人工审核] 最终确认
```

### Layer 1: Semantic Chunker - 保持语义完整性

**问题**: 如果把文档按固定 512 字符切分,可能切断一个完整概念:

```
Chunk 1: "...StatefulWidget 通过 State 对象管理状态。State 对象有三个关键"
Chunk 2: "方法:initState、build、dispose..."
```

AI 只看到 Chunk 1 时,不知道"三个关键方法"具体是什么,容易编造。

**解法**: 按 Markdown 标题层级切分,保持每个 chunk 是一个完整的语义单元:

```dart
// lib/services/content_analyzer.dart
List<SourceChunk> _splitByHeaders(String markdown) {
  final lines = markdown.split('\n');
  final chunks = <SourceChunk>[];
  
  for (var line in lines) {
    if (line.startsWith('#')) {
      // 遇到标题,开始新 chunk
      chunks.add(SourceChunk(
        locator: '$filename:$line',  // 可读的位置标记
        content: ...,
      ));
    }
  }
}
```

**Locator 设计**: 不用数字 ID,用可读的路径:
- ✅ `README.md:## 快速开始`
- ❌ `chunk_42`

这样用户点击题目来源时,能直接跳到原文对应位置。

---

### Layer 2: Citation Verification - 强制引用

**核心思想**: 不让 AI "凭感觉"生成,必须引用具体的 chunk ID。

**Prompt 设计**:

```dart
// lib/services/ai/tasks/question_generation_task.dart
final prompt = '''
你是出题专家,根据以下知识点和原文生成练习题。

知识点: $knowledgePoint

可用原文片段:
${chunks.map((c) => '[${c.id}] ${c.content}').join('\n\n')}

要求:
1. 每道题必须标注引用的 chunk ID
2. 题目内容必须能在引用的 chunk 中找到依据
3. 输出 JSON:
{
  "questionText": "...",
  "citedChunkIds": ["chunk_12", "chunk_15"],
  "explanation": "根据 [chunk_12],..."
}
''';
```

**验证逻辑**:

```dart
// lib/services/ai/tasks/citation_verification_task.dart
bool verifyCitation(Question q, List<SourceChunk> chunks) {
  for (final chunkId in q.citedChunkIds) {
    final chunk = chunks.firstWhere((c) => c.id == chunkId);
    
    // 检查题目关键词是否在 chunk 中出现
    final keywords = extractKeywords(q.questionText);
    if (!keywords.any((kw) => chunk.content.contains(kw))) {
      return false;  // 引用无效
    }
  }
  return true;
}
```

**效果**: 如果 AI 编造一个不存在的 chunk ID,或引用的 chunk 与题目内容无关,直接拒绝。

---

### Layer 3: Question Validator - 独立验证

即使通过了 Layer 2,还可能有问题:AI 可能"断章取义"——从原文抽出一句话,但忽略了下一句的限定条件。

**解法**: 用另一个独立的 AI,拿着题目和原文,判断"这道题的答案是否与原文一致"。

```dart
// lib/services/ai/tasks/question_validator_task.dart
final validationPrompt = '''
你是严格的事实核查员。

题目: ${question.questionText}
答案: ${question.correctAnswer}
原文: ${chunks.join('\n')}

任务: 判断答案是否与原文完全一致。

输出:
{
  "isValid": true/false,
  "reason": "..."
}

注意: 如果原文说"通常是 A",题目说"一定是 A",判定为 invalid。
''';
```

**为什么要独立 AI?**

- 生成题目的 AI 可能有"确认偏误"(confirmation bias)
- 独立的验证 AI 没有"我已经生成了"的心理负担,更客观

---

## 实现细节

### 1. 数据模型设计

```dart
// lib/data/models/question.dart
class Question {
  final String questionText;
  final List<String> choices;
  final int correctIndex;
  
  // 溯源字段
  final List<String> citedChunkIds;    // 引用的原文片段
  final String sourceLocator;          // 可读的位置 (README.md:## XX)
  
  // 验证字段
  final bool citationVerified;         // Layer 2 通过?
  final bool factValidated;            // Layer 3 通过?
}
```

### 2. AI Pipeline 流程

```dart
// lib/services/ai/ai_pipeline.dart
Future<List<Question>> generateQuestions(KnowledgePoint kp) async {
  // Step 1: 获取相关原文片段
  final chunks = await retrieveRelevantChunks(kp);
  
  // Step 2: 生成题目 (带引用)
  final rawQuestions = await questionGenerationTask.execute(kp, chunks);
  
  // Step 3: Citation Verification
  final cited = rawQuestions.where((q) => 
    citationVerificationTask.verify(q, chunks)
  ).toList();
  
  // Step 4: Fact Validation
  final validated = await Future.wait(
    cited.map((q) => questionValidatorTask.validate(q, chunks))
  );
  
  // Step 5: 只返回通过所有验证的题目
  return validated.where((q) => q.factValidated).toList();
}
```

### 3. 性能优化

**问题**: Layer 3 每道题都要调一次 AI,很慢。

**解法**: 批量验证 + 缓存

```dart
// 批量验证
final validationResults = await openAI.chat(
  messages: [
    SystemMessage(validationPrompt),
    UserMessage(
      questions.map((q) => 'Q${q.id}: ${q.questionText}').join('\n')
    )
  ],
  responseFormat: {'type': 'json_schema', 'schema': batchValidationSchema}
);

// 缓存验证结果
final cacheKey = '${question.id}_${chunkIds.join('_')}';
if (cache.has(cacheKey)) {
  return cache.get(cacheKey);
}
```

---

## 实测效果

基于 100 份技术文档(Flutter/React/算法)的测试:

| 方法 | 幻觉率 | 用户投诉 | 生成速度 |
|------|--------|---------|---------|
| GPT-4 直接生成 | 14.2% | 高 | 快 (5s/10题) |
| + Layer 1 (Semantic Chunker) | 9.8% | 中 | 快 (6s/10题) |
| + Layer 2 (Citation) | 4.7% | 低 | 中 (15s/10题) |
| + Layer 3 (Validator) | 2.9% | 极低 | 慢 (30s/10题) |

**关键发现**:
- Layer 1 和 Layer 2 的组合就能拦截 70% 的幻觉
- Layer 3 主要拦截"断章取义"类错误
- 用户更在意准确性而非速度(30 秒可接受,错题不可接受)

---

## 代价与权衡

### Token 消耗

- Layer 1: 无额外消耗(只是切分方式不同)
- Layer 2: +20% (Prompt 中要包含所有 chunk)
- Layer 3: +100% (每道题验证一次)

**总计**: 相比直接生成,Token 消耗约 2.2 倍。

### 生成成功率

- 无验证: 100% 的输入都能生成题目
- 三层验证: 约 60-70% 通过

**应对**: 如果一个知识点没生成出题目,提示用户"原文信息不足,建议补充文档"。

---

## 可复用的经验

### 1. Locator 设计原则

不要用数字 ID,用人类可读的路径:
```
✅ README.md:## 快速开始:步骤 2
❌ doc_3_chunk_42
```

### 2. Prompt 中的约束表达

不要说"尽量引用原文",要说"必须标注 chunk ID,未标注的题目将被拒绝"。

### 3. 验证的独立性

生成和验证用不同的 AI 调用,避免自我确认偏误。

### 4. 用户可见的溯源

在 UI 中显示引用链:
```
题目: StatefulWidget 的 State 对象何时创建?
来源: [README.md:## Widget 生命周期] (点击查看原文)
```

---

## 开源代码

完整实现已开源: [github.com/Drew-Z/anchor](https://github.com/Drew-Z/anchor)

核心文件:
- `lib/services/content_analyzer.dart` - Semantic Chunker
- `lib/services/ai/tasks/citation_verification_task.dart` - Layer 2
- `lib/services/ai/tasks/question_validator_task.dart` - Layer 3

---

## 总结

防止 AI 幻觉不是靠"更好的模型",而是靠**系统设计**:

1. **控制输入**: 语义切分保持上下文完整
2. **强制溯源**: 让 AI 标注每个结论的来源
3. **独立验证**: 用另一个 AI 交叉核对

这套方法不仅适用于教育场景,也可用于:
- 法律文档问答(需要引用具体条款)
- 医疗咨询(必须溯源到权威文献)
- 企业知识库(回答需要标注来源文档)

**核心理念**: 不要让 AI"相信自己",要让它"证明自己"。

---

**作者**: bill (Anchor Learning (锚学)项目维护者)  
**发布时间**: 2026-07-26  
**项目主页**: https://github.com/Drew-Z/anchor
