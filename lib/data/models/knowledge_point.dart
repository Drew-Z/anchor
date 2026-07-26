enum KnowledgePointKind {
  concept('concept', '通用概念'),
  architecture('architecture', '架构'),
  dataFlow('data_flow', '数据流'),
  implementation('implementation', '实现'),
  boundary('boundary', '边界'),
  tradeOff('trade_off', '取舍');

  final String value;
  final String label;

  const KnowledgePointKind(this.value, this.label);

  bool get isProjectUnderstanding => this != KnowledgePointKind.concept;

  static KnowledgePointKind fromString(String? value) {
    return KnowledgePointKind.values.firstWhere(
      (kind) => kind.value == value,
      orElse: () => KnowledgePointKind.concept,
    );
  }
}

class KnowledgePoint {
  final String id;
  final String title;
  final String summary;
  final KnowledgePointKind kind;
  final List<String> tags;
  final int difficulty;
  final int interviewRelevance;
  final int masteryLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  KnowledgePoint({
    required this.id,
    required this.title,
    required this.summary,
    this.kind = KnowledgePointKind.concept,
    this.tags = const [],
    this.difficulty = 1,
    this.interviewRelevance = 0,
    this.masteryLevel = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  KnowledgePoint copyWith({
    String? id,
    String? title,
    String? summary,
    KnowledgePointKind? kind,
    List<String>? tags,
    int? difficulty,
    int? interviewRelevance,
    int? masteryLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KnowledgePoint(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      kind: kind ?? this.kind,
      tags: tags ?? this.tags,
      difficulty: difficulty ?? this.difficulty,
      interviewRelevance: interviewRelevance ?? this.interviewRelevance,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'kind': kind.value,
      'tags': tags.join('\x00'),
      'difficulty': difficulty,
      'interview_relevance': interviewRelevance,
      'mastery_level': masteryLevel,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory KnowledgePoint.fromMap(Map<String, dynamic> map) {
    return KnowledgePoint(
      id: map['id'] as String,
      title: map['title'] as String,
      summary: map['summary'] as String,
      kind: KnowledgePointKind.fromString(map['kind'] as String?),
      tags: (map['tags'] as String?)
              ?.split('\x00')
              .where((tag) => tag.isNotEmpty)
              .toList() ??
          [],
      difficulty: (map['difficulty'] as int?) ?? 1,
      interviewRelevance: (map['interview_relevance'] as int?) ?? 0,
      masteryLevel: (map['mastery_level'] as int?) ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
