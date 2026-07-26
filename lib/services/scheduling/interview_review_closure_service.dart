import '../../data/database/database_helper.dart';
import '../../data/models/grounded_claim.dart';
import '../../data/models/interview_turn.dart';
import '../../data/models/product_event.dart';
import '../../data/models/question.dart';
import '../../data/repositories/knowledge_point_repository.dart';
import '../../data/repositories/question_repository.dart';
import '../privacy/product_event_recorder.dart';

class InterviewReviewClosureService {
  final KnowledgePointRepository _knowledgePointRepository;
  final QuestionRepository _questionRepository;
  final DatabaseHelper _databaseHelper;
  final ProductEventRecorder? _eventRecorder;

  const InterviewReviewClosureService({
    required KnowledgePointRepository knowledgePointRepository,
    required QuestionRepository questionRepository,
    required DatabaseHelper databaseHelper,
    ProductEventRecorder? eventRecorder,
  })  : _knowledgePointRepository = knowledgePointRepository,
        _questionRepository = questionRepository,
        _databaseHelper = databaseHelper,
        _eventRecorder = eventRecorder;

  Future<InterviewTurn> closeAndPersistTurn({
    required InterviewTurn turn,
    DateTime? now,
  }) async {
    if (turn.groundingDisposition != GroundingDisposition.grounded) {
      final closedTurn = turn.copyWith(
        weakKnowledgePointIds: const [],
        weakDimensions: const [],
        reviewQuestionIds: const [],
        nextInterviewQuestion: '',
      );
      await _databaseHelper.insertInterviewTurnWithQuestionUpdates(
        turn: closedTurn,
        questions: const [],
      );
      await _recordEvents(closedTurn);
      return closedTurn;
    }
    final current = now ?? DateTime.now();
    final weakDimensions = _weakDimensions(turn);
    final weakPointIds = turn.weakKnowledgePointIds.toSet();
    final currentPointId = turn.knowledgePointId;
    if (weakDimensions.isNotEmpty && currentPointId != null) {
      weakPointIds.add(currentPointId);
    }

    final knownWeakPointIds = <String>[];
    for (final pointId in weakPointIds) {
      if (await _knowledgePointRepository.getKnowledgePoint(pointId) != null) {
        knownWeakPointIds.add(pointId);
      }
    }

    if (weakDimensions.isEmpty ||
        knownWeakPointIds.isEmpty ||
        turn.citationIds.isEmpty) {
      final closedTurn = turn.copyWith(
        weakKnowledgePointIds: knownWeakPointIds,
        weakDimensions: weakDimensions,
      );
      await _databaseHelper.insertInterviewTurnWithQuestionUpdates(
        turn: closedTurn,
        questions: const [],
      );
      await _recordEvents(closedTurn);
      return closedTurn;
    }

    final reviewQuestions =
        (await _questionRepository.getAllQuestions()).where((question) {
      final pointId = question.knowledgePointId;
      return pointId != null &&
          knownWeakPointIds.contains(pointId) &&
          question.sourceStatus == SourceStatus.verified &&
          question.citationIds.isNotEmpty;
    }).toList();

    final scheduledQuestions = <Question>[];
    for (final question in reviewQuestions) {
      final dueAt = question.nextReviewAt;
      if (dueAt == null || dueAt.isAfter(current)) {
        scheduledQuestions.add(question.copyWith(nextReviewAt: current));
      }
    }

    final closedTurn = turn.copyWith(
      weakKnowledgePointIds: knownWeakPointIds,
      weakDimensions: weakDimensions,
      reviewQuestionIds:
          reviewQuestions.map((question) => question.id).toList(),
      reviewDueAt: current,
      nextInterviewQuestion: _nextInterviewQuestion(turn, weakDimensions),
    );
    await _databaseHelper.insertInterviewTurnWithQuestionUpdates(
      turn: closedTurn,
      questions: scheduledQuestions,
    );
    await _recordEvents(closedTurn);
    return closedTurn;
  }

  Future<void> _recordEvents(InterviewTurn turn) async {
    final recorder = _eventRecorder;
    if (recorder == null) return;
    final session = await _databaseHelper.getLearningSession(turn.sessionId);
    final duration = session == null
        ? Duration.zero
        : turn.createdAt.difference(session.startedAt).abs();
    await recorder.recordBestEffort(
      ProductEventName.groundedTurnCompleted,
      flowId: 'learning_session_${turn.sessionId}',
      targetId: turn.knowledgePointId,
      sessionId: turn.sessionId,
      properties: {
        'surface': 'interview',
        'disposition': turn.groundingDisposition.value,
        'citation_count': turn.citationIds.length,
        'duration_bucket': ProductEventRecorder.durationBucket(duration),
      },
      dedupeKey: 'grounded_turn_completed:interview:${turn.id}',
    );
    if (turn.reviewDueAt != null && turn.reviewQuestionIds.isNotEmpty) {
      await recorder.recordBestEffort(
        ProductEventName.reviewScheduled,
        flowId: 'learning_session_${turn.sessionId}',
        targetId: turn.knowledgePointId,
        sessionId: turn.sessionId,
        properties: {
          'target_type': 'knowledge_point',
          'due_bucket': ProductEventRecorder.dueBucket(
            turn.reviewDueAt!,
            now: turn.createdAt,
          ),
        },
        dedupeKey: 'review_scheduled:interview:${turn.id}',
      );
    }
  }

  List<InterviewScoreDimension> _weakDimensions(InterviewTurn turn) {
    final scores = <InterviewScoreDimension, int>{
      InterviewScoreDimension.accuracy: turn.accuracyScore,
      InterviewScoreDimension.projectDetail: turn.projectDetailScore,
      InterviewScoreDimension.engineering: turn.engineeringScore,
      InterviewScoreDimension.clarity: turn.clarityScore,
    };
    final weak = scores.entries
        .where((entry) => entry.value <= 2)
        .map((entry) => entry.key)
        .toList();
    if (weak.isNotEmpty || turn.weakKnowledgePointIds.isEmpty) return weak;

    final minimum = scores.values.reduce((a, b) => a < b ? a : b);
    return scores.entries
        .where((entry) => entry.value == minimum)
        .map((entry) => entry.key)
        .toList();
  }

  String _nextInterviewQuestion(
    InterviewTurn turn,
    List<InterviewScoreDimension> weakDimensions,
  ) {
    final focus = weakDimensions.map((dimension) => dimension.label).join('、');
    return '请重新回答“${turn.questionText}”，重点补充$focus。';
  }
}
