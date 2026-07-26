# 自定义 AI Prompt

本指南教你如何调整 AI 的行为,生成符合你需求的学习内容。

---

## 为什么要自定义 Prompt?

默认 Prompt 设计为通用场景,但你可能有特殊需求:

- 📚 **学习风格**: 更多实践题 vs 更多概念题
- 🎯 **难度偏好**: 只要简单题 vs 挑战困难题
- 🌍 **语言风格**: 正式学术 vs 轻松口语
- 🔍 **题型偏好**: 只要选择题 vs 多样化题型

---

## Prompt 文件位置

所有 AI Tasks 位于 `lib/services/ai/tasks/` 目录:

```
lib/services/ai/tasks/
├── knowledge_extraction_task.dart      # 知识点提取
├── question_generation_task.dart       # 题目生成
├── citation_verification_task.dart     # 引用验证
├── answer_evaluation_task.dart         # 答案评估
├── tutor_socratic_task.dart           # 苏格拉底式辅导
└── ...
```

---

## 1. 调整题目生成策略

### 文件: `question_generation_task.dart`

#### 修改题型分布

**默认配置**:
```dart
String get systemPrompt => '''
你是一个专业出题专家...

题型要求:
- singleChoice: 单选题,4个选项,只有1个正确
- multipleChoice: 多选题,4-5个选项,2-3个正确
- fillBlank: 填空题,答案简短明确
- trueFalse: 判断题,陈述清晰

题型分布: 50% 单选, 30% 多选, 20% 填空/判断
难度分布: 30% 简单, 50% 中等, 20% 困难
''';
```

#### 自定义 1: 只生成选择题

```dart
String get systemPrompt => '''
你是一个专业出题专家...

题型要求:
- 只生成单选题和多选题
- 每道题必须有 4 个选项
- 选项设计要有干扰性

题型分布: 70% 单选, 30% 多选
难度分布: 20% 简单, 60% 中等, 20% 困难
''';
```

#### 自定义 2: 偏向实践题

```dart
String get systemPrompt => '''
你是一个专业出题专家...

题目要求:
- 优先设计代码分析题和场景应用题
- 避免纯记忆类题目
- 每道题应该考察实际编程能力

题型分布: 40% 代码选择, 40% 场景判断, 20% 填空
难度分布: 10% 简单, 40% 中等, 50% 困难
''';
```

#### 自定义 3: 适合初学者

```dart
String get systemPrompt => '''
你是一个专业出题专家...

题目要求:
- 针对初学者,避免过于复杂的概念
- 题干使用简单易懂的语言
- 解析要详细,包含原理说明

题型分布: 60% 单选, 20% 判断, 20% 填空
难度分布: 60% 简单, 30% 中等, 10% 困难
''';
```

---

## 2. 调整知识点提取策略

### 文件: `knowledge_extraction_task.dart`

#### 默认配置

```dart
String get systemPrompt => '''
你是一个专业的技术内容分析专家...

要求:
1. 每个知识点必须是独立的、可学习的概念
2. 标题简洁明确,描述详细准确
3. 分类到: 核心概念/API 用法/最佳实践/常见陷阱
''';
```

#### 自定义 1: 更细粒度的知识点

```dart
String get systemPrompt => '''
你是一个专业的技术内容分析专家...

要求:
1. 尽可能详细地拆分知识点
2. 一个 API 的每个参数都可以是独立知识点
3. 每个示例代码都提取为独立知识点

分类更细: 
- 核心概念/API 用法/参数说明/返回值/异常处理/最佳实践/常见陷阱/性能优化
''';
```

#### 自定义 2: 只关注实践要点

```dart
String get systemPrompt => '''
你是一个专业的技术内容分析专家...

要求:
1. 只提取实际编程中会用到的知识点
2. 忽略理论背景和历史介绍
3. 重点关注: 如何使用、注意事项、常见错误

分类: 使用方法/注意事项/常见错误/最佳实践
''';
```

---

## 3. 调整 AI 辅导风格

### 文件: `tutor_socratic_task.dart`

#### 默认配置

```dart
String get systemPrompt => '''
你是一个苏格拉底式导师...

反馈风格:
- 肯定正确的部分
- 指出不足,但不直接纠正
- 提出启发式问题,而不是直接讲解
''';
```

#### 自定义 1: 更直接的反馈

```dart
String get systemPrompt => '''
你是一个直接友好的导师...

反馈风格:
- 明确指出错误
- 给出正确答案和原因
- 提供相关示例代码
- 语气轻松友好,避免说教
''';
```

#### 自定义 2: 更严格的苏格拉底式

```dart
String get systemPrompt => '''
你是一个严格的苏格拉底式导师...

反馈风格:
- 永远不直接给答案
- 通过连续追问,引导学生自己发现
- 即使学生答对了,也追问"为什么"
- 挑战学生的假设和思维盲点
''';
```

---

## 4. 调整引用验证严格度

### 文件: `citation_verification_task.dart`

#### 默认配置

```dart
String get systemPrompt => '''
你是一个严格的事实核查专家...

判断标准:
- verified (confidence >= 0.8): 引用充分,事实准确
- suspicious (0.5 <= confidence < 0.8): 引用部分支持,但有疑点
- invalid (confidence < 0.5): 引用不支持或答案错误
''';
```

#### 自定义 1: 更宽松(快速生成)

```dart
String get systemPrompt => '''
你是一个事实核查专家...

判断标准:
- verified (confidence >= 0.6): 引用基本合理
- suspicious (0.4 <= confidence < 0.6): 有明显问题
- invalid (confidence < 0.4): 完全错误

策略: 鼓励通过,除非有严重错误
''';
```

#### 自定义 2: 更严格(高质量优先)

```dart
String get systemPrompt => '''
你是一个极其严格的事实核查专家...

判断标准:
- verified (confidence >= 0.95): 引用精确,逻辑完美
- suspicious (0.7 <= confidence < 0.95): 有任何瑕疵
- invalid (confidence < 0.7): 不够严谨

策略: 宁可拒绝,不可通过低质量题目
''';
```

---

## 5. 调整生成数量

### 文件: `lib/services/ingestion/source_grounded_ingestion_service.dart`

#### 默认配置

```dart
int questionCountFor(int knowledgePointCount) {
  return knowledgePointCount * 2; // 每个知识点生成 2 道题
}

int maxKnowledgePointsFor(int chunkCount) {
  return math.min(chunkCount ~/ 3, 50); // 最多 50 个知识点
}
```

#### 自定义 1: 少而精

```dart
int questionCountFor(int knowledgePointCount) {
  return knowledgePointCount; // 每个知识点只生成 1 道高质量题
}

int maxKnowledgePointsFor(int chunkCount) {
  return math.min(chunkCount ~/ 5, 20); // 只提取核心知识点
}
```

#### 自定义 2: 海量练习

```dart
int questionCountFor(int knowledgePointCount) {
  return knowledgePointCount * 5; // 每个知识点生成 5 道题
}

int maxKnowledgePointsFor(int chunkCount) {
  return math.min(chunkCount ~/ 2, 100); // 详尽提取
}
```

---

## 6. 更换 AI 模型

### 文件: `lib/services/openai_service.dart`

#### 默认配置

```dart
class OpenAIService {
  final String model;
  
  OpenAIService({
    this.model = 'gpt-3.5-turbo', // 默认模型
  });
}
```

#### 选项 1: 使用 GPT-4(更高质量)

```dart
// 在 .env 文件中设置
OPENAI_MODEL=gpt-4-turbo

// 或在代码中修改
OpenAIService({
  this.model = 'gpt-4-turbo',
});
```

**对比**:
| 模型 | 质量 | 速度 | 成本 |
|------|------|------|------|
| gpt-3.5-turbo | ⭐⭐⭐ | ⚡⚡⚡ | $ |
| gpt-4-turbo | ⭐⭐⭐⭐⭐ | ⚡⚡ | $$$ |

#### 选项 2: 使用本地模型

```dart
class OpenAIService {
  final String baseUrl;
  final String model;
  
  OpenAIService({
    this.baseUrl = 'http://localhost:11434/v1', // Ollama
    this.model = 'llama3.1:8b',
  });
}
```

**兼容的本地模型**:
- Llama 3.1 (8B, 70B)
- Mistral (7B, 8x7B)
- Qwen 2.5

---

## 7. 添加自定义题型

### 示例: 添加"排序题"

#### 步骤 1: 定义题型

编辑 `lib/data/models/question_type.dart`:

```dart
enum QuestionType {
  singleChoice,
  multipleChoice,
  fillBlank,
  trueFalse,
  matching,
  sorting,        // 新增
  codeCompletion, // 新增: 代码补全题
}
```

#### 步骤 2: 更新 Prompt

编辑 `question_generation_task.dart`:

```dart
String get systemPrompt => '''
...

题型要求:
- sorting: 排序题,给出 3-5 个步骤,要求按正确顺序排列

示例 (排序题):
{
  "type": "sorting",
  "content": "以下是 Flutter Widget 渲染的步骤,请按正确顺序排列:",
  "options": [
    "A. build() 被调用",
    "B. Widget 树转为 Element 树",
    "C. Element 树转为 RenderObject 树",
    "D. RenderObject 执行布局和绘制"
  ],
  "answer": "A,B,C,D",
  "explanation": "..."
}
''';
```

#### 步骤 3: 更新 UI

编辑 `lib/features/learning/widgets/question_widgets.dart`:

```dart
Widget buildQuestion(Question question) {
  switch (question.type) {
    case QuestionType.sorting:
      return SortingQuestionWidget(question: question);
    // ... 其他题型
  }
}

class SortingQuestionWidget extends StatefulWidget {
  // 实现拖拽排序界面
}
```

---

## 8. Prompt 模板变量

### 当前实现

Prompt 通过字符串插值实现:

```dart
String buildUserPrompt(QuestionGenerationInput input) {
  return '''
知识点数量: ${input.knowledgePoints.length}
要生成的题目数: ${input.questionCount}
''';
}
```

### 改进: 使用模板引擎

创建 `lib/services/ai/prompt_template.dart`:

```dart
class PromptTemplate {
  final String template;
  
  PromptTemplate(this.template);
  
  String render(Map<String, dynamic> variables) {
    var result = template;
    variables.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value.toString());
    });
    return result;
  }
}

// 使用
final template = PromptTemplate('''
知识点数量: {{kpCount}}
题目数量: {{qCount}}
难度偏好: {{difficulty}}
''');

final prompt = template.render({
  'kpCount': 10,
  'qCount': 20,
  'difficulty': '中等',
});
```

---

## 9. 多语言支持

### 当前: 硬编码中文

```dart
String get systemPrompt => '''
你是一个专业出题专家...
''';
```

### 改进: 参数化语言

```dart
class QuestionGenerationTask {
  final String language;
  
  QuestionGenerationTask({
    required this.openaiService,
    this.language = 'zh-CN',
  });
  
  String get systemPrompt {
    if (language == 'en-US') {
      return '''
You are a professional quiz creator...
''';
    } else {
      return '''
你是一个专业出题专家...
''';
    }
  }
}
```

---

## 10. 调试技巧

### 记录完整的 Prompt 和 Response

编辑 `lib/services/openai_service.dart`:

```dart
Future<String> complete({
  required String systemPrompt,
  required String userPrompt,
}) async {
  // 开发模式下记录
  if (kDebugMode) {
    print('=== System Prompt ===');
    print(systemPrompt);
    print('=== User Prompt ===');
    print(userPrompt);
  }
  
  final response = await _callAPI(...);
  
  if (kDebugMode) {
    print('=== AI Response ===');
    print(response);
  }
  
  return response;
}
```

### 保存到文件(详细调试)

```dart
import 'dart:io';

void _logPrompt(String systemPrompt, String userPrompt, String response) {
  final timestamp = DateTime.now().toIso8601String();
  final file = File('logs/prompt_$timestamp.txt');
  file.writeAsStringSync('''
=== System ===
$systemPrompt

=== User ===
$userPrompt

=== Response ===
$response
''');
}
```

---

## 常见问题

### Q1: 修改后不生效?

**解决**:
1. 确认修改了正确的文件
2. 热重载可能不够,尝试完全重启应用
3. 检查是否有缓存(清除应用数据)

### Q2: AI 不按照我的 Prompt 执行?

**可能原因**:
- Prompt 表述模糊
- 与 User Prompt 冲突
- 模型能力限制(尝试 GPT-4)

**调试方法**:
1. 启用日志,查看实际发送的 Prompt
2. 在 OpenAI Playground 测试 Prompt
3. 简化 Prompt,逐步添加约束

### Q3: 如何测试 Prompt 效果?

**方法 1**: 单元测试

```dart
void main() {
  test('Question generation prompt', () async {
    final task = QuestionGenerationTask(mockOpenAI);
    final result = await task.run(testInput);
    
    expect(result.questions.length, 10);
    expect(result.questions.first.type, QuestionType.singleChoice);
  });
}
```

**方法 2**: 对比测试

生成两批题目(修改前后),对比质量:
- 题目多样性
- 引用准确性
- 难度分布

---

## 示例: 完整的自定义配置

### 场景: 为编程初学者定制

#### 1. 降低难度

```dart
// question_generation_task.dart
String get systemPrompt => '''
你是一个耐心的编程导师,为初学者出题...

题目要求:
- 避免复杂语法和高级特性
- 题干使用口语化表达
- 每道题只考察一个知识点
- 解析要详细,包含"为什么"

题型分布: 70% 单选, 30% 判断
难度: 80% 简单, 20% 中等
''';
```

#### 2. 增加练习量

```dart
// source_grounded_ingestion_service.dart
int questionCountFor(int knowledgePointCount) {
  return knowledgePointCount * 3; // 每个知识点 3 道题
}
```

#### 3. 友好的辅导风格

```dart
// tutor_socratic_task.dart
String get systemPrompt => '''
你是一个友好的编程小助手...

回答风格:
- 使用简单的类比和例子
- 避免专业术语,或给出通俗解释
- 多用鼓励性语言
- 语气轻松,像朋友聊天
''';
```

---

## 贡献你的 Prompt

如果你设计了很棒的 Prompt 配置,欢迎分享!

1. Fork 本项目
2. 创建 `prompts/community/` 目录
3. 添加你的配置文件:
   ```
   prompts/community/
   └── beginner-friendly/
       ├── README.md (说明)
       ├── question_generation_task.dart
       └── tutor_socratic_task.dart
   ```
4. 提交 PR,附上效果说明

---

## 下一步

- [AI Pipeline 设计](../architecture/AI_PIPELINE.md) - 理解 Task 架构
- [贡献指南](../../CONTRIBUTING.md) - 提交你的改进
- [社区讨论](https://github.com/你的用户名/duoduo/discussions) - 分享经验

---

**Prompt 工程是迭代的过程,大胆实验!** 🚀
