import 'package:anchor_learning/core/providers/providers.dart';
import 'package:anchor_learning/data/models/knowledge_point.dart';
import 'package:anchor_learning/data/models/question.dart';
import 'package:anchor_learning/data/models/question_type.dart';
import 'package:anchor_learning/features/agent/agent_home_screen.dart';
import 'package:anchor_learning/services/agent/agent_session_memory_index.dart';
import 'package:anchor_learning/services/agent/learning_agent_memory_record.dart';
import 'package:anchor_learning/services/agent/learning_agent_planner_service.dart';
import 'package:anchor_learning/services/agent/learning_agent_practice_target.dart';
import 'package:anchor_learning/services/agent/learning_agent_tool_registry.dart';
import 'package:anchor_learning/services/agent/learning_agent_workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/disabled_privacy_preferences_store.dart';

void main() {
  final fixture = _workspaceFixture();

  test('workspace unifies plan, memory, review and policy tool targets', () {
    final workspace = fixture.workspace;

    expect(workspace.goal, LearningAgentGoal.aiInterviewPrep);
    expect(workspace.knowledgeScope, LearningAgentKnowledgeScope.mixed);
    expect(workspace.historyRecordCount, 2);
    expect(workspace.openFollowUpCount, 1);
    expect(workspace.pendingReviewCount, 1);
    expect(workspace.nextReviewAt, fixture.reviewAt);
    expect(
      workspace.toolTargets.map((target) => target.tool.id).toSet(),
      containsAll({
        LearningAgentToolId.openTutorSession,
        LearningAgentToolId.openInterviewSession,
        LearningAgentToolId.startVerifiedPractice,
        LearningAgentToolId.startReviewSession,
      }),
    );
    expect(
      workspace.toolTargets
          .where((target) => target.isNextAction)
          .map((target) => target.tool.toolId),
      [workspace.plan.nextAction!.toolId],
    );
  });

  testWidgets('Agent first screen exposes one workspace and tool targets',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'learning_agent_goal': LearningAgentGoal.aiInterviewPrep.value,
    });
    tester.view.physicalSize = const Size(320, 800);
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
            (ref, goal) async => fixture.workspace,
          ),
          learningAgentActiveCheckpointListProvider.overrideWith(
            (ref) async => const [],
          ),
          agentSessionMemoryIndexProvider.overrideWith(
            (ref) async => AgentSessionMemoryIndex(const []),
          ),
          interviewSessionListProvider.overrideWith((ref) async => const []),
          tutorSessionListProvider.overrideWith((ref) async => const []),
          knowledgeAnswerSessionListProvider.overrideWith(
            (ref) async => const [],
          ),
        ],
        child: const MaterialApp(home: AgentHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Agent 工作台'), findsOneWidget);
    expect(find.text('AI 应用开发面试'), findsOneWidget);
    expect(find.text('知识范围：项目与编程知识'), findsOneWidget);
    expect(find.text('面试官模式'), findsNothing);
    expect(find.text('导师模式'), findsNothing);
    expect(find.text('复习模式'), findsNothing);

    for (final title in const [
      '工具目标',
      '启动导师模式',
      '启动面试模式',
      '完成已核验练习',
      '启动复习模式',
    ]) {
      await tester.scrollUntilVisible(
        find.text(title),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(title), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}

_WorkspaceFixture _workspaceFixture() {
  final now = DateTime.utc(2026, 7, 15, 8);
  final reviewAt = now.add(const Duration(days: 1));
  final projectPoint = KnowledgePoint(
    id: 'workspace-project-point',
    title: 'Agent runtime architecture',
    summary: 'Planner, policy, executor, state, and trace.',
    kind: KnowledgePointKind.architecture,
    masteryLevel: 45,
    difficulty: 3,
    interviewRelevance: 5,
    createdAt: now,
    updatedAt: now,
  );
  final programmingPoint = KnowledgePoint(
    id: 'workspace-programming-point',
    title: 'JSON schema boundary',
    summary: 'Syntax validity and schema conformance are separate checks.',
    kind: KnowledgePointKind.concept,
    masteryLevel: 35,
    difficulty: 2,
    interviewRelevance: 4,
    createdAt: now,
    updatedAt: now,
  );
  final questions = [
    _verifiedQuestion('workspace-project-question', projectPoint.id),
    _verifiedQuestion('workspace-programming-question', programmingPoint.id),
  ];
  final plan = const LearningAgentPlannerService().buildPlan(
    goal: LearningAgentGoal.aiInterviewPrep,
    knowledgePoints: [projectPoint, programmingPoint],
    evidenceBackedPoints: [projectPoint, programmingPoint],
    practiceablePoints: [projectPoint, programmingPoint],
    practiceTargets:
        questions.map(LearningAgentPracticeTarget.fromQuestion).toList(),
    pendingQuestions: const [],
    plannedAt: now,
    evidenceChunkCountByPointId: const {
      'workspace-project-point': 1,
      'workspace-programming-point': 1,
    },
    practiceTargetCountByPointId: const {
      'workspace-project-point': 1,
      'workspace-programming-point': 1,
    },
  );
  final memory = LearningAgentMemorySnapshot(
    records: [
      LearningAgentMemoryRecord(
        id: 'workspace-tutor-memory',
        type: LearningAgentMemoryRecordType.tutor,
        sourceId: 'workspace-tutor-turn',
        targetId: programmingPoint.id,
        targetLabel: programmingPoint.title,
        goals: const {LearningAgentGoal.aiInterviewPrep},
        occurredAt: now.subtract(const Duration(hours: 2)),
        title: '导师回合',
        summary: '解释了 JSON schema 的两层门禁。',
        followUpQuestions: const ['结构化输出为什么仍需要本地校验？'],
        citationIds: const ['workspace-programming-chunk'],
      ),
      LearningAgentMemoryRecord(
        id: 'workspace-interview-memory',
        type: LearningAgentMemoryRecordType.interview,
        sourceId: 'workspace-interview-turn',
        targetId: projectPoint.id,
        targetLabel: projectPoint.title,
        goals: const {LearningAgentGoal.aiInterviewPrep},
        occurredAt: now.subtract(const Duration(hours: 1)),
        title: '面试回合',
        summary: '说明了 planner 与 executor 的边界。',
        citationIds: const ['workspace-project-chunk'],
      ),
    ],
    openFollowUps: [
      LearningAgentOpenFollowUp(
        id: 'workspace-follow-up',
        recordId: 'workspace-tutor-memory',
        recordType: LearningAgentMemoryRecordType.tutor,
        targetId: programmingPoint.id,
        question: '结构化输出为什么仍需要本地校验？',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ],
    pendingReviews: [
      LearningAgentPendingReview(
        id: 'workspace-review',
        targetId: programmingPoint.id,
        dueAt: reviewAt,
        recordType: LearningAgentMemoryRecordType.programmingExercise,
      ),
    ],
    nextReviewAt: reviewAt,
  );
  return _WorkspaceFixture(
    workspace: const LearningAgentWorkspaceService().build(
      plan: plan,
      memory: memory,
    ),
    reviewAt: reviewAt,
  );
}

Question _verifiedQuestion(String id, String pointId) {
  return Question(
    id: id,
    deckId: 'workspace-deck',
    knowledgePointId: pointId,
    type: QuestionType.trueFalse,
    content: '固定工作台回归题',
    answer: '正确',
    sourceStatus: SourceStatus.verified,
    citationIds: const ['workspace-chunk'],
  );
}

class _WorkspaceFixture {
  final LearningAgentWorkspaceSnapshot workspace;
  final DateTime reviewAt;

  const _WorkspaceFixture({
    required this.workspace,
    required this.reviewAt,
  });
}
