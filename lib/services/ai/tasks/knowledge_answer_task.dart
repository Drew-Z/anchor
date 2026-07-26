import 'dart:convert';

import '../../../data/models/grounded_claim.dart';
import '../../../data/models/grounded_learning_context.dart';
import '../../../data/models/source_chunk.dart';
import '../../openai_service.dart';
import '../ai_task_result.dart';
import '../grounded_claim_gate.dart';

class KnowledgeAnswerResult {
  final String answer;
  final List<String> keyPoints;
  final List<String> followUpQuestions;
  final List<String> sourceGaps;
  final List<String> citationIds;
  final List<GroundedClaim> claims;
  final List<GroundedClaim> uncoveredClaims;
  final GroundingDisposition groundingDisposition;

  const KnowledgeAnswerResult({
    required this.answer,
    this.keyPoints = const [],
    this.followUpQuestions = const [],
    this.sourceGaps = const [],
    this.citationIds = const [],
    this.claims = const [],
    this.uncoveredClaims = const [],
    this.groundingDisposition = GroundingDisposition.legacy,
  });

  KnowledgeAnswerResult copyWith({
    String? answer,
    List<String>? keyPoints,
    List<String>? followUpQuestions,
    List<String>? sourceGaps,
    List<String>? citationIds,
    List<GroundedClaim>? claims,
    List<GroundedClaim>? uncoveredClaims,
    GroundingDisposition? groundingDisposition,
  }) {
    return KnowledgeAnswerResult(
      answer: answer ?? this.answer,
      keyPoints: keyPoints ?? this.keyPoints,
      followUpQuestions: followUpQuestions ?? this.followUpQuestions,
      sourceGaps: sourceGaps ?? this.sourceGaps,
      citationIds: citationIds ?? this.citationIds,
      claims: claims ?? this.claims,
      uncoveredClaims: uncoveredClaims ?? this.uncoveredClaims,
      groundingDisposition: groundingDisposition ?? this.groundingDisposition,
    );
  }

  factory KnowledgeAnswerResult.fromJson(Map<String, dynamic> json) {
    return KnowledgeAnswerResult(
      answer: json['answer'] as String? ?? '',
      keyPoints: _stringList(json['key_points']),
      followUpQuestions: _stringList(json['follow_up_questions']),
      sourceGaps: _stringList(json['source_gaps']),
      citationIds: _stringList(json['citation_ids']),
      claims: decodeGroundedClaims(json['claims']),
    );
  }

  static List<String> _stringList(dynamic value) {
    return (value as List<dynamic>?)
            ?.map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList() ??
        [];
  }
}

class KnowledgeAnswerTask {
  static const String _systemPrompt = '''
你是一个严谨的知识库学习助手。你的任务是只基于用户提供的 source chunks 回答问题。

要求：
1. 只能使用提供的 source chunks，不要引入外部事实。
2. 如果来源片段不足以回答，要明确写入 source_gaps，不要编造。
3. answer 用简洁中文回答，适合学习复盘和面试表达。
4. key_points 提炼 2-5 个要点。
5. follow_up_questions 给 1-3 个适合继续学习或面试追问的问题。
6. citation_ids 必须列出支撑回答的 source_chunk id。
7. citation_ids 必须来自提供的 source chunks id，不允许编造。
8. 如果没有任何可引用依据支撑 answer，应返回空 answer，并在 source_gaps 说明缺口。
9. claims 必须拆分 answer 和 key_points 中的每个可核验事实；section 只能是 answer 或 key_point。
10. 每个 claim 必须提供 evidence，citation_id 来自 source chunks，quote 是该 chunk 中可逐字找到的短摘录。
11. 顶层 citation_ids 仅作兼容输出，系统会按 claims 中通过校验的 evidence 重新计算。
12. 输出严格 JSON，不要 Markdown，不要解释。

JSON schema：
{
  "answer": "回答",
  "key_points": ["要点"],
  "follow_up_questions": ["追问"],
  "source_gaps": ["来源缺口"],
  "citation_ids": ["chunk_id"],
  "claims": [
    {
      "section": "answer",
      "text": "一个独立、可核验的事实主张",
      "evidence": [
        {"citation_id": "chunk_id", "quote": "来源中的逐字短摘录"}
      ]
    }
  ]
}
''';

  final OpenAIService _openai;

  KnowledgeAnswerTask(this._openai);

  Future<AiTaskResult<KnowledgeAnswerResult>> run({
    required String question,
    required List<SourceChunk> sourceChunks,
    GroundedLearningContext? groundedContext,
  }) async {
    final trimmedQuestion = question.trim();
    if (trimmedQuestion.isEmpty) {
      return AiTaskResult.failure(
        type: AiTaskErrorType.validation,
        message: '问题不能为空',
      );
    }
    final contextChunks = groundedContext?.chunks ?? sourceChunks;
    if (contextChunks.isEmpty ||
        (groundedContext != null &&
            !groundedContext.isExecutableFor(
              GroundedLearningSurface.knowledgeAnswer,
            ))) {
      return AiTaskResult.failure(
        type: AiTaskErrorType.validation,
        message: '至少需要一个来源片段才能回答知识库问题',
      );
    }

    try {
      final response = await _openai.chatCompletion(
        systemPrompt: _systemPrompt,
        userContent: _buildUserContent(
          question: trimmedQuestion,
          sourceChunks: contextChunks,
        ),
        temperature: 0.2,
      );

      KnowledgeAnswerResult result;
      try {
        result = _parseResponse(response);
      } catch (e) {
        return AiTaskResult.failure(
          type: AiTaskErrorType.parse,
          message: e.toString(),
          rawResponse: response,
        );
      }

      result = _applyGroundingGate(
        result: result,
        sourceChunks: contextChunks,
        groundedContext: groundedContext,
      );

      final hasAnswer = result.answer.trim().isNotEmpty;
      final hasSourceGaps = result.sourceGaps.isNotEmpty;
      if (hasAnswer &&
          (result.citationIds.isEmpty ||
              result.groundingDisposition == GroundingDisposition.refused)) {
        return AiTaskResult.failure(
          type: AiTaskErrorType.emptyResult,
          message: '知识库回答未通过主张级引用门禁',
          rawResponse: response,
        );
      }
      if (!hasAnswer && !hasSourceGaps) {
        return AiTaskResult.failure(
          type: AiTaskErrorType.emptyResult,
          message: 'AI 未返回回答，也没有说明来源缺口',
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

  KnowledgeAnswerResult _applyGroundingGate({
    required KnowledgeAnswerResult result,
    required List<SourceChunk> sourceChunks,
    GroundedLearningContext? groundedContext,
  }) {
    final audit = groundedContext == null
        ? const GroundedClaimGate().evaluate(
            claims: result.claims,
            sourceChunks: sourceChunks,
          )
        : const GroundedClaimGate().evaluateContext(
            claims: result.claims,
            context: groundedContext,
          );
    final answerClaims = audit.claimsForSection('answer');
    final keyPointClaims = audit.claimsForSection('key_point');
    final hasUnresolvedGap =
        result.sourceGaps.isNotEmpty || audit.uncoveredClaims.isNotEmpty;
    final disposition = answerClaims.isEmpty
        ? GroundingDisposition.refused
        : hasUnresolvedGap
            ? GroundingDisposition.partial
            : GroundingDisposition.grounded;
    final sourceGaps = <String>{...result.sourceGaps};
    if (audit.uncoveredClaims.isNotEmpty) {
      sourceGaps.add('部分主张缺少可核验的来源摘录');
    }
    if (answerClaims.isEmpty) {
      sourceGaps.add('现有来源不足以形成可核验回答');
    }
    return result.copyWith(
      answer: answerClaims.map((claim) => claim.text).join('\n'),
      keyPoints: keyPointClaims.map((claim) => claim.text).toList(),
      sourceGaps: sourceGaps.toList(),
      citationIds: audit.citationIds,
      claims: audit.groundedClaims,
      uncoveredClaims: audit.uncoveredClaims,
      groundingDisposition: disposition,
    );
  }

  String _buildUserContent({
    required String question,
    required List<SourceChunk> sourceChunks,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('--- question ---');
    buffer.writeln(question);
    buffer.writeln();
    buffer.writeln('--- source_chunks ---');
    for (final chunk in sourceChunks) {
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

  KnowledgeAnswerResult _parseResponse(String response) {
    try {
      return KnowledgeAnswerResult.fromJson(
        jsonDecode(response) as Map<String, dynamic>,
      );
    } catch (_) {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        throw FormatException('无法从 AI 响应中解析 JSON: $response');
      }
      return KnowledgeAnswerResult.fromJson(
        jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>,
      );
    }
  }
}
