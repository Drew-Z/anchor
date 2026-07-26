import 'dart:convert';

import '../../../data/models/grounded_claim.dart';
import '../../../data/models/grounded_learning_context.dart';
import '../../../data/models/knowledge_point.dart';
import '../../../data/models/source_chunk.dart';
import '../../../data/models/tutor_turn.dart';
import '../../openai_service.dart';
import '../ai_task_result.dart';
import '../grounded_claim_gate.dart';

class TutorSocraticResult {
  final String feedback;
  final String referenceAnswer;
  final String misconception;
  final String nextQuestion;
  final List<String> citationIds;
  final bool evidenceSufficient;
  final int accuracyScore;
  final List<GroundedClaim> claims;
  final List<GroundedClaim> uncoveredClaims;
  final GroundingDisposition groundingDisposition;

  const TutorSocraticResult({
    required this.feedback,
    this.referenceAnswer = '',
    this.misconception = '',
    this.nextQuestion = '',
    this.citationIds = const [],
    this.evidenceSufficient = true,
    this.accuracyScore = 0,
    this.claims = const [],
    this.uncoveredClaims = const [],
    this.groundingDisposition = GroundingDisposition.legacy,
  });

  TutorSocraticResult copyWith({
    String? feedback,
    String? referenceAnswer,
    String? misconception,
    String? nextQuestion,
    List<String>? citationIds,
    bool? evidenceSufficient,
    int? accuracyScore,
    List<GroundedClaim>? claims,
    List<GroundedClaim>? uncoveredClaims,
    GroundingDisposition? groundingDisposition,
  }) {
    return TutorSocraticResult(
      feedback: feedback ?? this.feedback,
      referenceAnswer: referenceAnswer ?? this.referenceAnswer,
      misconception: misconception ?? this.misconception,
      nextQuestion: nextQuestion ?? this.nextQuestion,
      citationIds: citationIds ?? this.citationIds,
      evidenceSufficient: evidenceSufficient ?? this.evidenceSufficient,
      accuracyScore: accuracyScore ?? this.accuracyScore,
      claims: claims ?? this.claims,
      uncoveredClaims: uncoveredClaims ?? this.uncoveredClaims,
      groundingDisposition: groundingDisposition ?? this.groundingDisposition,
    );
  }

  factory TutorSocraticResult.fromJson(Map<String, dynamic> json) {
    return TutorSocraticResult(
      feedback: json['feedback'] as String? ?? '',
      referenceAnswer: json['reference_answer'] as String? ?? '',
      misconception: json['misconception'] as String? ?? '',
      nextQuestion: json['next_question'] as String? ?? '',
      citationIds: (json['citation_ids'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList() ??
          [],
      evidenceSufficient: json['evidence_sufficient'] as bool? ?? true,
      accuracyScore: ((json['accuracy_score'] as num?) ?? 0).round(),
      claims: decodeGroundedClaims(json['claims']),
    );
  }
}

class TutorSocraticTask {
  static const String _systemPrompt = '''
你是一个证据约束的苏格拉底编程导师。每轮只处理一个问题和一个用户回答。

要求：
1. 只允许使用当前知识点、已确认先修知识点、已有导师轮次和提供的 source chunks。
2. 先判断用户回答覆盖了什么、缺了什么，再给简洁反馈；不要一次讲完所有内容。
3. misconception 只记录用户答案中可观察到的具体误区；没有则返回空字符串。
4. reference_answer 只能由来源支持，用于说明本轮应包含的关键点。
5. next_question 必须恰好是一个问题，只能追问当前知识点、未掌握先修项或本轮答案缺口。
6. citation_ids 只能使用提供的 source_chunk id，且必须支撑 feedback 和 reference_answer。
7. accuracy_score 为 0-100，只评价本轮回答对来源中关键点的覆盖和准确度。
8. 如果来源不足以评价回答或生成下一问，evidence_sufficient=false，明确说明“来源不足”，next_question 置空，不扩展事实。
9. claims 必须逐项覆盖 feedback、reference_answer 和非空 misconception；section 分别使用 feedback、reference_answer、misconception。
10. 每个 claim 的 evidence 必须给出合法 citation_id 和该 chunk 中可逐字找到的 quote。
11. 顶层 citation_ids 仅作兼容输出，系统会按通过 quote 校验的 claims 重算。
12. 输出严格 JSON，不要 Markdown，不要解释。

JSON schema：
{
  "feedback": "针对本轮回答的反馈",
  "reference_answer": "来源支持的关键答案",
  "misconception": "具体误区或空字符串",
  "next_question": "唯一的下一问或空字符串",
  "citation_ids": ["chunk_id"],
  "evidence_sufficient": true,
  "accuracy_score": 0,
  "claims": [
    {
      "section": "feedback",
      "text": "一个独立反馈主张",
      "evidence": [
        {"citation_id": "chunk_id", "quote": "来源中的逐字短摘录"}
      ]
    }
  ]
}
''';

  final OpenAIService _openai;

  TutorSocraticTask(this._openai);

  Future<AiTaskResult<TutorSocraticResult>> run({
    required KnowledgePoint knowledgePoint,
    required String question,
    required String userAnswer,
    required List<SourceChunk> sourceChunks,
    List<KnowledgePoint> prerequisiteKnowledgePoints = const [],
    Map<String, List<SourceChunk>> prerequisiteChunksByKnowledgePointId =
        const {},
    List<TutorTurn> previousTurns = const [],
    GroundedLearningContext? groundedContext,
  }) async {
    final trimmedQuestion = question.trim();
    final trimmedAnswer = userAnswer.trim();
    if (trimmedQuestion.isEmpty) {
      return AiTaskResult.failure(
        type: AiTaskErrorType.validation,
        message: '苏格拉底轮次必须包含一个当前问题',
      );
    }
    if (trimmedAnswer.isEmpty) {
      return AiTaskResult.failure(
        type: AiTaskErrorType.validation,
        message: '请先回答当前问题',
      );
    }
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
        message: '当前知识点缺少来源片段，无法评价回答',
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
          question: trimmedQuestion,
          userAnswer: trimmedAnswer,
          sourceChunks: currentChunks,
          prerequisiteKnowledgePoints: prerequisiteKnowledgePoints,
          prerequisiteChunksByKnowledgePointId: sanitizedPrerequisiteChunks,
          previousTurns: previousTurns,
        ),
        temperature: 0.1,
      );

      TutorSocraticResult result;
      try {
        result = _parseResponse(response);
      } catch (e) {
        return AiTaskResult.failure(
          type: AiTaskErrorType.parse,
          message: e.toString(),
          rawResponse: response,
        );
      }

      final availableChunks = <SourceChunk>[
        ...currentChunks,
        ...sanitizedPrerequisiteChunks.values.expand((chunks) => chunks),
      ];
      final audit = groundedContext == null
          ? const GroundedClaimGate().evaluate(
              claims: result.claims,
              sourceChunks: availableChunks,
              evidenceSufficient: result.evidenceSufficient,
            )
          : const GroundedClaimGate().evaluateContext(
              claims: result.claims,
              context: groundedContext,
              evidenceSufficient: result.evidenceSufficient,
            );
      final feedbackClaims = audit.claimsForSection('feedback');
      final referenceClaims = audit.claimsForSection('reference_answer');
      final misconceptionClaims = audit.claimsForSection('misconception');
      final hasRequiredClaims = feedbackClaims.isNotEmpty &&
          referenceClaims.isNotEmpty &&
          (result.misconception.trim().isEmpty ||
              misconceptionClaims.isNotEmpty);
      final fullyGrounded =
          audit.disposition == GroundingDisposition.grounded &&
              hasRequiredClaims;
      final downgradedDisposition = fullyGrounded
          ? GroundingDisposition.grounded
          : feedbackClaims.isEmpty && referenceClaims.isEmpty
              ? GroundingDisposition.refused
              : GroundingDisposition.partial;
      result = result.copyWith(
        feedback: fullyGrounded
            ? feedbackClaims.map((claim) => claim.text).join('\n')
            : _downgradedText(
                feedbackClaims,
                '部分反馈缺少可核验来源，已停止本轮追问。',
              ),
        referenceAnswer: referenceClaims.map((claim) => claim.text).join('\n'),
        misconception:
            misconceptionClaims.map((claim) => claim.text).join('\n'),
        citationIds: audit.citationIds,
        nextQuestion: fullyGrounded ? result.nextQuestion.trim() : '',
        evidenceSufficient: fullyGrounded,
        accuracyScore: fullyGrounded ? result.accuracyScore.clamp(0, 100) : 0,
        claims: audit.groundedClaims,
        uncoveredClaims: audit.uncoveredClaims,
        groundingDisposition: downgradedDisposition,
      );
      if (!result.evidenceSufficient) {
        return AiTaskResult.success(result, rawResponse: response);
      }
      if (result.feedback.trim().isEmpty ||
          result.referenceAnswer.trim().isEmpty ||
          result.nextQuestion.isEmpty ||
          result.citationIds.isEmpty) {
        return AiTaskResult.failure(
          type: AiTaskErrorType.emptyResult,
          message: 'AI 未返回带有效引用的反馈和唯一下一问',
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

  String _downgradedText(List<GroundedClaim> claims, String fallback) {
    final groundedText = claims.map((claim) => claim.text).join('\n').trim();
    return groundedText.isEmpty ? fallback : '$groundedText\n$fallback';
  }

  String _buildUserContent({
    required KnowledgePoint knowledgePoint,
    required String question,
    required String userAnswer,
    required List<SourceChunk> sourceChunks,
    required List<KnowledgePoint> prerequisiteKnowledgePoints,
    required Map<String, List<SourceChunk>>
        prerequisiteChunksByKnowledgePointId,
    required List<TutorTurn> previousTurns,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('--- current_knowledge_point ---');
    buffer.writeln('id: ${knowledgePoint.id}');
    buffer.writeln('title: ${knowledgePoint.title}');
    buffer.writeln('summary: ${knowledgePoint.summary}');
    _writeChunks(buffer, sourceChunks);

    buffer.writeln('--- confirmed_prerequisites ---');
    if (prerequisiteKnowledgePoints.isEmpty) {
      buffer.writeln('none');
    } else {
      for (final point in prerequisiteKnowledgePoints) {
        buffer.writeln('id: ${point.id}');
        buffer.writeln('title: ${point.title}');
        buffer.writeln('summary: ${point.summary}');
        _writeChunks(
          buffer,
          prerequisiteChunksByKnowledgePointId[point.id] ?? const [],
        );
      }
    }

    buffer.writeln('--- previous_tutor_turns ---');
    for (final turn in previousTurns.reversed.take(6).toList().reversed) {
      buffer.writeln('question: ${turn.questionText}');
      buffer.writeln('user_answer: ${turn.userAnswer}');
      buffer.writeln('feedback: ${turn.aiFeedback}');
      if (turn.misconception.isNotEmpty) {
        buffer.writeln('misconception: ${turn.misconception}');
      }
      buffer.writeln();
    }

    buffer.writeln('--- current_turn ---');
    buffer.writeln('question: $question');
    buffer.writeln('user_answer: $userAnswer');
    return buffer.toString();
  }

  void _writeChunks(StringBuffer buffer, List<SourceChunk> chunks) {
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
  }

  TutorSocraticResult _parseResponse(String response) {
    try {
      return TutorSocraticResult.fromJson(
        jsonDecode(response) as Map<String, dynamic>,
      );
    } catch (_) {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        throw FormatException('无法从 AI 响应中解析 JSON: $response');
      }
      return TutorSocraticResult.fromJson(
        jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>,
      );
    }
  }
}
