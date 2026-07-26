enum ProgrammingWeakDimension {
  conceptAccuracy('concept_accuracy', '概念准确'),
  reasoningProcess('reasoning_process', '推理过程'),
  evidenceUse('evidence_use', '代码或文档依据'),
  clarity('clarity', '表达清晰');

  final String value;
  final String label;

  const ProgrammingWeakDimension(this.value, this.label);

  static ProgrammingWeakDimension? tryParse(String value) {
    for (final dimension in ProgrammingWeakDimension.values) {
      if (dimension.value == value) return dimension;
    }
    return null;
  }
}

enum ProgrammingReviewTriggerType {
  tutorTurn('tutor_turn'),
  exerciseAttempt('exercise_attempt');

  final String value;

  const ProgrammingReviewTriggerType(this.value);

  static ProgrammingReviewTriggerType fromString(String value) {
    return ProgrammingReviewTriggerType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ProgrammingReviewTriggerType.exerciseAttempt,
    );
  }
}

class ProgrammingReviewAction {
  final String id;
  final String knowledgePointId;
  final ProgrammingReviewTriggerType triggerType;
  final String triggerId;
  final List<ProgrammingWeakDimension> weakDimensions;
  final List<String> prerequisiteKnowledgePointIds;
  final List<String> citationIds;
  final List<String> reviewQuestionIds;
  final List<String> reviewExerciseIds;
  final DateTime dueAt;
  final DateTime createdAt;
  final DateTime? completedAt;

  const ProgrammingReviewAction({
    required this.id,
    required this.knowledgePointId,
    required this.triggerType,
    required this.triggerId,
    required this.weakDimensions,
    this.prerequisiteKnowledgePointIds = const [],
    this.citationIds = const [],
    this.reviewQuestionIds = const [],
    this.reviewExerciseIds = const [],
    required this.dueAt,
    required this.createdAt,
    this.completedAt,
  });

  bool get isCompleted => completedAt != null;
  bool get isActionable =>
      reviewQuestionIds.isNotEmpty || reviewExerciseIds.isNotEmpty;

  ProgrammingReviewAction copyWith({
    String? id,
    String? knowledgePointId,
    ProgrammingReviewTriggerType? triggerType,
    String? triggerId,
    List<ProgrammingWeakDimension>? weakDimensions,
    List<String>? prerequisiteKnowledgePointIds,
    List<String>? citationIds,
    List<String>? reviewQuestionIds,
    List<String>? reviewExerciseIds,
    DateTime? dueAt,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return ProgrammingReviewAction(
      id: id ?? this.id,
      knowledgePointId: knowledgePointId ?? this.knowledgePointId,
      triggerType: triggerType ?? this.triggerType,
      triggerId: triggerId ?? this.triggerId,
      weakDimensions: weakDimensions ?? this.weakDimensions,
      prerequisiteKnowledgePointIds:
          prerequisiteKnowledgePointIds ?? this.prerequisiteKnowledgePointIds,
      citationIds: citationIds ?? this.citationIds,
      reviewQuestionIds: reviewQuestionIds ?? this.reviewQuestionIds,
      reviewExerciseIds: reviewExerciseIds ?? this.reviewExerciseIds,
      dueAt: dueAt ?? this.dueAt,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'knowledge_point_id': knowledgePointId,
      'trigger_type': triggerType.value,
      'trigger_id': triggerId,
      'weak_dimensions':
          weakDimensions.map((dimension) => dimension.value).join('\x00'),
      'prerequisite_knowledge_point_ids':
          _normalizedIds(prerequisiteKnowledgePointIds).join('\x00'),
      'citation_ids': _normalizedIds(citationIds).join('\x00'),
      'review_question_ids': _normalizedIds(reviewQuestionIds).join('\x00'),
      'review_exercise_ids': _normalizedIds(reviewExerciseIds).join('\x00'),
      'due_at': dueAt.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
    };
  }

  factory ProgrammingReviewAction.fromMap(Map<String, Object?> map) {
    return ProgrammingReviewAction(
      id: map['id'] as String,
      knowledgePointId: map['knowledge_point_id'] as String,
      triggerType: ProgrammingReviewTriggerType.fromString(
        map['trigger_type'] as String,
      ),
      triggerId: map['trigger_id'] as String,
      weakDimensions: _ids(map['weak_dimensions'])
          .map(ProgrammingWeakDimension.tryParse)
          .whereType<ProgrammingWeakDimension>()
          .toList(),
      prerequisiteKnowledgePointIds:
          _ids(map['prerequisite_knowledge_point_ids']),
      citationIds: _ids(map['citation_ids']),
      reviewQuestionIds: _ids(map['review_question_ids']),
      reviewExerciseIds: _ids(map['review_exercise_ids']),
      dueAt: DateTime.fromMillisecondsSinceEpoch(map['due_at'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      completedAt: map['completed_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int),
    );
  }
}

List<String> _ids(Object? value) {
  return (value as String?)
          ?.split('\x00')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList() ??
      const <String>[];
}

List<String> _normalizedIds(List<String> values) {
  return values
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();
}
