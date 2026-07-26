import 'dart:convert';

import '../../../data/models/knowledge_point.dart';
import '../../../data/models/grounded_learning_context.dart';
import '../../../data/models/source_chunk.dart';
import '../../openai_service.dart';
import '../ai_task_result.dart';

class TutorExplanationResult {
  final String definitionAndIntuition;
  final String mechanism;
  final String codeOrDocExample;
  final String boundaries;
  final List<String> misconceptions;
  final String interviewExpression;
  final String openingQuestion;
  final List<String> citationIds;
  final List<String> unsupportedLayers;
  final bool evidenceSufficient;

  const TutorExplanationResult({
    required this.definitionAndIntuition,
    required this.mechanism,
    required this.codeOrDocExample,
    required this.boundaries,
    this.misconceptions = const [],
    this.interviewExpression = '',
    this.openingQuestion = '',
    this.citationIds = const [],
    this.unsupportedLayers = const [],
    this.evidenceSufficient = true,
  });

  TutorExplanationResult copyWith({
    List<String>? citationIds,
    String? openingQuestion,
  }) {
    return TutorExplanationResult(
      definitionAndIntuition: definitionAndIntuition,
      mechanism: mechanism,
      codeOrDocExample: codeOrDocExample,
      boundaries: boundaries,
      misconceptions: misconceptions,
      interviewExpression: interviewExpression,
      openingQuestion: openingQuestion ?? this.openingQuestion,
      citationIds: citationIds ?? this.citationIds,
      unsupportedLayers: unsupportedLayers,
      evidenceSufficient: evidenceSufficient,
    );
  }

  factory TutorExplanationResult.fromJson(Map<String, dynamic> json) {
    return TutorExplanationResult(
      definitionAndIntuition: json['definition_and_intuition'] as String? ?? '',
      mechanism: json['mechanism'] as String? ?? '',
      codeOrDocExample: json['code_or_doc_example'] as String? ?? '',
      boundaries: json['boundaries'] as String? ?? '',
      misconceptions: (json['misconceptions'] as List<dynamic>?)
              ?.map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toSet()
              .toList() ??
          [],
      interviewExpression: json['interview_expression'] as String? ?? '',
      openingQuestion: json['opening_question'] as String? ?? '',
      citationIds: (json['citation_ids'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList() ??
          [],
      unsupportedLayers: (json['unsupported_layers'] as List<dynamic>?)
              ?.map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toSet()
              .toList() ??
          [],
      evidenceSufficient: json['evidence_sufficient'] as bool? ?? true,
    );
  }
}

class TutorExplanationTask {
  static const String _systemPrompt = '''
你是一个严谨的编程学习导师。你只能根据当前知识点、已确认的先修知识点和提供的 source chunks 讲解。

要求：
1. 不得引入 source chunks 之外的事实。无法支撑的层次写“来源不足”，并把层次名加入 unsupported_layers。
2. definition_and_intuition：先给正式定义，再给不引入新事实的直觉解释。
3. mechanism：解释工作机制、关键步骤和因果关系。
4. code_or_doc_example：只使用来源中真实存在的代码或文档例子；没有例子时写“来源不足”。
5. boundaries：说明适用边界、前提和来源明确支持的限制。
6. misconceptions：列出常见误区，并用来源支持的正确说法纠正。
7. interview_expression：给出不超出来源的面试表达结构。
8. opening_question：只提出一个问题，不给答案；问题必须能由现有来源回答，并优先检查核心机制或未掌握先修项。
9. citation_ids 只能使用提供的 source_chunk id，不得编造。
10. 如果核心定义、机制或首问缺少足够证据，evidence_sufficient=false，opening_question 置空，不继续扩展事实。
11. 输出严格 JSON，不要 Markdown，不要解释。

JSON schema：
{
  "definition_and_intuition": "定义与直觉",
  "mechanism": "工作机制",
  "code_or_doc_example": "代码或文档例子",
  "boundaries": "边界与前提",
  "misconceptions": ["误区与纠正"],
  "interview_expression": "面试表达",
  "opening_question": "唯一的首问",
  "citation_ids": ["chunk_id"],
  "unsupported_layers": ["层次名"],
  "evidence_sufficient": true
}
''';

  final OpenAIService _openai;

  TutorExplanationTask(this._openai);

  Future<AiTaskResult<TutorExplanationResult>> run({
    required KnowledgePoint knowledgePoint,
    required List<SourceChunk> sourceChunks,
    List<KnowledgePoint> prerequisiteKnowledgePoints = const [],
    Map<String, List<SourceChunk>> prerequisiteChunksByKnowledgePointId =
        const {},
    GroundedLearningContext? groundedContext,
  }) async {
    final allowedChunkIds = groundedContext?.chunkIdSet;
    final currentChunks = allowedChunkIds == null
        ? sourceChunks
        : sourceChunks
            .where((chunk) => allowedChunkIds.contains(chunk.id))
            .toList(growable: false);
    if (currentChunks.isEmpty ||
        (groundedContext != null &&
            !groundedContext.isExecutableFor(GroundedLearningSurface.tutor))) {
      return AiTaskResult.failure(
        type: AiTaskErrorType.validation,
        message: '至少需要一个当前知识点来源片段才能进行导师讲解',
      );
    }

    final allowedPrerequisiteIds =
        prerequisiteKnowledgePoints.map((point) => point.id).toSet();
    final sanitizedPrerequisiteChunks = <String, List<SourceChunk>>{
      for (final entry in prerequisiteChunksByKnowledgePointId.entries)
        if (allowedPrerequisiteIds.contains(entry.key))
          entry.key: allowedChunkIds == null
              ? entry.value
              : entry.value
                  .where((chunk) => allowedChunkIds.contains(chunk.id))
                  .toList(growable: false),
    };

    try {
      final response = await _openai.chatCompletion(
        systemPrompt: _systemPrompt,
        userContent: _buildUserContent(
          knowledgePoint: knowledgePoint,
          sourceChunks: currentChunks,
          prerequisiteKnowledgePoints: prerequisiteKnowledgePoints,
          prerequisiteChunksByKnowledgePointId: sanitizedPrerequisiteChunks,
        ),
        temperature: 0.1,
      );

      TutorExplanationResult result;
      try {
        result = _parseResponse(response);
      } catch (e) {
        return AiTaskResult.failure(
          type: AiTaskErrorType.parse,
          message: e.toString(),
          rawResponse: response,
        );
      }

      final knownChunkIds = <String>{
        ...currentChunks.map((chunk) => chunk.id),
        ...sanitizedPrerequisiteChunks.values
            .expand((chunks) => chunks)
            .map((chunk) => chunk.id),
      };
      result = result.copyWith(
        citationIds:
            result.citationIds.where(knownChunkIds.contains).toSet().toList(),
        openingQuestion:
            result.evidenceSufficient ? result.openingQuestion.trim() : '',
      );

      if (!result.evidenceSufficient) {
        return AiTaskResult.success(result, rawResponse: response);
      }
      if (result.definitionAndIntuition.trim().isEmpty ||
          result.mechanism.trim().isEmpty ||
          result.openingQuestion.isEmpty ||
          result.citationIds.isEmpty) {
        return AiTaskResult.failure(
          type: AiTaskErrorType.emptyResult,
          message: 'AI 未返回带有效引用的分层讲解和唯一首问',
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

  String _buildUserContent({
    required KnowledgePoint knowledgePoint,
    required List<SourceChunk> sourceChunks,
    required List<KnowledgePoint> prerequisiteKnowledgePoints,
    required Map<String, List<SourceChunk>>
        prerequisiteChunksByKnowledgePointId,
  }) {
    final buffer = StringBuffer();
    _writeKnowledgePoint(
      buffer,
      label: 'current_knowledge_point',
      point: knowledgePoint,
      chunks: sourceChunks,
    );

    buffer.writeln('--- confirmed_prerequisites ---');
    if (prerequisiteKnowledgePoints.isEmpty) {
      buffer.writeln('none');
    } else {
      for (final point in prerequisiteKnowledgePoints) {
        _writeKnowledgePoint(
          buffer,
          label: 'prerequisite',
          point: point,
          chunks: prerequisiteChunksByKnowledgePointId[point.id] ?? const [],
        );
      }
    }
    return buffer.toString();
  }

  void _writeKnowledgePoint(
    StringBuffer buffer, {
    required String label,
    required KnowledgePoint point,
    required List<SourceChunk> chunks,
  }) {
    buffer.writeln('--- $label ---');
    buffer.writeln('id: ${point.id}');
    buffer.writeln('title: ${point.title}');
    buffer.writeln('kind: ${point.kind.value}');
    buffer.writeln('summary: ${point.summary}');
    buffer.writeln('source_chunks:');
    for (final chunk in chunks) {
      buffer.writeln('- id: ${chunk.id}');
      if (chunk.locator != null && chunk.locator!.isNotEmpty) {
        buffer.writeln('  locator: ${chunk.locator}');
      }
      buffer.writeln('  content: |');
      for (final line in chunk.content.split('\n')) {
        buffer.writeln('    $line');
      }
    }
    buffer.writeln();
  }

  TutorExplanationResult _parseResponse(String response) {
    try {
      return TutorExplanationResult.fromJson(
        jsonDecode(response) as Map<String, dynamic>,
      );
    } catch (_) {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        throw FormatException('无法从 AI 响应中解析 JSON: $response');
      }
      return TutorExplanationResult.fromJson(
        jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>,
      );
    }
  }
}
