import 'dart:convert';
import 'dart:io';

import 'package:anchor_learning/data/models/grounded_claim.dart';
import 'package:anchor_learning/data/models/grounded_learning_context.dart';
import 'package:anchor_learning/data/models/interview_turn.dart';
import 'package:anchor_learning/data/models/knowledge_point.dart';
import 'package:anchor_learning/data/models/knowledge_point_source.dart';
import 'package:anchor_learning/data/models/learning_session.dart';
import 'package:anchor_learning/data/models/programming_exercise.dart';
import 'package:anchor_learning/data/models/programming_exercise_attempt.dart';
import 'package:anchor_learning/data/models/question.dart';
import 'package:anchor_learning/data/models/question_type.dart';
import 'package:anchor_learning/data/models/source.dart';
import 'package:anchor_learning/data/models/source_chunk.dart';
import 'package:anchor_learning/data/models/tutor_turn.dart';
import 'package:anchor_learning/services/agent/agent_session_memory_index.dart';
import 'package:anchor_learning/services/agent/grounded_learning_context_service.dart';
import 'package:anchor_learning/services/agent/learning_agent_checkpoint.dart';
import 'package:anchor_learning/services/agent/learning_agent_checkpoint_store.dart';
import 'package:anchor_learning/services/agent/learning_agent_memory_store.dart';
import 'package:anchor_learning/services/agent/learning_agent_memory_timeline_builder.dart';
import 'package:anchor_learning/services/agent/learning_agent_next_action.dart';
import 'package:anchor_learning/services/agent/learning_agent_planner_service.dart';
import 'package:anchor_learning/services/agent/learning_agent_practice_target.dart';
import 'package:anchor_learning/services/agent/learning_agent_runtime.dart';
import 'package:anchor_learning/services/agent/learning_agent_tool_registry.dart';
import 'package:anchor_learning/services/agent/learning_agent_workspace.dart';
import 'package:anchor_learning/services/ingestion/programming_source_import_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fixed unified Agent path stays grounded, stateful and resumable',
      () async {
    final fixture = await _loadFixture();
    final clock = _asMap(fixture['clock']);
    final expected = _asMap(fixture['expected']);
    final retrievedAt = DateTime.parse(clock['retrieved_at'] as String);
    final tutorAt = DateTime.parse(clock['tutor_at'] as String);
    final interviewAt = DateTime.parse(clock['interview_at'] as String);
    final practiceAt = DateTime.parse(clock['practice_at'] as String);
    final plannedAt = DateTime.parse(clock['planned_at'] as String);
    final resumedAt = DateTime.parse(clock['resumed_at'] as String);

    const importService = ProgrammingSourceImportService();
    final sources = <Source>[];
    final chunksBySourceId = <String, List<SourceChunk>>{};
    for (final sourceData in _asMapList(fixture['sources'])) {
      final snapshot = importService.buildSnapshot(
        draft: ProgrammingSourceImportDraft(
          title: sourceData['title'] as String,
          content: sourceData['content'] as String,
          trustLevel: SourceTrustLevel.fromString(
            sourceData['trust_level'] as String,
          ),
          uri: sourceData['uri'] as String,
          publisher: sourceData['publisher'] as String,
          revision: sourceData['revision'] as String,
          licenseExpression: sourceData['license_expression'] as String,
        ),
        sourceId: sourceData['id'] as String,
        retrievedAt: retrievedAt,
      );
      sources.add(snapshot.source);
      chunksBySourceId[snapshot.source.id] = snapshot.chunks;
    }
    expect(sources, hasLength(2));
    expect(sources.every((source) => source.contentHash.length == 64), isTrue);
    expect(
      sources.map((source) => source.trustLevel).toSet(),
      {SourceTrustLevel.sourceCode, SourceTrustLevel.officialDoc},
    );

    final points = <KnowledgePoint>[];
    final pointSources = <KnowledgePointSource>[];
    final chunkByPointId = <String, SourceChunk>{};
    for (final pointData in _asMapList(fixture['knowledge_points'])) {
      final point = KnowledgePoint(
        id: pointData['id'] as String,
        title: pointData['title'] as String,
        summary: pointData['summary'] as String,
        kind: KnowledgePointKind.fromString(pointData['kind'] as String),
        masteryLevel: pointData['mastery_level'] as int,
        difficulty: pointData['difficulty'] as int,
        interviewRelevance: pointData['interview_relevance'] as int,
        createdAt: retrievedAt,
        updatedAt: retrievedAt,
      );
      final sourceId = pointData['source_id'] as String;
      final chunk = chunksBySourceId[sourceId]!.single;
      points.add(point);
      chunkByPointId[point.id] = chunk;
      pointSources.add(
        KnowledgePointSource(
          knowledgePointId: point.id,
          sourceChunkId: chunk.id,
        ),
      );
    }
    final pointsById = {for (final point in points) point.id: point};
    final projectPoint = pointsById['unified-agent-project-point']!;
    final programmingPoint = pointsById['unified-agent-programming-point']!;
    final projectChunk = chunkByPointId[projectPoint.id]!;
    final programmingChunk = chunkByPointId[programmingPoint.id]!;

    const contextService = GroundedLearningContextService();
    final contexts = [
      GroundedLearningSurface.tutor,
      GroundedLearningSurface.interview,
      GroundedLearningSurface.programmingExerciseEvaluation,
    ]
        .map(
          (surface) => contextService.select(
            targetId: programmingPoint.id,
            knowledgePoint: programmingPoint,
            surface: surface,
            candidates: [
              GroundedLearningContextCandidate(
                chunk: programmingChunk,
                reasons: [
                  surface ==
                          GroundedLearningSurface.programmingExerciseEvaluation
                      ? GroundedLearningContextReason.practiceCitation
                      : GroundedLearningContextReason.targetRelation,
                ],
              ),
            ],
            sources: sources,
            requiredCitationIds: {programmingChunk.id},
          ),
        )
        .toList();
    expect(contexts.every((context) => context.isExecutable), isTrue);
    expect(
      contexts.map((context) => context.chunkIds),
      everyElement([programmingChunk.id]),
    );
    expect(
      contexts.every(
        (context) => context.items.single.quoteBoundary.containsQuote(
          'validate both parsing and schema constraints',
        ),
      ),
      isTrue,
    );
    expect(
      contexts.every(
        (context) =>
            context.items.single.trustLevel == SourceTrustLevel.officialDoc,
      ),
      isTrue,
    );

    final projectQuestion = Question(
      id: 'unified-agent-project-question',
      deckId: 'unified-agent-deck',
      knowledgePointId: projectPoint.id,
      type: QuestionType.trueFalse,
      content: 'Checkpoint resume should keep the original plan snapshot.',
      answer: '正确',
      sourceStatus: SourceStatus.verified,
      citationIds: [projectChunk.id],
    );
    final programmingQuestion = Question(
      id: 'unified-agent-programming-question',
      deckId: 'unified-agent-deck',
      knowledgePointId: programmingPoint.id,
      type: QuestionType.trueFalse,
      content: 'Syntactically valid JSON always satisfies its schema.',
      answer: '错误',
      sourceStatus: SourceStatus.verified,
      citationIds: [programmingChunk.id],
      nextReviewAt: plannedAt.subtract(const Duration(minutes: 30)),
    );
    final exercise = ProgrammingExercise(
      id: 'unified-agent-programming-exercise',
      knowledgePointId: programmingPoint.id,
      kind: ProgrammingExerciseKind.boundaryJudgment,
      prompt: 'Explain the boundary between JSON parsing and schema checks.',
      referenceAnswer: 'Parsing checks syntax; schema validation checks shape.',
      conceptAccuracyCriterion: 'Distinguish the two guarantees.',
      reasoningProcessCriterion: 'Apply the checks in order.',
      evidenceUseCriterion: 'Use the official source quote.',
      clarityCriterion: 'State both failure modes.',
      sourceStatus: SourceStatus.verified,
      citationIds: [programmingChunk.id],
      createdAt: retrievedAt,
      updatedAt: retrievedAt,
    );
    final practiceTargets = [
      LearningAgentPracticeTarget.fromQuestion(projectQuestion),
      LearningAgentPracticeTarget.fromQuestion(programmingQuestion),
      LearningAgentPracticeTarget.fromProgrammingExercise(exercise),
    ];

    LearningAgentPlan routeFor(LearningAgentGoal goal) {
      return const LearningAgentPlannerService().buildPlan(
        goal: goal,
        knowledgePoints: points,
        evidenceBackedPoints: points,
        practiceablePoints: points,
        practiceTargets: practiceTargets,
        pendingQuestions: const [],
        plannedAt: plannedAt,
        evidenceChunkCountByPointId: {
          projectPoint.id: 1,
          programmingPoint.id: 1,
        },
        practiceTargetCountByPointId: {
          projectPoint.id: 1,
          programmingPoint.id: 2,
        },
        programmingExerciseCountByPointId: {
          programmingPoint.id: 1,
        },
      );
    }

    final projectPlan = routeFor(LearningAgentGoal.projectWalkthrough);
    final programmingPlan = routeFor(LearningAgentGoal.programmingFoundations);
    final mixedPlan = routeFor(LearningAgentGoal.aiInterviewPrep);
    expect(projectPlan.knowledgeScope.value, expected['project_scope']);
    expect(programmingPlan.knowledgeScope.value, expected['programming_scope']);
    expect(mixedPlan.knowledgeScope.value, expected['mixed_scope']);
    expect(projectPlan.focusPoints.map((point) => point.id), [projectPoint.id]);
    expect(
      programmingPlan.focusPoints.map((point) => point.id),
      [programmingPoint.id],
    );
    expect(
      mixedPlan.focusPoints.map((point) => point.id).toSet(),
      {projectPoint.id, programmingPoint.id},
    );
    expect(
      programmingPlan.practiceTarget?.id,
      exercise.id,
    );

    final tutorSession = LearningSession(
      id: 'unified-agent-tutor-session',
      mode: LearningSessionMode.tutor,
      targetId: programmingPoint.id,
      startedAt: tutorAt,
      endedAt: tutorAt.add(const Duration(minutes: 10)),
    );
    final interviewSession = LearningSession(
      id: 'unified-agent-interview-session',
      mode: LearningSessionMode.interview,
      targetId: projectPoint.id,
      startedAt: interviewAt,
      endedAt: interviewAt.add(const Duration(minutes: 10)),
    );
    final tutorTurn = TutorTurn(
      id: 'unified-agent-tutor-turn',
      sessionId: tutorSession.id,
      knowledgePointId: programmingPoint.id,
      questionText: 'What does JSON parsing guarantee?',
      userAnswer: 'It guarantees both syntax and schema.',
      aiFeedback: 'Parsing guarantees syntax only; schema is a second gate.',
      referenceAnswer: 'Parsing and schema validation are separate checks.',
      misconception: 'Merged syntax validity with schema conformance.',
      nextQuestion: 'Why must the app validate the parsed value locally?',
      citationIds: [programmingChunk.id],
      evidenceSufficient: true,
      accuracyScore: 70,
      groundingDisposition: GroundingDisposition.grounded,
      createdAt: tutorAt.add(const Duration(minutes: 5)),
    );
    final interviewTurn = InterviewTurn(
      id: 'unified-agent-interview-turn',
      sessionId: interviewSession.id,
      knowledgePointId: projectPoint.id,
      knowledgePointKind: projectPoint.kind,
      questionText: 'Why is checkpoint resume deterministic?',
      userAnswer: 'It uses the current planner result.',
      aiFeedback: 'It resumes the saved plan snapshot instead.',
      referenceAnswer: 'The checkpoint owns the original plan snapshot.',
      citationIds: [projectChunk.id],
      accuracyScore: 75,
      projectDetailScore: 70,
      engineeringScore: 65,
      clarityScore: 80,
      weakDimensions: const [InterviewScoreDimension.engineering],
      reviewDueAt: plannedAt.subtract(const Duration(minutes: 15)),
      groundingDisposition: GroundingDisposition.grounded,
      createdAt: interviewAt.add(const Duration(minutes: 5)),
    );
    final attempt = ProgrammingExerciseAttempt(
      id: 'unified-agent-programming-attempt',
      exerciseId: exercise.id,
      knowledgePointId: programmingPoint.id,
      userAnswer: 'Parsing validates the object shape.',
      feedback: 'Separate syntax parsing from schema validation.',
      conceptAccuracyScore: 70,
      reasoningProcessScore: 75,
      evidenceUseScore: 65,
      clarityScore: 80,
      misconceptionCode: 'schema_parse_merge',
      misconceptionLabel: 'Merged parsing and schema checks',
      repairExplanation: 'Parse first, validate the parsed value second.',
      citationIds: [programmingChunk.id],
      evidenceSufficient: true,
      groundingDisposition: GroundingDisposition.grounded,
      createdAt: practiceAt,
    );

    final buildResult = const LearningAgentMemoryTimelineBuilder().build(
      sessions: [tutorSession, interviewSession],
      knowledgePoints: points,
      knowledgePointSources: pointSources,
      questions: [projectQuestion, programmingQuestion],
      interviewTurns: [interviewTurn],
      tutorTurns: [tutorTurn],
      programmingExercises: [exercise],
      programmingAttempts: [attempt],
      reviewActions: const [],
    );
    final memoryStore = LearningAgentMemoryStore(
      AgentSessionMemoryIndex(const []),
      records: buildResult.records,
      reviewSchedules: buildResult.reviewSchedules,
    );
    final memory = memoryStore.query(goal: LearningAgentGoal.aiInterviewPrep);
    expect(
      memory.records.map((record) => record.type.value).toSet(),
      Set<String>.from(expected['memory_types'] as List),
    );
    expect(memory.openFollowUps, hasLength(1));
    expect(memory.pendingReviews.length, greaterThanOrEqualTo(2));
    expect(memory.weakDimensions, isNotEmpty);

    final nextActionCandidates = <LearningAgentNextActionCandidate>[
      for (final followUp in memory.openFollowUps)
        LearningAgentNextActionCandidate.openFollowUp(
          id: followUp.id,
          question: followUp.question,
          createdAt: followUp.createdAt,
          targetId: followUp.targetId,
          targetLabel: pointsById[followUp.targetId]?.title,
        ),
      for (final review in memory.pendingReviews)
        if (!review.dueAt.isAfter(plannedAt))
          LearningAgentNextActionCandidate.dueReview(
            id: review.id,
            targetId: review.targetId,
            targetLabel: pointsById[review.targetId]?.title,
            reason: 'The fixed review schedule is due.',
            dueAt: review.dueAt,
          ),
    ];
    final finalPlan = const LearningAgentPlannerService().buildPlan(
      goal: LearningAgentGoal.aiInterviewPrep,
      knowledgePoints: points,
      evidenceBackedPoints: points,
      practiceablePoints: points,
      practiceTargets: practiceTargets,
      pendingQuestions: const [],
      nextActionCandidates: nextActionCandidates,
      plannedAt: plannedAt,
      evidenceChunkCountByPointId: {
        projectPoint.id: 1,
        programmingPoint.id: 1,
      },
      practiceTargetCountByPointId: {
        projectPoint.id: 1,
        programmingPoint.id: 2,
      },
      programmingExerciseCountByPointId: {
        programmingPoint.id: 1,
      },
      goalSessionCount: memory.recordCount,
      goalOpenFollowUpCount: memory.openFollowUps.length,
    );
    expect(
        finalPlan.nextAction?.priority.value, expected['next_action_priority']);
    expect(finalPlan.nextAction?.toolId, expected['selected_tool_id']);

    final workspace = const LearningAgentWorkspaceService().build(
      plan: finalPlan,
      memory: memory,
    );
    expect(workspace.historyRecordCount, 3);
    expect(workspace.pendingReviewCount, greaterThanOrEqualTo(2));
    expect(workspace.selectedToolTarget?.tool.id,
        LearningAgentToolId.handleFollowUps);
    expect(
      workspace.toolTargets.map((target) => target.tool.id).toSet(),
      containsAll({
        LearningAgentToolId.openTutorSession,
        LearningAgentToolId.openInterviewSession,
        LearningAgentToolId.startVerifiedPractice,
        LearningAgentToolId.startReviewSession,
      }),
    );

    final runtime = LearningAgentRuntime(
      checkpointStore: _RecordingCheckpointStore(),
    );
    final prepared = runtime.prepareSession(
      plan: finalPlan,
      startedAt: plannedAt,
    );
    expect(
        prepared.traceEvents.single.detail, contains('Next action 优先级: 开放追问'));
    final checkpoint = LearningAgentCheckpoint(
      state: prepared.state,
      traceEvents: prepared.traceEvents,
      plan: finalPlan,
    );
    final changedPlan = const LearningAgentPlannerService().buildPlan(
      goal: LearningAgentGoal.aiInterviewPrep,
      knowledgePoints: points,
      evidenceBackedPoints: points,
      practiceablePoints: points,
      practiceTargets: practiceTargets,
      pendingQuestions: const [],
      nextActionCandidates: nextActionCandidates
          .where(
            (candidate) =>
                candidate.priority == LearningAgentNextActionPriority.dueReview,
          )
          .toList(),
      plannedAt: resumedAt,
      goalOpenFollowUpCount: 0,
    );
    expect(
      changedPlan.nextAction?.priority,
      LearningAgentNextActionPriority.dueReview,
    );

    final resumed = await runtime.resumeCheckpoint(
      checkpoint,
      resumedAt: resumedAt,
    );
    expect(resumed.canResume, isTrue);
    expect(
      resumed.session?.plan.nextAction?.toMap(),
      finalPlan.nextAction?.toMap(),
    );
    expect(
      resumed.session?.plan.nextAction?.priority,
      isNot(changedPlan.nextAction?.priority),
    );
  });
}

Future<Map<String, dynamic>> _loadFixture() async {
  final json = await File(
    'test/fixtures/golden_path/unified_agent_closure_fixture.json',
  ).readAsString();
  return _asMap(jsonDecode(json));
}

Map<String, dynamic> _asMap(Object? value) {
  return Map<String, dynamic>.from(value! as Map);
}

List<Map<String, dynamic>> _asMapList(Object? value) {
  return (value! as List<dynamic>).map(_asMap).toList();
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
