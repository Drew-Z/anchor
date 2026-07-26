import 'dart:convert';

import '../../../data/models/grounded_learning_context.dart';
import '../../../data/models/knowledge_point.dart';
import '../../../data/models/source_chunk.dart';
import '../../openai_service.dart';
import '../ai_task_result.dart';

class InterviewQuestionDraft {
  final String question;
  final List<String> knowledgePointIds;
  final List<String> citationIds;
  final int difficulty;
  final bool isFollowUp;

  InterviewQuestionDraft({
    required this.question,
    this.knowledgePointIds = const [],
    this.citationIds = const [],
    this.difficulty = 1,
    this.isFollowUp = false,
  });

  InterviewQuestionDraft copyWith({
    String? question,
    List<String>? knowledgePointIds,
    List<String>? citationIds,
    int? difficulty,
    bool? isFollowUp,
  }) {
    return InterviewQuestionDraft(
      question: question ?? this.question,
      knowledgePointIds: knowledgePointIds ?? this.knowledgePointIds,
      citationIds: citationIds ?? this.citationIds,
      difficulty: difficulty ?? this.difficulty,
      isFollowUp: isFollowUp ?? this.isFollowUp,
    );
  }

  factory InterviewQuestionDraft.fromJson(Map<String, dynamic> json) {
    return InterviewQuestionDraft(
      question: json['question'] as String? ?? '',
      knowledgePointIds: (json['knowledge_point_ids'] as List<dynamic>?)
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
      difficulty:
          ((json['difficulty'] as num?) ?? 1).round().clamp(1, 5).toInt(),
      isFollowUp: json['is_follow_up'] as bool? ?? false,
    );
  }
}

class InterviewQuestionResult {
  final List<InterviewQuestionDraft> questions;

  InterviewQuestionResult({required this.questions});

  factory InterviewQuestionResult.fromJson(Map<String, dynamic> json) {
    final questionsJson = json['questions'] as List<dynamic>? ?? [];
    return InterviewQuestionResult(
      questions: questionsJson
          .whereType<Map<String, dynamic>>()
          .map(InterviewQuestionDraft.fromJson)
          .where((question) =>
              question.question.trim().isNotEmpty &&
              question.knowledgePointIds.isNotEmpty)
          .toList(),
    );
  }
}

class InterviewQuestionTask {
  static const String _systemPrompt = '''
你是一个 AI 应用开发面试官。你的任务是基于项目知识点和来源片段生成面试追问。

要求：
1. 只基于提供的 knowledge points 和 source chunks 提问。
2. 问题要逼迫候选人讲清楚项目细节、技术取舍和工程思维。
3. 不要在问题里给出参考答案。
4. 每个问题必须关联 knowledge_point_ids。
5. 如果问题依赖具体源码或材料，必须给 citation_ids。
6. 每个 citation_ids 必须来自提供的 source chunks。
7. difficulty 范围 1-5。
8. 如果用户提供 follow_up_question，要优先围绕它生成追问；来源不足时不要强行生成无依据问题。
9. 输出严格 JSON，不要 Markdown，不要解释。

JSON schema：
{
  "questions": [
    {
      "question": "你会如何解释这个项目的 AI 拆题链路？",
      "knowledge_point_ids": ["kp_id"],
      "citation_ids": ["chunk_id"],
      "difficulty": 3
    }
  ]
}
''';

  final OpenAIService _openai;

  InterviewQuestionTask(this._openai);

  Future<AiTaskResult<InterviewQuestionResult>> run({
    required List<KnowledgePoint> knowledgePoints,
    required List<SourceChunk> sourceChunks,
    int questionCount = 1,
    String? followUpQuestion,
    GroundedLearningContext? groundedContext,
  }) async {
    if (knowledgePoints.isEmpty) {
      return AiTaskResult.failure(
        type: AiTaskErrorType.validation,
        message: '至少需要一个知识点才能生成面试问题',
      );
    }
    final contextChunks = groundedContext?.chunks ?? sourceChunks;
    if (contextChunks.isEmpty ||
        (groundedContext != null &&
            !groundedContext.isExecutableFor(
              GroundedLearningSurface.interview,
            ))) {
      return AiTaskResult.failure(
        type: AiTaskErrorType.validation,
        message: '至少需要一个来源片段才能生成来源约束面试问题',
      );
    }

    try {
      final response = await _openai.chatCompletion(
        systemPrompt: _systemPrompt,
        userContent: _buildUserContent(
          knowledgePoints: knowledgePoints,
          sourceChunks: contextChunks,
          questionCount: questionCount,
          followUpQuestion: followUpQuestion,
        ),
        temperature: 0.3,
      );

      InterviewQuestionResult result;
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
        knowledgePoints: knowledgePoints,
        sourceChunks: contextChunks,
      );

      if (result.questions.isEmpty) {
        return AiTaskResult.failure(
          type: AiTaskErrorType.emptyResult,
          message: 'AI 未生成带有效知识点和引用依据的面试问题',
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

  InterviewQuestionResult _sanitizeResult({
    required InterviewQuestionResult result,
    required List<KnowledgePoint> knowledgePoints,
    required List<SourceChunk> sourceChunks,
  }) {
    final knownPointIds = knowledgePoints.map((point) => point.id).toSet();
    final knownChunkIds = sourceChunks.map((chunk) => chunk.id).toSet();

    final questions = result.questions
        .map((question) {
          final pointIds = question.knowledgePointIds
              .where(knownPointIds.contains)
              .toSet()
              .toList();
          final citationIds = question.citationIds
              .where(knownChunkIds.contains)
              .toSet()
              .toList();
          return question.copyWith(
            knowledgePointIds: pointIds,
            citationIds: citationIds,
          );
        })
        .where((question) =>
            question.question.trim().isNotEmpty &&
            question.knowledgePointIds.isNotEmpty &&
            question.citationIds.isNotEmpty)
        .toList();

    return InterviewQuestionResult(questions: questions);
  }

  String _buildUserContent({
    required List<KnowledgePoint> knowledgePoints,
    required List<SourceChunk> sourceChunks,
    required int questionCount,
    String? followUpQuestion,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('请生成 $questionCount 个面试问题。');
    buffer.writeln();

    final question = followUpQuestion?.trim();
    if (question != null && question.isNotEmpty) {
      buffer.writeln('--- follow_up_question ---');
      buffer.writeln(question);
      buffer.writeln();
    }

    buffer.writeln('--- knowledge_points ---');
    for (final point in knowledgePoints) {
      buffer.writeln('id: ${point.id}');
      buffer.writeln('title: ${point.title}');
      buffer.writeln('kind: ${point.kind.value}');
      buffer.writeln('summary: ${point.summary}');
      buffer.writeln('tags: ${point.tags.join(', ')}');
      buffer.writeln('difficulty: ${point.difficulty}');
      buffer.writeln('interview_relevance: ${point.interviewRelevance}');
      buffer.writeln();
    }

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

  InterviewQuestionResult _parseResponse(String response) {
    try {
      return InterviewQuestionResult.fromJson(
        jsonDecode(response) as Map<String, dynamic>,
      );
    } catch (_) {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        throw FormatException('无法从 AI 响应中解析 JSON: $response');
      }
      return InterviewQuestionResult.fromJson(
        jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>,
      );
    }
  }
}
