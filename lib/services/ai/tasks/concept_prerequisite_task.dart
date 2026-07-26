import 'dart:convert';

import '../../../data/models/knowledge_point.dart';
import '../../../data/models/knowledge_point_prerequisite.dart';
import '../../../data/models/source_chunk.dart';
import '../../openai_service.dart';
import '../ai_task_result.dart';

class ConceptPrerequisiteResult {
  final List<KnowledgePointPrerequisiteDraft> relations;

  const ConceptPrerequisiteResult({required this.relations});

  factory ConceptPrerequisiteResult.fromJson(Map<String, dynamic> json) {
    final values = json['relations'] as List<dynamic>? ?? const [];
    return ConceptPrerequisiteResult(
      relations: values.whereType<Map<String, dynamic>>().map((value) {
        return KnowledgePointPrerequisiteDraft(
          knowledgePointId: value['knowledge_point_id']?.toString() ?? '',
          prerequisiteKnowledgePointId:
              value['prerequisite_knowledge_point_id']?.toString() ?? '',
          rationale: value['rationale']?.toString() ?? '',
          citationIds: (value['citation_ids'] as List<dynamic>?)
                  ?.map((id) => id.toString())
                  .where((id) => id.isNotEmpty)
                  .toSet()
                  .toList() ??
              const [],
        );
      }).toList(),
    );
  }
}

class ConceptPrerequisiteTask {
  static const String _systemPrompt = '''
你是一个严谨的编程概念先修关系分析器。你只能根据提供的 concept knowledge points 和它们的 source chunks 提出候选先修关系。

定义：
- prerequisite_knowledge_point_id 表示应该先学习的概念。
- knowledge_point_id 表示依赖该先修概念、应该后学习的概念。

要求：
1. 只使用输入中给出的 knowledge point id 和 source chunk id。
2. 只有来源明确支持“先理解 A 才能理解 B”、定义依赖、API 前置条件或明确顺序时才输出关系。
3. 不要仅根据标题、难度数字、常识或你自己的课程经验推断先修关系。
4. 每条关系必须包含至少一个 citation_id；引用不足时不要输出该关系。
5. 不允许自环、重复关系或双向关系。
6. rationale 简短说明来源支持的依赖理由，不要加入来源外事实。
7. 没有充分依据时返回空 relations，这是正确结果。
8. 输出严格 JSON，不要 Markdown，不要解释。

JSON schema：
{
  "relations": [
    {
      "knowledge_point_id": "后学概念 id",
      "prerequisite_knowledge_point_id": "先学概念 id",
      "rationale": "依赖理由",
      "citation_ids": ["chunk_id"]
    }
  ]
}
''';

  final OpenAIService _openai;

  ConceptPrerequisiteTask(this._openai);

  Future<AiTaskResult<ConceptPrerequisiteResult>> run({
    required List<KnowledgePoint> knowledgePoints,
    required Map<String, List<SourceChunk>> sourceChunksByKnowledgePointId,
  }) async {
    final concepts = knowledgePoints
        .where((point) => point.kind == KnowledgePointKind.concept)
        .where(
          (point) =>
              sourceChunksByKnowledgePointId[point.id]?.isNotEmpty ?? false,
        )
        .toList();
    if (concepts.length < 2) {
      return AiTaskResult.failure(
        type: AiTaskErrorType.validation,
        message: '至少需要两个有来源的通用概念才能分析先修关系',
      );
    }

    try {
      final response = await _openai.chatCompletion(
        systemPrompt: _systemPrompt,
        userContent: _buildUserContent(
          concepts,
          sourceChunksByKnowledgePointId,
        ),
        temperature: 0.1,
      );
      ConceptPrerequisiteResult result;
      try {
        result = _parseResponse(response);
      } catch (error) {
        return AiTaskResult.failure(
          type: AiTaskErrorType.parse,
          message: error.toString(),
          rawResponse: response,
        );
      }
      return AiTaskResult.success(
        _sanitize(
          result,
          concepts,
          sourceChunksByKnowledgePointId,
        ),
        rawResponse: response,
      );
    } catch (error) {
      return AiTaskResult.failure(
        type: AiTaskErrorType.request,
        message: error.toString(),
      );
    }
  }

  ConceptPrerequisiteResult _sanitize(
    ConceptPrerequisiteResult result,
    List<KnowledgePoint> concepts,
    Map<String, List<SourceChunk>> sourceChunksByKnowledgePointId,
  ) {
    final knownPointIds = concepts.map((point) => point.id).toSet();
    final chunkIdsByPointId = {
      for (final entry in sourceChunksByKnowledgePointId.entries)
        entry.key: entry.value.map((chunk) => chunk.id).toSet(),
    };
    final seen = <String>{};
    final relations = <KnowledgePointPrerequisiteDraft>[];

    for (final relation in result.relations) {
      final knowledgePointId = relation.knowledgePointId.trim();
      final prerequisiteId = relation.prerequisiteKnowledgePointId.trim();
      final rationale = relation.rationale.trim();
      final endpointChunkIds = {
        ...?chunkIdsByPointId[knowledgePointId],
        ...?chunkIdsByPointId[prerequisiteId],
      };
      final citationIds = relation.citationIds
          .where(endpointChunkIds.contains)
          .toSet()
          .toList()
        ..sort();
      final key = '$prerequisiteId->$knowledgePointId';
      final reverseKey = '$knowledgePointId->$prerequisiteId';
      if (!knownPointIds.contains(knowledgePointId) ||
          !knownPointIds.contains(prerequisiteId) ||
          knowledgePointId == prerequisiteId ||
          rationale.isEmpty ||
          citationIds.isEmpty ||
          seen.contains(key) ||
          seen.contains(reverseKey)) {
        continue;
      }
      seen.add(key);
      relations.add(
        KnowledgePointPrerequisiteDraft(
          knowledgePointId: knowledgePointId,
          prerequisiteKnowledgePointId: prerequisiteId,
          rationale: rationale,
          citationIds: citationIds,
        ),
      );
      if (relations.length == 24) break;
    }

    return ConceptPrerequisiteResult(relations: relations);
  }

  String _buildUserContent(
    List<KnowledgePoint> concepts,
    Map<String, List<SourceChunk>> sourceChunksByKnowledgePointId,
  ) {
    final buffer = StringBuffer('请分析以下编程概念之间有来源支持的先修关系：\n\n');
    for (final point in concepts) {
      buffer.writeln('--- knowledge_point ---');
      buffer.writeln('id: ${point.id}');
      buffer.writeln('title: ${point.title}');
      buffer.writeln('summary: ${point.summary}');
      buffer.writeln('difficulty: ${point.difficulty}');
      buffer.writeln('source_chunks:');
      for (final chunk
          in sourceChunksByKnowledgePointId[point.id] ?? const []) {
        buffer.writeln('  - id: ${chunk.id}');
        if (chunk.locator != null && chunk.locator!.isNotEmpty) {
          buffer.writeln('    locator: ${chunk.locator}');
        }
        buffer.writeln('    content: |');
        for (final line in chunk.content.split('\n')) {
          buffer.writeln('      $line');
        }
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  ConceptPrerequisiteResult _parseResponse(String response) {
    try {
      return ConceptPrerequisiteResult.fromJson(
        jsonDecode(response) as Map<String, dynamic>,
      );
    } catch (_) {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        throw FormatException('无法从 AI 响应中解析 JSON: $response');
      }
      return ConceptPrerequisiteResult.fromJson(
        jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>,
      );
    }
  }
}
