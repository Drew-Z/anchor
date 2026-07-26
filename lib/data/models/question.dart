import 'question_type.dart';

enum SourceStatus {
  verified('verified', '已核验'),
  pending('pending', '待核验'),
  noSource('no_source', '无来源');

  final String value;
  final String label;
  const SourceStatus(this.value, this.label);

  static SourceStatus fromString(String value) {
    return SourceStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SourceStatus.noSource,
    );
  }
}

List<String> _citationIdsForStatus(
  SourceStatus sourceStatus,
  List<String> citationIds,
) {
  if (sourceStatus == SourceStatus.noSource) return const <String>[];
  return citationIds.where((id) => id.isNotEmpty).toSet().toList();
}

SourceStatus _sourceStatusForCitations(
  SourceStatus sourceStatus,
  List<String> citationIds,
) {
  return citationIds.isEmpty ? SourceStatus.noSource : sourceStatus;
}

/// 题目模型
class Question {
  final String id;
  final String deckId;
  final String? knowledgePointId;
  final QuestionType type;
  final String content; // 题干
  final List<String> options; // 选项(选择题/判断题/排序题用)
  final String answer; // 正确答案
  final String? explanation; // 解析
  final int difficulty;
  final SourceStatus sourceStatus;
  final List<String> citationIds;
  final DateTime? lastReviewedAt;
  final DateTime? nextReviewAt;
  final double ease;
  final int lapseCount;
  // 匹配题专用: 左右两列
  final List<String>? matchLeft;
  final List<String>? matchRight;

  Question({
    required this.id,
    required this.deckId,
    this.knowledgePointId,
    required this.type,
    required this.content,
    this.options = const [],
    required this.answer,
    this.explanation,
    this.difficulty = 1,
    this.sourceStatus = SourceStatus.noSource,
    this.citationIds = const [],
    this.lastReviewedAt,
    this.nextReviewAt,
    this.ease = 1.0,
    this.lapseCount = 0,
    this.matchLeft,
    this.matchRight,
  });

  Question copyWith({
    String? id,
    String? deckId,
    String? knowledgePointId,
    QuestionType? type,
    String? content,
    List<String>? options,
    String? answer,
    String? explanation,
    int? difficulty,
    SourceStatus? sourceStatus,
    List<String>? citationIds,
    DateTime? lastReviewedAt,
    DateTime? nextReviewAt,
    double? ease,
    int? lapseCount,
    List<String>? matchLeft,
    List<String>? matchRight,
  }) {
    return Question(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      knowledgePointId: knowledgePointId ?? this.knowledgePointId,
      type: type ?? this.type,
      content: content ?? this.content,
      options: options ?? this.options,
      answer: answer ?? this.answer,
      explanation: explanation ?? this.explanation,
      difficulty: difficulty ?? this.difficulty,
      sourceStatus: sourceStatus ?? this.sourceStatus,
      citationIds: citationIds ?? this.citationIds,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      ease: ease ?? this.ease,
      lapseCount: lapseCount ?? this.lapseCount,
      matchLeft: matchLeft ?? this.matchLeft,
      matchRight: matchRight ?? this.matchRight,
    );
  }

  Map<String, dynamic> toMap() {
    final normalizedCitationIds =
        _citationIdsForStatus(sourceStatus, citationIds);
    final normalizedSourceStatus =
        _sourceStatusForCitations(sourceStatus, normalizedCitationIds);

    return {
      'id': id,
      'deck_id': deckId,
      'knowledge_point_id': knowledgePointId,
      'type': type.value,
      'content': content,
      'options': options.join('\x00'),
      'answer': answer,
      'explanation': explanation,
      'difficulty': difficulty,
      'source_status': normalizedSourceStatus.value,
      'citation_ids': normalizedCitationIds.join('\x00'),
      'last_reviewed_at': lastReviewedAt?.millisecondsSinceEpoch,
      'next_review_at': nextReviewAt?.millisecondsSinceEpoch,
      'ease': ease,
      'lapse_count': lapseCount,
      'match_left': matchLeft?.join('\x00'),
      'match_right': matchRight?.join('\x00'),
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    final sourceStatus = SourceStatus.fromString(
      (map['source_status'] as String?) ?? SourceStatus.noSource.value,
    );
    final citationIds = _citationIdsForStatus(
      sourceStatus,
      (map['citation_ids'] as String?)
              ?.split('\x00')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
    );
    final normalizedSourceStatus =
        _sourceStatusForCitations(sourceStatus, citationIds);

    return Question(
      id: map['id'] as String,
      deckId: map['deck_id'] as String,
      knowledgePointId: map['knowledge_point_id'] as String?,
      type: QuestionType.fromString(map['type'] as String),
      content: map['content'] as String,
      options: (map['options'] as String?)
              ?.split('\x00')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      answer: map['answer'] as String,
      explanation: map['explanation'] as String?,
      difficulty: (map['difficulty'] as int?) ?? 1,
      sourceStatus: normalizedSourceStatus,
      citationIds: citationIds,
      lastReviewedAt: map['last_reviewed_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['last_reviewed_at'] as int),
      nextReviewAt: map['next_review_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['next_review_at'] as int),
      ease: ((map['ease'] as num?) ?? 1.0).toDouble(),
      lapseCount: (map['lapse_count'] as int?) ?? 0,
      matchLeft: (map['match_left'] as String?)
          ?.split('\x00')
          .where((s) => s.isNotEmpty)
          .toList(),
      matchRight: (map['match_right'] as String?)
          ?.split('\x00')
          .where((s) => s.isNotEmpty)
          .toList(),
    );
  }

  /// 从 OpenAI 返回的 JSON 构建
  factory Question.fromJson(Map<String, dynamic> json, String deckId) {
    final type =
        QuestionType.fromString(json['type'] as String? ?? 'multiple_choice');
    final options = (json['options'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final matchLeft = (json['match_left'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();
    final matchRight = (json['match_right'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();
    final citationIds = (json['citation_ids'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];
    final parsedSourceStatus = SourceStatus.fromString(
      json['source_status'] as String? ?? SourceStatus.noSource.value,
    );
    final normalizedCitationIds = _citationIdsForStatus(
      parsedSourceStatus,
      citationIds,
    );
    final normalizedSourceStatus = _sourceStatusForCitations(
      parsedSourceStatus,
      normalizedCitationIds,
    );

    return Question(
      id: '',
      deckId: deckId,
      knowledgePointId: json['knowledge_point_id'] as String?,
      type: type,
      content: json['content'] as String? ?? '',
      options: options,
      answer: json['answer']?.toString() ?? '',
      explanation: json['explanation'] as String?,
      difficulty: ((json['difficulty'] as num?) ?? 1).toInt(),
      sourceStatus: normalizedSourceStatus,
      citationIds: normalizedCitationIds,
      matchLeft: matchLeft,
      matchRight: matchRight,
    );
  }
}
