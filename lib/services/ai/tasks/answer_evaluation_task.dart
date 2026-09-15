import 'dart:convert';

import '../../../data/models/grounded_claim.dart';
import '../../../data/models/grounded_learning_context.dart';
import '../../../data/models/source_chunk.dart';
import '../../openai_service.dart';
import '../ai_task_result.dart';
import '../ai_provider_diagnostics.dart';
import '../grounded_claim_gate.dart';

class AnswerEvaluationResult {
  final int accuracyScore;
  final int projectDetailScore;
  final int engineeringScore;
  final int clarityScore;
  final String feedback;
  final String referenceAnswer;
  final String followUpQuestion;
  final String followUpKnowledgePointId;
  final List<String> followUpCitationIds;
  final List<String> weakKnowledgePointIds;
  final List<String> citationIds;
  final List<GroundedClaim> claims;
  final List<GroundedClaim> uncoveredClaims;
  final GroundingDisposition groundingDisposition;

  AnswerEvaluationResult({
    required this.accuracyScore,
    required this.projectDetailScore,
    required this.engineeringScore,
    required this.clarityScore,
    required this.feedback,
    required this.referenceAnswer,
    this.followUpQuestion = '',
    this.followUpKnowledgePointId = '',
    this.followUpCitationIds = const [],
    this.weakKnowledgePointIds = const [],
    this.citationIds = const [],
    this.claims = const [],
    this.uncoveredClaims = const [],
    this.groundingDisposition = GroundingDisposition.legacy,
  });

  AnswerEvaluationResult copyWith({
    int? accuracyScore,
    int? projectDetailScore,
    int? engineeringScore,
    int? clarityScore,
    String? feedback,
    String? referenceAnswer,
    String? followUpQuestion,
    String? followUpKnowledgePointId,
    List<String>? followUpCitationIds,
    List<String>? weakKnowledgePointIds,
    List<String>? citationIds,
    List<GroundedClaim>? claims,
    List<GroundedClaim>? uncoveredClaims,
    GroundingDisposition? groundingDisposition,
  }) {
    return AnswerEvaluationResult(
      accuracyScore: accuracyScore ?? this.accuracyScore,
      projectDetailScore: projectDetailScore ?? this.projectDetailScore,
      engineeringScore: engineeringScore ?? this.engineeringScore,
      clarityScore: clarityScore ?? this.clarityScore,
      feedback: feedback ?? this.feedback,
      referenceAnswer: referenceAnswer ?? this.referenceAnswer,
      followUpQuestion: followUpQuestion ?? this.followUpQuestion,
      followUpKnowledgePointId:
          followUpKnowledgePointId ?? this.followUpKnowledgePointId,
      followUpCitationIds: followUpCitationIds ?? this.followUpCitationIds,
      weakKnowledgePointIds:
          weakKnowledgePointIds ?? this.weakKnowledgePointIds,
      citationIds: citationIds ?? this.citationIds,
      claims: claims ?? this.claims,
      uncoveredClaims: uncoveredClaims ?? this.uncoveredClaims,
      groundingDisposition: groundingDisposition ?? this.groundingDisposition,
    );
  }

  factory AnswerEvaluationResult.fromJson(Map<String, dynamic> json) {
    return AnswerEvaluationResult(
      accuracyScore: _score(json['accuracy_score']),
      projectDetailScore: _score(json['project_detail_score']),
      engineeringScore: _score(json['engineering_score']),
      clarityScore: _score(json['clarity_score']),
      feedback: json['feedback'] as String? ?? '',
      referenceAnswer: json['reference_answer'] as String? ?? '',
      followUpQuestion: json['follow_up_question'] as String? ?? '',
      followUpKnowledgePointId:
          json['follow_up_knowledge_point_id'] as String? ?? '',
      followUpCitationIds: (json['follow_up_citation_ids'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList() ??
          [],
      weakKnowledgePointIds:
          (json['weak_knowledge_point_ids'] as List<dynamic>?)
                  ?.map((id) => id.toString())
                  .where((id) => id.isNotEmpty)
                  .toSet()
                  .toList() ??
              [],
      citationIds: (json['citation_ids'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList() ??
          [],
      claims: decodeGroundedClaims(json['claims']),
    );
  }

  static int _score(dynamic value) {
    return ((value as num?) ?? 0).round().clamp(0, 5).toInt();
  }
}

class AnswerEvaluationTask {
  static const String _systemPrompt = '''
你是一个严格但建设性的 AI 应用开发面试评估官。

任务：
根据面试问题、用户回答和来源片段，对用户回答进行评分和反馈。参考答案只能在用户回答之后生成。

评分维度，每项 0-5：
1. accuracy_score：技术事实是否正确。
2. project_detail_score：是否结合项目细节。
3. engineering_score：是否讲出取舍、限制和改进。
4. clarity_score：表达是否清晰像面试回答。

要求：
- 只基于提供的来源片段和问题上下文评估。
- 不要虚构项目事实。
- reference_answer 要像候选人在面试中可以说出的答案。
- reference_answer 必须尽量引用 citation_ids 支撑。
- 如果用户回答暴露薄弱点，写入 weak_knowledge_point_ids。
- weak_knowledge_point_ids 必须来自提供的 knowledge_point_ids。
- citation_ids 必须来自提供的 cited_chunks。
- follow_up_question 只能追问本轮回答中缺失、含糊或与源码矛盾的部分，不能引入新的项目事实。
- 有必要追问时，follow_up_knowledge_point_id 必须来自 knowledge_point_ids，follow_up_citation_ids 必须来自 cited_chunks 且至少一项。
- 没有必要或没有足够依据追问时，follow_up_question 和 follow_up_knowledge_point_id 输出空字符串，follow_up_citation_ids 输出空数组。
- claims 必须逐项覆盖 feedback 和 reference_answer；section 分别使用 feedback、reference_answer。
- 每个 claim 的 evidence 必须包含合法 citation_id 和该 chunk 中可逐字找到的 quote。
- 顶层 citation_ids 仅作兼容输出，系统会按通过 quote 校验的 claims 重算。
- 输出严格 JSON，不要 Markdown，不要解释。

JSON schema：
{
  "accuracy_score": 3,
  "project_detail_score": 2,
  "engineering_score": 2,
  "clarity_score": 4,
  "feedback": "反馈",
  "reference_answer": "参考答案",
  "follow_up_question": "针对本轮答案缺口的追问",
  "follow_up_knowledge_point_id": "kp_id",
  "follow_up_citation_ids": ["chunk_id"],
  "weak_knowledge_point_ids": ["kp_id"],
  "citation_ids": ["chunk_id"],
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

  AnswerEvaluationTask(this._openai);

  Future<AiTaskResult<AnswerEvaluationResult>> run({
    required String question,
    required String userAnswer,
    required List<String> knowledgePointIds,
    required List<SourceChunk> citedChunks,
    GroundedLearningContext? groundedContext,
  }) async {
    if (question.trim().isEmpty) {
      return AiTaskResult.failure(
        type: AiTaskErrorType.validation,
        message: '面试问题不能为空',
      );
    }
    if (userAnswer.trim().isEmpty) {
      return AiTaskResult.failure(
        type: AiTaskErrorType.validation,
        message: '用户回答不能为空',
      );
    }
    final contextChunks = groundedContext?.chunks ?? citedChunks;
    if (contextChunks.isEmpty ||
        (groundedContext != null &&
            !groundedContext.isExecutableFor(
              GroundedLearningSurface.interview,
            ))) {
      return AiTaskResult.failure(
        type: AiTaskErrorType.validation,
        message: '回答评估必须提供来源片段',
      );
    }

    try {
      final response = await _openai.chatCompletion(
        systemPrompt: _systemPrompt,
        userContent: _buildUserContent(
          question: question,
          userAnswer: userAnswer,
          knowledgePointIds: knowledgePointIds,
          citedChunks: contextChunks,
        ),
        temperature: 0.2,
      );

      AnswerEvaluationResult result;
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
        knowledgePointIds: knowledgePointIds,
        citedChunks: contextChunks,
        groundedContext: groundedContext,
      );

      return AiTaskResult.success(result, rawResponse: response);
    } on AiProviderException catch (error) {
      final message = error.kind == AiProviderFailureKind.timeout
          ? 'AI 评估响应超时，请保留回答后重试。'
          : error.message;
      return AiTaskResult.failure(
        type: AiTaskErrorType.request,
        message: message,
      );
    } catch (e) {
      return AiTaskResult.failure(
        type: AiTaskErrorType.request,
        message: e.toString(),
      );
    }
  }

  AnswerEvaluationResult _sanitizeResult({
    required AnswerEvaluationResult result,
    required List<String> knowledgePointIds,
    required List<SourceChunk> citedChunks,
  }) {
    final knownPointIds = knowledgePointIds.toSet();
    final knownCitationIds = citedChunks.map((chunk) => chunk.id).toSet();
    final followUpQuestion = result.followUpQuestion.trim();
    final followUpPointId = result.followUpKnowledgePointId.trim();
    final followUpCitationIds = result.followUpCitationIds
        .where(knownCitationIds.contains)
        .toSet()
        .toList();
    final hasGroundedFollowUp = followUpQuestion.isNotEmpty &&
        knownPointIds.contains(followUpPointId) &&
        followUpCitationIds.isNotEmpty;
    return result.copyWith(
      followUpQuestion: hasGroundedFollowUp ? followUpQuestion : '',
      followUpKnowledgePointId: hasGroundedFollowUp ? followUpPointId : '',
      followUpCitationIds:
          hasGroundedFollowUp ? followUpCitationIds : const <String>[],
      weakKnowledgePointIds: result.weakKnowledgePointIds
          .where(knownPointIds.contains)
          .toSet()
          .toList(),
      citationIds:
          result.citationIds.where(knownCitationIds.contains).toSet().toList(),
    );
  }

  AnswerEvaluationResult _applyGroundingGate({
    required AnswerEvaluationResult result,
    required List<String> knowledgePointIds,
    required List<SourceChunk> citedChunks,
    GroundedLearningContext? groundedContext,
  }) {
    final audit = groundedContext == null
        ? const GroundedClaimGate().evaluate(
            claims: result.claims,
            sourceChunks: citedChunks,
          )
        : const GroundedClaimGate().evaluateContext(
            claims: result.claims,
            context: groundedContext,
          );
    final feedbackClaims = audit.claimsForSection('feedback');
    final referenceClaims = audit.claimsForSection('reference_answer');
    final fullyGrounded = audit.disposition == GroundingDisposition.grounded &&
        feedbackClaims.isNotEmpty &&
        referenceClaims.isNotEmpty;
    final groundedResult = result.copyWith(
      accuracyScore: fullyGrounded ? result.accuracyScore : 0,
      projectDetailScore: fullyGrounded ? result.projectDetailScore : 0,
      engineeringScore: fullyGrounded ? result.engineeringScore : 0,
      clarityScore: fullyGrounded ? result.clarityScore : 0,
      feedback: fullyGrounded
          ? feedbackClaims.map((claim) => claim.text).join('\n')
          : _downgradedText(feedbackClaims),
      referenceAnswer: referenceClaims.map((claim) => claim.text).join('\n'),
      followUpQuestion: fullyGrounded ? result.followUpQuestion : '',
      followUpKnowledgePointId:
          fullyGrounded ? result.followUpKnowledgePointId : '',
      followUpCitationIds:
          fullyGrounded ? result.followUpCitationIds : const [],
      weakKnowledgePointIds:
          fullyGrounded ? result.weakKnowledgePointIds : const [],
      citationIds: audit.citationIds,
      claims: audit.groundedClaims,
      uncoveredClaims: audit.uncoveredClaims,
      groundingDisposition: fullyGrounded
          ? GroundingDisposition.grounded
          : feedbackClaims.isEmpty && referenceClaims.isEmpty
              ? GroundingDisposition.refused
              : GroundingDisposition.partial,
    );
    return _sanitizeResult(
      result: groundedResult,
      knowledgePointIds: knowledgePointIds,
      citedChunks: citedChunks,
    );
  }

  String _downgradedText(List<GroundedClaim> feedbackClaims) {
    final groundedText =
        feedbackClaims.map((claim) => claim.text).join('\n').trim();
    const notice = '部分面试评价缺少可核验来源，未应用本轮评分。';
    return groundedText.isEmpty ? notice : '$groundedText\n$notice';
  }

  String _buildUserContent({
    required String question,
    required String userAnswer,
    required List<String> knowledgePointIds,
    required List<SourceChunk> citedChunks,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('--- interview_question ---');
    buffer.writeln(question);
    buffer.writeln();
    buffer.writeln('knowledge_point_ids: ${knowledgePointIds.join(', ')}');
    buffer.writeln();
    buffer.writeln('--- user_answer ---');
    buffer.writeln(userAnswer);
    buffer.writeln();
    buffer.writeln('--- cited_chunks ---');
    for (final chunk in citedChunks) {
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

  AnswerEvaluationResult _parseResponse(String response) {
    try {
      return AnswerEvaluationResult.fromJson(
        jsonDecode(response) as Map<String, dynamic>,
      );
    } catch (_) {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        throw FormatException('无法从 AI 响应中解析 JSON: $response');
      }
      return AnswerEvaluationResult.fromJson(
        jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>,
      );
    }
  }
}
