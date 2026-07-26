import 'package:flutter_test/flutter_test.dart';

import 'package:dlg_q/data/models/knowledge_point.dart';
import 'package:dlg_q/data/models/question.dart';
import 'package:dlg_q/data/models/question_type.dart';
import 'package:dlg_q/services/agent/learning_agent_practice_target.dart';
import 'package:dlg_q/services/agent/learning_agent_planner_service.dart';

void main() {
  final planner = LearningAgentPlannerService();
  final now = DateTime.utc(2026, 7, 15);
  final projectPoint = KnowledgePoint(
    id: 'project-architecture',
    title: 'Agent runtime architecture',
    summary: 'Planner, policy, executor, state, and trace.',
    kind: KnowledgePointKind.architecture,
    masteryLevel: 40,
    interviewRelevance: 5,
    createdAt: now,
    updatedAt: now,
  );
  final programmingPoint = KnowledgePoint(
    id: 'programming-json',
    title: 'JSON schema boundary',
    summary: 'Valid JSON and schema conformance are different guarantees.',
    kind: KnowledgePointKind.concept,
    masteryLevel: 30,
    interviewRelevance: 4,
    createdAt: now,
    updatedAt: now,
  );
  final projectVerified = _question(
    id: 'project-verified',
    pointId: projectPoint.id,
    status: SourceStatus.verified,
  );
  final programmingVerified = _question(
    id: 'programming-verified',
    pointId: programmingPoint.id,
    status: SourceStatus.verified,
  );
  final projectPending = _question(
    id: 'project-pending',
    pointId: projectPoint.id,
    status: SourceStatus.pending,
  );
  final programmingPending = _question(
    id: 'programming-pending',
    pointId: programmingPoint.id,
    status: SourceStatus.pending,
  );
  final unlinkedVerified = _question(
    id: 'unlinked-verified',
    status: SourceStatus.verified,
  );

  test('goals expose an explicit default knowledge scope', () {
    expect(
      LearningAgentGoal.aiInterviewPrep.knowledgeScope,
      LearningAgentKnowledgeScope.mixed,
    );
    expect(
      LearningAgentGoal.projectWalkthrough.knowledgeScope,
      LearningAgentKnowledgeScope.project,
    );
    expect(
      LearningAgentGoal.programmingFoundations.knowledgeScope,
      LearningAgentKnowledgeScope.programming,
    );
  });

  test('project walkthrough excludes programming concepts and questions', () {
    final plan = planner.buildPlan(
      goal: LearningAgentGoal.projectWalkthrough,
      evidenceBackedPoints: [projectPoint, programmingPoint],
      practiceablePoints: [projectPoint, programmingPoint],
      practiceTargets: [
        projectVerified,
        programmingVerified,
        unlinkedVerified,
      ].map(LearningAgentPracticeTarget.fromQuestion).toList(),
      pendingQuestions: [projectPending, programmingPending],
    );

    expect(plan.knowledgeScope, LearningAgentKnowledgeScope.project);
    expect(plan.readiness.evidenceBackedPointCount, 1);
    expect(plan.readiness.practiceablePointCount, 1);
    expect(plan.readiness.verifiedQuestionCount, 1);
    expect(plan.readiness.pendingQuestionCount, 1);
    expect(plan.focusPoints.map((point) => point.id), [projectPoint.id]);
    expect(plan.nextStep?.type, LearningAgentStepType.verifyQuestions);
  });

  test('programming foundations excludes project units and questions', () {
    final plan = planner.buildPlan(
      goal: LearningAgentGoal.programmingFoundations,
      evidenceBackedPoints: [projectPoint, programmingPoint],
      practiceablePoints: [projectPoint, programmingPoint],
      practiceTargets: [
        projectVerified,
        programmingVerified,
        unlinkedVerified,
      ].map(LearningAgentPracticeTarget.fromQuestion).toList(),
      pendingQuestions: [projectPending, programmingPending],
    );

    expect(plan.knowledgeScope, LearningAgentKnowledgeScope.programming);
    expect(plan.readiness.evidenceBackedPointCount, 1);
    expect(plan.readiness.practiceablePointCount, 1);
    expect(plan.readiness.verifiedQuestionCount, 1);
    expect(plan.readiness.pendingQuestionCount, 1);
    expect(plan.focusPoints.map((point) => point.id), [programmingPoint.id]);
    expect(plan.nextStep?.type, LearningAgentStepType.verifyQuestions);
  });

  test('AI interview prep keeps the mixed project and programming corpus', () {
    final plan = planner.buildPlan(
      evidenceBackedPoints: [projectPoint, programmingPoint],
      practiceablePoints: [projectPoint, programmingPoint],
      practiceTargets: [
        projectVerified,
        programmingVerified,
        unlinkedVerified,
      ].map(LearningAgentPracticeTarget.fromQuestion).toList(),
      pendingQuestions: const [],
    );

    expect(plan.knowledgeScope, LearningAgentKnowledgeScope.mixed);
    expect(plan.readiness.evidenceBackedPointCount, 2);
    expect(plan.readiness.practiceablePointCount, 2);
    expect(plan.readiness.verifiedQuestionCount, 2);
    expect(
      plan.focusPoints.map((point) => point.id).toSet(),
      {projectPoint.id, programmingPoint.id},
    );
    expect(plan.nextStep?.type, LearningAgentStepType.interview);
  });
}

Question _question({
  required String id,
  String? pointId,
  required SourceStatus status,
}) {
  return Question(
    id: id,
    deckId: 'scope-deck',
    knowledgePointId: pointId,
    type: QuestionType.trueFalse,
    content: 'Scope test question',
    answer: '正确',
    sourceStatus: status,
    citationIds: const ['scope-chunk'],
  );
}
