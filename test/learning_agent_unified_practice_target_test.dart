import 'dart:convert';

import 'package:dlg_q/core/providers/providers.dart';
import 'package:dlg_q/data/database/database_helper.dart';
import 'package:dlg_q/data/models/knowledge_point.dart';
import 'package:dlg_q/data/models/knowledge_point_source.dart';
import 'package:dlg_q/data/models/programming_exercise.dart';
import 'package:dlg_q/data/models/programming_exercise_attempt.dart';
import 'package:dlg_q/data/models/question.dart';
import 'package:dlg_q/data/models/question_type.dart';
import 'package:dlg_q/data/models/source.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/data/repositories/knowledge_point_repository.dart';
import 'package:dlg_q/data/repositories/programming_exercise_repository.dart';
import 'package:dlg_q/data/repositories/question_repository.dart';
import 'package:dlg_q/data/repositories/source_chunk_repository.dart';
import 'package:dlg_q/data/repositories/source_repository.dart';
import 'package:dlg_q/features/agent/programming_exercise_screen.dart';
import 'package:dlg_q/features/learning/quiz_screen.dart';
import 'package:dlg_q/services/agent/learning_agent_executor.dart';
import 'package:dlg_q/services/agent/learning_agent_plan_codec.dart';
import 'package:dlg_q/services/agent/learning_agent_planner_service.dart';
import 'package:dlg_q/services/agent/learning_agent_practice_target.dart';
import 'package:dlg_q/services/agent/learning_agent_state.dart';
import 'package:dlg_q/services/agent/learning_agent_tool_registry.dart';
import 'package:dlg_q/services/agent/learning_agent_trace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final point = _knowledgePoint();
  final question = _question(point.id);
  final exercise = _exercise(point.id);

  test('planner selects a verified question as the only practice target', () {
    final plan = _plan(point, [
      LearningAgentPracticeTarget.fromQuestion(question),
    ]);

    expect(plan.nextStep?.type, LearningAgentStepType.practice);
    expect(plan.readiness.verifiedQuestionCount, 1);
    expect(plan.readiness.verifiedProgrammingExerciseCount, 0);
    expect(plan.readiness.verifiedPracticeTargetCount, 1);
    expect(plan.practiceTarget?.type, LearningAgentPracticeTargetType.question);
    expect(plan.practiceTarget?.id, question.id);
    expect(plan.startBlockReason, isNull);
  });

  test('planner selects a verified programming exercise without questions', () {
    final plan = _plan(point, [
      LearningAgentPracticeTarget.fromProgrammingExercise(exercise),
    ]);

    expect(plan.nextStep?.type, LearningAgentStepType.practice);
    expect(plan.readiness.verifiedQuestionCount, 0);
    expect(plan.readiness.verifiedProgrammingExerciseCount, 1);
    expect(plan.readiness.verifiedPracticeTargetCount, 1);
    expect(
      plan.practiceTarget?.type,
      LearningAgentPracticeTargetType.programmingExercise,
    );
    expect(plan.practiceTarget?.id, exercise.id);
    expect(plan.startBlockReason, isNull);
  });

  test(
      'planner deterministically prefers the programming exercise when both exist',
      () {
    final plan = _plan(point, [
      LearningAgentPracticeTarget.fromQuestion(question),
      LearningAgentPracticeTarget.fromProgrammingExercise(exercise),
    ]);

    expect(plan.readiness.verifiedPracticeTargetCount, 2);
    expect(plan.nextStep?.targetCount, 2);
    expect(
      plan.practiceTarget?.type,
      LearningAgentPracticeTargetType.programmingExercise,
    );
    expect(plan.practiceTarget?.id, exercise.id);
  });

  test('planner excludes unverified or uncited practice targets', () {
    final plan = _plan(point, [
      LearningAgentPracticeTarget.fromProgrammingExercise(
        exercise.copyWith(sourceStatus: SourceStatus.pending),
      ),
      LearningAgentPracticeTarget.fromQuestion(
        question.copyWith(citationIds: const []),
      ),
    ]);

    expect(plan.readiness.verifiedPracticeTargetCount, 0);
    expect(plan.practiceTarget, isNull);
    expect(
      plan.steps
          .singleWhere(
            (step) => step.type == LearningAgentStepType.practice,
          )
          .enabled,
      isFalse,
    );
  });

  test('plan codec preserves typed targets and decodes old additive snapshots',
      () {
    const codec = LearningAgentPlanCodec();
    final plan = _plan(point, [
      LearningAgentPracticeTarget.fromProgrammingExercise(exercise),
    ]);
    final decoded = codec.decode(codec.encode(plan));

    expect(decoded.practiceTarget?.routingId, plan.practiceTarget?.routingId);
    expect(decoded.readiness.verifiedProgrammingExerciseCount, 1);
    expect(
      decoded.focusPoints.single.verifiedProgrammingExerciseCount,
      1,
    );

    final legacyMap = jsonDecode(codec.encode(plan)) as Map<String, dynamic>;
    (legacyMap['readiness'] as Map<String, dynamic>)
        .remove('verified_programming_exercise_count');
    ((legacyMap['focus_points'] as List).single as Map<String, dynamic>)
        .remove('verified_programming_exercise_count');
    (legacyMap['session_summary'] as Map<String, dynamic>)
        .remove('practice_target');
    final legacyDecoded = codec.decode(jsonEncode(legacyMap));

    expect(legacyDecoded.practiceTarget, isNull);
    expect(legacyDecoded.readiness.verifiedProgrammingExerciseCount, 0);
  });

  testWidgets('executor opens the exact verified question target',
      (tester) async {
    final plan = _plan(point, [
      LearningAgentPracticeTarget.fromQuestion(question),
    ]);
    final repositories = _RepositoryBundle(
      point: point,
      questions: [question],
      exercises: const [],
    );
    final harness = await _pumpHarness(tester, repositories);

    final execution = _execute(harness, plan);
    await tester.pumpAndSettle();

    final quiz = tester.widget<QuizScreen>(find.byType(QuizScreen));
    expect(quiz.questions?.map((item) => item.id), [question.id]);

    Navigator.of(tester.element(find.byType(QuizScreen))).pop();
    await tester.pumpAndSettle();
    expect((await execution).isCompleted, isTrue);
  });

  testWidgets('executor opens the exact verified programming exercise target',
      (tester) async {
    final plan = _plan(point, [
      LearningAgentPracticeTarget.fromProgrammingExercise(exercise),
    ]);
    final repositories = _RepositoryBundle(
      point: point,
      questions: const [],
      exercises: [exercise],
    );
    final harness = await _pumpHarness(tester, repositories);

    final execution = _execute(harness, plan);
    await tester.pumpAndSettle();

    final screen = tester.widget<ProgrammingExerciseScreen>(
      find.byType(ProgrammingExerciseScreen),
    );
    expect(screen.knowledgePoint.id, point.id);
    expect(screen.initialExerciseId, exercise.id);

    Navigator.of(tester.element(find.byType(ProgrammingExerciseScreen))).pop();
    await tester.pumpAndSettle();
    final result = await execution;
    expect(result.isCompleted, isTrue);
    final policyTrace = result.traceEvents.singleWhere(
      (event) => event.type == LearningAgentTraceEventType.policyChecked,
    );
    expect(policyTrace.detail, contains('Grounded context ID:'));
    expect(policyTrace.detail, contains('selection_reason=practice_citation'));
    expect(policyTrace.evidenceChunkIds, ['typed-practice-chunk']);
  });

  testWidgets('executor blocks when the planned target is no longer verified',
      (tester) async {
    final plan = _plan(point, [
      LearningAgentPracticeTarget.fromProgrammingExercise(exercise),
    ]);
    final repositories = _RepositoryBundle(
      point: point,
      questions: const [],
      exercises: [exercise.copyWith(sourceStatus: SourceStatus.pending)],
    );
    final harness = await _pumpHarness(tester, repositories);

    final result = await _execute(harness, plan);

    expect(result.isBlocked, isTrue);
    expect(
      result.policyResult?.blockingIssues.map((issue) => issue.code),
      contains('formal_practice_target_unverified'),
    );
    expect(find.byType(ProgrammingExerciseScreen), findsNothing);
  });

  testWidgets('executor opens the exact pending programming verification',
      (tester) async {
    final pendingExercise = exercise.copyWith(
      id: 'pending-programming-exercise',
      sourceStatus: SourceStatus.pending,
    );
    final plan = _verificationPlan(point, pendingExercise);
    final repositories = _RepositoryBundle(
      point: point,
      questions: const [],
      exercises: [pendingExercise],
    );
    final harness = await _pumpHarness(tester, repositories);

    final execution = _executeVerification(harness, plan);
    await tester.pumpAndSettle();

    final screen = tester.widget<ProgrammingExerciseScreen>(
      find.byType(ProgrammingExerciseScreen),
    );
    expect(screen.knowledgePoint.id, point.id);
    expect(screen.initialExerciseId, pendingExercise.id);
    expect(find.text('核验代码阅读'), findsOneWidget);
    expect(find.text(pendingExercise.referenceAnswer), findsOneWidget);

    await tester.tap(find.text('暂不核验'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(ProgrammingExerciseScreen))).pop();
    await tester.pumpAndSettle();
    expect((await execution).isCompleted, isTrue);
  });

  testWidgets('executor blocks when pending exercise state has changed',
      (tester) async {
    final pendingExercise = exercise.copyWith(
      id: 'pending-programming-exercise',
      sourceStatus: SourceStatus.pending,
    );
    final plan = _verificationPlan(point, pendingExercise);
    final repositories = _RepositoryBundle(
      point: point,
      questions: const [],
      exercises: [
        pendingExercise.copyWith(sourceStatus: SourceStatus.verified),
      ],
    );
    final harness = await _pumpHarness(tester, repositories);

    final result = await _executeVerification(harness, plan);

    expect(result.isBlocked, isTrue);
    expect(
      result.policyResult?.blockingIssues.map((issue) => issue.code),
      contains('verification_exercise_state_changed'),
    );
    expect(find.byType(ProgrammingExerciseScreen), findsNothing);
  });
}

LearningAgentPlan _plan(
  KnowledgePoint point,
  List<LearningAgentPracticeTarget> targets,
) {
  final executableTargets =
      targets.where((target) => target.isExecutable).toList();
  final exerciseCount = executableTargets
      .where(
        (target) =>
            target.type == LearningAgentPracticeTargetType.programmingExercise,
      )
      .length;
  return const LearningAgentPlannerService().buildPlan(
    goal: LearningAgentGoal.programmingFoundations,
    evidenceBackedPoints: [point],
    practiceablePoints: executableTargets.isEmpty ? const [] : [point],
    practiceTargets: targets,
    pendingQuestions: const [],
    evidenceChunkCountByPointId: {point.id: 1},
    practiceTargetCountByPointId: {point.id: executableTargets.length},
    programmingExerciseCountByPointId: {point.id: exerciseCount},
  );
}

LearningAgentPlan _verificationPlan(
  KnowledgePoint point,
  ProgrammingExercise exercise,
) {
  return const LearningAgentPlannerService().buildPlan(
    goal: LearningAgentGoal.programmingFoundations,
    knowledgePoints: [point],
    evidenceBackedPoints: [point],
    practiceablePoints: const [],
    practiceTargets: const [],
    pendingQuestions: const [],
    pendingProgrammingExercises: [exercise],
    evidenceChunkCountByPointId: {point.id: 1},
  );
}

Future<_Harness> _pumpHarness(
  WidgetTester tester,
  _RepositoryBundle repositories,
) async {
  late BuildContext buildContext;
  late WidgetRef ref;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        knowledgePointRepositoryProvider.overrideWithValue(
          repositories.knowledgePoints,
        ),
        questionRepositoryProvider.overrideWithValue(repositories.questions),
        programmingExerciseRepositoryProvider.overrideWithValue(
          repositories.exercises,
        ),
        sourceRepositoryProvider.overrideWithValue(repositories.sources),
        sourceChunkRepositoryProvider.overrideWithValue(repositories.chunks),
      ],
      child: MaterialApp(
        home: Consumer(
          builder: (context, widgetRef, _) {
            buildContext = context;
            ref = widgetRef;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    ),
  );
  await tester.pump();
  return _Harness(buildContext: buildContext, ref: ref);
}

Future<LearningAgentExecutionResult> _execute(
  _Harness harness,
  LearningAgentPlan plan,
) {
  final target = plan.practiceTarget!;
  final state = LearningAgentState.initial(
    sessionId: 'practice-session',
    goal: plan.goal,
    targetId: target.routingId,
    focusPointId: target.knowledgePointId,
    availableToolIds: const [
      'start_verified_practice',
    ],
  ).transitionTo(
    LearningAgentPhase.plan,
    selectedToolId: LearningAgentToolId.startVerifiedPractice.value,
  );
  return const DefaultLearningAgentExecutor().execute(
    LearningAgentExecutionContext(
      buildContext: harness.buildContext,
      ref: harness.ref,
      plan: plan,
      sessionId: 'practice-session',
      initialState: state,
      persistToolStartCheckpoint: _ignoreCheckpoint,
    ),
  );
}

Future<LearningAgentExecutionResult> _executeVerification(
  _Harness harness,
  LearningAgentPlan plan,
) {
  final action = plan.nextAction!;
  final state = LearningAgentState.initial(
    sessionId: 'verification-session',
    goal: plan.goal,
    targetId: action.targetId,
    availableToolIds: [LearningAgentToolId.verifyPendingQuestions.value],
  ).transitionTo(
    LearningAgentPhase.plan,
    selectedToolId: LearningAgentToolId.verifyPendingQuestions.value,
  );
  return const DefaultLearningAgentExecutor().execute(
    LearningAgentExecutionContext(
      buildContext: harness.buildContext,
      ref: harness.ref,
      plan: plan,
      sessionId: 'verification-session',
      initialState: state,
      persistToolStartCheckpoint: _ignoreCheckpoint,
    ),
  );
}

Future<void> _ignoreCheckpoint(
  LearningAgentState state,
  List<dynamic> traceEvents,
) async {}

KnowledgePoint _knowledgePoint() {
  final now = DateTime.utc(2026, 7, 15);
  return KnowledgePoint(
    id: 'typed-practice-point',
    title: 'Typed practice target',
    summary: 'Question and programming exercise share one planner contract.',
    kind: KnowledgePointKind.concept,
    masteryLevel: 30,
    difficulty: 3,
    interviewRelevance: 4,
    createdAt: now,
    updatedAt: now,
  );
}

Question _question(String pointId) {
  return Question(
    id: 'verified-question',
    deckId: 'typed-practice-deck',
    knowledgePointId: pointId,
    type: QuestionType.trueFalse,
    content: 'A schema and valid JSON are the same guarantee.',
    answer: '错误',
    sourceStatus: SourceStatus.verified,
    citationIds: const ['typed-practice-chunk'],
  );
}

ProgrammingExercise _exercise(String pointId) {
  final now = DateTime.utc(2026, 7, 15);
  return ProgrammingExercise(
    id: 'verified-programming-exercise',
    knowledgePointId: pointId,
    kind: ProgrammingExerciseKind.codeReading,
    prompt: 'Explain where schema validation happens in this call path.',
    referenceAnswer: 'Validation happens after JSON parsing.',
    conceptAccuracyCriterion: 'Separate syntax from schema validation.',
    reasoningProcessCriterion: 'Trace the validation boundary.',
    evidenceUseCriterion: 'Use the cited source chunk.',
    clarityCriterion: 'Name both guarantees clearly.',
    sourceStatus: SourceStatus.verified,
    citationIds: const ['typed-practice-chunk'],
    createdAt: now,
    updatedAt: now,
  );
}

class _Harness {
  final BuildContext buildContext;
  final WidgetRef ref;

  const _Harness({required this.buildContext, required this.ref});
}

class _RepositoryBundle {
  final _FakeKnowledgePointRepository knowledgePoints;
  final _FakeQuestionRepository questions;
  final _FakeProgrammingExerciseRepository exercises;
  final _FakeSourceRepository sources;
  final _FakeSourceChunkRepository chunks;

  _RepositoryBundle({
    required KnowledgePoint point,
    required List<Question> questions,
    required List<ProgrammingExercise> exercises,
  })  : knowledgePoints = _FakeKnowledgePointRepository(point),
        questions = _FakeQuestionRepository(questions),
        exercises = _FakeProgrammingExerciseRepository(exercises),
        sources = _FakeSourceRepository(_source()),
        chunks = _FakeSourceChunkRepository(_sourceChunk());
}

class _FakeKnowledgePointRepository extends KnowledgePointRepository {
  final KnowledgePoint point;

  _FakeKnowledgePointRepository(this.point) : super(DatabaseHelper());

  @override
  Future<KnowledgePoint?> getKnowledgePoint(String id) async {
    return id == point.id ? point : null;
  }

  @override
  Future<List<KnowledgePointSource>> getKnowledgePointSources(String id) async {
    if (id != point.id) return const [];
    return [
      KnowledgePointSource(
        knowledgePointId: 'typed-practice-point',
        sourceChunkId: 'typed-practice-chunk',
      ),
    ];
  }
}

class _FakeQuestionRepository extends QuestionRepository {
  final List<Question> values;

  _FakeQuestionRepository(this.values) : super(DatabaseHelper());

  @override
  Future<List<Question>> getAllQuestions() async => values;
}

class _FakeProgrammingExerciseRepository extends ProgrammingExerciseRepository {
  final List<ProgrammingExercise> values;

  _FakeProgrammingExerciseRepository(this.values) : super(DatabaseHelper());

  @override
  Future<ProgrammingExercise?> getExercise(String id) async {
    for (final exercise in values) {
      if (exercise.id == id) return exercise;
    }
    return null;
  }

  @override
  Future<List<ProgrammingExercise>> getExercisesForKnowledgePoint(
    String knowledgePointId,
  ) async {
    return values
        .where((exercise) => exercise.knowledgePointId == knowledgePointId)
        .toList();
  }

  @override
  Future<List<ProgrammingExerciseAttempt>> getAttemptsForExercise(
    String exerciseId,
  ) async {
    return const [];
  }
}

class _FakeSourceRepository extends SourceRepository {
  final Source source;

  _FakeSourceRepository(this.source) : super(DatabaseHelper());

  @override
  Future<Source?> getSource(String id) async {
    return id == source.id ? source : null;
  }
}

class _FakeSourceChunkRepository extends SourceChunkRepository {
  final SourceChunk chunk;

  _FakeSourceChunkRepository(this.chunk) : super(DatabaseHelper());

  @override
  Future<SourceChunk?> getSourceChunk(String id) async {
    return id == chunk.id ? chunk : null;
  }
}

Source _source() {
  final now = DateTime.utc(2026, 7, 15);
  return Source(
    id: 'typed-practice-source',
    title: 'Typed practice source',
    type: SourceType.officialDoc,
    trustLevel: SourceTrustLevel.officialDoc,
    createdAt: now,
    updatedAt: now,
  );
}

SourceChunk _sourceChunk() {
  return SourceChunk(
    id: 'typed-practice-chunk',
    sourceId: 'typed-practice-source',
    chunkIndex: 0,
    content: 'JSON parsing and schema validation are separate boundaries.',
    locator: 'docs/schema.md:1-1',
    createdAt: DateTime.utc(2026, 7, 15),
  );
}
