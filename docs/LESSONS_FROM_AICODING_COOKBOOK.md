# 从 aicoding-cookbook 学到的关键设计

> 参考项目: https://github.com/lili-luo/aicoding-cookbook  
> 重点研究: docs-to-book skill

## 核心洞察

### 1. 文档解析的正确思路

**aicoding-cookbook 的方法**:
- **语义边界切分** - 按章节(h2/h3)、代码块、列表自然划分,而非固定字数
- **保留结构上下文** - 每个 chunk 知道自己在整体中的位置(part → chapter → section)
- **代码是事实基线** - 文档会撒谎,代码不会;冲突时以代码为准

**当前项目的问题**:
```dart
// lib/services/content_analyzer.dart:82
final chunks = <String>[];
for (int i = 0; i < contentLength; i += 500) {  // ❌ 固定 500 字硬切
  chunks.add(content.substring(i, end));
}
```

**改进方向**:
```dart
// 新的语义切分算法
class SemanticChunker {
  List<SourceChunk> chunkByStructure(String markdown) {
    // 1. 解析 Markdown 语法树
    final document = Document.parse(markdown);
    
    // 2. 按标题层级切分
    final sections = _extractSections(document);
    
    // 3. 每个 section 内按代码块/列表/段落边界切分
    // 4. 保留层级信息: part.chapter.section
    // 5. 目标:每个 chunk 500-2000 字,但不破坏语义完整性
  }
}
```

---

### 2. 知识点提取的最佳实践

**docs-to-book 的七部分分类法**:
```
0. 起点导读 (这是什么 / 怎么读)
一. 认识项目 (总览 / 架构 / 边界)
二. 架构演进 (为什么这么设计 / 历史决策)
三. 方法论   (领域知识 / 术语 / 套路)
四. 业务实现 (核心模块 / 工作流)
五. 数据与集成 (存储 / 数据流 / 外部依赖)
六. 部署运维 (怎么跑 / 怎么排查)
七. 参考规范 (开发规范 / 漂移清单)
```

**映射到多多学的 KnowledgePointKind**:
```dart
enum KnowledgePointKind {
  concept,        // 对应「三.方法论」- 领域概念
  architecture,   // 对应「一.认识项目」- 架构设计
  dataFlow,       // 对应「五.数据与集成」- 数据流转
  implementation, // 对应「四.业务实现」- 具体实现
  boundary,       // 对应「一.认识项目」- 职责边界
  tradeOff,       // 对应「二.架构演进」- 设计权衡
}
```

**启发**: 当前的分类太技术化,应该更贴近**认知曲线**:
- 先理解"是什么"(concept/architecture)
- 再理解"为什么"(tradeOff/boundary)
- 最后理解"怎么做"(implementation/dataFlow)

---

### 3. AI 任务的模块化设计

**docs-to-book 的 Phase 划分**:
```
Phase 0: 盘点与梳理 (评估文档完备度 → 选路径 → 代码探查)
Phase 1: 骨架       (七部分归类 → 定页面结构 → book.config.js)
Phase 2: 外壳       (设计系统 → 构建脚本 → 测试)
Phase 3: 内容       (并行子代理填充 → 事实验证 → 清理)
Phase 4: 验证       (抽查准确性 → verify.js → 视觉终检)
```

**当前项目可复用的模式**:

#### 导入流程改造
```
当前: 用户手动点"生成题目" → 阻塞等待 → 一次性返回
改进: 
  Phase 0: 文档解析 (语义切分 → 提取结构)
  Phase 1: 知识点提取 (并行子任务 → 按 chunk 提取)
  Phase 2: 题目生成 (知识点 → 多题型生成)
  Phase 3: 质量检查 (去重 → 难度标定 → 可答性验证)
```

#### Agent 对话流程
```
当前: 单轮问答,无记忆
改进:
  Phase 0: 理解意图 (问题分类 → 检索相关知识点)
  Phase 1: 生成回答 (结合上下文 → 引用来源)
  Phase 2: 验证事实 (grep 源文档 → 确认准确性)
  Phase 3: 更新记忆 (存入 Checkpoint → 下次复用)
```

---

### 4. 质量保证的硬性检查

**docs-to-book 的 quality-checks.md 教训**:

| 检查项 | 为什么重要 | 在多多学怎么做 |
|--------|-----------|--------------|
| **数字类事实** | AI 会编数字(端口/阈值/计数) | 生成题目后,grep 源文档确认所有数字 |
| **否定结论** | AI 会瞎断言"无 X" | 选择题的"错误"选项必须真的错(代码验证) |
| **代码片段** | AI 会从文档抄过时版本 | 填空题的代码片段必须来自源文档,逐行对齐 |
| **配置项** | 环境变量名 ≠ 有效配置 | 判断题的配置描述必须在文档中找到对应段落 |

**落地方案**: 新增 `QuestionValidator` 服务
```dart
class QuestionValidator {
  /// 验证题目的事实准确性
  Future<ValidationResult> validate(Question question, Source source) async {
    final chunks = await _getRelatedChunks(source.id, question);
    
    switch (question.type) {
      case QuestionType.multipleChoice:
        return _validateChoices(question, chunks);
      
      case QuestionType.fillInBlank:
        return _validateCodeSnippet(question, chunks);
      
      case QuestionType.trueFalse:
        return _validateStatement(question, chunks);
    }
  }
  
  /// 从原文中查找数字/术语,确认一致
  Future<bool> _validateChoices(Question q, List<SourceChunk> chunks) {
    for (final choice in q.choices) {
      if (choice.contains(RegExp(r'\d+'))) {  // 包含数字
        final number = extractNumber(choice);
        if (!chunks.any((c) => c.content.contains(number))) {
          return false;  // AI 编造的数字
        }
      }
    }
    return true;
  }
}
```

---

### 5. 子代理并行策略

**docs-to-book 的并行原则**:
```markdown
- 只读探查用轻量/只读型代理
- 写内容用通用代理
- 子代理只返回「结构化摘要」,不自己落盘文件
- 主 agent 收到后统一 Write,避免文件冲突
```

**在多多学的应用场景**:

#### 大文档导入
```dart
// 当前:主线程阻塞处理
// 改进:并行子任务
Future<void> importLargeDocument(Source source) async {
  // 1. 主线程:切分 chunks
  final chunks = await _semanticChunker.chunk(source);
  
  // 2. 并行:每个 chunk 提取知识点
  final results = await Future.wait(
    chunks.map((chunk) => _extractKnowledgePoints(chunk))
  );
  
  // 3. 主线程:合并去重,统一写入数据库
  final allPoints = results.expand((r) => r).toList();
  final deduplicated = _deduplicateByTitle(allPoints);
  await _batchInsert(deduplicated);
}
```

---

## 立即可用的改进点

### 短期(本周)

1. **语义切分算法**
   - 文件: `lib/services/content_analyzer.dart`
   - 改动: 替换 `for (i=0; i<len; i+=500)` 为按标题/代码块切分
   - 参考: docs-to-book 的 `codebase-survey.md` 第 19-58 行

2. **知识点分类优化**
   - 文件: `lib/data/models/knowledge_point.dart`
   - 改动: 在 UI 显示时按"认知曲线"排序(concept → architecture → implementation)
   - 新增字段: `prerequisite_ids` 表示前置依赖

3. **题目质量验证**
   - 新建: `lib/services/question_validator.dart`
   - 功能: 生成题目后自动 grep 源文档验证事实
   - 触发: `QuestionGenerationTask` 完成后

### 中期(第 2-3 周)

4. **导入流程 Phase 化**
   - 参考: docs-to-book 的 Phase 0-4 划分
   - 当前 4 步 → 改为后台自动 Pipeline
   - UI 只显示进度条,每个 Phase 完成时通知

5. **Agent 记忆系统**
   - 参考: docs-to-book 的"漂移清单"机制
   - Agent 对话时记录:用户纠正的错误 / 已确认的事实
   - 存入 `agent_memory` 表,下次对话时加载

6. **并行任务调度器**
   - 新建: `lib/services/task_scheduler.dart`
   - 功能: 管理 AI 任务队列,根据 API Rate Limit 自动调度
   - 支持: 暂停/恢复/取消

### 长期(第 4-8 周)

7. **插件系统设计**
   - 参考: docs-to-book 的 Skill 模块化
   - 定义接口: `ContentImporter` / `QuestionGenerator` / `AIModelAdapter`
   - 社区贡献: Anki 导入器 / LeetCode 同步器 / Obsidian 集成

8. **知识图谱可视化**
   - 参考: docs-to-book 的 Mermaid 架构图
   - 在知识库页面显示:知识点依赖关系图
   - 交互: 点击节点跳转到学习页面

---

## 关键代码片段参考

### 1. 语义切分(伪代码)
```dart
// 参考 docs-to-book 的章节提取逻辑
List<SourceChunk> chunkByHeadings(String markdown) {
  final lines = markdown.split('\n');
  final chunks = <SourceChunk>[];
  
  String currentHeading = '';
  List<String> currentContent = [];
  int chunkIndex = 0;
  
  for (final line in lines) {
    if (line.startsWith('#')) {  // 新章节
      if (currentContent.isNotEmpty) {
        chunks.add(SourceChunk(
          chunkIndex: chunkIndex++,
          content: currentContent.join('\n'),
          locator: currentHeading,  // 章节标题作为定位符
        ));
      }
      currentHeading = line.replaceFirst(RegExp(r'^#+\s*'), '');
      currentContent = [line];
    } else {
      currentContent.add(line);
    }
  }
  
  return chunks;
}
```

### 2. 知识点依赖关系(SQL Schema)
```sql
-- 参考 docs-to-book 的 book.config.js 结构
CREATE TABLE knowledge_point_prerequisites (
  id TEXT PRIMARY KEY,
  knowledge_point_id TEXT NOT NULL,  -- 当前知识点
  prerequisite_id TEXT NOT NULL,     -- 前置知识点
  reason TEXT,                       -- 为什么依赖(可选)
  FOREIGN KEY (knowledge_point_id) REFERENCES knowledge_points(id),
  FOREIGN KEY (prerequisite_id) REFERENCES knowledge_points(id)
);

-- 查询:学习某个知识点前应该先学什么
SELECT kp.* 
FROM knowledge_points kp
JOIN knowledge_point_prerequisites kpp ON kp.id = kpp.prerequisite_id
WHERE kpp.knowledge_point_id = ?
ORDER BY kp.difficulty ASC;
```

### 3. 题目验证器(核心逻辑)
```dart
// 参考 docs-to-book 的 quality-checks.md
class QuestionFactChecker {
  Future<List<String>> checkMultipleChoice(Question q, String sourceContent) async {
    final issues = <String>[];
    
    // 检查每个选项是否在原文中出现
    for (final choice in q.choices) {
      final keywords = _extractKeywords(choice);
      
      if (!keywords.every((kw) => sourceContent.contains(kw))) {
        issues.add('选项 "${choice}" 的关键词未在原文找到');
      }
      
      // 特别检查数字
      final numbers = RegExp(r'\d+').allMatches(choice);
      for (final match in numbers) {
        final num = match.group(0)!;
        if (!sourceContent.contains(num)) {
          issues.add('选项中的数字 "$num" 在原文中不存在(可能是 AI 编造的)');
        }
      }
    }
    
    return issues;
  }
}
```

---

## 总结:最重要的 3 个教训

1. **语义>字数** - 切分文档时按结构切,不要按固定字数切
2. **代码是事实** - 生成内容后必须回源文档验证,AI 会编
3. **并行要克制** - 子任务只返回摘要,主线程统一写文件,避免冲突

这些原则在 docs-to-book 经过大量项目验证,直接复用可少走很多弯路。
