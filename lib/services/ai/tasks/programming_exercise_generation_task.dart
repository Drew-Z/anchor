import 'dart:convert';

import '../../../data/models/knowledge_point.dart';
import '../../../data/models/programming_exercise.dart';
import '../../../data/models/question.dart';
import '../../../data/models/source_chunk.dart';
import '../../openai_service.dart';
import '../ai_task_result.dart';

class ProgrammingExerciseDraft {
  final ProgrammingExerciseKind kind;
  final String prompt;
  final String referenceAnswer;
  final String conceptAccuracyCriterion;
  final String reasoningProcessCriterion;
  final String evidenceUseCriterion;
  final String clarityCriterion;
  final List<String> citationIds;

  const ProgrammingExerciseDraft({
    required this.kind,
    required this.prompt,
    required this.referenceAnswer,
    required this.conceptAccuracyCriterion,
    required this.reasoningProcessCriterion,
    required this.evidenceUseCriterion,
    required this.clarityCriterion,
    required this.citationIds,
  });

  ProgrammingExerciseDraft copyWith({List<String>? citationIds}) {
    return ProgrammingExerciseDraft(
      kind: kind,
      prompt: prompt,
      referenceAnswer: referenceAnswer,
      conceptAccuracyCriterion: conceptAccuracyCriterion,
      reasoningProcessCriterion: reasoningProcessCriterion,
      evidenceUseCriterion: evidenceUseCriterion,
      clarityCriterion: clarityCriterion,
      citationIds: citationIds ?? this.citationIds,
    );
  }

  ProgrammingExercise toExercise({
    required String id,
    required String knowledgePointId,
    required DateTime createdAt,
    bool isRetest = false,
    String? parentAttemptId,
  }) {
    return ProgrammingExercise(
      id: id,
      knowledgePointId: knowledgePointId,
      kind: kind,
      prompt: prompt,
      referenceAnswer: referenceAnswer,
      conceptAccuracyCriterion: conceptAccuracyCriterion,
      reasoningProcessCriterion: reasoningProcessCriterion,
      evidenceUseCriterion: evidenceUseCriterion,
      clarityCriterion: clarityCriterion,
      sourceStatus: SourceStatus.pending,
      citationIds: citationIds,
      isRetest: isRetest,
      parentAttemptId: parentAttemptId,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  factory ProgrammingExerciseDraft.fromJson(Map<String, dynamic> json) {
    return ProgrammingExerciseDraft(
      kind: ProgrammingExerciseKind.fromString(json['kind'] as String? ?? ''),
      prompt: json['prompt'] as String? ?? '',
      referenceAnswer: json['reference_answer'] as String? ?? '',
      conceptAccuracyCriterion:
          json['concept_accuracy_criterion'] as String? ?? '',
      reasoningProcessCriterion:
          json['reasoning_process_criterion'] as String? ?? '',
      evidenceUseCriterion: json['evidence_use_criterion'] as String? ?? '',
      clarityCriterion: json['clarity_criterion'] as String? ?? '',
      citationIds: (json['citation_ids'] as List<dynamic>? ?? const [])
          .map((id) => id.toString())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(),
    );
  }

  bool get isComplete =>
      prompt.trim().isNotEmpty &&
      referenceAnswer.trim().isNotEmpty &&
      conceptAccuracyCriterion.trim().isNotEmpty &&
      reasoningProcessCriterion.trim().isNotEmpty &&
      evidenceUseCriterion.trim().isNotEmpty &&
      clarityCriterion.trim().isNotEmpty &&
      citationIds.isNotEmpty;
}

class ProgrammingExerciseGenerationTask {
  static const String _systemPrompt = '''
你是一个证据约束的编程练习设计器。你只能根据当前知识点和提供的 source chunks 出题。

要求：
1. 最多生成四道练习，每种类型最多一道：explanation、code_reading、boundary_judgment、implementation。
2. 练习必须能够仅凭提供的来源完成，不得引入来源之外的 API、行为或最佳实践。
3. reference_answer 是核验练习时使用的参考关键点，不得把来源未支持的内容当作标准答案。
4. 每道题都要给出四个独立评价标准：概念准确、推理过程、代码或文档依据、表达清晰。
5. citation_ids 只能使用提供的 source_chunk id，并且必须直接支撑题干与参考答案。
6. 来源不足以生成某类练习时跳过该类型，不要猜测补全。
7. 输出严格 JSON，不要 Markdown，不要解释。

JSON schema：
{
  "exercises": [
    {
      "kind": "explanation",
      "prompt": "题目",
      "reference_answer": "来源支持的参考关键点",
      "concept_accuracy_criterion": "概念准确标准",
      "reasoning_process_criterion": "推理过程标准",
      "evidence_use_criterion": "代码或文档依据标准",
      "clarity_criterion": "表达清晰标准",
      "citation_ids": ["chunk_id"]
    }
  ]
}
''';

  final OpenAIService _openai;

  ProgrammingExerciseGenerationTask(this._openai);

  Future<AiTaskResult<List<ProgrammingExerciseDraft>>> run({
    required KnowledgePoint knowledgePoint,
    required List<SourceChunk> sourceChunks,
  }) async {
    if (sourceChunks.isEmpty) {
      return AiTaskResult.failure(
        type: AiTaskErrorType.validation,
        message: '至少需要一个来源片段才能生成编程练习',
      );
    }

    final knownChunkIds = sourceChunks.map((chunk) => chunk.id).toSet();
    try {
      final response = await _openai.chatCompletion(
        systemPrompt: _systemPrompt,
        userContent: _buildUserContent(knowledgePoint, sourceChunks),
        temperature: 0.1,
      );

      List<ProgrammingExerciseDraft> parsed;
      try {
        parsed = _parseResponse(response);
      } catch (e) {
        return AiTaskResult.failure(
          type: AiTaskErrorType.parse,
          message: e.toString(),
          rawResponse: response,
        );
      }

      final byKind = <ProgrammingExerciseKind, ProgrammingExerciseDraft>{};
      for (final draft in parsed) {
        final sanitized = draft.copyWith(
          citationIds: draft.citationIds.where(knownChunkIds.contains).toList(),
        );
        if (!sanitized.isComplete || byKind.containsKey(sanitized.kind)) {
          continue;
        }
        byKind[sanitized.kind] = sanitized;
      }
      final exercises = ProgrammingExerciseKind.values
          .map((kind) => byKind[kind])
          .whereType<ProgrammingExerciseDraft>()
          .take(4)
          .toList();
      if (exercises.isEmpty) {
        return AiTaskResult.failure(
          type: AiTaskErrorType.emptyResult,
          message: 'AI 未返回可由现有来源支撑的完整编程练习',
          rawResponse: response,
        );
      }
      return AiTaskResult.success(exercises, rawResponse: response);
    } catch (e) {
      return AiTaskResult.failure(
        type: AiTaskErrorType.request,
        message: e.toString(),
      );
    }
  }

  String _buildUserContent(
    KnowledgePoint knowledgePoint,
    List<SourceChunk> sourceChunks,
  ) {
    final buffer = StringBuffer()
      ..writeln('--- current_knowledge_point ---')
      ..writeln('id: ${knowledgePoint.id}')
      ..writeln('title: ${knowledgePoint.title}')
      ..writeln('kind: ${knowledgePoint.kind.value}')
      ..writeln('summary: ${knowledgePoint.summary}')
      ..writeln('source_chunks:');
    for (final chunk in sourceChunks) {
      buffer.writeln('- id: ${chunk.id}');
      if (chunk.locator != null && chunk.locator!.isNotEmpty) {
        buffer.writeln('  locator: ${chunk.locator}');
      }
      buffer.writeln('  content: |');
      for (final line in chunk.content.split('\n')) {
        buffer.writeln('    $line');
      }
    }
    return buffer.toString();
  }

  List<ProgrammingExerciseDraft> _parseResponse(String response) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response) as Map<String, dynamic>;
    } catch (_) {
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (match == null) {
        throw FormatException('无法从 AI 响应中解析练习 JSON: $response');
      }
      json = jsonDecode(match.group(0)!) as Map<String, dynamic>;
    }
    final items = json['exercises'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map>()
        .map((item) => ProgrammingExerciseDraft.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }
}
