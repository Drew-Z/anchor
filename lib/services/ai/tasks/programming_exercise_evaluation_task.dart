import 'dart:convert';

import '../../../data/models/grounded_claim.dart';
import '../../../data/models/grounded_learning_context.dart';
import '../../../data/models/knowledge_point.dart';
import '../../../data/models/programming_exercise.dart';
import '../../../data/models/source_chunk.dart';
import '../../openai_service.dart';
import '../ai_task_result.dart';
import '../grounded_claim_gate.dart';
import 'programming_exercise_generation_task.dart';

class ProgrammingExerciseEvaluationResult {
  final String feedback;
  final int conceptAccuracyScore;
  final int reasoningProcessScore;
  final int evidenceUseScore;
  final int clarityScore;
  final String misconceptionCode;
  final String misconceptionLabel;
  final String repairExplanation;
  final List<String> citationIds;
  final bool evidenceSufficient;
  final ProgrammingExerciseDraft? retestExercise;
  final List<GroundedClaim> claims;
  final List<GroundedClaim> uncoveredClaims;
  final GroundingDisposition groundingDisposition;

  const ProgrammingExerciseEvaluationResult({
    required this.feedback,
    this.conceptAccuracyScore = 0,
    this.reasoningProcessScore = 0,
    this.evidenceUseScore = 0,
    this.clarityScore = 0,
    this.misconceptionCode = '',
    this.misconceptionLabel = '',
    this.repairExplanation = '',
    this.citationIds = const [],
    this.evidenceSufficient = true,
    this.retestExercise,
    this.claims = const [],
    this.uncoveredClaims = const [],
    this.groundingDisposition = GroundingDisposition.legacy,
  });

  int get averageScore => ((conceptAccuracyScore +
              reasoningProcessScore +
              evidenceUseScore +
              clarityScore) /
          4)
      .round();

  ProgrammingExerciseEvaluationResult copyWith({
    int? conceptAccuracyScore,
    int? reasoningProcessScore,
    int? evidenceUseScore,
    int? clarityScore,
    List<String>? citationIds,
    ProgrammingExerciseDraft? retestExercise,
    bool clearRetestExercise = false,
    String? feedback,
    String? repairExplanation,
    bool? evidenceSufficient,
    List<GroundedClaim>? claims,
    List<GroundedClaim>? uncoveredClaims,
    GroundingDisposition? groundingDisposition,
  }) {
    return ProgrammingExerciseEvaluationResult(
      feedback: feedback ?? this.feedback,
      conceptAccuracyScore: conceptAccuracyScore ?? this.conceptAccuracyScore,
      reasoningProcessScore:
          reasoningProcessScore ?? this.reasoningProcessScore,
      evidenceUseScore: evidenceUseScore ?? this.evidenceUseScore,
      clarityScore: clarityScore ?? this.clarityScore,
      misconceptionCode: misconceptionCode,
      misconceptionLabel: misconceptionLabel,
      repairExplanation: repairExplanation ?? this.repairExplanation,
      citationIds: citationIds ?? this.citationIds,
      evidenceSufficient: evidenceSufficient ?? this.evidenceSufficient,
      retestExercise:
          clearRetestExercise ? null : retestExercise ?? this.retestExercise,
      claims: claims ?? this.claims,
      uncoveredClaims: uncoveredClaims ?? this.uncoveredClaims,
      groundingDisposition: groundingDisposition ?? this.groundingDisposition,
    );
  }

  factory ProgrammingExerciseEvaluationResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final retestJson = json['retest_exercise'];
    return ProgrammingExerciseEvaluationResult(
      feedback: json['feedback'] as String? ?? '',
      conceptAccuracyScore:
          ((json['concept_accuracy_score'] as num?) ?? 0).round(),
      reasoningProcessScore:
          ((json['reasoning_process_score'] as num?) ?? 0).round(),
      evidenceUseScore: ((json['evidence_use_score'] as num?) ?? 0).round(),
      clarityScore: ((json['clarity_score'] as num?) ?? 0).round(),
      misconceptionCode: json['misconception_code'] as String? ?? '',
      misconceptionLabel: json['misconception_label'] as String? ?? '',
      repairExplanation: json['repair_explanation'] as String? ?? '',
      citationIds: (json['citation_ids'] as List<dynamic>? ?? const [])
          .map((id) => id.toString())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(),
      evidenceSufficient: json['evidence_sufficient'] as bool? ?? true,
      retestExercise: retestJson is Map
          ? ProgrammingExerciseDraft.fromJson(
              Map<String, dynamic>.from(retestJson),
            )
          : null,
      claims: decodeGroundedClaims(json['claims']),
    );
  }
}

class ProgrammingExerciseEvaluationTask {
  static const String _systemPrompt = '''
你是一个证据约束的编程练习评价器。你只能根据练习、用户回答、四维标准和提供的 source chunks 评价。

要求：
1. 分别按 0-100 评价：概念准确、推理过程、代码或文档依据、表达清晰。
2. feedback 必须指出回答覆盖、缺失和错误之处，不得用来源之外的事实纠正用户。
3. 平均分低于 80 时，必须把主要错误归并为稳定的 misconception_code 和可读的 misconception_label。
4. 平均分低于 80 时，repair_explanation 必须给出仅由来源支持的修复讲解，并生成一道 source-only 复测题。
5. 复测题必须包含完整四维标准与合法 citation_ids，且不能直接重复原题。
6. citation_ids 只能使用提供的 source_chunk id，并直接支撑反馈、修复讲解和参考答案。
7. 来源不足以评价时 evidence_sufficient=false，明确写“来源不足”，不要补充事实，也不要生成复测题。
8. claims 必须逐项覆盖 feedback，以及非空 repair_explanation；section 分别使用 feedback、repair_explanation。
9. 每个 claim 的 evidence 必须给出合法 citation_id 和该 chunk 中可逐字找到的 quote。
10. 顶层 citation_ids 仅作兼容输出，系统会按通过 quote 校验的 claims 重算。
11. 输出严格 JSON，不要 Markdown，不要解释。

JSON schema：
{
  "feedback": "评价",
  "concept_accuracy_score": 0,
  "reasoning_process_score": 0,
  "evidence_use_score": 0,
  "clarity_score": 0,
  "misconception_code": "stable_code_or_empty",
  "misconception_label": "可读误区或空字符串",
  "repair_explanation": "来源支持的修复讲解或空字符串",
  "citation_ids": ["chunk_id"],
  "evidence_sufficient": true,
  "retest_exercise": null,
  "claims": [
    {
      "section": "feedback",
      "text": "一个独立评价主张",
      "evidence": [
        {"citation_id": "chunk_id", "quote": "来源中的逐字短摘录"}
      ]
    }
  ]
}
''';

  final OpenAIService _openai;

  ProgrammingExerciseEvaluationTask(this._openai);

  Future<AiTaskResult<ProgrammingExerciseEvaluationResult>> run({
    required KnowledgePoint knowledgePoint,
    required ProgrammingExercise exercise,
    required String userAnswer,
    required List<SourceChunk> sourceChunks,
    GroundedLearningContext? groundedContext,
  }) async {
    final answer = userAnswer.trim();
    if (answer.isEmpty) {
      return AiTaskResult.failure(
        type: AiTaskErrorType.validation,
        message: '请先完成编程练习再提交',
      );
    }
    final contextChunks = groundedContext?.chunks ?? sourceChunks;
    if (contextChunks.isEmpty ||
        (groundedContext != null &&
            !groundedContext.isExecutableFor(
              GroundedLearningSurface.programmingExerciseEvaluation,
            ))) {
      return AiTaskResult.failure(
        type: AiTaskErrorType.validation,
        message: '当前练习缺少来源片段，无法评价',
      );
    }

    final knownChunkIds = contextChunks.map((chunk) => chunk.id).toSet();
    try {
      final response = await _openai.chatCompletion(
        systemPrompt: _systemPrompt,
        userContent: _buildUserContent(
          knowledgePoint,
          exercise,
          answer,
          contextChunks,
        ),
        temperature: 0.1,
      );

      ProgrammingExerciseEvaluationResult result;
      try {
        result = _parseResponse(response);
      } catch (e) {
        return AiTaskResult.failure(
          type: AiTaskErrorType.parse,
          message: e.toString(),
          rawResponse: response,
        );
      }

      var retest = result.retestExercise;
      if (retest != null) {
        retest = retest.copyWith(
          citationIds:
              retest.citationIds.where(knownChunkIds.contains).toList(),
        );
        if (!retest.isComplete) retest = null;
      }
      result = result.copyWith(
        conceptAccuracyScore: result.conceptAccuracyScore.clamp(0, 100),
        reasoningProcessScore: result.reasoningProcessScore.clamp(0, 100),
        evidenceUseScore: result.evidenceUseScore.clamp(0, 100),
        clarityScore: result.clarityScore.clamp(0, 100),
        citationIds: result.citationIds.where(knownChunkIds.contains).toList(),
        retestExercise: retest,
        clearRetestExercise: !result.evidenceSufficient || retest == null,
      );

      if (!result.evidenceSufficient) {
        return AiTaskResult.success(
          _refusedResult(result, contextChunks, groundedContext),
          rawResponse: response,
        );
      }

      final audit = groundedContext == null
          ? const GroundedClaimGate().evaluate(
              claims: result.claims,
              sourceChunks: contextChunks,
            )
          : const GroundedClaimGate().evaluateContext(
              claims: result.claims,
              context: groundedContext,
            );
      final feedbackClaims = audit.claimsForSection('feedback');
      final repairClaims = audit.claimsForSection('repair_explanation');
      final hasClaimForExistingRepair =
          result.repairExplanation.trim().isEmpty || repairClaims.isNotEmpty;
      final fullyGrounded =
          audit.disposition == GroundingDisposition.grounded &&
              feedbackClaims.isNotEmpty &&
              hasClaimForExistingRepair;
      if (!fullyGrounded) {
        return AiTaskResult.success(
          result.copyWith(
            feedback: _downgradedText(feedbackClaims),
            repairExplanation:
                repairClaims.map((claim) => claim.text).join('\n'),
            conceptAccuracyScore: 0,
            reasoningProcessScore: 0,
            evidenceUseScore: 0,
            clarityScore: 0,
            citationIds: audit.citationIds,
            evidenceSufficient: false,
            clearRetestExercise: true,
            claims: audit.groundedClaims,
            uncoveredClaims: audit.uncoveredClaims,
            groundingDisposition: feedbackClaims.isEmpty && repairClaims.isEmpty
                ? GroundingDisposition.refused
                : GroundingDisposition.partial,
          ),
          rawResponse: response,
        );
      }
      result = result.copyWith(
        feedback: feedbackClaims.map((claim) => claim.text).join('\n'),
        repairExplanation: repairClaims.map((claim) => claim.text).join('\n'),
        citationIds: audit.citationIds,
        claims: audit.groundedClaims,
        uncoveredClaims: audit.uncoveredClaims,
        groundingDisposition: GroundingDisposition.grounded,
      );
      if (result.feedback.trim().isEmpty || result.citationIds.isEmpty) {
        return AiTaskResult.failure(
          type: AiTaskErrorType.emptyResult,
          message: 'AI 未返回带有效引用的四维评价',
          rawResponse: response,
        );
      }
      if (result.averageScore < 80 &&
          (result.misconceptionCode.trim().isEmpty ||
              result.misconceptionLabel.trim().isEmpty ||
              result.repairExplanation.trim().isEmpty ||
              result.retestExercise == null)) {
        return AiTaskResult.failure(
          type: AiTaskErrorType.emptyResult,
          message: '错误回答缺少可读误区、修复讲解或有来源复测题',
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

  ProgrammingExerciseEvaluationResult _refusedResult(
    ProgrammingExerciseEvaluationResult result,
    List<SourceChunk> sourceChunks,
    GroundedLearningContext? groundedContext,
  ) {
    final audit = groundedContext == null
        ? const GroundedClaimGate().evaluate(
            claims: result.claims,
            sourceChunks: sourceChunks,
            evidenceSufficient: false,
          )
        : const GroundedClaimGate().evaluateContext(
            claims: result.claims,
            context: groundedContext,
            evidenceSufficient: false,
          );
    return result.copyWith(
      feedback: '来源不足，未应用本轮编程练习评分。',
      repairExplanation: '',
      conceptAccuracyScore: 0,
      reasoningProcessScore: 0,
      evidenceUseScore: 0,
      clarityScore: 0,
      citationIds: audit.citationIds,
      evidenceSufficient: false,
      clearRetestExercise: true,
      claims: audit.groundedClaims,
      uncoveredClaims: audit.uncoveredClaims,
      groundingDisposition: GroundingDisposition.refused,
    );
  }

  String _downgradedText(List<GroundedClaim> feedbackClaims) {
    final groundedText =
        feedbackClaims.map((claim) => claim.text).join('\n').trim();
    const notice = '部分练习评价缺少可核验来源，未应用本轮评分。';
    return groundedText.isEmpty ? notice : '$groundedText\n$notice';
  }

  String _buildUserContent(
    KnowledgePoint knowledgePoint,
    ProgrammingExercise exercise,
    String userAnswer,
    List<SourceChunk> sourceChunks,
  ) {
    final buffer = StringBuffer()
      ..writeln('--- knowledge_point ---')
      ..writeln('id: ${knowledgePoint.id}')
      ..writeln('title: ${knowledgePoint.title}')
      ..writeln('summary: ${knowledgePoint.summary}')
      ..writeln('--- exercise ---')
      ..writeln('kind: ${exercise.kind.value}')
      ..writeln('prompt: ${exercise.prompt}')
      ..writeln('reference_answer: ${exercise.referenceAnswer}')
      ..writeln(
        'concept_accuracy_criterion: ${exercise.conceptAccuracyCriterion}',
      )
      ..writeln(
        'reasoning_process_criterion: ${exercise.reasoningProcessCriterion}',
      )
      ..writeln('evidence_use_criterion: ${exercise.evidenceUseCriterion}')
      ..writeln('clarity_criterion: ${exercise.clarityCriterion}')
      ..writeln('--- user_answer ---')
      ..writeln(userAnswer)
      ..writeln('--- source_chunks ---');
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

  ProgrammingExerciseEvaluationResult _parseResponse(String response) {
    try {
      return ProgrammingExerciseEvaluationResult.fromJson(
        jsonDecode(response) as Map<String, dynamic>,
      );
    } catch (_) {
      final match = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (match == null) {
        throw FormatException('无法从 AI 响应中解析评价 JSON: $response');
      }
      return ProgrammingExerciseEvaluationResult.fromJson(
        jsonDecode(match.group(0)!) as Map<String, dynamic>,
      );
    }
  }
}
