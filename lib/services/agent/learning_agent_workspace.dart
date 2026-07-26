import 'learning_agent_memory_record.dart';
import 'learning_agent_planner_service.dart';
import 'learning_agent_tool_registry.dart';

enum LearningAgentWorkspaceToolState {
  nextAction,
  available,
  blocked,
  unavailable;
}

class LearningAgentWorkspaceToolTarget {
  final LearningAgentToolDefinition tool;
  final LearningAgentPlanStep step;
  final LearningAgentWorkspaceToolState state;

  const LearningAgentWorkspaceToolTarget({
    required this.tool,
    required this.step,
    required this.state,
  });

  bool get isNextAction => state == LearningAgentWorkspaceToolState.nextAction;
  bool get canExecute => isNextAction;

  String get statusLabel {
    switch (state) {
      case LearningAgentWorkspaceToolState.nextAction:
        return '下一动作';
      case LearningAgentWorkspaceToolState.available:
        return '路线可用';
      case LearningAgentWorkspaceToolState.blocked:
        return '当前阻断';
      case LearningAgentWorkspaceToolState.unavailable:
        return '尚未就绪';
    }
  }
}

class LearningAgentWorkspaceSnapshot {
  final LearningAgentPlan plan;
  final LearningAgentMemorySnapshot memory;
  final List<LearningAgentWorkspaceToolTarget> toolTargets;

  const LearningAgentWorkspaceSnapshot({
    required this.plan,
    required this.memory,
    required this.toolTargets,
  });

  LearningAgentGoal get goal => plan.goal;
  LearningAgentKnowledgeScope get knowledgeScope => plan.knowledgeScope;
  int get historyRecordCount => memory.recordCount;
  int get openFollowUpCount => memory.openFollowUps.length;
  int get pendingReviewCount => memory.pendingReviews.length;
  DateTime? get nextReviewAt => memory.nextReviewAt;

  LearningAgentWorkspaceToolTarget? get selectedToolTarget {
    for (final target in toolTargets) {
      if (target.isNextAction) return target;
    }
    return null;
  }
}

class LearningAgentWorkspaceService {
  final LearningAgentToolRegistry toolRegistry;

  const LearningAgentWorkspaceService({
    this.toolRegistry = const LearningAgentToolRegistry(),
  });

  LearningAgentWorkspaceSnapshot build({
    required LearningAgentPlan plan,
    required LearningAgentMemorySnapshot memory,
  }) {
    final selectedToolId = plan.nextAction?.toolId;
    final selectedActionExecutable = plan.nextAction?.executable ?? false;
    final toolTargets = <LearningAgentWorkspaceToolTarget>[];
    final stepsByType = {
      for (final step in plan.steps) step.type: step,
    };

    for (final stepType in _workspaceStepOrder) {
      final step = stepsByType[stepType] ?? _supplementalStep(plan, stepType);
      if (step == null) continue;
      final tool = toolRegistry.toolForStep(step.type);
      if (tool == null || !tool.supportsGoal(plan.goal)) continue;
      final isSelected = selectedToolId == tool.toolId;
      final state = isSelected
          ? selectedActionExecutable
              ? LearningAgentWorkspaceToolState.nextAction
              : LearningAgentWorkspaceToolState.blocked
          : step.enabled
              ? LearningAgentWorkspaceToolState.available
              : LearningAgentWorkspaceToolState.unavailable;
      toolTargets.add(
        LearningAgentWorkspaceToolTarget(
          tool: tool,
          step: step,
          state: state,
        ),
      );
    }

    return LearningAgentWorkspaceSnapshot(
      plan: plan,
      memory: memory,
      toolTargets: List.unmodifiable(toolTargets),
    );
  }

  LearningAgentPlanStep? _supplementalStep(
    LearningAgentPlan plan,
    LearningAgentStepType type,
  ) {
    final readiness = plan.readiness;
    switch (type) {
      case LearningAgentStepType.tutor:
        return LearningAgentPlanStep(
          type: type,
          title: '导师学习',
          description: '基于来源片段解释目标知识，并保留追问和薄弱点。',
          enabled: readiness.canTutor,
          targetCount: readiness.evidenceBackedPointCount,
          disabledReason: '缺少带来源依据的知识点',
        );
      case LearningAgentStepType.interview:
        return LearningAgentPlanStep(
          type: type,
          title: '面试训练',
          description: '围绕来源约束知识点检验项目细节和工程表达。',
          enabled: readiness.canInterview,
          targetCount: readiness.evidenceBackedPointCount,
          disabledReason: '缺少带来源依据的知识点',
        );
      case LearningAgentStepType.practice:
        return LearningAgentPlanStep(
          type: type,
          title: '已核验练习',
          description: '执行带引用的普通题或开放编程练习。',
          enabled: readiness.canPractice,
          targetCount: readiness.verifiedPracticeTargetCount,
          disabledReason: '缺少已核验练习',
        );
      case LearningAgentStepType.review:
        return LearningAgentPlanStep(
          type: type,
          title: '到期复习',
          description: '按统一记忆和复习时间处理薄弱知识点。',
          enabled: readiness.canReview,
          targetCount: readiness.practiceablePointCount,
          disabledReason: '缺少可复习的已核验内容',
        );
      case LearningAgentStepType.importSources:
      case LearningAgentStepType.verifyQuestions:
      case LearningAgentStepType.handleFollowUps:
        return null;
    }
  }
}

const _workspaceStepOrder = <LearningAgentStepType>[
  LearningAgentStepType.handleFollowUps,
  LearningAgentStepType.importSources,
  LearningAgentStepType.verifyQuestions,
  LearningAgentStepType.tutor,
  LearningAgentStepType.interview,
  LearningAgentStepType.practice,
  LearningAgentStepType.review,
];
