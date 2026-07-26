import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../data/models/source_chunk.dart';

/// 语义切分服务 - 将文档切分为可引用的最小语义单元
///
/// **设计理念**:
/// 传统的固定字数切分(如每500字一块)会破坏文档结构,导致:
/// - 代码块被截断,语法不完整
/// - 段落被切断,语义不连贯
/// - 引用溯源时难以定位
///
/// SemanticChunker 按文档的 **自然结构** 切分:
/// - **Markdown**: 按标题层级(##, ###)切分,保持章节完整性
/// - **代码**: 按函数/类边界切分,保留精确行号
/// - **纯文本**: 按段落(空行)切分,保持段落连贯性
///
/// **核心优势**:
/// 1. **语义完整**: 每个 chunk 是独立可理解的单元
/// 2. **精确溯源**: 生成人类可读的 locator
///    - 示例: `README.md → ## 快速开始 → ### 安装步骤`
///    - 示例: `lib/main.dart:15-42`
/// 3. **AI 友好**: 切分边界与 AI 理解边界一致,提升题目质量
///
/// **使用示例**:
/// ```dart
/// final chunker = SemanticChunker();
///
/// // Markdown 文档
/// final markdownChunks = chunker.chunkMarkdown(
///   sourceId: 'source_123',
///   markdown: markdownContent,
///   baseLocator: 'README.md',
///   createdAt: DateTime.now(),
/// );
///
/// // 代码文件
/// final codeChunks = chunker.chunkCode(
///   sourceId: 'source_456',
///   code: codeContent,
///   filePath: 'lib/main.dart',
///   createdAt: DateTime.now(),
/// );
/// ```
///
/// **参考**: aicoding-cookbook/docs-to-book 的 semantic chunking 策略
class SemanticChunker {
  /// 目标 chunk 大小(字符数)
  ///
  /// 经验值: 1500字符约对应 GPT-3.5 的 400 tokens,在上下文窗口中
  /// 既能保持足够信息密度,又不会占用过多 token
  static const int targetChunkSize = 1500;

  /// 最小 chunk 大小(避免切太碎)
  ///
  /// 过小的 chunk 缺乏上下文,AI 难以理解其含义
  static const int minChunkSize = 500;

  /// 最大 chunk 大小(避免单个 chunk 太大)
  ///
  /// 过大的 chunk 会让 AI 提取知识点时遗漏细节
  static const int maxChunkSize = 3000;

  /// 按语义结构切分 Markdown 文档
  ///
  /// **切分策略**:
  /// 1. 提取文档中的所有标题(##, ###, ####)
  /// 2. 按标题层级划分章节
  /// 3. 如果章节内容 ≤ 3000字符,整个章节作为一个 chunk
  /// 4. 如果章节内容过大,进一步按段落/代码块边界切分
  ///
  /// **关键设计**:
  /// - **不破坏代码块**: 检测 ``` 边界,代码块内不切分
  /// - **保持段落完整**: 在空行处切分,不截断段落
  /// - **生成可读 locator**: `README.md → ## 快速开始 → ### 安装`
  ///
  /// **参数**:
  /// - [sourceId]: 所属源文档ID
  /// - [markdown]: Markdown 内容
  /// - [baseLocator]: 基础定位符(通常是文件名)
  /// - [createdAt]: 创建时间
  ///
  /// **返回**: 切分后的 SourceChunk 列表,每个 chunk 包含:
  /// - `content`: 切分后的内容
  /// - `locator`: 定位信息(如 "README.md → ## 架构设计")
  /// - `startLine`/`endLine`: 行号范围(便于溯源)
  List<SourceChunk> chunkMarkdown({
    required String sourceId,
    required String markdown,
    required DateTime createdAt,
    String? baseLocator,
  }) {
    if (markdown.trim().isEmpty) return [];

    final lines = markdown.split('\n');
    final chunks = <SourceChunk>[];

    // 解析文档结构:提取所有标题及其位置
    final sections = _extractSections(lines);

    if (sections.isEmpty) {
      // 无标题的纯文本,按段落切分
      return _chunkPlainText(
        sourceId: sourceId,
        lines: lines,
        createdAt: createdAt,
        baseLocator: baseLocator,
      );
    }

    // 按标题层级切分
    for (int i = 0; i < sections.length; i++) {
      final section = sections[i];
      final nextSectionStart =
          i + 1 < sections.length ? sections[i + 1].startLine : lines.length;

      final sectionLines = lines.sublist(section.startLine, nextSectionStart);
      final sectionContent = sectionLines.join('\n').trim();

      if (sectionContent.isEmpty) continue;

      // 如果章节内容小于目标大小,整个章节作为一个 chunk
      if (sectionContent.length <= maxChunkSize) {
        chunks.add(_createChunk(
          sourceId: sourceId,
          chunkIndex: chunks.length,
          content: sectionContent,
          locator: _buildLocator(baseLocator, section.title),
          startLine: section.startLine + 1,
          endLine: nextSectionStart,
          createdAt: createdAt,
        ));
        continue;
      }

      // 章节内容过大,进一步按段落/代码块切分
      final subChunks = _chunkSectionContent(
        sourceId: sourceId,
        startChunkIndex: chunks.length,
        lines: sectionLines,
        sectionTitle: section.title,
        sectionStartLine: section.startLine,
        baseLocator: baseLocator,
        createdAt: createdAt,
      );
      chunks.addAll(subChunks);
    }

    return chunks;
  }

  /// 切分纯代码文件(无 Markdown 标题)
  ///
  /// **切分策略**:
  /// - 按固定行数(约100行)切分,但尽量保持函数/类边界完整
  /// - 简单策略: 向前查找空行作为边界
  /// - 生成精确的行号定位: `lib/main.dart:15-42`
  ///
  /// **为什么按行数而非字符数**:
  /// - 代码定位习惯按行号(IDE跳转、错误提示都是行号)
  /// - 保持与原文件的对应关系,便于用户溯源
  ///
  /// **参数**:
  /// - [sourceId]: 所属源文档ID
  /// - [code]: 代码内容
  /// - [filePath]: 文件路径(用于生成 locator)
  /// - [createdAt]: 创建时间
  ///
  /// **返回**: 切分后的 SourceChunk 列表,每个 chunk 的 locator 格式为:
  /// `<filePath>:<startLine>-<endLine>`
  List<SourceChunk> chunkCode({
    required String sourceId,
    required String code,
    required String? filePath,
    required DateTime createdAt,
  }) {
    if (code.trim().isEmpty) return [];

    final lines = code.split('\n');
    final chunks = <SourceChunk>[];

    // 代码按固定行数切分,但保持函数/类边界完整
    int startLine = 0;
    while (startLine < lines.length) {
      int endLine = (startLine + 100).clamp(0, lines.length);

      // 向前找到完整的函数/类结束(简单策略:找到下一个空行)
      while (endLine < lines.length && lines[endLine].trim().isNotEmpty) {
        endLine++;
      }

      final chunkLines = lines.sublist(startLine, endLine);
      final content = chunkLines.join('\n').trim();

      if (content.isNotEmpty) {
        chunks.add(_createChunk(
          sourceId: sourceId,
          chunkIndex: chunks.length,
          content: content,
          locator: filePath != null ? '$filePath:${startLine + 1}-$endLine' : null,
          startLine: startLine + 1,
          endLine: endLine,
          createdAt: createdAt,
        ));
      }

      startLine = endLine;
    }

    return chunks;
  }

  /// 提取文档中的所有标题及其位置
  List<_Section> _extractSections(List<String> lines) {
    final sections = <_Section>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(line);

      if (match != null) {
        final level = match.group(1)!.length;
        final title = match.group(2)!.trim();
        sections.add(_Section(
          level: level,
          title: title,
          startLine: i,
        ));
      }
    }

    return sections;
  }

  /// 按段落切分纯文本(无标题结构)
  List<SourceChunk> _chunkPlainText({
    required String sourceId,
    required List<String> lines,
    required DateTime createdAt,
    String? baseLocator,
  }) {
    final chunks = <SourceChunk>[];
    final buffer = StringBuffer();
    int chunkStartLine = 0;
    int currentLine = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      buffer.writeln(line);
      currentLine = i;

      // 遇到空行且累积内容达到目标大小,切分
      if (line.trim().isEmpty && buffer.length >= minChunkSize) {
        final content = buffer.toString().trim();
        if (content.isNotEmpty) {
          chunks.add(_createChunk(
            sourceId: sourceId,
            chunkIndex: chunks.length,
            content: content,
            locator: baseLocator,
            startLine: chunkStartLine + 1,
            endLine: currentLine + 1,
            createdAt: createdAt,
          ));
        }
        buffer.clear();
        chunkStartLine = i + 1;
      }

      // 内容过大,强制切分
      if (buffer.length >= maxChunkSize) {
        final content = buffer.toString().trim();
        if (content.isNotEmpty) {
          chunks.add(_createChunk(
            sourceId: sourceId,
            chunkIndex: chunks.length,
            content: content,
            locator: baseLocator,
            startLine: chunkStartLine + 1,
            endLine: currentLine + 1,
            createdAt: createdAt,
          ));
        }
        buffer.clear();
        chunkStartLine = i + 1;
      }
    }

    // 剩余内容
    if (buffer.isNotEmpty) {
      final content = buffer.toString().trim();
      if (content.isNotEmpty) {
        chunks.add(_createChunk(
          sourceId: sourceId,
          chunkIndex: chunks.length,
          content: content,
          locator: baseLocator,
          startLine: chunkStartLine + 1,
          endLine: lines.length,
          createdAt: createdAt,
        ));
      }
    }

    return chunks;
  }

  /// 切分章节内容(按代码块/列表/段落边界)
  List<SourceChunk> _chunkSectionContent({
    required String sourceId,
    required int startChunkIndex,
    required List<String> lines,
    required String sectionTitle,
    required int sectionStartLine,
    String? baseLocator,
    required DateTime createdAt,
  }) {
    final chunks = <SourceChunk>[];
    final buffer = StringBuffer();
    int chunkStartLine = 0;
    bool inCodeBlock = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // 检测代码块边界
      if (line.trimLeft().startsWith('```')) {
        inCodeBlock = !inCodeBlock;
      }

      buffer.writeln(line);

      // 代码块内不切分
      if (inCodeBlock) continue;

      // 遇到空行且累积内容达到目标大小,切分
      if (line.trim().isEmpty && buffer.length >= minChunkSize) {
        final content = buffer.toString().trim();
        if (content.isNotEmpty) {
          chunks.add(_createChunk(
            sourceId: sourceId,
            chunkIndex: startChunkIndex + chunks.length,
            content: content,
            locator: _buildLocator(baseLocator, sectionTitle),
            startLine: sectionStartLine + chunkStartLine + 1,
            endLine: sectionStartLine + i + 1,
            createdAt: createdAt,
          ));
        }
        buffer.clear();
        chunkStartLine = i + 1;
      }

      // 内容过大,强制切分(但保持代码块完整)
      if (buffer.length >= maxChunkSize && !inCodeBlock) {
        final content = buffer.toString().trim();
        if (content.isNotEmpty) {
          chunks.add(_createChunk(
            sourceId: sourceId,
            chunkIndex: startChunkIndex + chunks.length,
            content: content,
            locator: _buildLocator(baseLocator, sectionTitle),
            startLine: sectionStartLine + chunkStartLine + 1,
            endLine: sectionStartLine + i + 1,
            createdAt: createdAt,
          ));
        }
        buffer.clear();
        chunkStartLine = i + 1;
      }
    }

    // 剩余内容
    if (buffer.isNotEmpty) {
      final content = buffer.toString().trim();
      if (content.isNotEmpty) {
        chunks.add(_createChunk(
          sourceId: sourceId,
          chunkIndex: startChunkIndex + chunks.length,
          content: content,
          locator: _buildLocator(baseLocator, sectionTitle),
          startLine: sectionStartLine + chunkStartLine + 1,
          endLine: sectionStartLine + lines.length,
          createdAt: createdAt,
        ));
      }
    }

    return chunks;
  }

  /// 构建 locator(层级路径)
  String? _buildLocator(String? base, String section) {
    if (base == null || base.isEmpty) return section;
    return '$base → $section';
  }

  /// 创建 SourceChunk 实例
  SourceChunk _createChunk({
    required String sourceId,
    required int chunkIndex,
    required String content,
    String? locator,
    int? startLine,
    int? endLine,
    required DateTime createdAt,
  }) {
    final contentHash = sha256.convert(utf8.encode(content)).toString();

    return SourceChunk(
      id: '${sourceId}_chunk_$chunkIndex',
      sourceId: sourceId,
      chunkIndex: chunkIndex,
      content: content,
      locator: locator,
      startLine: startLine,
      endLine: endLine,
      contentHash: contentHash,
      createdAt: createdAt,
    );
  }
}

/// 文档章节结构
class _Section {
  final int level;       // 标题层级(1-6)
  final String title;    // 标题文本
  final int startLine;   // 起始行号

  _Section({
    required this.level,
    required this.title,
    required this.startLine,
  });
}
