import 'package:anchor_learning/data/database/database_helper.dart';
import 'package:anchor_learning/data/models/deck.dart';
import 'package:anchor_learning/data/models/grounded_claim.dart';
import 'package:anchor_learning/data/models/interview_turn.dart';
import 'package:anchor_learning/data/models/knowledge_point.dart';
import 'package:anchor_learning/data/models/learning_session.dart';
import 'package:anchor_learning/data/models/question.dart';
import 'package:anchor_learning/data/models/question_type.dart';
import 'package:anchor_learning/data/repositories/knowledge_point_repository.dart';
import 'package:anchor_learning/data/repositories/learning_session_repository.dart';
import 'package:anchor_learning/data/repositories/question_repository.dart';
import 'package:anchor_learning/services/scheduling/interview_review_closure_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('low interview dimensions create a cited review action and due question',
      () async {
    final fixture = await _ClosureFixture.create();
    addTearDown(fixture.databaseHelper.close);
    final now = DateTime(2026, 7, 15, 12);

    final closedTurn = await fixture.service.closeAndPersistTurn(
      turn: fixture.turn(
        accuracyScore: 2,
        projectDetailScore: 1,
        engineeringScore: 4,
        clarityScore: 4,
        weakKnowledgePointIds: [fixture.point.id],
      ),
      now: now,
    );

    expect(closedTurn.hasReviewAction, isTrue);
    expect(closedTurn.weakDimensions, [
      InterviewScoreDimension.accuracy,
      InterviewScoreDimension.projectDetail,
    ]);
    expect(closedTurn.reviewQuestionIds, [fixture.question.id]);
    expect(closedTurn.reviewDueAt, now);
    expect(closedTurn.nextInterviewQuestion, contains('事实准确、项目细节'));
    final scheduledQuestion =
        (await fixture.questionRepository.getAllQuestions())
            .singleWhere((question) => question.id == fixture.question.id);
    expect(scheduledQuestion.nextReviewAt, now);

    final persisted = (await fixture.learningSessionRepository
            .getInterviewTurns(fixture.session.id))
        .single;
    expect(persisted.weakDimensions, closedTurn.weakDimensions);
    expect(persisted.reviewQuestionIds, [fixture.question.id]);
    expect(persisted.nextInterviewQuestion, closedTurn.nextInterviewQuestion);
  });

  test('a strong turn does not create or reschedule a review action', () async {
    final fixture = await _ClosureFixture.create();
    addTearDown(fixture.databaseHelper.close);
    final originalDueAt = fixture.question.nextReviewAt;

    final closedTurn = await fixture.service.closeAndPersistTurn(
      turn: fixture.turn(
        accuracyScore: 4,
        projectDetailScore: 4,
        engineeringScore: 5,
        clarityScore: 4,
      ),
      now: DateTime(2026, 7, 15, 12),
    );

    expect(closedTurn.hasReviewAction, isFalse);
    expect(closedTurn.weakDimensions, isEmpty);
    expect(closedTurn.reviewQuestionIds, isEmpty);
    final unchangedQuestion =
        (await fixture.questionRepository.getAllQuestions())
            .singleWhere((question) => question.id == fixture.question.id);
    expect(unchangedQuestion.nextReviewAt, originalDueAt);
  });

  test('partial and refused turns persist without creating review actions',
      () async {
    for (final disposition in [
      GroundingDisposition.partial,
      GroundingDisposition.refused,
    ]) {
      final fixture = await _ClosureFixture.create();
      final originalDueAt = fixture.question.nextReviewAt;

      final closedTurn = await fixture.service.closeAndPersistTurn(
        turn: fixture.turn(
          accuracyScore: 1,
          projectDetailScore: 1,
          engineeringScore: 1,
          clarityScore: 1,
          weakKnowledgePointIds: [fixture.point.id],
          groundingDisposition: disposition,
        ),
        now: DateTime(2026, 7, 15, 12),
      );

      expect(closedTurn.hasReviewAction, isFalse);
      expect(closedTurn.weakKnowledgePointIds, isEmpty);
      expect(closedTurn.reviewQuestionIds, isEmpty);
      expect(
        (await fixture.questionRepository.getAllQuestions())
            .single
            .nextReviewAt,
        originalDueAt,
      );
      expect(
        (await fixture.learningSessionRepository
                .getInterviewTurns(fixture.session.id))
            .single
            .groundingDisposition,
        disposition,
      );
      await fixture.databaseHelper.close();
    }
  });

  test('turn persistence failure rolls back review scheduling', () async {
    final fixture = await _ClosureFixture.create();
    addTearDown(fixture.databaseHelper.close);
    final originalDueAt = fixture.question.nextReviewAt;

    await expectLater(
      fixture.service.closeAndPersistTurn(
        turn: fixture.turn(
          sessionId: 'missing-session',
          accuracyScore: 1,
          projectDetailScore: 1,
          engineeringScore: 2,
          clarityScore: 3,
          weakKnowledgePointIds: [fixture.point.id],
        ),
        now: DateTime(2026, 7, 15, 12),
      ),
      throwsA(anything),
    );

    final unchangedQuestion =
        (await fixture.questionRepository.getAllQuestions())
            .singleWhere((question) => question.id == fixture.question.id);
    expect(unchangedQuestion.nextReviewAt, originalDueAt);
    expect(
      await fixture.learningSessionRepository
          .getInterviewTurns(fixture.session.id),
      isEmpty,
    );
  });
}

class _ClosureFixture {
  final DatabaseHelper databaseHelper;
  final KnowledgePointRepository knowledgePointRepository;
  final QuestionRepository questionRepository;
  final LearningSessionRepository learningSessionRepository;
  final InterviewReviewClosureService service;
  final KnowledgePoint point;
  final Question question;
  final LearningSession session;

  const _ClosureFixture({
    required this.databaseHelper,
    required this.knowledgePointRepository,
    required this.questionRepository,
    required this.learningSessionRepository,
    required this.service,
    required this.point,
    required this.question,
    required this.session,
  });

  static Future<_ClosureFixture> create() async {
    final databaseHelper = DatabaseHelper.forTesting(
      databaseFactory: databaseFactoryFfi,
    );
    final knowledgePointRepository = KnowledgePointRepository(databaseHelper);
    final questionRepository = QuestionRepository(databaseHelper);
    final learningSessionRepository = LearningSessionRepository(databaseHelper);
    final now = DateTime(2026, 7, 15, 9);
    final point = KnowledgePoint(
      id: 'point-architecture',
      title: 'Provider orchestration',
      summary: 'Providers connect tasks and repositories.',
      kind: KnowledgePointKind.architecture,
      createdAt: now,
      updatedAt: now,
    );
    final question = Question(
      id: 'question-architecture',
      deckId: 'deck-1',
      knowledgePointId: point.id,
      type: QuestionType.fillBlank,
      content: 'How does provider orchestration work?',
      answer: 'Providers connect tasks and repositories.',
      sourceStatus: SourceStatus.verified,
      citationIds: const ['chunk-architecture'],
      nextReviewAt: DateTime(2026, 7, 30),
    );
    final session = LearningSession(
      id: 'session-1',
      mode: LearningSessionMode.interview,
      targetId: point.id,
      startedAt: now,
    );

    await databaseHelper.insertDeck(
      Deck(
        id: 'deck-1',
        title: 'Project interview',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await knowledgePointRepository.insertKnowledgePoint(point);
    await questionRepository.insertQuestion(question);
    await learningSessionRepository.insertLearningSession(session);

    return _ClosureFixture(
      databaseHelper: databaseHelper,
      knowledgePointRepository: knowledgePointRepository,
      questionRepository: questionRepository,
      learningSessionRepository: learningSessionRepository,
      service: InterviewReviewClosureService(
        knowledgePointRepository: knowledgePointRepository,
        questionRepository: questionRepository,
        databaseHelper: databaseHelper,
      ),
      point: point,
      question: question,
      session: session,
    );
  }

  InterviewTurn turn({
    String? sessionId,
    required int accuracyScore,
    required int projectDetailScore,
    required int engineeringScore,
    required int clarityScore,
    List<String> weakKnowledgePointIds = const [],
    GroundingDisposition groundingDisposition = GroundingDisposition.grounded,
  }) {
    return InterviewTurn(
      id: 'turn-1',
      sessionId: sessionId ?? session.id,
      questionText: question.content,
      userAnswer: 'Providers call repositories.',
      aiFeedback: 'Add the source-backed orchestration details.',
      referenceAnswer: question.answer,
      knowledgePointId: point.id,
      knowledgePointKind: point.kind,
      citationIds: question.citationIds,
      accuracyScore: accuracyScore,
      projectDetailScore: projectDetailScore,
      engineeringScore: engineeringScore,
      clarityScore: clarityScore,
      weakKnowledgePointIds: weakKnowledgePointIds,
      groundingDisposition: groundingDisposition,
      createdAt: DateTime(2026, 7, 15, 12),
    );
  }
}
