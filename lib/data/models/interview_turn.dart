import 'grounded_claim.dart';
import 'knowledge_point.dart';

enum InterviewScoreDimension {
  accuracy('accuracy', '事实准确'),
  projectDetail('project_detail', '项目细节'),
  engineering('engineering', '工程判断'),
  clarity('clarity', '表达清晰');

  final String value;
  final String label;

  const InterviewScoreDimension(this.value, this.label);

  static InterviewScoreDimension? tryFromString(String value) {
    for (final dimension in InterviewScoreDimension.values) {
      if (dimension.value == value) return dimension;
    }
    return null;
  }
}

List<String> _cleanIds(List<String> ids) {
  return ids.where((id) => id.isNotEmpty).toSet().toList();
}

class InterviewTurn {
  final String id;
  final String sessionId;
  final String questionText;
  final String userAnswer;
  final String aiFeedback;
  final String referenceAnswer;
  final String? knowledgePointId;
  final KnowledgePointKind knowledgePointKind;
  final List<String> citationIds;
  final int accuracyScore;
  final int projectDetailScore;
  final int engineeringScore;
  final int clarityScore;
  final List<String> weakKnowledgePointIds;
  final List<InterviewScoreDimension> weakDimensions;
  final List<String> reviewQuestionIds;
  final DateTime? reviewDueAt;
  final String nextInterviewQuestion;
  final List<GroundedClaim> groundedClaims;
  final GroundingDisposition groundingDisposition;
  final DateTime createdAt;

  InterviewTurn({
    required this.id,
    required this.sessionId,
    required this.questionText,
    required this.userAnswer,
    required this.aiFeedback,
    required this.referenceAnswer,
    this.knowledgePointId,
    this.knowledgePointKind = KnowledgePointKind.concept,
    this.citationIds = const [],
    this.accuracyScore = 0,
    this.projectDetailScore = 0,
    this.engineeringScore = 0,
    this.clarityScore = 0,
    this.weakKnowledgePointIds = const [],
    this.weakDimensions = const [],
    this.reviewQuestionIds = const [],
    this.reviewDueAt,
    this.nextInterviewQuestion = '',
    this.groundedClaims = const [],
    this.groundingDisposition = GroundingDisposition.grounded,
    required this.createdAt,
  });

  bool get hasReviewAction {
    return knowledgePointId != null &&
        weakDimensions.isNotEmpty &&
        citationIds.isNotEmpty &&
        nextInterviewQuestion.isNotEmpty;
  }

  InterviewTurn copyWith({
    List<String>? citationIds,
    List<String>? weakKnowledgePointIds,
    List<InterviewScoreDimension>? weakDimensions,
    List<String>? reviewQuestionIds,
    DateTime? reviewDueAt,
    String? nextInterviewQuestion,
    List<GroundedClaim>? groundedClaims,
    GroundingDisposition? groundingDisposition,
  }) {
    return InterviewTurn(
      id: id,
      sessionId: sessionId,
      questionText: questionText,
      userAnswer: userAnswer,
      aiFeedback: aiFeedback,
      referenceAnswer: referenceAnswer,
      knowledgePointId: knowledgePointId,
      knowledgePointKind: knowledgePointKind,
      citationIds: citationIds ?? this.citationIds,
      accuracyScore: accuracyScore,
      projectDetailScore: projectDetailScore,
      engineeringScore: engineeringScore,
      clarityScore: clarityScore,
      weakKnowledgePointIds:
          weakKnowledgePointIds ?? this.weakKnowledgePointIds,
      weakDimensions: weakDimensions ?? this.weakDimensions,
      reviewQuestionIds: reviewQuestionIds ?? this.reviewQuestionIds,
      reviewDueAt: reviewDueAt ?? this.reviewDueAt,
      nextInterviewQuestion:
          nextInterviewQuestion ?? this.nextInterviewQuestion,
      groundedClaims: groundedClaims ?? this.groundedClaims,
      groundingDisposition: groundingDisposition ?? this.groundingDisposition,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    final normalizedCitationIds = _cleanIds(citationIds);
    final normalizedWeakPointIds = _cleanIds(weakKnowledgePointIds);
    final normalizedReviewQuestionIds = _cleanIds(reviewQuestionIds);
    final normalizedWeakDimensions = weakDimensions.toSet().toList();

    return {
      'id': id,
      'session_id': sessionId,
      'question_text': questionText,
      'user_answer': userAnswer,
      'ai_feedback': aiFeedback,
      'reference_answer': referenceAnswer,
      'knowledge_point_id': knowledgePointId,
      'knowledge_point_kind': knowledgePointKind.value,
      'citation_ids': normalizedCitationIds.join('\x00'),
      'accuracy_score': accuracyScore,
      'project_detail_score': projectDetailScore,
      'engineering_score': engineeringScore,
      'clarity_score': clarityScore,
      'weak_knowledge_point_ids': normalizedWeakPointIds.join('\x00'),
      'weak_dimensions': normalizedWeakDimensions
          .map((dimension) => dimension.value)
          .join('\x00'),
      'review_question_ids': normalizedReviewQuestionIds.join('\x00'),
      'review_due_at': reviewDueAt?.millisecondsSinceEpoch,
      'next_interview_question': nextInterviewQuestion,
      'grounded_claims_json': encodeGroundedClaims(groundedClaims),
      'grounding_disposition': groundingDisposition.value,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory InterviewTurn.fromMap(Map<String, dynamic> map) {
    return InterviewTurn(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      questionText: map['question_text'] as String,
      userAnswer: map['user_answer'] as String,
      aiFeedback: map['ai_feedback'] as String,
      referenceAnswer: map['reference_answer'] as String,
      knowledgePointId: map['knowledge_point_id'] as String?,
      knowledgePointKind: KnowledgePointKind.fromString(
        map['knowledge_point_kind'] as String?,
      ),
      citationIds: _cleanIds(
        (map['citation_ids'] as String?)?.split('\x00') ?? const [],
      ),
      accuracyScore: (map['accuracy_score'] as int?) ?? 0,
      projectDetailScore: (map['project_detail_score'] as int?) ?? 0,
      engineeringScore: (map['engineering_score'] as int?) ?? 0,
      clarityScore: (map['clarity_score'] as int?) ?? 0,
      weakKnowledgePointIds: _cleanIds(
        (map['weak_knowledge_point_ids'] as String?)?.split('\x00') ?? const [],
      ),
      weakDimensions: ((map['weak_dimensions'] as String?)?.split('\x00') ??
              const <String>[])
          .map(InterviewScoreDimension.tryFromString)
          .whereType<InterviewScoreDimension>()
          .toSet()
          .toList(),
      reviewQuestionIds: _cleanIds(
        (map['review_question_ids'] as String?)?.split('\x00') ?? const [],
      ),
      reviewDueAt: map['review_due_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['review_due_at'] as int),
      nextInterviewQuestion: map['next_interview_question'] as String? ?? '',
      groundedClaims: decodeGroundedClaims(map['grounded_claims_json']),
      groundingDisposition: GroundingDisposition.fromString(
        map['grounding_disposition'] as String?,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
