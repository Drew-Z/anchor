import 'dart:convert';

import '../../../data/models/source_chunk.dart';
import '../../openai_service.dart';
import '../ai_task_result.dart';

class ExtractedKnowledgePoint {
  final String title;
  final String summary;
  final List<String> tags;
  final int difficulty;
  final int interviewRelevance;
  final List<String> sourceChunkIds;

  ExtractedKnowledgePoint({
    required this.title,
    required this.summary,
    this.tags = const [],
    this.difficulty = 1,
    this.interviewRelevance = 0,
    this.sourceChunkIds = const [],
  });

  ExtractedKnowledgePoint copyWith({
    String? title,
    String? summary,
    List<String>? tags,
    int? difficulty,
    int? interviewRelevance,
    List<String>? sourceChunkIds,
  }) {
    return ExtractedKnowledgePoint(
      title: title ?? this.title,
      summary: summary ?? this.summary,
      tags: tags ?? this.tags,
      difficulty: difficulty ?? this.difficulty,
      interviewRelevance: interviewRelevance ?? this.interviewRelevance,
      sourceChunkIds: sourceChunkIds ?? this.sourceChunkIds,
    );
  }

  factory ExtractedKnowledgePoint.fromJson(Map<String, dynamic> json) {
    return ExtractedKnowledgePoint(
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)
              ?.map((tag) => tag.toString())
              .where((tag) => tag.isNotEmpty)
              .toSet()
              .toList() ??
          [],
      difficulty:
          ((json['difficulty'] as num?) ?? 1).round().clamp(1, 5).toInt(),
      interviewRelevance: ((json['interview_relevance'] as num?) ?? 0)
          .round()
          .clamp(0, 5)
          .toInt(),
      sourceChunkIds: (json['source_chunk_ids'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList() ??
          [],
    );
  }
}

class KnowledgeExtractionResult {
  final List<ExtractedKnowledgePoint> knowledgePoints;

  KnowledgeExtractionResult({required this.knowledgePoints});

  factory KnowledgeExtractionResult.fromJson(Map<String, dynamic> json) {
    final pointsJson = json['knowledge_points'] as List<dynamic>? ?? [];
    return KnowledgeExtractionResult(
      knowledgePoints: pointsJson
          .whereType<Map<String, dynamic>>()
          .map(ExtractedKnowledgePoint.fromJson)
          .where((point) =>
              point.title.trim().isNotEmpty &&
              point.summary.trim().isNotEmpty &&
              point.sourceChunkIds.isNotEmpty)
          .toList(),
    );
  }
}

class KnowledgeExtractionTask {
  static const String _systemPrompt = '''
你是一个严谨的知识库学习内容分析器。你的任务是从用户提供的来源片段中抽取可学习的知识点。

要求：
1. 只基于提供的 source chunks，不要引入外部知识。
2. 每个知识点必须包含至少一个 source_chunk_id。
3. source_chunk_ids 必须来自提供的 source chunks id，不允许编造。
4. 知识点标题要短，适合作为学习卡片标题。
5. summary 要说明这个知识点是什么，以及为什么值得学习。
6. difficulty 范围 1-5，1 最简单，5 最难。
7. interview_relevance 范围 0-5，表示它对技术面试表达的价值。
8. 输出必须是严格 JSON，不要 Markdown，不要解释。

JSON schema：
{
  "knowledge_points": [
    {
      "title": "知识点标题",
      "summary": "知识点摘要",
      "tags": ["标签1", "标签2"],
      "difficulty": 1,
      "interview_relevance": 3,
      "source_chunk_ids": ["chunk_id"]
    }
  ]
}
''';

  final OpenAIService _openai;

  KnowledgeExtractionTask(this._openai);

  Future<AiTaskResult<KnowledgeExtractionResult>> run({
    required List<SourceChunk> sourceChunks,
  }) async {
    if (sourceChunks.isEmpty) {
      return AiTaskResult.failure(
        type: AiTaskErrorType.validation,
        message: '至少需要一个来源片段才能抽取知识点',
      );
    }

    final userContent = _buildUserContent(sourceChunks);

    try {
      final response = await _openai.chatCompletion(
        systemPrompt: _systemPrompt,
        userContent: userContent,
        temperature: 0.2,
      );

      KnowledgeExtractionResult result;
      try {
        result = _parseResponse(response);
      } catch (e) {
        return AiTaskResult.failure(
          type: AiTaskErrorType.parse,
          message: e.toString(),
          rawResponse: response,
        );
      }

      result = _sanitizeResult(
        result: result,
        sourceChunks: sourceChunks,
      );

      if (result.knowledgePoints.isEmpty) {
        return AiTaskResult.failure(
          type: AiTaskErrorType.emptyResult,
          message: 'AI 未抽取出带有效来源引用的知识点',
          rawResponse: response,
        );
      }

      return AiTaskResult.success(result, rawResponse: response);
    } catch (e) {
      return AiTaskResult.failure(
        type: AiTaskErrorType.request,
        message: e.toString(),
      );
    }
  }

  KnowledgeExtractionResult _sanitizeResult({
    required KnowledgeExtractionResult result,
    required List<SourceChunk> sourceChunks,
  }) {
    final knownChunkIds = sourceChunks.map((chunk) => chunk.id).toSet();

    final points = result.knowledgePoints
        .map((point) {
          final sourceChunkIds = point.sourceChunkIds
              .where(knownChunkIds.contains)
              .toSet()
              .toList();
          return point.copyWith(sourceChunkIds: sourceChunkIds);
        })
        .where((point) =>
            point.title.trim().isNotEmpty &&
            point.summary.trim().isNotEmpty &&
            point.sourceChunkIds.isNotEmpty)
        .toList();

    return KnowledgeExtractionResult(knowledgePoints: points);
  }

  String _buildUserContent(List<SourceChunk> sourceChunks) {
    final buffer = StringBuffer();
    buffer.writeln('请从以下来源片段中抽取知识点：');
    buffer.writeln();

    for (final chunk in sourceChunks) {
      buffer.writeln('--- source_chunk ---');
      buffer.writeln('id: ${chunk.id}');
      if (chunk.locator != null && chunk.locator!.isNotEmpty) {
        buffer.writeln('locator: ${chunk.locator}');
      }
      buffer.writeln('content:');
      buffer.writeln(chunk.content);
      buffer.writeln();
    }

    return buffer.toString();
  }

  KnowledgeExtractionResult _parseResponse(String response) {
    try {
      return KnowledgeExtractionResult.fromJson(
        jsonDecode(response) as Map<String, dynamic>,
      );
    } catch (_) {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        throw FormatException('无法从 AI 响应中解析 JSON: $response');
      }
      return KnowledgeExtractionResult.fromJson(
        jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>,
      );
    }
  }
}
