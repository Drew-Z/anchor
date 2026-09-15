import 'dart:async';

import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/data/database/database_helper.dart';
import 'package:anchor_learning/data/models/learning_session.dart';
import 'package:anchor_learning/data/repositories/learning_session_repository.dart';
import 'package:anchor_learning/features/agent/agent_session_launch_screen.dart';
import 'package:anchor_learning/services/agent/agent_session_memory_index.dart';
import 'package:anchor_learning/services/agent/learning_agent_runtime_contracts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'ignores duplicate start actions while the first checkpoint is pending',
      (tester) async {
    final store = _LifecycleCheckpointStore(delayAllSaves: true);
    final executor = _LifecycleExecutor();

    await _pumpApp(tester, store: store, executor: executor);
    await _tapStart(tester);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(store.saveCount, 1);
    expect(executor.executeCount, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    store.completeAll();
    await tester.pump();
    expect(executor.executeCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not persist a tool checkpoint after route exit',
      (tester) async {
    final store = _LifecycleCheckpointStore();
    final executor = _LifecycleExecutor(
      resultCompleter: Completer<LearningAgentExecutionResult>(),
    );

    await _pumpApp(tester, store: store, executor: executor);
    await _tapStart(tester);
    await tester.pump();
    final executionContext = executor.lastContext;
    expect(executionContext, isNotNull);
    expect(store.saveCount, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await expectLater(
      executionContext!.persistToolStartCheckpoint(
        executionContext.initialState,
        executionContext.initialTraceEvents,
      ),
      throwsA(isA<Exception>()),
    );

    expect(store.saveCount, 1);
    executor.complete(_completedResult());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('aborts a pending tool checkpoint callback after route exit',
      (tester) async {
    final store = _LifecycleCheckpointStore();
    final executor = _LifecycleExecutor(
      resultCompleter: Completer<LearningAgentExecutionResult>(),
    );

    await _pumpApp(tester, store: store, executor: executor);
    await _tapStart(tester);
    await tester.pump();
    final executionContext = executor.lastContext!;
    store.delayNextSave = true;
    final callback = executionContext.persistToolStartCheckpoint(
      executionContext.initialState,
      executionContext.initialTraceEvents,
    );
    final callbackFinished = expectLater(callback, throwsA(isA<Exception>()));
    expect(store.saveCount, 2);
    expect(store.pendingCount, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    store.completeNext();
    await callbackFinished;
    executor.complete(_completedResult());
    await tester.pump();

    expect(store.saveCount, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not start the final checkpoint after executor route exit',
      (tester) async {
    final store = _LifecycleCheckpointStore();
    final executorCompleter = Completer<LearningAgentExecutionResult>();
    final executor = _LifecycleExecutor(resultCompleter: executorCompleter);

    await _pumpApp(tester, store: store, executor: executor);
    await _tapStart(tester);
    await tester.pump();
    expect(store.saveCount, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    executorCompleter.complete(_completedResult());
    await tester.pump();

    expect(store.saveCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'ignores duplicate completion actions while reflection save is pending',
      (tester) async {
    final store = _LifecycleCheckpointStore();
    final repository = _LifecycleLearningSessionRepository();
    final executor = _LifecycleExecutor();

    await _pumpApp(
      tester,
      store: store,
      executor: executor,
      sessionRepository: repository,
    );
    await _tapStart(tester);
    await tester.pumpAndSettle();
    await _scrollToText(tester, '完成并返回 Agent');

    store.delayNextSave = true;
    await tester.tap(find.text('完成并返回 Agent'));
    await tester.tap(find.text('完成并返回 Agent'));
    await tester.pump();

    expect(store.saveCount, 3);
    expect(store.pendingCount, 1);
    expect(repository.insertCount, 0);
    store.completeNext();
    await tester.pumpAndSettle();

    expect(repository.insertCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blocks restarting while reflection persistence owns the session',
      (tester) async {
    final store = _LifecycleCheckpointStore();
    final executor = _LifecycleExecutor();
    final repository = _LifecycleLearningSessionRepository();

    await _pumpApp(
      tester,
      store: store,
      executor: executor,
      sessionRepository: repository,
    );
    await _tapStart(tester);
    await tester.pumpAndSettle();
    await _scrollToText(tester, '完成并返回 Agent');
    await tester.scrollUntilVisible(
      find.byType(ElevatedButton),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    final restart =
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed!;
    await _scrollToText(tester, '完成并返回 Agent');

    store.delayNextSave = true;
    await tester.tap(find.text('完成并返回 Agent'));
    restart();
    await tester.pump();

    expect(store.saveCount, 3);
    expect(executor.executeCount, 1);
    expect(repository.insertCount, 0);
    await tester.scrollUntilVisible(
      find.byType(ElevatedButton),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );

    store.completeNext();
    await tester.pumpAndSettle();
    expect(repository.insertCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'does not insert a session after reflection checkpoint route exit',
      (tester) async {
    final store = _LifecycleCheckpointStore();
    final repository = _LifecycleLearningSessionRepository();
    final executor = _LifecycleExecutor();

    await _pumpApp(
      tester,
      store: store,
      executor: executor,
      sessionRepository: repository,
    );
    await _tapStart(tester);
    await tester.pumpAndSettle();
    await _scrollToText(tester, '完成并返回 Agent');

    store.delayNextSave = true;
    await tester.tap(find.text('完成并返回 Agent'));
    await tester.pump();
    expect(store.saveCount, 3);
    expect(store.pendingCount, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    store.completeNext();
    await tester.pump();

    expect(repository.insertCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ignores final checkpoint completion after route exit',
      (tester) async {
    final store = _LifecycleCheckpointStore();
    final executor = _LifecycleExecutor(
      resultCompleter: Completer<LearningAgentExecutionResult>(),
    );

    await _pumpApp(tester, store: store, executor: executor);
    await _tapStart(tester);
    await tester.pump();
    store.delayNextSave = true;
    executor.complete(LearningAgentExecutionResult.completed(
      step: _plan().sessionSummary.nextStep!,
    ));
    await tester.pump();
    expect(store.saveCount, 2);
    expect(store.pendingCount, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    store.completeNext();
    await tester.pump();

    expect(store.saveCount, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ignores session insert completion after route exit',
      (tester) async {
    final store = _LifecycleCheckpointStore();
    final insertCompleter = Completer<String>();
    final repository = _LifecycleLearningSessionRepository(
      insertCompleter: insertCompleter,
    );

    await _pumpApp(
      tester,
      store: store,
      executor: _LifecycleExecutor(),
      sessionRepository: repository,
    );
    await _tapStart(tester);
    await tester.pumpAndSettle();
    await _scrollToText(tester, '完成并返回 Agent');
    await tester.tap(find.text('完成并返回 Agent'));
    await tester.pump();
    expect(repository.insertCount, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    insertCompleter.complete('saved-session');
    await tester.pump();

    expect(repository.insertCount, 1);
    expect(store.saveCount, 3);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required _LifecycleCheckpointStore store,
  required _LifecycleExecutor executor,
  LearningSessionRepository? sessionRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        learningAgentCheckpointStoreProvider.overrideWithValue(store),
        learningAgentRuntimeProvider.overrideWithValue(
          LearningAgentRuntime(checkpointStore: store),
        ),
        learningAgentExecutorProvider.overrideWithValue(executor),
        if (sessionRepository != null)
          learningSessionRepositoryProvider
              .overrideWithValue(sessionRepository),
        agentSessionMemoryIndexProvider.overrideWith(
          (ref) async => AgentSessionMemoryIndex(const []),
        ),
      ],
      child: MaterialApp(home: AgentSessionLaunchScreen(plan: _plan())),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapStart(WidgetTester tester) async {
  final scrollable = find.byType(Scrollable).first;
  for (var i = 0; i < 30; i++) {
    if (find.byType(ElevatedButton).evaluate().isNotEmpty) break;
    final state = tester.state<ScrollableState>(scrollable);
    state.position.jumpTo(state.position.maxScrollExtent);
    await tester.pump();
  }
  final button = find.byType(ElevatedButton);
  expect(button, findsOneWidget);
  await tester.tap(button);
}

Future<void> _scrollToText(WidgetTester tester, String label) async {
  final target = find.text(label);
  final scrollable = find.byType(Scrollable).first;
  for (var i = 0; i < 30; i++) {
    if (target.evaluate().isNotEmpty &&
        tester.getCenter(target).dy >= 0 &&
        tester.getCenter(target).dy <= 600) {
      return;
    }
    final state = tester.state<ScrollableState>(scrollable);
    state.position.jumpTo(state.position.maxScrollExtent);
    await tester.pump();
  }
  expect(target, findsOneWidget);
}

LearningAgentExecutionResult _completedResult() {
  final plan = _plan();
  return LearningAgentExecutionResult.completed(
    step: plan.sessionSummary.nextStep!,
    shouldRefreshInputs: false,
  );
}

LearningAgentPlan _plan() {
  const step = LearningAgentPlanStep(
    type: LearningAgentStepType.importSources,
    title: '导入资料',
    description: '导入项目资料',
    enabled: true,
    targetCount: 1,
  );
  return const LearningAgentPlan(
    goal: LearningAgentGoal.projectWalkthrough,
    readiness: LearningAgentReadiness(
      evidenceBackedPointCount: 0,
      practiceablePointCount: 0,
      verifiedQuestionCount: 0,
      pendingQuestionCount: 0,
    ),
    memory: LearningAgentMemoryState(
      goalSessionCount: 0,
      goalOpenFollowUpCount: 0,
    ),
    steps: [step],
    sessionSummary: LearningAgentSessionSummary(
      goal: LearningAgentGoal.projectWalkthrough,
      nextStep: step,
      focusPoint: null,
      title: '导入资料',
      objective: '导入项目资料',
      targetLabel: '来源库',
      evidenceConstraint: '导入内容必须可追溯',
      memoryReminder: null,
      successCriteria: ['导入一份资料'],
      reflectionPrompts: ['资料是否已准备好？'],
    ),
  );
}

class _LifecycleCheckpointStore implements LearningAgentCheckpointStore {
  final bool delayAllSaves;
  bool delayNextSave = false;
  int saveCount = 0;
  LearningAgentCheckpoint? savedCheckpoint;
  final List<Completer<LearningAgentCheckpoint>> _pending = [];
  final List<LearningAgentCheckpoint> _pendingCheckpoints = [];

  _LifecycleCheckpointStore({this.delayAllSaves = false});

  int get pendingCount => _pending.length;

  @override
  Future<LearningAgentCheckpoint> save(
    LearningAgentCheckpoint checkpoint,
  ) {
    saveCount += 1;
    final revision = savedCheckpoint?.sessionId == checkpoint.sessionId
        ? savedCheckpoint!.revision
        : 0;
    final saved = checkpoint.withRevision(revision + 1);
    if (delayAllSaves || delayNextSave) {
      delayNextSave = false;
      final completer = Completer<LearningAgentCheckpoint>();
      _pending.add(completer);
      _pendingCheckpoints.add(saved);
      return completer.future;
    }
    savedCheckpoint = saved;
    return Future.value(saved);
  }

  void completeNext() {
    final completer = _pending.removeAt(0);
    savedCheckpoint = _pendingCheckpoints.removeAt(0);
    completer.complete(savedCheckpoint);
  }

  void completeAll() {
    while (_pending.isNotEmpty) {
      completeNext();
    }
  }

  @override
  Future<LearningAgentCheckpoint?> load(String sessionId) async => null;

  @override
  Future<List<LearningAgentCheckpoint>> loadActive({int limit = 20}) async =>
      savedCheckpoint == null ? const [] : [savedCheckpoint!];

  @override
  Future<void> delete(String sessionId) async {}
}

class _LifecycleExecutor implements LearningAgentExecutor {
  final Completer<LearningAgentExecutionResult>? resultCompleter;
  int executeCount = 0;
  LearningAgentExecutionContext? lastContext;

  _LifecycleExecutor({this.resultCompleter});

  @override
  Future<LearningAgentExecutionResult> execute(
    LearningAgentExecutionContext context,
  ) {
    executeCount += 1;
    lastContext = context;
    return resultCompleter?.future ?? Future.value(_completedResult());
  }

  void complete(LearningAgentExecutionResult result) {
    resultCompleter?.complete(result);
  }
}

class _LifecycleLearningSessionRepository extends LearningSessionRepository {
  final Completer<String>? insertCompleter;
  int insertCount = 0;

  _LifecycleLearningSessionRepository({this.insertCompleter})
      : super(DatabaseHelper());

  @override
  Future<String> insertLearningSession(LearningSession session) async {
    insertCount += 1;
    if (insertCompleter != null) return insertCompleter!.future;
    return session.id;
  }
}
