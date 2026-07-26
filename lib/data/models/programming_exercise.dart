import 'question.dart';

enum ProgrammingExerciseKind {
  explanation('explanation', '概念解释'),
  codeReading('code_reading', '代码阅读'),
  boundaryJudgment('boundary_judgment', '边界判断'),
  implementation('implementation', '小型实现');

  final String value;
  final String label;

  const ProgrammingExerciseKind(this.value, this.label);

  static ProgrammingExerciseKind fromString(String value) {
    return ProgrammingExerciseKind.values.firstWhere(
      (kind) => kind.value == value,
      orElse: () => ProgrammingExerciseKind.explanation,
    );
  }
}

class ProgrammingExercise {
  final String id;
  final String knowledgePointId;
  final ProgrammingExerciseKind kind;
  final String prompt;
  final String referenceAnswer;
  final String conceptAccuracyCriterion;
  final String reasoningProcessCriterion;
  final String evidenceUseCriterion;
  final String clarityCriterion;
  final SourceStatus sourceStatus;
  final List<String> citationIds;
  final bool isRetest;
  final String? parentAttemptId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProgrammingExercise({
    required this.id,
    required this.knowledgePointId,
    required this.kind,
    required this.prompt,
    required this.referenceAnswer,
    required this.conceptAccuracyCriterion,
    required this.reasoningProcessCriterion,
    required this.evidenceUseCriterion,
    required this.clarityCriterion,
    this.sourceStatus = SourceStatus.pending,
    this.citationIds = const [],
    this.isRetest = false,
    this.parentAttemptId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get canAffectFormalMastery =>
      sourceStatus == SourceStatus.verified && citationIds.isNotEmpty;

  ProgrammingExercise copyWith({
    String? id,
    String? knowledgePointId,
    ProgrammingExerciseKind? kind,
    String? prompt,
    String? referenceAnswer,
    String? conceptAccuracyCriterion,
    String? reasoningProcessCriterion,
    String? evidenceUseCriterion,
    String? clarityCriterion,
    SourceStatus? sourceStatus,
    List<String>? citationIds,
    bool? isRetest,
    String? parentAttemptId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProgrammingExercise(
      id: id ?? this.id,
      knowledgePointId: knowledgePointId ?? this.knowledgePointId,
      kind: kind ?? this.kind,
      prompt: prompt ?? this.prompt,
      referenceAnswer: referenceAnswer ?? this.referenceAnswer,
      conceptAccuracyCriterion:
          conceptAccuracyCriterion ?? this.conceptAccuracyCriterion,
      reasoningProcessCriterion:
          reasoningProcessCriterion ?? this.reasoningProcessCriterion,
      evidenceUseCriterion: evidenceUseCriterion ?? this.evidenceUseCriterion,
      clarityCriterion: clarityCriterion ?? this.clarityCriterion,
      sourceStatus: sourceStatus ?? this.sourceStatus,
      citationIds: citationIds ?? this.citationIds,
      isRetest: isRetest ?? this.isRetest,
      parentAttemptId: parentAttemptId ?? this.parentAttemptId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    final normalizedCitations = citationIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final normalizedStatus =
        normalizedCitations.isEmpty ? SourceStatus.noSource : sourceStatus;
    return {
      'id': id,
      'knowledge_point_id': knowledgePointId,
      'kind': kind.value,
      'prompt': prompt,
      'reference_answer': referenceAnswer,
      'rubric_concept_accuracy': conceptAccuracyCriterion,
      'rubric_reasoning_process': reasoningProcessCriterion,
      'rubric_evidence_use': evidenceUseCriterion,
      'rubric_clarity': clarityCriterion,
      'source_status': normalizedStatus.value,
      'citation_ids': normalizedCitations.join('\x00'),
      'is_retest': isRetest ? 1 : 0,
      'parent_attempt_id': parentAttemptId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ProgrammingExercise.fromMap(Map<String, Object?> map) {
    final citationIds = (map['citation_ids'] as String?)
            ?.split('\x00')
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList() ??
        const <String>[];
    final storedStatus = SourceStatus.fromString(
      map['source_status'] as String? ?? SourceStatus.noSource.value,
    );
    return ProgrammingExercise(
      id: map['id'] as String,
      knowledgePointId: map['knowledge_point_id'] as String,
      kind: ProgrammingExerciseKind.fromString(map['kind'] as String),
      prompt: map['prompt'] as String,
      referenceAnswer: map['reference_answer'] as String,
      conceptAccuracyCriterion: map['rubric_concept_accuracy'] as String? ?? '',
      reasoningProcessCriterion:
          map['rubric_reasoning_process'] as String? ?? '',
      evidenceUseCriterion: map['rubric_evidence_use'] as String? ?? '',
      clarityCriterion: map['rubric_clarity'] as String? ?? '',
      sourceStatus: citationIds.isEmpty ? SourceStatus.noSource : storedStatus,
      citationIds: citationIds,
      isRetest: (map['is_retest'] as int? ?? 0) == 1,
      parentAttemptId: map['parent_attempt_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
