import 'grounded_claim.dart';

List<String> _cleanTutorIds(List<String> ids) {
  return ids.where((id) => id.isNotEmpty).toSet().toList();
}

class TutorTurn {
  final String id;
  final String sessionId;
  final String knowledgePointId;
  final String questionText;
  final String userAnswer;
  final String aiFeedback;
  final String referenceAnswer;
  final String misconception;
  final String nextQuestion;
  final List<String> citationIds;
  final List<String> prerequisiteKnowledgePointIds;
  final bool evidenceSufficient;
  final int accuracyScore;
  final List<GroundedClaim> groundedClaims;
  final GroundingDisposition groundingDisposition;
  final DateTime createdAt;

  const TutorTurn({
    required this.id,
    required this.sessionId,
    required this.knowledgePointId,
    required this.questionText,
    required this.userAnswer,
    required this.aiFeedback,
    this.referenceAnswer = '',
    this.misconception = '',
    this.nextQuestion = '',
    this.citationIds = const [],
    this.prerequisiteKnowledgePointIds = const [],
    this.evidenceSufficient = true,
    this.accuracyScore = 0,
    this.groundedClaims = const [],
    this.groundingDisposition = GroundingDisposition.grounded,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'knowledge_point_id': knowledgePointId,
      'question_text': questionText,
      'user_answer': userAnswer,
      'ai_feedback': aiFeedback,
      'reference_answer': referenceAnswer,
      'misconception': misconception,
      'next_question': nextQuestion,
      'citation_ids': _cleanTutorIds(citationIds).join('\x00'),
      'prerequisite_knowledge_point_ids':
          _cleanTutorIds(prerequisiteKnowledgePointIds).join('\x00'),
      'evidence_sufficient': evidenceSufficient ? 1 : 0,
      'accuracy_score': accuracyScore.clamp(0, 100),
      'grounded_claims_json': encodeGroundedClaims(groundedClaims),
      'grounding_disposition': groundingDisposition.value,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory TutorTurn.fromMap(Map<String, dynamic> map) {
    return TutorTurn(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      knowledgePointId: map['knowledge_point_id'] as String,
      questionText: map['question_text'] as String,
      userAnswer: map['user_answer'] as String,
      aiFeedback: map['ai_feedback'] as String,
      referenceAnswer: map['reference_answer'] as String? ?? '',
      misconception: map['misconception'] as String? ?? '',
      nextQuestion: map['next_question'] as String? ?? '',
      citationIds: _cleanTutorIds(
        (map['citation_ids'] as String?)?.split('\x00') ?? const [],
      ),
      prerequisiteKnowledgePointIds: _cleanTutorIds(
        (map['prerequisite_knowledge_point_ids'] as String?)?.split('\x00') ??
            const [],
      ),
      evidenceSufficient: (map['evidence_sufficient'] as int? ?? 0) == 1,
      accuracyScore: (map['accuracy_score'] as int? ?? 0).clamp(0, 100).toInt(),
      groundedClaims: decodeGroundedClaims(map['grounded_claims_json']),
      groundingDisposition: GroundingDisposition.fromString(
        map['grounding_disposition'] as String?,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
