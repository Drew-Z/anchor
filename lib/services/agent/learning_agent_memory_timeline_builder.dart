import '../../data/models/grounded_claim.dart';
import '../../data/models/interview_turn.dart';
import '../../data/models/knowledge_point.dart';
import '../../data/models/knowledge_point_source.dart';
import '../../data/models/learning_session.dart';
import '../../data/models/programming_exercise.dart';
import '../../data/models/programming_exercise_attempt.dart';
import '../../data/models/programming_review_action.dart';
import '../../data/models/question.dart';
import '../../data/models/tutor_turn.dart';
import 'agent_session_memory_index.dart';
import 'knowledge_answer_session_summary.dart';
import 'learning_agent_memory_record.dart';
import 'learning_agent_planner_service.dart';

class LearningAgentMemoryTimelineBuilder {
  static const int _weakScoreThreshold = 80;

  const LearningAgentMemoryTimelineBuilder();

  LearningAgentMemoryBuildResult build({
    required List<LearningSession> sessions,
    required List<KnowledgePoint> knowledgePoints,
    required List<KnowledgePointSource> knowledgePointSources,
    required List<Question> questions,
    required List<InterviewTurn> interviewTurns,
    required List<TutorTurn> tutorTurns,
    required List<ProgrammingExercise> programmingExercises,
    required List<ProgrammingExerciseAttempt> programmingAttempts,
    required List<ProgrammingReviewAction> reviewActions,
  }) {
    final pointsById = {
      for (final point in knowledgePoints) point.id: point,
    };
    final sessionsById = {
      for (final session in sessions) session.id: session,
    };
    final questionsById = {
      for (final question in questions) question.id: question,
    };
    final exercisesById = {
      for (final exercise in programmingExercises) exercise.id: exercise,
    };
    final pointIdsByChunkId = <String, Set<String>>{};
    for (final relation in knowledgePointSources) {
      pointIdsByChunkId
          .putIfAbsent(relation.sourceChunkId, () => <String>{})
          .add(relation.knowledgePointId);
    }

    final records = <LearningAgentMemoryRecord>[
      ..._knowledgeAnswerRecords(
        sessions: sessions,
        pointsById: pointsById,
        pointIdsByChunkId: pointIdsByChunkId,
      ),
      ..._tutorRecords(tutorTurns, pointsById),
      ..._interviewRecords(
        turns: interviewTurns,
        sessionsById: sessionsById,
        pointsById: pointsById,
      ),
      ..._programmingAttemptRecords(
        attempts: programmingAttempts,
        exercisesById: exercisesById,
        pointsById: pointsById,
      ),
      ..._agentReflectionRecords(
        sessions: sessions,
        pointsById: pointsById,
        questionsById: questionsById,
        exercisesById: exercisesById,
      ),
      ..._reviewActionRecords(reviewActions, pointsById),
    ]..sort(_compareRecordsNewestFirst);

    final reviewSchedules = questions
        .where(
      (question) =>
          question.knowledgePointId != null &&
          question.nextReviewAt != null &&
          pointsById.containsKey(question.knowledgePointId),
    )
        .map((question) {
      final point = pointsById[question.knowledgePointId]!;
      return LearningAgentMemoryReviewSchedule(
        id: 'question-review:${question.id}',
        targetId: point.id,
        goals: _goalsForPoint(point),
        dueAt: question.nextReviewAt!,
      );
    }).toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));

    return LearningAgentMemoryBuildResult(
      records: List.unmodifiable(records),
      reviewSchedules: List.unmodifiable(reviewSchedules),
    );
  }

  Iterable<LearningAgentMemoryRecord> _knowledgeAnswerRecords({
    required List<LearningSession> sessions,
    required Map<String, KnowledgePoint> pointsById,
    required Map<String, Set<String>> pointIdsByChunkId,
  }) sync* {
    for (final session in sessions) {
      if (session.mode != LearningSessionMode.knowledgeAnswer) continue;
      final summary = KnowledgeAnswerSessionSummaryRecord.fromSession(session);
      final targets = _knowledgeAnswerTargets(
        session: session,
        summary: summary,
        pointsById: pointsById,
        pointIdsByChunkId: pointIdsByChunkId,
      );
      for (final target in targets) {
        final point =
            target.targetId == null ? null : pointsById[target.targetId];
        yield LearningAgentMemoryRecord(
          id: _scopedRecordId(session.id, target.targetId),
          type: LearningAgentMemoryRecordType.knowledgeAnswer,
          sourceId: session.id,
          sessionId: session.id,
          targetId: target.targetId,
          targetLabel: point?.title,
          targetResolution: target.resolution,
          goals: _goalsForPoint(point),
          occurredAt: session.endedAt ?? session.startedAt,
          title: _nonEmpty(summary.question, fallback: '历史知识库问答'),
          summary: _nonEmpty(
            summary.answer,
            fallback: summary.sourceGaps.isEmpty
                ? '未记录回答正文'
                : '来源缺口：${summary.sourceGaps.join('、')}',
          ),
          handledPrompts: _values(summary.question),
          followUpQuestions: _cleanStrings(summary.followUpQuestions),
          citationIds: _cleanStrings(summary.citationIds),
          evidenceSufficient: summary.hasCleanEvidence,
        );
      }
    }
  }

  List<_ResolvedMemoryTarget> _knowledgeAnswerTargets({
    required LearningSession session,
    required KnowledgeAnswerSessionSummaryRecord summary,
    required Map<String, KnowledgePoint> pointsById,
    required Map<String, Set<String>> pointIdsByChunkId,
  }) {
    final summaryPointId = summary.knowledgePointId?.trim();
    if (summaryPointId != null && pointsById.containsKey(summaryPointId)) {
      return [
        _ResolvedMemoryTarget(
          targetId: summaryPointId,
          resolution: LearningAgentMemoryTargetResolution.direct,
        ),
      ];
    }

    final storedTargetId = session.targetId?.trim();
    if (storedTargetId != null && pointsById.containsKey(storedTargetId)) {
      return [
        _ResolvedMemoryTarget(
          targetId: storedTargetId,
          resolution: LearningAgentMemoryTargetResolution.direct,
        ),
      ];
    }

    final inferredPointIds = <String>{};
    for (final citationId in <String>{
      ...summary.citationIds,
      if (storedTargetId != null) storedTargetId,
    }) {
      inferredPointIds.addAll(pointIdsByChunkId[citationId] ?? const {});
    }
    final knownIds = inferredPointIds
        .where(pointsById.containsKey)
        .toList(growable: false)
      ..sort();
    if (knownIds.isNotEmpty) {
      return [
        for (final pointId in knownIds)
          _ResolvedMemoryTarget(
            targetId: pointId,
            resolution: LearningAgentMemoryTargetResolution.sourceCitation,
          ),
      ];
    }
    return const [
      _ResolvedMemoryTarget(
        resolution: LearningAgentMemoryTargetResolution.unresolved,
      ),
    ];
  }

  Iterable<LearningAgentMemoryRecord> _tutorRecords(
    List<TutorTurn> turns,
    Map<String, KnowledgePoint> pointsById,
  ) sync* {
    for (final turn in turns) {
      final point = pointsById[turn.knowledgePointId];
      final weakDimensions = <LearningAgentMemoryWeakDimension>[
        if (turn.groundingDisposition != GroundingDisposition.legacy &&
            turn.accuracyScore < _weakScoreThreshold)
          _weakDimension(
            key: 'accuracy',
            label: '准确性',
            evidenceId: turn.id,
          ),
        if (!turn.evidenceSufficient)
          _weakDimension(
            key: 'evidence_use',
            label: '代码或文档依据',
            evidenceId: turn.id,
          ),
      ];
      yield LearningAgentMemoryRecord(
        id: 'tutor:${turn.id}',
        type: LearningAgentMemoryRecordType.tutor,
        sourceId: turn.id,
        sessionId: turn.sessionId,
        targetId: turn.knowledgePointId,
        targetLabel: point?.title,
        targetResolution: LearningAgentMemoryTargetResolution.childRecord,
        goals: _goalsForPoint(point),
        occurredAt: turn.createdAt,
        title: _nonEmpty(turn.questionText, fallback: '导师学习记录'),
        summary: _nonEmpty(
          turn.aiFeedback,
          fallback: _nonEmpty(turn.misconception, fallback: '已完成导师回合'),
        ),
        handledPrompts: _values(turn.questionText),
        followUpQuestions: _values(turn.nextQuestion),
        misconceptions: _misconceptions(
          code: '',
          label: turn.misconception,
        ),
        weakDimensions: weakDimensions,
        citationIds: _cleanStrings(turn.citationIds),
        evidenceSufficient: turn.evidenceSufficient &&
            turn.groundingDisposition == GroundingDisposition.grounded,
      );
    }
  }

  Iterable<LearningAgentMemoryRecord> _interviewRecords({
    required List<InterviewTurn> turns,
    required Map<String, LearningSession> sessionsById,
    required Map<String, KnowledgePoint> pointsById,
  }) sync* {
    for (final turn in turns) {
      final targets = _interviewTargets(
        turn: turn,
        session: sessionsById[turn.sessionId],
        pointsById: pointsById,
      );
      for (final target in targets) {
        final point =
            target.targetId == null ? null : pointsById[target.targetId];
        yield LearningAgentMemoryRecord(
          id: _scopedRecordId('interview:${turn.id}', target.targetId),
          type: LearningAgentMemoryRecordType.interview,
          sourceId: turn.id,
          sessionId: turn.sessionId,
          targetId: target.targetId,
          targetLabel: point?.title,
          targetResolution: target.resolution,
          goals: _goalsForPoint(point),
          occurredAt: turn.createdAt,
          title: _nonEmpty(turn.questionText, fallback: '面试回答'),
          summary: _nonEmpty(turn.aiFeedback, fallback: '已完成面试回合'),
          handledPrompts: _values(turn.questionText),
          followUpQuestions: _values(turn.nextInterviewQuestion),
          weakDimensions: turn.weakDimensions
              .map((dimension) => _interviewWeakDimension(dimension, turn.id))
              .toList(growable: false),
          reviewDueAt: turn.reviewDueAt,
          citationIds: _cleanStrings(turn.citationIds),
          evidenceSufficient:
              turn.groundingDisposition == GroundingDisposition.grounded,
        );
      }
    }
  }

  List<_ResolvedMemoryTarget> _interviewTargets({
    required InterviewTurn turn,
    required LearningSession? session,
    required Map<String, KnowledgePoint> pointsById,
  }) {
    final directId = turn.knowledgePointId?.trim();
    if (directId != null && pointsById.containsKey(directId)) {
      return [
        _ResolvedMemoryTarget(
          targetId: directId,
          resolution: LearningAgentMemoryTargetResolution.childRecord,
        ),
      ];
    }

    final scopeIds = <String>{
      ...turn.weakKnowledgePointIds.where(pointsById.containsKey),
      ...?session?.targetId
          ?.split('\x00')
          .map((id) => id.trim())
          .where(pointsById.containsKey),
    }.toList()
      ..sort();
    if (scopeIds.isNotEmpty) {
      return [
        for (final pointId in scopeIds)
          _ResolvedMemoryTarget(
            targetId: pointId,
            resolution: LearningAgentMemoryTargetResolution.sessionScope,
          ),
      ];
    }
    return const [
      _ResolvedMemoryTarget(
        resolution: LearningAgentMemoryTargetResolution.unresolved,
      ),
    ];
  }

  Iterable<LearningAgentMemoryRecord> _programmingAttemptRecords({
    required List<ProgrammingExerciseAttempt> attempts,
    required Map<String, ProgrammingExercise> exercisesById,
    required Map<String, KnowledgePoint> pointsById,
  }) sync* {
    for (final attempt in attempts) {
      final exercise = exercisesById[attempt.exerciseId];
      final point = pointsById[attempt.knowledgePointId];
      final retest = attempt.retestExerciseId == null
          ? null
          : exercisesById[attempt.retestExerciseId];
      final weakDimensions = <LearningAgentMemoryWeakDimension>[
        if (attempt.conceptAccuracyScore < _weakScoreThreshold)
          _weakDimension(
            key: 'accuracy',
            label: '准确性',
            evidenceId: attempt.id,
          ),
        if (attempt.reasoningProcessScore < _weakScoreThreshold)
          _weakDimension(
            key: 'reasoning_process',
            label: '推理过程',
            evidenceId: attempt.id,
          ),
        if (attempt.evidenceUseScore < _weakScoreThreshold)
          _weakDimension(
            key: 'evidence_use',
            label: '代码或文档依据',
            evidenceId: attempt.id,
          ),
        if (attempt.clarityScore < _weakScoreThreshold)
          _weakDimension(
            key: 'clarity',
            label: '表达清晰',
            evidenceId: attempt.id,
          ),
      ];
      yield LearningAgentMemoryRecord(
        id: 'programming-attempt:${attempt.id}',
        type: LearningAgentMemoryRecordType.programmingExercise,
        sourceId: attempt.id,
        targetId: attempt.knowledgePointId,
        targetLabel: point?.title,
        targetResolution: LearningAgentMemoryTargetResolution.childRecord,
        goals: _goalsForPoint(point),
        occurredAt: attempt.createdAt,
        title: _nonEmpty(exercise?.prompt, fallback: '编程练习'),
        summary: [
          '平均分 ${attempt.averageScore}',
          if (attempt.misconceptionLabel.trim().isNotEmpty)
            '误区：${attempt.misconceptionLabel.trim()}',
          if (attempt.feedback.trim().isNotEmpty) attempt.feedback.trim(),
        ].join(' · '),
        handledPrompts: _values(exercise?.prompt),
        followUpQuestions: _values(
          retest?.prompt ??
              (attempt.retestExerciseId == null
                  ? null
                  : '完成重测练习 ${attempt.retestExerciseId}'),
        ),
        misconceptions: _misconceptions(
          code: attempt.misconceptionCode,
          label: attempt.misconceptionLabel,
        ),
        weakDimensions: weakDimensions,
        citationIds: _cleanStrings(attempt.citationIds),
        evidenceSufficient: attempt.evidenceSufficient &&
            attempt.groundingDisposition == GroundingDisposition.grounded,
      );
    }
  }

  Iterable<LearningAgentMemoryRecord> _agentReflectionRecords({
    required List<LearningSession> sessions,
    required Map<String, KnowledgePoint> pointsById,
    required Map<String, Question> questionsById,
    required Map<String, ProgrammingExercise> exercisesById,
  }) sync* {
    for (final session in sessions) {
      if (session.mode != LearningSessionMode.agentSession) continue;
      final summary = AgentSessionSummaryRecord.fromSession(session);
      final target = _agentTarget(
        targetId: session.targetId,
        pointsById: pointsById,
        questionsById: questionsById,
        exercisesById: exercisesById,
      );
      final point =
          target.targetId == null ? null : pointsById[target.targetId];
      yield LearningAgentMemoryRecord(
        id: 'agent-reflection:${session.id}',
        type: LearningAgentMemoryRecordType.agentReflection,
        sourceId: session.id,
        sessionId: session.id,
        targetId: target.targetId,
        targetLabel: point?.title ?? summary.target,
        targetResolution: target.resolution,
        goals: summary.goal == null
            ? _goalsForPoint(point)
            : <LearningAgentGoal>{summary.goal!},
        occurredAt: session.endedAt ?? session.startedAt,
        title: summary.title,
        summary: _nonEmpty(
          summary.note,
          fallback: _nonEmpty(
            summary.confirmedCriteria,
            fallback: _nonEmpty(summary.criteria, fallback: '已保存 Agent 复盘'),
          ),
        ),
        handledPrompts: _values(summary.activeQuestion),
        followUpQuestions: _values(summary.nextQuestion),
      );
    }
  }

  _ResolvedMemoryTarget _agentTarget({
    required String? targetId,
    required Map<String, KnowledgePoint> pointsById,
    required Map<String, Question> questionsById,
    required Map<String, ProgrammingExercise> exercisesById,
  }) {
    final normalized = targetId?.trim();
    if (normalized == null || normalized.isEmpty) {
      return const _ResolvedMemoryTarget(
        resolution: LearningAgentMemoryTargetResolution.unresolved,
      );
    }
    if (pointsById.containsKey(normalized)) {
      return _ResolvedMemoryTarget(
        targetId: normalized,
        resolution: LearningAgentMemoryTargetResolution.direct,
      );
    }

    String? pointId;
    if (normalized.startsWith('question:')) {
      pointId = questionsById[normalized.substring('question:'.length)]
          ?.knowledgePointId;
    } else if (normalized.startsWith('programming_exercise:')) {
      pointId =
          exercisesById[normalized.substring('programming_exercise:'.length)]
              ?.knowledgePointId;
    } else {
      pointId = questionsById[normalized]?.knowledgePointId ??
          exercisesById[normalized]?.knowledgePointId;
    }
    if (pointId != null && pointsById.containsKey(pointId)) {
      return _ResolvedMemoryTarget(
        targetId: pointId,
        resolution: LearningAgentMemoryTargetResolution.practiceRouting,
      );
    }
    return _ResolvedMemoryTarget(
      targetId: normalized,
      resolution: LearningAgentMemoryTargetResolution.unresolved,
    );
  }

  Iterable<LearningAgentMemoryRecord> _reviewActionRecords(
    List<ProgrammingReviewAction> actions,
    Map<String, KnowledgePoint> pointsById,
  ) sync* {
    for (final action in actions) {
      final point = pointsById[action.knowledgePointId];
      final dimensionLabels =
          action.weakDimensions.map((dimension) => dimension.label).toList();
      final materialCount =
          action.reviewQuestionIds.length + action.reviewExerciseIds.length;
      yield LearningAgentMemoryRecord(
        id: 'review-action:${action.id}',
        type: LearningAgentMemoryRecordType.reviewAction,
        sourceId: action.id,
        targetId: action.knowledgePointId,
        targetLabel: point?.title,
        targetResolution: LearningAgentMemoryTargetResolution.direct,
        goals: _goalsForPoint(point),
        occurredAt: action.completedAt ?? action.createdAt,
        title: action.isCompleted ? '已完成复习动作' : '待处理复习动作',
        summary: [
          if (dimensionLabels.isNotEmpty) '薄弱维度：${dimensionLabels.join('、')}',
          '$materialCount 个复习材料',
        ].join(' · '),
        weakDimensions: action.weakDimensions
            .map(
              (dimension) => _programmingWeakDimension(
                dimension,
                action.triggerId,
              ),
            )
            .toList(growable: false),
        weakPrerequisites: action.prerequisiteKnowledgePointIds
            .map((id) => pointsById[id])
            .whereType<KnowledgePoint>()
            .map(
              (prerequisite) => LearningAgentMemoryWeakPrerequisite(
                targetId: prerequisite.id,
                targetLabel: prerequisite.title,
              ),
            )
            .toList(growable: false),
        reviewDueAt: action.dueAt,
        reviewCompletedAt: action.completedAt,
        citationIds: _cleanStrings(action.citationIds),
      );
    }
  }

  static Set<LearningAgentGoal> _goalsForPoint(KnowledgePoint? point) {
    if (point == null) return const <LearningAgentGoal>{};
    return Set.unmodifiable(<LearningAgentGoal>{
      LearningAgentGoal.aiInterviewPrep,
      if (point.kind.isProjectUnderstanding)
        LearningAgentGoal.projectWalkthrough
      else
        LearningAgentGoal.programmingFoundations,
    });
  }

  static LearningAgentMemoryWeakDimension _interviewWeakDimension(
    InterviewScoreDimension dimension,
    String evidenceId,
  ) {
    switch (dimension) {
      case InterviewScoreDimension.accuracy:
        return _weakDimension(
          key: 'accuracy',
          label: '准确性',
          evidenceId: evidenceId,
        );
      case InterviewScoreDimension.projectDetail:
        return _weakDimension(
          key: 'project_detail',
          label: '项目细节',
          evidenceId: evidenceId,
        );
      case InterviewScoreDimension.engineering:
        return _weakDimension(
          key: 'engineering',
          label: '工程判断',
          evidenceId: evidenceId,
        );
      case InterviewScoreDimension.clarity:
        return _weakDimension(
          key: 'clarity',
          label: '表达清晰',
          evidenceId: evidenceId,
        );
    }
  }

  static LearningAgentMemoryWeakDimension _programmingWeakDimension(
    ProgrammingWeakDimension dimension,
    String evidenceId,
  ) {
    switch (dimension) {
      case ProgrammingWeakDimension.conceptAccuracy:
        return _weakDimension(
          key: 'accuracy',
          label: '准确性',
          evidenceId: evidenceId,
        );
      case ProgrammingWeakDimension.reasoningProcess:
        return _weakDimension(
          key: 'reasoning_process',
          label: '推理过程',
          evidenceId: evidenceId,
        );
      case ProgrammingWeakDimension.evidenceUse:
        return _weakDimension(
          key: 'evidence_use',
          label: '代码或文档依据',
          evidenceId: evidenceId,
        );
      case ProgrammingWeakDimension.clarity:
        return _weakDimension(
          key: 'clarity',
          label: '表达清晰',
          evidenceId: evidenceId,
        );
    }
  }

  static LearningAgentMemoryWeakDimension _weakDimension({
    required String key,
    required String label,
    required String evidenceId,
  }) {
    return LearningAgentMemoryWeakDimension(
      key: key,
      label: label,
      evidenceId: evidenceId,
    );
  }

  static List<LearningAgentMemoryMisconception> _misconceptions({
    required String code,
    required String label,
  }) {
    final normalizedLabel = label.trim();
    if (normalizedLabel.isEmpty) return const [];
    final normalizedCode = code.trim().toLowerCase();
    final key = normalizedCode.isNotEmpty
        ? 'code:$normalizedCode'
        : 'label:${_normalizeText(normalizedLabel)}';
    return [
      LearningAgentMemoryMisconception(
        key: key,
        label: normalizedLabel,
      ),
    ];
  }

  static List<String> _values(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return const [];
    return [normalized];
  }

  static List<String> _cleanStrings(Iterable<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  static String _nonEmpty(String? value, {required String fallback}) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? fallback : normalized;
  }

  static String _normalizeText(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
  }

  static String _scopedRecordId(String sourceId, String? targetId) {
    final normalized = targetId?.trim();
    if (normalized == null || normalized.isEmpty) return sourceId;
    return '$sourceId@$normalized';
  }

  static int _compareRecordsNewestFirst(
    LearningAgentMemoryRecord a,
    LearningAgentMemoryRecord b,
  ) {
    final time = b.occurredAt.compareTo(a.occurredAt);
    if (time != 0) return time;
    return a.id.compareTo(b.id);
  }
}

class _ResolvedMemoryTarget {
  final String? targetId;
  final LearningAgentMemoryTargetResolution resolution;

  const _ResolvedMemoryTarget({
    this.targetId,
    required this.resolution,
  });
}
