import 'package:flutter_test/flutter_test.dart';
import 'package:dlg_q/services/validation/question_validator.dart';
import 'package:dlg_q/data/models/question.dart';
import 'package:dlg_q/data/models/source_chunk.dart';

void main() {
  late QuestionValidator validator;

  setUp(() {
    validator = QuestionValidator();
  });

  group('QuestionValidator - MultipleChoice', () {
    test('数字在原文中存在 - 通过验证', () async {
      final question = Question(
        id: 'q1',
        deckId: 'deck1',
        type: QuestionType.multipleChoice,
        content: 'Flutter 支持多少种布局模式?',
        options: ['2种', '3种', '4种', '5种'],
        answer: '3种',
        explanation: '',
        createdAt: DateTime.now(),
      );

      final chunks = [
        SourceChunk(
          id: 'c1',
          sourceId: 's1',
          chunkIndex: 0,
          content: 'Flutter 提供了 3 种主要的布局模式:Flex、Stack 和 Constraints。',
          createdAt: DateTime.now(),
        ),
      ];

      final result = await validator.validate(
        question: question,
        sourceChunks: chunks,
      );

      expect(result.isValid, isTrue);
      expect(result.issues, isEmpty);
    });

    test('数字在原文中不存在 - 验证失败', () async {
      final question = Question(
        id: 'q1',
        deckId: 'deck1',
        type: QuestionType.multipleChoice,
        content: 'Flutter 支持多少种布局?',
        options: ['5种', '6种', '7种', '8种'],
        answer: '7种',
        explanation: '',
        createdAt: DateTime.now(),
      );

      final chunks = [
        SourceChunk(
          id: 'c1',
          sourceId: 's1',
          chunkIndex: 0,
          content: 'Flutter 提供了 3 种主要的布局模式。',
          createdAt: DateTime.now(),
        ),
      ];

      final result = await validator.validate(
        question: question,
        sourceChunks: chunks,
      );

      expect(result.isValid, isFalse);
      expect(result.issues.any((i) => i.contains('7种')), isTrue);
    });

    test('正确答案无原文支撑 - 验证失败', () async {
      final question = Question(
        id: 'q1',
        deckId: 'deck1',
        type: QuestionType.multipleChoice,
        content: 'Dart 的特性是?',
        options: ['强类型', '编译型', '动态链接', '解释型'],
        answer: '动态链接', // 这个在原文中不存在
        explanation: '',
        createdAt: DateTime.now(),
      );

      final chunks = [
        SourceChunk(
          id: 'c1',
          sourceId: 's1',
          chunkIndex: 0,
          content: 'Dart 是强类型的编译型语言。',
          createdAt: DateTime.now(),
        ),
      ];

      final result = await validator.validate(
        question: question,
        sourceChunks: chunks,
      );

      expect(result.isValid, isFalse);
      expect(result.issues.any((i) => i.contains('正确答案')), isTrue);
    });
  });

  group('QuestionValidator - FillInBlank', () {
    test('答案在原文中存在 - 通过验证', () async {
      final question = Question(
        id: 'q1',
        deckId: 'deck1',
        type: QuestionType.fillInBlank,
        content: 'Flutter 的 UI 框架基于___设计。',
        answer: 'Widget',
        explanation: '',
        createdAt: DateTime.now(),
      );

      final chunks = [
        SourceChunk(
          id: 'c1',
          sourceId: 's1',
          chunkIndex: 0,
          content: 'Flutter 的 UI 框架基于 Widget 设计,一切皆 Widget。',
          createdAt: DateTime.now(),
        ),
      ];

      final result = await validator.validate(
        question: question,
        sourceChunks: chunks,
      );

      expect(result.isValid, isTrue);
    });

    test('答案在原文中不存在 - 验证失败', () async {
      final question = Question(
        id: 'q1',
        deckId: 'deck1',
        type: QuestionType.fillInBlank,
        content: 'Flutter 使用___语言开发。',
        answer: 'Kotlin', // 错误答案
        explanation: '',
        createdAt: DateTime.now(),
      );

      final chunks = [
        SourceChunk(
          id: 'c1',
          sourceId: 's1',
          chunkIndex: 0,
          content: 'Flutter 使用 Dart 语言开发。',
          createdAt: DateTime.now(),
        ),
      ];

      final result = await validator.validate(
        question: question,
        sourceChunks: chunks,
      );

      expect(result.isValid, isFalse);
      expect(result.issues.any((i) => i.contains('Kotlin')), isTrue);
    });

    test('代码片段在原文中存在 - 通过验证', () async {
      final question = Question(
        id: 'q1',
        deckId: 'deck1',
        type: QuestionType.fillInBlank,
        content:
            '以下代码片段用于创建按钮:\n```dart\nElevatedButton(\n  onPressed: () {},\n  child: Text(___),\n)\n```',
        answer: "'Click Me'",
        explanation: '',
        createdAt: DateTime.now(),
      );

      final chunks = [
        SourceChunk(
          id: 'c1',
          sourceId: 's1',
          chunkIndex: 0,
          content: '''
示例代码:
```dart
ElevatedButton(
  onPressed: () {},
  child: Text('Click Me'),
)
```
''',
          createdAt: DateTime.now(),
        ),
      ];

      final result = await validator.validate(
        question: question,
        sourceChunks: chunks,
      );

      expect(result.isValid, isTrue);
    });
  });

  group('QuestionValidator - TrueFalse', () {
    test('陈述在原文中有支撑 - 通过验证', () async {
      final question = Question(
        id: 'q1',
        deckId: 'deck1',
        type: QuestionType.trueFalse,
        content: 'Flutter 是跨平台框架',
        options: ['正确', '错误'],
        answer: '正确',
        explanation: '',
        createdAt: DateTime.now(),
      );

      final chunks = [
        SourceChunk(
          id: 'c1',
          sourceId: 's1',
          chunkIndex: 0,
          content: 'Flutter 是 Google 推出的跨平台移动应用开发框架。',
          createdAt: DateTime.now(),
        ),
      ];

      final result = await validator.validate(
        question: question,
        sourceChunks: chunks,
      );

      expect(result.isValid, isTrue);
    });

    test('包含否定性陈述 - 需要人工复核', () async {
      final question = Question(
        id: 'q1',
        deckId: 'deck1',
        type: QuestionType.trueFalse,
        content: 'Flutter 不支持热重载',
        options: ['正确', '错误'],
        answer: '错误',
        explanation: '',
        createdAt: DateTime.now(),
      );

      final chunks = [
        SourceChunk(
          id: 'c1',
          sourceId: 's1',
          chunkIndex: 0,
          content: 'Flutter 支持热重载功能。',
          createdAt: DateTime.now(),
        ),
      ];

      final result = await validator.validate(
        question: question,
        sourceChunks: chunks,
      );

      // 包含否定陈述,需要人工复核
      expect(result.issues.any((i) => i.contains('否定性陈述')), isTrue);
      expect(result.needsManualReview, isTrue);
    });

    test('关键词匹配率过低 - 验证失败', () async {
      final question = Question(
        id: 'q1',
        deckId: 'deck1',
        type: QuestionType.trueFalse,
        content: 'React Native 使用 JavaScript 开发',
        options: ['正确', '错误'],
        answer: '正确',
        explanation: '',
        createdAt: DateTime.now(),
      );

      final chunks = [
        SourceChunk(
          id: 'c1',
          sourceId: 's1',
          chunkIndex: 0,
          content: 'Flutter 使用 Dart 语言开发移动应用。',
          createdAt: DateTime.now(),
        ),
      ];

      final result = await validator.validate(
        question: question,
        sourceChunks: chunks,
      );

      expect(result.isValid, isFalse);
      expect(result.issues.any((i) => i.contains('匹配率过低')), isTrue);
    });
  });

  group('QuestionValidator - Matching', () {
    test('匹配项在原文中存在 - 通过验证', () async {
      final question = Question(
        id: 'q1',
        deckId: 'deck1',
        type: QuestionType.matching,
        content: '将 Widget 与其功能匹配',
        matchLeft: ['Container', 'Text', 'Image'],
        matchRight: ['显示图片', '显示文本', '布局容器'],
        answer: 'Container-布局容器|Text-显示文本|Image-显示图片',
        explanation: '',
        createdAt: DateTime.now(),
      );

      final chunks = [
        SourceChunk(
          id: 'c1',
          sourceId: 's1',
          chunkIndex: 0,
          content: '''
Flutter 常用 Widget:
- Container: 布局容器,用于设置边距、背景等
- Text: 显示文本内容
- Image: 显示图片资源
''',
          createdAt: DateTime.now(),
        ),
      ];

      final result = await validator.validate(
        question: question,
        sourceChunks: chunks,
      );

      expect(result.isValid, isTrue);
    });

    test('匹配关系无依据 - 验证失败', () async {
      final question = Question(
        id: 'q1',
        deckId: 'deck1',
        type: QuestionType.matching,
        content: '匹配',
        matchLeft: ['A', 'B'],
        matchRight: ['X', 'Y'],
        answer: 'A-X|B-Y',
        explanation: '',
        createdAt: DateTime.now(),
      );

      final chunks = [
        SourceChunk(
          id: 'c1',
          sourceId: 's1',
          chunkIndex: 0,
          content: 'A 和 B 是两个概念。X 和 Y 是另外的概念。', // 没有关联
          createdAt: DateTime.now(),
        ),
      ];

      final result = await validator.validate(
        question: question,
        sourceChunks: chunks,
      );

      expect(result.isValid, isFalse);
      expect(result.issues.any((i) => i.contains('找不到依据')), isTrue);
    });
  });

  group('QuestionValidator - Ordering', () {
    test('步骤顺序与原文一致 - 通过验证', () async {
      final question = Question(
        id: 'q1',
        deckId: 'deck1',
        type: QuestionType.ordering,
        content: '排列 Flutter 项目创建步骤',
        options: ['创建项目', '安装依赖', '运行应用', '编写代码'],
        answer: '创建项目|安装依赖|编写代码|运行应用',
        explanation: '',
        createdAt: DateTime.now(),
      );

      final chunks = [
        SourceChunk(
          id: 'c1',
          sourceId: 's1',
          chunkIndex: 0,
          content: '''
Flutter 开发流程:
1. 创建项目: flutter create my_app
2. 安装依赖: flutter pub get
3. 编写代码: 在 lib/main.dart 中实现功能
4. 运行应用: flutter run
''',
          createdAt: DateTime.now(),
        ),
      ];

      final result = await validator.validate(
        question: question,
        sourceChunks: chunks,
      );

      expect(result.isValid, isTrue);
    });

    test('步骤在原文中不存在 - 验证失败', () async {
      final question = Question(
        id: 'q1',
        deckId: 'deck1',
        type: QuestionType.ordering,
        content: '排列步骤',
        options: ['步骤1', '步骤2', '步骤3'],
        answer: '步骤1|步骤2|步骤3',
        explanation: '',
        createdAt: DateTime.now(),
      );

      final chunks = [
        SourceChunk(
          id: 'c1',
          sourceId: 's1',
          chunkIndex: 0,
          content: 'Flutter 是一个框架。', // 不包含这些步骤
          createdAt: DateTime.now(),
        ),
      ];

      final result = await validator.validate(
        question: question,
        sourceChunks: chunks,
      );

      expect(result.isValid, isFalse);
      expect(result.issues.any((i) => i.contains('不存在')), isTrue);
    });
  });

  group('QuestionValidator - Batch', () {
    test('批量验证多道题目', () async {
      final questions = [
        Question(
          id: 'q1',
          deckId: 'deck1',
          type: QuestionType.multipleChoice,
          content: 'Flutter 使用什么语言?',
          options: ['Dart', 'Java', 'Kotlin', 'Swift'],
          answer: 'Dart',
          explanation: '',
          createdAt: DateTime.now(),
        ),
        Question(
          id: 'q2',
          deckId: 'deck1',
          type: QuestionType.fillInBlank,
          content: 'Flutter 的核心是___。',
          answer: 'Widget',
          explanation: '',
          createdAt: DateTime.now(),
        ),
      ];

      final chunks = [
        SourceChunk(
          id: 'c1',
          sourceId: 's1',
          chunkIndex: 0,
          content: 'Flutter 使用 Dart 语言开发,核心概念是 Widget。',
          createdAt: DateTime.now(),
        ),
      ];

      final results = await validator.validateBatch(
        questions: questions,
        sourceChunks: chunks,
      );

      expect(results.length, equals(2));
      expect(results['q1']?.isValid, isTrue);
      expect(results['q2']?.isValid, isTrue);
    });
  });

  group('QuestionValidator - Confidence', () {
    test('无问题时置信度为 1.0', () async {
      final question = Question(
        id: 'q1',
        deckId: 'deck1',
        type: QuestionType.trueFalse,
        content: 'Flutter 是框架',
        options: ['正确', '错误'],
        answer: '正确',
        explanation: '',
        createdAt: DateTime.now(),
      );

      final chunks = [
        SourceChunk(
          id: 'c1',
          sourceId: 's1',
          chunkIndex: 0,
          content: 'Flutter 是一个跨平台的移动应用开发框架。',
          createdAt: DateTime.now(),
        ),
      ];

      final result = await validator.validate(
        question: question,
        sourceChunks: chunks,
      );

      expect(result.confidence, equals(1.0));
      expect(result.needsManualReview, isFalse);
    });

    test('有问题时置信度降低', () async {
      final question = Question(
        id: 'q1',
        deckId: 'deck1',
        type: QuestionType.multipleChoice,
        content: '测试',
        options: ['A', 'B', 'C', 'D'],
        answer: 'A',
        explanation: '',
        createdAt: DateTime.now(),
      );

      final chunks = [
        SourceChunk(
          id: 'c1',
          sourceId: 's1',
          chunkIndex: 0,
          content: '完全不相关的内容。',
          createdAt: DateTime.now(),
        ),
      ];

      final result = await validator.validate(
        question: question,
        sourceChunks: chunks,
      );

      expect(result.confidence, lessThan(1.0));
      expect(result.needsManualReview, isTrue);
    });
  });
}
