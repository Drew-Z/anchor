# 测试指南

本文档说明 **Anchor Learning (锚学)** 的测试策略、测试编写规范和运行方法。

---

## 测试策略

### 测试金字塔

```
          /\
         /  \        E2E Tests (少量)
        /----\       - 关键用户流程
       /      \      
      /--------\     Integration Tests (适量)
     /          \    - 跨层交互
    /------------\   - 数据库 + Repository
   /______________\  Unit Tests (大量)
                     - 纯逻辑
                     - 工具函数
                     - AI Task 解析
```

### 测试原则

1. **测试行为,不测试实现**: 关注输入输出,而非内部实现
2. **隔离测试**: 使用 Mock 隔离外部依赖 (API, 数据库)
3. **可读性优先**: 测试即文档,命名清晰表达意图
4. **快速执行**: 单元测试应在秒级完成

---

## 测试结构

```
test/
├── unit/                   # 单元测试
│   ├── services/
│   │   ├── ai/            # AI Tasks 测试
│   │   ├── ingestion/     # 文档导入测试
│   │   └── validation/    # 数据验证测试
│   ├── utils/             # 工具函数测试
│   └── models/            # 数据模型测试
├── integration/           # 集成测试
│   ├── database/          # 数据库集成测试
│   └── repository/        # Repository 集成测试
├── widget/                # Widget 测试
│   └── features/
└── fixtures/              # 测试数据
    ├── markdown_samples/
    ├── code_samples/
    └── json/
```

---

## 运行测试

### 基本命令

```bash
# 运行所有测试
flutter test

# 运行特定文件
flutter test test/unit/services/ai/knowledge_extraction_task_test.dart

# 运行特定目录
flutter test test/unit/services/

# 生成测试覆盖率
flutter test --coverage

# 查看覆盖率报告
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### 监听模式

```bash
# 使用 flutter test 自带的监听
flutter test --watch
```

### 性能测试

```bash
# 运行性能测试
flutter test --dart-define=PERFORMANCE_TEST=true test/performance/
```

---

## 单元测试

### 1. AI Task 测试

测试 AI Task 的解析逻辑和验证规则。

**示例**: `test/unit/services/ai/knowledge_extraction_task_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:anchor_learning/services/ai/tasks/knowledge_extraction_task.dart';
import 'package:anchor_learning/data/models/source_chunk.dart';

void main() {
  group('KnowledgeExtractionTask', () {
    late KnowledgeExtractionTask task;

    setUp(() {
      // 使用 Mock OpenAIService
      final mockService = MockOpenAIService();
      task = KnowledgeExtractionTask(mockService);
    });

    group('parseResponse', () {
      test('解析有效的知识点列表', () {
        const response = '''
        {
          "knowledgePoints": [
            {
              "title": "StatefulWidget 生命周期",
              "description": "Flutter 中 StatefulWidget 的生命周期管理",
              "category": "核心概念",
              "citedChunkIds": ["chunk_001", "chunk_002"]
            }
          ]
        }
        ''';

        final input = KnowledgeExtractionInput(
          chunks: [
            SourceChunk(id: 'chunk_001', content: '...'),
            SourceChunk(id: 'chunk_002', content: '...'),
          ],
          maxKnowledgePoints: 10,
        );

        final output = task.parseResponse(response, input);

        expect(output.knowledgePoints, hasLength(1));
        expect(output.knowledgePoints[0].title, 'StatefulWidget 生命周期');
        expect(output.knowledgePoints[0].citedChunkIds, hasLength(2));
      });

      test('拒绝引用不存在的 chunk ID', () {
        const response = '''
        {
          "knowledgePoints": [
            {
              "title": "测试知识点",
              "description": "描述",
              "category": "核心概念",
              "citedChunkIds": ["chunk_999"]
            }
          ]
        }
        ''';

        final input = KnowledgeExtractionInput(
          chunks: [
            SourceChunk(id: 'chunk_001', content: '...'),
          ],
          maxKnowledgePoints: 10,
        );

        expect(
          () => task.parseResponse(response, input),
          throwsA(isA<ValidationError>()),
        );
      });
    });
  });
}
```

### 2. 文档切分测试

**示例**: `test/unit/services/ingestion/semantic_chunker_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:anchor_learning/services/ingestion/semantic_chunker.dart';

void main() {
  group('SemanticChunker', () {
    late SemanticChunker chunker;

    setUp(() {
      chunker = SemanticChunker();
    });

    group('chunkMarkdown', () {
      test('按标题层级切分 Markdown', () {
        const markdown = '''
# 一级标题

内容 1

## 二级标题 A

内容 A

## 二级标题 B

内容 B
        ''';

        final chunks = chunker.chunkMarkdown(
          markdown,
          locatorPrefix: 'README.md',
        );

        expect(chunks, hasLength(3));
        expect(chunks[0].locator, 'README.md:# 一级标题');
        expect(chunks[1].locator, 'README.md:## 二级标题 A');
        expect(chunks[2].locator, 'README.md:## 二级标题 B');
      });

      test('保持代码块完整性', () {
        const markdown = '''
## 代码示例

```dart
void main() {
  print('Hello');
}
```

说明文本
        ''';

        final chunks = chunker.chunkMarkdown(
          markdown,
          locatorPrefix: 'example.md',
        );

        expect(chunks[0].content, contains('```dart'));
        expect(chunks[0].content, contains('```'));
        expect(chunks[0].content, contains('说明文本'));
      });
    });

    group('chunkCode', () {
      test('按函数/类定义切分 Dart 代码', () {
        const code = '''
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

void helperFunction() {
  // ...
}
        ''';

        final chunks = chunker.chunkCode(
          code,
          locatorPrefix: 'lib/my_widget.dart',
          language: 'dart',
        );

        expect(chunks.length, greaterThan(1));
        expect(chunks[0].content, contains('class MyWidget'));
        expect(chunks[1].content, contains('void helperFunction'));
      });
    });
  });
}
```

### 3. 数据验证测试

**示例**: `test/unit/services/validation/question_validator_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:anchor_learning/services/validation/question_validator.dart';

void main() {
  group('QuestionValidator', () {
    late QuestionValidator validator;

    setUp(() {
      validator = QuestionValidator(MockOpenAIService());
    });

    test('验证题目与源文档一致性', () async {
      final draft = QuestionDraft(
        knowledgePointId: 'kp_001',
        type: QuestionType.singleChoice,
        content: '以下关于 Flutter 的说法,正确的是?',
        options: ['A. Flutter 使用 Java', 'B. Flutter 使用 Dart'],
        answer: 'B',
        explanation: 'Flutter 使用 Dart 语言开发。[chunk_001]',
        citedChunkIds: ['chunk_001'],
      );

      final chunks = [
        SourceChunk(
          id: 'chunk_001',
          content: 'Flutter 是使用 Dart 语言开发的跨平台框架。',
        ),
      ];

      final result = await validator.validate(draft, chunks);

      expect(result.isValid, isTrue);
      expect(result.confidence, greaterThan(0.8));
    });

    test('检测答案与源文档矛盾', () async {
      final draft = QuestionDraft(
        knowledgePointId: 'kp_001',
        type: QuestionType.singleChoice,
        content: '以下关于 Flutter 的说法,正确的是?',
        options: ['A. Flutter 使用 Java', 'B. Flutter 使用 Dart'],
        answer: 'A', // 错误答案
        explanation: 'Flutter 使用 Java 语言开发。[chunk_001]',
        citedChunkIds: ['chunk_001'],
      );

      final chunks = [
        SourceChunk(
          id: 'chunk_001',
          content: 'Flutter 是使用 Dart 语言开发的跨平台框架。',
        ),
      ];

      final result = await validator.validate(draft, chunks);

      expect(result.isValid, isFalse);
      expect(result.confidence, lessThan(0.5));
    });
  });
}
```

---

## 集成测试

### 数据库测试

**示例**: `test/integration/database/question_repository_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:anchor_learning/data/database/app_database.dart';
import 'package:anchor_learning/data/repositories/question_repository.dart';

void main() {
  group('QuestionRepository Integration', () {
    late AppDatabase database;
    late QuestionRepository repository;

    setUp(() {
      // 使用内存数据库
      database = AppDatabase(NativeDatabase.memory());
      repository = QuestionRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('保存并读取题目', () async {
      final question = Question(
        id: 'q_001',
        knowledgePointId: 'kp_001',
        type: QuestionType.singleChoice,
        content: '测试题目',
        answer: 'A',
        createdAt: DateTime.now(),
      );

      await repository.insertQuestion(question);

      final retrieved = await repository.getQuestion('q_001');

      expect(retrieved, isNotNull);
      expect(retrieved!.content, '测试题目');
    });

    test('更新题目掌握度', () async {
      final question = Question(
        id: 'q_001',
        knowledgePointId: 'kp_001',
        type: QuestionType.singleChoice,
        content: '测试题目',
        answer: 'A',
        ease: 1.0,
        createdAt: DateTime.now(),
      );

      await repository.insertQuestion(question);
      await repository.updateMastery('q_001', ease: 1.5);

      final updated = await repository.getQuestion('q_001');

      expect(updated!.ease, 1.5);
    });
  });
}
```

---

## Widget 测试

**示例**: `test/widget/features/quiz/quiz_card_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anchor_learning/features/quiz/quiz_card.dart';

void main() {
  group('QuizCard Widget', () {
    testWidgets('显示题目内容', (tester) async {
      final question = Question(
        id: 'q_001',
        knowledgePointId: 'kp_001',
        type: QuestionType.singleChoice,
        content: '这是一个测试题目?',
        options: ['A. 选项1', 'B. 选项2'],
        answer: 'A',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizCard(question: question),
          ),
        ),
      );

      expect(find.text('这是一个测试题目?'), findsOneWidget);
      expect(find.text('A. 选项1'), findsOneWidget);
      expect(find.text('B. 选项2'), findsOneWidget);
    });

    testWidgets('点击选项后高亮', (tester) async {
      final question = Question(
        id: 'q_001',
        knowledgePointId: 'kp_001',
        type: QuestionType.singleChoice,
        content: '测试题目?',
        options: ['A. 选项1', 'B. 选项2'],
        answer: 'A',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizCard(question: question),
          ),
        ),
      );

      await tester.tap(find.text('A. 选项1'));
      await tester.pump();

      final optionAWidget = tester.widget<Container>(
        find.ancestor(
          of: find.text('A. 选项1'),
          matching: find.byType(Container),
        ).first,
      );

      // 验证高亮样式
      expect(
        (optionAWidget.decoration as BoxDecoration).border,
        isNotNull,
      );
    });
  });
}
```

---

## Mock 和 Fixtures

### 创建 Mock

使用 `mockito`:

```dart
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:anchor_learning/services/ai/openai_service.dart';

@GenerateMocks([OpenAIService])
void main() {
  // 测试代码
}
```

生成 Mock:

```bash
dart run build_runner build
```

使用 Mock:

```dart
test('AI 调用返回预期结果', () async {
  final mockService = MockOpenAIService();
  
  when(mockService.complete(
    systemPrompt: anyNamed('systemPrompt'),
    userPrompt: anyNamed('userPrompt'),
  )).thenAnswer((_) async => '{"result": "success"}');

  final task = MyAITask(mockService);
  final result = await task.run(input);

  expect(result.isSuccess, isTrue);
});
```

### 测试 Fixtures

创建可复用的测试数据:

**`test/fixtures/sample_questions.dart`**:

```dart
import 'package:anchor_learning/data/models/question.dart';

class SampleQuestions {
  static Question singleChoice() {
    return Question(
      id: 'q_sc_001',
      knowledgePointId: 'kp_001',
      type: QuestionType.singleChoice,
      content: '以下关于 Flutter 的说法,正确的是?',
      options: [
        'A. Flutter 使用 Java',
        'B. Flutter 使用 Dart',
        'C. Flutter 使用 JavaScript',
        'D. Flutter 使用 C++',
      ],
      answer: 'B',
      explanation: 'Flutter 使用 Dart 语言开发。',
      difficulty: 2,
      ease: 1.0,
      createdAt: DateTime(2024, 1, 1),
    );
  }

  static Question multipleChoice() {
    // ...
  }
}
```

使用:

```dart
test('测试单选题显示', () {
  final question = SampleQuestions.singleChoice();
  // 测试逻辑
});
```

---

## 测试覆盖率

### 目标

- **整体覆盖率**: ≥ 70%
- **核心业务逻辑**: ≥ 90% (AI Tasks, 数据验证, 复习调度)
- **UI 代码**: ≥ 40% (Widget 测试)

### 生成报告

```bash
# 生成覆盖率数据
flutter test --coverage

# 转换为 HTML 报告
genhtml coverage/lcov.info -o coverage/html

# 查看报告
open coverage/html/index.html
```

### 排除文件

在 `test/.test_coverage.yaml` 中配置:

```yaml
exclude:
  - '**/*.g.dart'
  - '**/*.drift.dart'
  - 'lib/generated/**'
```

---

## 最佳实践

### 1. 命名规范

```dart
// ✅ 好: 描述行为
test('更新掌握度后计算下次复习时间', () {});

// ❌ 差: 描述实现
test('调用 calculateNextReview 方法', () {});
```

### 2. Arrange-Act-Assert (AAA) 模式

```dart
test('示例测试', () {
  // Arrange: 准备测试数据
  final input = TestData.sample();
  
  // Act: 执行被测试的操作
  final result = service.process(input);
  
  // Assert: 验证结果
  expect(result.isSuccess, isTrue);
  expect(result.data, isNotNull);
});
```

### 3. 一个测试一个断言 (理想情况)

```dart
// ✅ 好: 专注单一行为
test('计算正确答案后增加 ease', () {
  final ease = calculateEase(isCorrect: true, currentEase: 1.0);
  expect(ease, 1.1);
});

test('计算错误答案后减少 ease', () {
  final ease = calculateEase(isCorrect: false, currentEase: 1.0);
  expect(ease, 0.8);
});

// ⚠️ 可接受: 多个相关断言
test('解析有效响应返回完整结构', () {
  final result = parser.parse(validJson);
  expect(result.title, isNotEmpty);
  expect(result.description, isNotEmpty);
  expect(result.citedChunkIds, isNotEmpty);
});
```

### 4. 使用描述性的 group

```dart
group('MasteryService', () {
  group('calculateInterval', () {
    group('when answer is correct', () {
      test('increases interval based on ease', () {});
      test('respects minimum interval of 1 day', () {});
    });
    
    group('when answer is incorrect', () {
      test('resets interval to 1 day', () {});
      test('decreases ease factor', () {});
    });
  });
});
```

### 5. 避免测试实现细节

```dart
// ❌ 差: 测试内部状态
test('调用私有方法 _parseChunks', () {
  // 测试实现细节,容易因重构而失败
});

// ✅ 好: 测试公开行为
test('从 Markdown 提取标题层级结构', () {
  final result = chunker.chunk(markdown);
  expect(result.first.locator, contains('# 标题'));
});
```

---

## CI/CD 集成

在 GitHub Actions 中运行测试 (`.github/workflows/ci.yml`):

```yaml
test:
  name: Run Tests
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.44.8'
    
    - name: Get dependencies
      run: flutter pub get
    
    - name: Run tests
      run: flutter test --coverage
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        files: ./coverage/lcov.info
```

---

## 性能测试

对于性能敏感的代码 (如文档切分、搜索),编写性能基准测试:

**`test/performance/semantic_chunker_benchmark.dart`**:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:anchor_learning/services/ingestion/semantic_chunker.dart';

void main() {
  test('切分大型 Markdown 文档性能', () {
    final chunker = SemanticChunker();
    final largeMarkdown = _generateLargeMarkdown(lines: 10000);

    final stopwatch = Stopwatch()..start();
    final chunks = chunker.chunkMarkdown(largeMarkdown, locatorPrefix: 'test');
    stopwatch.stop();

    print('Chunked ${largeMarkdown.length} chars into ${chunks.length} chunks '
          'in ${stopwatch.elapsedMilliseconds}ms');

    expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5秒内完成
  });
}
```

---

## 下一步

- 查看 [贡献指南](../CONTRIBUTING.md) 了解代码审查要求
- 参考 [架构文档](./architecture/SYSTEM_OVERVIEW.md) 理解测试边界
- 运行 `flutter test` 验证现有测试通过

---

## 常见问题

### 1. 测试运行很慢

- 检查是否有异步操作未正确 await
- 使用内存数据库而非文件数据库
- 避免在测试中调用真实 API

### 2. Mock 生成失败

```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### 3. 覆盖率报告不准确

确保运行前清理旧数据:

```bash
rm -rf coverage
flutter test --coverage
```
