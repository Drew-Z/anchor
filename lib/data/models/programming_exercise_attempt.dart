import 'grounded_claim.dart';

class ProgrammingExerciseAttempt {
  final String id;
  final String exerciseId;
  final String knowledgePointId;
  final String userAnswer;
  final String feedback;
  final int conceptAccuracyScore;
  final int reasoningProcessScore;
  final int evidenceUseScore;
  final int clarityScore;
  final String misconceptionCode;
  final String misconceptionLabel;
  final String repairExplanation;
  final List<String> citationIds;
  final bool evidenceSufficient;
  final bool formalMasteryApplied;
  final String? retestExerciseId;
  final List<GroundedClaim> groundedClaims;
  final GroundingDisposition groundingDisposition;
  final DateTime createdAt;

  const ProgrammingExerciseAttempt({
    required this.id,
    required this.exerciseId,
    required this.knowledgePointId,
    required this.userAnswer,
    required this.feedback,
    this.conceptAccuracyScore = 0,
    this.reasoningProcessScore = 0,
    this.evidenceUseScore = 0,
    this.clarityScore = 0,
    this.misconceptionCode = '',
    this.misconceptionLabel = '',
    this.repairExplanation = '',
    this.citationIds = const [],
    this.evidenceSufficient = true,
    this.formalMasteryApplied = false,
    this.retestExerciseId,
    this.groundedClaims = const [],
    this.groundingDisposition = GroundingDisposition.grounded,
    required this.createdAt,
  });

  int get averageScore => ((conceptAccuracyScore +
              reasoningProcessScore +
              evidenceUseScore +
              clarityScore) /
          4)
      .round();

  ProgrammingExerciseAttempt copyWith({
    String? id,
    String? exerciseId,
    String? knowledgePointId,
    String? userAnswer,
    String? feedback,
    int? conceptAccuracyScore,
    int? reasoningProcessScore,
    int? evidenceUseScore,
    int? clarityScore,
    String? misconceptionCode,
    String? misconceptionLabel,
    String? repairExplanation,
    List<String>? citationIds,
    bool? evidenceSufficient,
    bool? formalMasteryApplied,
    String? retestExerciseId,
    List<GroundedClaim>? groundedClaims,
    GroundingDisposition? groundingDisposition,
    DateTime? createdAt,
  }) {
    return ProgrammingExerciseAttempt(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      knowledgePointId: knowledgePointId ?? this.knowledgePointId,
      userAnswer: userAnswer ?? this.userAnswer,
      feedback: feedback ?? this.feedback,
      conceptAccuracyScore: conceptAccuracyScore ?? this.conceptAccuracyScore,
      reasoningProcessScore:
          reasoningProcessScore ?? this.reasoningProcessScore,
      evidenceUseScore: evidenceUseScore ?? this.evidenceUseScore,
      clarityScore: clarityScore ?? this.clarityScore,
      misconceptionCode: misconceptionCode ?? this.misconceptionCode,
      misconceptionLabel: misconceptionLabel ?? this.misconceptionLabel,
      repairExplanation: repairExplanation ?? this.repairExplanation,
      citationIds: citationIds ?? this.citationIds,
      evidenceSufficient: evidenceSufficient ?? this.evidenceSufficient,
      formalMasteryApplied: formalMasteryApplied ?? this.formalMasteryApplied,
      retestExerciseId: retestExerciseId ?? this.retestExerciseId,
      groundedClaims: groundedClaims ?? this.groundedClaims,
      groundingDisposition: groundingDisposition ?? this.groundingDisposition,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    final normalizedCitations = citationIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    return {
      'id': id,
      'exercise_id': exerciseId,
      'knowledge_point_id': knowledgePointId,
      'user_answer': userAnswer,
      'feedback': feedback,
      'concept_accuracy_score': conceptAccuracyScore.clamp(0, 100),
      'reasoning_process_score': reasoningProcessScore.clamp(0, 100),
      'evidence_use_score': evidenceUseScore.clamp(0, 100),
      'clarity_score': clarityScore.clamp(0, 100),
      'misconception_code': misconceptionCode,
      'misconception_label': misconceptionLabel,
      'repair_explanation': repairExplanation,
      'citation_ids': normalizedCitations.join('\x00'),
      'evidence_sufficient': evidenceSufficient ? 1 : 0,
      'formal_mastery_applied': formalMasteryApplied ? 1 : 0,
      'retest_exercise_id': retestExerciseId,
      'grounded_claims_json': encodeGroundedClaims(groundedClaims),
      'grounding_disposition': groundingDisposition.value,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ProgrammingExerciseAttempt.fromMap(Map<String, Object?> map) {
    return ProgrammingExerciseAttempt(
      id: map['id'] as String,
      exerciseId: map['exercise_id'] as String,
      knowledgePointId: map['knowledge_point_id'] as String,
      userAnswer: map['user_answer'] as String,
      feedback: map['feedback'] as String,
      conceptAccuracyScore: map['concept_accuracy_score'] as int? ?? 0,
      reasoningProcessScore: map['reasoning_process_score'] as int? ?? 0,
      evidenceUseScore: map['evidence_use_score'] as int? ?? 0,
      clarityScore: map['clarity_score'] as int? ?? 0,
      misconceptionCode: map['misconception_code'] as String? ?? '',
      misconceptionLabel: map['misconception_label'] as String? ?? '',
      repairExplanation: map['repair_explanation'] as String? ?? '',
      citationIds: (map['citation_ids'] as String?)
              ?.split('\x00')
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList() ??
          const <String>[],
      evidenceSufficient: (map['evidence_sufficient'] as int? ?? 1) == 1,
      formalMasteryApplied: (map['formal_mastery_applied'] as int? ?? 0) == 1,
      retestExerciseId: map['retest_exercise_id'] as String?,
      groundedClaims: decodeGroundedClaims(map['grounded_claims_json']),
      groundingDisposition: GroundingDisposition.fromString(
        map['grounding_disposition'] as String?,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
