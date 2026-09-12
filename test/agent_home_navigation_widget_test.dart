import 'dart:async';

import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/data/database/database_helper.dart';
import 'package:anchor_learning/data/models/knowledge_point.dart';
import 'package:anchor_learning/data/models/learning_session.dart';
import 'package:anchor_learning/data/repositories/knowledge_point_repository.dart';
import 'package:anchor_learning/features/agent/agent_home_screen.dart';
import 'package:anchor_learning/features/agent/agent_session_detail_screen.dart';
import 'package:anchor_learning/features/agent/agent_session_history_screen.dart';
import 'package:anchor_learning/features/agent/agent_session_launch_screen.dart';
import 'package:anchor_learning/features/knowledge_base/knowledge_base_screen.dart';
import 'package:anchor_learning/services/agent/agent_session_memory_index.dart';
import 'package:anchor_learning/services/agent/learning_agent_memory_record.dart';
import 'package:anchor_learning/services/agent/learning_agent_runtime_contracts.dart';
import 'package:anchor_learning/services/agent/learning_agent_workspace.dart';
import 'package:anchor_learning/services/agent/project_interview_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  for (final textScale in [1.0, 2.0]) {
    testWidgets('plan labels and disclosure remain readable at ${textScale}x',
        (tester) async {
      final plan = _plan();
      await _pumpHome(
        tester,
        store: _MemoryCheckpointStore(),
        plan: plan,
        viewport: Size(textScale == 1 ? 390 : 320, 844),
        textScale: textScale,
      );

      for (final label in [
        '${plan.goal.label}路线',
        '知识范围：${plan.knowledgeScope.label}',
        '已核验练习 0',
        '执行下一步',
      ]) {
        final target = find.text(label);
        await _scrollTo(tester, target);
        expect(tester.renderObject<RenderParagraph>(target).didExceedMaxLines,
            isFalse,
            reason: '$label must remain readable at ${textScale}x');
        final bounds = tester.getRect(target);
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(tester.view.physicalSize.width));
      }

      await _tapVisibleText(tester, '计划依据');
      await tester.pumpAndSettle();
      await _scrollTo(tester, find.text('建立可追溯的项目上下文'));
      expect(find.text('建立可追溯的项目上下文'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('expanded plan evidence remains readable at ${textScale}x',
        (tester) async {
      final plan = _planWithDetailedEvidence();
      final store = _MemoryCheckpointStore();
      await _pumpHome(
        tester,
        store: store,
        plan: plan,
        viewport: Size(textScale == 1 ? 390 : 320, 844),
        textScale: textScale,
      );

      final disclosure = find.widgetWithText(ExpansionTile, '计划依据');
      final summary = plan.sessionSummary;
      final point = plan.focusPoints.single;
      final labels = [
        '当前 Agent Session：${summary.title}',
        summary.objective,
        '目标：${summary.targetLabel}',
        '来源约束：${summary.evidenceConstraint}',
        '学习记忆：${summary.memoryReminder}',
        point.title,
        '${point.reason} · 掌握 ${point.masteryLevel}% · '
            '面试 ${point.interviewRelevance}',
        '证据 ${point.evidenceChunkCount}',
        '可练习 ${point.verifiedPracticeTargetCount}',
      ];
      final title = find.descendant(
        of: disclosure,
        matching: find.text(labels.first),
      );
      expect(title, findsNothing);

      await _tapVisibleText(tester, '计划依据');
      await tester.pumpAndSettle();
      for (final label in labels) {
        final target = find.descendant(
          of: disclosure,
          matching: find.text(label),
        );
        await _scrollTo(tester, target);
        expect(tester.renderObject<RenderParagraph>(target).didExceedMaxLines,
            isFalse,
            reason: '$label must remain readable at ${textScale}x');
        final bounds = tester.getRect(target);
        final disclosureBounds = tester.getRect(disclosure);
        expect(bounds.left, greaterThanOrEqualTo(disclosureBounds.left));
        expect(bounds.right, lessThanOrEqualTo(disclosureBounds.right));
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(tester.view.physicalSize.width));
      }

      await _tapVisibleText(tester, '计划依据');
      await tester.pumpAndSettle();
      expect(title, findsNothing);
      await _tapVisibleText(tester, '计划依据');
      await tester.pumpAndSettle();
      expect(title, findsOneWidget);
      expect(store.saveCount, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('unfinished checkpoint card remains readable at ${textScale}x',
        (tester) async {
      final plan = _plan();
      final checkpoint = _unknownOutcomeCheckpoint(plan);
      await _pumpHome(
        tester,
        store: _MemoryCheckpointStore(checkpoint: checkpoint),
        plan: plan,
        viewport: Size(textScale == 1 ? 390 : 320, 844),
        textScale: textScale,
      );

      for (final target in [
        find.text('未完成 Agent Session'),
        find.text(checkpoint.state.phase.label),
        find.text('${plan.goal.label} · 导入来源'),
        find.textContaining('最终结果尚未保存'),
        find.text('确认工具结果'),
      ]) {
        await _scrollTo(tester, target);
        expect(tester.renderObject<RenderParagraph>(target).didExceedMaxLines,
            isFalse,
            reason: 'checkpoint content must remain readable at ${textScale}x');
        final bounds = tester.getRect(target);
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(tester.view.physicalSize.width));
      }

      final title = find.text('未完成 Agent Session');
      await _scrollTo(tester, title);
      final paragraph = tester.renderObject<RenderParagraph>(title);
      final titleText = paragraph.text.toPlainText();
      for (final word in ['Agent', 'Session']) {
        final start = titleText.indexOf(word);
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: start, extentOffset: start + word.length),
        );
        expect(boxes, hasLength(1),
            reason: '$word must stay on one line at ${textScale}x');
      }
      expect(tester.takeException(), isNull);
    });
  }

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

  testWidgets('workspace checkpoint lookup failure can retry', (tester) async {
    final checkpoint = _checkpoint(_plan());
    final store = _MemoryCheckpointStore(checkpoint: checkpoint)
      ..failNextLoad = true;
    await _pumpHome(tester, store: store, plan: _resumePlan(checkpoint));

    await _tapVisibleText(tester, '继续未完成会话');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('未完成会话读取失败'), findsOneWidget);
    expect(find.byType(AgentSessionLaunchScreen), findsNothing);
    expect(store.saveCount, 0);

    await _tapVisibleText(tester, '继续未完成会话');
    await tester.pumpAndSettle();
    expect(find.byType(AgentSessionLaunchScreen), findsOneWidget);
    expect(store.loadCount, 2);
    expect(store.saveCount, 1);
    expect(store.checkpoint!.plan, same(checkpoint.plan));
  });

  testWidgets('late checkpoint lookup ignores a replaced home route',
      (tester) async {
    final checkpoint = _checkpoint(_plan());
    final pending = Completer<LearningAgentCheckpoint?>();
    final store = _MemoryCheckpointStore(checkpoint: checkpoint)
      ..nextLoad = pending;
    final navigatorKey = GlobalKey<NavigatorState>();
    await _pumpHome(
      tester,
      store: store,
      plan: _resumePlan(checkpoint),
      navigatorKey: navigatorKey,
    );
    await _tapVisibleText(tester, '继续未完成会话');
    await tester.pump();
    await _replaceHomeRoute(tester, navigatorKey);

    pending.complete(checkpoint);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Returned from Agent home'), findsOneWidget);
    expect(find.byType(AgentSessionLaunchScreen), findsNothing);
    expect(store.saveCount, 0);
  });

  testWidgets('late checkpoint lookup failure ignores a disposed scope',
      (tester) async {
    final checkpoint = _checkpoint(_plan());
    final pending = Completer<LearningAgentCheckpoint?>();
    final store = _MemoryCheckpointStore(checkpoint: checkpoint)
      ..nextLoad = pending;
    await _pumpHome(tester, store: store, plan: _resumePlan(checkpoint));
    await _tapVisibleText(tester, '继续未完成会话');
    await tester.pumpWidget(const SizedBox.shrink());

    pending.completeError(StateError('late checkpoint lookup failure'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(store.saveCount, 0);
  });

  testWidgets('missing workspace checkpoint keeps the existing recovery path',
      (tester) async {
    final store = _MemoryCheckpointStore();
    await _pumpHome(
      tester,
      store: store,
      plan: _resumePlan(_checkpoint(_plan())),
    );
    await _tapVisibleText(tester, '继续未完成会话');
    await tester.pumpAndSettle();

    expect(find.text('未完成会话已不存在，正在重新规划下一动作。'), findsOneWidget);
    expect(find.byType(AgentSessionLaunchScreen), findsNothing);
    expect(store.loadCount, 1);
    expect(store.saveCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('focus point lookup failure can retry', (tester) async {
    final plan = _planWithDetailedEvidence();
    final point = _knowledgePoint(plan.focusPoints.single);
    final repository = _ReadControlledKnowledgePointRepository(point)
      ..failNextRead = true;
    await _pumpHome(
      tester,
      store: _MemoryCheckpointStore(),
      plan: plan,
      pointRepository: repository,
    );
    await _tapVisibleText(tester, '计划依据');
    await _tapVisibleText(tester, plan.focusPoints.single.title);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('知识点读取失败'), findsOneWidget);
    expect(find.byType(KnowledgePointDetailScreen), findsNothing);
    await _tapVisibleText(tester, plan.focusPoints.single.title);
    await tester.pumpAndSettle();
    expect(find.byType(KnowledgePointDetailScreen), findsOneWidget);
    expect(
        tester
            .widget<KnowledgePointDetailScreen>(
              find.byType(KnowledgePointDetailScreen),
            )
            .point,
        same(point));
    expect(repository.readCount, 2);
  });

  testWidgets('late focus point lookup ignores a replaced home route',
      (tester) async {
    final plan = _planWithDetailedEvidence();
    final point = _knowledgePoint(plan.focusPoints.single);
    final pending = Completer<KnowledgePoint?>();
    final repository = _ReadControlledKnowledgePointRepository(point)
      ..nextRead = pending;
    final navigatorKey = GlobalKey<NavigatorState>();
    await _pumpHome(
      tester,
      store: _MemoryCheckpointStore(),
      plan: plan,
      pointRepository: repository,
      navigatorKey: navigatorKey,
    );
    await _tapVisibleText(tester, '计划依据');
    await _tapVisibleText(tester, plan.focusPoints.single.title);
    await _replaceHomeRoute(tester, navigatorKey);

    pending.complete(point);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Returned from Agent home'), findsOneWidget);
    expect(find.byType(KnowledgePointDetailScreen), findsNothing);
    expect(repository.readCount, 1);
  });

  testWidgets('late focus point lookup failure ignores a disposed scope',
      (tester) async {
    final plan = _planWithDetailedEvidence();
    final pending = Completer<KnowledgePoint?>();
    final repository = _ReadControlledKnowledgePointRepository(null)
      ..nextRead = pending;
    await _pumpHome(
      tester,
      store: _MemoryCheckpointStore(),
      plan: plan,
      pointRepository: repository,
    );
    await _tapVisibleText(tester, '计划依据');
    await _tapVisibleText(tester, plan.focusPoints.single.title);
    await tester.pumpWidget(const SizedBox.shrink());

    pending.completeError(StateError('late knowledge point lookup failure'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(repository.readCount, 1);
  });

  testWidgets('missing focus point keeps the knowledge library fallback',
      (tester) async {
    final plan = _planWithDetailedEvidence();
    final repository = _ReadControlledKnowledgePointRepository(null);
    await _pumpHome(
      tester,
      store: _MemoryCheckpointStore(),
      plan: plan,
      pointRepository: repository,
    );
    await _tapVisibleText(tester, '计划依据');
    await _tapVisibleText(tester, plan.focusPoints.single.title);
    await tester.pumpAndSettle();

    expect(find.byType(KnowledgeBaseScreen), findsOneWidget);
    expect(
        tester
            .widget<KnowledgeBaseScreen>(find.byType(KnowledgeBaseScreen))
            .initialTabIndex,
        2);
    expect(find.byType(KnowledgePointDetailScreen), findsNothing);
    expect(repository.readCount, 1);
    expect(tester.takeException(), isNull);
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
  KnowledgePointRepository? pointRepository,
  GlobalKey<NavigatorState>? navigatorKey,
  Size viewport = const Size(390, 844),
  double textScale = 1,
}) async {
  final activePlan = plan ?? _plan();
  final workspace = LearningAgentWorkspaceSnapshot(
    plan: activePlan,
    memory: const LearningAgentMemorySnapshot(),
    toolTargets: const [],
  );
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        privacyPreferencesStoreProvider.overrideWithValue(
          const DisabledPrivacyPreferencesStore(),
        ),
        if (pointRepository != null) ...[
          knowledgePointRepositoryProvider.overrideWithValue(pointRepository),
          knowledgePointEvidenceChunksProvider.overrideWith(
            (ref, pointId) async => const [],
          ),
          knowledgePointQuestionsProvider.overrideWith(
            (ref, pointId) async => const [],
          ),
          learningTargetMemoryProvider.overrideWith(
            (ref, pointId) async => const LearningAgentMemorySnapshot(),
          ),
          sourceListProvider.overrideWith((ref) async => const []),
          knowledgePointListProvider.overrideWith((ref) async => const []),
          allQuestionsProvider.overrideWith((ref) async => const []),
          pendingQuestionListProvider.overrideWith((ref) async => const []),
        ],
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
      child: MaterialApp(
        navigatorKey: navigatorKey,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: const AgentHomeScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapVisibleText(WidgetTester tester, String label) async {
  final target = find.text(label);
  await _scrollTo(tester, target);
  await tester.tap(target);
}

Future<void> _replaceHomeRoute(
  WidgetTester tester,
  GlobalKey<NavigatorState> navigatorKey,
) async {
  navigatorKey.currentState!.pushReplacement<void, void>(
    MaterialPageRoute(
      builder: (context) => const Scaffold(
        body: Text('Returned from Agent home'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

KnowledgePoint _knowledgePoint(LearningAgentFocusPoint focusPoint) {
  final now = DateTime(2026, 9, 12);
  return KnowledgePoint(
    id: focusPoint.id,
    title: focusPoint.title,
    summary: 'Synthetic source-grounded knowledge point.',
    kind: KnowledgePointKind.architecture,
    createdAt: now,
    updatedAt: now,
  );
}

LearningAgentPlan _resumePlan(LearningAgentCheckpoint checkpoint) {
  final base = checkpoint.plan!;
  final candidate = LearningAgentNextActionCandidate.unfinishedCheckpoint(
    sessionId: checkpoint.sessionId,
    title: '继续原 checkpoint',
    reason: '保留原计划恢复未完成会话',
    updatedAt: checkpoint.state.updatedAt,
  );
  return LearningAgentPlan(
    goal: base.goal,
    readiness: base.readiness,
    memory: base.memory,
    steps: base.steps,
    sessionSummary: base.sessionSummary,
    nextAction: LearningAgentNextAction(
      selectedCandidate: candidate,
      inputSnapshot: LearningAgentNextActionInputSnapshot(
        goalValue: base.goal.value,
        plannedAt: checkpoint.state.updatedAt,
        candidates: [candidate],
      ),
    ),
  );
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

LearningAgentPlan _planWithDetailedEvidence() {
  final base = _plan();
  const point = LearningAgentFocusPoint(
    id: 'plan-evidence-focus',
    title: 'Watcher 观察者模式：订阅清理与异步通知中的项目边界',
    reason: '近期复盘显示需要补充订阅生命周期和异常处理的来源依据',
    masteryLevel: 35,
    difficulty: 3,
    interviewRelevance: 5,
    evidenceChunkCount: 12,
    verifiedQuestionCount: 3,
  );
  return LearningAgentPlan(
    goal: base.goal,
    readiness: base.readiness,
    memory: base.memory,
    steps: base.steps,
    focusPoints: const [point],
    sessionSummary: LearningAgentSessionSummary(
      goal: base.goal,
      nextStep: base.nextStep,
      focusPoint: point,
      title: '基于项目来源说明观察者模式的订阅生命周期与异常处理',
      objective: '结合项目资料解释设计选择，区分已经证实的实现细节与仍需要核验的假设，'
          '并在会话结束时记录需要补充的证据。',
      targetLabel: point.title,
      evidenceConstraint: '追问优先围绕已有证据片段支撑的项目细节展开；'
          '缺少来源的结论必须明确标注，不得当作已经验证的事实。',
      memoryReminder: '上次会话尚未讲清取消订阅后的通知边界；'
          '这次先回到对应来源核对，再补充完整说明。',
      successCriteria: const ['能用来源解释设计取舍'],
      reflectionPrompts: const ['哪些结论仍需来源核验？'],
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
  bool failNextLoad = false;
  Completer<LearningAgentCheckpoint?>? nextLoad;
  int loadCount = 0;
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
    loadCount += 1;
    if (failNextLoad) {
      failNextLoad = false;
      throw StateError('checkpoint lookup unavailable');
    }
    final pending = nextLoad;
    nextLoad = null;
    if (pending != null) return pending.future;
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

class _ReadControlledKnowledgePointRepository extends KnowledgePointRepository {
  final KnowledgePoint? point;
  bool failNextRead = false;
  Completer<KnowledgePoint?>? nextRead;
  int readCount = 0;

  _ReadControlledKnowledgePointRepository(this.point) : super(DatabaseHelper());

  @override
  Future<KnowledgePoint?> getKnowledgePoint(String id) async {
    readCount += 1;
    if (failNextRead) {
      failNextRead = false;
      throw StateError('knowledge point lookup unavailable');
    }
    final pending = nextRead;
    nextRead = null;
    if (pending != null) return pending.future;
    return point?.id == id ? point : null;
  }
}
