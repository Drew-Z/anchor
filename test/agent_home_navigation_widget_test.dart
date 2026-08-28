import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/data/models/learning_session.dart';
import 'package:anchor_learning/features/agent/agent_home_screen.dart';
import 'package:anchor_learning/features/agent/agent_session_detail_screen.dart';
import 'package:anchor_learning/features/agent/agent_session_history_screen.dart';
import 'package:anchor_learning/features/agent/agent_session_launch_screen.dart';
import 'package:anchor_learning/services/agent/agent_session_memory_index.dart';
import 'package:anchor_learning/services/agent/learning_agent_memory_record.dart';
import 'package:anchor_learning/services/agent/learning_agent_runtime_contracts.dart';
import 'package:anchor_learning/services/agent/learning_agent_workspace.dart';
import 'package:anchor_learning/services/agent/project_interview_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/disabled_privacy_preferences_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'learning_agent_goal': LearningAgentGoal.projectWalkthrough.value,
    });
  });

  testWidgets('workspace next action opens the Agent launch screen',
      (tester) async {
    final store = _MemoryCheckpointStore();
    await _pumpHome(tester, store: store);

    await _tapVisibleText(tester, '执行下一步');
    await tester.pumpAndSettle();

    expect(find.byType(AgentSessionLaunchScreen), findsOneWidget);
    expect(find.text('Agent Session'), findsOneWidget);
  });

  testWidgets('recent Agent Session opens its detail screen', (tester) async {
    final store = _MemoryCheckpointStore();
    final session = _session();
    await _pumpHome(
      tester,
      store: store,
      memory: AgentSessionMemoryIndex([session]),
    );

    await _tapVisibleText(tester, '讲清项目细节 · 首页导航回归会话');
    await tester.pumpAndSettle();

    expect(find.byType(AgentSessionDetailScreen), findsOneWidget);
    expect(find.text('Agent Session 复盘'), findsOneWidget);
    expect(find.text('首页导航回归目标'), findsWidgets);
  });

  testWidgets('empty recent Agent Session opens the full history screen',
      (tester) async {
    final store = _MemoryCheckpointStore();
    await _pumpHome(tester, store: store);

    await _tapVisibleText(tester, '查看 Agent Session 历史');
    await tester.pumpAndSettle();

    expect(find.byType(AgentSessionHistoryScreen), findsOneWidget);
    expect(find.text('Agent Session 历史'), findsOneWidget);
    expect(find.text('完成 Agent Session 后，这里会出现完整历史'), findsOneWidget);
  });

  testWidgets('unfinished checkpoint resumes into the launch screen',
      (tester) async {
    final plan = _plan();
    final store = _MemoryCheckpointStore(checkpoint: _checkpoint(plan));
    await _pumpHome(tester, store: store, plan: plan);

    await _tapVisibleText(tester, '继续会话');
    await tester.pumpAndSettle();

    expect(find.byType(AgentSessionLaunchScreen), findsOneWidget);
    expect(find.textContaining('已恢复本地会话'), findsOneWidget);
    expect(store.saveCount, 1);
  });

  testWidgets('checkpoint deletion confirms and refreshes the home screen',
      (tester) async {
    final plan = _plan();
    final store = _MemoryCheckpointStore(checkpoint: _checkpoint(plan));
    await _pumpHome(tester, store: store, plan: plan);

    await _scrollTo(tester, find.byTooltip('删除未完成会话'));
    await tester.tap(find.byTooltip('删除未完成会话'));
    await tester.pumpAndSettle();

    expect(find.text('删除未完成会话？'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '删除'));
    await tester.pumpAndSettle();

    expect(store.deletedSessionIds, ['checkpoint-session']);
    expect(find.text('未完成 Agent Session'), findsNothing);
    expect(find.text('未完成 Agent Session 已删除。'), findsOneWidget);
  });

  testWidgets('unknown tool outcome can be confirmed and resumed for review',
      (tester) async {
    final plan = _plan();
    final store = _MemoryCheckpointStore(
      checkpoint: _unknownOutcomeCheckpoint(plan),
    );
    await _pumpHome(tester, store: store, plan: plan);

    await _tapVisibleText(tester, '确认工具结果');
    await tester.pumpAndSettle();

    expect(find.text('确认工具执行结果'), findsOneWidget);
    expect(find.textContaining('最终结果尚未保存'), findsNWidgets(2));
    expect(find.text('Operation：operation-import-1'), findsOneWidget);
    expect(find.text('Attempt：event-tool-started'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '已在来源库确认导入结果');
    await tester.tap(find.widgetWithText(TextButton, '确认已完成'));
    await tester.pumpAndSettle();

    expect(find.byType(AgentSessionLaunchScreen), findsOneWidget);
    expect(find.textContaining('已恢复本地会话'), findsOneWidget);
    expect(store.saveCount, 2);
    expect(store.checkpoint!.state.phase, LearningAgentPhase.reflect);
    expect(store.checkpoint!.state.pendingUserDecision, isNull);
  });

  testWidgets('pending tool decision can end the unfinished session',
      (tester) async {
    final plan = _plan();
    final store = _MemoryCheckpointStore(
      checkpoint: _unknownOutcomeCheckpoint(plan),
    );
    await _pumpHome(tester, store: store, plan: plan);

    await _tapVisibleText(tester, '确认工具结果');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '结束会话'));
    await tester.pumpAndSettle();

    expect(find.byType(AgentSessionLaunchScreen), findsNothing);
    expect(find.text('Agent Session 已结束，决策与执行轨迹已保存。'), findsOneWidget);
    expect(store.saveCount, 1);
    expect(store.checkpoint!.state.phase, LearningAgentPhase.canceled);
    expect(store.checkpoint!.state.pendingUserDecision, isNull);
  });

  testWidgets('workspace read failure retries and recovers', (tester) async {
    var shouldFail = true;
    final workspace = LearningAgentWorkspaceSnapshot(
      plan: _plan(),
      memory: const LearningAgentMemorySnapshot(),
      toolTargets: const [],
    );
    await _pumpHome(
      tester,
      store: _MemoryCheckpointStore(),
      workspaceLoader: (ref, goal) async {
        if (shouldFail) throw StateError('workspace unavailable');
        return workspace;
      },
    );

    expect(find.textContaining('Agent 工作台读取失败'), findsOneWidget);
    shouldFail = false;
    await _tapVisibleText(tester, '重试读取工作台');
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text('执行下一步'));
    expect(find.text('执行下一步'), findsOneWidget);
  });

  testWidgets('active checkpoint read failure retries and recovers',
      (tester) async {
    var attempts = 0;
    final store = _MemoryCheckpointStore();
    await _pumpHome(
      tester,
      store: store,
      checkpointLoader: (ref) async {
        attempts += 1;
        if (attempts == 1) throw StateError('checkpoint unavailable');
        return store.loadActive();
      },
    );

    expect(find.textContaining('未完成 Agent 会话读取失败'), findsOneWidget);
    await _tapVisibleText(tester, '重试读取会话');
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.textContaining('未完成 Agent 会话读取失败'), findsNothing);
  });

  testWidgets('project interview outcome read failure retries and recovers',
      (tester) async {
    var attempts = 0;
    await _pumpHome(
      tester,
      store: _MemoryCheckpointStore(),
      outcomeLoader: (ref) async {
        attempts += 1;
        if (attempts == 1) throw StateError('outcome unavailable');
        return ProjectInterviewOutcome(
          generatedAt: DateTime(2026, 8, 23),
          goal: 'Agent home navigation test',
          scope: const [],
          projectTitles: const [],
          units: const [],
        );
      },
    );

    expect(find.text('重新读取项目面试成果'), findsOneWidget);
    await tester.tap(find.text('重新读取项目面试成果'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('项目面试成果'), findsOneWidget);
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required _MemoryCheckpointStore store,
  LearningAgentPlan? plan,
  AgentSessionMemoryIndex? memory,
  Future<LearningAgentWorkspaceSnapshot> Function(Ref, LearningAgentGoal)?
      workspaceLoader,
  Future<List<LearningAgentCheckpoint>> Function(Ref)? checkpointLoader,
  Future<ProjectInterviewOutcome> Function(Ref)? outcomeLoader,
}) async {
  final activePlan = plan ?? _plan();
  final workspace = LearningAgentWorkspaceSnapshot(
    plan: activePlan,
    memory: const LearningAgentMemorySnapshot(),
    toolTargets: const [],
  );
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        privacyPreferencesStoreProvider.overrideWithValue(
          const DisabledPrivacyPreferencesStore(),
        ),
        learningAgentWorkspaceProvider.overrideWith(
          workspaceLoader ?? (ref, goal) async => workspace,
        ),
        learningAgentCheckpointStoreProvider.overrideWithValue(store),
        learningAgentRuntimeProvider.overrideWithValue(
          LearningAgentRuntime(checkpointStore: store),
        ),
        learningAgentActiveCheckpointListProvider.overrideWith(
          checkpointLoader ?? (ref) => store.loadActive(),
        ),
        agentSessionMemoryIndexProvider.overrideWith(
          (ref) async => memory ?? AgentSessionMemoryIndex(const []),
        ),
        interviewSessionListProvider.overrideWith((ref) async => const []),
        tutorSessionListProvider.overrideWith((ref) async => const []),
        knowledgeAnswerSessionListProvider.overrideWith(
          (ref) async => const [],
        ),
        projectInterviewOutcomeProvider.overrideWith(
          outcomeLoader ??
              (ref) async => ProjectInterviewOutcome(
                    generatedAt: DateTime(2026, 8, 23),
                    goal: 'Agent home navigation test',
                    scope: const [],
                    projectTitles: const [],
                    units: const [],
                  ),
        ),
      ],
      child: const MaterialApp(home: AgentHomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapVisibleText(WidgetTester tester, String label) async {
  final target = find.text(label);
  await _scrollTo(tester, target);
  await tester.tap(target);
}

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    240,
    scrollable: find.byType(Scrollable).first,
  );
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

LearningAgentPlan _plan() {
  const step = LearningAgentPlanStep(
    type: LearningAgentStepType.importSources,
    title: '导入项目资料',
    description: '为项目讲解导入一份可追溯资料',
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
      title: '导入项目资料',
      objective: '建立可追溯的项目上下文',
      targetLabel: '项目来源库',
      evidenceConstraint: '导入内容必须保留来源',
      memoryReminder: null,
      successCriteria: ['导入一份资料'],
      reflectionPrompts: ['资料是否可追溯？'],
    ),
  );
}

LearningAgentCheckpoint _checkpoint(LearningAgentPlan plan) {
  final runtime = LearningAgentRuntime(
    checkpointStore: _MemoryCheckpointStore(),
  );
  final session = runtime.prepareSession(
    plan: plan,
    startedAt: DateTime(2026, 8, 23, 10),
  );
  final state = session.state.copyWith(sessionId: 'checkpoint-session');
  final events = session.traceEvents
      .map(
        (event) => LearningAgentTraceEvent(
          id: event.id,
          sessionId: 'checkpoint-session',
          goal: event.goal,
          type: event.type,
          level: event.level,
          occurredAt: event.occurredAt,
          phase: event.phase,
          targetId: event.targetId,
          targetLabel: event.targetLabel,
          toolId: event.toolId,
          summary: event.summary,
          detail: event.detail,
        ),
      )
      .toList();
  return LearningAgentCheckpoint(
    state: state,
    traceEvents: events,
    plan: plan,
    revision: 1,
  );
}

LearningAgentCheckpoint _unknownOutcomeCheckpoint(LearningAgentPlan plan) {
  final base = _checkpoint(plan);
  const operationId = 'operation-import-1';
  const attemptId = 'event-tool-started';
  final input = LearningAgentToolInputSnapshot(
    toolId: LearningAgentToolId.importSources.value,
    targetId: base.state.targetId,
  );
  final request = LearningAgentUserDecisionRequest.toolOutcomeUnknown(
    sessionId: base.sessionId,
    toolTitle: '导入来源',
    toolId: LearningAgentToolId.importSources.value,
    operationId: operationId,
    attemptId: attemptId,
    requestedAt: DateTime(2026, 8, 23, 10, 1),
  );
  final state = base.state.copyWith(
    phase: LearningAgentPhase.act,
    activeToolOperationId: operationId,
    activeToolInputSnapshot: input,
    pendingUserDecision: request,
  );
  final event = LearningAgentTraceEvent(
    id: attemptId,
    sessionId: base.sessionId,
    goal: state.goal,
    type: LearningAgentTraceEventType.toolStarted,
    occurredAt: DateTime(2026, 8, 23, 10, 1),
    phase: LearningAgentPhase.act,
    targetId: state.targetId,
    targetLabel: plan.sessionSummary.targetLabel,
    toolId: LearningAgentToolId.importSources.value,
    summary: '开始导入来源',
  );
  return LearningAgentCheckpoint(
    state: state,
    traceEvents: [event],
    plan: plan,
    revision: base.revision,
  );
}

LearningSession _session() {
  final startedAt = DateTime(2026, 8, 23, 9);
  return LearningSession(
    id: 'home-session',
    mode: LearningSessionMode.agentSession,
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(minutes: 4)),
    summary: [
      '讲清项目细节 · 首页导航回归会话',
      '目标: 首页导航回归目标',
      '成功标准: 能打开复盘详情',
    ].join('\n'),
  );
}

class _MemoryCheckpointStore implements LearningAgentCheckpointStore {
  LearningAgentCheckpoint? checkpoint;
  int saveCount = 0;
  final List<String> deletedSessionIds = [];

  _MemoryCheckpointStore({this.checkpoint});

  @override
  Future<void> delete(String sessionId) async {
    deletedSessionIds.add(sessionId);
    if (checkpoint?.sessionId == sessionId) checkpoint = null;
  }

  @override
  Future<LearningAgentCheckpoint?> load(String sessionId) async {
    return checkpoint?.sessionId == sessionId ? checkpoint : null;
  }

  @override
  Future<List<LearningAgentCheckpoint>> loadActive({int limit = 20}) async {
    return checkpoint == null ? const [] : [checkpoint!];
  }

  @override
  Future<LearningAgentCheckpoint> save(
    LearningAgentCheckpoint candidate,
  ) async {
    final currentRevision =
        checkpoint?.sessionId == candidate.sessionId ? checkpoint!.revision : 0;
    if (candidate.revision != currentRevision) {
      throw LearningAgentCheckpointConflictException(
        sessionId: candidate.sessionId,
        expectedRevision: candidate.revision,
        actualRevision: currentRevision,
      );
    }
    saveCount += 1;
    checkpoint = candidate.withRevision(currentRevision + 1);
    return checkpoint!;
  }
}
