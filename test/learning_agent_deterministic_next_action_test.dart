import 'package:dlg_q/data/models/knowledge_point.dart';
import 'package:dlg_q/data/models/programming_exercise.dart';
import 'package:dlg_q/data/models/question.dart';
import 'package:dlg_q/data/models/question_type.dart';
import 'package:dlg_q/services/agent/agent_session_memory_index.dart';
import 'package:dlg_q/services/agent/learning_agent_checkpoint.dart';
import 'package:dlg_q/services/agent/learning_agent_checkpoint_store.dart';
import 'package:dlg_q/services/agent/learning_agent_memory_record.dart';
import 'package:dlg_q/services/agent/learning_agent_memory_store.dart';
import 'package:dlg_q/services/agent/learning_agent_next_action.dart';
import 'package:dlg_q/services/agent/learning_agent_plan_codec.dart';
import 'package:dlg_q/services/agent/learning_agent_planner_service.dart';
import 'package:dlg_q/services/agent/learning_agent_practice_target.dart';
import 'package:dlg_q/services/agent/learning_agent_runtime.dart';
import 'package:dlg_q/services/agent/learning_agent_tool_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final plannedAt = DateTime.utc(2026, 7, 15, 9);

  test('fixed priority is stable and one added state changes one level', () {
    const policy = LearningAgentNextActionPolicy();
    final candidates = <LearningAgentNextActionCandidate>[
      LearningAgentNextActionCandidate.newLearning(
        id: 'learn',
        title: '开始新学习',
        reason: '没有更高优先级工作。',
        stepTypeName: LearningAgentStepRouteNames.tutor,
        toolId: LearningAgentToolRouteIds.openTutorSession,
      ),
    ];

    void expectPriority(LearningAgentNextActionPriority priority) {
      final action = policy.choose(
        goalValue: 'programming_foundations',
        plannedAt: plannedAt,
        candidates: candidates,
      );
      expect(action.priority, priority);
    }

    expectPriority(LearningAgentNextActionPriority.newLearning);
    candidates.add(
      LearningAgentNextActionCandidate.dueReview(
        id: 'review',
        reason: '复习已到期。',
        dueAt: plannedAt,
      ),
    );
    expectPriority(LearningAgentNextActionPriority.dueReview);
    candidates.add(
      LearningAgentNextActionCandidate.weakPrerequisite(
        id: 'prerequisite',
        reason: '先修概念薄弱。',
        occurredAt: plannedAt,
      ),
    );
    expectPriority(LearningAgentNextActionPriority.weakPrerequisite);
    candidates.add(
      LearningAgentNextActionCandidate.pendingVerification(
        id: 'pending',
        reason: '内容仍待核验。',
      ),
    );
    expectPriority(LearningAgentNextActionPriority.pendingVerification);
    candidates.add(
      LearningAgentNextActionCandidate.evidenceGap(
        id: 'gap',
        reason: '缺少来源片段。',
      ),
    );
    expectPriority(LearningAgentNextActionPriority.evidenceGap);
    candidates.add(
      LearningAgentNextActionCandidate.openFollowUp(
        id: 'follow-up',
        question: '解释事件循环边界',
        createdAt: plannedAt,
      ),
    );
    expectPriority(LearningAgentNextActionPriority.openFollowUp);
    candidates.add(
      LearningAgentNextActionCandidate.unfinishedCheckpoint(
        sessionId: 'session-1',
        title: '继续会话',
        reason: '会话停在执行阶段。',
        updatedAt: plannedAt,
        toolId: LearningAgentToolRouteIds.openTutorSession,
      ),
    );
    expectPriority(LearningAgentNextActionPriority.unfinishedCheckpoint);

    final forward = policy.choose(
      goalValue: 'programming_foundations',
      plannedAt: plannedAt,
      candidates: candidates,
    );
    final reversed = policy.choose(
      goalValue: 'programming_foundations',
      plannedAt: plannedAt,
      candidates: candidates.reversed,
    );
    expect(reversed.id, forward.id);
    expect(
      reversed.inputSnapshot.candidates.map((item) => item.canonicalKey),
      forward.inputSnapshot.candidates.map((item) => item.canonicalKey),
    );
  });

  test('planner saves due-review reason, input snapshot and tool in codec', () {
    final point = _point();
    final question = _question(point.id);
    final plan = _plan(
      point,
      question,
      plannedAt: plannedAt,
      candidates: [
        LearningAgentNextActionCandidate.dueReview(
          id: 'question-review',
          targetId: point.id,
          targetLabel: point.title,
          reason: '“${point.title}”的复习时间已到。',
          dueAt: plannedAt.subtract(const Duration(minutes: 1)),
        ),
      ],
    );

    expect(
        plan.nextAction?.priority, LearningAgentNextActionPriority.dueReview);
    expect(
        plan.nextAction?.toolId, LearningAgentToolId.startReviewSession.value);
    expect(plan.nextAction?.reason, contains('复习时间已到'));
    expect(plan.nextStep?.type, LearningAgentStepType.review);
    expect(plan.sessionSummary.focusPoint?.id, point.id);
    expect(plan.nextAction?.inputSnapshot.candidates, isNotEmpty);

    const codec = LearningAgentPlanCodec();
    final restored = codec.decode(codec.encode(plan));
    expect(restored.nextAction?.priority, plan.nextAction?.priority);
    expect(restored.nextAction?.toolId, plan.nextAction?.toolId);
    expect(
      restored.nextAction?.inputSnapshot.toMap(),
      plan.nextAction?.inputSnapshot.toMap(),
    );
  });

  test('planner routes one pending programming exercise to exact verification',
      () {
    final point = _point();
    final question = _question(point.id);
    final exercise = _pendingExercise(point.id);
    final plan = const LearningAgentPlannerService().buildPlan(
      goal: LearningAgentGoal.programmingFoundations,
      knowledgePoints: [point],
      evidenceBackedPoints: [point],
      practiceablePoints: [point],
      practiceTargets: [LearningAgentPracticeTarget.fromQuestion(question)],
      pendingQuestions: const [],
      pendingProgrammingExercises: [exercise],
      plannedAt: plannedAt,
      evidenceChunkCountByPointId: {point.id: 1},
      practiceTargetCountByPointId: {point.id: 1},
    );

    expect(plan.readiness.pendingQuestionCount, 0);
    expect(plan.readiness.pendingProgrammingExerciseCount, 1);
    expect(plan.readiness.pendingVerificationCount, 1);
    expect(
      plan.nextAction?.priority,
      LearningAgentNextActionPriority.pendingVerification,
    );
    expect(
      plan.nextAction?.targetId,
      'programming_exercise:${exercise.id}',
    );
    expect(
      plan.nextAction?.toolId,
      LearningAgentToolId.verifyPendingQuestions.value,
    );
    expect(plan.nextAction?.reason, contains(exercise.prompt));
    expect(plan.nextStep?.type, LearningAgentStepType.verifyQuestions);

    const codec = LearningAgentPlanCodec();
    final restored = codec.decode(codec.encode(plan));
    expect(restored.readiness.pendingProgrammingExerciseCount, 1);
    expect(restored.nextAction?.toMap(), plan.nextAction?.toMap());
  });

  test('blocked higher-priority action stops lower actions explicitly', () {
    final point = _point();
    final question = _question(point.id);
    final plan = _plan(
      point,
      question,
      plannedAt: plannedAt,
      candidates: [
        LearningAgentNextActionCandidate.unfinishedCheckpoint(
          sessionId: 'broken-session',
          title: '继续未完成会话',
          reason: '发现一个未完成 checkpoint。',
          updatedAt: plannedAt,
          executable: false,
          blockerCode: 'missing_plan',
          blockerMessage: 'checkpoint 缺少原 plan snapshot，不能安全恢复。',
        ),
      ],
    );

    expect(
      plan.nextAction?.priority,
      LearningAgentNextActionPriority.unfinishedCheckpoint,
    );
    expect(plan.nextAction?.executable, isFalse);
    expect(plan.nextStep, isNull);
    expect(plan.canExecuteNextAction, isFalse);
    expect(plan.startBlockReason, contains('缺少原 plan snapshot'));
    expect(plan.blockers, contains(plan.nextAction?.blockerMessage));
  });

  test('plan-created trace explains the deterministic selection', () {
    final point = _point();
    final question = _question(point.id);
    final plan = _plan(
      point,
      question,
      plannedAt: plannedAt,
      candidates: [
        LearningAgentNextActionCandidate.dueReview(
          id: 'trace-review',
          targetId: point.id,
          targetLabel: point.title,
          reason: '固定复习输入已经到期。',
          dueAt: plannedAt,
        ),
      ],
    );
    final runtime = LearningAgentRuntime(
      checkpointStore: _RecordingCheckpointStore(),
    );

    final session = runtime.prepareSession(plan: plan, startedAt: plannedAt);
    final detail = session.traceEvents.single.detail ?? '';

    expect(detail, contains('Next action 优先级: 到期复习'));
    expect(detail, contains('Next action 原因: 固定复习输入已经到期。'));
    expect(detail, contains(LearningAgentToolId.startReviewSession.value));
    expect(detail, contains('到期复习 1'));
  });

  test('checkpoint resume keeps the original next-action snapshot', () async {
    final point = _point();
    final question = _question(point.id);
    final originalPlan = _plan(
      point,
      question,
      plannedAt: plannedAt,
      candidates: [
        LearningAgentNextActionCandidate.dueReview(
          id: 'original-review',
          targetId: point.id,
          targetLabel: point.title,
          reason: '原计划要求先完成到期复习。',
          dueAt: plannedAt,
        ),
      ],
    );
    final newerPlan = _plan(
      point,
      question,
      plannedAt: plannedAt.add(const Duration(minutes: 5)),
      candidates: [
        LearningAgentNextActionCandidate.weakPrerequisite(
          id: 'new-prerequisite',
          targetId: point.id,
          targetLabel: point.title,
          reason: '当前数据已经变化。',
          occurredAt: plannedAt.add(const Duration(minutes: 5)),
        ),
      ],
    );
    final runtime = LearningAgentRuntime(
      checkpointStore: _RecordingCheckpointStore(),
    );
    final prepared = runtime.prepareSession(
      plan: originalPlan,
      startedAt: plannedAt,
    );
    final checkpoint = LearningAgentCheckpoint(
      state: prepared.state,
      traceEvents: prepared.traceEvents,
      plan: originalPlan,
    );

    final resumed = await runtime.resumeCheckpoint(
      checkpoint,
      resumedAt: plannedAt.add(const Duration(minutes: 10)),
    );

    expect(resumed.canResume, isTrue);
    expect(
      resumed.session?.plan.nextAction?.toMap(),
      originalPlan.nextAction?.toMap(),
    );
    expect(
      resumed.session?.plan.nextAction?.priority,
      isNot(newerPlan.nextAction?.priority),
    );
  });

  test('unified memory exposes weak prerequisites and ordered pending reviews',
      () {
    final dueAt = plannedAt.subtract(const Duration(hours: 1));
    final laterAt = plannedAt.add(const Duration(days: 1));
    final store = LearningAgentMemoryStore(
      AgentSessionMemoryIndex(const []),
      records: [
        LearningAgentMemoryRecord(
          id: 'review-record',
          type: LearningAgentMemoryRecordType.reviewAction,
          sourceId: 'review-action',
          targetId: 'advanced-point',
          goals: const {LearningAgentGoal.programmingFoundations},
          occurredAt: dueAt,
          title: '待处理复习动作',
          summary: '先修薄弱',
          weakPrerequisites: const [
            LearningAgentMemoryWeakPrerequisite(
              targetId: 'basic-point',
              targetLabel: '基础概念',
            ),
          ],
          reviewDueAt: dueAt,
        ),
      ],
      reviewSchedules: [
        LearningAgentMemoryReviewSchedule(
          id: 'later-review',
          targetId: 'advanced-point',
          goals: const {LearningAgentGoal.programmingFoundations},
          dueAt: laterAt,
        ),
      ],
    );

    final snapshot = store.query(
      goal: LearningAgentGoal.programmingFoundations,
    );

    expect(snapshot.weakPrerequisites.single.targetId, 'basic-point');
    expect(snapshot.weakPrerequisites.single.occurrenceCount, 1);
    expect(snapshot.pendingReviews, hasLength(2));
    expect(snapshot.pendingReviews.first.dueAt, dueAt);
    expect(snapshot.nextReviewAt, dueAt);
  });
}

LearningAgentPlan _plan(
  KnowledgePoint point,
  Question question, {
  required DateTime plannedAt,
  List<LearningAgentNextActionCandidate> candidates = const [],
}) {
  final target = LearningAgentPracticeTarget.fromQuestion(question);
  return const LearningAgentPlannerService().buildPlan(
    goal: LearningAgentGoal.programmingFoundations,
    knowledgePoints: [point],
    evidenceBackedPoints: [point],
    practiceablePoints: [point],
    practiceTargets: [target],
    pendingQuestions: const [],
    nextActionCandidates: candidates,
    plannedAt: plannedAt,
    evidenceChunkCountByPointId: {point.id: 1},
    practiceTargetCountByPointId: {point.id: 1},
  );
}

KnowledgePoint _point() {
  final now = DateTime.utc(2026, 7, 15);
  return KnowledgePoint(
    id: 'event-loop-point',
    title: '事件循环',
    summary: '解释任务和微任务调度。',
    kind: KnowledgePointKind.concept,
    masteryLevel: 45,
    difficulty: 3,
    interviewRelevance: 5,
    createdAt: now,
    updatedAt: now,
  );
}

Question _question(String pointId) {
  return Question(
    id: 'event-loop-question',
    deckId: 'event-loop-deck',
    knowledgePointId: pointId,
    type: QuestionType.trueFalse,
    content: '微任务在同步代码之前执行。',
    answer: '错误',
    sourceStatus: SourceStatus.verified,
    citationIds: const ['event-loop-chunk'],
  );
}

ProgrammingExercise _pendingExercise(String pointId) {
  final now = DateTime.utc(2026, 7, 15);
  return ProgrammingExercise(
    id: 'pending-event-loop-exercise',
    knowledgePointId: pointId,
    kind: ProgrammingExerciseKind.codeReading,
    prompt: '解释这段调度代码中的微任务执行边界。',
    referenceAnswer: '同步代码结束后清空微任务队列。',
    conceptAccuracyCriterion: '区分同步任务与微任务。',
    reasoningProcessCriterion: '按执行顺序说明边界。',
    evidenceUseCriterion: '引用来源片段。',
    clarityCriterion: '明确指出执行时机。',
    sourceStatus: SourceStatus.pending,
    citationIds: const ['event-loop-chunk'],
    createdAt: now,
    updatedAt: now,
  );
}

class _RecordingCheckpointStore implements LearningAgentCheckpointStore {
  @override
  Future<void> delete(String sessionId) async {}

  @override
  Future<LearningAgentCheckpoint?> load(String sessionId) async => null;

  @override
  Future<List<LearningAgentCheckpoint>> loadActive({int limit = 20}) async {
    return const [];
  }

  @override
  Future<LearningAgentCheckpoint> save(
    LearningAgentCheckpoint checkpoint,
  ) async {
    return checkpoint.withRevision(checkpoint.revision + 1);
  }
}
