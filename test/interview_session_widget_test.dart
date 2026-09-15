import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/data/database/database_helper.dart';
import 'package:anchor_learning/data/models/grounded_learning_context.dart';
import 'package:anchor_learning/data/models/interview_turn.dart';
import 'package:anchor_learning/data/models/knowledge_point.dart';
import 'package:anchor_learning/data/models/knowledge_point_source.dart';
import 'package:anchor_learning/data/models/learning_session.dart';
import 'package:anchor_learning/data/models/source.dart';
import 'package:anchor_learning/data/models/source_chunk.dart';
import 'package:anchor_learning/data/repositories/knowledge_point_repository.dart';
import 'package:anchor_learning/data/repositories/learning_session_repository.dart';
import 'package:anchor_learning/data/repositories/question_repository.dart';
import 'package:anchor_learning/data/repositories/source_chunk_repository.dart';
import 'package:anchor_learning/features/agent/interview_session_screen.dart';
import 'package:anchor_learning/services/agent/interviewer_service.dart';
import 'package:anchor_learning/services/ai/ai_task_result.dart';
import 'package:anchor_learning/services/ai/tasks/answer_evaluation_task.dart';
import 'package:anchor_learning/services/ai/tasks/interview_question_task.dart';
import 'package:anchor_learning/services/openai_service.dart';
import 'package:anchor_learning/services/scheduling/interview_review_closure_service.dart';
import 'package:anchor_learning/services/scheduling/mastery_service.dart';

void main() {
  testWidgets('late startup key result after route exit is ignored',
      (tester) async {
    final fixture = _InterviewFixture();
    final openai = _ControlledOpenAIService.pendingKey();
    await tester.pumpWidget(fixture.app(openai: openai));
    await tester.pump();

    expect(openai.hasApiKeyCalls, 1);
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    openai.pendingKey!.complete(true);
    await tester.pumpAndSettle();

    expect(fixture.knowledgeRepository.allPointsCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending evaluation owns the submit action', (tester) async {
    final fixture = _InterviewFixture(
      evaluationTask: _ControlledEvaluationTask.pending(),
    );
    await tester.pumpWidget(fixture.app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'A grounded answer.');
    final submit = find.text('提交回答');
    await tester.tap(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(fixture.evaluationTask.runCalls, 1);
  });

  testWidgets('late evaluation result after route exit does not persist',
      (tester) async {
    final evaluationTask = _ControlledEvaluationTask.pending();
    final fixture = _InterviewFixture(evaluationTask: evaluationTask);
    await tester.pumpWidget(fixture.app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'A grounded answer.');
    await tester.tap(find.text('提交回答'));
    await tester.pump();
    expect(evaluationTask.runCalls, 1);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    evaluationTask.pendingResult!.complete(
      AiTaskResult.success(_evaluationResult()),
    );
    await tester.pumpAndSettle();

    expect(fixture.closureService.closeCalls, 0);
    expect(fixture.masteryService.updateCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mounted evaluation failure remains retryable', (tester) async {
    final fixture = _InterviewFixture(
      evaluationTask:
          _ControlledEvaluationTask.failure('controlled evaluation failure'),
    );
    await tester.pumpWidget(fixture.app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'A grounded answer.');
    await tester.tap(find.text('提交回答'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(fixture.evaluationTask.runCalls, 1);
    expect(
      find.textContaining('controlled evaluation failure', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('提交回答'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending next question owns the next action', (tester) async {
    final questionTask = _ControlledQuestionTask.sequence(
      immediate: _questionResult(),
      pending: true,
    );
    final fixture = _InterviewFixture(
      questionTask: questionTask,
      evaluationTask: _ControlledEvaluationTask.immediate(),
    );
    await tester.pumpWidget(fixture.app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'A grounded answer.');
    await tester.tap(find.text('提交回答'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续下一题'));
    await tester.tap(find.text('继续下一题'));
    await tester.pump();

    expect(questionTask.runCalls, 2);
  });

  testWidgets('late next question result after route exit is ignored',
      (tester) async {
    final questionTask = _ControlledQuestionTask.sequence(
      immediate: _questionResult(),
      pending: true,
    );
    final fixture = _InterviewFixture(
      questionTask: questionTask,
      evaluationTask: _ControlledEvaluationTask.immediate(),
    );
    await tester.pumpWidget(fixture.app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'A grounded answer.');
    await tester.tap(find.text('提交回答'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续下一题'));
    await tester.pump();
    expect(questionTask.runCalls, 2);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    questionTask.pendingResult!
        .complete(AiTaskResult.success(_questionResult()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('pending completion owns persistence after route exit',
      (tester) async {
    final fixture = _InterviewFixture(
      singlePoint: true,
      evaluationTask: _ControlledEvaluationTask.immediate(),
    );
    fixture.sessionRepository.pendingUpdate = Completer<void>();
    await tester.pumpWidget(fixture.app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'A grounded answer.');
    await tester.tap(find.text('提交回答'));
    await tester.pumpAndSettle();
    final finish = find.text('完成面试');
    expect(finish, findsOneWidget);
    await tester.tap(finish);
    await tester.tap(finish);
    await tester.pump();
    expect(fixture.sessionRepository.updateCalls, 1);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    fixture.sessionRepository.pendingUpdate!.complete();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

class _InterviewFixture {
  final bool singlePoint;
  final DateTime now = DateTime(2026, 7, 15);
  late final List<KnowledgePoint> points = [
    KnowledgePoint(
      id: 'interview-point',
      title: 'Interview point',
      summary: 'A source-backed interview point.',
      createdAt: now,
      updatedAt: now,
    ),
    if (!singlePoint)
      KnowledgePoint(
        id: 'interview-point-2',
        title: 'Second interview point',
        summary: 'A second source-backed interview point.',
        createdAt: now,
        updatedAt: now,
      ),
  ];
  late final List<SourceChunk> chunks = [
    SourceChunk(
      id: 'interview-chunk',
      sourceId: 'interview-source',
      chunkIndex: 0,
      content: 'The provider delegates persistence to the repository.',
      locator: 'lib/store.dart:10-10',
      contentHash: 'interview-hash',
      createdAt: now,
    ),
    if (!singlePoint)
      SourceChunk(
        id: 'interview-chunk-2',
        sourceId: 'interview-source-2',
        chunkIndex: 0,
        content: 'The second provider delegates to the second repository.',
        locator: 'lib/store.dart:20-20',
        contentHash: 'interview-hash-2',
        createdAt: now,
      ),
  ];
  late final _FakeKnowledgePointRepository knowledgeRepository =
      _FakeKnowledgePointRepository(points, chunks);
  late final _FakeSourceChunkRepository chunkRepository =
      _FakeSourceChunkRepository(chunks);
  late final _FakeLearningSessionRepository sessionRepository =
      _FakeLearningSessionRepository();
  late final _FakeInterviewReviewClosureService closureService =
      _FakeInterviewReviewClosureService();
  late final _FakeMasteryService masteryService = _FakeMasteryService();

  final _ControlledQuestionTask questionTask;
  final _ControlledEvaluationTask evaluationTask;

  _InterviewFixture({
    this.singlePoint = false,
    _ControlledQuestionTask? questionTask,
    _ControlledEvaluationTask? evaluationTask,
  })  : questionTask = questionTask ??
            _ControlledQuestionTask.sequence(immediate: _questionResult()),
        evaluationTask = evaluationTask ?? _ControlledEvaluationTask.pending();

  Widget app({OpenAIService? openai}) {
    return ProviderScope(
      overrides: [
        openaiServiceProvider.overrideWithValue(
          openai ?? _ControlledOpenAIService.immediateKey(),
        ),
        knowledgePointRepositoryProvider.overrideWithValue(knowledgeRepository),
        sourceChunkRepositoryProvider.overrideWithValue(chunkRepository),
        learningSessionRepositoryProvider.overrideWithValue(sessionRepository),
        interviewerServiceProvider.overrideWithValue(
          InterviewerService(
            questionTask: questionTask,
            evaluationTask: evaluationTask,
          ),
        ),
        interviewReviewClosureServiceProvider.overrideWithValue(closureService),
        masteryServiceProvider.overrideWithValue(masteryService),
        sourceProvider.overrideWith(
          (ref, sourceId) async => Source(
            id: sourceId,
            title: 'Interview source',
            type: SourceType.project,
            trustLevel: SourceTrustLevel.sourceCode,
            createdAt: now,
            updatedAt: now,
          ),
        ),
      ],
      child: const MaterialApp(home: InterviewSessionScreen()),
    );
  }
}

InterviewQuestionResult _questionResult() {
  return _questionResultFor(
    pointId: 'interview-point',
    chunkId: 'interview-chunk',
  );
}

InterviewQuestionResult _questionResultFor({
  required String pointId,
  required String chunkId,
}) {
  return InterviewQuestionResult(
    questions: [
      InterviewQuestionDraft(
        question: 'How does persistence work?',
        knowledgePointIds: [pointId],
        citationIds: [chunkId],
        difficulty: 3,
      ),
    ],
  );
}

AnswerEvaluationResult _evaluationResult() {
  return AnswerEvaluationResult(
    accuracyScore: 4,
    projectDetailScore: 4,
    engineeringScore: 3,
    clarityScore: 4,
    feedback: 'The answer is grounded.',
    referenceAnswer: 'The provider delegates persistence to the repository.',
  );
}

class _ControlledOpenAIService extends OpenAIService {
  final Completer<bool>? pendingKey;
  final bool immediateKey;
  int hasApiKeyCalls = 0;

  _ControlledOpenAIService._({this.pendingKey, this.immediateKey = false});

  factory _ControlledOpenAIService.pendingKey() =>
      _ControlledOpenAIService._(pendingKey: Completer<bool>());

  factory _ControlledOpenAIService.immediateKey() =>
      _ControlledOpenAIService._(immediateKey: true);

  @override
  Future<bool> hasApiKey({String? providerId}) {
    hasApiKeyCalls++;
    final pending = pendingKey;
    return pending == null ? Future.value(immediateKey) : pending.future;
  }
}

class _ControlledQuestionTask extends InterviewQuestionTask {
  final List<Future<AiTaskResult<InterviewQuestionResult>>> responses;
  final Completer<AiTaskResult<InterviewQuestionResult>>? pendingResult;
  int runCalls = 0;
  int _index = 0;

  _ControlledQuestionTask._({
    required this.responses,
    this.pendingResult,
  }) : super(OpenAIService());

  factory _ControlledQuestionTask.sequence({
    required InterviewQuestionResult immediate,
    bool pending = false,
  }) {
    final pendingResult =
        pending ? Completer<AiTaskResult<InterviewQuestionResult>>() : null;
    return _ControlledQuestionTask._(
      pendingResult: pendingResult,
      responses: [
        Future.value(AiTaskResult.success(immediate)),
        if (pending) pendingResult!.future,
      ],
    );
  }

  @override
  Future<AiTaskResult<InterviewQuestionResult>> run({
    required List<KnowledgePoint> knowledgePoints,
    required List<SourceChunk> sourceChunks,
    int questionCount = 1,
    String? followUpQuestion,
    GroundedLearningContext? groundedContext,
  }) {
    runCalls++;
    return responses[_index++];
  }
}

class _ControlledEvaluationTask extends AnswerEvaluationTask {
  final Completer<AiTaskResult<AnswerEvaluationResult>>? pendingResult;
  final AiTaskResult<AnswerEvaluationResult>? result;
  int runCalls = 0;

  _ControlledEvaluationTask._({this.pendingResult, this.result})
      : super(OpenAIService());

  factory _ControlledEvaluationTask.pending() => _ControlledEvaluationTask._(
        pendingResult: Completer<AiTaskResult<AnswerEvaluationResult>>(),
      );

  factory _ControlledEvaluationTask.immediate() => _ControlledEvaluationTask._(
        result: AiTaskResult.success(_evaluationResult()),
      );

  factory _ControlledEvaluationTask.failure(String message) =>
      _ControlledEvaluationTask._(
        result: AiTaskResult.failure(
          type: AiTaskErrorType.request,
          message: message,
        ),
      );

  @override
  Future<AiTaskResult<AnswerEvaluationResult>> run({
    required String question,
    required String userAnswer,
    required List<String> knowledgePointIds,
    required List<SourceChunk> citedChunks,
    GroundedLearningContext? groundedContext,
  }) {
    runCalls++;
    final pending = pendingResult;
    return pending == null ? Future.value(result!) : pending.future;
  }
}

class _FakeKnowledgePointRepository extends KnowledgePointRepository {
  final List<KnowledgePoint> points;
  final List<SourceChunk> chunks;
  int allPointsCalls = 0;

  _FakeKnowledgePointRepository(this.points, this.chunks)
      : super(DatabaseHelper());

  @override
  Future<List<KnowledgePoint>> getAllKnowledgePoints() async {
    allPointsCalls++;
    return points;
  }

  @override
  Future<KnowledgePoint?> getKnowledgePoint(String id) async {
    for (final point in points) {
      if (id == point.id) return point;
    }
    return null;
  }

  @override
  Future<List<KnowledgePointSource>> getKnowledgePointSources(String id) async {
    final index = points.indexWhere((point) => point.id == id);
    if (index < 0) return const [];
    return [
      KnowledgePointSource(
        knowledgePointId: points[index].id,
        sourceChunkId: chunks[index].id,
      ),
    ];
  }
}

class _FakeSourceChunkRepository extends SourceChunkRepository {
  final List<SourceChunk> chunks;

  _FakeSourceChunkRepository(this.chunks) : super(DatabaseHelper());

  @override
  Future<SourceChunk?> getSourceChunk(String id) async {
    for (final chunk in chunks) {
      if (id == chunk.id) return chunk;
    }
    return null;
  }
}

class _FakeLearningSessionRepository extends LearningSessionRepository {
  int insertCalls = 0;
  int updateCalls = 0;
  Completer<void>? pendingUpdate;

  _FakeLearningSessionRepository() : super(DatabaseHelper());

  @override
  Future<List<InterviewTurn>> getInterviewTurns(String sessionId) async => [];

  @override
  Future<String> insertLearningSession(LearningSession session) async {
    insertCalls++;
    return session.id;
  }

  @override
  Future<void> updateLearningSession(LearningSession session) async {
    updateCalls++;
    final pending = pendingUpdate;
    if (pending != null) return pending.future;
  }
}

class _FakeInterviewReviewClosureService extends InterviewReviewClosureService {
  int closeCalls = 0;

  _FakeInterviewReviewClosureService()
      : super(
          knowledgePointRepository: KnowledgePointRepository(DatabaseHelper()),
          questionRepository: QuestionRepository(DatabaseHelper()),
          databaseHelper: DatabaseHelper(),
        );

  @override
  Future<InterviewTurn> closeAndPersistTurn({
    required InterviewTurn turn,
    DateTime? now,
  }) async {
    closeCalls++;
    return turn;
  }
}

class _FakeMasteryService extends MasteryService {
  int updateCalls = 0;

  _FakeMasteryService() : super(KnowledgePointRepository(DatabaseHelper()));

  @override
  Future<void> updateFromInterviewTurn({
    required InterviewTurn turn,
    required List<String> knowledgePointIds,
  }) async {
    updateCalls++;
  }
}
