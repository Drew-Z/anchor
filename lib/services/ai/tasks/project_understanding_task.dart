import 'dart:convert';

import '../../../data/models/knowledge_point.dart';
import '../../../data/models/source_chunk.dart';
import '../../openai_service.dart';
import '../ai_task_result.dart';

class ProjectUnderstandingUnit {
  final KnowledgePointKind kind;
  final String title;
  final String summary;
  final List<String> tags;
  final int difficulty;
  final int interviewRelevance;
  final List<String> sourceChunkIds;

  const ProjectUnderstandingUnit({
    required this.kind,
    required this.title,
    required this.summary,
    this.tags = const [],
    this.difficulty = 1,
    this.interviewRelevance = 0,
    this.sourceChunkIds = const [],
  });

  ProjectUnderstandingUnit copyWith({
    KnowledgePointKind? kind,
    String? title,
    String? summary,
    List<String>? tags,
    int? difficulty,
    int? interviewRelevance,
    List<String>? sourceChunkIds,
  }) {
    return ProjectUnderstandingUnit(
      kind: kind ?? this.kind,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      tags: tags ?? this.tags,
      difficulty: difficulty ?? this.difficulty,
      interviewRelevance: interviewRelevance ?? this.interviewRelevance,
      sourceChunkIds: sourceChunkIds ?? this.sourceChunkIds,
    );
  }

  factory ProjectUnderstandingUnit.fromJson(Map<String, dynamic> json) {
    return ProjectUnderstandingUnit(
      kind: KnowledgePointKind.fromString(json['kind'] as String?),
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)
              ?.map((tag) => tag.toString().trim())
              .where((tag) => tag.isNotEmpty)
              .toSet()
              .toList() ??
          const [],
      difficulty:
          ((json['difficulty'] as num?) ?? 1).round().clamp(1, 5).toInt(),
      interviewRelevance: ((json['interview_relevance'] as num?) ?? 0)
          .round()
          .clamp(0, 5)
          .toInt(),
      sourceChunkIds: (json['source_chunk_ids'] as List<dynamic>?)
              ?.map((id) => id.toString().trim())
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList() ??
          const [],
    );
  }
}

class ProjectUnderstandingResult {
  final List<ProjectUnderstandingUnit> units;

  const ProjectUnderstandingResult({required this.units});

  factory ProjectUnderstandingResult.fromJson(Map<String, dynamic> json) {
    final units = json['units'] as List<dynamic>? ?? const [];
    return ProjectUnderstandingResult(
      units: units
          .whereType<Map<String, dynamic>>()
          .map(ProjectUnderstandingUnit.fromJson)
          .where((unit) => unit.kind.isProjectUnderstanding)
          .toList(),
    );
  }
}

class ProjectUnderstandingTask {
  static const String _systemPrompt = '''
你是一个严谨的项目源码理解分析器。你的任务是把用户提供的项目 source chunks 转成适合技术面试学习的项目理解单元。

要求：
1. 只基于提供的 source chunks，不要使用外部知识或猜测未展示的实现。
2. kind 只能是 architecture、data_flow、implementation、boundary、trade_off。
3. 优先覆盖架构、数据流和关键实现；只有源码明确支持时才输出边界或取舍。
4. 每个单元必须包含至少一个 source_chunk_id，并且只能引用提供的 chunk id。
5. summary 必须说明源码实际做了什么、组件如何协作，以及这点为什么值得在面试中讲。
6. 不要把常见最佳实践、框架惯例或推测写成该项目已经实现的事实。
7. 同一个事实不要换标题重复输出，最多输出 12 个单元。
8. difficulty 范围 1-5；interview_relevance 范围 0-5。
9. 输出严格 JSON，不要 Markdown，不要额外解释。

JSON schema：
{
  "units": [
    {
      "kind": "architecture",
      "title": "短标题",
      "summary": "由源码直接支撑的项目理解",
      "tags": ["Flutter", "数据流"],
      "difficulty": 3,
      "interview_relevance": 5,
      "source_chunk_ids": ["chunk_id"]
    }
  ]
}
''';

  final OpenAIService _openai;

  ProjectUnderstandingTask(this._openai);

  Future<AiTaskResult<ProjectUnderstandingResult>> run({
    required List<SourceChunk> sourceChunks,
  }) async {
    if (sourceChunks.isEmpty) {
      return AiTaskResult.failure(
        type: AiTaskErrorType.validation,
        message: '至少需要一个源码片段才能生成项目理解',
      );
    }

    try {
      final response = await _openai.chatCompletion(
        systemPrompt: _systemPrompt,
        userContent: _buildUserContent(sourceChunks),
        temperature: 0.1,
      );
      late final ProjectUnderstandingResult parsed;
      try {
        parsed = _parseResponse(response);
      } catch (error) {
        return AiTaskResult.failure(
          type: AiTaskErrorType.parse,
          message: error.toString(),
          rawResponse: response,
        );
      }

      final result = _sanitizeResult(parsed, sourceChunks);
      if (result.units.isEmpty) {
        return AiTaskResult.failure(
          type: AiTaskErrorType.emptyResult,
          message: 'AI 未生成带有效源码引用的项目理解单元',
          rawResponse: response,
        );
      }
      return AiTaskResult.success(result, rawResponse: response);
    } catch (error) {
      return AiTaskResult.failure(
        type: AiTaskErrorType.request,
        message: error.toString(),
      );
    }
  }

  ProjectUnderstandingResult _sanitizeResult(
    ProjectUnderstandingResult result,
    List<SourceChunk> sourceChunks,
  ) {
    final knownChunkIds = sourceChunks.map((chunk) => chunk.id).toSet();
    final seenUnits = <String>{};
    final units = <ProjectUnderstandingUnit>[];

    for (final unit in result.units) {
      final title = unit.title.trim();
      final summary = unit.summary.trim();
      final sourceChunkIds =
          unit.sourceChunkIds.where(knownChunkIds.contains).toSet().toList();
      final identity = '${unit.kind.value}:${title.toLowerCase()}';
      if (title.isEmpty ||
          summary.isEmpty ||
          sourceChunkIds.isEmpty ||
          !seenUnits.add(identity)) {
        continue;
      }
      units.add(
        unit.copyWith(
          title: title,
          summary: summary,
          sourceChunkIds: sourceChunkIds,
        ),
      );
      if (units.length == 12) break;
    }
    return ProjectUnderstandingResult(units: units);
  }

  String _buildUserContent(List<SourceChunk> sourceChunks) {
    final buffer = StringBuffer('请分析以下项目源码片段：\n\n');
    for (final chunk in sourceChunks) {
      buffer.writeln('--- source_chunk ---');
      buffer.writeln('id: ${chunk.id}');
      if (chunk.relativePath != null && chunk.relativePath!.isNotEmpty) {
        buffer.writeln('relative_path: ${chunk.relativePath}');
      }
      if (chunk.locator != null && chunk.locator!.isNotEmpty) {
        buffer.writeln('locator: ${chunk.locator}');
      }
      buffer.writeln('content:');
      buffer.writeln(chunk.content);
      buffer.writeln();
    }
    return buffer.toString();
  }

  ProjectUnderstandingResult _parseResponse(String response) {
    try {
      return ProjectUnderstandingResult.fromJson(
        jsonDecode(response) as Map<String, dynamic>,
      );
    } catch (_) {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        throw FormatException('无法从 AI 响应中解析 JSON: $response');
      }
      return ProjectUnderstandingResult.fromJson(
        jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>,
      );
    }
  }
}
