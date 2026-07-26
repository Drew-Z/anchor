import '../../data/database/database_helper.dart';
import '../../data/models/grounded_claim.dart';
import '../../data/models/knowledge_point.dart';
import '../../data/models/programming_exercise.dart';
import '../../data/models/programming_exercise_attempt.dart';
import '../../data/models/programming_review_action.dart';
import '../../data/models/product_event.dart';
import '../../data/models/question.dart';
import '../../data/models/tutor_turn.dart';
import '../../data/repositories/knowledge_point_repository.dart';
import '../../data/repositories/programming_exercise_repository.dart';
import '../../data/repositories/programming_review_action_repository.dart';
import '../../data/repositories/question_repository.dart';
import '../privacy/product_event_recorder.dart';

class ProgrammingReviewQueueItem {
  final ProgrammingReviewAction action;
  final KnowledgePoint knowledgePoint;
  final List<KnowledgePoint> prerequisiteKnowledgePoints;
  final List<Question> questions;
  final List<ProgrammingExercise> exercises;

  const ProgrammingReviewQueueItem({
    required this.action,
    required this.knowledgePoint,
    this.prerequisiteKnowledgePoints = const [],
    this.questions = const [],
    this.exercises = const [],
  });

  bool get isActionable => questions.isNotEmpty || exercises.isNotEmpty;
}

class ProgrammingReviewClosureService {
  static const int weakScoreThreshold = 80;
  static const int prerequisiteMasteryThreshold = 70;

  final KnowledgePointRepository _knowledgePointRepository;
  final QuestionRepository _questionRepository;
  final ProgrammingExerciseRepository _exerciseRepository;
  final ProgrammingReviewActionRepository _actionRepository;
  final DatabaseHelper _databaseHelper;
  final ProductEventRecorder? _eventRecorder;

  const ProgrammingReviewClosureService({
    required KnowledgePointRepository knowledgePointRepository,
    required QuestionRepository questionRepository,
    required ProgrammingExerciseRepository exerciseRepository,
    required ProgrammingReviewActionRepository actionRepository,
    required DatabaseHelper databaseHelper,
    ProductEventRecorder? eventRecorder,
  })  : _knowledgePointRepository = knowledgePointRepository,
        _questionRepository = questionRepository,
        _exerciseRepository = exerciseRepository,
        _actionRepository = actionRepository,
        _databaseHelper = databaseHelper,
        _eventRecorder = eventRecorder;

  Future<ProgrammingReviewAction?> closeTutorTurn({
    required TutorTurn turn,
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();
    final action = await _actionForTutorTurn(turn, current);
    await _databaseHelper.insertTutorTurnWithProgrammingReviewAction(
      turn: turn,
      action: action,
    );
    await _recordTutorTurn(turn, action);
    return action;
  }

  Future<void> _recordTutorTurn(
    TutorTurn turn,
    ProgrammingReviewAction? action,
  ) async {
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
        'surface': 'tutor',
        'disposition': turn.groundingDisposition.value,
        'citation_count': turn.citationIds.length,
        'duration_bucket': ProductEventRecorder.durationBucket(duration),
      },
      dedupeKey: 'grounded_turn_completed:tutor:${turn.id}',
    );
    if (action != null) {
      await recorder.recordBestEffort(
        ProductEventName.reviewScheduled,
        flowId: 'learning_session_${turn.sessionId}',
        targetId: action.knowledgePointId,
        sessionId: turn.sessionId,
        properties: {
          'target_type': 'knowledge_point',
          'due_bucket': ProductEventRecorder.dueBucket(
            action.dueAt,
            now: action.createdAt,
          ),
        },
        dedupeKey:
            'review_scheduled:${action.triggerType.value}:${action.triggerId}',
      );
    }
  }

  Future<ProgrammingReviewAction?> closeExerciseAttempt({
    required ProgrammingExercise exercise,
    required ProgrammingExerciseAttempt attempt,
    DateTime? now,
  }) async {
    if (attempt.groundingDisposition != GroundingDisposition.grounded) {
      return null;
    }
    final current = now ?? DateTime.now();
    await _completeActionsForExercise(exercise.id, current);
    final action = await _actionForExerciseAttempt(
      exercise,
      attempt,
      current,
    );
    if (action != null) await _actionRepository.upsertAction(action);
    return action;
  }

  Future<List<ProgrammingReviewQueueItem>> getOpenQueue() async {
    final actions = await _actionRepository.getOpenActions();
    final items = <ProgrammingReviewQueueItem>[];
    for (final original in actions) {
      final action = await _refreshMaterials(original);
      final point = await _knowledgePointRepository.getKnowledgePoint(
        action.knowledgePointId,
      );
      if (point == null) continue;

      final prerequisites = <KnowledgePoint>[];
      for (final id in action.prerequisiteKnowledgePointIds) {
        final prerequisite =
            await _knowledgePointRepository.getKnowledgePoint(id);
        if (prerequisite != null) prerequisites.add(prerequisite);
      }
      final questionsById = {
        for (final question in await _questionRepository.getAllQuestions())
          question.id: question,
      };
      final exercisesById = {
        for (final exercise in await _exerciseRepository.getAllExercises())
          exercise.id: exercise,
      };
      items.add(
        ProgrammingReviewQueueItem(
          action: action,
          knowledgePoint: point,
          prerequisiteKnowledgePoints: prerequisites,
          questions: action.reviewQuestionIds
              .map((id) => questionsById[id])
              .whereType<Question>()
              .toList(),
          exercises: action.reviewExerciseIds
              .map((id) => exercisesById[id])
              .whereType<ProgrammingExercise>()
              .toList(),
        ),
      );
    }
    items.sort((a, b) {
      final due = a.action.dueAt.compareTo(b.action.dueAt);
      if (due != 0) return due;
      final mastery = a.knowledgePoint.masteryLevel
          .compareTo(b.knowledgePoint.masteryLevel);
      if (mastery != 0) return mastery;
      return a.knowledgePoint.title.compareTo(b.knowledgePoint.title);
    });
    return items;
  }

  Future<ProgrammingReviewAction?> _actionForTutorTurn(
    TutorTurn turn,
    DateTime now,
  ) async {
    if (!turn.evidenceSufficient ||
        turn.groundingDisposition != GroundingDisposition.grounded ||
        turn.citationIds.isEmpty ||
        turn.accuracyScore >= weakScoreThreshold) {
      return null;
    }
    return _buildAction(
      knowledgePointId: turn.knowledgePointId,
      triggerType: ProgrammingReviewTriggerType.tutorTurn,
      triggerId: turn.id,
      weakDimensions: const [ProgrammingWeakDimension.conceptAccuracy],
      citationIds: turn.citationIds,
      now: now,
    );
  }

  Future<ProgrammingReviewAction?> _actionForExerciseAttempt(
    ProgrammingExercise exercise,
    ProgrammingExerciseAttempt attempt,
    DateTime now,
  ) async {
    if (exercise.sourceStatus != SourceStatus.verified ||
        attempt.groundingDisposition != GroundingDisposition.grounded ||
        exercise.citationIds.isEmpty ||
        !attempt.evidenceSufficient ||
        attempt.citationIds.isEmpty ||
        !exercise.citationIds.toSet().containsAll(attempt.citationIds) ||
        exercise.id != attempt.exerciseId ||
        exercise.knowledgePointId != attempt.knowledgePointId) {
      return null;
    }
    final weakDimensions = <ProgrammingWeakDimension>[
      if (attempt.conceptAccuracyScore < weakScoreThreshold)
        ProgrammingWeakDimension.conceptAccuracy,
      if (attempt.reasoningProcessScore < weakScoreThreshold)
        ProgrammingWeakDimension.reasoningProcess,
      if (attempt.evidenceUseScore < weakScoreThreshold)
        ProgrammingWeakDimension.evidenceUse,
      if (attempt.clarityScore < weakScoreThreshold)
        ProgrammingWeakDimension.clarity,
    ];
    if (weakDimensions.isEmpty) return null;
    return _buildAction(
      knowledgePointId: exercise.knowledgePointId,
      triggerType: ProgrammingReviewTriggerType.exerciseAttempt,
      triggerId: attempt.id,
      weakDimensions: weakDimensions,
      citationIds: attempt.citationIds,
      excludeExerciseId: exercise.id,
      now: now,
    );
  }

  Future<ProgrammingReviewAction?> _buildAction({
    required String knowledgePointId,
    required ProgrammingReviewTriggerType triggerType,
    required String triggerId,
    required List<ProgrammingWeakDimension> weakDimensions,
    required List<String> citationIds,
    String? excludeExerciseId,
    required DateTime now,
  }) async {
    final point =
        await _knowledgePointRepository.getKnowledgePoint(knowledgePointId);
    if (point == null || citationIds.isEmpty || weakDimensions.isEmpty) {
      return null;
    }
    final prerequisiteResult = await _missingPrerequisites(knowledgePointId);
    final affectedIds = <String>{
      knowledgePointId,
      ...prerequisiteResult.pointIds,
    };
    final materials = await _eligibleMaterials(
      affectedIds,
      excludeExerciseId: excludeExerciseId,
    );
    final allCitations = <String>{
      ...citationIds,
      ...prerequisiteResult.citationIds,
    }.toList()
      ..sort();
    final id = 'programming-review-${triggerType.value}-$triggerId';
    return ProgrammingReviewAction(
      id: id,
      knowledgePointId: knowledgePointId,
      triggerType: triggerType,
      triggerId: triggerId,
      weakDimensions: weakDimensions,
      prerequisiteKnowledgePointIds: prerequisiteResult.pointIds,
      citationIds: allCitations,
      reviewQuestionIds: materials.questionIds,
      reviewExerciseIds: materials.exerciseIds,
      dueAt: now,
      createdAt: now,
    );
  }

  Future<ProgrammingReviewAction> _refreshMaterials(
    ProgrammingReviewAction action,
  ) async {
    final affectedIds = <String>{
      action.knowledgePointId,
      ...action.prerequisiteKnowledgePointIds,
    };
    String? excludeExerciseId;
    if (action.triggerType == ProgrammingReviewTriggerType.exerciseAttempt) {
      final attempt = await _exerciseRepository.getAttempt(action.triggerId);
      excludeExerciseId = attempt?.exerciseId;
    }
    final materials = await _eligibleMaterials(
      affectedIds,
      excludeExerciseId: excludeExerciseId,
    );
    if (_sameIds(action.reviewQuestionIds, materials.questionIds) &&
        _sameIds(action.reviewExerciseIds, materials.exerciseIds)) {
      return action;
    }
    final updated = action.copyWith(
      reviewQuestionIds: materials.questionIds,
      reviewExerciseIds: materials.exerciseIds,
    );
    await _actionRepository.updateAction(updated);
    return updated;
  }

  Future<_MissingPrerequisites> _missingPrerequisites(
    String knowledgePointId,
  ) async {
    final relations =
        await _knowledgePointRepository.getKnowledgePointPrerequisites();
    final ids = <String>[];
    final citations = <String>{};
    for (final relation in relations) {
      if (relation.knowledgePointId != knowledgePointId ||
          relation.citationIds.isEmpty) {
        continue;
      }
      final point = await _knowledgePointRepository.getKnowledgePoint(
        relation.prerequisiteKnowledgePointId,
      );
      if (point == null ||
          point.kind != KnowledgePointKind.concept ||
          point.masteryLevel >= prerequisiteMasteryThreshold) {
        continue;
      }
      final sources =
          await _knowledgePointRepository.getKnowledgePointSources(point.id);
      if (sources.isEmpty) continue;
      ids.add(point.id);
      citations.addAll(relation.citationIds);
    }
    ids.sort();
    return _MissingPrerequisites(ids, citations.toList()..sort());
  }

  Future<_ReviewMaterials> _eligibleMaterials(
    Set<String> knowledgePointIds, {
    String? excludeExerciseId,
  }) async {
    final questions = (await _questionRepository.getAllQuestions())
        .where((question) =>
            knowledgePointIds.contains(question.knowledgePointId) &&
            question.sourceStatus == SourceStatus.verified &&
            question.citationIds.isNotEmpty)
        .map((question) => question.id)
        .toSet()
        .toList()
      ..sort();
    final exercises = (await _exerciseRepository.getAllExercises())
        .where((exercise) =>
            exercise.id != excludeExerciseId &&
            knowledgePointIds.contains(exercise.knowledgePointId) &&
            exercise.isRetest &&
            exercise.sourceStatus == SourceStatus.verified &&
            exercise.citationIds.isNotEmpty)
        .map((exercise) => exercise.id)
        .toSet()
        .toList()
      ..sort();
    return _ReviewMaterials(questions, exercises);
  }

  Future<void> _completeActionsForExercise(
    String exerciseId,
    DateTime completedAt,
  ) async {
    final actions = await _actionRepository.getOpenActions();
    for (final action in actions) {
      if (!action.reviewExerciseIds.contains(exerciseId)) continue;
      await _actionRepository.updateAction(
        action.copyWith(completedAt: completedAt),
      );
    }
  }

  bool _sameIds(List<String> left, List<String> right) {
    return left.length == right.length && left.toSet().containsAll(right);
  }
}

class _MissingPrerequisites {
  final List<String> pointIds;
  final List<String> citationIds;

  const _MissingPrerequisites(this.pointIds, this.citationIds);
}

class _ReviewMaterials {
  final List<String> questionIds;
  final List<String> exerciseIds;

  const _ReviewMaterials(this.questionIds, this.exerciseIds);
}
