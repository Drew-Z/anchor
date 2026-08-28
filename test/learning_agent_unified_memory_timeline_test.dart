import 'package:anchor_learning/data/models/interview_turn.dart';
import 'package:anchor_learning/data/models/knowledge_point.dart';
import 'package:anchor_learning/data/models/knowledge_point_source.dart';
import 'package:anchor_learning/data/models/learning_session.dart';
import 'package:anchor_learning/data/models/programming_exercise.dart';
import 'package:anchor_learning/data/models/programming_exercise_attempt.dart';
import 'package:anchor_learning/data/models/programming_review_action.dart';
import 'package:anchor_learning/data/models/question.dart';
import 'package:anchor_learning/data/models/question_type.dart';
import 'package:anchor_learning/data/models/tutor_turn.dart';
import 'package:anchor_learning/services/agent/agent_session_memory_index.dart';
import 'package:anchor_learning/services/agent/learning_agent_memory_record.dart';
import 'package:anchor_learning/services/agent/learning_agent_memory_store.dart';
import 'package:anchor_learning/services/agent/learning_agent_memory_timeline_builder.dart';
import 'package:anchor_learning/services/agent/learning_agent_planner_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds one target timeline across all learning surfaces', () {
    final fixture = _MemoryFixture.build();
    final targetRecords = fixture.result.records
        .where((record) => record.targetId == fixture.point.id)
        .toList();

    expect(targetRecords, hasLength(7));
    expect(
      targetRecords.map((record) => record.type).toSet(),
      equals(LearningAgentMemoryRecordType.values.toSet()),
    );

    final legacyAnswer = targetRecords.singleWhere(
      (record) => record.type == LearningAgentMemoryRecordType.knowledgeAnswer,
    );
    expect(
      legacyAnswer.targetResolution,
      LearningAgentMemoryTargetResolution.sourceCitation,
    );
    expect(legacyAnswer.title, '请比较事件循环');

    final reflection = targetRecords.singleWhere(
      (record) => record.type == LearningAgentMemoryRecordType.agentReflection,
    );
    expect(
      reflection.targetResolution,
      LearningAgentMemoryTargetResolution.practiceRouting,
    );
    expect(reflection.summary, '我需要继续区分任务队列。');
  });

  test('queries recent records, follow-ups, misconceptions and review state',
      () {
    final fixture = _MemoryFixture.build();
    final store = LearningAgentMemoryStore(
      AgentSessionMemoryIndex([fixture.agentSession]),
      records: fixture.result.records,
      reviewSchedules: fixture.result.reviewSchedules,
    );

    final snapshot = store.query(targetId: fixture.point.id, recentLimit: 3);
    expect(snapshot.recordCount, 7);
    expect(snapshot.recentRecords, hasLength(3));
    expect(
      snapshot.openFollowUps.map((item) => item.question),
      containsAll(<String>[
        '说明微任务队列',
        '请重新回答并补充边界',
        '完成重测练习',
        '继续解释队列边界',
      ]),
    );
    expect(
      snapshot.openFollowUps.map((item) => item.question),
      isNot(contains('请比较事件循环')),
    );
    expect(
      snapshot.openFollowUps.map((item) => item.question),
      isNot(contains('解释事件循环')),
    );

    expect(snapshot.stableMisconceptions, hasLength(1));
    expect(snapshot.stableMisconceptions.single.label, '把 Future 当成线程');
    expect(snapshot.stableMisconceptions.single.occurrenceCount, 2);

    final accuracy = snapshot.weakDimensions.singleWhere(
      (dimension) => dimension.key == 'accuracy',
    );
    expect(accuracy.occurrenceCount, 4);
    expect(snapshot.nextReviewAt, fixture.at(5));

    final tutorOnly = store.query(
      targetId: fixture.point.id,
      recordTypes: const {LearningAgentMemoryRecordType.tutor},
    );
    expect(tutorOnly.records, hasLength(2));
    expect(tutorOnly.openFollowUps.single.question, '说明微任务队列');
    expect(tutorOnly.nextReviewAt, isNull);

    final programmingGoal = store.query(
      goal: LearningAgentGoal.programmingFoundations,
      targetId: fixture.point.id,
    );
    expect(programmingGoal.records, hasLength(7));
    expect(
      store
          .recordsForType(
            LearningAgentMemoryRecordType.programmingExercise,
            goal: LearningAgentGoal.programmingFoundations,
            targetId: fixture.point.id,
          )
          .single
          .sourceId,
      'attempt-1',
    );

    final targetMemory = store.memoryForTarget(fixture.point.id);
    expect(targetMemory.recordCount, 7);
    expect(targetMemory.openFollowUpCount, 4);
    expect(targetMemory.latestOpenFollowUpQuestion, '继续解释队列边界');

    final legacyStore = LearningAgentMemoryStore(
      AgentSessionMemoryIndex([fixture.agentSession]),
    );
    final legacyTargetMemory =
        legacyStore.memoryForTarget(fixture.agentSession.targetId);
    expect(legacyTargetMemory.openFollowUpCount, 1);
    expect(
      legacyTargetMemory.latestOpenFollowUpQuestion,
      '继续解释队列边界',
    );
  });
}

class _MemoryFixture {
  final DateTime base;
  final KnowledgePoint point;
  final LearningSession agentSession;
  final LearningAgentMemoryBuildResult result;

  const _MemoryFixture({
    required this.base,
    required this.point,
    required this.agentSession,
    required this.result,
  });

  DateTime at(int day) => base.add(Duration(days: day));

  factory _MemoryFixture.build() {
    final base = DateTime.utc(2026, 7, 1, 9);
    DateTime at(int day) => base.add(Duration(days: day));

    final point = KnowledgePoint(
      id: 'kp-event-loop',
      title: 'Dart 事件循环',
      summary: '事件队列与微任务队列的调度关系。',
      kind: KnowledgePointKind.concept,
      createdAt: at(0),
      updatedAt: at(0),
    );
    final exercise = ProgrammingExercise(
      id: 'exercise-1',
      knowledgePointId: point.id,
      kind: ProgrammingExerciseKind.explanation,
      prompt: '解释事件循环的执行顺序',
      referenceAnswer: '先同步，再微任务，再事件任务。',
      conceptAccuracyCriterion: '顺序正确',
      reasoningProcessCriterion: '说明原因',
      evidenceUseCriterion: '引用文档',
      clarityCriterion: '表达清晰',
      sourceStatus: SourceStatus.verified,
      citationIds: const ['chunk-loop'],
      createdAt: at(0),
      updatedAt: at(0),
    );
    final retest = ProgrammingExercise(
      id: 'exercise-retest',
      knowledgePointId: point.id,
      kind: ProgrammingExerciseKind.boundaryJudgment,
      prompt: '完成重测练习',
      referenceAnswer: '判断微任务插队边界。',
      conceptAccuracyCriterion: '边界正确',
      reasoningProcessCriterion: '推理完整',
      evidenceUseCriterion: '引用文档',
      clarityCriterion: '表达清晰',
      sourceStatus: SourceStatus.verified,
      citationIds: const ['chunk-loop'],
      isRetest: true,
      parentAttemptId: 'attempt-1',
      createdAt: at(6),
      updatedAt: at(6),
    );
    final question = Question(
      id: 'question-1',
      deckId: 'deck-1',
      knowledgePointId: point.id,
      type: QuestionType.multipleChoice,
      content: '微任务何时执行？',
      answer: '同步代码之后',
      sourceStatus: SourceStatus.verified,
      citationIds: const ['chunk-loop'],
      nextReviewAt: at(10),
    );

    final knowledgeAnswerSession = LearningSession(
      id: 'answer-session',
      mode: LearningSessionMode.knowledgeAnswer,
      targetId: 'chunk-loop',
      startedAt: at(1),
      endedAt: at(1),
      summary: '知识库问答: 请比较事件循环\n'
          '回答: 它协调同步任务、微任务和事件任务。\n'
          '继续追问: 请比较事件循环\n'
          '引用: chunk-loop',
    );
    final tutorSession = LearningSession(
      id: 'tutor-session',
      mode: LearningSessionMode.tutor,
      targetId: point.id,
      startedAt: at(2),
      endedAt: at(3),
    );
    final interviewSession = LearningSession(
      id: 'interview-session',
      mode: LearningSessionMode.interview,
      targetId: point.id,
      startedAt: at(4),
      endedAt: at(4),
    );
    final agentSession = LearningSession(
      id: 'agent-session',
      mode: LearningSessionMode.agentSession,
      targetId: 'programming_exercise:${exercise.id}',
      startedAt: at(7),
      endedAt: at(7),
      summary: '编程知识学习 · 事件循环复盘\n'
          '目标: Dart 事件循环\n'
          '成功标准: 1/2\n'
          '下次追问: 继续解释队列边界\n'
          '复盘: 我需要继续区分任务队列。',
    );

    final tutorTurns = [
      TutorTurn(
        id: 'tutor-1',
        sessionId: tutorSession.id,
        knowledgePointId: point.id,
        questionText: 'Future 是线程吗？',
        userAnswer: '是。',
        aiFeedback: 'Future 表示异步结果，不等于线程。',
        misconception: '把 Future 当成线程',
        nextQuestion: '解释事件循环',
        citationIds: const ['chunk-loop'],
        accuracyScore: 60,
        createdAt: at(2),
      ),
      TutorTurn(
        id: 'tutor-2',
        sessionId: tutorSession.id,
        knowledgePointId: point.id,
        questionText: '解释事件循环',
        userAnswer: '先跑同步代码。',
        aiFeedback: '还需要说明微任务队列。',
        misconception: '把 Future 当成线程',
        nextQuestion: '说明微任务队列',
        citationIds: const ['chunk-loop'],
        accuracyScore: 70,
        createdAt: at(3),
      ),
    ];
    final interviewTurn = InterviewTurn(
      id: 'interview-1',
      sessionId: interviewSession.id,
      questionText: '请比较事件循环',
      userAnswer: '有两个队列。',
      aiFeedback: '需要说明边界。',
      referenceAnswer: '同步、微任务、事件任务依次调度。',
      knowledgePointId: point.id,
      citationIds: const ['chunk-loop'],
      weakDimensions: const [
        InterviewScoreDimension.accuracy,
        InterviewScoreDimension.clarity,
      ],
      reviewDueAt: at(5),
      nextInterviewQuestion: '请重新回答并补充边界',
      createdAt: at(4),
    );
    final attempt = ProgrammingExerciseAttempt(
      id: 'attempt-1',
      exerciseId: exercise.id,
      knowledgePointId: point.id,
      userAnswer: '同步后执行事件队列。',
      feedback: '遗漏微任务队列。',
      conceptAccuracyScore: 70,
      reasoningProcessScore: 75,
      evidenceUseScore: 65,
      clarityScore: 70,
      misconceptionCode: 'missing_microtask_priority',
      misconceptionLabel: '遗漏微任务优先级',
      citationIds: const ['chunk-loop'],
      retestExerciseId: retest.id,
      createdAt: at(6),
    );
    final action = ProgrammingReviewAction(
      id: 'review-1',
      knowledgePointId: point.id,
      triggerType: ProgrammingReviewTriggerType.exerciseAttempt,
      triggerId: attempt.id,
      weakDimensions: const [ProgrammingWeakDimension.conceptAccuracy],
      citationIds: const ['chunk-loop'],
      reviewExerciseIds: const ['exercise-retest'],
      dueAt: at(8),
      createdAt: at(8),
    );

    final result = const LearningAgentMemoryTimelineBuilder().build(
      sessions: [
        knowledgeAnswerSession,
        tutorSession,
        interviewSession,
        agentSession,
      ],
      knowledgePoints: [point],
      knowledgePointSources: [
        KnowledgePointSource(
          knowledgePointId: point.id,
          sourceChunkId: 'chunk-loop',
        ),
      ],
      questions: [question],
      interviewTurns: [interviewTurn],
      tutorTurns: tutorTurns,
      programmingExercises: [exercise, retest],
      programmingAttempts: [attempt],
      reviewActions: [action],
    );
    return _MemoryFixture(
      base: base,
      point: point,
      agentSession: agentSession,
      result: result,
    );
  }
}
