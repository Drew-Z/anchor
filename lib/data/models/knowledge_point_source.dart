enum KnowledgePointSourceRelation {
  defines('defines', '定义'),
  explains('explains', '解释'),
  example('example', '例子'),
  counterexample('counterexample', '反例'),
  implementation('implementation', '实现');

  final String value;
  final String label;
  const KnowledgePointSourceRelation(this.value, this.label);

  static KnowledgePointSourceRelation fromString(String value) {
    return KnowledgePointSourceRelation.values.firstWhere(
      (e) => e.value == value,
      orElse: () => KnowledgePointSourceRelation.explains,
    );
  }
}

class KnowledgePointSource {
  final String knowledgePointId;
  final String sourceChunkId;
  final KnowledgePointSourceRelation relation;

  KnowledgePointSource({
    required this.knowledgePointId,
    required this.sourceChunkId,
    this.relation = KnowledgePointSourceRelation.explains,
  });

  Map<String, dynamic> toMap() {
    return {
      'knowledge_point_id': knowledgePointId,
      'source_chunk_id': sourceChunkId,
      'relation': relation.value,
    };
  }

  factory KnowledgePointSource.fromMap(Map<String, dynamic> map) {
    return KnowledgePointSource(
      knowledgePointId: map['knowledge_point_id'] as String,
      sourceChunkId: map['source_chunk_id'] as String,
      relation: KnowledgePointSourceRelation.fromString(
        map['relation'] as String,
      ),
    );
  }
}
