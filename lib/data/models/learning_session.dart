enum LearningSessionMode {
  quiz('quiz', '答题'),
  interview('interview', '面试'),
  tutor('tutor', '导师'),
  projectWalkthrough('project_walkthrough', '项目讲解'),
  knowledgeAnswer('knowledge_answer', '知识库问答'),
  agentSession('agent_session', 'Agent Session');

  final String value;
  final String label;
  const LearningSessionMode(this.value, this.label);

  static LearningSessionMode fromString(String value) {
    return LearningSessionMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => LearningSessionMode.quiz,
    );
  }
}

class LearningSession {
  final String id;
  final LearningSessionMode mode;
  final String? targetId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int xpGained;
  final String? summary;

  LearningSession({
    required this.id,
    required this.mode,
    this.targetId,
    required this.startedAt,
    this.endedAt,
    this.xpGained = 0,
    this.summary,
  });

  LearningSession copyWith({
    String? id,
    LearningSessionMode? mode,
    String? targetId,
    DateTime? startedAt,
    DateTime? endedAt,
    int? xpGained,
    String? summary,
  }) {
    return LearningSession(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      targetId: targetId ?? this.targetId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      xpGained: xpGained ?? this.xpGained,
      summary: summary ?? this.summary,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mode': mode.value,
      'target_id': targetId,
      'started_at': startedAt.millisecondsSinceEpoch,
      'ended_at': endedAt?.millisecondsSinceEpoch,
      'xp_gained': xpGained,
      'summary': summary,
    };
  }

  factory LearningSession.fromMap(Map<String, dynamic> map) {
    return LearningSession(
      id: map['id'] as String,
      mode: LearningSessionMode.fromString(map['mode'] as String),
      targetId: map['target_id'] as String?,
      startedAt: DateTime.fromMillisecondsSinceEpoch(map['started_at'] as int),
      endedAt: map['ended_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['ended_at'] as int),
      xpGained: (map['xp_gained'] as int?) ?? 0,
      summary: map['summary'] as String?,
    );
  }
}
