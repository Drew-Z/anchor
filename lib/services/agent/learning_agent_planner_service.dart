import '../../data/models/knowledge_point.dart';
import '../../data/models/programming_exercise.dart';
import '../../data/models/question.dart';
import 'learning_agent_next_action.dart';
import 'learning_agent_practice_target.dart';

enum LearningAgentKnowledgeScope {
  mixed('mixed', '项目与编程知识'),
  project('project', '项目知识'),
  programming('programming', '编程知识');

  final String value;
  final String label;

  const LearningAgentKnowledgeScope(this.value, this.label);

  bool includesPoint(KnowledgePoint point) {
    switch (this) {
      case LearningAgentKnowledgeScope.mixed:
        return true;
      case LearningAgentKnowledgeScope.project:
        return point.kind.isProjectUnderstanding;
      case LearningAgentKnowledgeScope.programming:
        return point.kind == KnowledgePointKind.concept;
    }
  }
}

enum LearningAgentGoal {
  aiInterviewPrep('ai_interview_prep', 'AI 应用开发面试'),
  projectWalkthrough('project_walkthrough', '讲清项目细节'),
  programmingFoundations('programming_foundations', '编程知识学习');

  final String value;
  final String label;
  const LearningAgentGoal(this.value, this.label);

  static LearningAgentGoal fromString(String value) {
    return LearningAgentGoal.values.firstWhere(
      (goal) => goal.value == value,
      orElse: () => LearningAgentGoal.aiInterviewPrep,
    );
  }

  LearningAgentKnowledgeScope get knowledgeScope {
    switch (this) {
      case LearningAgentGoal.aiInterviewPrep:
        return LearningAgentKnowledgeScope.mixed;
      case LearningAgentGoal.projectWalkthrough:
        return LearningAgentKnowledgeScope.project;
      case LearningAgentGoal.programmingFoundations:
        return LearningAgentKnowledgeScope.programming;
    }
  }
}

enum LearningAgentStepType {
  importSources,
  verifyQuestions,
  handleFollowUps,
  tutor,
  interview,
  practice,
  review;
}

class LearningAgentReadiness {
  final int evidenceBackedPointCount;
  final int evidenceGapPointCount;
  final int practiceablePointCount;
  final int verifiedQuestionCount;
  final int verifiedProgrammingExerciseCount;
  final int pendingQuestionCount;
  final int pendingProgrammingExerciseCount;

  const LearningAgentReadiness({
    required this.evidenceBackedPointCount,
    this.evidenceGapPointCount = 0,
    required this.practiceablePointCount,
    required this.verifiedQuestionCount,
    this.verifiedProgrammingExerciseCount = 0,
    required this.pendingQuestionCount,
    this.pendingProgrammingExerciseCount = 0,
  });

  bool get canTutor => evidenceBackedPointCount > 0;
  bool get canInterview => evidenceBackedPointCount > 0;
  int get verifiedPracticeTargetCount =>
      verifiedQuestionCount + verifiedProgrammingExerciseCount;

  bool get canPractice => verifiedPracticeTargetCount > 0;
  bool get canReview => practiceablePointCount > 0;
  int get pendingVerificationCount =>
      pendingQuestionCount + pendingProgrammingExerciseCount;

  int get score {
    var value = 0;
    if (canTutor) value += 30;
    if (canInterview) value += 25;
    if (canPractice) value += 25;
    if (canReview) value += 20;
    return value;
  }
}

class LearningAgentMemoryState {
  final int goalSessionCount;
  final int goalOpenFollowUpCount;
  final String? latestGoalSessionTitle;
  final String? latestGoalSessionTarget;
  final DateTime? latestGoalSessionStartedAt;

  const LearningAgentMemoryState({
    required this.goalSessionCount,
    required this.goalOpenFollowUpCount,
    this.latestGoalSessionTitle,
    this.latestGoalSessionTarget,
    this.latestGoalSessionStartedAt,
  });

  bool get hasGoalSessions => goalSessionCount > 0;
  bool get hasOpenFollowUps => goalOpenFollowUpCount > 0;
  bool get hasLatestGoalSession => latestGoalSessionStartedAt != null;
}

class LearningAgentPlanStep {
  final LearningAgentStepType type;
  final String title;
  final String description;
  final bool enabled;
  final int targetCount;
  final String? disabledReason;

  const LearningAgentPlanStep({
    required this.type,
    required this.title,
    required this.description,
    required this.enabled,
    this.targetCount = 0,
    this.disabledReason,
  });
}

class LearningAgentFocusPoint {
  final String id;
  final String title;
  final String reason;
  final int masteryLevel;
  final int difficulty;
  final int interviewRelevance;
  final int evidenceChunkCount;
  final int verifiedQuestionCount;
  final int verifiedProgrammingExerciseCount;

  const LearningAgentFocusPoint({
    required this.id,
    required this.title,
    required this.reason,
    required this.masteryLevel,
    required this.difficulty,
    required this.interviewRelevance,
    required this.evidenceChunkCount,
    required this.verifiedQuestionCount,
    this.verifiedProgrammingExerciseCount = 0,
  });

  int get verifiedPracticeTargetCount =>
      verifiedQuestionCount + verifiedProgrammingExerciseCount;
}

class LearningAgentSessionSummary {
  final LearningAgentGoal goal;
  final LearningAgentPlanStep? nextStep;
  final LearningAgentFocusPoint? focusPoint;
  final LearningAgentPracticeTarget? practiceTarget;
  final String title;
  final String objective;
  final String targetLabel;
  final String evidenceConstraint;
  final String? memoryReminder;
  final List<String> successCriteria;
  final List<String> reflectionPrompts;

  const LearningAgentSessionSummary({
    required this.goal,
    required this.nextStep,
    required this.focusPoint,
    this.practiceTarget,
    required this.title,
    required this.objective,
    required this.targetLabel,
    required this.evidenceConstraint,
    required this.memoryReminder,
    required this.successCriteria,
    required this.reflectionPrompts,
  });

  bool get canStart => nextStep != null;
  LearningAgentKnowledgeScope get knowledgeScope => goal.knowledgeScope;
}

class LearningAgentPlan {
  final LearningAgentGoal goal;
  final LearningAgentReadiness readiness;
  final LearningAgentMemoryState memory;
  final List<LearningAgentPlanStep> steps;
  final List<LearningAgentFocusPoint> focusPoints;
  final List<String> blockers;
  final LearningAgentNextAction? nextAction;
  final LearningAgentSessionSummary sessionSummary;

  const LearningAgentPlan({
    required this.goal,
    required this.readiness,
    required this.memory,
    required this.steps,
    required this.sessionSummary,
    this.focusPoints = const [],
    this.blockers = const [],
    this.nextAction,
  });

  LearningAgentPlanStep? get nextStep => sessionSummary.nextStep;

  LearningAgentKnowledgeScope get knowledgeScope => goal.knowledgeScope;
  LearningAgentPracticeTarget? get practiceTarget =>
      sessionSummary.practiceTarget;
  bool get canStartSession => startBlockReason == null;
  bool get canExecuteNextAction => nextAction?.executable ?? canStartSession;

  String? get startBlockReason {
    final action = nextAction;
    if (action != null) {
      if (!action.executable) {
        return action.blockerMessage ?? '下一动作当前不可执行';
      }
      if (action.resumesCheckpoint) {
        return '存在未完成 Agent Session，应从原 plan snapshot 恢复';
      }
    }
    final sessionStep = sessionSummary.nextStep;
    if (!sessionSummary.canStart || sessionStep == null) {
      return '当前没有可执行的 Agent Session';
    }
    if (action?.stepTypeName != null &&
        action!.stepTypeName != sessionStep.type.name) {
      return '下一动作与 Session 步骤不一致，请刷新后再执行';
    }
    final expectedToolId =
        learningAgentToolIdForStepName(sessionStep.type.name);
    if (action?.toolId != null && action!.toolId != expectedToolId) {
      return '下一动作工具与 Session 步骤不一致，请刷新后再执行';
    }

    switch (sessionStep.type) {
      case LearningAgentStepType.importSources:
        return null;
      case LearningAgentStepType.verifyQuestions:
        return readiness.pendingVerificationCount > 0 ? null : '暂无待核验内容';
      case LearningAgentStepType.handleFollowUps:
        return memory.hasOpenFollowUps ? null : '暂无未处理追问';
      case LearningAgentStepType.tutor:
      case LearningAgentStepType.interview:
        return readiness.evidenceBackedPointCount > 0 ? null : '缺少带来源依据的知识点';
      case LearningAgentStepType.practice:
        return readiness.verifiedPracticeTargetCount > 0 ? null : '缺少已核验练习';
      case LearningAgentStepType.review:
        return readiness.practiceablePointCount > 0 ? null : '缺少可复习的已核验题目';
    }
  }
}

class LearningAgentPlannerService {
  final LearningAgentNextActionPolicy nextActionPolicy;

  const LearningAgentPlannerService({
    this.nextActionPolicy = const LearningAgentNextActionPolicy(),
  });

  LearningAgentPlan buildPlan({
    LearningAgentGoal goal = LearningAgentGoal.aiInterviewPrep,
    List<KnowledgePoint> knowledgePoints = const [],
    required List<KnowledgePoint> evidenceBackedPoints,
    required List<KnowledgePoint> practiceablePoints,
    required List<LearningAgentPracticeTarget> practiceTargets,
    required List<Question> pendingQuestions,
    List<ProgrammingExercise> pendingProgrammingExercises = const [],
    List<LearningAgentNextActionCandidate> nextActionCandidates = const [],
    DateTime? plannedAt,
    Map<String, int> evidenceChunkCountByPointId = const {},
    Map<String, int> practiceTargetCountByPointId = const {},
    Map<String, int> programmingExerciseCountByPointId = const {},
    int goalSessionCount = 0,
    int goalOpenFollowUpCount = 0,
    String? latestGoalSessionTitle,
    String? latestGoalSessionTarget,
    DateTime? latestGoalSessionStartedAt,
  }) {
    final planned = plannedAt ?? DateTime.now();
    final allPoints = knowledgePoints.isEmpty
        ? _uniquePoints([...evidenceBackedPoints, ...practiceablePoints])
        : _uniquePoints(knowledgePoints);
    final scopedAllPoints = _pointsForGoal(goal, allPoints);
    final scopedEvidenceBackedPoints = _pointsForGoal(
      goal,
      evidenceBackedPoints,
    );
    final scopedPracticeablePoints = _pointsForGoal(
      goal,
      practiceablePoints,
    );
    final scopedPointIds = {
      ...scopedAllPoints.map((point) => point.id),
      ...scopedEvidenceBackedPoints.map((point) => point.id),
      ...scopedPracticeablePoints.map((point) => point.id),
    };
    final scopedPracticeTargets = _practiceTargetsForPointIds(
      practiceTargets,
      scopedPointIds,
    );
    final scopedPendingQuestions = _questionsForPointIds(
      pendingQuestions,
      scopedPointIds,
    );
    final scopedPendingProgrammingExercises = pendingProgrammingExercises
        .where(
          (exercise) =>
              exercise.sourceStatus == SourceStatus.pending &&
              scopedPointIds.contains(exercise.knowledgePointId),
        )
        .toList(growable: false);
    final evidenceBackedPointIds =
        scopedEvidenceBackedPoints.map((point) => point.id).toSet();
    final evidenceGapPoints = scopedAllPoints
        .where((point) => !evidenceBackedPointIds.contains(point.id))
        .toList(growable: false);
    final externalEvidenceGapCount = nextActionCandidates
        .where(
          (candidate) =>
              candidate.priority == LearningAgentNextActionPriority.evidenceGap,
        )
        .map((candidate) => candidate.id)
        .toSet()
        .length;
    final readiness = LearningAgentReadiness(
      evidenceBackedPointCount: scopedEvidenceBackedPoints.length,
      evidenceGapPointCount:
          evidenceGapPoints.length + externalEvidenceGapCount,
      practiceablePointCount: scopedPracticeablePoints.length,
      verifiedQuestionCount: scopedPracticeTargets
          .where(
            (target) => target.type == LearningAgentPracticeTargetType.question,
          )
          .length,
      verifiedProgrammingExerciseCount: scopedPracticeTargets
          .where(
            (target) =>
                target.type ==
                LearningAgentPracticeTargetType.programmingExercise,
          )
          .length,
      pendingQuestionCount: scopedPendingQuestions.length,
      pendingProgrammingExerciseCount: scopedPendingProgrammingExercises.length,
    );
    final memory = LearningAgentMemoryState(
      goalSessionCount: goalSessionCount,
      goalOpenFollowUpCount: goalOpenFollowUpCount,
      latestGoalSessionTitle: latestGoalSessionTitle,
      latestGoalSessionTarget: latestGoalSessionTarget,
      latestGoalSessionStartedAt: latestGoalSessionStartedAt,
    );

    final steps = _stepsForGoal(goal, readiness, memory);
    final allFocusPoints = _focusPointsForGoal(
      goal: goal,
      evidenceBackedPoints: scopedEvidenceBackedPoints,
      practiceablePoints: scopedPracticeablePoints,
      evidenceChunkCountByPointId: evidenceChunkCountByPointId,
      practiceTargetCountByPointId: practiceTargetCountByPointId,
      programmingExerciseCountByPointId: programmingExerciseCountByPointId,
    );
    final generatedCandidates = _generatedNextActionCandidates(
      steps: steps,
      memory: memory,
      evidenceGapPoints: evidenceGapPoints,
      pendingQuestions: scopedPendingQuestions,
      pendingProgrammingExercises: scopedPendingProgrammingExercises,
      focusPoints: allFocusPoints,
      practiceTargets: scopedPracticeTargets,
      hasExternalOpenFollowUp: nextActionCandidates.any(
        (candidate) =>
            candidate.priority == LearningAgentNextActionPriority.openFollowUp,
      ),
      hasExternalEvidenceGap: nextActionCandidates.any(
        (candidate) =>
            candidate.priority == LearningAgentNextActionPriority.evidenceGap,
      ),
    );
    final validatedCandidates = _validatedNextActionCandidates(
      [...nextActionCandidates, ...generatedCandidates],
      steps,
    );
    final nextAction = nextActionPolicy.choose(
      goalValue: goal.value,
      plannedAt: planned,
      candidates: validatedCandidates,
    );
    final focusPoints = _focusPointsForAction(
      allFocusPoints,
      nextAction.targetId,
    ).take(3).toList(growable: false);
    final sessionSummary = _sessionSummaryForPlan(
      goal: goal,
      readiness: readiness,
      memory: memory,
      steps: steps,
      focusPoints: focusPoints,
      practiceTargets: scopedPracticeTargets,
      nextAction: nextAction,
    );
    final blockers = <String>{
      ..._blockers(readiness),
      if (!nextAction.executable && nextAction.blockerMessage != null)
        nextAction.blockerMessage!,
    }.toList(growable: false);

    return LearningAgentPlan(
      goal: goal,
      readiness: readiness,
      memory: memory,
      blockers: blockers,
      steps: steps,
      focusPoints: focusPoints,
      nextAction: nextAction,
      sessionSummary: sessionSummary,
    );
  }

  List<KnowledgePoint> _uniquePoints(List<KnowledgePoint> points) {
    final byId = <String, KnowledgePoint>{};
    for (final point in points) {
      byId.putIfAbsent(point.id, () => point);
    }
    return byId.values.toList(growable: false);
  }

  List<KnowledgePoint> _pointsForGoal(
    LearningAgentGoal goal,
    List<KnowledgePoint> points,
  ) {
    final scope = goal.knowledgeScope;
    return points.where(scope.includesPoint).toList(growable: false);
  }

  List<Question> _questionsForPointIds(
    List<Question> questions,
    Set<String> pointIds,
  ) {
    return questions.where((question) {
      final pointId = question.knowledgePointId?.trim();
      return pointId != null &&
          pointId.isNotEmpty &&
          pointIds.contains(pointId);
    }).toList(growable: false);
  }

  List<LearningAgentPracticeTarget> _practiceTargetsForPointIds(
    List<LearningAgentPracticeTarget> targets,
    Set<String> pointIds,
  ) {
    final scoped = targets.where((target) {
      return target.isExecutable && pointIds.contains(target.knowledgePointId);
    }).toList(growable: false);
    scoped.sort(_comparePracticeTargets);
    return scoped;
  }

  List<String> _blockers(LearningAgentReadiness readiness) {
    final blockers = <String>[];
    if (!readiness.canTutor) {
      blockers.add('缺少带来源依据的知识点');
    }
    if (readiness.evidenceGapPointCount > 0) {
      blockers.add('${readiness.evidenceGapPointCount} 个知识点仍有证据缺口');
    }
    if (!readiness.canPractice) {
      blockers.add('缺少已核验练习');
    }
    if (readiness.pendingVerificationCount > 0) {
      blockers.add('${readiness.pendingVerificationCount} 项内容仍待来源核验');
    }
    return blockers;
  }

  List<LearningAgentPlanStep> _stepsForGoal(
    LearningAgentGoal goal,
    LearningAgentReadiness readiness,
    LearningAgentMemoryState memory,
  ) {
    final preparationSteps = [
      LearningAgentPlanStep(
        type: LearningAgentStepType.handleFollowUps,
        title: '处理历史追问',
        description: '先回到当前目标未处理追问，延续上一轮留下的问题。',
        enabled: memory.hasOpenFollowUps,
        targetCount: memory.goalOpenFollowUpCount,
        disabledReason: '暂无未处理追问',
      ),
      LearningAgentPlanStep(
        type: LearningAgentStepType.importSources,
        title: '导入项目和编程资料',
        description: '先把 README、源码说明、官方文档或课程笔记变成可引用来源。',
        enabled: !readiness.canTutor || readiness.evidenceGapPointCount > 0,
        disabledReason: '已有带来源依据的知识点',
      ),
      LearningAgentPlanStep(
        type: LearningAgentStepType.verifyQuestions,
        title: '核验待确认内容',
        description: '把有引用的普通题或编程练习确认到已核验状态，正式练习才会使用它们。',
        enabled: readiness.pendingVerificationCount > 0,
        targetCount: readiness.pendingVerificationCount,
        disabledReason: '暂无待核验内容',
      ),
    ];

    switch (goal) {
      case LearningAgentGoal.aiInterviewPrep:
        return [
          ...preparationSteps,
          LearningAgentPlanStep(
            type: LearningAgentStepType.interview,
            title: '进行来源约束面试',
            description: '围绕有来源知识点追问项目细节、取舍、限制和表达。',
            enabled: readiness.canInterview,
            targetCount: readiness.evidenceBackedPointCount,
            disabledReason: '缺少带来源依据的知识点',
          ),
          LearningAgentPlanStep(
            type: LearningAgentStepType.review,
            title: '复习薄弱知识点',
            description: '用已核验普通题或编程练习巩固面试暴露出的薄弱点。',
            enabled: readiness.canReview,
            targetCount: readiness.practiceablePointCount,
            disabledReason: '缺少可复习的已核验题目',
          ),
        ];
      case LearningAgentGoal.projectWalkthrough:
        return [
          ...preparationSteps,
          LearningAgentPlanStep(
            type: LearningAgentStepType.tutor,
            title: '分层讲解项目知识点',
            description: '先用导师模式把项目材料讲成面试可表达的结构。',
            enabled: readiness.canTutor,
            targetCount: readiness.evidenceBackedPointCount,
            disabledReason: '缺少带来源依据的知识点',
          ),
          LearningAgentPlanStep(
            type: LearningAgentStepType.interview,
            title: '用追问检验项目表达',
            description: '确认自己能讲清实现细节、边界和工程选择。',
            enabled: readiness.canInterview,
            targetCount: readiness.evidenceBackedPointCount,
            disabledReason: '缺少带来源依据的知识点',
          ),
          LearningAgentPlanStep(
            type: LearningAgentStepType.review,
            title: '复习薄弱知识点',
            description: '用已核验普通题或编程练习巩固项目表达暴露出的薄弱点。',
            enabled: readiness.canReview,
            targetCount: readiness.practiceablePointCount,
            disabledReason: '缺少可复习的已核验题目',
          ),
        ];
      case LearningAgentGoal.programmingFoundations:
        return [
          ...preparationSteps,
          LearningAgentPlanStep(
            type: LearningAgentStepType.practice,
            title: '完成已核验练习',
            description: '执行 planner 选中的普通题或开放编程练习。',
            enabled: readiness.canPractice,
            targetCount: readiness.verifiedPracticeTargetCount,
            disabledReason: '缺少已核验练习',
          ),
          LearningAgentPlanStep(
            type: LearningAgentStepType.tutor,
            title: '学习编程概念',
            description: '基于来源片段理解概念、机制、易错点和自测问题。',
            enabled: readiness.canTutor,
            targetCount: readiness.evidenceBackedPointCount,
            disabledReason: '缺少带来源依据的知识点',
          ),
          LearningAgentPlanStep(
            type: LearningAgentStepType.review,
            title: '复习薄弱知识点',
            description: '按统一记忆和复习时间处理已经到期的薄弱知识点。',
            enabled: readiness.canReview,
            targetCount: readiness.practiceablePointCount,
            disabledReason: '缺少可复习的已核验题目',
          ),
        ];
    }
  }

  List<LearningAgentFocusPoint> _focusPointsForGoal({
    required LearningAgentGoal goal,
    required List<KnowledgePoint> evidenceBackedPoints,
    required List<KnowledgePoint> practiceablePoints,
    required Map<String, int> evidenceChunkCountByPointId,
    required Map<String, int> practiceTargetCountByPointId,
    required Map<String, int> programmingExerciseCountByPointId,
  }) {
    final practiceableIds = practiceablePoints.map((point) => point.id).toSet();
    final candidates = _uniquePoints([
      if (goal == LearningAgentGoal.programmingFoundations)
        ...practiceablePoints,
      ...evidenceBackedPoints,
    ]);
    final sorted = [...candidates];
    sorted.sort((a, b) {
      if (goal == LearningAgentGoal.programmingFoundations) {
        final practiceable = (practiceableIds.contains(b.id) ? 1 : 0)
            .compareTo(practiceableIds.contains(a.id) ? 1 : 0);
        if (practiceable != 0) return practiceable;
      }
      final mastery = a.masteryLevel.compareTo(b.masteryLevel);
      if (mastery != 0) return mastery;
      final relevance = b.interviewRelevance.compareTo(a.interviewRelevance);
      if (relevance != 0) return relevance;
      final difficulty = b.difficulty.compareTo(a.difficulty);
      if (difficulty != 0) return difficulty;
      return a.id.compareTo(b.id);
    });

    return sorted.map((point) {
      final practiceTargetCount = practiceTargetCountByPointId[point.id] ?? 0;
      final programmingExerciseCount =
          programmingExerciseCountByPointId[point.id] ?? 0;
      return LearningAgentFocusPoint(
        id: point.id,
        title: point.title,
        reason: _focusReason(goal, point),
        masteryLevel: point.masteryLevel,
        difficulty: point.difficulty,
        interviewRelevance: point.interviewRelevance,
        evidenceChunkCount: evidenceChunkCountByPointId[point.id] ?? 0,
        verifiedQuestionCount: (practiceTargetCount - programmingExerciseCount)
            .clamp(0, 1 << 31)
            .toInt(),
        verifiedProgrammingExerciseCount: programmingExerciseCount,
      );
    }).toList();
  }

  String _focusReason(LearningAgentGoal goal, KnowledgePoint point) {
    final lowMastery = point.masteryLevel < 60;
    final highInterviewRelevance = point.interviewRelevance >= 4;

    if (goal == LearningAgentGoal.programmingFoundations) {
      return lowMastery ? '掌握度偏低，适合先补概念' : '适合继续巩固编程基础';
    }
    if (highInterviewRelevance && lowMastery) {
      return '面试相关度高，且掌握度偏低';
    }
    if (highInterviewRelevance) {
      return '面试相关度高，适合优先打磨表达';
    }
    if (lowMastery) {
      return '掌握度偏低，适合优先补齐';
    }
    return '来源完整，适合继续强化';
  }

  List<LearningAgentNextActionCandidate> _generatedNextActionCandidates({
    required List<LearningAgentPlanStep> steps,
    required LearningAgentMemoryState memory,
    required List<KnowledgePoint> evidenceGapPoints,
    required List<Question> pendingQuestions,
    required List<ProgrammingExercise> pendingProgrammingExercises,
    required List<LearningAgentFocusPoint> focusPoints,
    required List<LearningAgentPracticeTarget> practiceTargets,
    required bool hasExternalOpenFollowUp,
    required bool hasExternalEvidenceGap,
  }) {
    final candidates = <LearningAgentNextActionCandidate>[];
    if (memory.hasOpenFollowUps && !hasExternalOpenFollowUp) {
      candidates.add(
        LearningAgentNextActionCandidate(
          id: 'follow-up:goal-memory',
          priority: LearningAgentNextActionPriority.openFollowUp,
          title: '处理开放追问',
          reason: '当前目标还有 ${memory.goalOpenFollowUpCount} 条未处理追问，需要先延续上一轮学习。',
          targetId: memory.latestGoalSessionTarget,
          targetLabel: memory.latestGoalSessionTarget,
          stepTypeName: LearningAgentStepRouteNames.handleFollowUps,
          toolId: LearningAgentToolRouteIds.handleFollowUps,
          occurredAt: memory.latestGoalSessionStartedAt,
        ),
      );
    }

    final sortedEvidenceGaps = [...evidenceGapPoints]..sort((a, b) {
        final mastery = a.masteryLevel.compareTo(b.masteryLevel);
        if (mastery != 0) return mastery;
        final relevance = b.interviewRelevance.compareTo(a.interviewRelevance);
        if (relevance != 0) return relevance;
        return a.id.compareTo(b.id);
      });
    for (var index = 0; index < sortedEvidenceGaps.length; index += 1) {
      final point = sortedEvidenceGaps[index];
      candidates.add(
        LearningAgentNextActionCandidate.evidenceGap(
          id: point.id,
          targetId: point.id,
          targetLabel: point.title,
          occurredAt: point.updatedAt,
          rank: index,
          reason: '“${point.title}”尚无可读取的来源片段，正式学习前需要先补齐证据。',
        ),
      );
    }
    final importStep = _stepForType(steps, LearningAgentStepType.importSources);
    if (!hasExternalEvidenceGap &&
        sortedEvidenceGaps.isEmpty &&
        importStep?.enabled == true) {
      candidates.add(
        LearningAgentNextActionCandidate.evidenceGap(
          id: 'source-library',
          targetId: 'source-library',
          targetLabel: '来源库',
          reason: '当前知识范围还没有带来源依据的知识点，需要先导入正规资料。',
        ),
      );
    }

    final sortedPendingQuestions = [...pendingQuestions]
      ..sort((a, b) => a.id.compareTo(b.id));
    for (var index = 0; index < sortedPendingQuestions.length; index += 1) {
      final question = sortedPendingQuestions[index];
      candidates.add(
        LearningAgentNextActionCandidate.pendingVerification(
          id: question.id,
          targetId:
              '${LearningAgentPracticeTargetType.question.value}:${question.id}',
          targetLabel: question.content,
          rank: index,
          reason: '题目“${question.content}”仍处于待核验状态，不能进入正式练习。',
        ),
      );
    }
    final sortedPendingExercises = [...pendingProgrammingExercises]
      ..sort((a, b) => a.id.compareTo(b.id));
    for (var index = 0; index < sortedPendingExercises.length; index += 1) {
      final exercise = sortedPendingExercises[index];
      candidates.add(
        LearningAgentNextActionCandidate.pendingVerification(
          id: 'programming-exercise:${exercise.id}',
          targetId:
              '${LearningAgentPracticeTargetType.programmingExercise.value}:${exercise.id}',
          targetLabel: exercise.prompt,
          rank: sortedPendingQuestions.length + index,
          reason: '编程练习“${exercise.prompt}”仍处于待核验状态，不能进入正式作答。',
        ),
      );
    }

    var learningRank = 0;
    for (final step in steps) {
      if (!step.enabled || _isPreparationStep(step.type)) continue;
      final toolId = learningAgentToolIdForStepName(step.type.name);
      if (toolId == null) continue;
      final focusPoint = focusPoints.isEmpty ? null : focusPoints.first;
      final practiceTarget = step.type == LearningAgentStepType.practice ||
              step.type == LearningAgentStepType.review
          ? _selectPracticeTarget(practiceTargets, focusPoint?.id)
          : null;
      final targetId = practiceTarget?.knowledgePointId ?? focusPoint?.id;
      final targetLabel = practiceTarget?.displayLabel ?? focusPoint?.title;
      candidates.add(
        LearningAgentNextActionCandidate.newLearning(
          id: '${step.type.name}:${practiceTarget?.routingId ?? targetId ?? step.type.name}',
          title: step.title,
          reason: _newLearningReason(step, focusPoint, practiceTarget),
          stepTypeName: step.type.name,
          toolId: toolId,
          targetId: targetId,
          targetLabel: targetLabel,
          rank: learningRank,
        ),
      );
      learningRank += 1;
    }
    return candidates;
  }

  List<LearningAgentNextActionCandidate> _validatedNextActionCandidates(
    List<LearningAgentNextActionCandidate> candidates,
    List<LearningAgentPlanStep> steps,
  ) {
    return candidates.map((candidate) {
      if (!candidate.executable ||
          candidate.priority ==
              LearningAgentNextActionPriority.unfinishedCheckpoint) {
        return candidate;
      }
      final stepTypeName = candidate.stepTypeName;
      final toolId = candidate.toolId;
      if (stepTypeName == null || toolId == null) {
        return candidate.blocked(
          code: 'next_action_route_missing',
          message: '下一动作缺少明确的步骤或工具，系统不会猜测执行路径。',
        );
      }
      final step = _stepForName(steps, stepTypeName);
      if (step == null) {
        return candidate.blocked(
          code: 'next_action_step_unavailable',
          message: '当前目标不支持下一动作步骤 $stepTypeName。',
        );
      }
      final expectedToolId = learningAgentToolIdForStepName(stepTypeName);
      if (expectedToolId != toolId) {
        return candidate.blocked(
          code: 'next_action_tool_mismatch',
          message: '下一动作记录的工具与步骤不一致，系统不会猜测替代工具。',
        );
      }
      if (!step.enabled) {
        return candidate.blocked(
          code: 'next_action_step_disabled',
          message: step.disabledReason ?? '下一动作对应步骤当前不可执行。',
        );
      }
      return candidate;
    }).toList(growable: false);
  }

  Iterable<LearningAgentFocusPoint> _focusPointsForAction(
    List<LearningAgentFocusPoint> focusPoints,
    String? targetId,
  ) sync* {
    if (targetId != null) {
      for (final point in focusPoints) {
        if (point.id == targetId) yield point;
      }
    }
    for (final point in focusPoints) {
      if (point.id != targetId) yield point;
    }
  }

  LearningAgentPlanStep? _stepForType(
    List<LearningAgentPlanStep> steps,
    LearningAgentStepType type,
  ) {
    for (final step in steps) {
      if (step.type == type) return step;
    }
    return null;
  }

  LearningAgentPlanStep? _stepForName(
    List<LearningAgentPlanStep> steps,
    String name,
  ) {
    for (final step in steps) {
      if (step.type.name == name) return step;
    }
    return null;
  }

  bool _isPreparationStep(LearningAgentStepType type) {
    return type == LearningAgentStepType.importSources ||
        type == LearningAgentStepType.verifyQuestions ||
        type == LearningAgentStepType.handleFollowUps;
  }

  String _newLearningReason(
    LearningAgentPlanStep step,
    LearningAgentFocusPoint? focusPoint,
    LearningAgentPracticeTarget? practiceTarget,
  ) {
    final targetLabel = practiceTarget?.displayLabel ?? focusPoint?.title;
    if (targetLabel == null) {
      return '当前没有更高优先级的未完成工作，按目标路线开始新的学习动作。';
    }
    return '当前没有未完成会话、开放追问或到期修复工作，下一步学习“$targetLabel”。';
  }

  LearningAgentSessionSummary _sessionSummaryForPlan({
    required LearningAgentGoal goal,
    required LearningAgentReadiness readiness,
    required LearningAgentMemoryState memory,
    required List<LearningAgentPlanStep> steps,
    required List<LearningAgentFocusPoint> focusPoints,
    required List<LearningAgentPracticeTarget> practiceTargets,
    required LearningAgentNextAction nextAction,
  }) {
    final nextStep = nextAction.executable && !nextAction.resumesCheckpoint
        ? _stepForName(steps, nextAction.stepTypeName ?? '')
        : null;
    LearningAgentFocusPoint? focusPoint;
    if (nextStep != null &&
        !_isPreparationStep(nextStep.type) &&
        focusPoints.isNotEmpty) {
      focusPoint = focusPoints.first;
    }
    final practiceTarget = nextStep?.type == LearningAgentStepType.practice ||
            nextStep?.type == LearningAgentStepType.review
        ? _selectPracticeTarget(practiceTargets, focusPoint?.id)
        : null;

    return LearningAgentSessionSummary(
      goal: goal,
      nextStep: nextStep,
      focusPoint: focusPoint,
      practiceTarget: practiceTarget,
      title: nextAction.title,
      objective: nextAction.reason,
      targetLabel: nextAction.targetLabel ??
          _sessionTargetLabel(nextStep, focusPoint, practiceTarget),
      evidenceConstraint: nextAction.resumesCheckpoint
          ? '恢复时继续使用 checkpoint 中保存的原 plan snapshot，不重新规划路由。'
          : !nextAction.executable
              ? nextAction.blockerMessage ?? '下一动作当前不可执行。'
              : _sessionEvidenceConstraint(
                  nextStep,
                  focusPoint,
                  readiness,
                  practiceTarget,
                ),
      memoryReminder: _sessionMemoryReminder(memory),
      successCriteria: nextStep == null
          ? const []
          : _sessionSuccessCriteria(
              nextStep,
              focusPoint,
              readiness,
            ),
      reflectionPrompts: nextStep == null
          ? const []
          : _sessionReflectionPrompts(nextStep, focusPoint),
    );
  }

  String? _sessionMemoryReminder(LearningAgentMemoryState memory) {
    if (memory.goalOpenFollowUpCount > 0) {
      final latestContext = _latestSessionContext(memory);
      if (latestContext != null) {
        return '当前目标还有 ${memory.goalOpenFollowUpCount} 条未处理追问，建议先回到$latestContext处理。';
      }
      return '当前目标还有 ${memory.goalOpenFollowUpCount} 条未处理追问，建议优先回到历史记录处理。';
    }
    if (memory.goalSessionCount > 0) {
      final latestContext = _latestSessionContext(memory);
      if (latestContext != null) {
        return '当前目标已有 ${memory.goalSessionCount} 条记录，上次是$latestContext，可先回看复盘再继续。';
      }
      return '当前目标已有 ${memory.goalSessionCount} 条 Agent Session 记录，可先回看复盘再继续。';
    }
    return null;
  }

  String? _latestSessionContext(LearningAgentMemoryState memory) {
    final startedAt = memory.latestGoalSessionStartedAt;
    if (startedAt == null) return null;

    final parts = <String>[];
    final target = memory.latestGoalSessionTarget?.trim();
    if (target != null && target.isNotEmpty) {
      parts.add('目标“$target”');
    }

    final title = memory.latestGoalSessionTitle?.trim();
    if (title != null && title.isNotEmpty) {
      parts.add('“$title”');
    }

    parts.add(_compactDateTime(startedAt));
    return parts.join(' · ');
  }

  String _compactDateTime(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  LearningAgentPracticeTarget? _selectPracticeTarget(
    List<LearningAgentPracticeTarget> targets,
    String? focusPointId,
  ) {
    if (targets.isEmpty) return null;
    final matchingFocus = focusPointId == null
        ? const <LearningAgentPracticeTarget>[]
        : targets
            .where((target) => target.knowledgePointId == focusPointId)
            .toList(growable: false);
    return matchingFocus.isEmpty ? targets.first : matchingFocus.first;
  }

  int _comparePracticeTargets(
    LearningAgentPracticeTarget a,
    LearningAgentPracticeTarget b,
  ) {
    final typeOrder = _practiceTargetTypeOrder(a.type)
        .compareTo(_practiceTargetTypeOrder(b.type));
    if (typeOrder != 0) return typeOrder;
    final pointOrder = a.knowledgePointId.compareTo(b.knowledgePointId);
    if (pointOrder != 0) return pointOrder;
    return a.id.compareTo(b.id);
  }

  int _practiceTargetTypeOrder(LearningAgentPracticeTargetType type) {
    switch (type) {
      case LearningAgentPracticeTargetType.programmingExercise:
        return 0;
      case LearningAgentPracticeTargetType.question:
        return 1;
    }
  }

  String _sessionTargetLabel(
    LearningAgentPlanStep? step,
    LearningAgentFocusPoint? focusPoint,
    LearningAgentPracticeTarget? practiceTarget,
  ) {
    if (step == null) return '暂无目标';

    switch (step.type) {
      case LearningAgentStepType.importSources:
        return '来源库';
      case LearningAgentStepType.verifyQuestions:
        return '${step.targetCount} 道待核验题';
      case LearningAgentStepType.handleFollowUps:
        return '${step.targetCount} 条未处理追问';
      case LearningAgentStepType.tutor:
      case LearningAgentStepType.interview:
        return focusPoint?.title ?? '${step.targetCount} 个知识点';
      case LearningAgentStepType.practice:
      case LearningAgentStepType.review:
        return practiceTarget?.displayLabel ??
            focusPoint?.title ??
            '${step.targetCount} 个练习';
    }
  }

  String _sessionEvidenceConstraint(
    LearningAgentPlanStep? step,
    LearningAgentFocusPoint? focusPoint,
    LearningAgentReadiness readiness,
    LearningAgentPracticeTarget? practiceTarget,
  ) {
    if (step == null) {
      return '正式学习只在存在来源知识点和已核验题目后启动。';
    }

    switch (step.type) {
      case LearningAgentStepType.importSources:
        return '导入阶段只建立来源和片段，不把无来源内容放入正式练习。';
      case LearningAgentStepType.verifyQuestions:
        return '只有通过来源核验的普通题和编程练习才会进入正式学习与复习。';
      case LearningAgentStepType.handleFollowUps:
        return '处理追问时仍从已有来源知识点和历史复盘进入，不把无来源内容放入正式记忆。';
      case LearningAgentStepType.tutor:
        if (focusPoint != null) {
          return '解释必须受 ${focusPoint.evidenceChunkCount} 个真实来源片段约束。';
        }
        return '导师模式只使用存在真实来源片段的知识点。';
      case LearningAgentStepType.interview:
        if (focusPoint != null) {
          return '追问优先围绕 ${focusPoint.evidenceChunkCount} 个证据片段支撑的知识点。';
        }
        return '面试问题只围绕有来源知识点生成。';
      case LearningAgentStepType.practice:
        if (practiceTarget != null) {
          return '${practiceTarget.type.label}已人工核验，并绑定 ${practiceTarget.citationIds.length} 条来源引用。';
        }
        return '正式练习必须已人工核验并包含来源引用。';
      case LearningAgentStepType.review:
        return '复习队列只使用 ${readiness.practiceablePointCount} 个可练习知识点的已核验普通题或编程练习。';
    }
  }

  List<String> _sessionSuccessCriteria(
    LearningAgentPlanStep? step,
    LearningAgentFocusPoint? focusPoint,
    LearningAgentReadiness readiness,
  ) {
    if (step == null) {
      return const ['补齐来源、核验题目或新增学习材料后，再启动正式学习。'];
    }

    switch (step.type) {
      case LearningAgentStepType.importSources:
        return const [
          '至少导入一份项目、官方文档或课程资料。',
          '导入内容被拆成可追溯来源片段。',
          '不把无来源内容直接放进正式练习。',
        ];
      case LearningAgentStepType.verifyQuestions:
        return [
          '处理 ${readiness.pendingQuestionCount} 道待核验题中的下一批题目。',
          '只把有有效引用支撑的题目标记为已核验。',
          '无法由来源支撑的题目保持待核验或降级为无来源。',
        ];
      case LearningAgentStepType.handleFollowUps:
        return const [
          '打开当前目标的未处理追问历史。',
          '选择一条追问继续导师或面试处理。',
          '处理完成后回到 Agent Session 复盘记录本轮追问。',
        ];
      case LearningAgentStepType.tutor:
        return [
          focusPoint == null
              ? '能用自己的话复述本次讲解的核心概念。'
              : '能用自己的话复述“${focusPoint.title}”。',
          '能指出解释所依赖的来源片段。',
          '记录一个仍不清楚、需要继续追问的问题。',
        ];
      case LearningAgentStepType.interview:
        return [
          focusPoint == null
              ? '至少完成一轮来源约束面试问答。'
              : '至少围绕“${focusPoint.title}”完成一轮面试问答。',
          '回答中说清实现细节、限制或工程取舍。',
          '复盘反馈中的薄弱知识点并更新掌握度。',
        ];
      case LearningAgentStepType.practice:
        return [
          focusPoint == null
              ? '完成 planner 选中的已核验练习。'
              : '优先完成“${focusPoint.title}”相关已核验练习。',
          '作答后查看解析、评价和来源引用。',
          '练习结果进入复习调度或掌握度更新路径。',
        ];
      case LearningAgentStepType.review:
        return [
          focusPoint == null ? '完成一组到期复习题。' : '优先复习“${focusPoint.title}”相关题目。',
          '只复习已核验普通题或编程练习，避免无来源内容进入正式记忆。',
          '复习结果更新下一次复习时间。',
        ];
    }
  }

  List<String> _sessionReflectionPrompts(
    LearningAgentPlanStep? step,
    LearningAgentFocusPoint? focusPoint,
  ) {
    if (step == null) {
      return const ['还缺少什么材料，导致我现在不能开始正式学习？'];
    }

    switch (step.type) {
      case LearningAgentStepType.importSources:
        return const [
          '这份资料最适合支持哪个面试话题？',
          '哪些内容还缺少官方文档或源码证据？',
        ];
      case LearningAgentStepType.verifyQuestions:
        return const [
          '哪些题目的答案能被来源直接支撑？',
          '哪些题目需要重写或降级为无来源？',
        ];
      case LearningAgentStepType.handleFollowUps:
        return const [
          '这条追问为什么上轮没有处理完？',
          '继续处理它需要回到哪条来源或哪个项目细节？',
          '处理完后还需要留下新的下次追问吗？',
        ];
      case LearningAgentStepType.tutor:
        return [
          focusPoint == null
              ? '我能不能不用原文复述这个概念？'
              : '我能不能不用原文复述“${focusPoint.title}”？',
          '这个知识点在我的项目里对应什么实现细节？',
          '如果面试官继续追问，我最容易卡在哪里？',
        ];
      case LearningAgentStepType.interview:
        return [
          focusPoint == null
              ? '我回答时有没有讲清实现、限制和取舍？'
              : '我回答“${focusPoint.title}”时有没有讲清实现、限制和取舍？',
          '哪些反馈能转成下一轮要复习的知识点？',
          '我的回答有没有超出来源依据？',
        ];
      case LearningAgentStepType.practice:
        return [
          '我错题的原因是概念没懂、记忆不稳，还是题干没读清？',
          '每道错题的正确答案能对应到哪条来源？',
          '下一次复习前我需要补哪一个概念？',
        ];
      case LearningAgentStepType.review:
        return [
          '哪些知识已经能稳定回忆？',
          '哪些题仍然需要更短间隔复习？',
          '这轮复习暴露了哪个最值得追问的概念？',
        ];
    }
  }
}
