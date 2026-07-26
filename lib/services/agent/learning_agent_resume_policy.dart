import 'learning_agent_state.dart';
import 'learning_agent_tool_registry.dart';

enum LearningAgentResumeStatus {
  ready('ready', '可恢复'),
  waitingForUser('waiting_for_user', '等待用户决策'),
  missingState('missing_state', '缺少运行状态'),
  missingPlan('missing_plan', '缺少计划快照'),
  incompatiblePlan('incompatible_plan', '计划快照不兼容'),
  missingTool('missing_tool', '缺少可恢复工具'),
  missingEvidence('missing_evidence', '缺少恢复证据'),
  completed('completed', '已完成'),
  canceled('canceled', '已结束'),
  blocked('blocked', '已阻断');

  final String value;
  final String label;
  const LearningAgentResumeStatus(this.value, this.label);
}

class LearningAgentResumeReadiness {
  final LearningAgentResumeStatus status;
  final bool canResume;
  final bool requiresUserDecision;
  final String title;
  final String message;

  const LearningAgentResumeReadiness({
    required this.status,
    required this.canResume,
    this.requiresUserDecision = false,
    required this.title,
    required this.message,
  });
}

class LearningAgentResumePolicy {
  final LearningAgentToolRegistry toolRegistry;

  const LearningAgentResumePolicy({
    this.toolRegistry = const LearningAgentToolRegistry(),
  });

  LearningAgentResumeReadiness evaluate(
    LearningAgentState? state, {
    LearningAgentToolDefinition? selectedTool,
  }) {
    if (state == null) {
      return const LearningAgentResumeReadiness(
        status: LearningAgentResumeStatus.missingState,
        canResume: false,
        title: '缺少运行状态',
        message: '当前没有可恢复的 Agent runtime state。',
      );
    }

    if (state.phase == LearningAgentPhase.complete) {
      return const LearningAgentResumeReadiness(
        status: LearningAgentResumeStatus.completed,
        canResume: false,
        title: '会话已完成',
        message: '当前 Agent Session 已完成，不需要恢复。',
      );
    }

    if (state.phase == LearningAgentPhase.canceled) {
      return const LearningAgentResumeReadiness(
        status: LearningAgentResumeStatus.canceled,
        canResume: false,
        title: '会话已结束',
        message: '当前 Agent Session 已由用户结束，不再恢复。',
      );
    }

    if (state.phase == LearningAgentPhase.blocked) {
      return const LearningAgentResumeReadiness(
        status: LearningAgentResumeStatus.blocked,
        canResume: false,
        title: '会话已阻断',
        message: '当前 Agent Session 被策略或运行错误阻断，需要先处理阻断原因。',
      );
    }

    final tool = _selectedTool(state, selectedTool);
    if (tool == null) {
      return const LearningAgentResumeReadiness(
        status: LearningAgentResumeStatus.missingTool,
        canResume: false,
        title: '缺少可恢复工具',
        message: '当前 Agent runtime state 没有记录可继续执行的工具。',
      );
    }

    if (_needsEvidenceForResume(state, tool)) {
      return LearningAgentResumeReadiness(
        status: LearningAgentResumeStatus.missingEvidence,
        canResume: false,
        title: '缺少恢复证据',
        message: '${tool.title} 需要来源证据，当前 state 没有记录证据片段。',
      );
    }

    if (state.isWaitingForUser) {
      return LearningAgentResumeReadiness(
        status: LearningAgentResumeStatus.waitingForUser,
        canResume: true,
        requiresUserDecision: true,
        title: '等待用户决策',
        message: state.pendingUserDecision!.prompt,
      );
    }

    return LearningAgentResumeReadiness(
      status: LearningAgentResumeStatus.ready,
      canResume: true,
      title: '可以恢复',
      message: '可以从 ${state.phase.label} 阶段继续执行 ${tool.title}。',
    );
  }

  LearningAgentToolDefinition? _selectedTool(
    LearningAgentState state,
    LearningAgentToolDefinition? selectedTool,
  ) {
    if (selectedTool != null) return selectedTool;
    final toolId = state.selectedToolId;
    if (toolId == null || toolId.isEmpty) return null;
    return toolRegistry.toolForIdValue(toolId);
  }

  bool _needsEvidenceForResume(
    LearningAgentState state,
    LearningAgentToolDefinition tool,
  ) {
    if (state.phase == LearningAgentPhase.plan) return false;
    if (state.evidenceChunkIds.isNotEmpty) return false;
    switch (tool.evidenceRequirement) {
      case LearningAgentToolEvidenceRequirement.targetEvidenceChunks:
      case LearningAgentToolEvidenceRequirement.verifiedQuestionCitations:
        return true;
      case LearningAgentToolEvidenceRequirement.none:
      case LearningAgentToolEvidenceRequirement.optionalContext:
      case LearningAgentToolEvidenceRequirement.sessionMemory:
        return false;
    }
  }
}

List<String> learningAgentResumeReadinessDiagnosticLines(
  LearningAgentState? state, {
  LearningAgentToolDefinition? selectedTool,
  LearningAgentResumePolicy policy = const LearningAgentResumePolicy(),
}) {
  final readiness = policy.evaluate(state, selectedTool: selectedTool);
  return [
    'Agent 恢复状态: ${readiness.status.label}',
    'Agent 可恢复: ${readiness.canResume ? '是' : '否'}',
    'Agent 恢复提示: ${readiness.message}',
    if (readiness.requiresUserDecision) 'Agent 恢复需用户决策: 是',
  ];
}

bool isLearningAgentResumeReadinessDiagnosticLine(String line) {
  return line.startsWith('Agent 恢复状态:') ||
      line.startsWith('Agent 可恢复:') ||
      line.startsWith('Agent 恢复提示:') ||
      line.startsWith('Agent 恢复需用户决策:');
}
