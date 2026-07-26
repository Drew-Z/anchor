import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../data/models/source_chunk.dart';

/// 语义切分器 - 按文档结构(标题/代码块/列表)切分,而非固定字数
///
/// 参考: aicoding-cookbook/docs-to-book 的 codebase-survey.md
/// 核心原则: 保持语义完整性,不破坏段落/代码块/列表边界
class SemanticChunker {
  /// 目标 chunk 大小(字符数)
  static const int targetChunkSize = 1500;

  /// 最小 chunk 大小(避免切太碎)
  static const int minChunkSize = 500;

  /// 最大 chunk 大小(避免单个 chunk 太大)
  static const int maxChunkSize = 3000;

  /// 按语义结构切分 Markdown 文档
  ///
  /// 返回的每个 chunk 包含:
  /// - content: 切分后的内容
  /// - locator: 定位信息(如 "## 架构设计" 章节标题)
  /// - startLine/endLine: 行号范围(便于溯源)
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
