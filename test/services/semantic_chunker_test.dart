import 'package:flutter_test/flutter_test.dart';
import 'package:dlg_q/services/ingestion/semantic_chunker.dart';

void main() {
  late SemanticChunker chunker;

  setUp(() {
    chunker = SemanticChunker();
  });

  group('SemanticChunker - Markdown', () {
    test('按标题切分章节', () {
      final markdown = '''
# 第一章

这是第一章的内容。

## 1.1 小节

这是小节的内容。

# 第二章

这是第二章的内容,包含更多细节。
''';

      final chunks = chunker.chunkMarkdown(
        sourceId: 'test_source',
        markdown: markdown,
        createdAt: DateTime.now(),
      );

      expect(chunks.length, greaterThan(0));
      expect(chunks[0].locator, contains('第一章'));
      expect(chunks[0].startLine, equals(1));
    });

    test('保持代码块完整性', () {
      final markdown = '''
## 代码示例

下面是一个例子:

```dart
class Example {
  void method() {
    print('hello');
  }
}
```

这段代码展示了...
''';

      final chunks = chunker.chunkMarkdown(
        sourceId: 'test_source',
        markdown: markdown,
        createdAt: DateTime.now(),
      );

      // 代码块不应该被切分
      final hasCompleteCodeBlock = chunks.any(
        (chunk) =>
            chunk.content.contains('```dart') && chunk.content.contains('```'),
      );
      expect(hasCompleteCodeBlock, isTrue);
    });

    test('大章节自动子切分', () {
      // 构造一个超过 3000 字的大章节
      final largeParagraph = '这是一段很长的文字。' * 200; // ~2000 字
      final markdown = '''
# 大章节

$largeParagraph

$largeParagraph
''';

      final chunks = chunker.chunkMarkdown(
        sourceId: 'test_source',
        markdown: markdown,
        createdAt: DateTime.now(),
      );

      // 应该被切分成多个 chunk
      expect(chunks.length, greaterThan(1));

      // 每个 chunk 不应该超过最大限制
      for (final chunk in chunks) {
        expect(chunk.content.length,
            lessThanOrEqualTo(SemanticChunker.maxChunkSize + 500));
      }
    });

    test('无标题纯文本按段落切分', () {
      final text = '''
这是第一段。

这是第二段,内容较长${'。' * 200}

这是第三段。
''';

      final chunks = chunker.chunkMarkdown(
        sourceId: 'test_source',
        markdown: text,
        createdAt: DateTime.now(),
      );

      expect(chunks.length, greaterThan(0));
      // 应该按段落(空行)边界切分
    });

    test('locator 包含层级信息', () {
      final markdown = '''
# 顶层

## 子章节

内容
''';

      final chunks = chunker.chunkMarkdown(
        sourceId: 'test_source',
        markdown: markdown,
        createdAt: DateTime.now(),
        baseLocator: 'README.md',
      );

      // locator 应该包含完整路径
      expect(
          chunks.any((c) => c.locator?.contains('README.md') ?? false), isTrue);
    });

    test('空内容返回空列表', () {
      final chunks = chunker.chunkMarkdown(
        sourceId: 'test_source',
        markdown: '',
        createdAt: DateTime.now(),
      );

      expect(chunks, isEmpty);
    });

    test('chunk 包含行号信息', () {
      final markdown = '''
# 标题

第一行
第二行
第三行
''';

      final chunks = chunker.chunkMarkdown(
        sourceId: 'test_source',
        markdown: markdown,
        createdAt: DateTime.now(),
      );

      expect(chunks[0].startLine, isNotNull);
      expect(chunks[0].endLine, isNotNull);
      expect(chunks[0].endLine! > chunks[0].startLine!, isTrue);
    });
  });

  group('SemanticChunker - Code', () {
    test('按固定行数切分代码', () {
      final code = List.generate(150, (i) => 'line $i').join('\n');

      final chunks = chunker.chunkCode(
        sourceId: 'test_source',
        code: code,
        filePath: 'main.dart',
        createdAt: DateTime.now(),
      );

      expect(chunks.length, greaterThan(1));
    });

    test('遵守自定义最大行数', () {
      final code = List.generate(5, (i) => 'line $i').join('\n');

      final chunks = chunker.chunkCode(
        sourceId: 'test_source',
        code: code,
        filePath: 'main.dart',
        createdAt: DateTime.now(),
        maxLinesPerChunk: 2,
      );

      expect(chunks, hasLength(3));
      expect(chunks.map((chunk) => chunk.endLine), [2, 4, 5]);
    });

    test('拒绝非正数最大行数', () {
      expect(
        () => chunker.chunkCode(
          sourceId: 'test_source',
          code: 'line 1',
          filePath: 'main.dart',
          createdAt: DateTime.now(),
          maxLinesPerChunk: 0,
        ),
        throwsArgumentError,
      );
    });

    test('locator 包含文件路径和行号', () {
      final code = 'void main() {}\n' * 50;

      final chunks = chunker.chunkCode(
        sourceId: 'test_source',
        code: code,
        filePath: 'lib/main.dart',
        createdAt: DateTime.now(),
      );

      expect(chunks[0].locator, contains('lib/main.dart'));
      expect(chunks[0].locator, contains(':'));
    });

    test('空代码返回空列表', () {
      final chunks = chunker.chunkCode(
        sourceId: 'test_source',
        code: '',
        filePath: 'empty.dart',
        createdAt: DateTime.now(),
      );

      expect(chunks, isEmpty);
    });
  });

  group('SemanticChunker - ContentHash', () {
    test('相同内容生成相同 hash', () {
      final markdown = '# 测试\n\n内容';

      final chunks1 = chunker.chunkMarkdown(
        sourceId: 'test1',
        markdown: markdown,
        createdAt: DateTime.now(),
      );

      final chunks2 = chunker.chunkMarkdown(
        sourceId: 'test2',
        markdown: markdown,
        createdAt: DateTime.now(),
      );

      // 内容相同,hash 应该相同(用于增量更新检测)
      expect(chunks1[0].contentHash, equals(chunks2[0].contentHash));
    });

    test('不同内容生成不同 hash', () {
      final chunks1 = chunker.chunkMarkdown(
        sourceId: 'test',
        markdown: '# 版本1',
        createdAt: DateTime.now(),
      );

      final chunks2 = chunker.chunkMarkdown(
        sourceId: 'test',
        markdown: '# 版本2',
        createdAt: DateTime.now(),
      );

      expect(chunks1[0].contentHash, isNot(equals(chunks2[0].contentHash)));
    });
  });

  group('SemanticChunker - Edge Cases', () {
    test('处理多层嵌套标题', () {
      final markdown = '''
# H1
## H2
### H3
#### H4
内容
''';

      final chunks = chunker.chunkMarkdown(
        sourceId: 'test',
        markdown: markdown,
        createdAt: DateTime.now(),
      );

      expect(chunks, isNotEmpty);
    });

    test('处理连续空行', () {
      final markdown = '''
段落1


段落2



段落3
''';

      final chunks = chunker.chunkMarkdown(
        sourceId: 'test',
        markdown: markdown,
        createdAt: DateTime.now(),
      );

      expect(chunks, isNotEmpty);
    });

    test('处理特殊字符', () {
      final markdown = '''
# 标题 「特殊」

内容包含 <html> & 符号
''';

      final chunks = chunker.chunkMarkdown(
        sourceId: 'test',
        markdown: markdown,
        createdAt: DateTime.now(),
      );

      expect(chunks[0].content, contains('特殊'));
      expect(chunks[0].content, contains('<html>'));
    });
  });
}
