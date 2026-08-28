import 'dart:convert';

import '../../../data/models/knowledge_point.dart';
import '../../../data/models/question.dart';
import '../../../data/models/question_type.dart';
import '../../../data/models/source_chunk.dart';
import '../../openai_service.dart';
import '../ai_task_result.dart';

/// AI 生成的题目草稿(未持久化)
///
/// **与 Question 的区别**:
/// - GeneratedQuestionDraft: AI 生成的临时结果,不包含 id/createdAt 等持久化字段
/// - Question: 持久化到数据库的题目,包含完整的元数据和统计数据
///
/// **字段说明**:
/// - [type]: 题目类型(选择题/填空题/匹配题等)
/// - [content]: 题目内容
/// - [options]: 选项列表(选择题/匹配题使用)
/// - [answer]: 标准答案
/// - [explanation]: 解析(可选)
/// - [knowledgePointId]: 关联的知识点ID(可选)
/// - [difficulty]: 难度等级 1-5
/// - [sourceStatus]: 来源状态(是否有引用支撑)
/// - [citationIds]: 引用的 SourceChunk ID 列表
/// - [matchLeft]/[matchRight]: 匹配题的左右列表
class GeneratedQuestionDraft {
  final QuestionType type;
  final String content;
  final List<String> options;
  final String answer;
  final String? explanation;
  final String? knowledgePointId;
  final int difficulty;
  final SourceStatus sourceStatus;
  final List<String> citationIds;
  final List<String>? matchLeft;
  final List<String>? matchRight;

  GeneratedQuestionDraft({
    required this.type,
    required this.content,
    this.options = const [],
    required this.answer,
    this.explanation,
    this.knowledgePointId,
    this.difficulty = 1,
    this.sourceStatus = SourceStatus.noSource,
    this.citationIds = const [],
    this.matchLeft,
    this.matchRight,
  });

  GeneratedQuestionDraft copyWith({
    QuestionType? type,
    String? content,
    List<String>? options,
    String? answer,
    String? explanation,
    String? knowledgePointId,
    int? difficulty,
    SourceStatus? sourceStatus,
    List<String>? citationIds,
    List<String>? matchLeft,
    List<String>? matchRight,
  }) {
    return GeneratedQuestionDraft(
      type: type ?? this.type,
      content: content ?? this.content,
      options: options ?? this.options,
      answer: answer ?? this.answer,
      explanation: explanation ?? this.explanation,
      knowledgePointId: knowledgePointId ?? this.knowledgePointId,
      difficulty: difficulty ?? this.difficulty,
      sourceStatus: sourceStatus ?? this.sourceStatus,
      citationIds: citationIds ?? this.citationIds,
      matchLeft: matchLeft ?? this.matchLeft,
      matchRight: matchRight ?? this.matchRight,
    );
  }

  factory GeneratedQuestionDraft.fromJson(Map<String, dynamic> json) {
    final parsedCitationIds = (json['citation_ids'] as List<dynamic>?)
            ?.map((id) => id.toString())
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList() ??
        [];
    final parsedStatus = SourceStatus.fromString(
      json['source_status'] as String? ?? SourceStatus.pending.value,
    );
    final citationIds =
        parsedStatus == SourceStatus.noSource ? <String>[] : parsedCitationIds;
    final sourceStatus =
        citationIds.isEmpty ? SourceStatus.noSource : parsedStatus;

    return GeneratedQuestionDraft(
      type: QuestionType.fromString(
        json['type'] as String? ?? QuestionType.multipleChoice.value,
      ),
      content: json['content'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((option) => option.toString())
              .toList() ??
          [],
      answer: json['answer']?.toString() ?? '',
      explanation: json['explanation'] as String?,
      knowledgePointId: json['knowledge_point_id'] as String?,
      difficulty:
          ((json['difficulty'] as num?) ?? 1).round().clamp(1, 5).toInt(),
      sourceStatus: sourceStatus,
      citationIds: citationIds,
      matchLeft: (json['match_left'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList(),
      matchRight: (json['match_right'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList(),
    );
  }

  /// 转换为可持久化的 Question 对象
  ///
  /// **参数**:
  /// - [deckId]: 题目所属的卡组ID
  ///
  /// **注意**: 返回的 Question 的 id 为空字符串,需要在插入数据库时生成
  Question toQuestion({required String deckId}) {
    return Question(
      id: '',
      deckId: deckId,
      knowledgePointId: knowledgePointId,
      type: type,
      content: content,
      options: options,
      answer: answer,
      explanation: explanation,
      difficulty: difficulty,
      sourceStatus: sourceStatus,
      citationIds: citationIds,
      matchLeft: matchLeft,
      matchRight: matchRight,
    );
  }
}

/// 题目生成结果
///
/// 包含 AI 生成的所有题目草稿列表
class QuestionGenerationResult {
  final List<GeneratedQuestionDraft> questions;

  QuestionGenerationResult({required this.questions});

  /// 从 JSON 解析,自动过滤无效题目
  ///
  /// **过滤规则**:
  /// - content 为空的题目
  /// - answer 为空的题目
  factory QuestionGenerationResult.fromJson(Map<String, dynamic> json) {
    final questionsJson = json['questions'] as List<dynamic>? ?? [];
    return QuestionGenerationResult(
      questions: questionsJson
          .whereType<Map<String, dynamic>>()
          .map(GeneratedQuestionDraft.fromJson)
          .where((question) =>
              question.content.trim().isNotEmpty &&
              question.answer.trim().isNotEmpty)
          .toList(),
    );
  }
}

/// 题目生成任务
///
/// **功能**: 根据知识点和原文片段生成可学习题目(选择题/填空题/匹配题等)
///
/// **核心原则**:
/// 1. **Source-grounded**: 每道题必须基于提供的知识点和原文,不能编造
/// 2. **引用可溯源**: 题目的答案必须能在原文中找到支撑(citation_ids)
/// 3. **自动过滤无效题目**: 过滤掉内容或答案为空的题目
///
/// **支持的题型**:
/// - multiple_choice: 选择题(4个选项)
/// - fill_blank: 填空题(content 中使用 ___ 表示空缺)
/// - true_false: 判断题(正确/错误)
/// - matching: 匹配题(左右两列,答案格式 "左-右|左-右")
/// - ordering: 排序题(打乱顺序的选项,答案格式 "第一步|第二步|第三步")
///
/// **使用示例**:
/// ```dart
/// final task = QuestionGenerationTask(openAIService);
///
/// final result = await task.run(
///   knowledgePoints: [kp1, kp2],
///   sourceChunks: [chunk1, chunk2],
/// );
///
/// if (result.isSuccess) {
///   for (final question in result.data!.questions) {
///     print('生成题目: ${question.content}');
///     print('答案: ${question.answer}');
///   }
/// }
/// ```
class QuestionGenerationTask {
  static const String _systemPrompt = '''
你是一个严谨的 source-grounded 出题助手。你的任务是根据知识点和来源片段生成可学习题目。

要求：
1. 只基于提供的 knowledge points 和 source chunks 出题。
2. 每道题必须尽量包含 citation_ids，指向支持答案的 source_chunk id。
3. knowledge_point_id 必须来自提供的 knowledge points id。
4. citation_ids 必须来自提供的 source chunks id，不允许编造。
5. 如果某道题没有可靠 citation_ids，source_status 必须是 "no_source"。
6. 如果有 citation_ids，但仍需要用户确认，source_status 使用 "pending"。
7. 不要把 AI 自己的解释当作来源。
8. 题型可用：multiple_choice, fill_blank, true_false, matching, ordering。
9. 输出必须是严格 JSON，不要 Markdown，不要解释。

题型字段：
- multiple_choice: options 4 个，answer 必须等于某个 option。
- fill_blank: content 中使用 ___ 表示空缺。
- true_false: options 为 ["正确", "错误"]，answer 为其中之一。
- matching: match_left, match_right 数量相等，answer 格式 "左-右|左-右"。
- ordering: options 为打乱顺序，answer 格式 "第一步|第二步|第三步"。

JSON schema：
{
  "questions": [
    {
      "knowledge_point_id": "kp_id",
      "type": "multiple_choice",
      "content": "题干",
      "options": ["A", "B", "C", "D"],
      "answer": "B",
      "explanation": "解析",
      "difficulty": 1,
      "source_status": "pending",
      "citation_ids": ["chunk_id"]
    }
  ]
}
''';

  final OpenAIService _openai;

  QuestionGenerationTask(this._openai);

  /// 执行题目生成任务
  ///
  /// **参数**:
  /// - [knowledgePoints]: 知识点列表(不能为空)
  /// - [sourceChunks]: 原文片段列表(不能为空)
  /// - [questionCount]: 期望生成的题目数量(默认 8)
  ///
  /// **返回**: `AiTaskResult<QuestionGenerationResult>`
  /// - 成功: 包含生成的题目列表
  /// - 失败: 包含错误类型和详细信息
  ///
  /// **错误类型**:
  /// - validation: 参数校验失败(如知识点或原文为空)
  /// - request: OpenAI API 调用失败
  /// - parse: JSON 解析失败
  /// - emptyResult: AI 未生成有效题目
  Future<AiTaskResult<QuestionGenerationResult>> run({
    required List<KnowledgePoint> knowledgePoints,
    required List<SourceChunk> sourceChunks,
    int questionCount = 8,
  }) async {
    if (knowledgePoints.isEmpty) {
      return AiTaskResult.failure(
        type: AiTaskErrorType.validation,
        message: '至少需要一个知识点才能生成题目',
      );
    }
    if (sourceChunks.isEmpty) {
      return AiTaskResult.failure(
        type: AiTaskErrorType.validation,
        message: '至少需要一个来源片段才能生成带引用的题目',
      );
    }

    try {
      final response = await _openai.chatCompletion(
        systemPrompt: _systemPrompt,
        userContent: _buildUserContent(
          knowledgePoints: knowledgePoints,
          sourceChunks: sourceChunks,
          questionCount: questionCount,
        ),
        temperature: 0.3,
      );

      QuestionGenerationResult result;
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
        sourceChunks: sourceChunks,
      );

      if (result.questions.isEmpty) {
        return AiTaskResult.failure(
          type: AiTaskErrorType.emptyResult,
          message: 'AI 未生成带有效知识点的题目',
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

  QuestionGenerationResult _sanitizeResult({
    required QuestionGenerationResult result,
    required List<KnowledgePoint> knowledgePoints,
    required List<SourceChunk> sourceChunks,
  }) {
    final knownPointIds = knowledgePoints.map((point) => point.id).toSet();
    final knownChunkIds = sourceChunks.map((chunk) => chunk.id).toSet();

    final questions = result.questions
        .map((question) {
          final citationIds = question.citationIds
              .where(knownChunkIds.contains)
              .toSet()
              .toList();
          final sourceStatus = citationIds.isEmpty
              ? SourceStatus.noSource
              : SourceStatus.pending;
          return question.copyWith(
            citationIds: citationIds,
            sourceStatus: sourceStatus,
          );
        })
        .where((question) =>
            question.content.trim().isNotEmpty &&
            question.answer.trim().isNotEmpty &&
            question.knowledgePointId != null &&
            knownPointIds.contains(question.knowledgePointId))
        .toList();

    return QuestionGenerationResult(questions: questions);
  }

  String _buildUserContent({
    required List<KnowledgePoint> knowledgePoints,
    required List<SourceChunk> sourceChunks,
    required int questionCount,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('请生成 $questionCount 道题。');
    buffer.writeln();

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
      buffer.writeln('source_id: ${chunk.sourceId}');
      if (chunk.locator != null && chunk.locator!.isNotEmpty) {
        buffer.writeln('locator: ${chunk.locator}');
      }
      buffer.writeln('content:');
      buffer.writeln(chunk.content);
      buffer.writeln();
    }

    return buffer.toString();
  }

  QuestionGenerationResult _parseResponse(String response) {
    try {
      return QuestionGenerationResult.fromJson(
        jsonDecode(response) as Map<String, dynamic>,
      );
    } catch (_) {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        throw FormatException('无法从 AI 响应中解析 JSON: $response');
      }
      return QuestionGenerationResult.fromJson(
        jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>,
      );
    }
  }
}
