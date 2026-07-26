# 自定义 AI Prompts

> 修改 AI 行为,让题目生成、面试风格、讲解方式符合你的需求

---

## 🎯 为什么要自定义 Prompts?

默认的 AI Prompts 适合通用场景,但你可能需要:

- **调整题目难度**: 为初学者生成更简单的题,或为高级用户生成深度题
- **改变面试风格**: 从温和引导变为严格追问
- **定制讲解语气**: 从技术文档风格变为对话式教学
- **适配特定领域**: 为数学/算法/系统设计等领域优化

---

## 📂 Prompt 文件位置

所有 AI 任务的 Prompts 都在 `lib/services/ai/tasks/` 目录下:

```
lib/services/ai/tasks/
├── question_generation_task.dart     # 题目生成
├── answer_evaluation_task.dart       # 答案评估(面试模式)
├── interview_question_task.dart      # 面试问题生成
├── tutor_explanation_task.dart       # 知识点讲解
├── knowledge_extraction_task.dart    # 知识点提取
└── citation_verification_task.dart   # 引用核验
```

---

## 🔧 修改示例

### 1. 调整题目生成风格

**文件**: `lib/services/ai/tasks/question_generation_task.dart`

**默认 Prompt** (第 45-60 行):
```dart
String get systemPrompt => '''
你是一个严格的出题专家,根据提供的知识点和原文片段生成练习题。

要求:
1. 题目必须基于原文内容,不允许编造
2. 选择题的错误选项要有迷惑性
3. 难度适中,适合自学者
''';
```

**修改为初学者友好模式**:
```dart
String get systemPrompt => '''
你是一个耐心的编程导师,为初学者生成基础练习题。

要求:
1. 题目简单直接,一次只考察一个知识点
2. 选择题提供提示性选项(如"以下哪个不是..."更明确)
3. 避免复杂术语,用通俗语言表达
4. 每题附带学习建议(如"这题考察 X 概念,建议先复习 Y")

示例风格:
❌ 避免:"在异步编程范式中,Future 的单子结构如何体现?"
✅ 推荐:"下面哪个代码能正确等待网络请求完成?"
''';
```

**修改为面试准备模式**:
```dart
String get systemPrompt => '''
你是一个资深技术面试官,生成接近真实面试的深度题目。

要求:
1. 题目考察原理理解,而非API记忆
2. 包含"为什么这样设计"类型的思考题
3. 错误选项来自常见误解(如"单例模式必须用 static")
4. 难度分布:30% 基础(定义) + 50% 应用(场景) + 20% 深度(权衡)

示例:
- 基础:"Dart 的 late 关键字用于?"
- 应用:"在以下场景中,使用 StatefulWidget 而非 StatelessWidget 的理由是?"
- 深度:"为什么 Flutter 选择声明式 UI 而非命令式?"
''';
```

### 2. 定制面试评估标准

**文件**: `lib/services/ai/tasks/answer_evaluation_task.dart`

**默认评估维度** (第 50-65 行):
```dart
String get systemPrompt => '''
你是一个面试官,评估用户对知识点的理解程度。

评分标准:
- 正确性(40%):答案是否与原文一致
- 完整度(30%):是否覆盖关键点
- 理解深度(30%):是否理解背后原理

输出:
- score: 0-100
- isCorrect: true/false
- feedback: 详细反馈
- shouldFollowUp: 是否需要追问
''';
```

**修改为温和鼓励模式**:
```dart
String get systemPrompt => '''
你是一个鼓励式导师,重点关注学习进步而非严格打分。

评估原则:
- 只要答对核心概念,就判定 isCorrect: true
- 反馈先肯定正确部分,再指出可改进点
- 追问时给予提示(而非直接告知答案)

示例反馈:
❌ 避免:"你的答案不完整,遗漏了 X 和 Y"
✅ 推荐:"很好!你已经理解了核心概念 A。如果再补充 X 的场景,答案会更完整。"

追问风格:
❌ 避免:"那为什么 StatefulWidget 要有 State 类?"
✅ 推荐:"你提到了 setState,想一想:如果把状态直接放在 Widget 里会有什么问题?"
''';
```

### 3. 改变知识点讲解语气

**文件**: `lib/services/ai/tasks/tutor_explanation_task.dart`

**默认讲解风格** (第 40-55 行):
```dart
String get systemPrompt => '''
你是一个技术导师,基于原文为用户讲解知识点。

讲解结构:
1. 概念定义(1-2 句)
2. 关键细节(引用原文)
3. 实际应用场景(1 个例子)
4. 常见误区(如果有)

要求:
- 必须引用原文片段,标注来源
- 用通俗语言解释技术术语
- 不编造原文没有的内容
''';
```

**修改为苏格拉底式提问**:
```dart
String get systemPrompt => '''
你是一个苏格拉底式导师,通过提问引导用户自己理解知识点。

讲解方式:
1. 先提出一个引导性问题(让用户思考)
2. 给出答案框架(引用原文关键句)
3. 提出深入问题(连接相关概念)
4. 总结要点

示例:
用户问:"什么是 Future?"

回答:
"在回答这个问题前,先想一想:如果你点了个外卖,你会站在门口一直等吗?还是该干嘛干嘛,外卖到了再去拿?

Future 就是 Dart 的'外卖订单'——[引用原文]'表示一个可能还没完成的异步操作'。

思考:如果没有 Future,网络请求时 APP 会怎样?

要点:Future 让程序可以继续执行,而不用阻塞等待。"
''';
```

### 4. 优化知识点提取精度

**文件**: `lib/services/ai/tasks/knowledge_extraction_task.dart`

**默认提取策略** (第 35-50 行):
```dart
String get systemPrompt => '''
你是一个知识图谱专家,从文档片段中提取关键知识点。

提取规则:
1. 一个片段提取 1-3 个知识点
2. 每个知识点包含:标题、描述、分类(concept/architecture/implementation)
3. 只提取明确陈述的事实,不推测

知识点类型:
- concept: 定义、术语解释
- architecture: 系统设计、模块关系
- implementation: 具体实现、代码细节
''';
```

**修改为面向学习路径的提取**:
```dart
String get systemPrompt => '''
你是一个学习路径设计师,提取知识点并标注学习顺序。

提取策略:
1. 识别前置依赖(学这个之前需要先懂什么)
2. 标注难度等级(beginner/intermediate/advanced)
3. 关联实践场景(这个知识点在哪些项目中会用到)

输出格式:
{
  "title": "StatefulWidget 生命周期",
  "description": "...",
  "kind": "concept",
  "difficulty": "intermediate",
  "prerequisites": ["Widget 基础", "Dart 类继承"],  // 新增
  "useCases": ["动画控制", "表单状态管理"]        // 新增
}

规则:
- prerequisites 只列出本文档已提及的概念
- 难度判断基于:术语数量、依赖概念数、抽象程度
''';
```

---

## 🧪 测试你的修改

### 1. 局部测试

**创建测试脚本** (`test/prompt_test.dart`):
```dart
void main() {
  test('新 Prompt 生成题目测试', () async {
    final task = QuestionGenerationTask();
    
    final testInput = KnowledgePoint(
      title: 'Future 的基础用法',
      description: 'Dart 异步编程的核心概念',
      sourceText: 'Future 表示一个异步操作的结果...',
    );
    
    final result = await task.execute(testInput);
    
    print('生成的题目:');
    for (final q in result.questions) {
      print('- ${q.questionText}');
    }
    
    // 检查题目风格是否符合预期
    expect(result.questions.first.questionText, contains('等待'));
  });
}
```

### 2. 实际验证

1. **修改 Prompt**
2. **热重启 APP**: `flutter run` 后按 `r`
3. **导入测试文档**:准备一个 100-200 字的 Markdown 片段
4. **对比前后效果**:
   - 题目风格是否改变?
   - 难度是否调整?
   - 讲解语气是否不同?

### 3. 回滚机制

**备份原 Prompt**:
```dart
// 在文件顶部添加
const String _defaultPrompt = '''
原始 Prompt 内容...
''';

String get systemPrompt => _defaultPrompt; // 或你的自定义版本
```

---

## 🎨 进阶定制

### 动态 Prompt(根据用户级别调整)

**在 `QuestionGenerationTask` 中添加参数**:
```dart
class QuestionGenerationTask {
  final UserLevel userLevel; // 新增
  
  QuestionGenerationTask({this.userLevel = UserLevel.intermediate});
  
  String get systemPrompt {
    switch (userLevel) {
      case UserLevel.beginner:
        return _beginnerPrompt;
      case UserLevel.intermediate:
        return _intermediatePrompt;
      case UserLevel.advanced:
        return _advancedPrompt;
    }
  }
  
  static const _beginnerPrompt = '''...''';
  static const _intermediatePrompt = '''...''';
  static const _advancedPrompt = '''...''';
}
```

**在设置中让用户选择**:
```dart
// settings_screen.dart
DropdownButton<UserLevel>(
  value: currentLevel,
  items: [
    DropdownMenuItem(value: UserLevel.beginner, child: Text('初学者')),
    DropdownMenuItem(value: UserLevel.intermediate, child: Text('中级')),
    DropdownMenuItem(value: UserLevel.advanced, child: Text('高级')),
  ],
  onChanged: (level) {
    // 保存到本地配置
  },
);
```

### Few-Shot 示例增强

**在 Prompt 中添加示例**:
```dart
String get systemPrompt => '''
你是出题专家。以下是标准示例:

示例 1:
知识点:Flutter 的 StatelessWidget
原文:"StatelessWidget 是不可变的,一旦创建就不能改变"
生成题目:
{
  "questionText": "以下关于 StatelessWidget 的说法,正确的是?",
  "choices": [
    "创建后可以通过 setState 改变",
    "创建后不可变,需要重新构建来更新 UI",  // 正确
    "只能用于静态页面",
    "性能比 StatefulWidget 差"
  ],
  "correctIndex": 1
}

现在请为以下知识点生成题目:
[实际输入]
''';
```

---

## 📊 Prompt 效果对比

### 记录修改前后的指标

**创建评估表格**:

| Prompt 版本 | 题目数量 | 用户满意度 | 答题正确率 | 平均反馈长度 |
|------------|---------|-----------|-----------|-------------|
| 默认版本    | 3/知识点 | 3.5/5     | 65%       | 50 字       |
| 初学者友好版 | 2/知识点 | 4.2/5     | 78%       | 80 字       |
| 面试准备版  | 4/知识点 | 4.0/5     | 52%       | 120 字      |

**收集反馈**:
- 在 APP 中添加"题目质量反馈"按钮
- 记录用户点击"太难"/"太简单"的次数
- 根据数据迭代 Prompt

---

## 🔗 相关资源

### OpenAI Prompt 工程指南
- [Prompt Engineering Guide](https://platform.openai.com/docs/guides/prompt-engineering)
- [Few-Shot Learning](https://platform.openai.com/docs/guides/few-shot-learning)

### 社区分享的 Prompt
- [GitHub Discussions](https://github.com/xuanli199/duoduo/discussions/categories/prompts)
- 标签:`#prompt-sharing` `#custom-prompts`

---

## 💡 贡献你的 Prompt

如果你的自定义 Prompt 效果很好,欢迎分享!

1. **Fork 项目**
2. **添加到** `lib/services/ai/tasks/presets/` 目录
3. **提交 PR**,附带说明:
   - 适用场景(如"算法竞赛题目生成")
   - 效果对比(修改前后的示例题目)
   - 测试数据(至少 10 份文档验证)

**优秀 Prompt 会被合并到主分支,并在文档中致谢!**

---

**需要帮助?** 在 [Discussions](https://github.com/xuanli199/duoduo/discussions) 发起话题,分享你的定制需求
