import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/data/database/database_helper.dart';
import 'package:anchor_learning/data/models/grounded_learning_context.dart';
import 'package:anchor_learning/data/models/knowledge_point.dart';
import 'package:anchor_learning/data/models/knowledge_point_prerequisite.dart';
import 'package:anchor_learning/data/models/knowledge_point_source.dart';
import 'package:anchor_learning/data/models/learning_session.dart';
import 'package:anchor_learning/data/models/source.dart';
import 'package:anchor_learning/data/models/source_chunk.dart';
import 'package:anchor_learning/data/models/tutor_turn.dart';
import 'package:anchor_learning/data/repositories/knowledge_point_repository.dart';
import 'package:anchor_learning/data/repositories/learning_session_repository.dart';
import 'package:anchor_learning/data/repositories/source_chunk_repository.dart';
import 'package:anchor_learning/features/agent/tutor_session_screen.dart';
import 'package:anchor_learning/services/ai/ai_task_result.dart';
import 'package:anchor_learning/services/ai/tasks/tutor_explanation_task.dart';
import 'package:anchor_learning/services/ai/tasks/tutor_socratic_task.dart';
import 'package:anchor_learning/services/openai_service.dart';

import 'support/fake_programming_review_closure_service.dart';

void main() {
  testWidgets('pending explanation owns the point action', (tester) async {
    final fixture = _TutorFixture(
      explanationTask: _ControlledExplanationTask.pending(),
    );
    final openai = _ControlledOpenAIService.pendingKey();
    await tester.pumpWidget(fixture.app(openai: openai));
    await tester.pumpAndSettle();

    final point = find.text('Tutor point');
    await tester.tap(point);
    await tester.tap(point);
    await tester.pump();

    expect(openai.hasApiKeyCalls, 1);
  });

  testWidgets('late explanation key result after route exit is ignored',
      (tester) async {
    final fixture = _TutorFixture();
    final openai = _ControlledOpenAIService.pendingKey();
    await tester.pumpWidget(fixture.app(openai: openai));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tutor point'));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    openai.pendingKey!.complete(true);
    await tester.pumpAndSettle();

    expect(fixture.knowledgeRepository.sourceCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late explanation result after route exit does not persist',
      (tester) async {
    final fixture = _TutorFixture(
      explanationTask: _ControlledExplanationTask.pending(),
    );
    await tester.pumpWidget(fixture.app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tutor point'));
    await tester.pump();
    expect(fixture.explanationTask.runCalls, 1);
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    fixture.explanationTask.pendingResult!.complete(
      AiTaskResult.success(_explanationResult()),
    );
    await tester.pumpAndSettle();

    expect(fixture.sessionRepository.insertCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mounted explanation failure remains retryable', (tester) async {
    final fixture = _TutorFixture(
      explanationTask:
          _ControlledExplanationTask.failure('controlled explanation failure'),
    );
    await tester.pumpWidget(fixture.app(initialPoint: fixture.point));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('controlled explanation failure',
          skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('重试讲解'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending answer submission owns the feedback action',
      (tester) async {
    final fixture = _TutorFixture(
      socraticTask: _ControlledSocraticTask.pending(),
    );
    await tester.pumpWidget(fixture.app(initialPoint: fixture.point));
    await tester.pumpAndSettle();

    final answer = find.byKey(
      const ValueKey('tutor-answer-input'),
      skipOffstage: false,
    );
    await tester.scrollUntilVisible(
      answer,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(answer, 'A grounded answer.');
    final submit = find.byKey(const ValueKey('tutor-submit-answer'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(fixture.socraticTask.runCalls, 1);
  });

  testWidgets('late answer result after route exit does not persist',
      (tester) async {
    final fixture = _TutorFixture(
      socraticTask: _ControlledSocraticTask.pending(),
    );
    await tester.pumpWidget(fixture.app(initialPoint: fixture.point));
    await tester.pumpAndSettle();

    final answer = find.byKey(
      const ValueKey('tutor-answer-input'),
      skipOffstage: false,
    );
    await tester.scrollUntilVisible(
      answer,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(answer, 'A grounded answer.');
    final submit = find.byKey(const ValueKey('tutor-submit-answer'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(fixture.socraticTask.runCalls, 1);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    fixture.socraticTask.pendingResult!.complete(
      AiTaskResult.success(_socraticResult()),
    );
    await tester.pumpAndSettle();

    expect(fixture.closureCalls, 0);
    expect(fixture.sessionRepository.updateCalls, 0);
    expect(tester.takeException(), isNull);
  });
}

class _TutorFixture {
  final DateTime now = DateTime(2026, 7, 15);
  late final KnowledgePoint point = KnowledgePoint(
    id: 'tutor-point',
    title: 'Tutor point',
    summary: 'A source-backed tutor point.',
    createdAt: now,
    updatedAt: now,
  );
  late final SourceChunk chunk = SourceChunk(
    id: 'tutor-chunk',
    sourceId: 'tutor-source',
    chunkIndex: 0,
    content: 'The provider delegates persistence to the repository.',
    locator: 'lib/store.dart:10-10',
    contentHash: 'tutor-hash',
    createdAt: now,
  );
  late final _FakeKnowledgePointRepository knowledgeRepository =
      _FakeKnowledgePointRepository(point, chunk);
  late final _FakeSourceChunkRepository chunkRepository =
      _FakeSourceChunkRepository(chunk);
  late final _FakeLearningSessionRepository sessionRepository =
      _FakeLearningSessionRepository();
  late final _ControlledExplanationTask explanationTask;
  late final _ControlledSocraticTask socraticTask;
  int closureCalls = 0;

  _TutorFixture({
    _ControlledExplanationTask? explanationTask,
    _ControlledSocraticTask? socraticTask,
  })  : explanationTask =
            explanationTask ?? _ControlledExplanationTask.immediate(),
        socraticTask = socraticTask ?? _ControlledSocraticTask.pending();

  Widget app({
    OpenAIService? openai,
    KnowledgePoint? initialPoint,
  }) {
    return ProviderScope(
      overrides: [
        openaiServiceProvider.overrideWithValue(
          openai ?? _ControlledOpenAIService.immediateKey(),
        ),
        knowledgePointRepositoryProvider.overrideWithValue(knowledgeRepository),
        sourceChunkRepositoryProvider.overrideWithValue(chunkRepository),
        learningSessionRepositoryProvider.overrideWithValue(sessionRepository),
        tutorExplanationTaskProvider.overrideWithValue(explanationTask),
        tutorSocraticTaskProvider.overrideWithValue(socraticTask),
        programmingReviewClosureServiceProvider.overrideWithValue(
          FakeProgrammingReviewClosureService(
            onTutorTurn: (turn) async {
              closureCalls++;
            },
          ),
        ),
        evidenceBackedKnowledgePointListProvider.overrideWith(
          (ref) async => [point],
        ),
        sourceProvider.overrideWith(
          (ref, sourceId) async => Source(
            id: sourceId,
            title: 'Tutor source',
            type: SourceType.project,
            trustLevel: SourceTrustLevel.sourceCode,
            createdAt: now,
            updatedAt: now,
          ),
        ),
      ],
      child: MaterialApp(
        home: TutorSessionScreen(initialPoint: initialPoint),
      ),
    );
  }
}

TutorExplanationResult _explanationResult() {
  return const TutorExplanationResult(
    definitionAndIntuition: 'A grounded definition.',
    mechanism: 'The provider delegates to the repository.',
    codeOrDocExample: 'The source shows the delegation.',
    boundaries: 'Only the cited path is supported.',
    openingQuestion: 'What does the provider delegate?',
    citationIds: ['tutor-chunk'],
  );
}

TutorSocraticResult _socraticResult() {
  return const TutorSocraticResult(
    feedback: 'The answer is grounded.',
    referenceAnswer: 'The provider delegates to the repository.',
    nextQuestion: 'What is the repository boundary?',
    citationIds: ['tutor-chunk'],
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

class _ControlledExplanationTask extends TutorExplanationTask {
  final Completer<AiTaskResult<TutorExplanationResult>>? pendingResult;
  final AiTaskResult<TutorExplanationResult>? result;
  int runCalls = 0;

  _ControlledExplanationTask._({this.pendingResult, this.result})
      : super(OpenAIService());

  factory _ControlledExplanationTask.pending() => _ControlledExplanationTask._(
        pendingResult: Completer<AiTaskResult<TutorExplanationResult>>(),
      );

  factory _ControlledExplanationTask.immediate() =>
      _ControlledExplanationTask._(
        result: AiTaskResult.success(_explanationResult()),
      );

  factory _ControlledExplanationTask.failure(String message) =>
      _ControlledExplanationTask._(
        result: AiTaskResult.failure(
          type: AiTaskErrorType.request,
          message: message,
        ),
      );

  @override
  Future<AiTaskResult<TutorExplanationResult>> run({
    required KnowledgePoint knowledgePoint,
    required List<SourceChunk> sourceChunks,
    List<KnowledgePoint> prerequisiteKnowledgePoints = const [],
    Map<String, List<SourceChunk>> prerequisiteChunksByKnowledgePointId =
        const {},
    GroundedLearningContext? groundedContext,
  }) {
    runCalls++;
    final pending = pendingResult;
    return pending == null ? Future.value(result!) : pending.future;
  }
}

class _ControlledSocraticTask extends TutorSocraticTask {
  final Completer<AiTaskResult<TutorSocraticResult>>? pendingResult;
  int runCalls = 0;

  _ControlledSocraticTask._({this.pendingResult}) : super(OpenAIService());

  factory _ControlledSocraticTask.pending() => _ControlledSocraticTask._(
        pendingResult: Completer<AiTaskResult<TutorSocraticResult>>(),
      );

  @override
  Future<AiTaskResult<TutorSocraticResult>> run({
    required KnowledgePoint knowledgePoint,
    required String question,
    required String userAnswer,
    required List<SourceChunk> sourceChunks,
    List<KnowledgePoint> prerequisiteKnowledgePoints = const [],
    Map<String, List<SourceChunk>> prerequisiteChunksByKnowledgePointId =
        const {},
    List<TutorTurn> previousTurns = const [],
    GroundedLearningContext? groundedContext,
  }) {
    runCalls++;
    final pending = pendingResult;
    return pending == null
        ? Future.value(AiTaskResult.success(_socraticResult()))
        : pending.future;
  }
}

class _FakeKnowledgePointRepository extends KnowledgePointRepository {
  final KnowledgePoint point;
  final SourceChunk chunk;
  int sourceCalls = 0;

  _FakeKnowledgePointRepository(this.point, this.chunk)
      : super(DatabaseHelper());

  @override
  Future<KnowledgePoint?> getKnowledgePoint(String id) async {
    return id == point.id ? point : null;
  }

  @override
  Future<List<KnowledgePointSource>> getKnowledgePointSources(String id) async {
    sourceCalls++;
    return id == point.id
        ? [
            KnowledgePointSource(
              knowledgePointId: point.id,
              sourceChunkId: chunk.id,
            ),
          ]
        : const [];
  }

  @override
  Future<List<KnowledgePointPrerequisite>>
      getKnowledgePointPrerequisites() async => const [];
}

class _FakeSourceChunkRepository extends SourceChunkRepository {
  final SourceChunk chunk;

  _FakeSourceChunkRepository(this.chunk) : super(DatabaseHelper());

  @override
  Future<SourceChunk?> getSourceChunk(String id) async {
    return id == chunk.id ? chunk : null;
  }
}

class _FakeLearningSessionRepository extends LearningSessionRepository {
  int insertCalls = 0;
  int updateCalls = 0;

  _FakeLearningSessionRepository() : super(DatabaseHelper());

  @override
  Future<String> insertLearningSession(LearningSession session) async {
    insertCalls++;
    return session.id;
  }

  @override
  Future<LearningSession?> getLearningSession(String id) async => null;

  @override
  Future<void> updateLearningSession(LearningSession session) async {
    updateCalls++;
  }
}
