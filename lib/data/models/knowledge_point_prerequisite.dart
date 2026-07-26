class KnowledgePointPrerequisiteDraft {
  final String knowledgePointId;
  final String prerequisiteKnowledgePointId;
  final String rationale;
  final List<String> citationIds;

  const KnowledgePointPrerequisiteDraft({
    required this.knowledgePointId,
    required this.prerequisiteKnowledgePointId,
    required this.rationale,
    this.citationIds = const [],
  });

  String get key => '$prerequisiteKnowledgePointId->$knowledgePointId';

  KnowledgePointPrerequisiteDraft reversed() {
    return KnowledgePointPrerequisiteDraft(
      knowledgePointId: prerequisiteKnowledgePointId,
      prerequisiteKnowledgePointId: knowledgePointId,
      rationale: rationale,
      citationIds: citationIds,
    );
  }

  KnowledgePointPrerequisite toRelation(DateTime createdAt) {
    return KnowledgePointPrerequisite(
      knowledgePointId: knowledgePointId,
      prerequisiteKnowledgePointId: prerequisiteKnowledgePointId,
      rationale: rationale,
      citationIds: citationIds,
      createdAt: createdAt,
    );
  }
}

class KnowledgePointPrerequisite {
  final String knowledgePointId;
  final String prerequisiteKnowledgePointId;
  final String rationale;
  final List<String> citationIds;
  final DateTime createdAt;

  const KnowledgePointPrerequisite({
    required this.knowledgePointId,
    required this.prerequisiteKnowledgePointId,
    required this.rationale,
    this.citationIds = const [],
    required this.createdAt,
  });

  String get key => '$prerequisiteKnowledgePointId->$knowledgePointId';

  KnowledgePointPrerequisiteDraft toDraft() {
    return KnowledgePointPrerequisiteDraft(
      knowledgePointId: knowledgePointId,
      prerequisiteKnowledgePointId: prerequisiteKnowledgePointId,
      rationale: rationale,
      citationIds: citationIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'knowledge_point_id': knowledgePointId,
      'prerequisite_knowledge_point_id': prerequisiteKnowledgePointId,
      'rationale': rationale,
      'citation_ids': citationIds.join('\x00'),
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory KnowledgePointPrerequisite.fromMap(Map<String, dynamic> map) {
    return KnowledgePointPrerequisite(
      knowledgePointId: map['knowledge_point_id'] as String,
      prerequisiteKnowledgePointId:
          map['prerequisite_knowledge_point_id'] as String,
      rationale: (map['rationale'] as String?) ?? '',
      citationIds: (map['citation_ids'] as String?)
              ?.split('\x00')
              .where((id) => id.isNotEmpty)
              .toList() ??
          [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
