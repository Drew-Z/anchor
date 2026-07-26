import 'package:dlg_q/data/database/database_helper.dart';
import 'package:dlg_q/data/models/deck.dart';
import 'package:dlg_q/data/models/grounded_claim.dart';
import 'package:dlg_q/data/models/knowledge_point.dart';
import 'package:dlg_q/data/models/knowledge_point_prerequisite.dart';
import 'package:dlg_q/data/models/knowledge_point_source.dart';
import 'package:dlg_q/data/models/learning_session.dart';
import 'package:dlg_q/data/models/programming_exercise.dart';
import 'package:dlg_q/data/models/programming_exercise_attempt.dart';
import 'package:dlg_q/data/models/programming_review_action.dart';
import 'package:dlg_q/data/models/question.dart';
import 'package:dlg_q/data/models/question_type.dart';
import 'package:dlg_q/data/models/source.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/data/models/tutor_turn.dart';
import 'package:dlg_q/data/repositories/knowledge_point_repository.dart';
import 'package:dlg_q/data/repositories/programming_exercise_repository.dart';
import 'package:dlg_q/data/repositories/programming_review_action_repository.dart';
import 'package:dlg_q/data/repositories/question_repository.dart';
import 'package:dlg_q/services/scheduling/programming_review_closure_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('low tutor accuracy creates a cited action with missing prerequisites',
      () async {
    final fixture = await _ProgrammingReviewFixture.create();
    addTearDown(fixture.databaseHelper.close);
    final now = DateTime(2026, 7, 15, 20);

    final action = await fixture.service.closeTutorTurn(
      turn: fixture.tutorTurn(
        id: 'tutor-turn-low',
        accuracyScore: 79,
      ),
      now: now,
    );

    expect(action, isNotNull);
    expect(action!.weakDimensions, [ProgrammingWeakDimension.conceptAccuracy]);
    expect(action.prerequisiteKnowledgePointIds, [fixture.prerequisite.id]);
    expect(action.citationIds, ['chunk-prerequisite', 'chunk-target']);
    expect(action.reviewQuestionIds, [
      'question-prerequisite-verified',
      'question-target-verified',
    ]);
    expect(action.reviewExerciseIds, [
      'exercise-prerequisite-retest',
      'exercise-target-retest',
    ]);
    expect(action.dueAt, now);

    final queue = await fixture.service.getOpenQueue();
    expect(queue, hasLength(1));
    expect(queue.single.knowledgePoint.id, fixture.target.id);
    expect(
      queue.single.prerequisiteKnowledgePoints.map((point) => point.id),
      [fixture.prerequisite.id],
    );
    expect(
      queue.single.questions.map((question) => question.id),
      action.reviewQuestionIds,
    );
    expect(
      queue.single.exercises.map((exercise) => exercise.id),
      action.reviewExerciseIds,
    );
    expect(
      await fixture.databaseHelper.getTutorTurns(fixture.session.id),
      hasLength(1),
    );
  });

  test('tutor evidence gates reject unsupported or non-weak turns', () async {
    final fixture = await _ProgrammingReviewFixture.create();
    addTearDown(fixture.databaseHelper.close);

    expect(
      await fixture.service.closeTutorTurn(
        turn: fixture.tutorTurn(
          id: 'tutor-turn-insufficient',
          accuracyScore: 20,
          evidenceSufficient: false,
        ),
      ),
      isNull,
    );
    expect(
      await fixture.service.closeTutorTurn(
        turn: fixture.tutorTurn(
          id: 'tutor-turn-partial',
          accuracyScore: 20,
          groundingDisposition: GroundingDisposition.partial,
        ),
      ),
      isNull,
    );
    expect(
      await fixture.service.closeTutorTurn(
        turn: fixture.tutorTurn(
          id: 'tutor-turn-uncited',
          accuracyScore: 20,
          citationIds: const [],
        ),
      ),
      isNull,
    );
    expect(
      await fixture.service.closeTutorTurn(
        turn: fixture.tutorTurn(
          id: 'tutor-turn-threshold',
          accuracyScore: 80,
        ),
      ),
      isNull,
    );
    expect(await fixture.actionRepository.getOpenActions(), isEmpty);
    expect(
      await fixture.databaseHelper.getTutorTurns(fixture.session.id),
      hasLength(4),
    );
  });

  test('exercise scores map to four dimensions and enforce evidence scope',
      () async {
    final fixture = await _ProgrammingReviewFixture.create();
    addTearDown(fixture.databaseHelper.close);
    final original = fixture.originalExercise;
    final attempt = fixture.attempt(
      id: 'attempt-low-dimensions',
      exercise: original,
      conceptAccuracyScore: 79,
      reasoningProcessScore: 80,
      evidenceUseScore: 35,
      clarityScore: 70,
    );
    await fixture.exerciseRepository.insertAttempt(attempt);

    final action = await fixture.service.closeExerciseAttempt(
      exercise: original,
      attempt: attempt,
      now: DateTime(2026, 7, 15, 20, 30),
    );

    expect(action, isNotNull);
    expect(action!.weakDimensions, [
      ProgrammingWeakDimension.conceptAccuracy,
      ProgrammingWeakDimension.evidenceUse,
      ProgrammingWeakDimension.clarity,
    ]);
    expect(action.reviewExerciseIds, isNot(contains(original.id)));
    expect(action.reviewExerciseIds, contains('exercise-target-retest'));

    final forgedAttempt = fixture.attempt(
      id: 'attempt-forged-citation',
      exercise: original,
      conceptAccuracyScore: 20,
      reasoningProcessScore: 20,
      evidenceUseScore: 20,
      clarityScore: 20,
      citationIds: const ['chunk-outside-exercise'],
    );
    await fixture.exerciseRepository.insertAttempt(forgedAttempt);
    expect(
      await fixture.service.closeExerciseAttempt(
        exercise: original,
        attempt: forgedAttempt,
      ),
      isNull,
    );

    final refusedAttempt = fixture.attempt(
      id: 'attempt-refused',
      exercise: original,
      conceptAccuracyScore: 20,
      reasoningProcessScore: 20,
      evidenceUseScore: 20,
      clarityScore: 20,
      groundingDisposition: GroundingDisposition.refused,
    );
    await fixture.exerciseRepository.insertAttempt(refusedAttempt);
    expect(
      await fixture.service.closeExerciseAttempt(
        exercise: original,
        attempt: refusedAttempt,
      ),
      isNull,
    );

    final insufficientAttempt = fixture.attempt(
      id: 'attempt-insufficient',
      exercise: original,
      conceptAccuracyScore: 20,
      reasoningProcessScore: 20,
      evidenceUseScore: 20,
      clarityScore: 20,
      evidenceSufficient: false,
    );
    await fixture.exerciseRepository.insertAttempt(insufficientAttempt);
    expect(
      await fixture.service.closeExerciseAttempt(
        exercise: original,
        attempt: insufficientAttempt,
      ),
      isNull,
    );

    final pendingAttempt = fixture.attempt(
      id: 'attempt-pending-exercise',
      exercise: fixture.pendingRetest,
      conceptAccuracyScore: 20,
      reasoningProcessScore: 20,
      evidenceUseScore: 20,
      clarityScore: 20,
    );
    await fixture.exerciseRepository.insertAttempt(pendingAttempt);
    expect(
      await fixture.service.closeExerciseAttempt(
        exercise: fixture.pendingRetest,
        attempt: pendingAttempt,
      ),
      isNull,
    );
  });

  test(
      'verified retest completion closes the old action and can open a new one',
      () async {
    final fixture = await _ProgrammingReviewFixture.create();
    addTearDown(fixture.databaseHelper.close);
    final now = DateTime(2026, 7, 15, 21);
    final retest = fixture.targetRetest;
    final firstAction = fixture.reviewAction(
      id: 'review-action-first',
      triggerId: 'tutor-trigger-first',
      reviewExerciseIds: [retest.id],
      now: now,
    );
    await fixture.actionRepository.upsertAction(firstAction);
    final refusedRetestAttempt = fixture.attempt(
      id: 'attempt-retest-refused',
      exercise: retest,
      conceptAccuracyScore: 0,
      reasoningProcessScore: 0,
      evidenceUseScore: 0,
      clarityScore: 0,
      groundingDisposition: GroundingDisposition.refused,
    );
    await fixture.exerciseRepository.insertAttempt(refusedRetestAttempt);
    expect(
      await fixture.service.closeExerciseAttempt(
        exercise: retest,
        attempt: refusedRetestAttempt,
        now: now.add(const Duration(minutes: 1)),
      ),
      isNull,
    );
    expect(
      (await fixture.actionRepository.getAction(firstAction.id))?.isCompleted,
      isFalse,
    );
    final strongAttempt = fixture.attempt(
      id: 'attempt-retest-strong',
      exercise: retest,
      conceptAccuracyScore: 90,
      reasoningProcessScore: 90,
      evidenceUseScore: 90,
      clarityScore: 90,
    );
    await fixture.exerciseRepository.insertAttempt(strongAttempt);

    expect(
      await fixture.service.closeExerciseAttempt(
        exercise: retest,
        attempt: strongAttempt,
        now: now.add(const Duration(minutes: 5)),
      ),
      isNull,
    );
    expect(
      (await fixture.actionRepository.getAction(firstAction.id))?.isCompleted,
      isTrue,
    );
    expect(await fixture.actionRepository.getOpenActions(), isEmpty);

    final secondAction = fixture.reviewAction(
      id: 'review-action-second',
      triggerId: 'tutor-trigger-second',
      reviewExerciseIds: [retest.id],
      now: now.add(const Duration(minutes: 10)),
    );
    await fixture.actionRepository.upsertAction(secondAction);
    final weakAttempt = fixture.attempt(
      id: 'attempt-retest-weak',
      exercise: retest,
      conceptAccuracyScore: 55,
      reasoningProcessScore: 60,
      evidenceUseScore: 65,
      clarityScore: 85,
    );
    await fixture.exerciseRepository.insertAttempt(weakAttempt);

    final nextAction = await fixture.service.closeExerciseAttempt(
      exercise: retest,
      attempt: weakAttempt,
      now: now.add(const Duration(minutes: 15)),
    );

    expect(
      (await fixture.actionRepository.getAction(secondAction.id))?.isCompleted,
      isTrue,
    );
    expect(nextAction, isNotNull);
    expect(nextAction!.triggerId, weakAttempt.id);
    expect(nextAction.reviewExerciseIds, isNot(contains(retest.id)));
    expect(nextAction.weakDimensions, [
      ProgrammingWeakDimension.conceptAccuracy,
      ProgrammingWeakDimension.reasoningProcess,
      ProgrammingWeakDimension.evidenceUse,
    ]);
    expect(
      (await fixture.actionRepository.getOpenActions()).single.id,
      nextAction.id,
    );
  });

  test('tutor turn and review action roll back together on persistence failure',
      () async {
    final fixture = await _ProgrammingReviewFixture.create();
    addTearDown(fixture.databaseHelper.close);
    final turn = fixture.tutorTurn(
      id: 'tutor-turn-missing-session',
      sessionId: 'missing-session',
      accuracyScore: 20,
    );

    await expectLater(
      fixture.service.closeTutorTurn(turn: turn),
      throwsA(anything),
    );
    expect(
      await fixture.actionRepository.getAction(
        'programming-review-tutor_turn-${turn.id}',
      ),
      isNull,
    );
    expect(
      await fixture.databaseHelper.getTutorTurns(fixture.session.id),
      isEmpty,
    );
  });
}

class _ProgrammingReviewFixture {
  final DatabaseHelper databaseHelper;
  final KnowledgePointRepository knowledgePointRepository;
  final QuestionRepository questionRepository;
  final ProgrammingExerciseRepository exerciseRepository;
  final ProgrammingReviewActionRepository actionRepository;
  final ProgrammingReviewClosureService service;
  final KnowledgePoint target;
  final KnowledgePoint prerequisite;
  final LearningSession session;
  final ProgrammingExercise originalExercise;
  final ProgrammingExercise targetRetest;
  final ProgrammingExercise pendingRetest;

  const _ProgrammingReviewFixture({
    required this.databaseHelper,
    required this.knowledgePointRepository,
    required this.questionRepository,
    required this.exerciseRepository,
    required this.actionRepository,
    required this.service,
    required this.target,
    required this.prerequisite,
    required this.session,
    required this.originalExercise,
    required this.targetRetest,
    required this.pendingRetest,
  });

  static Future<_ProgrammingReviewFixture> create() async {
    final databaseHelper = DatabaseHelper.forTesting(
      databaseFactory: databaseFactoryFfi,
    );
    final knowledgePointRepository = KnowledgePointRepository(databaseHelper);
    final questionRepository = QuestionRepository(databaseHelper);
    final exerciseRepository = ProgrammingExerciseRepository(databaseHelper);
    final actionRepository = ProgrammingReviewActionRepository(databaseHelper);
    final now = DateTime(2026, 7, 15, 19, 30);
    final target = _point('target', 'Return path', 45, now);
    final prerequisite = _point('prerequisite', 'State ownership', 30, now);
    final uncitedPrerequisite =
        _point('uncited-prerequisite', 'Uncited prerequisite', 20, now);
    final unsourcedPrerequisite =
        _point('unsourced-prerequisite', 'Unsourced prerequisite', 20, now);
    final masteredPrerequisite =
        _point('mastered-prerequisite', 'Mastered prerequisite', 90, now);

    await databaseHelper.insertSource(
      Source(
        id: 'source-programming',
        title: 'Official programming reference',
        type: SourceType.officialDoc,
        uri: 'https://example.com/reference',
        revision: '2026-07-15',
        publisher: 'Example Foundation',
        licenseExpression: 'CC-BY-4.0',
        retrievedAt: now,
        contentHash: 'source-hash',
        trustLevel: SourceTrustLevel.officialDoc,
        createdAt: now,
        updatedAt: now,
      ),
    );
    for (final chunk in [
      _chunk('chunk-target', 0, 'The function returns persistedValue.', now),
      _chunk(
        'chunk-prerequisite',
        1,
        'State ownership determines where persistedValue lives.',
        now,
      ),
      _chunk(
        'chunk-uncited-prerequisite',
        2,
        'This prerequisite has a source but no cited edge.',
        now,
      ),
      _chunk(
        'chunk-mastered-prerequisite',
        3,
        'This prerequisite is already mastered.',
        now,
      ),
    ]) {
      await databaseHelper.insertSourceChunk(chunk);
    }
    for (final point in [
      target,
      prerequisite,
      uncitedPrerequisite,
      unsourcedPrerequisite,
      masteredPrerequisite,
    ]) {
      await knowledgePointRepository.insertKnowledgePoint(point);
    }
    for (final relation in [
      KnowledgePointSource(
        knowledgePointId: target.id,
        sourceChunkId: 'chunk-target',
      ),
      KnowledgePointSource(
        knowledgePointId: prerequisite.id,
        sourceChunkId: 'chunk-prerequisite',
      ),
      KnowledgePointSource(
        knowledgePointId: uncitedPrerequisite.id,
        sourceChunkId: 'chunk-uncited-prerequisite',
      ),
      KnowledgePointSource(
        knowledgePointId: masteredPrerequisite.id,
        sourceChunkId: 'chunk-mastered-prerequisite',
      ),
    ]) {
      await knowledgePointRepository.addKnowledgePointSource(relation);
    }
    await knowledgePointRepository.replaceKnowledgePointPrerequisites(
      scopeKnowledgePointIds: [
        target.id,
        prerequisite.id,
        uncitedPrerequisite.id,
        unsourcedPrerequisite.id,
        masteredPrerequisite.id,
      ],
      relations: [
        KnowledgePointPrerequisite(
          knowledgePointId: target.id,
          prerequisiteKnowledgePointId: prerequisite.id,
          rationale: 'State ownership is needed before tracing the return.',
          citationIds: const ['chunk-prerequisite'],
          createdAt: now,
        ),
        KnowledgePointPrerequisite(
          knowledgePointId: target.id,
          prerequisiteKnowledgePointId: uncitedPrerequisite.id,
          rationale: 'This edge has no evidence and must be ignored.',
          createdAt: now.add(const Duration(microseconds: 1)),
        ),
        KnowledgePointPrerequisite(
          knowledgePointId: target.id,
          prerequisiteKnowledgePointId: unsourcedPrerequisite.id,
          rationale: 'This point has no attached source and must be ignored.',
          citationIds: const ['chunk-prerequisite'],
          createdAt: now.add(const Duration(microseconds: 2)),
        ),
        KnowledgePointPrerequisite(
          knowledgePointId: target.id,
          prerequisiteKnowledgePointId: masteredPrerequisite.id,
          rationale: 'This point is already mastered and must be ignored.',
          citationIds: const ['chunk-mastered-prerequisite'],
          createdAt: now.add(const Duration(microseconds: 3)),
        ),
      ],
    );

    await databaseHelper.insertDeck(
      Deck(
        id: 'programming-review-deck',
        title: 'Programming review',
        createdAt: now,
        updatedAt: now,
      ),
    );
    for (final question in [
      _question(
        'question-target-verified',
        target.id,
        SourceStatus.verified,
        const ['chunk-target'],
      ),
      _question(
        'question-prerequisite-verified',
        prerequisite.id,
        SourceStatus.verified,
        const ['chunk-prerequisite'],
      ),
      _question(
        'question-target-pending',
        target.id,
        SourceStatus.pending,
        const ['chunk-target'],
      ),
      _question(
        'question-target-uncited',
        target.id,
        SourceStatus.verified,
        const [],
      ),
    ]) {
      await questionRepository.insertQuestion(question);
    }

    final originalExercise = _exercise(
      'exercise-original',
      target.id,
      now,
      sourceStatus: SourceStatus.verified,
      citationIds: const ['chunk-target'],
    );
    final targetRetest = _exercise(
      'exercise-target-retest',
      target.id,
      now.add(const Duration(minutes: 1)),
      sourceStatus: SourceStatus.verified,
      citationIds: const ['chunk-target'],
      isRetest: true,
    );
    final prerequisiteRetest = _exercise(
      'exercise-prerequisite-retest',
      prerequisite.id,
      now.add(const Duration(minutes: 2)),
      sourceStatus: SourceStatus.verified,
      citationIds: const ['chunk-prerequisite'],
      isRetest: true,
    );
    final pendingRetest = _exercise(
      'exercise-target-pending-retest',
      target.id,
      now.add(const Duration(minutes: 3)),
      sourceStatus: SourceStatus.pending,
      citationIds: const ['chunk-target'],
      isRetest: true,
    );
    final uncitedRetest = _exercise(
      'exercise-target-uncited-retest',
      target.id,
      now.add(const Duration(minutes: 4)),
      sourceStatus: SourceStatus.verified,
      isRetest: true,
    );
    for (final exercise in [
      originalExercise,
      targetRetest,
      prerequisiteRetest,
      pendingRetest,
      uncitedRetest,
    ]) {
      await exerciseRepository.insertExercise(exercise);
    }

    final session = LearningSession(
      id: 'programming-tutor-session',
      mode: LearningSessionMode.tutor,
      targetId: target.id,
      startedAt: now,
    );
    await databaseHelper.insertLearningSession(session);

    return _ProgrammingReviewFixture(
      databaseHelper: databaseHelper,
      knowledgePointRepository: knowledgePointRepository,
      questionRepository: questionRepository,
      exerciseRepository: exerciseRepository,
      actionRepository: actionRepository,
      service: ProgrammingReviewClosureService(
        knowledgePointRepository: knowledgePointRepository,
        questionRepository: questionRepository,
        exerciseRepository: exerciseRepository,
        actionRepository: actionRepository,
        databaseHelper: databaseHelper,
      ),
      target: target,
      prerequisite: prerequisite,
      session: session,
      originalExercise: originalExercise,
      targetRetest: targetRetest,
      pendingRetest: pendingRetest,
    );
  }

  TutorTurn tutorTurn({
    required String id,
    String? sessionId,
    required int accuracyScore,
    bool evidenceSufficient = true,
    List<String> citationIds = const ['chunk-target'],
    GroundingDisposition groundingDisposition = GroundingDisposition.grounded,
  }) {
    return TutorTurn(
      id: id,
      sessionId: sessionId ?? session.id,
      knowledgePointId: target.id,
      questionText: 'What value reaches the return boundary?',
      userAnswer: 'A temporary value.',
      aiFeedback: 'Trace the cited persisted value.',
      referenceAnswer: 'The function returns persistedValue.',
      misconception: 'The answer confused a temporary and persisted value.',
      nextQuestion: 'Where is persistedValue owned?',
      citationIds: citationIds,
      prerequisiteKnowledgePointIds: [prerequisite.id],
      evidenceSufficient: evidenceSufficient,
      accuracyScore: accuracyScore,
      groundingDisposition: groundingDisposition,
      createdAt: DateTime(2026, 7, 15, 20),
    );
  }

  ProgrammingExerciseAttempt attempt({
    required String id,
    required ProgrammingExercise exercise,
    required int conceptAccuracyScore,
    required int reasoningProcessScore,
    required int evidenceUseScore,
    required int clarityScore,
    List<String>? citationIds,
    bool evidenceSufficient = true,
    GroundingDisposition groundingDisposition = GroundingDisposition.grounded,
  }) {
    return ProgrammingExerciseAttempt(
      id: id,
      exerciseId: exercise.id,
      knowledgePointId: exercise.knowledgePointId,
      userAnswer: 'The answer under test.',
      feedback: 'Use the cited return path.',
      conceptAccuracyScore: conceptAccuracyScore,
      reasoningProcessScore: reasoningProcessScore,
      evidenceUseScore: evidenceUseScore,
      clarityScore: clarityScore,
      misconceptionCode: 'return_path_confusion',
      misconceptionLabel: 'Return path confusion',
      repairExplanation: 'Trace the final return statement.',
      citationIds: citationIds ?? exercise.citationIds,
      evidenceSufficient: evidenceSufficient,
      groundingDisposition: groundingDisposition,
      createdAt: DateTime(2026, 7, 15, 20, 30),
    );
  }

  ProgrammingReviewAction reviewAction({
    required String id,
    required String triggerId,
    required List<String> reviewExerciseIds,
    required DateTime now,
  }) {
    return ProgrammingReviewAction(
      id: id,
      knowledgePointId: target.id,
      triggerType: ProgrammingReviewTriggerType.tutorTurn,
      triggerId: triggerId,
      weakDimensions: const [ProgrammingWeakDimension.conceptAccuracy],
      citationIds: const ['chunk-target'],
      reviewExerciseIds: reviewExerciseIds,
      dueAt: now,
      createdAt: now,
    );
  }
}

KnowledgePoint _point(
  String id,
  String title,
  int masteryLevel,
  DateTime now,
) {
  return KnowledgePoint(
    id: id,
    title: title,
    summary: '$title summary',
    kind: KnowledgePointKind.concept,
    masteryLevel: masteryLevel,
    createdAt: now,
    updatedAt: now,
  );
}

SourceChunk _chunk(String id, int index, String content, DateTime now) {
  return SourceChunk(
    id: id,
    sourceId: 'source-programming',
    chunkIndex: index,
    content: content,
    locator: 'reference:L${index + 1}-L${index + 1}',
    contentHash: 'hash-$id',
    createdAt: now,
  );
}

Question _question(
  String id,
  String knowledgePointId,
  SourceStatus sourceStatus,
  List<String> citationIds,
) {
  return Question(
    id: id,
    deckId: 'programming-review-deck',
    knowledgePointId: knowledgePointId,
    type: QuestionType.fillBlank,
    content: 'Review $id',
    answer: 'Verified answer',
    sourceStatus: sourceStatus,
    citationIds: citationIds,
  );
}

ProgrammingExercise _exercise(
  String id,
  String knowledgePointId,
  DateTime now, {
  required SourceStatus sourceStatus,
  List<String> citationIds = const [],
  bool isRetest = false,
}) {
  return ProgrammingExercise(
    id: id,
    knowledgePointId: knowledgePointId,
    kind: ProgrammingExerciseKind.codeReading,
    prompt: 'Trace the return path for $id.',
    referenceAnswer: 'The final statement returns persistedValue.',
    conceptAccuracyCriterion: 'Identify persistedValue.',
    reasoningProcessCriterion: 'Trace the final return statement.',
    evidenceUseCriterion: 'Use the cited line.',
    clarityCriterion: 'State the value directly.',
    sourceStatus: sourceStatus,
    citationIds: citationIds,
    isRetest: isRetest,
    createdAt: now,
    updatedAt: now,
  );
}
