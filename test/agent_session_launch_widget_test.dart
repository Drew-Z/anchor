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
      'does not execute the agent until the initial checkpoint can be saved',
      (tester) async {
    final store = _TestCheckpointStore(failNextSave: true);
    final executor = _RecordingExecutor();

    await tester.pumpWidget(
      _app(
        plan: _plan(),
        store: store,
        executor: executor,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await _tapStart(tester);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Agent 运行状态保存失败'), findsOneWidget);
    expect(find.textContaining('disk unavailable'), findsOneWidget);
    expect(find.text('重试创建并启动'), findsOneWidget);
    expect(executor.executeCount, 0);
    expect(store.saveCount, 1);

    await _tapText(tester, '重试创建并启动');
    await tester.pumpAndSettle();

    expect(executor.executeCount, 1);
    expect(store.saveCount, 3);
    expect(find.text('Agent 运行状态保存失败'), findsNothing);
  });

  testWidgets('ignores a delayed execution result after the page is removed',
      (tester) async {
    final store = _TestCheckpointStore();
    final executionCompleter = Completer<LearningAgentExecutionResult>();
    final executor =
        _RecordingExecutor(resultFuture: executionCompleter.future);

    await tester.pumpWidget(
      _app(
        plan: _plan(),
        store: store,
        executor: executor,
      ),
    );
    await tester.pumpAndSettle();

    await _tapStart(tester);
    await tester.pump();
    expect(executor.executeCount, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    executionCompleter.complete(
      LearningAgentExecutionResult.completed(
        step: _plan().sessionSummary.nextStep!,
        shouldRefreshInputs: false,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a retry after execution failure and recovers',
      (tester) async {
    final store = _TestCheckpointStore();
    final plan = _plan();
    final executor = _RecordingExecutor(
      results: [
        LearningAgentExecutionResult.failed(
          step: plan.sessionSummary.nextStep,
          message: 'tool exploded',
        ),
        LearningAgentExecutionResult.completed(
          step: plan.sessionSummary.nextStep!,
          shouldRefreshInputs: false,
        ),
      ],
    );

    await tester.pumpWidget(
      _app(plan: plan, store: store, executor: executor),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await _tapStart(tester);
    await tester.pumpAndSettle();

    expect(executor.executeCount, 1);
    expect(find.textContaining('启动失败'), findsOneWidget);
    expect(find.textContaining('tool exploded'), findsNWidgets(2));
    expect(find.text('重新启动'), findsOneWidget);

    await _tapText(tester, '重新启动');
    await tester.pumpAndSettle();

    expect(executor.executeCount, 2);
    expect(find.text('启动失败'), findsNothing);
    await _scrollToText(tester, '完成并返回 Agent');
    expect(find.text('完成并返回 Agent'), findsOneWidget);
  });

  testWidgets('keeps a canceled execution neutral without showing completion',
      (tester) async {
    final store = _TestCheckpointStore();
    final plan = _plan();
    final executor = _RecordingExecutor(
      results: [
        LearningAgentExecutionResult.canceled(
          step: plan.sessionSummary.nextStep,
          message: '用户取消了本轮执行',
        ),
      ],
    );

    await tester.pumpWidget(
      _app(plan: plan, store: store, executor: executor),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await _tapStart(tester);
    await tester.pumpAndSettle();

    expect(executor.executeCount, 1);
    expect(find.text('用户取消了本轮执行'), findsOneWidget);
    expect(find.text('启动失败'), findsNothing);
    expect(find.text('本轮学习已返回'), findsNothing);
    expect(find.text('完成并返回 Agent'), findsNothing);
  });

  testWidgets('shows completion review after a successful execution',
      (tester) async {
    final store = _TestCheckpointStore();
    final plan = _plan();
    final executor = _RecordingExecutor(
      results: [
        LearningAgentExecutionResult.completed(
          step: plan.sessionSummary.nextStep!,
          shouldRefreshInputs: false,
        ),
      ],
    );

    await tester.pumpWidget(
      _app(plan: plan, store: store, executor: executor),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await _tapStart(tester);
    await tester.pumpAndSettle();

    expect(executor.executeCount, 1);
    await _scrollToText(tester, '本轮学习已返回');
    expect(find.text('本轮学习已返回'), findsOneWidget);
    expect(find.textContaining('复盘问题：'), findsOneWidget);
    await _scrollToText(tester, '完成并返回 Agent');
    expect(find.text('完成并返回 Agent'), findsOneWidget);
  });

  testWidgets('retries reflection persistence without losing the review',
      (tester) async {
    final store = _TestCheckpointStore();
    final repository =
        _RecordingLearningSessionRepository(failNextInsert: true);
    final plan = _plan();

    await tester.pumpWidget(
      _app(
        plan: plan,
        store: store,
        executor: _RecordingExecutor(),
        sessionRepository: repository,
      ),
    );
    await tester.pumpAndSettle();
    await _tapStart(tester);
    await tester.pumpAndSettle();

    await _scrollToText(tester, '完成并返回 Agent');
    await _scrollToText(tester, '下次最想让 Agent 追问什么');
    await tester.enterText(find.byType(TextField).first, '下轮继续核验来源');
    await _scrollToText(tester, '写下本轮学到了什么、哪里还卡、下次要追问什么');
    await tester.enterText(find.byType(TextField).last, '本轮资料已具备追溯信息');
    await _tapText(tester, '完成并返回 Agent');
    await tester.pumpAndSettle();

    expect(repository.insertCount, 1);
    expect(
        find.textContaining('session database unavailable'), findsNWidgets(2));
    await _scrollToText(tester, '重新保存复盘');
    expect(find.text('重新保存复盘'), findsOneWidget);

    await _tapText(tester, '重新保存复盘');
    await tester.pumpAndSettle();

    expect(repository.insertCount, 2);
    expect(repository.savedSessions, hasLength(1));
    expect(
      repository.savedSessions.single.summary,
      allOf(
        contains('下次追问: 下轮继续核验来源'),
        contains('复盘: 本轮资料已具备追溯信息'),
      ),
    );
  });
}

Future<void> _tapStart(WidgetTester tester) async {
  final scrollable = find.byType(Scrollable).first;
  for (var i = 0; i < 30; i++) {
    final state = tester.state<ScrollableState>(scrollable);
    state.position.jumpTo(state.position.maxScrollExtent);
    await tester.pump();
    if (find.byType(ElevatedButton).evaluate().isNotEmpty) break;
  }
  expect(find.byType(ElevatedButton), findsOneWidget);
  await tester.tap(find.byType(ElevatedButton));
}

Future<void> _tapText(WidgetTester tester, String label) async {
  await _scrollToText(tester, label);
  await tester.tap(find.text(label));
}

Future<void> _scrollToText(WidgetTester tester, String label) async {
  final target = find.text(label);
  final scrollable = find.byType(Scrollable).first;
  for (var i = 0; i < 30; i++) {
    if (target.evaluate().isNotEmpty &&
        tester.getCenter(target).dy >= 0 &&
        tester.getCenter(target).dy <= 600) {
      break;
    }
    final state = tester.state<ScrollableState>(scrollable);
    state.position.jumpTo(state.position.maxScrollExtent);
    await tester.pump();
  }
}

Widget _app({
  required LearningAgentPlan plan,
  required _TestCheckpointStore store,
  required _RecordingExecutor executor,
  LearningSessionRepository? sessionRepository,
}) {
  return ProviderScope(
    overrides: [
      learningAgentCheckpointStoreProvider.overrideWithValue(store),
      learningAgentRuntimeProvider.overrideWithValue(
        LearningAgentRuntime(checkpointStore: store),
      ),
      learningAgentExecutorProvider.overrideWithValue(executor),
      if (sessionRepository != null)
        learningSessionRepositoryProvider.overrideWithValue(sessionRepository),
      agentSessionMemoryIndexProvider.overrideWith(
        (ref) async => AgentSessionMemoryIndex(const []),
      ),
    ],
    child: MaterialApp(
      home: AgentSessionLaunchScreen(plan: plan),
    ),
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

class _TestCheckpointStore implements LearningAgentCheckpointStore {
  bool failNextSave;
  int saveCount = 0;
  LearningAgentCheckpoint? savedCheckpoint;

  _TestCheckpointStore({this.failNextSave = false});

  @override
  Future<LearningAgentCheckpoint> save(
    LearningAgentCheckpoint checkpoint,
  ) async {
    saveCount += 1;
    if (failNextSave) {
      failNextSave = false;
      throw StateError('disk unavailable');
    }
    final revision = savedCheckpoint?.sessionId == checkpoint.sessionId
        ? savedCheckpoint!.revision
        : 0;
    final saved = checkpoint.withRevision(revision + 1);
    savedCheckpoint = saved;
    return saved;
  }

  @override
  Future<LearningAgentCheckpoint?> load(String sessionId) async => null;

  @override
  Future<List<LearningAgentCheckpoint>> loadActive({int limit = 20}) async {
    return savedCheckpoint == null ? const [] : [savedCheckpoint!];
  }

  @override
  Future<void> delete(String sessionId) async {}
}

class _RecordingExecutor implements LearningAgentExecutor {
  final Future<LearningAgentExecutionResult>? resultFuture;
  final List<LearningAgentExecutionResult>? results;
  int executeCount = 0;

  _RecordingExecutor({this.resultFuture, this.results});

  @override
  Future<LearningAgentExecutionResult> execute(
    LearningAgentExecutionContext context,
  ) {
    executeCount += 1;
    if (results != null && results!.isNotEmpty) {
      return Future.value(
          results![(executeCount - 1).clamp(0, results!.length - 1)]);
    }
    return resultFuture ??
        Future.value(
          LearningAgentExecutionResult.completed(
            step: context.plan.sessionSummary.nextStep!,
            shouldRefreshInputs: false,
          ),
        );
  }
}

class _RecordingLearningSessionRepository extends LearningSessionRepository {
  bool failNextInsert;
  int insertCount = 0;
  final List<LearningSession> savedSessions = [];

  _RecordingLearningSessionRepository({this.failNextInsert = false})
      : super(DatabaseHelper());

  @override
  Future<String> insertLearningSession(LearningSession session) async {
    insertCount += 1;
    if (failNextInsert) {
      failNextInsert = false;
      throw StateError('session database unavailable');
    }
    savedSessions.add(session);
    return session.id;
  }
}
