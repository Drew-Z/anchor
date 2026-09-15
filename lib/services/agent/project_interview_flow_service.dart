import '../../data/models/interview_turn.dart';
import '../../data/models/knowledge_point.dart';
import '../../data/models/source_chunk.dart';
import '../ai/tasks/answer_evaluation_task.dart';
import '../ai/tasks/interview_question_task.dart';

class ProjectInterviewFlowService {
  const ProjectInterviewFlowService();

  List<KnowledgePoint> orderKnowledgePoints(
    List<KnowledgePoint> points, {
    String? focusedPointId,
  }) {
    final ordered = [...points]..sort(_comparePoints);
    final focusId = focusedPointId?.trim();
    if (focusId == null || focusId.isEmpty) return ordered;

    final focusIndex = ordered.indexWhere((point) => point.id == focusId);
    if (focusIndex <= 0) return ordered;
    final focusedPoint = ordered.removeAt(focusIndex);
    return [focusedPoint, ...ordered];
  }

  KnowledgePoint? nextUnaskedPoint({
    required List<KnowledgePoint> orderedPoints,
    required Set<String> askedPointIds,
  }) {
    for (final point in orderedPoints) {
      if (!askedPointIds.contains(point.id)) return point;
    }
    return null;
  }

  InterviewQuestionDraft? buildGroundedFollowUp({
    required InterviewQuestionDraft currentQuestion,
    required AnswerEvaluationResult evaluation,
    required List<KnowledgePoint> knowledgePoints,
    required List<SourceChunk> citedChunks,
    required Set<String> followedUpPointIds,
  }) {
    final question = evaluation.followUpQuestion.trim();
    final pointId = evaluation.followUpKnowledgePointId.trim();
    if (question.isEmpty ||
        pointId.isEmpty ||
        followedUpPointIds.contains(pointId) ||
        !currentQuestion.knowledgePointIds.contains(pointId)) {
      return null;
    }

    final knownPointIds = knowledgePoints.map((point) => point.id).toSet();
    if (!knownPointIds.contains(pointId)) return null;

    final currentCitationIds = currentQuestion.citationIds.toSet();
    final knownChunkIds = citedChunks.map((chunk) => chunk.id).toSet();
    final citationIds = evaluation.followUpCitationIds
        .where(currentCitationIds.contains)
        .where(knownChunkIds.contains)
        .toSet()
        .toList();
    if (citationIds.isEmpty) return null;

    return InterviewQuestionDraft(
      question: question,
      knowledgePointIds: [pointId],
      citationIds: citationIds,
      difficulty: (currentQuestion.difficulty + 1).clamp(1, 5).toInt(),
      isFollowUp: true,
    );
  }

  InterviewQuestionDraft? restorePendingFollowUp({
    required List<InterviewTurn> turns,
    required Set<String> availablePointIds,
    required Set<String> availableCitationIds,
  }) {
    if (turns.isEmpty) return null;
    final latestTurn = turns.last;
    final pointId = latestTurn.knowledgePointId;
    final question = latestTurn.nextInterviewQuestion.trim();
    if (pointId == null ||
        pointId.isEmpty ||
        question.isEmpty ||
        !availablePointIds.contains(pointId)) {
      return null;
    }
    final pointTurnCount =
        turns.where((turn) => turn.knowledgePointId == pointId).length;
    if (pointTurnCount != 1) return null;

    final citationIds = latestTurn.citationIds
        .where(availableCitationIds.contains)
        .toSet()
        .toList(growable: false);
    if (citationIds.isEmpty) return null;
    return InterviewQuestionDraft(
      question: question,
      knowledgePointIds: [pointId],
      citationIds: citationIds,
      difficulty: 2,
      isFollowUp: true,
    );
  }

  int _comparePoints(KnowledgePoint a, KnowledgePoint b) {
    final kind = _kindRank(a.kind).compareTo(_kindRank(b.kind));
    if (kind != 0) return kind;
    final relevance = b.interviewRelevance.compareTo(a.interviewRelevance);
    if (relevance != 0) return relevance;
    final mastery = a.masteryLevel.compareTo(b.masteryLevel);
    if (mastery != 0) return mastery;
    final difficulty = b.difficulty.compareTo(a.difficulty);
    if (difficulty != 0) return difficulty;
    return a.id.compareTo(b.id);
  }

  int _kindRank(KnowledgePointKind kind) {
    return switch (kind) {
      KnowledgePointKind.architecture => 0,
      KnowledgePointKind.dataFlow => 1,
      KnowledgePointKind.implementation => 2,
      KnowledgePointKind.boundary => 3,
      KnowledgePointKind.tradeOff => 4,
      KnowledgePointKind.concept => 5,
    };
  }
}
