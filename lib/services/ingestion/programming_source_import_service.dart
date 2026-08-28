import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../data/models/source.dart';
import '../../data/models/source_chunk.dart';
import 'semantic_chunker.dart';

class ProgrammingSourceImportDraft {
  final String title;
  final String content;
  final SourceTrustLevel trustLevel;
  final String? uri;
  final String? publisher;
  final String? revision;
  final String? licenseExpression;

  const ProgrammingSourceImportDraft({
    required this.title,
    required this.content,
    required this.trustLevel,
    this.uri,
    this.publisher,
    this.revision,
    this.licenseExpression,
  });

  bool get requiresAuditableProvenance =>
      trustLevel == SourceTrustLevel.officialDoc ||
      trustLevel == SourceTrustLevel.sourceCode;
}

class ProgrammingSourceImportValidation {
  final List<String> errors;

  const ProgrammingSourceImportValidation(this.errors);

  bool get isValid => errors.isEmpty;
}

class ProgrammingSourceSnapshot {
  final Source source;
  final List<SourceChunk> chunks;

  const ProgrammingSourceSnapshot({
    required this.source,
    required this.chunks,
  });
}

class ProgrammingSourceImportService {
  static const int maxChunkCharacters = 1800;

  final SemanticChunker _semanticChunker;

  const ProgrammingSourceImportService({
    SemanticChunker? semanticChunker,
  }) : _semanticChunker = semanticChunker ?? const SemanticChunker();

  ProgrammingSourceImportValidation validate(
    ProgrammingSourceImportDraft draft,
  ) {
    final errors = <String>[];
    final title = draft.title.trim();
    final content = draft.content.trim();

    if (title.isEmpty) errors.add('请填写来源标题');
    if (content.isEmpty) errors.add('请粘贴要学习的来源正文');

    if (draft.requiresAuditableProvenance) {
      final uriText = draft.uri?.trim() ?? '';
      final publisher = draft.publisher?.trim() ?? '';
      final revision = draft.revision?.trim() ?? '';
      if (uriText.isEmpty) {
        errors.add('官方文档或源码必须填写规范来源 URL');
      } else if (!_isSupportedCanonicalUri(uriText)) {
        errors.add('规范来源 URL 必须是完整的 http 或 https 地址');
      }
      if (publisher.isEmpty) {
        errors.add('官方文档或源码必须填写发布者或仓库所有者');
      }
      if (revision.isEmpty) {
        errors.add('官方文档或源码必须填写文档版本、tag 或 commit revision');
      }
    }

    return ProgrammingSourceImportValidation(errors);
  }

  ProgrammingSourceSnapshot buildSnapshot({
    required ProgrammingSourceImportDraft draft,
    required String sourceId,
    required DateTime retrievedAt,
  }) {
    final validation = validate(draft);
    if (!validation.isValid) {
      throw ArgumentError(validation.errors.join('\n'));
    }

    final normalizedContent = _normalizeContent(draft.content);
    final normalizedUri = _optionalText(draft.uri);
    final source = Source(
      id: sourceId,
      title: draft.title.trim(),
      type: _sourceTypeFor(draft.trustLevel),
      uri: normalizedUri,
      revision: _optionalText(draft.revision),
      publisher: _optionalText(draft.publisher),
      licenseExpression: _optionalText(draft.licenseExpression),
      retrievedAt: retrievedAt,
      contentHash: _sha256(normalizedContent),
      trustLevel: draft.trustLevel,
      createdAt: retrievedAt,
      updatedAt: retrievedAt,
    );

    return ProgrammingSourceSnapshot(
      source: source,
      chunks: _buildChunksWithSemantics(
        sourceId: sourceId,
        content: normalizedContent,
        createdAt: retrievedAt,
      ),
    );
  }

  bool _isSupportedCanonicalUri(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  SourceType _sourceTypeFor(SourceTrustLevel trustLevel) {
    switch (trustLevel) {
      case SourceTrustLevel.officialDoc:
        return SourceType.officialDoc;
      case SourceTrustLevel.sourceCode:
        return SourceType.codeFile;
      case SourceTrustLevel.userNote:
        return SourceType.userNote;
      case SourceTrustLevel.bookCourse:
      case SourceTrustLevel.article:
      case SourceTrustLevel.unknown:
        return SourceType.text;
    }
  }

  List<SourceChunk> _buildChunksWithSemantics({
    required String sourceId,
    required String content,
    required DateTime createdAt,
  }) {
    // 检测内容是否为 Markdown(含标题/代码块)
    final isMarkdown =
        content.contains(RegExp(r'^#{1,6}\s', multiLine: true)) ||
            content.contains('```');

    if (isMarkdown) {
      // 使用语义切分器按标题/代码块切分
      return _semanticChunker.chunkMarkdown(
        sourceId: sourceId,
        markdown: content,
        createdAt: createdAt,
      );
    } else {
      // 纯文本回退到固定字符切分(保持向后兼容)
      return _buildChunks(
        sourceId: sourceId,
        content: content,
        createdAt: createdAt,
      );
    }
  }

  List<SourceChunk> _buildChunks({
    required String sourceId,
    required String content,
    required DateTime createdAt,
  }) {
    final chunks = <SourceChunk>[];
    final lines = content.split('\n');
    final buffer = StringBuffer();
    var startLine = 1;
    var endLine = 1;

    void flush() {
      final chunkContent = buffer.toString().trimRight();
      if (chunkContent.isEmpty) return;
      final index = chunks.length;
      chunks.add(
        SourceChunk(
          id: '${sourceId}_chunk_$index',
          sourceId: sourceId,
          chunkIndex: index,
          content: chunkContent,
          locator: 'snapshot:L$startLine-L$endLine',
          startLine: startLine,
          endLine: endLine,
          contentHash: _sha256(chunkContent),
          createdAt: createdAt,
        ),
      );
      buffer.clear();
    }

    for (var index = 0; index < lines.length; index++) {
      final lineNumber = index + 1;
      final line = lines[index];
      if (line.length > maxChunkCharacters) {
        flush();
        for (var offset = 0;
            offset < line.length;
            offset += maxChunkCharacters) {
          final end = (offset + maxChunkCharacters).clamp(0, line.length);
          final part = line.substring(offset, end.toInt());
          final chunkIndex = chunks.length;
          chunks.add(
            SourceChunk(
              id: '${sourceId}_chunk_$chunkIndex',
              sourceId: sourceId,
              chunkIndex: chunkIndex,
              content: part,
              locator: 'snapshot:L$lineNumber-L$lineNumber',
              startLine: lineNumber,
              endLine: lineNumber,
              contentHash: _sha256(part),
              createdAt: createdAt,
            ),
          );
        }
        startLine = lineNumber + 1;
        endLine = lineNumber + 1;
        continue;
      }

      final addedLength = line.length + (buffer.isEmpty ? 0 : 1);
      if (buffer.isNotEmpty &&
          buffer.length + addedLength > maxChunkCharacters) {
        flush();
        startLine = lineNumber;
      }
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.write(line);
      endLine = lineNumber;
    }
    flush();

    return chunks;
  }

  String _normalizeContent(String content) {
    return content.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
  }

  String? _optionalText(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String _sha256(String content) {
    return sha256.convert(utf8.encode(content)).toString();
  }
}
