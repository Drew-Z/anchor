import 'package:dlg_q/core/providers/providers.dart';
import 'package:dlg_q/data/models/grounded_claim.dart';
import 'package:dlg_q/data/models/interview_turn.dart';
import 'package:dlg_q/data/models/knowledge_point.dart';
import 'package:dlg_q/data/models/knowledge_point_source.dart';
import 'package:dlg_q/data/models/learning_session.dart';
import 'package:dlg_q/data/models/source.dart';
import 'package:dlg_q/data/models/source_chunk.dart';
import 'package:dlg_q/features/agent/project_interview_outcome_screen.dart';
import 'package:dlg_q/features/onboarding/first_run_screen.dart';
import 'package:dlg_q/services/agent/agent_session_memory_index.dart';
import 'package:dlg_q/services/agent/learning_agent_planner_service.dart';
import 'package:dlg_q/services/agent/learning_agent_memory_store.dart';
import 'package:dlg_q/services/agent/project_interview_outcome.dart';
import 'package:dlg_q/services/onboarding/first_run_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/disabled_privacy_preferences_store.dart';

void main() {
  testWidgets('project interview outcome fits a 320px viewport',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final outcome = _outcome();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          privacyPreferencesStoreProvider.overrideWithValue(
            const DisabledPrivacyPreferencesStore(),
          ),
          projectInterviewOutcomeProvider.overrideWith(
            (ref) async => outcome,
          ),
        ],
        child: const MaterialApp(home: ProjectInterviewOutcomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('项目面试成果'), findsOneWidget);
    expect(find.text('可面试'), findsOneWidget);
    expect(find.text('需练习'), findsOneWidget);
    expect(find.text('证据缺口'), findsOneWidget);
    expect(find.text('未评估'), findsOneWidget);
    expect(find.text('Architecture unit'), findsOneWidget);

    await tester.tap(find.text('Architecture unit'));
    await tester.pumpAndSettle();
    expect(find.text('最近回答'), findsOneWidget);
    expect(find.text('来源支持的参考提纲'), findsOneWidget);
    expect(find.text('lib/runtime.dart:20-24'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first-run outcome preview renders the shared outcome read model',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final outcome = _outcome();
    final now = outcome.generatedAt;
    final plan = const LearningAgentPlannerService().buildPlan(
      goal: LearningAgentGoal.aiInterviewPrep,
      knowledgePoints: [outcome.units.single.point],
      evidenceBackedPoints: [outcome.units.single.point],
      practiceablePoints: const [],
      practiceTargets: const [],
      pendingQuestions: const [],
      plannedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          privacyPreferencesStoreProvider.overrideWithValue(
            const DisabledPrivacyPreferencesStore(),
          ),
          projectInterviewOutcomeProvider.overrideWith(
            (ref) async => outcome,
          ),
          agentSessionListProvider.overrideWith(
            (ref) async => [
              LearningSession(
                id: 'agent-session',
                mode: LearningSessionMode.agentSession,
                targetId: outcome.units.single.point.id,
                startedAt: now.subtract(const Duration(minutes: 5)),
                endedAt: now,
                summary: '首轮来源绑定面试已完成。',
              ),
            ],
          ),
          learningAgentPlanProvider(LearningAgentGoal.aiInterviewPrep)
              .overrideWith((ref) async => plan),
        ],
        child: MaterialApp(
          home: FirstRunScreen(
            progress: FirstRunProgress(
              step: FirstRunStep.outcomePreview,
              selectedGoal: LearningAgentGoal.aiInterviewPrep,
              sourceId: outcome.units.single.strongestEvidence!.source.id,
              sessionId: 'agent-session',
              startedAt: now.subtract(const Duration(minutes: 10)),
              updatedAt: now,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('首次学习结果'), findsOneWidget);
    expect(find.text('Architecture unit'), findsOneWidget);
    expect(find.textContaining('可面试'), findsWidgets);
    expect(find.text('你的最近回答'), findsOneWidget);
    expect(find.text('来源支持的参考提纲'), findsOneWidget);
    expect(find.text('lib/runtime.dart:20-24'), findsOneWidget);
    expect(find.text('首轮来源绑定面试已完成。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

ProjectInterviewOutcome _outcome() {
  final now = DateTime.utc(2026, 7, 16, 9);
  final source = Source(
    id: 'source',
    title: 'Runtime project',
    type: SourceType.project,
    trustLevel: SourceTrustLevel.sourceCode,
    createdAt: now,
    updatedAt: now,
  );
  final chunk = SourceChunk(
    id: 'chunk',
    sourceId: source.id,
    chunkIndex: 0,
    content: 'The runtime stores one immutable plan snapshot.',
    relativePath: 'lib/runtime.dart',
    startLine: 20,
    endLine: 24,
    createdAt: now,
  );
  final point = KnowledgePoint(
    id: 'point',
    title: 'Architecture unit',
    summary: 'The runtime persists one plan snapshot before execution.',
    kind: KnowledgePointKind.architecture,
    masteryLevel: 80,
    interviewRelevance: 5,
    createdAt: now,
    updatedAt: now,
  );
  final turn = InterviewTurn(
    id: 'turn',
    sessionId: 'session',
    questionText: '如何保持恢复行为稳定？',
    userAnswer: '我在执行前保存计划快照，恢复时复用同一份。',
    aiFeedback: 'feedback',
    referenceAnswer: 'reference',
    knowledgePointId: point.id,
    knowledgePointKind: point.kind,
    citationIds: [chunk.id],
    accuracyScore: 4,
    projectDetailScore: 4,
    engineeringScore: 4,
    clarityScore: 4,
    groundedClaims: [
      GroundedClaim(
        section: 'reference_answer',
        text: 'The runtime stores one immutable plan snapshot.',
        evidence: [
          GroundedClaimEvidence(
            citationId: chunk.id,
            quote: chunk.content,
          ),
        ],
      ),
    ],
    groundingDisposition: GroundingDisposition.grounded,
    createdAt: now,
  );
  return const ProjectInterviewOutcomeService().build(
    knowledgePoints: [point],
    knowledgePointSources: [
      KnowledgePointSource(
        knowledgePointId: point.id,
        sourceChunkId: chunk.id,
        relation: KnowledgePointSourceRelation.implementation,
      ),
    ],
    sources: [source],
    sourceChunks: [chunk],
    interviewTurns: [turn],
    tutorTurns: const [],
    questions: const [],
    programmingAttempts: const [],
    reviewActions: const [],
    memoryStore: LearningAgentMemoryStore(
      AgentSessionMemoryIndex(const []),
    ),
    now: now,
  );
}
